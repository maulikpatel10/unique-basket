import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import type { Store } from '../types';
import {
  Search,
  Filter,
  Eye,
  Store as StoreIcon,
  ChevronLeft,
  ChevronRight,
  CreditCard,
  Banknote,
  ShoppingBag
} from 'lucide-react';

interface PaymentRow {
  id: string;
  orderNumber: string;
  createdAt: string;
  updatedAt: string;
  fulfillmentType: 'DELIVERY' | 'PICKUP';
  paymentMethod: 'COD' | 'ONLINE';
  paymentStatus: string;
  orderStatus: string;
  total: string;
  user: { id: string; name: string | null; phone: string; email?: string | null };
  store: { id: string; name: string; storeId: string };
  payments: { id: string; razorpayOrderId: string; razorpayPaymentId: string | null; amount: string; status: string }[];
}

interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export const Payments: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const isSuperAdmin = user?.role === 'SUPER_ADMIN';

  const [stores, setStores] = useState<Store[]>([]);
  const [selectedStoreId, setSelectedStoreId] = useState('');

  const [payments, setPayments] = useState<PaymentRow[]>([]);
  const [pagination, setPagination] = useState<PaginationMeta>({ total: 0, page: 1, limit: 10, totalPages: 1 });

  const [searchTerm, setSearchTerm] = useState('');
  const [methodFilter, setMethodFilter] = useState('ALL');
  const [statusFilter, setStatusFilter] = useState('ALL');

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);


  useEffect(() => {
    const fetchStores = async () => {
      try {
        const res = await api.get('/admin/stores');
        setStores(res.data.data);
        if (isSuperAdmin) {
          setSelectedStoreId('');
        } else {
          setSelectedStoreId(user?.storeId || '');
        }
      } catch (e) {
        console.error('Stores fetch error:', e);
      }
    };
    fetchStores();
  }, [user, isSuperAdmin]);

  const fetchPayments = async (page = 1) => {
    try {
      setLoading(true);
      setError(null);
      const params: any = { page, limit: 10 };
      if (selectedStoreId) params.storeId = selectedStoreId;
      if (methodFilter !== 'ALL') params.paymentMethod = methodFilter;
      if (statusFilter !== 'ALL') params.paymentStatus = statusFilter;
      if (searchTerm.trim()) params.search = searchTerm.trim();

      const res = await api.get('/admin/payments', { params });
      setPayments(res.data.data.payments);
      setPagination(res.data.data.pagination);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load payments.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPayments(1);
  }, [selectedStoreId, methodFilter, statusFilter]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchPayments(1);
  };

  const getPaymentStatusBadge = (status: string) => {
    switch (status) {
      case 'PAID':
        return <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">PAID</span>;
      case 'FAILED':
        return <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-red-500/10 text-red-400 border border-red-500/20">FAILED</span>;
      default:
        return <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">PENDING</span>;
    }
  };

  const getMethodBadge = (method: string) => {
    if (method === 'COD') {
      return (
        <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-bold bg-orange-500/10 text-orange-400 border border-orange-500/20">
          <Banknote className="h-3 w-3" />COD
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-bold bg-sky-500/10 text-sky-400 border border-sky-500/20">
        <CreditCard className="h-3 w-3" />ONLINE
      </span>
    );
  };

  return (
    <div className="relative space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white">Payment & COD Management</h2>
          <p className="text-slate-400 text-sm mt-1">Monitor payment records, Razorpay transactions, and COD collection status.</p>
        </div>

        {isSuperAdmin ? (
          <div className="flex items-center gap-3 bg-darkbg-800 border border-slate-700/50 rounded-lg px-4 py-2 text-sm shadow-md">
            <StoreIcon className="h-4 w-4 text-brand-400" />
            <span className="text-slate-300 font-semibold shrink-0">Store Scope:</span>
            <select
              value={selectedStoreId}
              onChange={(e) => setSelectedStoreId(e.target.value)}
              className="rounded bg-slate-900 border border-slate-700 text-slate-200 px-2.5 py-1.5 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="">All Outlet Stores</option>
              {stores.map((s) => (
                <option key={s.id} value={s.id}>{s.name} ({s.storeId})</option>
              ))}
            </select>
          </div>
        ) : (
          <div className="flex items-center gap-2.5 bg-darkbg-800 border border-slate-700/40 rounded-lg px-4 py-2.5 text-xs text-slate-400 font-semibold shadow-md">
            <StoreIcon className="h-4 w-4 text-brand-400" />
            <span>Scope:</span>
            <strong className="text-slate-200 uppercase">
              {stores.find((s) => s.id === selectedStoreId)?.name || 'Assigned Store'}
            </strong>
          </div>
        )}
      </div>

      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-4 bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl shadow-md">
        <form onSubmit={handleSearch} className="relative flex-1">
          <span className="absolute inset-y-0 left-3 flex items-center text-slate-400"><Search className="h-4 w-4" /></span>
          <input
            type="text"
            placeholder="Search by order #, customer name, phone, payment ID..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
          />
        </form>

        <div className="flex flex-wrap gap-3 items-center">
          <Filter className="h-4 w-4 text-slate-400" />
          <select
            value={methodFilter}
            onChange={(e) => setMethodFilter(e.target.value)}
            className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
          >
            <option value="ALL">All Methods</option>
            <option value="COD">COD Only</option>
            <option value="ONLINE">Online / Razorpay</option>
          </select>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
          >
            <option value="ALL">All Statuses</option>
            <option value="PENDING">Pending</option>
            <option value="PAID">Paid</option>
            <option value="FAILED">Failed</option>
          </select>
        </div>
      </div>

      {/* COD Info Banner */}
      <div className="flex items-start gap-3 bg-amber-950/20 border border-amber-800/30 rounded-xl p-4 text-xs text-amber-400">
        <Banknote className="h-4 w-4 shrink-0 mt-0.5" />
        <div>
          <p className="font-bold mb-0.5">COD Policy</p>
          <p className="text-amber-500/80">COD orders remain <strong>PENDING</strong> until physical cash collection is confirmed during pickup handover or delivery. COD configuration is managed in <strong>Settings</strong>. Admin cannot manually override Razorpay online payment status.</p>
        </div>
      </div>

      {/* Table */}
      {loading ? (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => <div key={i} className="h-16 bg-slate-800/60 rounded-lg animate-pulse" />)}
        </div>
      ) : error ? (
        <div className="text-center py-12 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-red-400 text-sm font-semibold">{error}</p>
          <button onClick={() => fetchPayments(1)} className="mt-4 rounded-lg bg-slate-700 text-slate-200 px-4 py-2 text-xs font-bold">Retry</button>
        </div>
      ) : payments.length === 0 ? (
        <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <ShoppingBag className="h-10 w-10 text-slate-600 mx-auto mb-3" />
          <p className="text-slate-400 text-sm">No payment records found for the selected filters.</p>
        </div>
      ) : (
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 overflow-hidden shadow-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-5 py-4">Order # & Date</th>
                  <th className="px-5 py-4">Customer</th>
                  <th className="px-5 py-4">Store</th>
                  <th className="px-5 py-4">Method</th>
                  <th className="px-5 py-4">Payment Status</th>
                  <th className="px-5 py-4">Razorpay Payment ID</th>
                  <th className="px-5 py-4 text-right">Amount</th>
                  <th className="px-5 py-4 text-center">Details</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {payments.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-800/10 transition-colors">
                    <td className="px-5 py-4">
                      <p className="font-mono font-bold text-white">{p.orderNumber}</p>
                      <p className="text-[10px] font-mono text-slate-400">
                        {new Date(p.createdAt).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}
                      </p>
                    </td>
                    <td className="px-5 py-4">
                      <p className="font-bold text-slate-200">{p.user.name || 'Customer'}</p>
                      <p className="text-xs font-mono text-slate-400">{p.user.phone}</p>
                    </td>
                    <td className="px-5 py-4 text-xs font-semibold text-slate-300">
                      {p.store.name} <span className="text-slate-500">({p.store.storeId})</span>
                    </td>
                    <td className="px-5 py-4">{getMethodBadge(p.paymentMethod)}</td>
                    <td className="px-5 py-4">{getPaymentStatusBadge(p.paymentStatus)}</td>
                    <td className="px-5 py-4">
                      {p.payments.length > 0 && p.payments[0].razorpayPaymentId ? (
                        <span className="font-mono text-[10px] text-sky-400 select-all">{p.payments[0].razorpayPaymentId}</span>
                      ) : (
                        <span className="text-slate-600 text-xs italic">
                          {p.paymentMethod === 'COD' ? 'Cash on Delivery' : '—'}
                        </span>
                      )}
                    </td>
                    <td className="px-5 py-4 text-right font-mono font-bold text-emerald-400">
                      ₹{Number(p.total).toFixed(2)}
                    </td>
                    <td className="px-5 py-4 text-center">
                      <button
                        onClick={() => navigate(`/admin/payments/${p.id}`)}
                        title="View Payment Details"
                        className="p-1.5 text-slate-400 hover:text-cyan-400 hover:bg-slate-700/50 rounded transition-colors"
                      >
                        <Eye className="h-4 w-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="flex items-center justify-between px-5 py-4 bg-slate-900/40 border-t border-slate-800 text-xs text-slate-400">
            <div>
              Page <strong className="text-slate-200">{pagination.page}</strong> of <strong className="text-slate-200">{pagination.totalPages}</strong> ({pagination.total} records)
            </div>
            <div className="flex items-center gap-2">
              <button disabled={pagination.page <= 1} onClick={() => fetchPayments(pagination.page - 1)} className="p-1.5 rounded bg-slate-800 text-slate-300 disabled:opacity-40">
                <ChevronLeft className="h-4 w-4" />
              </button>
              <button disabled={pagination.page >= pagination.totalPages} onClick={() => fetchPayments(pagination.page + 1)} className="p-1.5 rounded bg-slate-800 text-slate-300 disabled:opacity-40">
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
