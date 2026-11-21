import { execFileSync, execSync, spawn } from 'node:child_process';
import fs from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import dotenv from 'dotenv';
import { startStaticSpaServer } from './static-spa-server.mjs';

export const ROOT_DIR = process.cwd();

export function loadPlaywrightEnv() {
  const envFile = path.join(ROOT_DIR, '.env.playwright');
  if (fs.existsSync(envFile)) {
    dotenv.config({ path: envFile, override: false });
  }
  const backendPort = Number(process.env.PW_BACKEND_PORT || 8989);
  const adminPort = Number(process.env.PW_ADMIN_PORT || 9101);
  const staffPort = Number(process.env.PW_STAFF_PORT || 9102);
  const clientPort = Number(process.env.PW_CLIENT_PORT || 9103);
  return {
    backendPort,
    backendUrl: process.env.PW_BACKEND_URL || `http://localhost:${backendPort}`,
    adminPort,
    adminUrl: process.env.PW_ADMIN_URL || `http://localhost:${adminPort}`,
    staffPort,
    staffUrl: process.env.PW_STAFF_URL || `http://localhost:${staffPort}`,
    clientPort,
    clientUrl: process.env.PW_CLIENT_URL || `http://localhost:${clientPort}`,
  };
}

export const FLUTTER_APP_META = {
  admin: { dir: 'smartspace_admin', envPortKey: 'adminPort', envUrlKey: 'adminUrl' },
  staff: { dir: 'smartspace_staff', envPortKey: 'staffPort', envUrlKey: 'staffUrl' },
  client: { dir: 'smartspace_client', envPortKey: 'clientPort', envUrlKey: 'clientUrl' },
};

async function httpGetStatus(url, timeoutMs = 2000) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: ctrl.signal });
    return res.status;
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

function checkTcpPort(host, port, timeoutMs = 1500) {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    let done = false;
    const finish = (ok) => {
      if (done) return;
      done = true;
      socket.destroy();
      resolve(ok);
    };
    socket.setTimeout(timeoutMs);
    socket.once('connect', () => finish(true));
    socket.once('timeout', () => finish(false));
    socket.once('error', () => finish(false));
    socket.connect(port, host);
  });
}

function runCommandSync(cmd, args, cwd, label) {
  console.log(`[ServiceManager] ${label}: ${cmd} ${args.join(' ')}`);
  if (process.platform === 'win32') {
    const quoted = args.map((a) => {
      const clean = String(a).replace(/"/g, '');
      return /[\s=]/.test(clean) ? `"${clean}"` : clean;
    });
    execSync(`${cmd} ${quoted.join(' ')}`, {
      cwd,
      stdio: 'inherit',
    });
  } else {
    execFileSync(cmd, args, {
      cwd,
      stdio: 'inherit',
      shell: false,
    });
  }
}

export function stopProcessTree(child) {
  if (!child || child.exitCode !== null || !child.pid) return;
  try {
    if (process.platform === 'win32') {
      execFileSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], { stdio: 'ignore' });
    } else {
      process.kill(-child.pid, 'SIGTERM');
    }
  } catch {
    try {
      child.kill('SIGKILL');
    } catch {
      // Ignore already exited process
    }
  }
}

