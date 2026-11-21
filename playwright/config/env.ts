import fs from 'node:fs';
import path from 'node:path';
import dotenv from 'dotenv';

const envFile = path.resolve(process.cwd(), '.env.playwright');
if (fs.existsSync(envFile)) {
  dotenv.config({ path: envFile, override: false });
}

const backendPort = Number(process.env.PW_BACKEND_PORT || 8989);
const adminPort = Number(process.env.PW_ADMIN_PORT || 9101);
const staffPort = Number(process.env.PW_STAFF_PORT || 9102);
const clientPort = Number(process.env.PW_CLIENT_PORT || 9103);

export type TestRole = 'admin' | 'staff' | 'client';

export interface RoleCredentials {
  email: string;
  password: string;
}

export const PW_ENV = {
  backendPort,
  backendUrl: process.env.PW_BACKEND_URL || `http://localhost:${backendPort}`,
  adminPort,
  adminUrl: process.env.PW_ADMIN_URL || `http://localhost:${adminPort}`,
  staffPort,
  staffUrl: process.env.PW_STAFF_URL || `http://localhost:${staffPort}`,
  clientPort,
  clientUrl: process.env.PW_CLIENT_URL || `http://localhost:${clientPort}`,
  isCI: Boolean(process.env.CI),
  videoMode: process.env.PW_VIDEO === 'true' ? ('retain-on-failure' as const) : ('off' as const),
  getCredentials(role: TestRole): RoleCredentials | null {
    const upper = role.toUpperCase();
    const email = process.env[`PW_${upper}_EMAIL`]?.trim();
    const password = process.env[`PW_${upper}_PASSWORD`]?.trim();
    if (!email || !password) {
      return null;
    }
    return { email, password };
  },
};
