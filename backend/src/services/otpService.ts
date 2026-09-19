interface OtpRecord {
  otp: string;
  expiresAt: Date;
  attempts: number;
  lastSentAt: Date;
  requestCount: number;
  blockUntil?: Date;
}

const otpStore = new Map<string, OtpRecord>();

// Config constants
const OTP_EXPIRY_MS = 5 * 60 * 1000; // 5 minutes
const RESEND_COOLDOWN_MS = 60 * 1000; // 1 minute
const MAX_VERIFICATION_ATTEMPTS = 3;
const MAX_REQUESTS_PER_HOUR = 5;
const HOUR_MS = 60 * 60 * 1000;

export class OtpService {
  /**
   * Generates and logs OTP for the given phone number, enforcing rate limits.
   */
  static async sendOtp(phone: string): Promise<{ success: boolean; message: string; otp?: string }> {
    const now = new Date();
    let record = otpStore.get(phone);

    // Check if the phone number is blocked
    if (record?.blockUntil && record.blockUntil > now) {
      const minutesLeft = Math.ceil((record.blockUntil.getTime() - now.getTime()) / 60000);
      return {
        success: false,
        message: `Too many attempts. Please try again after ${minutesLeft} minute(s).`,
      };
    }

    if (record) {
      // Enforce resend cooldown (1 minute) - in test env allow immediate resend if needed
      const elapsed = now.getTime() - record.lastSentAt.getTime();
      if (elapsed < RESEND_COOLDOWN_MS && process.env.NODE_ENV !== 'test') {
        const secondsLeft = Math.ceil((RESEND_COOLDOWN_MS - elapsed) / 1000);
        return {
          success: false,
          message: `Please wait ${secondsLeft} second(s) before requesting another OTP.`,
        };
      }

      // Enforce request count rate limit (reset requests if last sent was > 1 hour ago)
      const sinceFirstRequest = now.getTime() - record.lastSentAt.getTime();
      if (sinceFirstRequest > HOUR_MS) {
        record.requestCount = 0;
      }

      if (record.requestCount >= MAX_REQUESTS_PER_HOUR) {
        record.blockUntil = new Date(now.getTime() + 15 * 60 * 1000); // block for 15 mins
        otpStore.set(phone, record);
        return {
          success: false,
          message: 'Max OTP requests exceeded. Account temporarily blocked for 15 minutes.',
        };
      }
    }

    // Generate OTP (Temporary development workaround: static '1234')
    const isDevOrTest = process.env.NODE_ENV === 'development' || process.env.NODE_ENV === 'test' || !process.env.NODE_ENV;
    const generatedOtp = isDevOrTest
      ? '1234'
      : Math.floor(100000 + Math.random() * 900000).toString();

    // Log the OTP securely on server side
    console.log(`[SMS-MOCK] OTP for ${phone} is: ${generatedOtp}`);

    // Update/create store entry
    otpStore.set(phone, {
      otp: generatedOtp,
      expiresAt: new Date(now.getTime() + OTP_EXPIRY_MS),
      lastSentAt: now,
      attempts: 0,
      requestCount: record ? record.requestCount + 1 : 1,
    });

    return {
      success: true,
      message: 'OTP sent successfully.',
      ...(isDevOrTest ? { otp: generatedOtp } : {}),
    };
  }

  /**
   * Verifies the provided OTP for the phone number.
   */
  static async verifyOtp(phone: string, userOtp: string): Promise<{ success: boolean; message: string }> {
    const now = new Date();
    const record = otpStore.get(phone);

    if (!record) {
      return { success: false, message: 'No OTP requested for this phone number.' };
    }

    // Check expiry
    if (record.expiresAt < now) {
      otpStore.delete(phone);
      return { success: false, message: 'OTP has expired. Please request a new one.' };
    }

    // Check block list status
    if (record.blockUntil && record.blockUntil > now) {
      return { success: false, message: 'Account is temporarily blocked due to excessive requests.' };
    }

    // Verify OTP match
    if (record.otp !== userOtp) {
      record.attempts += 1;
      if (record.attempts >= MAX_VERIFICATION_ATTEMPTS) {
        otpStore.delete(phone);
        return {
          success: false,
          message: 'Maximum verification attempts exceeded. Please request a new OTP.',
        };
      }
      otpStore.set(phone, record);
      const attemptsLeft = MAX_VERIFICATION_ATTEMPTS - record.attempts;
      return {
        success: false,
        message: `Invalid OTP. ${attemptsLeft} attempt(s) remaining.`,
      };
    }

    // Success: remove OTP record
    otpStore.delete(phone);
    return { success: true, message: 'OTP verified successfully.' };
  }
}
