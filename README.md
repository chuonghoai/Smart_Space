# SmartSpace

## Prerequisites

- Node.js
- npm
- Flutter
- Java
- Maven

> Note: npm chỉ được sử dụng làm task runner ở root monorepo. npm không thay thế Flutter hoặc Maven.

## Development Commands

Root `package.json` được sử dụng làm command runner cho monorepo.

### Xem toàn bộ command khả dụng

```bash
npm run help
```

### Chạy Development

- **Chạy Backend (Spring Boot):**
  ```bash
  npm run backend:dev
  ```

- **Chạy Client (Flutter):**
  ```bash
  npm run client:dev
  ```

- **Chạy Admin (Flutter):**
  ```bash
  npm run admin:dev
  ```

- **Chạy Staff (Flutter):**
  ```bash
  npm run staff:dev
  ```

Các lệnh tương tự cho việc test, build và analyze cũng có sẵn. Chạy `npm run help` để xem danh sách chi tiết.
