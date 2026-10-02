import { spawnSync } from 'child_process';
import path from 'path';
import { prisma } from '../src/config/db';

// P0-07: the destructive seed must refuse to run outside development/test.
describe('Seed script guard (P0-07)', () => {
  const backendRoot = path.resolve(__dirname, '..');

  const runSeed = (nodeEnv: string | undefined) => {
    const env: NodeJS.ProcessEnv = { ...process.env };
    if (nodeEnv === undefined) {
      delete env.NODE_ENV;
    } else {
      env.NODE_ENV = nodeEnv;
    }
    return spawnSync('npx', ['tsx', 'prisma/seed.ts'], {
      cwd: backendRoot,
      env,
      encoding: 'utf-8',
      timeout: 60000,
    });
  };

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it.each([['production'], [undefined], ['staging']])(
    'refuses to run and leaves data untouched when NODE_ENV is %s',
    async (nodeEnv) => {
      const adminsBefore = await prisma.adminUser.count();
      const storesBefore = await prisma.store.count();
      const ordersBefore = await prisma.order.count();

      const result = runSeed(nodeEnv);

      expect(result.status).toBe(1);
      expect(result.stderr).toContain('[seed] Refusing to run');
      expect(result.stdout).not.toContain('Cleared existing records');

      expect(await prisma.adminUser.count()).toBe(adminsBefore);
      expect(await prisma.store.count()).toBe(storesBefore);
      expect(await prisma.order.count()).toBe(ordersBefore);
    },
    90000
  );
});
