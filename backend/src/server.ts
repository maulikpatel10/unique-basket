import app from './app';
import { connectDb } from './config/db';
import { validateEnv } from './config/validateEnv';

const PORT = process.env.PORT || 5001;

async function bootstrap() {
  // Refuse to start with missing or insecure secrets
  try {
    validateEnv();
  } catch (error: any) {
    console.error(`[server]: ${error.message}`);
    process.exit(1);
  }

  // Establish connection to PostgreSQL
  await connectDb();

  // Listen on configured port
  app.listen(PORT, () => {
    console.log(`[server]: UNIQUE BASKET API is running at http://localhost:${PORT}`);
  });
}

bootstrap();
