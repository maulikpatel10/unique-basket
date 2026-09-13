import app from './app';
import { connectDb } from './config/db';

const PORT = process.env.PORT || 5001;

async function bootstrap() {
  // Establish connection to PostgreSQL
  await connectDb();

  // Listen on configured port
  app.listen(PORT, () => {
    console.log(`[server]: UNIQUE BASKET API is running at http://localhost:${PORT}`);
  });
}

bootstrap();
