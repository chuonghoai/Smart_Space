import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {
  ensureBackendReady,
  ensureFlutterWebBuild,
  ensureFlutterWebServer,
  loadPlaywrightEnv,
  ROOT_DIR,
} from '../helpers/service-manager.mjs';
import { validateRegionSmpGrep } from '../helpers/smp-registry.mjs';

const VALID_REGIONS = new Set(['backend', 'admin', 'staff', 'client', 'all']);

function normalizeExtraArgs(rawArgs) {
  const args = [...rawArgs];
  const hasGrep = args.some((a) => a === '--grep' || a === '-g' || a.startsWith('--grep=') || a.startsWith('-g='));
  if (!hasGrep && process.env.npm_config_grep) {
    args.push('--grep', process.env.npm_config_grep);
  }
  return args;
}

function runPlaywrightProject(region, extraArgs) {
  return new Promise((resolve) => {
    const pwCli = path.join(ROOT_DIR, 'node_modules', '@playwright', 'test', 'cli.js');
    const child = spawn(
      process.execPath,
      [pwCli, 'test', `--project=${region}`, ...extraArgs],
      {
        cwd: ROOT_DIR,
        shell: false,
        stdio: ['ignore', 'pipe', 'pipe'],
        env: {
          ...process.env,
          PW_REPORT_REGION: region,
          FORCE_COLOR: '1',
        },
      },
    );

    const writePrefixed = (stream, chunk) => {
      for (const line of chunk.toString('utf8').split(/(?<=\n)/)) {
        stream.write(`[${region}] ${line}`);
      }
    };
    child.stdout.on('data', (c) => writePrefixed(process.stdout, c));
    child.stderr.on('data', (c) => writePrefixed(process.stderr, c));

    child.on('close', (code) => {
      resolve({ region, exitCode: code ?? 1 });
    });
  });
}

function countStatsFromReport(region) {
  const jsonPath = path.join(ROOT_DIR, 'playwright-report', region, 'results.json');
  if (!fs.existsSync(jsonPath)) {
    return { total: 0, passed: 0, failed: 0, skipped: 0, found: false };
  }
  const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  const stats = data.stats || {};
  const passed = Number(stats.expected || 0);
  const failed = Number(stats.unexpected || 0);
  const flaky = Number(stats.flaky || 0);
  const skipped = Number(stats.skipped || 0);
  const total = passed + failed + flaky + skipped;
  return { total, passed: passed + flaky, failed, skipped, found: true };
}

async function main() {
  const region = process.argv[2];
  const extraArgs = normalizeExtraArgs(process.argv.slice(3));

  if (!region || !VALID_REGIONS.has(region)) {
    console.error('Cú pháp: node playwright/scripts/runner.mjs <backend|admin|staff|client|all> [playwright args...]');
    process.exit(1);
  }

  try {
    validateRegionSmpGrep(region, extraArgs);
  } catch (err) {
    console.error(`\n[LỖI] ${err.message}\n`);
    process.exit(1);
  }

  const envConfig = loadPlaywrightEnv();
  const stopHandles = [];
  let cleaned = false;

  const cleanup = async () => {
    if (cleaned) return;
    cleaned = true;
    for (const stopFn of stopHandles.reverse()) {
      try {
        await stopFn();
      } catch (err) {
        console.error('[Runner] Lỗi khi dọn dẹp service:', err.message);
      }
    }
  };

  process.on('SIGINT', async () => {
    await cleanup();
    process.exit(130);
  });
  process.on('SIGTERM', async () => {
    await cleanup();
    process.exit(143);
  });

  try {
    if (process.env.PW_SKIP_SERVICES !== 'true') {
      if (process.env.PW_SKIP_BACKEND !== 'true') {
        const backendHandle = await ensureBackendReady(envConfig);
        stopHandles.push(backendHandle.stop);
      }

      if (region === 'all') {
        // Build tuần tự các web app chưa có build/web để tránh xung đột .dart_tool/mobile_shared
        for (const appRegion of ['admin', 'staff', 'client']) {
          ensureFlutterWebBuild(appRegion, envConfig);
        }
        const servers = await Promise.all([
          ensureFlutterWebServer('admin', envConfig),
          ensureFlutterWebServer('staff', envConfig),
          ensureFlutterWebServer('client', envConfig),
        ]);
        for (const s of servers) stopHandles.push(s.stop);
      } else if (region === 'admin' || region === 'staff' || region === 'client') {
        const webHandle = await ensureFlutterWebServer(region, envConfig);
        stopHandles.push(webHandle.stop);
      }
    }

    if (region === 'all') {
      console.log('\n[Runner] Bắt đầu chạy SONG SONG 4 vùng Playwright (backend, admin, staff, client)...\n');
      const regions = ['backend', 'admin', 'staff', 'client'];
      const settled = await Promise.allSettled(regions.map((r) => runPlaywrightProject(r, extraArgs)));

      console.log('\n==================== TỔNG HỢP KẾT QUẢ PLAYWRIGHT ====================');
      console.log('| Project | Kết quả | Tổng | PASS | FAIL | SKIPPED |');
      console.log('|---|---|---:|---:|---:|---:|');

      let allOk = true;
      let sumTotal = 0;
      let sumPass = 0;
      let sumFail = 0;
      let sumSkip = 0;

      for (let i = 0; i < regions.length; i++) {
        const r = regions[i];
        const res = settled[i];
        const exitCode = res.status === 'fulfilled' ? res.value.exitCode : 1;
        const stats = countStatsFromReport(r);
        const statusLabel = exitCode === 0 ? 'PASS' : 'FAIL';
        if (exitCode !== 0) allOk = false;

        sumTotal += stats.total;
        sumPass += stats.passed;
        sumFail += stats.failed;
        sumSkip += stats.skipped;

        console.log(`| ${r} | ${statusLabel} | ${stats.total} | ${stats.passed} | ${stats.failed} | ${stats.skipped} |`);
      }
      console.log(`| **Tổng** | **${allOk ? 'PASS' : 'FAIL'}** | **${sumTotal}** | **${sumPass}** | **${sumFail}** | **${sumSkip}** |`);
      console.log('=====================================================================\n');

      process.exitCode = allOk ? 0 : 1;
    } else {
      console.log(`\n[Runner] Chạy Playwright vùng "${region}"...\n`);
      const res = await runPlaywrightProject(region, extraArgs);
      const stats = countStatsFromReport(region);
      console.log(
        `\n[Runner] Kết thúc vùng "${region}" (exit=${res.exitCode}) — PASS=${stats.passed}, FAIL=${stats.failed}, SKIPPED=${stats.skipped}`,
      );
      console.log(`[Runner] Báo cáo HTML: playwright-report/${region}/index.html\n`);
      process.exitCode = res.exitCode;
    }
  } finally {
    await cleanup();
  }
}

main().catch((err) => {
  console.error(`\n[LỖI RUNNER] ${err.message}\n`);
  process.exit(1);
});
