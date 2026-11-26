import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json; charset=utf-8',
};

export function startStaticSpaServer({ rootDir, port, host = '127.0.0.1' }) {
  const resolvedRoot = path.resolve(rootDir);
  const indexHtml = path.join(resolvedRoot, 'index.html');

  if (!fs.existsSync(indexHtml)) {
    throw new Error(`Không tìm thấy ${indexHtml}. Cần build Flutter Web trước khi khởi chạy server.`);
  }

  const server = http.createServer((req, res) => {
    const method = req.method || 'GET';
    if (method !== 'GET' && method !== 'HEAD') {
      res.writeHead(405, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Method Not Allowed');
      return;
    }

    const reqUrl = new URL(req.url || '/', `http://${host}:${port}`);
    const pathname = decodeURIComponent(reqUrl.pathname);

    if (pathname === '/__pw_health') {
      res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('OK');
      return;
    }

    const relPath = pathname.replace(/^\/+/, '');
    const candidate = path.resolve(resolvedRoot, relPath || 'index.html');

    if (!candidate.startsWith(resolvedRoot)) {
      res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Forbidden');
      return;
    }

    let targetFile = null;
    if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) {
      targetFile = candidate;
    } else if (path.extname(pathname) === '') {
      // SPA fallback cho usePathUrlStrategy() (smartspace_admin, smartspace_client)
      targetFile = indexHtml;
    }

    if (!targetFile) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Not Found');
      return;
    }

    const ext = path.extname(targetFile).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': 'no-cache',
    });

    if (method === 'HEAD') {
      res.end();
      return;
    }

    fs.createReadStream(targetFile).pipe(res);
  });

  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, host, () => {
      resolve({
        url: `http://localhost:${port}`,
        close: () =>
          new Promise((resClose) => {
            server.close(() => resClose());
          }),
      });
    });
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const dir = process.argv[2];
  const port = Number(process.argv[3] || 9101);
  if (!dir) {
    console.error('Usage: node static-spa-server.mjs <rootDir> <port>');
    process.exit(1);
  }
  const srv = await startStaticSpaServer({ rootDir: dir, port });
  console.log(`[StaticSPA] Serving ${path.resolve(dir)} at ${srv.url}`);
}
