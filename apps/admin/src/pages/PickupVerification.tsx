import React, { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { api } from '../services/api';
import {
  QrCode,
  Search,
  CheckCircle,
  XCircle,
  ShoppingBag,
  User,
  Phone,
  IndianRupee,
  RefreshCw,
  AlertCircle
} from 'lucide-react';

interface VerifiedPickupData {
  id: string;
  orderNumber: string;
  customerName: string;
  phone: string;
  items: Array<{
    name: string;
    quantity: number;
    unit: string;
  }>;
  subtotal: number;
  total: number;
  orderStatus: string;
  paymentStatus: string;
}

export const PickupVerification: React.FC = () => {
  const [searchParams] = useSearchParams();
  // Pre-fill when opened from an order's "Verify Pickup" action
  const [orderNumber, setOrderNumber] = useState(searchParams.get('orderNumber') ?? '');
  const [phone, setPhone] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [verifiedOrder, setVerifiedOrder] = useState<VerifiedPickupData | null>(null);

  // Toast
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!orderNumber.trim() || !phone.trim()) {
      setError('Both Order Number and Customer Mobile Number are required.');
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const res = await api.post('/admin/orders/pickup-verify', {
        orderNumber: orderNumber.trim(),
        phone: phone.trim(),
      });

      setVerifiedOrder(res.data.data);
      showToast('success', res.data.message || 'Order successfully verified and handed over!');
    } catch (err: any) {
      console.error('Error verifying pickup order:', err);
      const errMsg =
        err.response?.data?.message ||
        'Failed to verify pickup order. Please check the details and try again.';
      setError(errMsg);
      showToast('error', errMsg);
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setOrderNumber('');
    setPhone('');
    setError(null);
    setVerifiedOrder(null);
  };

  return (
    <div className="relative space-y-6 max-w-4xl mx-auto">
      {/* Toast Alert */}
      {toast && (
        <div
          className={`fixed top-4 right-4 z-50 flex items-center gap-3 rounded-lg px-5 py-3 shadow-lg border text-sm font-semibold transition-all duration-300 ${
            toast.type === 'success'
              ? 'bg-emerald-950/90 text-emerald-400 border-emerald-500/30'
              : 'bg-red-950/90 text-red-400 border-red-500/30'
          }`}
        >
          {toast.type === 'success' ? <CheckCircle className="h-5 w-5" /> : <XCircle className="h-5 w-5" />}
          <span>{toast.message}</span>
        </div>
      )}

      {/* Page Header */}
      <div>
        <h2 className="text-2xl font-bold text-white flex items-center gap-2.5">
          <QrCode className="h-6 w-6 text-brand-400" />
          <span>Store Pickup Handover & Verification</span>
        </h2>
        <p className="text-slate-400 text-sm mt-1">
          Verify pickup orders using the Order Number and customer registered mobile number before handover.
        </p>
      </div>

      {/* Verification Form Card */}
      {!verifiedOrder ? (
        <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 sm:p-8 shadow-md space-y-6">
          <form onSubmit={handleVerify} className="space-y-5">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-2">
                  Order Number <span className="text-red-400">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <Search className="h-4 w-4" />
                  </span>
                  <input
                    type="text"
                    required
                    placeholder="e.g. UB-20260825-001"
                    value={orderNumber}
                    onChange={(e) => setOrderNumber(e.target.value)}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm font-mono focus:border-brand-500 outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-2">
                  Registered Mobile Number <span className="text-red-400">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <Phone className="h-4 w-4" />
                  </span>
                  <input
                    type="text"
                    required
                    placeholder="e.g. +919999999999 or 9876543210"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm font-mono focus:border-brand-500 outline-none"
                  />
                </div>
              </div>
            </div>

            {error && (
              <div className="flex items-center gap-2.5 p-3 rounded-lg bg-red-950/40 border border-red-500/30 text-red-400 text-xs font-semibold">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <div className="flex justify-end pt-2">
              <button
                type="submit"
                disabled={loading || !orderNumber.trim() || !phone.trim()}
                className="flex items-center justify-center gap-2 rounded-lg bg-brand-500 hover:bg-brand-600 text-white px-6 py-2.5 text-xs font-bold transition-colors disabled:opacity-50"
              >
                {loading ? (
                  <>
                    <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                    <span>Verifying Pickup...</span>
                  </>
                ) : (
                  <>
                    <CheckCircle className="h-4 w-4" />
                    <span>Verify & Handover</span>
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      ) : (
        /* Verified Handover Order Summary Card */
        <div className="space-y-6">
          <div className="bg-darkbg-800 border border-emerald-500/30 rounded-2xl p-6 sm:p-8 shadow-md space-y-6">
            <div className="flex items-center gap-3 p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-xl text-emerald-400 font-bold text-sm">
              <CheckCircle className="h-5 w-5 shrink-0" />
              <span>Handover Verified — Order status marked as PICKED UP and payment recorded as PAID.</span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
              <div className="bg-slate-900/60 border border-slate-700/50 p-4 rounded-xl">
                <span className="text-[10px] font-bold uppercase text-slate-400">Order Number</span>
                <p className="text-base font-mono font-bold text-white mt-1">{verifiedOrder.orderNumber}</p>
              </div>

              <div className="bg-slate-900/60 border border-slate-700/50 p-4 rounded-xl">
                <span className="text-[10px] font-bold uppercase text-slate-400">Customer</span>
                <p className="text-sm font-bold text-slate-200 mt-1 flex items-center gap-1.5">
                  <User className="h-3.5 w-3.5 text-slate-400" />
                  <span>{verifiedOrder.customerName}</span>
                </p>
                <p className="text-xs font-mono text-slate-400 mt-0.5">{verifiedOrder.phone}</p>
              </div>

              <div className="bg-slate-900/60 border border-slate-700/50 p-4 rounded-xl">
                <span className="text-[10px] font-bold uppercase text-slate-400">Status</span>
                <div className="mt-1 flex items-center gap-1.5">
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                    {verifiedOrder.orderStatus}
                  </span>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                    {verifiedOrder.paymentStatus}
                  </span>
                </div>
              </div>

              <div className="bg-slate-900/60 border border-slate-700/50 p-4 rounded-xl">
                <span className="text-[10px] font-bold uppercase text-slate-400">Total Amount</span>
                <p className="text-base font-mono font-bold text-emerald-400 mt-1 flex items-center gap-0.5">
                  <IndianRupee className="h-4 w-4" />
                  <span>{verifiedOrder.total.toFixed(2)}</span>
                </p>
              </div>
            </div>

            {/* Items List */}
            <div className="space-y-3">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-300 flex items-center gap-2">
                <ShoppingBag className="h-4 w-4 text-brand-400" />
                <span>Handover Items Checklist</span>
              </h4>

              <div className="overflow-x-auto rounded-xl border border-slate-700/50">
                <table className="w-full text-left text-sm text-slate-300">
                  <thead className="bg-slate-900/50 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                    <tr>
                      <th className="px-5 py-3">Product Name</th>
                      <th className="px-5 py-3 text-center">Unit</th>
                      <th className="px-5 py-3 text-right">Quantity</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800">
                    {verifiedOrder.items.map((item, idx) => (
                      <tr key={idx} className="hover:bg-slate-800/10">
                        <td className="px-5 py-3 font-bold text-white">{item.name}</td>
                        <td className="px-5 py-3 text-center text-xs font-semibold text-slate-400">{item.unit}</td>
                        <td className="px-5 py-3 text-right font-mono font-bold text-slate-100">{item.quantity}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="flex justify-end pt-2">
              <button
                type="button"
                onClick={handleReset}
                className="flex items-center gap-2 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-5 py-2.5 text-xs font-bold transition-colors"
              >
                <RefreshCw className="h-4 w-4" />
                <span>Verify Another Pickup</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
