import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../services/api';

import {
  ArrowLeft,
  User,
  Store as StoreIcon,
  MapPin,
  CreditCard,
  Banknote,
  ShoppingBag,
  Clock,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Info,
  ShieldCheck,
  Package,
  Truck,
} from 'lucide-react';

interface PaymentDetail {
  id: string;
  orderNumber: string;
  createdAt: string;
  updatedAt: string;
  fulfillmentType: 'DELIVERY' | 'PICKUP';
  orderStatus: string;
  paymentMethod: 'COD' | 'ONLINE';
  paymentStatus: string;
  subtotal: string;
  deliveryFee: string;
  discount: string;
  total: string;
  isCOD: boolean;
  user: { id: string; name: string | null; phone: string; email?: string | null };
  store: { id: string; name: string; storeId: string; address: string };
  deliveryAddress?: {
    id: string;
    title?: string;
    addressLine: string;
    city: string;
    state: string;
    pincode: string;
  } | null;
  razorpayTransactions: {
    id: string;
    razorpayOrderId: string;
    razorpayPaymentId: string | null;
    amount: string;
    gatewayStatus: string;
    createdAt: string;
  }[];
}

const getPaymentStatusBadge = (status: string) => {
  switch (status) {
    case 'PAID':
      return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"><CheckCircle className="h-3.5 w-3.5" />PAID</span>;
    case 'FAILED':
      return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-red-500/10 text-red-400 border border-red-500/20"><XCircle className="h-3.5 w-3.5" />FAILED</span>;
    default:
      return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20"><Clock className="h-3.5 w-3.5" />PENDING</span>;
  }
};

const formatDate = (iso: string) =>
  new Date(iso).toLocaleString('en-IN', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit', hour12: true
  });

const Section: React.FC<{ title: string; icon: React.ReactNode; children: React.ReactNode }> = ({ title, icon, children }) => (
  <div className="bg-darkbg-800 border border-slate-700/50 rounded-xl overflow-hidden">
    <div className="flex items-center gap-2.5 px-6 py-4 bg-slate-900/40 border-b border-slate-700/50">
      <div className="text-brand-400">{icon}</div>
      <h3 className="text-slate-200 font-bold text-sm uppercase tracking-wider">{title}</h3>
    </div>
    <div className="p-6 space-y-4">{children}</div>
  </div>
);

const Field: React.FC<{ label: string; value: React.ReactNode }> = ({ label, value }) => (
  <div className="flex flex-wrap justify-between gap-3">
    <span className="text-slate-400 text-sm">{label}</span>
    <span className="text-slate-200 text-sm font-semibold text-right">{value}</span>
  </div>
);

