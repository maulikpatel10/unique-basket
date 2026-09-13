import Razorpay from 'razorpay';
import dotenv from 'dotenv';

dotenv.config();

const keyId = process.env.RAZORPAY_KEY_ID || 'mock_key_id';
const keySecret = process.env.RAZORPAY_KEY_SECRET || 'mock_key_secret';

let razorpayInstance: any;

// Use mock in test environment or when using mock keys in development
if (process.env.NODE_ENV === 'test' || keyId === 'rzp_test_key_id_mock') {
  console.log('[RAZORPAY-MOCK] Using simulated mock provider.');
  razorpayInstance = {
    orders: {
      create: async (params: { amount: number; currency: string; receipt: string }) => {
        return {
          id: `order_RpMock_${Math.random().toString(36).substring(7)}`,
          entity: 'order',
          amount: params.amount,
          amount_paid: 0,
          amount_due: params.amount,
          currency: params.currency,
          receipt: params.receipt,
          status: 'created',
          attempts: 0,
          created_at: Math.floor(Date.now() / 1000),
        };
      },
    },
  };
} else {
  razorpayInstance = new Razorpay({
    key_id: keyId,
    key_secret: keySecret,
  });
}

export const razorpay = razorpayInstance;
