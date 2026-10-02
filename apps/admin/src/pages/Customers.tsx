import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import { useAuth } from '../context/authContextStore';
import {
  Search,
  Filter,
  ArrowUpDown,
  CheckCircle,
  XCircle,
  Eye,
  ChevronLeft,
  ChevronRight,
  User,
  ShoppingBag
} from 'lucide-react';
import { asApiError } from '../utils/apiError';

interface CustomerSummary {
  id: string;
  phone: string;
  name: string;
  email: string | null;
  dob?: string | null;
  gender?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  orderCount: number;
  totalSpent: number;
}

interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export const Customers: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();

  const [customers, setCustomers] = useState<CustomerSummary[]>([]);
  const [pagination, setPagination] = useState<PaginationMeta>({
    total: 0,
    page: 1,
    limit: 10,
    totalPages: 1,
  });

  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL');
  const [sortBy, setSortBy] = useState<'newest' | 'orders_desc' | 'orders_asc' | 'spend_desc' | 'spend_asc'>('newest');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Status toggle confirmation modal
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    customer: CustomerSummary | null;
  }>({
    isOpen: false,
    customer: null,
  });
  const [submitting, setSubmitting] = useState(false);

  // Notification Toast
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const fetchCustomers = async (page: number = 1) => {
    try {
      setLoading(true);
      setError(null);
      const res = await api.get('/admin/customers', {
        params: {
          search: searchTerm.trim(),
          status: statusFilter,
          sortBy,
          page,
          limit: 10,
        },
      });

      setCustomers(res.data.data.customers);
      setPagination(res.data.data.pagination);
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error fetching customers:', err);
      setError(err.response?.data?.message || 'Failed to load customer list.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCustomers(1);
  }, [statusFilter, sortBy]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchCustomers(1);
  };

  const handleToggleStatus = async () => {
    if (!confirmModal.customer) return;
    setSubmitting(true);
    try {
      const targetState = !confirmModal.customer.isActive;
      await api.put(`/admin/customers/${confirmModal.customer.id}/status`, {
        isActive: targetState,
      });

      showToast(
        'success',
        targetState ? 'Customer activated successfully.' : 'Customer deactivated successfully.'
      );
      setConfirmModal({ isOpen: false, customer: null });
      fetchCustomers(pagination.page);
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error toggling customer status:', err);
      showToast('error', err.response?.data?.message || 'Failed to update customer status.');
    } finally {
      setSubmitting(false);
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
          <h2 className="text-2xl font-bold text-white">Registered Customers</h2>
          <p className="text-slate-400 text-sm mt-1">
            Overview of customer profiles, purchase totals, and status management.
          </p>
        </div>
      </div>

      {/* Search & Filter Header */}
      <div className="flex flex-col md:flex-row gap-4 bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl shadow-md">
        <form onSubmit={handleSearchSubmit} className="relative flex-1">
          <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
            <Search className="h-4 w-4" />
          </span>
          <input
            type="text"
            placeholder="Search by customer name, mobile number, or ID..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
          />
        </form>

        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2">
            <Filter className="h-4 w-4 text-slate-400" />
            <span className="text-xs text-slate-400 uppercase font-semibold">Account State:</span>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as typeof statusFilter)}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="ALL">All Customers</option>
              <option value="ACTIVE">Active</option>
              <option value="INACTIVE">Deactivated</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <ArrowUpDown className="h-4 w-4 text-slate-400" />
            <span className="text-xs text-slate-400 uppercase font-semibold">Sort By:</span>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as typeof sortBy)}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="newest">Newest</option>
              <option value="orders_desc">Most Orders</option>
              <option value="orders_asc">Least Orders</option>
              <option value="spend_desc">Highest Spending</option>
              <option value="spend_asc">Lowest Spending</option>
            </select>
          </div>
        </div>
      </div>

      {/* Customer Listing Table */}
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
            onClick={() => fetchCustomers(1)}
            className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
          >
            Retry
          </button>
        </div>
      ) : customers.length === 0 ? (
        <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <User className="h-10 w-10 text-slate-600 mx-auto mb-3" />
          <p className="text-slate-400 text-sm font-medium">No registered customers match your criteria.</p>
        </div>
      ) : (
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 overflow-hidden shadow-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-6 py-4">Customer Name</th>
                  <th className="px-6 py-4">Phone Number</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4 text-center">Total Orders</th>
                  <th className="px-6 py-4 text-right">Lifetime Spend</th>
                  <th className="px-6 py-4">Joined Date</th>
                  <th className="px-6 py-4 text-center">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {customers.map((c) => (
                  <tr key={c.id} className="hover:bg-slate-800/10 transition-colors">
                    <td className="px-6 py-4 font-bold text-white tracking-wide">
                      {c.name}
                    </td>
                    <td className="px-6 py-4 text-xs font-mono text-slate-300">
                      {c.phone}
                    </td>
                    <td className="px-6 py-4">
                      {user?.role === 'SUPER_ADMIN' ? (
                        <button
                          onClick={() => setConfirmModal({ isOpen: true, customer: c })}
                          title={c.isActive ? 'Click to deactivate customer' : 'Click to activate customer'}
                          className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border transition-all duration-200 hover:scale-[1.02] cursor-pointer ${
                            c.isActive
                              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/25'
                              : 'bg-red-500/10 text-red-400 border-red-500/20 hover:bg-red-500/25'
                          }`}
                        >
                          {c.isActive ? 'ACTIVE' : 'INACTIVE'}
                        </button>
                      ) : (
                        <span
                          className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border ${
                            c.isActive
                              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                              : 'bg-red-500/10 text-red-400 border-red-500/20'
                          }`}
                        >
                          {c.isActive ? 'ACTIVE' : 'INACTIVE'}
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-center font-bold text-slate-200">
                      <div className="inline-flex items-center gap-1 bg-slate-900 px-2.5 py-1 rounded border border-slate-700/50 text-xs font-mono">
                        <ShoppingBag className="h-3 w-3 text-slate-400" />
                        <span>{c.orderCount}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-right font-mono font-bold text-emerald-400">
                      ₹{c.totalSpent.toLocaleString('en-IN')}
                    </td>
                    <td className="px-6 py-4 text-xs font-mono text-slate-400">
                      {new Date(c.createdAt).toLocaleDateString('en-IN', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                      })}
                    </td>
                    <td className="px-6 py-4 text-center">
                      <div className="flex items-center justify-center gap-2">
                        <button
                          onClick={() => navigate(`/admin/customers/${c.id}`)}
                          title="View Customer Profile"
                          className="p-1.5 text-slate-400 hover:text-cyan-400 hover:bg-slate-700/50 rounded transition-colors"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination Controls */}
          <div className="flex items-center justify-between px-6 py-4 bg-slate-900/40 border-t border-slate-800 text-xs text-slate-400">
            <div>
              Showing page <strong className="text-slate-200">{pagination.page}</strong> of{' '}
              <strong className="text-slate-200">{pagination.totalPages}</strong> ({pagination.total} total customers)
            </div>

            <div className="flex items-center gap-2">
              <button
                disabled={pagination.page <= 1}
                onClick={() => fetchCustomers(pagination.page - 1)}
                className="p-1.5 rounded bg-slate-800 hover:bg-slate-750 text-slate-300 disabled:opacity-40"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <button
                disabled={pagination.page >= pagination.totalPages}
                onClick={() => fetchCustomers(pagination.page + 1)}
                className="p-1.5 rounded bg-slate-800 hover:bg-slate-750 text-slate-300 disabled:opacity-40"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      {confirmModal.isOpen && confirmModal.customer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setConfirmModal({ isOpen: false, customer: null })} />

          <div className="relative w-full max-w-sm rounded-xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl space-y-4">
            <h3 className="text-base font-bold text-white">
              {confirmModal.customer.isActive ? 'Deactivate Customer Account?' : 'Activate Customer Account?'}
            </h3>

            <p className="text-xs text-slate-400 leading-relaxed">
              {confirmModal.customer.isActive
                ? `Deactivating ${confirmModal.customer.name} (${confirmModal.customer.phone}) will prevent them from initiating new orders or logging in. Existing historical orders will remain intact.`
                : `Activating ${confirmModal.customer.name} (${confirmModal.customer.phone}) will restore their ability to log in and place delivery/pickup orders.`}
            </p>

            <div className="flex gap-3 pt-2">
              <button
                type="button"
                onClick={() => setConfirmModal({ isOpen: false, customer: null })}
                className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-2 text-xs font-bold"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={submitting}
                onClick={handleToggleStatus}
                className={`flex-1 flex items-center justify-center rounded-lg py-2 text-xs font-bold text-white ${
                  confirmModal.customer.isActive
                    ? 'bg-red-600 hover:bg-red-700'
                    : 'bg-emerald-600 hover:bg-emerald-700'
                }`}
              >
                {submitting ? (
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                ) : confirmModal.customer.isActive ? (
                  'Deactivate'
                ) : (
                  'Activate'
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