export async function ensureBackendReady(envConfig = loadPlaywrightEnv()) {
  const healthUrl = `${envConfig.backendUrl}/v3/api-docs`;
  const existing = await httpGetStatus(healthUrl);
  if (existing === 200) {
    console.log(`[ServiceManager] Backend đã sẵn sàng tại ${envConfig.backendUrl} (tái sử dụng).`);
    return {
      startedByRunner: false,
      url: envConfig.backendUrl,
      stop: async () => {},
    };
  }

  const backendDir = path.join(ROOT_DIR, 'SmartSpace_Backend');
  const jarPath = path.join(backendDir, 'target', 'SmartSpace-0.0.1-SNAPSHOT.jar');
  const mustBuild = process.env.PW_REBUILD_BACKEND === 'true' || !fs.existsSync(jarPath);

  if (mustBuild) {
    runCommandSync('mvn', ['package', '-DskipTests', '-Dfile.encoding=UTF-8'], backendDir, 'Đóng gói Backend JAR');
  }

  if (!fs.existsSync(jarPath)) {
    throw new Error(`Không tìm thấy file JAR Backend tại ${jarPath}.`);
  }

  // Kiểm tra nhanh cổng MySQL trước khi khởi động Spring Boot
  const dsUrl = process.env.SPRING_DATASOURCE_URL || 'jdbc:mysql://localhost:3306/smart_space';
  const dbMatch = dsUrl.match(/mysql:\/\/([^:/]+):?(\d*)/i);
  if (dbMatch) {
    const dbHost = dbMatch[1];
    const dbPort = Number(dbMatch[2] || 3306);
    const dbOpen = await checkTcpPort(dbHost, dbPort);
    if (!dbOpen) {
      throw new Error(
        `MySQL chưa sẵn sàng tại ${dbHost}:${dbPort}. Hãy khởi động MySQL trước khi chạy test Backend.`,
      );
    }
  }

  console.log(`[ServiceManager] Đang khởi chạy Backend tại ${envConfig.backendUrl}...`);
  const javaChild = spawn(
    'java',
    ['-Xmx512m', '-Dfile.encoding=UTF-8', '-jar', jarPath, `--server.port=${envConfig.backendPort}`],
    {
      cwd: backendDir,
      detached: process.platform !== 'win32',
      stdio: ['ignore', 'pipe', 'pipe'],
      env: { ...process.env },
    },
  );

  const logTail = [];
  const pushLog = (chunk) => {
    for (const line of chunk.toString('utf8').split(/\r?\n/)) {
      if (line.trim()) {
        logTail.push(line);
        if (logTail.length > 80) logTail.shift();
      }
    }
  };
  javaChild.stdout?.on('data', pushLog);
  javaChild.stderr?.on('data', pushLog);

  const deadline = Date.now() + 90_000;
  let ready = false;
  while (Date.now() < deadline) {
    if (javaChild.exitCode !== null) {
      throw new Error(
        `Backend thoát sớm với mã ${javaChild.exitCode}.\nLog gần nhất:\n${logTail.slice(-30).join('\n')}`,
      );
    }
    const status = await httpGetStatus(healthUrl, 1500);
    if (status === 200) {
      ready = true;
      break;
    }
    await new Promise((r) => setTimeout(r, 1000));
  }

  if (!ready) {
    stopProcessTree(javaChild);
    throw new Error(
      `Quá thời gian chờ Backend (${healthUrl}) trong 90 giây.\nLog gần nhất:\n${logTail.slice(-30).join('\n')}`,
    );
  }

  console.log(`[ServiceManager] Backend đã sẵn sàng (${healthUrl} -> 200 OK).`);
  return {
    startedByRunner: true,
    url: envConfig.backendUrl,
    stop: async () => {
      console.log('[ServiceManager] Dừng tiến trình Backend do test runner khởi chạy...');
      stopProcessTree(javaChild);
    },
  };
}

export function ensureFlutterWebBuild(region, envConfig = loadPlaywrightEnv()) {
  const meta = FLUTTER_APP_META[region];
  if (!meta) throw new Error(`Vùng Flutter không hợp lệ: ${region}`);

  const appDir = path.join(ROOT_DIR, meta.dir);
  const indexHtml = path.join(appDir, 'build', 'web', 'index.html');
  const mustBuild = process.env.PW_REBUILD_WEB === 'true' || !fs.existsSync(indexHtml);

  if (!mustBuild) {
    console.log(`[ServiceManager] Đã có bản build Flutter Web cho ${region} (${indexHtml}).`);
    return path.join(appDir, 'build', 'web');
  }

  const dotenvFile = path.join(appDir, '.env');
  if (!fs.existsSync(dotenvFile)) {
    fs.writeFileSync(dotenvFile, 'GOOGLE_CLIENT_ID=\nMAPBOX_ACCESS_TOKEN=\n', 'utf8');
    console.log(`[ServiceManager] Tạo .env placeholder cho ${meta.dir} phục vụ flutter build web.`);
  }

  runCommandSync(
    'flutter',
    ['build', 'web', `--dart-define=API_URL=${envConfig.backendUrl}`],
    appDir,
    `Build Flutter Web (${meta.dir})`,
  );

  if (!fs.existsSync(indexHtml)) {
    throw new Error(`Build Flutter Web cho ${meta.dir} hoàn tất nhưng thiếu ${indexHtml}.`);
  }
  return path.join(appDir, 'build', 'web');
}

export async function ensureFlutterWebServer(region, envConfig = loadPlaywrightEnv()) {
  const meta = FLUTTER_APP_META[region];
  const port = envConfig[meta.envPortKey];
  const url = envConfig[meta.envUrlKey];

  const existing = await httpGetStatus(`${url}/__pw_health`, 1000);
  if (existing === 200) {
    console.log(`[ServiceManager] Flutter Web (${region}) đã chạy tại ${url} (tái sử dụng).`);
    return {
      startedByRunner: false,
      url,
      stop: async () => {},
    };
  }

  const webDir = ensureFlutterWebBuild(region, envConfig);
  const srv = await startStaticSpaServer({ rootDir: webDir, port });
  console.log(`[ServiceManager] Đã bật Flutter Web (${region}) tại ${srv.url}`);
  return {
    startedByRunner: true,
    url: srv.url,
    stop: async () => {
      console.log(`[ServiceManager] Đóng static server Flutter Web (${region})...`);
      await srv.close();
    },
  };
}
