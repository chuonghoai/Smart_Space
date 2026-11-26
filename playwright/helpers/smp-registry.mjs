import fs from 'node:fs';
import path from 'node:path';

const ROOT_DIR = process.cwd();
const LIST_PATH = path.join(ROOT_DIR, 'docs', 'TestCaseList.md');
const DETAILS_DIR = path.join(ROOT_DIR, 'docs', 'TestCases');

export function loadSmpRegistry() {
  if (!fs.existsSync(LIST_PATH)) {
    throw new Error(`Không tìm thấy ${LIST_PATH}`);
  }
  const text = fs.readFileSync(LIST_PATH, 'utf8');
  const map = new Map();

  for (const line of text.split(/\r?\n/)) {
    const cells = line.split(/(?<!\\)\|/).map((c) => c.trim());
    if (cells.length < 11) continue;
    if (!/^\d+$/.test(cells[1]) || !/^SMP-\d{3,}$/.test(cells[2])) continue;
    const detailMatch = cells[9].match(/^\[Xem chi tiết\]\(([^)]+)\)$/);
    if (!detailMatch) continue;
    const id = cells[2];
    const name = cells[3].replace(/\\\|/g, '|');
    const project = cells[4];
    const detailRel = detailMatch[1].trim();
    const detailPath = path.join(ROOT_DIR, 'docs', detailRel);

    let filePath = '';
    if (fs.existsSync(detailPath)) {
      const detailText = fs.readFileSync(detailPath, 'utf8');
      const fm = detailText.match(/\*\*File test tương ứng:\*\*\s*`([^`]+)`/);
      if (fm) filePath = fm[1].trim();
    }

    let engine = 'unknown';
    let region = null;
    if (filePath.startsWith('playwright/')) {
      engine = 'playwright';
      region = filePath.split('/')[1] || null;
    } else if (filePath.endsWith('_test.dart')) {
      engine = 'native-flutter';
      region = filePath.split('/')[0] || null;
    } else if (filePath.endsWith('.java')) {
      engine = 'native-backend';
      region = 'SmartSpace_Backend';
    }

    map.set(id, { id, name, project, detailPath, filePath, engine, region });
  }
  return map;
}

export function extractSmpIdsFromArgs(extraArgs) {
  const ids = new Set();
  for (let i = 0; i < extraArgs.length; i++) {
    const arg = extraArgs[i];
    if (arg === '--grep' || arg === '-g') {
      const val = extraArgs[i + 1] || '';
      for (const m of val.matchAll(/SMP-\d{3,}/gi)) {
        ids.add(m[0].toUpperCase());
      }
      i++;
    } else if (arg.startsWith('--grep=') || arg.startsWith('-g=')) {
      const val = arg.split('=', 2)[1] || '';
      for (const m of val.matchAll(/SMP-\d{3,}/gi)) {
        ids.add(m[0].toUpperCase());
      }
    }
  }
  return [...ids];
}

export function validateRegionSmpGrep(targetRegion, extraArgs) {
  const ids = extractSmpIdsFromArgs(extraArgs);
  if (ids.length === 0) return;

  const registry = loadSmpRegistry();
  const allIds = [...registry.keys()].sort();
  const minId = allIds[0] || 'SMP-001';
  const maxId = allIds[allIds.length - 1] || 'N/A';

  for (const id of ids) {
    const entry = registry.get(id);
    if (!entry) {
      throw new Error(
        `Mã test case "${id}" không tồn tại trong docs/TestCaseList.md (hiện có từ ${minId} đến ${maxId}).`,
      );
    }

    if (entry.engine !== 'playwright') {
      throw new Error(
        `Mã test case "${id}" (${entry.project}) là test native tại "${entry.filePath}", không thực thi qua Playwright.\n` +
          `Hãy chạy bằng lệnh chuyên dụng: npm run test:smp -- ${id}`,
      );
    }

    if (targetRegion !== 'all' && entry.region !== targetRegion) {
      throw new Error(
        `Mã test case "${id}" thuộc vùng "${entry.region}" (${entry.filePath}), không thuộc vùng "${targetRegion}".\n` +
          `Hãy chạy: npm run ${entry.region}:test -- --grep "${id}"`,
      );
    }
  }
}

export function resolveNativeTestTarget(entry) {
  const fullPath = path.join(ROOT_DIR, entry.filePath);
  if (!fs.existsSync(fullPath)) {
    throw new Error(`Không tìm thấy file test thực tế: ${entry.filePath}`);
  }
  const content = fs.readFileSync(fullPath, 'utf8');
  const lines = content.split(/\r?\n/);
  const markerIdx = lines.findIndex((l) => l.includes(`Test Case ID: ${entry.id}`));
  if (markerIdx === -1) {
    throw new Error(`Không tìm thấy chú thích "// Test Case ID: ${entry.id}" trong ${entry.filePath}`);
  }

  if (entry.engine === 'native-flutter') {
    const appDir = entry.filePath.split('/')[0];
    const relTestFile = entry.filePath.slice(appDir.length + 1);
    for (let i = markerIdx + 1; i < Math.min(lines.length, markerIdx + 10); i++) {
      const m = lines[i].match(/\b(?:test|testWidgets)\s*\(\s*(['"])(.*?)\1/);
      if (m) {
        let testName = m[2];
        if (testName.includes('$')) {
          // Trường hợp vòng lặp for (ví dụ SMP-058: '[$name] hiện 2 nửa...')
          testName = testName.replace(/^\[[^\]]*\]\s*/, '').replace(/\$\{?[\w.]+\}?/g, '').trim();
        }
        return { kind: 'flutter', appDir, relTestFile, testName };
      }
    }
    throw new Error(`Không phân tích được tên test Flutter cho ${entry.id} trong ${entry.filePath}`);
  }

  if (entry.engine === 'native-backend') {
    const pkgMatch = content.match(/^\s*package\s+([\w.]+)\s*;/m);
    const clsMatch = content.match(/\bclass\s+([A-Za-z0-9_]+)/);
    if (!pkgMatch || !clsMatch) {
      throw new Error(`Không tìm thấy package/class trong ${entry.filePath}`);
    }

    const classStack = [];
    let braceDepth = 0;
    let inBlockComment = false;
    let inTextBlock = false;
    for (let i = 0; i <= markerIdx; i++) {
      let s = lines[i];
      // Lược bỏ block comment, text block ("""), string/char literal và line comment để đếm dấu ngoặc nhọn chính xác
      let stripped = '';
      for (let j = 0; j < s.length; j++) {
        const ch = s[j];
        const next = s[j + 1];
        if (inBlockComment) {
          if (ch === '*' && next === '/') {
            inBlockComment = false;
            j++;
          }
          continue;
        }
        if (inTextBlock) {
          if (ch === '"' && next === '"' && s[j + 2] === '"') {
            inTextBlock = false;
            j += 2;
          }
          continue;
        }
        if (ch === '/' && next === '*') {
          inBlockComment = true;
          j++;
          continue;
        }
        if (ch === '/' && next === '/') {
          break;
        }
        if (ch === '"' && next === '"' && s[j + 2] === '"') {
          inTextBlock = true;
          j += 2;
          continue;
        }
        if (ch === '"' || ch === "'") {
          const quote = ch;
          j++;
          while (j < s.length) {
            if (s[j] === '\\') {
              j += 2;
              continue;
            }
            if (s[j] === quote) break;
            j++;
          }
          continue;
        }
        stripped += ch;
      }

      const declMatch = stripped.match(/\bclass\s+([A-Za-z0-9_]+)/);
      if (declMatch) {
        classStack.push({ name: declMatch[1], enterDepth: braceDepth, opened: false });
      }
      for (const ch of stripped) {
        if (ch === '{') braceDepth++;
        else if (ch === '}') braceDepth--;
      }
      for (const item of classStack) {
        if (braceDepth > item.enterDepth) item.opened = true;
      }
      while (classStack.length > 0) {
        const top = classStack[classStack.length - 1];
        if (top.opened && braceDepth <= top.enterDepth) {
          classStack.pop();
        } else {
          break;
        }
      }
    }

    const classNamePath = classStack.length > 0 ? classStack.map((c) => c.name).join('$') : clsMatch[1];
    const fqcn = `${pkgMatch[1]}.${classNamePath}`;
    let methodName = null;
    for (let i = markerIdx + 1; i < Math.min(lines.length, markerIdx + 12); i++) {
      const mm = lines[i].match(/\bvoid\s+([A-Za-z0-9_]+)\s*\(/);
      if (mm) {
        methodName = mm[1];
        break;
      }
    }
    if (!methodName) {
      throw new Error(`Không tìm thấy tên method Java cho ${entry.id} trong ${entry.filePath}`);
    }
    const requiresLiveServer = content.includes('localhost:8989') || content.includes('HttpClient');
    return { kind: 'junit', fqcn, methodName, requiresLiveServer };
  }

  throw new Error(`Không hỗ trợ engine "${entry.engine}" cho ${entry.id}`);
}
