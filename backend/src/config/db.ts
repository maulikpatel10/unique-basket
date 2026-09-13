import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is not set in environment variables');
}

const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);

export const prisma = new PrismaClient({ adapter });

export async function connectDb() {
  try {
    await prisma.$connect();
    console.log('PostgreSQL database connected successfully via Prisma Pg Adapter.');
  } catch (error) {
    console.error('Failed to connect to the database:', error);
    process.exit(1);
  }
}
