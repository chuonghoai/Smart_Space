import fs from 'node:fs';
import path from 'node:path';

function findFileRecursive(dir, targetName) {
  if (!fs.existsSync(dir)) return null;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isFile() && entry.name === targetName) return full;
    if (entry.isDirectory()) {
      const found = findFileRecursive(full, targetName);
      if (found) return found;
    }
  }
  return null;
}

function findDirsNamed(dir, targetDirName) {
  const results = [];
  if (!fs.existsSync(dir)) return results;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const full = path.join(dir, entry.name);
    if (entry.name === targetDirName) {
      results.push(full);
    } else {
      results.push(...findDirsNamed(full, targetDirName));
    }
  }
  return results;
}

function readPlaywrightStats(regionDir, region) {
  const direct = path.join(regionDir, 'results.json');
  const nested = path.join(regionDir, 'playwright-report', region, 'results.json');
  const file = fs.existsSync(direct)
    ? direct
    : fs.existsSync(nested)
      ? nested
      : findFileRecursive(regionDir, 'results.json');
  if (!file || !fs.existsSync(file)) {
    return { total: 0, pass: 0, fail: 0, skip: 0, found: false };
  }
  const stats = JSON.parse(fs.readFileSync(file, 'utf8')).stats || {};
  const pass = Number(stats.expected || 0) + Number(stats.flaky || 0);
  const fail = Number(stats.unexpected || 0);
  const skip = Number(stats.skipped || 0);
  return { total: pass + fail + skip, pass, fail, skip, found: true };
}

function readFlutterNativeStats(regionDir, fileName) {
  const file = findFileRecursive(regionDir, fileName);
  if (!file || !fs.existsSync(file)) {
    return { total: 0, pass: 0, fail: 0, skip: 0, found: false };
  }
  const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  const testNames = new Map();
  let pass = 0;
  let fail = 0;
  let skip = 0;

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.startsWith('{')) continue;
    let ev;
    try {
      ev = JSON.parse(trimmed);
    } catch {
      continue;
    }
    if (ev.type === 'testStart' && ev.test && typeof ev.test.id === 'number') {
      testNames.set(ev.test.id, String(ev.test.name || ''));
    } else if (ev.type === 'testDone' && typeof ev.testID === 'number') {
      const name = testNames.get(ev.testID) || '';
      const isSynthetic =
        name.startsWith('loading ') ||
        name === '(setUpAll)' ||
        name === '(tearDownAll)' ||
        name.startsWith('(setUpAll)') ||
        name.startsWith('(tearDownAll)');
      if (isSynthetic) {
        // Giữ nguyên lỗi loading/setUpAll nếu thực sự fail để không nuốt lỗi ẩn
        if (ev.result !== 'success' && !ev.skipped) {
          fail++;
        }
        continue;
      }
      if (ev.hidden) continue;
      if (ev.skipped) {
        skip++;
      } else if (ev.result === 'success') {
        pass++;
      } else {
        fail++;
      }
    }
  }
  return { total: pass + fail + skip, pass, fail, skip, found: true };
}

function readSurefireDirStats(backendDir, subDirName) {
  const dirs = findDirsNamed(backendDir, subDirName);
  let pass = 0;
  let fail = 0;
  let skip = 0;
  let foundAny = false;

  for (const dir of dirs) {
    for (const file of fs.readdirSync(dir)) {
      if (!file.startsWith('TEST-') || !file.endsWith('.xml')) continue;
      foundAny = true;
      const xml = fs.readFileSync(path.join(dir, file), 'utf8');
      const suiteMatch = xml.match(/<testsuite\b([^>]*)>/);
      if (!suiteMatch) continue;
      const attrs = suiteMatch[1];
      const getAttr = (name) => {
        const m = attrs.match(new RegExp(`\\b${name}="(\\d+)"`));
        return m ? Number(m[1]) : 0;
      };
      const tests = getAttr('tests');
      const errors = getAttr('errors');
      const failures = getAttr('failures');
      const skipped = getAttr('skipped');
      const failedCount = errors + failures;
      fail += failedCount;
      skip += skipped;
      pass += Math.max(0, tests - failedCount - skipped);
    }
  }
  return { total: pass + fail + skip, pass, fail, skip, found: foundAny };
}

function addStats(a, b) {
  return {
    total: a.total + b.total,
    pass: a.pass + b.pass,
    fail: a.fail + b.fail,
    skip: a.skip + b.skip,
  };
}

