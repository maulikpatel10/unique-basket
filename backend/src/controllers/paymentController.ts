import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { OrderStatus, PaymentStatus } from '@prisma/client';
import { NotificationService } from '../services/notificationService';

export class PaymentController {
  /**
   * Cryptographic server-side verification of Razorpay payments.
   */
  static async verifyPayment(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

      if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
        res.status(400).json({
          success: false,
          message: 'Missing verification parameters (order_id, payment_id, signature).',
          errorCode: 'MISSING_PAYMENT_PARAMETERS',
        });
        return;
      }

      const keySecret = process.env.RAZORPAY_KEY_SECRET || 'mock_key_secret';

      // Verify Razorpay signature mathematically
      const body = razorpay_order_id + '|' + razorpay_payment_id;
      const expectedSignature = crypto
        .createHmac('sha256', keySecret)
        .update(body.toString())
        .digest('hex');

      const bufferExpected = Buffer.from(expectedSignature);
      const bufferReceived = Buffer.from(razorpay_signature);

      if (bufferExpected.length !== bufferReceived.length) {
        res.status(400).json({
          success: false,
          message: 'Payment verification failed. Cryptographic signature mismatch.',
          errorCode: 'PAYMENT_SIGNATURE_INVALID',
        });
        return;
      }

      const isVerified = crypto.timingSafeEqual(bufferExpected, bufferReceived);

      if (!isVerified) {
        res.status(400).json({
          success: false,
          message: 'Payment verification failed. Cryptographic signature mismatch.',
          errorCode: 'PAYMENT_SIGNATURE_INVALID',
        });
        return;
      }

      // Start transaction to update payment & order status
      const order = await prisma.$transaction(async (tx) => {
        // Find payment record
        const payment = await tx.payment.findUnique({
          where: { razorpayOrderId: razorpay_order_id },
        });

        if (!payment) {
          throw new Error('PAYMENT_RECORD_NOT_FOUND');
        }

        // Update payment record
        await tx.payment.update({
          where: { id: payment.id },
          data: {
            razorpayPaymentId: razorpay_payment_id,
            razorpaySignature: razorpay_signature,
            status: 'captured',
          },
        });

        // Update order status to PAID and CONFIRMED
        const orderUpdate = await tx.order.update({
          where: { id: payment.orderId },
          data: {
            paymentStatus: PaymentStatus.PAID,
            orderStatus: OrderStatus.CONFIRMED,
            updatedAt: new Date(),
          },
        });

        // Write Audit Log
        await tx.auditLog.create({
          data: {
            action: 'PAYMENT_VERIFIED_ONLINE',
            details: `Online payment successfully verified for order number: ${orderUpdate.orderNumber}. Payment ID: ${razorpay_payment_id}`,
          },
        });

        return orderUpdate;
      });

      // Asynchronously trigger customer notification on payment verification
      NotificationService.sendToUser(
        order.userId,
        'Order Confirmed',
        `Your payment for order ${order.orderNumber} is verified and your order is confirmed.`,
        { orderId: order.id, status: 'CONFIRMED' }
      ).catch((err) => console.error('Error sending payment confirmation notification to customer:', err));

      res.status(200).json({
        success: true,
        message: 'Payment verified and order confirmed successfully.',
        data: {
          orderId: order.id,
          orderNumber: order.orderNumber,
          paymentStatus: order.paymentStatus,
          orderStatus: order.orderStatus,
        },
      });
    } catch (error: any) {
      if (error.message === 'PAYMENT_RECORD_NOT_FOUND') {
        res.status(404).json({
          success: false,
          message: 'Payment transaction record not found.',
          errorCode: 'TRANSACTION_NOT_FOUND',
        });
        return;
      }
      next(error);
    }
  }

  /**
   * Handle Razorpay Asynchronous Webhooks.
   */
  static async handleWebhook(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || 'mock_webhook_secret';
      const signature = req.headers['x-razorpay-signature'] as string;

      if (!signature) {
        res.status(400).json({ success: false, message: 'Missing Webhook signature.' });
        return;
      }

      // Verify webhook signature
      const shasum = crypto.createHmac('sha256', webhookSecret);
      shasum.update(JSON.stringify(req.body));
      const digest = shasum.digest('hex');

      const isVerified = crypto.timingSafeEqual(
        Buffer.from(digest),
        Buffer.from(signature)
      );

      if (!isVerified) {
        res.status(400).json({ success: false, message: 'Invalid Webhook signature.' });
        return;
      }

      const event = req.body.event;

      // Handle captured payment events
      if (event === 'payment.captured') {
        const payload = req.body.payload.payment.entity;
        const razorpayOrderId = payload.order_id;
        const razorpayPaymentId = payload.id;

        // Perform identical verification check inside transaction
        const payment = await prisma.payment.findUnique({
          where: { razorpayOrderId },
        });

        if (payment && payment.status !== 'captured') {
          await prisma.$transaction(async (tx) => {
            await tx.payment.update({
              where: { id: payment.id },
              data: {
                razorpayPaymentId,
                status: 'captured',
              },
            });

            await tx.order.update({
              where: { id: payment.orderId },
              data: {
                paymentStatus: PaymentStatus.PAID,
                orderStatus: OrderStatus.CONFIRMED,
                updatedAt: new Date(),
              },
            });

            await tx.auditLog.create({
              data: {
                action: 'WEBHOOK_PAYMENT_CAPTURED',
                details: `Asynchronous payment capture webhook verified for order ID: ${payment.orderId}`,
              },
            });
          });
        }
      }

      if (event === 'payment.failed') {
        const payload = req.body.payload.payment.entity;
        const razorpayOrderId = payload.order_id;
        const razorpayPaymentId = payload.id;

        const payment = await prisma.payment.findUnique({
          where: { razorpayOrderId },
        });

        if (payment && payment.status !== 'captured') {
          await prisma.$transaction(async (tx) => {
            await tx.payment.update({
              where: { id: payment.id },
              data: {
                razorpayPaymentId,
                status: 'failed',
              },
            });

            await tx.order.update({
              where: { id: payment.orderId },
              data: {
                paymentStatus: PaymentStatus.FAILED,
                updatedAt: new Date(),
              },
            });

            await tx.auditLog.create({
              data: {
                action: 'WEBHOOK_PAYMENT_FAILED',
                details: `Asynchronous payment failure webhook verified for order ID: ${payment.orderId}`,
              },
            });
          });
        }
      }

      // Return standard success to Razorpay gateway
      res.status(200).json({ status: 'ok' });
    } catch (error) {
      next(error);
    }
  }
}
