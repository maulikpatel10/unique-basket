import * as admin from 'firebase-admin';
import dotenv from 'dotenv';
import { prisma } from '../config/db';

dotenv.config();

let firebaseInitialized = false;

// Attempt to initialize Firebase Admin SDK using service account env variable
try {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (serviceAccountJson) {
    const serviceAccount = JSON.parse(serviceAccountJson);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    firebaseInitialized = true;
    console.log('[FIREBASE] Admin SDK initialized successfully.');
  } else {
    console.log('[FIREBASE-MOCK] FIREBASE_SERVICE_ACCOUNT not configured. Falling back to console simulation.');
  }
} catch (error) {
  console.error('[FIREBASE] Error initializing Admin SDK. Falling back to simulation:', error);
}

export class NotificationService {
  /**
   * Send notification to a specific customer's registered devices.
   */
  static async sendToUser(userId: string, title: string, body: string, dataPayload?: Record<string, string>): Promise<void> {
    try {
      const tokens = await prisma.deviceToken.findMany({
        where: { userId },
      });

      if (tokens.length === 0) {
        console.log(`[FCM-MOCK] No registered tokens for user ID: ${userId}. Notifying console: "${title}: ${body}"`);
        return;
      }

      const tokenStrings = tokens.map((t) => t.token);

      if (firebaseInitialized) {
        const messagePayload = {
          notification: { title, body },
          data: dataPayload,
          tokens: tokenStrings,
        };

        const response = await admin.messaging().sendEachForMulticast(messagePayload);
        
        // Clean up invalid or expired tokens returned by FCM
        const tokensToRemove: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const error = resp.error;
            if (
              error?.code === 'messaging/invalid-registration-token' ||
              error?.code === 'messaging/registration-token-not-registered'
            ) {
              tokensToRemove.push(tokenStrings[idx]);
            }
          }
        });

        if (tokensToRemove.length > 0) {
          await prisma.deviceToken.deleteMany({
            where: { token: { in: tokensToRemove } },
          });
          console.log(`[FCM] Cleaned up ${tokensToRemove.length} expired device tokens.`);
        }
      } else {
        console.log(`[FCM-MOCK-DELIVERY] Sent to User: ${userId} (Tokens: ${tokenStrings.length}) - Title: "${title}" | Body: "${body}"`);
      }
    } catch (error) {
      console.error('[FCM] Error sending message to user:', error);
    }
  }

  /**
   * Send notification to all managers assigned to a specific store.
   */
  static async sendToStoreManagers(storeId: string, title: string, body: string, dataPayload?: Record<string, string>): Promise<void> {
    try {
      // Find all managers for this storeId
      const managers = await prisma.storeManager.findMany({
        where: { storeId },
        select: { adminUserId: true },
      });

      const managerIds = managers.map((m) => m.adminUserId);

      if (managerIds.length === 0) {
        console.log(`[FCM-MOCK] No managers assigned to store: ${storeId}`);
        return;
      }

      // Fetch manager device tokens
      const tokens = await prisma.deviceToken.findMany({
        where: { adminUserId: { in: managerIds } },
      });

      if (tokens.length === 0) {
        console.log(`[FCM-MOCK] No tokens for managers of store: ${storeId}. Notifying console: "${title}: ${body}"`);
        return;
      }

      const tokenStrings = tokens.map((t) => t.token);

      if (firebaseInitialized) {
        const messagePayload = {
          notification: { title, body },
          data: dataPayload,
          tokens: tokenStrings,
        };

        const response = await admin.messaging().sendEachForMulticast(messagePayload);
        
        // Prune stale tokens
        const tokensToRemove: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const error = resp.error;
            if (
              error?.code === 'messaging/invalid-registration-token' ||
              error?.code === 'messaging/registration-token-not-registered'
            ) {
              tokensToRemove.push(tokenStrings[idx]);
            }
          }
        });

        if (tokensToRemove.length > 0) {
          await prisma.deviceToken.deleteMany({
            where: { token: { in: tokensToRemove } },
          });
        }
      } else {
        console.log(`[FCM-MOCK-DELIVERY] Sent to Store Managers of ${storeId} (Tokens: ${tokenStrings.length}) - Title: "${title}" | Body: "${body}"`);
      }
    } catch (error) {
      console.error('[FCM] Error sending message to store managers:', error);
    }
  }
}