function main() {
  const artifactsRoot = process.argv[2] ? path.resolve(process.argv[2]) : path.resolve(process.cwd(), 'artifacts');
  const jobResults = {
    backend: process.env.RES_BACKEND || 'unknown',
    admin: process.env.RES_ADMIN || 'unknown',
    staff: process.env.RES_STAFF || 'unknown',
    client: process.env.RES_CLIENT || 'unknown',
  };

  const backendDir = path.join(artifactsRoot, 'backend');
  const adminDir = path.join(artifactsRoot, 'admin');
  const staffDir = path.join(artifactsRoot, 'staff');
  const clientDir = path.join(artifactsRoot, 'client');

  const pwRows = [
    { label: 'Backend', job: jobResults.backend, ...readPlaywrightStats(backendDir, 'backend') },
    { label: 'Admin', job: jobResults.admin, ...readPlaywrightStats(adminDir, 'admin') },
    { label: 'Staff', job: jobResults.staff, ...readPlaywrightStats(staffDir, 'staff') },
    { label: 'Client', job: jobResults.client, ...readPlaywrightStats(clientDir, 'client') },
  ];

  const beUnit = readSurefireDirStats(backendDir, 'surefire-unit');
  const beCtrl = readSurefireDirStats(backendDir, 'surefire-controller');
  const beApp = readSurefireDirStats(backendDir, 'surefire-app');
  const nativeBackend = addStats(addStats(beUnit, beCtrl), beApp);

  const nativeAdmin = readFlutterNativeStats(adminDir, 'native-admin.json');
  const nativeStaff = readFlutterNativeStats(staffDir, 'native-staff.json');
  const nativeClientApp = readFlutterNativeStats(clientDir, 'native-client.json');
  const nativeShared = readFlutterNativeStats(clientDir, 'native-shared.json');

  const nativeRows = [
    { label: 'Backend (Unit + Controller + App)', ...nativeBackend },
    { label: 'Admin (Flutter Native)', ...nativeAdmin },
    { label: 'Staff (Flutter Native)', ...nativeStaff },
    { label: 'Client (Flutter Native)', ...nativeClientApp },
    { label: 'Shared (mobile_shared)', ...nativeShared },
  ];

  const pwSum = pwRows.reduce((acc, r) => addStats(acc, r), { total: 0, pass: 0, fail: 0, skip: 0 });
  const nativeSum = nativeRows.reduce((acc, r) => addStats(acc, r), { total: 0, pass: 0, fail: 0, skip: 0 });
  const grandSum = addStats(pwSum, nativeSum);

  const lines = [
    '## SmartSpace Full Automation Summary (Playwright + Native)',
    '',
    '### 1. Playwright Automation',
    '| Project | Kết quả Job | Tổng | PASS | FAIL | SKIPPED |',
    '|---|---|---:|---:|---:|---:|',
    ...pwRows.map((r) => `| ${r.label} | ${r.job} | ${r.total} | ${r.pass} | ${r.fail} | ${r.skip} |`),
    `| **Tổng Playwright** | - | **${pwSum.total}** | **${pwSum.pass}** | **${pwSum.fail}** | **${pwSum.skip}** |`,
    '',
    '### 2. Native Test Suites (JUnit + Flutter Test)',
    '| Suite | Tổng | PASS | FAIL | SKIPPED |',
    '|---|---:|---:|---:|---:|',
    ...nativeRows.map((r) => `| ${r.label} | ${r.total} | ${r.pass} | ${r.fail} | ${r.skip} |`),
    `| **Tổng Native** | **${nativeSum.total}** | **${nativeSum.pass}** | **${nativeSum.fail}** | **${nativeSum.skip}** |`,
    '',
    `**Tổng hợp toàn hệ thống:** Tổng=${grandSum.total}, PASS=${grandSum.pass}, FAIL=${grandSum.fail}, SKIPPED=${grandSum.skip}`,
  ];

  const md = `${lines.join('\n')}\n`;
  if (process.env.GITHUB_STEP_SUMMARY) {
    fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, md, 'utf8');
  }
  console.log(md);

  const knownJobFailure = Object.values(jobResults).some((res) => res !== 'unknown' && res !== 'success');
  if (knownJobFailure || grandSum.fail > 0) {
    process.exit(1);
  }
}

main();