export const PaymentDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [detail, setDetail] = useState<PaymentDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchDetail = async () => {
      if (!id) return;
      try {
        setLoading(true);
        setError(null);
        const res = await api.get(`/admin/payments/${id}`);
        setDetail(res.data.data);
      } catch (err: any) {
        if (err.response?.status === 403) {
          setError('Access Denied. You do not have permission to view this payment.');
        } else if (err.response?.status === 404) {
          setError('Payment record not found.');
        } else {
          setError(err.response?.data?.message || 'Failed to load payment details.');
        }
      } finally {
        setLoading(false);
      }
    };
    fetchDetail();
  }, [id]);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-8 w-64 bg-slate-800 rounded-lg animate-pulse" />
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-40 bg-slate-800/60 rounded-xl animate-pulse" />
        ))}
      </div>
    );
  }

  if (error || !detail) {
    return (
      <div className="flex flex-col items-center justify-center py-24 text-center">
        <AlertTriangle className="h-12 w-12 text-red-400 mb-4" />
        <p className="text-slate-400 text-base">{error || 'Payment not found.'}</p>
        <button onClick={() => navigate(-1)} className="mt-6 flex items-center gap-2 text-sm text-slate-400 hover:text-slate-200 transition-colors">
          <ArrowLeft className="h-4 w-4" /> Back to Payments
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Back Button + Header */}
      <div className="flex items-center gap-4">
        <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-sm text-slate-400 hover:text-white transition-colors">
          <ArrowLeft className="h-5 w-5" />
          <span className="font-semibold">Payments</span>
        </button>
        <span className="text-slate-600">/</span>
        <h2 className="text-xl font-bold text-white">Payment Details — <span className="font-mono text-brand-400">{detail.orderNumber}</span></h2>
      </div>

      {/* Summary Strip */}
      <div className="flex flex-wrap gap-4">
        <div className="flex items-center gap-2.5 bg-darkbg-800 border border-slate-700/50 rounded-xl px-4 py-3 shadow">
          <ShoppingBag className="h-4 w-4 text-brand-400" />
          <div>
            <p className="text-xs text-slate-400 font-semibold">Order Status</p>
            <p className="text-sm font-bold text-slate-200">{detail.orderStatus}</p>
          </div>
        </div>
        <div className="flex items-center gap-2.5 bg-darkbg-800 border border-slate-700/50 rounded-xl px-4 py-3 shadow">
          {detail.isCOD ? <Banknote className="h-4 w-4 text-orange-400" /> : <CreditCard className="h-4 w-4 text-sky-400" />}
          <div>
            <p className="text-xs text-slate-400 font-semibold">Payment Method</p>
            <p className="text-sm font-bold text-slate-200">{detail.paymentMethod}</p>
          </div>
        </div>
        <div className="flex items-center gap-2.5 bg-darkbg-800 border border-slate-700/50 rounded-xl px-4 py-3 shadow">
          {detail.fulfillmentType === 'DELIVERY' ? <Truck className="h-4 w-4 text-violet-400" /> : <Package className="h-4 w-4 text-violet-400" />}
          <div>
            <p className="text-xs text-slate-400 font-semibold">Fulfillment</p>
            <p className="text-sm font-bold text-slate-200">{detail.fulfillmentType}</p>
          </div>
        </div>
        <div className="flex items-center gap-2.5 bg-darkbg-800 border border-slate-700/50 rounded-xl px-4 py-3 shadow">
          <span className="font-mono font-bold text-2xl text-emerald-400">₹</span>
          <div>
            <p className="text-xs text-slate-400 font-semibold">Total</p>
            <p className="text-sm font-bold text-emerald-400 font-mono">₹{Number(detail.total).toFixed(2)}</p>
          </div>
        </div>
        <div className="flex items-center gap-2.5 bg-darkbg-800 border border-slate-700/50 rounded-xl px-4 py-3 shadow">
          <div>{getPaymentStatusBadge(detail.paymentStatus)}</div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Order Section */}
        <Section title="Order Information" icon={<ShoppingBag className="h-4 w-4" />}>
          <Field label="Order Number" value={<span className="font-mono">{detail.orderNumber}</span>} />
          <Field label="Order ID" value={<span className="font-mono text-xs text-slate-400 break-all">{detail.id}</span>} />
          <Field label="Order Status" value={<span className="text-slate-200">{detail.orderStatus}</span>} />
          <Field label="Fulfillment Type" value={detail.fulfillmentType} />
          <Field label="Placed At" value={formatDate(detail.createdAt)} />
          <Field label="Last Updated" value={formatDate(detail.updatedAt)} />
        </Section>

        {/* Customer Section */}
        <Section title="Customer" icon={<User className="h-4 w-4" />}>
          <Field label="Name" value={detail.user.name || '—'} />
          <Field label="Phone" value={<span className="font-mono">{detail.user.phone}</span>} />
          <Field label="Email" value={detail.user.email || <span className="italic text-slate-500">Not provided</span>} />
          <Field label="Customer ID" value={<span className="font-mono text-xs text-slate-400 break-all">{detail.user.id}</span>} />
        </Section>

        {/* Store Section */}
        <Section title="Assigned Store" icon={<StoreIcon className="h-4 w-4" />}>
          <Field label="Store Name" value={detail.store.name} />
          <Field label="Store Code" value={<span className="font-mono">{detail.store.storeId}</span>} />
          <Field label="Store ID" value={<span className="font-mono text-xs text-slate-400 break-all">{detail.store.id}</span>} />
          {detail.store.address && <Field label="Address" value={<span className="text-right">{detail.store.address}</span>} />}
        </Section>

        {/* Delivery Address */}
        {detail.fulfillmentType === 'DELIVERY' && detail.deliveryAddress && (
          <Section title="Delivery Address" icon={<MapPin className="h-4 w-4" />}>
            {detail.deliveryAddress.title && <Field label="Address Label" value={detail.deliveryAddress.title} />}
            <Field label="Address" value={detail.deliveryAddress.addressLine} />
            <Field label="City" value={detail.deliveryAddress.city} />
            <Field label="State" value={detail.deliveryAddress.state} />
            <Field label="Pincode" value={<span className="font-mono">{detail.deliveryAddress.pincode}</span>} />
          </Section>
        )}
      </div>

      {/* Payment Section */}
      <Section title="Payment Details" icon={detail.isCOD ? <Banknote className="h-4 w-4" /> : <CreditCard className="h-4 w-4" />}>
        <Field label="Payment Method" value={detail.paymentMethod} />
        <Field label="Payment Status" value={getPaymentStatusBadge(detail.paymentStatus)} />
        <div className="border-t border-slate-700/50 pt-4 space-y-2">
          <div className="flex justify-between text-sm text-slate-400"><span>Subtotal</span><span className="text-slate-200 font-mono">₹{Number(detail.subtotal).toFixed(2)}</span></div>
          <div className="flex justify-between text-sm text-slate-400"><span>Delivery Fee</span><span className="text-slate-200 font-mono">₹{Number(detail.deliveryFee).toFixed(2)}</span></div>
          {Number(detail.discount) > 0 && (
            <div className="flex justify-between text-sm text-slate-400"><span>Discount</span><span className="text-emerald-400 font-mono">−₹{Number(detail.discount).toFixed(2)}</span></div>
          )}
          <div className="flex justify-between text-base font-bold border-t border-slate-700/60 pt-3 mt-2">
            <span className="text-slate-300">Total</span>
            <span className="text-emerald-400 font-mono">₹{Number(detail.total).toFixed(2)}</span>
          </div>
        </div>
      </Section>

      {/* Razorpay Section */}
      {!detail.isCOD && (
        <Section title="Razorpay Transaction" icon={<ShieldCheck className="h-4 w-4" />}>
          {detail.razorpayTransactions.length === 0 ? (
            <div className="flex items-center gap-2 text-amber-400 text-sm">
              <AlertTriangle className="h-4 w-4" />
              No Razorpay transaction record found. Payment may not have been initiated.
            </div>
          ) : (
            detail.razorpayTransactions.map((txn) => (
              <div key={txn.id} className="space-y-3">
                <Field label="Razorpay Order ID" value={<span className="font-mono text-xs text-sky-400 select-all break-all">{txn.razorpayOrderId}</span>} />
                <Field
                  label="Razorpay Payment ID"
                  value={
                    txn.razorpayPaymentId
                      ? <span className="font-mono text-xs text-emerald-400 select-all break-all">{txn.razorpayPaymentId}</span>
                      : <span className="text-slate-500 italic text-xs">Not yet captured</span>
                  }
                />
                <Field label="Gateway Amount" value={<span className="font-mono">₹{Number(txn.amount).toFixed(2)}</span>} />
                <Field label="Gateway Status" value={<span className="uppercase font-mono text-xs text-slate-300">{txn.gatewayStatus}</span>} />
                <Field label="Initiated At" value={formatDate(txn.createdAt)} />
                <div className="flex items-start gap-2 mt-2 bg-emerald-950/30 border border-emerald-700/30 rounded-lg p-3 text-xs text-emerald-400">
                  <ShieldCheck className="h-4 w-4 shrink-0 mt-0.5" />
                  <span>Razorpay signature verification is enforced server-side via HMAC-SHA256. This Admin Panel only displays safe metadata — no private keys or raw signatures are ever exposed.</span>
                </div>
              </div>
            ))
          )}
        </Section>
      )}

      {/* COD Section */}
      {detail.isCOD && (
        <Section title="COD Collection Status" icon={<Banknote className="h-4 w-4" />}>
          <Field label="Collection Method" value="Cash on Delivery" />
          <Field label="Current COD Status" value={getPaymentStatusBadge(detail.paymentStatus)} />
          <Field label="Fulfillment Type" value={detail.fulfillmentType} />
          <div className="flex items-start gap-2 mt-2 bg-amber-950/20 border border-amber-700/30 rounded-lg p-3 text-xs text-amber-400">
            <Info className="h-4 w-4 shrink-0 mt-0.5" />
            <span>
              COD payment status is set to <strong>PAID</strong> only upon successful pickup handover or delivery confirmation — performed by an authorized Store Manager during the physical handover process.
              Admin cannot manually override COD payment status. Razorpay is not used for COD transactions.
            </span>
          </div>
        </Section>
      )}
    </div>
  );
};
