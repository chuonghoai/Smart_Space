import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { ensureBackendReady, loadPlaywrightEnv, ROOT_DIR } from '../helpers/service-manager.mjs';
import { loadSmpRegistry, resolveNativeTestTarget } from '../helpers/smp-registry.mjs';

async function main() {
  const rawId = process.argv[2]?.trim().toUpperCase();
  if (!rawId || !/^SMP-\d{3,}$/.test(rawId)) {
    console.error('Cú pháp: npm run test:smp -- SMP-XXX (ví dụ: npm run test:smp -- SMP-336 hoặc SMP-001)');
    process.exit(1);
  }

  const registry = loadSmpRegistry();
  const entry = registry.get(rawId);
  if (!entry) {
    console.error(`[LỖI] Không tìm thấy mã test case "${rawId}" trong docs/TestCaseList.md.`);
    process.exit(1);
  }

  console.log(`[SMP Runner] ${entry.id}: ${entry.name}`);
  console.log(`  Project : ${entry.project}`);
  console.log(`  Engine  : ${entry.engine}`);
  console.log(`  File    : ${entry.filePath}`);

  if (entry.engine === 'playwright') {
    const res = spawnSync(
      process.execPath,
      [path.join('playwright', 'scripts', 'runner.mjs'), entry.region, '--grep', entry.id],
      { cwd: ROOT_DIR, stdio: 'inherit', shell: false },
    );
    process.exit(res.status ?? 1);
  }

  const target = resolveNativeTestTarget(entry);

  if (target.kind === 'flutter') {
    const appDir = path.join(ROOT_DIR, target.appDir);
    console.log(`[SMP Runner] Thực thi native flutter test: "${target.testName}" trong ${target.appDir}/${target.relTestFile}`);
    let res;
    if (process.platform === 'win32') {
      const safeRegex = target.testName
        .replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        .replace(/["%]/g, '.');
      res = spawnSync(
        `flutter test "${target.relTestFile}" --name "${safeRegex}"`,
        { cwd: appDir, stdio: 'inherit', shell: true },
      );
    } else {
      res = spawnSync(
        'flutter',
        ['test', target.relTestFile, '--plain-name', target.testName],
        { cwd: appDir, stdio: 'inherit', shell: false },
      );
    }
    process.exit(res.status ?? 1);
  }

  if (target.kind === 'junit') {
    const backendDir = path.join(ROOT_DIR, 'SmartSpace_Backend');
    let backendHandle = null;
    try {
      if (target.requiresLiveServer) {
        backendHandle = await ensureBackendReady(loadPlaywrightEnv());
      }
      console.log(`[SMP Runner] Thực thi native JUnit test: ${target.fqcn}#${target.methodName}`);
      const res = process.platform === 'win32'
        ? spawnSync(
            `mvn test "-Dtest=${target.fqcn}#${target.methodName}" "-DfailIfNoTests=true" "-Dfile.encoding=UTF-8"`,
            { cwd: backendDir, stdio: 'inherit', shell: true },
          )
        : spawnSync(
            'mvn',
            ['test', `-Dtest=${target.fqcn}#${target.methodName}`, '-DfailIfNoTests=true', '-Dfile.encoding=UTF-8'],
            { cwd: backendDir, stdio: 'inherit', shell: false },
          );
      process.exitCode = res.status ?? 1;
    } finally {
      if (backendHandle) {
        await backendHandle.stop();
      }
    }
    return;
  }
}

main().catch((err) => {
  console.error(`\n[LỖI SMP RUNNER] ${err.message}\n`);
  process.exit(1);
});
