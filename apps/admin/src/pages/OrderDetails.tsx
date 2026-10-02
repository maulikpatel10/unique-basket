import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import type { FulfillmentType } from '../types';
import {
  ArrowLeft,
  ShoppingBag,
  Truck,
  Store as StoreIcon,
  Phone,
  Mail,
  CheckCircle,
  XCircle,
  Calendar,
  User,
  ArrowRight,
  Ban,
  AlertTriangle,
  Check
} from 'lucide-react';
import {
  getNextOrderAction,
  canCancelOrder,
  formatOrderStatus,
  getWorkflowSteps
} from '../utils/orderWorkflow';
import { asApiError } from '../utils/apiError';

interface OrderItemDetail {
  id: string;
  productId: string;
  productName: string;
  unit: string;
  quantity: string;
  unitPrice: string;
  totalPrice: string;
  product?: { name: string; unit: string; imageUrl?: string | null };
}

interface PaymentRecord {
  id: string;
  razorpayOrderId: string;
  razorpayPaymentId: string | null;
  razorpaySignature: string | null;
  amount: string;
  status: string;
  createdAt: string;
}

interface OrderFullDetails {
  id: string;
  orderNumber: string;
  createdAt: string;
  fulfillmentType: FulfillmentType;
  orderStatus: string;
  paymentStatus: string;
  paymentMethod: 'COD' | 'ONLINE';
  subtotal: string;
  deliveryFee: string;
  discount: string;
  total: string;
  user: { id: string; name: string | null; phone: string; email?: string | null };
  store: { id: string; name: string; storeId: string; address: string; phone: string };
  address: {
    id: string;
    title: string;
    addressLine: string;
    city: string;
    state: string;
    pincode: string;
    latitude: string;
    longitude: string;
  } | null;
  items: OrderItemDetail[];
  payments: PaymentRecord[];
}

