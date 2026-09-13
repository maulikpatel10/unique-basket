import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import type { Store, FulfillmentType } from '../types';
import {
  Search,
  Filter,
  CheckCircle,
  XCircle,
  Eye,
  Store as StoreIcon,
  Truck,
  ChevronLeft,
  ChevronRight,
  ShoppingBag,
  ArrowRight,
  Ban,
  AlertTriangle
} from 'lucide-react';
import {
  getNextOrderAction,
  canCancelOrder,
  formatOrderStatus
} from '../utils/orderWorkflow';

interface OrderSummary {
  id: string;
  orderNumber: string;
  createdAt: string;
  fulfillmentType: FulfillmentType;
  orderStatus: string;
  paymentStatus: string;
  paymentMethod: 'COD' | 'ONLINE';
  subtotal: number;
  deliveryFee: number;
  discount: number;
  total: number;
  user: { id: string; name: string | null; phone: string; email?: string | null };
  store: { id: string; name: string; storeId: string };
}

interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export const Orders: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const isSuperAdmin = user?.role === 'SUPER_ADMIN';

  const [stores, setStores] = useState<Store[]>([]);
  const [selectedStoreId, setSelectedStoreId] = useState('');

  const [orders, setOrders] = useState<OrderSummary[]>([]);
  const [pagination, setPagination] = useState<PaginationMeta>({
    total: 0,
    page: 1,
    limit: 10,
    totalPages: 1,
  });

  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [fulfillmentFilter, setFulfillmentFilter] = useState('ALL');
  const [paymentStatusFilter, setPaymentStatusFilter] = useState('ALL');

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Status transition modal
  const [statusModal, setStatusModal] = useState<{
    isOpen: boolean;
    order: OrderSummary | null;
    nextStatus: string;
    actionLabel: string;
  }>({
    isOpen: false,
    order: null,
    nextStatus: '',
    actionLabel: '',
  });

  // Cancel order modal
  const [cancelModal, setCancelModal] = useState<{
    isOpen: boolean;
    order: OrderSummary | null;
  }>({
    isOpen: false,
    order: null,
  });

  const [submitting, setSubmitting] = useState(false);

  // Toast
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  // Load stores list
  useEffect(() => {
    const fetchStores = async () => {
      try {
        const res = await api.get('/admin/stores');
        const list = res.data.data;
        setStores(list);
        if (isSuperAdmin) {
          setSelectedStoreId('');
        } else {
          setSelectedStoreId(user?.storeId || '');
        }
      } catch (err) {
        console.error('Error fetching stores:', err);
      }
    };
    fetchStores();
  }, [user, isSuperAdmin]);

  const fetchOrders = async (page: number = 1) => {
    try {
      setLoading(true);
      setError(null);
      const params: any = {
        page,
        limit: 10,
      };

      if (selectedStoreId) params.storeId = selectedStoreId;
      if (statusFilter !== 'ALL') params.status = statusFilter;
      if (fulfillmentFilter !== 'ALL') params.fulfillment = fulfillmentFilter;
      if (paymentStatusFilter !== 'ALL') params.paymentStatus = paymentStatusFilter;
      if (searchTerm.trim()) params.search = searchTerm.trim();

      const res = await api.get('/admin/orders', { params });
      
      if (res.data.data.orders) {
        setOrders(res.data.data.orders);
        setPagination(res.data.data.pagination);
      } else {
        setOrders(res.data.data);
        setPagination({ total: res.data.data.length, page: 1, limit: 10, totalPages: 1 });
      }
    } catch (err: any) {
      console.error('Error fetching orders:', err);
      setError(err.response?.data?.message || 'Failed to load orders list.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders(1);
  }, [selectedStoreId, statusFilter, fulfillmentFilter, paymentStatusFilter]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchOrders(1);
  };

  const handleUpdateStatus = async () => {
    if (!statusModal.order || !statusModal.nextStatus) return;
    setSubmitting(true);
    try {
      await api.put(`/admin/orders/${statusModal.order.id}/status`, {
        status: statusModal.nextStatus,
      });

      showToast('success', `Order status updated to ${formatOrderStatus(statusModal.nextStatus)}.`);
      setStatusModal({ isOpen: false, order: null, nextStatus: '', actionLabel: '' });
      fetchOrders(pagination.page);
    } catch (err: any) {
      console.error('Error updating order status:', err);
      showToast('error', err.response?.data?.message || 'Failed to update order status.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleCancelOrder = async () => {
    if (!cancelModal.order) return;
    setSubmitting(true);
    try {
      await api.put(`/admin/orders/${cancelModal.order.id}/status`, {
        status: 'CANCELLED',
      });

      showToast('success', `Order ${cancelModal.order.orderNumber} has been cancelled.`);
      setCancelModal({ isOpen: false, order: null });
      fetchOrders(pagination.page);
    } catch (err: any) {
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
          <span className="inline-flex px-2.5 py-0.5 rounded text-[11px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            {formatOrderStatus(status)}
          </span>
        );
      case 'CANCELLED':
        return (
          <span className="inline-flex px-2.5 py-0.5 rounded text-[11px] font-bold bg-red-500/10 text-red-400 border border-red-500/20">
            CANCELLED
          </span>
        );
      case 'OUT_FOR_DELIVERY':
        return (
          <span className="inline-flex px-2.5 py-0.5 rounded text-[11px] font-bold bg-orange-500/10 text-orange-400 border border-orange-500/20">
            OUT FOR DELIVERY
          </span>
        );
      case 'READY_FOR_PICKUP':
        return (
          <span className="inline-flex px-2.5 py-0.5 rounded text-[11px] font-bold bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
            READY FOR PICKUP
          </span>
        );
      case 'PREPARING':
        return (
          <span className="inline-flex px-2.5 py-0.5 rounded text-[11px] font-bold bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
            PREPARING
          </span>
        );
      case 'CONFIRMED':
        return (
          <span className="inline-flex px-2.5 py-0.5 rounded text-[11px] font-bold bg-sky-500/10 text-sky-400 border border-sky-500/20">
            CONFIRMED
          </span>
        );
      case 'PLACED':
      default:
        return (
          <span className="inline-flex px-2.5 py-0.5 rounded text-[11px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
            PLACED
          </span>
        );
    }
  };

  const getPaymentStatusBadge = (status: string) => {
    switch (status) {
      case 'PAID':
        return (
          <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            PAID
          </span>
        );
      case 'FAILED':
        return (
          <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-red-500/10 text-red-400 border border-red-500/20">
            FAILED
          </span>
        );
      default:
        return (
          <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
            PENDING
          </span>
        );
    }
  };


  return (
    <div className="relative space-y-6">
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
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white">Order Operations Management</h2>
          <p className="text-slate-400 text-sm mt-1">
            Track customer orders, status transitions, and store fulfillments.
          </p>
        </div>

        {/* Store Selector */}
        {isSuperAdmin ? (
          <div className="flex items-center gap-3 bg-darkbg-800 border border-slate-700/50 rounded-lg px-4 py-2 text-sm shadow-md">
            <StoreIcon className="h-4.5 w-4.5 text-brand-400" />
            <span className="text-slate-300 font-semibold shrink-0">Store Scope:</span>
            <select
              value={selectedStoreId}
              onChange={(e) => setSelectedStoreId(e.target.value)}
              className="rounded bg-slate-900 border border-slate-700 text-slate-200 px-2.5 py-1.5 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="">All Outlet Stores</option>
              {stores.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name} ({s.storeId})
                </option>
              ))}
            </select>
          </div>
        ) : (
          <div className="flex items-center gap-2.5 bg-darkbg-800 border border-slate-700/40 rounded-lg px-4 py-2.5 text-xs text-slate-400 font-semibold shadow-md">
            <StoreIcon className="h-4 w-4 text-brand-400" />
            <span>Outlet Scope:</span>
            <strong className="text-slate-200 uppercase">
              {stores.find((s) => s.id === selectedStoreId)?.name || 'Assigned Store'}
            </strong>
          </div>
        )}
      </div>

      {/* Filters Bar */}
      <div className="flex flex-col md:flex-row gap-4 bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl shadow-md">
        <form onSubmit={handleSearchSubmit} className="relative flex-1">
          <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
            <Search className="h-4 w-4" />
          </span>
          <input
            type="text"
            placeholder="Search by order #, customer name, or phone..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
          />
        </form>

        <div className="flex flex-wrap gap-3 items-center">
          <div className="flex items-center gap-2">
            <Filter className="h-4 w-4 text-slate-400" />
            <select
              value={fulfillmentFilter}
              onChange={(e) => setFulfillmentFilter(e.target.value)}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="ALL">All Types</option>
              <option value="DELIVERY">Delivery Only</option>
              <option value="PICKUP">Store Pickup Only</option>
            </select>
          </div>

          <div>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="ALL">All Order Statuses</option>
              <option value="PLACED">Placed</option>
              <option value="CONFIRMED">Confirmed</option>
              <option value="PREPARING">Preparing</option>
              <option value="READY_FOR_PICKUP">Ready for Pickup</option>
              <option value="OUT_FOR_DELIVERY">Out for Delivery</option>
              <option value="DELIVERED">Delivered</option>
              <option value="PICKED_UP">Picked Up</option>
              <option value="CANCELLED">Cancelled</option>
            </select>
          </div>

          <div>
            <select
              value={paymentStatusFilter}
              onChange={(e) => setPaymentStatusFilter(e.target.value)}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="ALL">All Payment Statuses</option>
              <option value="PENDING">Pending</option>
              <option value="PAID">Paid</option>
              <option value="FAILED">Failed</option>
            </select>
          </div>
        </div>
      </div>

      {/* Orders Table */}
      {loading ? (
        <div className="space-y-4">
          <div className="h-10 bg-slate-800 rounded-lg animate-pulse"></div>
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-16 bg-slate-800/60 rounded-lg animate-pulse"></div>
          ))}
        </div>
      ) : error ? (
        <div className="text-center py-12 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-red-400 text-sm font-semibold">{error}</p>
          <button
            onClick={() => fetchOrders(1)}
            className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
          >
            Retry
          </button>
        </div>
      ) : orders.length === 0 ? (
        <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <ShoppingBag className="h-10 w-10 text-slate-600 mx-auto mb-3" />
          <p className="text-slate-400 text-sm font-medium">No orders found matching your filter selection.</p>
        </div>
      ) : (
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 overflow-hidden shadow-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-6 py-4">Order # & Date</th>
                  <th className="px-6 py-4">Customer</th>
                  <th className="px-6 py-4">Assigned Store</th>
                  <th className="px-6 py-4">Fulfillment</th>
                  <th className="px-6 py-4">Order Status</th>
                  <th className="px-6 py-4">Payment Status</th>
                  <th className="px-6 py-4 text-right">Total Amount</th>
                  <th className="px-6 py-4 text-left min-w-[210px] sm:min-w-[230px]">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {orders.map((o) => {
                  const nextAction = getNextOrderAction(o.orderStatus, o.fulfillmentType);
                  const isCancelable = canCancelOrder(o.orderStatus);

                  return (
                    <tr key={o.id} className="hover:bg-slate-800/10 transition-colors">
                      <td className="px-6 py-4">
                        <div>
                          <p className="font-mono font-bold text-white tracking-wide">{o.orderNumber}</p>
                          <p className="text-[10px] font-mono text-slate-400">
                            {new Date(o.createdAt).toLocaleDateString('en-IN', {
                              day: '2-digit',
                              month: 'short',
                              hour: '2-digit',
                              minute: '2-digit',
                            })}
                          </p>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div>
                          <p className="font-bold text-slate-200">{o.user.name || 'Customer'}</p>
                          <p className="text-xs font-mono text-slate-400">{o.user.phone}</p>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-xs font-semibold text-slate-300">
                        {o.store.name} ({o.store.storeId})
                      </td>
                      <td className="px-6 py-4">
                        <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-slate-300">
                          {o.fulfillmentType === 'DELIVERY' ? (
                            <Truck className="h-3.5 w-3.5 text-sky-400" />
                          ) : (
                            <StoreIcon className="h-3.5 w-3.5 text-amber-400" />
                          )}
                          <span>{o.fulfillmentType}</span>
                        </span>
                      </td>
                      <td className="px-6 py-4">{getOrderStatusBadge(o.orderStatus)}</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-1.5">
                          {getPaymentStatusBadge(o.paymentStatus)}
                          <span className="text-[10px] font-mono text-slate-500 uppercase">({o.paymentMethod})</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-right font-mono font-bold text-emerald-400">
                        ₹{Number(o.total).toFixed(2)}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          {/* View Order Details Icon Button */}
                          <button
                            onClick={() => navigate(`/admin/orders/${o.id}`)}
                            title="View Order"
                            aria-label="View Order"
                            className="h-9 w-9 shrink-0 flex items-center justify-center rounded-lg bg-slate-900/80 border border-slate-700/80 hover:bg-slate-800 hover:border-slate-600 text-slate-400 hover:text-white transition-all shadow-xs focus:outline-none focus:ring-2 focus:ring-brand-500/30"
                          >
                            <Eye className="h-4 w-4" />
                          </button>

                          {/* Contextual Next Step Action Button or Terminal State Pill */}
                          {nextAction ? (
                            <button
                              onClick={() =>
                                setStatusModal({
                                  isOpen: true,
                                  order: o,
                                  nextStatus: nextAction.nextStatus,
                                  actionLabel: nextAction.actionLabel,
                                })
                              }
                              className="h-9 px-3 flex-1 min-w-[125px] flex items-center justify-between gap-2 rounded-lg text-xs font-semibold bg-brand-500/15 text-brand-400 border border-brand-500/30 hover:bg-brand-500/25 active:bg-brand-500/30 focus:outline-none focus:ring-2 focus:ring-brand-500/40 transition-all shadow-xs"
                            >
                              <span className="whitespace-nowrap">{nextAction.actionLabel}</span>
                              <ArrowRight className="h-3.5 w-3.5 shrink-0 opacity-80" />
                            </button>
                          ) : (
                            <div
                              className={`h-9 px-3 flex-1 min-w-[110px] flex items-center justify-center rounded-lg text-xs font-semibold border cursor-default select-none transition-colors ${
                                o.orderStatus === 'CANCELLED'
                                  ? 'text-red-400/80 bg-slate-900/60 border-red-500/20'
                                  : 'text-emerald-400/80 bg-slate-900/60 border-emerald-500/20'
                              }`}
                            >
                              <span>{o.orderStatus === 'CANCELLED' ? 'Cancelled' : 'Completed'}</span>
                            </div>
                          )}

                          {/* Separate Cancellation Action Button */}
                          {isCancelable && (
                            <button
                              onClick={() => setCancelModal({ isOpen: true, order: o })}
                              title="Cancel Order"
                              aria-label="Cancel Order"
                              className="h-9 w-9 shrink-0 flex items-center justify-center rounded-lg bg-slate-900/80 border border-slate-700/80 text-slate-400 hover:text-red-400 hover:bg-red-500/10 hover:border-red-500/30 transition-all shadow-xs focus:outline-none focus:ring-2 focus:ring-red-500/30"
                            >
                              <Ban className="h-3.5 w-3.5" />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Pagination Controls */}
          <div className="flex items-center justify-between px-6 py-4 bg-slate-900/40 border-t border-slate-800 text-xs text-slate-400">
            <div>
              Showing page <strong className="text-slate-200">{pagination.page}</strong> of{' '}
              <strong className="text-slate-200">{pagination.totalPages}</strong> ({pagination.total} total orders)
            </div>

            <div className="flex items-center gap-2">
              <button
                disabled={pagination.page <= 1}
                onClick={() => fetchOrders(pagination.page - 1)}
                className="p-1.5 rounded bg-slate-800 hover:bg-slate-750 text-slate-300 disabled:opacity-40"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <button
                disabled={pagination.page >= pagination.totalPages}
                onClick={() => fetchOrders(pagination.page + 1)}
                className="p-1.5 rounded bg-slate-800 hover:bg-slate-750 text-slate-300 disabled:opacity-40"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Status Transition Confirmation Modal */}
      {statusModal.isOpen && statusModal.order && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div
            className="fixed inset-0 bg-black/60 backdrop-blur-xs"
            onClick={() => setStatusModal({ isOpen: false, order: null, nextStatus: '', actionLabel: '' })}
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
                <span className="font-mono font-bold text-white">{statusModal.order.orderNumber}</span>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Fulfillment:</span>
                <span className="font-semibold text-slate-200">{statusModal.order.fulfillmentType}</span>
              </div>
              <div className="border-t border-slate-800 pt-2 flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Current Status:</span>
                {getOrderStatusBadge(statusModal.order.orderStatus)}
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
                onClick={() => setStatusModal({ isOpen: false, order: null, nextStatus: '', actionLabel: '' })}
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
      {cancelModal.isOpen && cancelModal.order && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div
            className="fixed inset-0 bg-black/60 backdrop-blur-xs"
            onClick={() => setCancelModal({ isOpen: false, order: null })}
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
                <span className="font-mono font-bold text-white">{cancelModal.order.orderNumber}</span>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Current Status:</span>
                {getOrderStatusBadge(cancelModal.order.orderStatus)}
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400 font-semibold">Customer:</span>
                <span className="font-bold text-slate-200">{cancelModal.order.user.name || 'Customer'}</span>
              </div>
            </div>

            <div className="p-3 bg-red-950/30 border border-red-500/20 rounded-xl text-red-400 text-xs font-semibold leading-relaxed">
              ⚠️ Cancelling this order will automatically restore product inventory stock to the assigned outlet store.
            </div>

            <div className="flex gap-3 pt-1">
              <button
                type="button"
                onClick={() => setCancelModal({ isOpen: false, order: null })}
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