export const OrderDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [order, setOrder] = useState<OrderFullDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Status transition modal
  const [statusModal, setStatusModal] = useState<{
    isOpen: boolean;
    nextStatus: string;
    actionLabel: string;
  }>({
    isOpen: false,
    nextStatus: '',
    actionLabel: '',
  });

  // Cancel order modal
  const [cancelModal, setCancelModal] = useState<{
    isOpen: boolean;
  }>({
    isOpen: false,
  });

  const [submitting, setSubmitting] = useState(false);

  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const fetchOrderDetails = async () => {
    if (!id) return;
    try {
      setLoading(true);
      setError(null);
      const res = await api.get(`/admin/orders/${id}`);
      setOrder(res.data.data);
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error fetching order details:', err);
      setError(err.response?.data?.message || 'Failed to load order details.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrderDetails();
  }, [id]);

  const handleUpdateStatus = async () => {
    if (!order || !statusModal.nextStatus) return;
    setSubmitting(true);
    try {
      await api.put(`/admin/orders/${order.id}/status`, {
        status: statusModal.nextStatus,
      });

      showToast('success', `Order status updated to ${formatOrderStatus(statusModal.nextStatus)}.`);
      setStatusModal({ isOpen: false, nextStatus: '', actionLabel: '' });
      fetchOrderDetails();
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error updating order status:', err);
      showToast('error', err.response?.data?.message || 'Failed to update order status.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleCancelOrder = async () => {
    if (!order) return;
    setSubmitting(true);
    try {
      await api.put(`/admin/orders/${order.id}/status`, {
        status: 'CANCELLED',
      });

      showToast('success', `Order ${order.orderNumber} has been cancelled.`);
      setCancelModal({ isOpen: false });
      fetchOrderDetails();
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error cancelling order:', err);
      showToast('error', err.response?.data?.message || 'Failed to cancel order.');
    } finally {
      setSubmitting(false);
    }
  };

  const getOrderStatusBadge = (status: string) => {
    switch (status) {
      case 'DELIVERED':
      case 'PICKED_UP':
        return (
          <span className="inline-flex px-2.5 py-1 rounded text-xs font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            {formatOrderStatus(status)}
          </span>
        );
      case 'CANCELLED':
        return (
          <span className="inline-flex px-2.5 py-1 rounded text-xs font-bold bg-red-500/10 text-red-400 border border-red-500/20">
            CANCELLED
          </span>
        );
      case 'OUT_FOR_DELIVERY':
        return (
          <span className="inline-flex px-2.5 py-1 rounded text-xs font-bold bg-orange-500/10 text-orange-400 border border-orange-500/20">
            OUT FOR DELIVERY
          </span>
        );
      case 'READY_FOR_PICKUP':
        return (
          <span className="inline-flex px-2.5 py-1 rounded text-xs font-bold bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
            READY FOR PICKUP
          </span>
        );
      case 'PREPARING':
        return (
          <span className="inline-flex px-2.5 py-1 rounded text-xs font-bold bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
            PREPARING
          </span>
        );
      case 'CONFIRMED':
        return (
          <span className="inline-flex px-2.5 py-1 rounded text-xs font-bold bg-sky-500/10 text-sky-400 border border-sky-500/20">
            CONFIRMED
          </span>
        );
      case 'PLACED':
      default:
        return (
          <span className="inline-flex px-2.5 py-1 rounded text-xs font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
            PLACED
          </span>
        );
    }
  };

  const getPaymentStatusBadge = (status: string) => {
    switch (status) {
      case 'PAID':
        return (
          <span className="inline-flex px-2.5 py-1 rounded text-xs font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            PAID
          </span>
        );
      case 'FAILED':
        return (
          <span className="inline-flex px-2.5 py-1 rounded text-xs font-bold bg-red-500/10 text-red-400 border border-red-500/20">
            FAILED
          </span>
        );
      default:
        return (
          <span className="inline-flex px-2.5 py-1 rounded text-xs font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
            PENDING
          </span>
        );
    }
  };

  const getActionButtonStyle = (variant: 'primary' | 'info' | 'cyan' | 'amber' | 'emerald') => {
    switch (variant) {
      case 'primary':
        return 'bg-brand-500 hover:bg-brand-600 text-white shadow-md shadow-brand-500/20';
      case 'info':
        return 'bg-indigo-600 hover:bg-indigo-700 text-white shadow-md shadow-indigo-500/20';
      case 'cyan':
        return 'bg-cyan-600 hover:bg-cyan-700 text-white shadow-md shadow-cyan-500/20';
      case 'amber':
        return 'bg-amber-600 hover:bg-amber-700 text-white shadow-md shadow-amber-500/20';
      case 'emerald':
        return 'bg-emerald-600 hover:bg-emerald-700 text-white shadow-md shadow-emerald-500/20';
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-8 w-40 bg-slate-800 rounded animate-pulse"></div>
        <div className="h-32 bg-slate-800 rounded-xl animate-pulse"></div>
        <div className="h-64 bg-slate-800 rounded-xl animate-pulse"></div>
      </div>
    );
  }

  if (error || !order) {
    return (
      <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
        <p className="text-red-400 text-sm font-semibold">{error || 'Order not found.'}</p>
        <button
          onClick={() => navigate('/admin/orders')}
          className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
        >
          Return to Orders
        </button>
      </div>
    );
  }

  const nextAction = getNextOrderAction(order.orderStatus, order.fulfillmentType, order.paymentMethod, order.paymentStatus);
  const isCancelable = canCancelOrder(order.orderStatus);
  const workflowSteps = getWorkflowSteps(order.fulfillmentType);
  const currentStepIndex = workflowSteps.indexOf(order.orderStatus as (typeof workflowSteps)[number]);
  const isCancelled = order.orderStatus === 'CANCELLED';

  return (
    <div className="space-y-6">
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

      {/* Back Button */}
      <button
        onClick={() => navigate('/admin/orders')}
        className="flex items-center gap-2 text-xs font-bold text-slate-400 hover:text-white transition-colors"
      >
        <ArrowLeft className="h-4 w-4" />
        <span>Back to Order Operations</span>
      </button>

      {/* Header Card */}
      <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 shadow-md flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <div className="flex flex-wrap items-center gap-3">
            <h2 className="text-xl font-bold font-mono text-white">{order.orderNumber}</h2>
            {getOrderStatusBadge(order.orderStatus)}
            {getPaymentStatusBadge(order.paymentStatus)}
          </div>
          <p className="text-xs text-slate-400 mt-1.5 flex items-center gap-2 font-mono">
            <Calendar className="h-3.5 w-3.5 text-slate-500" />
            <span>Placed on {new Date(order.createdAt).toLocaleString('en-IN')}</span>
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-3">
          {nextAction && (
            <button
              onClick={() =>
                nextAction.requiresPickupVerification
                  ? navigate(`/admin/pickup-verify?orderNumber=${encodeURIComponent(order.orderNumber)}`)
                  : setStatusModal({
                      isOpen: true,
                      nextStatus: nextAction.nextStatus,
                      actionLabel: nextAction.actionLabel,
                    })
              }
              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${getActionButtonStyle(
                nextAction.buttonVariant
              )}`}
            >
              <span>{nextAction.actionLabel}</span>
              <ArrowRight className="h-3.5 w-3.5" />
            </button>
          )}

          {isCancelable && (
            <button
              onClick={() => setCancelModal({ isOpen: true })}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-red-500/10 text-red-400 border border-red-500/25 hover:bg-red-500/20 transition-colors"
            >
              <Ban className="h-3.5 w-3.5" />
              <span>Cancel Order</span>
            </button>
          )}

          {!nextAction && !isCancelable && (
            <span
              className={`px-3 py-1.5 rounded-xl text-xs font-bold border ${
                order.orderStatus === 'CANCELLED'
                  ? 'text-red-400 bg-red-500/10 border-red-500/20'
                  : 'text-emerald-400 bg-emerald-500/10 border-emerald-500/20'
              }`}
            >
              {order.orderStatus === 'CANCELLED' ? 'Cancelled Order' : 'Order Completed'}
            </span>
          )}
        </div>
      </div>

      {/* Order Progress Stepper */}
      <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 shadow-md">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-xs font-bold uppercase tracking-wider text-slate-300 flex items-center gap-2">
            <span>Fulfillment Progress</span>
            <span className="text-[10px] font-semibold text-slate-400 bg-slate-900 border border-slate-700 px-2 py-0.5 rounded">
              {order.fulfillmentType}
            </span>
          </h3>

          {isCancelled && (
            <span className="text-xs font-bold text-red-400 flex items-center gap-1.5 bg-red-500/10 border border-red-500/20 px-2.5 py-1 rounded-lg">
              <Ban className="h-3.5 w-3.5" />
              <span>Order Cancelled</span>
            </span>
          )}
        </div>

        {/* Stepper Track */}
        <div className="relative pt-2 pb-1">
          <div className="grid grid-cols-1 sm:grid-cols-5 md:grid-flow-col md:auto-cols-fr gap-4">
            {workflowSteps.map((step, idx) => {
              const isCompleted = !isCancelled && currentStepIndex > idx;
              const isCurrent = !isCancelled && currentStepIndex === idx;

              return (
                <div key={step} className="relative flex flex-col items-center text-center group">
                  {/* Step Connector Line (for md and larger screens) */}
                  {idx < workflowSteps.length - 1 && (
                    <div
                      className={`hidden md:block absolute top-4 left-1/2 w-full h-0.5 -z-0 transition-colors ${
                        !isCancelled && currentStepIndex > idx ? 'bg-brand-500' : 'bg-slate-700/60'
                      }`}
                    />
                  )}

                  {/* Step Circle Indicator */}
                  <div
                    className={`relative z-10 flex items-center justify-center h-8 w-8 rounded-full font-bold text-xs transition-all ${
                      isCompleted
                        ? 'bg-brand-500 text-slate-950 ring-4 ring-brand-500/20'
                        : isCurrent
                        ? 'bg-slate-900 text-brand-400 border-2 border-brand-500 ring-4 ring-brand-500/30 animate-pulse'
                        : 'bg-slate-900 text-slate-500 border border-slate-700'
                    }`}
                  >
                    {isCompleted ? (
                      <Check className="h-4 w-4 stroke-[3]" />
                    ) : (
                      <span>{idx + 1}</span>
                    )}
                  </div>

                  {/* Step Label */}
                  <div className="mt-2.5 space-y-0.5">
                    <p
                      className={`text-[11px] font-bold tracking-tight uppercase ${
                        isCompleted
                          ? 'text-slate-200'
                          : isCurrent
                          ? 'text-brand-400'
                          : 'text-slate-500'
                      }`}
                    >
                      {formatOrderStatus(step)}
                    </p>
                    <p className="text-[10px] text-slate-500">
                      {isCompleted ? 'Completed' : isCurrent ? 'Active Step' : 'Upcoming'}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Customer & Store Details Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Customer Information */}
        <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 shadow-md space-y-3">
          <h3 className="text-sm font-bold text-slate-300 uppercase tracking-wider flex items-center gap-2">
            <User className="h-4 w-4 text-brand-400" />
            <span>Customer Profile</span>
          </h3>

          <div className="space-y-2 text-xs">
            <p className="font-bold text-white text-sm">{order.user.name || 'Customer'}</p>
            <p className="flex items-center gap-2 text-slate-400">
              <Phone className="h-3.5 w-3.5 text-slate-500" />
              <strong className="text-slate-200 font-mono">{order.user.phone}</strong>
            </p>
            {order.user.email && (
              <p className="flex items-center gap-2 text-slate-400">
                <Mail className="h-3.5 w-3.5 text-slate-500" />
                <span className="text-slate-300">{order.user.email}</span>
              </p>
            )}
          </div>

          {order.fulfillmentType === 'DELIVERY' && order.address && (
            <div className="border-t border-slate-700/50 pt-3 mt-3 space-y-1">
              <p className="text-[10px] font-bold uppercase text-slate-400 tracking-wider">
                Delivery Address ({order.address.title})
              </p>
              <p className="text-xs text-slate-200 leading-relaxed">{order.address.addressLine}</p>
              <p className="text-xs text-slate-400">
                {order.address.city}, {order.address.state} - {order.address.pincode}
              </p>
            </div>
          )}
        </div>

        {/* Store & Fulfillment */}
        <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 shadow-md space-y-3">
          <h3 className="text-sm font-bold text-slate-300 uppercase tracking-wider flex items-center gap-2">
            <StoreIcon className="h-4 w-4 text-brand-400" />
            <span>Assigned Outlet Store</span>
          </h3>

          <div className="space-y-2 text-xs">
            <div className="flex items-center justify-between">
              <p className="font-bold text-white text-sm">{order.store.name}</p>
              <span className="font-mono text-[10px] bg-slate-900 border border-slate-700 px-2 py-0.5 rounded text-slate-300">
                {order.store.storeId}
              </span>
            </div>
            <p className="text-slate-400 leading-relaxed">{order.store.address}</p>
            <p className="flex items-center gap-2 text-slate-400">
              <Phone className="h-3.5 w-3.5 text-slate-500" />
              <span className="font-mono">{order.store.phone}</span>
            </p>
          </div>

          <div className="border-t border-slate-700/50 pt-3 mt-3 flex items-center justify-between text-xs">
            <span className="text-slate-400 font-semibold">Fulfillment Method:</span>
            <span className="font-bold text-white flex items-center gap-1.5">
              {order.fulfillmentType === 'DELIVERY' ? (
                <Truck className="h-4 w-4 text-sky-400" />
              ) : (
                <StoreIcon className="h-4 w-4 text-amber-400" />
              )}
              <span>{order.fulfillmentType}</span>
            </span>
          </div>
        </div>
      </div>

      {/* Order Items Table */}
      <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 shadow-md space-y-4">
        <h3 className="text-sm font-bold text-slate-300 uppercase tracking-wider flex items-center gap-2">
          <ShoppingBag className="h-4 w-4 text-brand-400" />
          <span>Purchased Items Breakdown</span>
        </h3>

        <div className="overflow-x-auto rounded-xl border border-slate-700/50">
          <table className="w-full text-left text-sm text-slate-300">
            <thead className="bg-slate-900/50 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
              <tr>
                <th className="px-5 py-3">Product Name</th>
                <th className="px-5 py-3 text-center">Unit</th>
                <th className="px-5 py-3 text-right">Unit Price</th>
                <th className="px-5 py-3 text-center">Quantity</th>
                <th className="px-5 py-3 text-right">Subtotal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {order.items.map((item) => (
                <tr key={item.id} className="hover:bg-slate-800/10">
                  <td className="px-5 py-3 font-bold text-white">{item.productName}</td>
                  <td className="px-5 py-3 text-center text-xs font-semibold text-slate-400">{item.unit}</td>
                  <td className="px-5 py-3 text-right font-mono">₹{Number(item.unitPrice).toFixed(2)}</td>
                  <td className="px-5 py-3 text-center font-mono font-bold text-slate-200">
                    {Number(item.quantity)}
                  </td>
                  <td className="px-5 py-3 text-right font-mono font-bold text-slate-100">
                    ₹{Number(item.totalPrice).toFixed(2)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Summary Totals & Payment Details */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 border-t border-slate-800 pt-4">
          {/* Payment Info */}
          <div className="space-y-2 text-xs">
            <p className="text-[10px] font-bold uppercase text-slate-400 tracking-wider">Payment Metadata</p>
            <p className="flex items-center justify-between text-slate-300">
              <span>Method:</span>
              <strong className="text-white uppercase font-mono">{order.paymentMethod}</strong>
            </p>
            <p className="flex items-center justify-between text-slate-300">
              <span>Status:</span>
              <span>{getPaymentStatusBadge(order.paymentStatus)}</span>
            </p>

            {order.payments.length > 0 && (
              <div className="bg-slate-900/60 p-3 rounded-lg border border-slate-700/40 space-y-1 mt-2 font-mono">
                <p className="text-[10px] text-slate-400 uppercase font-semibold">Razorpay Transaction</p>
                <p className="text-[11px] text-slate-200">
                  Order ID: <span className="select-all">{order.payments[0].razorpayOrderId}</span>
                </p>
                {order.payments[0].razorpayPaymentId && (
                  <p className="text-[11px] text-emerald-400">
                    Payment ID: <span className="select-all">{order.payments[0].razorpayPaymentId}</span>
                  </p>
                )}
              </div>
            )}
          </div>

          {/* Totals Breakdown */}
          <div className="space-y-2 text-xs text-right">
            <p className="flex justify-between text-slate-400">
              <span>Items Subtotal:</span>
              <span className="font-mono text-slate-200">₹{Number(order.subtotal).toFixed(2)}</span>
            </p>
            <p className="flex justify-between text-slate-400">
              <span>Delivery Fee:</span>
              <span className="font-mono text-slate-200">₹{Number(order.deliveryFee).toFixed(2)}</span>
            </p>
            {Number(order.discount) > 0 && (
              <p className="flex justify-between text-emerald-400 font-semibold">
                <span>Discount Applied:</span>
                <span className="font-mono">-₹{Number(order.discount).toFixed(2)}</span>
              </p>
            )}
            <div className="border-t border-slate-700/50 pt-2 flex justify-between text-sm font-bold text-white">
              <span>Final Total Amount:</span>
              <span className="font-mono text-emerald-400 text-base">₹{Number(order.total).toFixed(2)}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Status Transition Confirmation Modal */}
      {statusModal.isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div
            className="fixed inset-0 bg-black/60 backdrop-blur-xs"
            onClick={() => setStatusModal({ isOpen: false, nextStatus: '', actionLabel: '' })}
          />

          <div className="relative w-full max-w-md rounded-2xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl space-y-5">
            <div>
              <h3 className="text-base font-bold text-white flex items-center gap-2">
                <CheckCircle className="h-5 w-5 text-brand-400" />
                <span>Confirm Order Status Change</span>
              </h3>
              <p className="text-xs text-slate-400 mt-1">
                Advance order to the next step in the fulfillment workflow.
              </p>
            </div>

            <div className="bg-slate-900/70 border border-slate-700/50 rounded-xl p-4 space-y-3">
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Order Number:</span>
                <span className="font-mono font-bold text-white">{order.orderNumber}</span>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Fulfillment:</span>
                <span className="font-semibold text-slate-200">{order.fulfillmentType}</span>
              </div>
              <div className="border-t border-slate-800 pt-2 flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Current Status:</span>
                {getOrderStatusBadge(order.orderStatus)}
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Next Status:</span>
                {getOrderStatusBadge(statusModal.nextStatus)}
              </div>
            </div>

            <p className="text-xs text-slate-300 text-center font-medium">
              Are you sure you want to continue?
            </p>

            <div className="flex gap-3 pt-1">
              <button
                type="button"
                onClick={() => setStatusModal({ isOpen: false, nextStatus: '', actionLabel: '' })}
                className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-2.5 text-xs font-bold transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={submitting}
                onClick={handleUpdateStatus}
                className="flex-1 flex items-center justify-center gap-2 rounded-lg bg-brand-500 hover:bg-brand-600 text-white py-2.5 text-xs font-bold transition-colors disabled:opacity-50"
              >
                {submitting ? (
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                ) : (
                  'Confirm'
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Cancellation Confirmation Modal */}
      {cancelModal.isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div
            className="fixed inset-0 bg-black/60 backdrop-blur-xs"
            onClick={() => setCancelModal({ isOpen: false })}
          />

          <div className="relative w-full max-w-md rounded-2xl bg-darkbg-800 border border-red-500/30 p-6 shadow-2xl space-y-5">
            <div>
              <h3 className="text-base font-bold text-red-400 flex items-center gap-2">
                <AlertTriangle className="h-5 w-5 text-red-400" />
                <span>Cancel Order</span>
              </h3>
              <p className="text-xs text-slate-400 mt-1">
                Are you sure you want to cancel this order?
              </p>
            </div>

            <div className="bg-slate-900/70 border border-slate-700/50 rounded-xl p-4 space-y-2.5">
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Order:</span>
                <span className="font-mono font-bold text-white">{order.orderNumber}</span>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Current Status:</span>
                {getOrderStatusBadge(order.orderStatus)}
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Customer:</span>
                <span className="font-bold text-slate-200">{order.user.name || 'Customer'}</span>
              </div>
            </div>

            <div className="p-3 bg-red-950/30 border border-red-500/20 rounded-xl text-red-400 text-xs font-semibold leading-relaxed">
              ⚠️ Cancelling this order will automatically restore product inventory stock to the assigned outlet store.
            </div>

            <div className="flex gap-3 pt-1">
              <button
                type="button"
                onClick={() => setCancelModal({ isOpen: false })}
                className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-2.5 text-xs font-bold transition-colors"
              >
                Keep Order
              </button>
              <button
                type="button"
                disabled={submitting}
                onClick={handleCancelOrder}
                className="flex-1 flex items-center justify-center gap-2 rounded-lg bg-red-600 hover:bg-red-700 text-white py-2.5 text-xs font-bold transition-colors disabled:opacity-50"
              >
                {submitting ? (
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                ) : (
                  'Cancel Order'
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
