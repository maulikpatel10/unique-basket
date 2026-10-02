import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/authContextStore';
import { api } from '../services/api';
import type { Order } from '../types';
import {
  TrendingUp,
  ShoppingBag,
  Clock,
  Store as StoreIcon,
  AlertCircle
} from 'lucide-react';
import { asApiError } from '../utils/apiError';

export const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const [orders, setOrders] = useState<Order[]>([]);
  const [summary, setSummary] = useState({ totalOrders: 0, pendingOrders: 0, revenue: 0, activeStores: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        setError(null);

        // P2-07: metrics are aggregated server-side (store-isolated for managers)
        const res = await api.get('/admin/dashboard/summary');
        const data = res.data.data;
        setOrders(data.recentOrders ?? []);
        setSummary({
          totalOrders: data.totalOrders ?? 0,
          pendingOrders: data.pendingOrders ?? 0,
          revenue: Number(data.revenue ?? 0),
          activeStores: data.activeStores ?? 0,
        });
      } catch (caught: unknown) {
        const err = asApiError(caught);
        console.error('Failed to load dashboard metrics:', err);
        setError('Failed to load dashboard stats. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, [user]);

  // Metrics from the server-side summary
  const { totalOrders, pendingOrders, revenue } = summary;
  const activeOutletsCount = summary.activeStores;

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(val);
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-8 w-48 bg-slate-800 rounded-lg animate-pulse"></div>
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-32 bg-slate-800 rounded-xl border border-slate-700/50 animate-pulse"></div>
          ))}
        </div>
        <div className="h-64 bg-slate-800 rounded-xl border border-slate-700/50 animate-pulse"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Welcome banner */}
      <div>
        <h2 className="text-2xl font-bold text-white">Welcome Back, {user?.name}!</h2>
        <p className="text-slate-400 text-sm mt-1">
          Here is what's happening at{' '}
          {user?.role === 'SUPER_ADMIN' ? 'all Unique Basket stores' : `your assigned store (Store ID: ${user?.storeId?.slice(0, 8)}...)`}{' '}
          today.
        </p>
      </div>

      {error && (
        <div className="flex items-center gap-2.5 rounded-lg bg-red-500/10 border border-red-500/20 p-4 text-xs text-red-400">
          <AlertCircle className="h-4.5 w-4.5" />
          <p>{error}</p>
        </div>
      )}

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {/* Total Revenue */}
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md hover:border-slate-600/50 transition-all duration-200">
          <div className="flex items-center justify-between">
            <span className="text-slate-400 text-xs font-semibold uppercase tracking-wider">Total Sales</span>
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-500/10 text-brand-500 border border-brand-500/20">
              <TrendingUp className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-4">
            <h3 className="text-2xl font-bold text-white">{formatCurrency(revenue)}</h3>
            <p className="text-[10px] text-brand-400 mt-1">From completed handovers</p>
          </div>
        </div>

        {/* Total Orders */}
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md hover:border-slate-600/50 transition-all duration-200">
          <div className="flex items-center justify-between">
            <span className="text-slate-400 text-xs font-semibold uppercase tracking-wider">Total Orders</span>
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-blue-500/10 text-blue-400 border border-blue-500/20">
              <ShoppingBag className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-4">
            <h3 className="text-2xl font-bold text-white">{totalOrders}</h3>
            <p className="text-[10px] text-slate-400 mt-1">Lifetime orders received</p>
          </div>
        </div>

        {/* Pending Orders */}
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md hover:border-slate-600/50 transition-all duration-200">
          <div className="flex items-center justify-between">
            <span className="text-slate-400 text-xs font-semibold uppercase tracking-wider">Pending Tasks</span>
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-500/10 text-amber-400 border border-amber-500/20">
              <Clock className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-4">
            <h3 className="text-2xl font-bold text-white">{pendingOrders}</h3>
            <p className="text-[10px] text-slate-400 mt-1">Awaiting confirmation/delivery</p>
          </div>
        </div>

        {/* Total Stores (Super Admin) or Status Tag (Store Manager) */}
        {user?.role === 'SUPER_ADMIN' ? (
          <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md hover:border-slate-600/50 transition-all duration-200">
            <div className="flex items-center justify-between">
              <span className="text-slate-400 text-xs font-semibold uppercase tracking-wider">Active Outlets</span>
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-purple-500/10 text-purple-400 border border-purple-500/20">
                <StoreIcon className="h-5 w-5" />
              </div>
            </div>
            <div className="mt-4">
              <h3 className="text-2xl font-bold text-white">{activeOutletsCount}</h3>
              <p className="text-[10px] text-slate-400 mt-1">Registered active stores</p>
            </div>
          </div>
        ) : (
          <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md hover:border-slate-600/50 transition-all duration-200">
            <div className="flex items-center justify-between">
              <span className="text-slate-400 text-xs font-semibold uppercase tracking-wider">Operational Status</span>
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-500/10 text-brand-400 border border-brand-500/20">
                <StoreIcon className="h-5 w-5" />
              </div>
            </div>
            <div className="mt-4">
              <h3 className="text-lg font-bold text-emerald-400">ONLINE & ACTIVE</h3>
              <p className="text-[10px] text-slate-400 mt-1">Store manager controls active</p>
            </div>
          </div>
        )}
      </div>

      {/* Recent Orders List */}
      <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md">
        <h3 className="text-base font-bold text-white mb-4">Recent Orders Activity</h3>

        {orders.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-slate-400 text-sm">No orders recorded yet.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-4 py-3">Order Number</th>
                  <th className="px-4 py-3">Fulfillment</th>
                  <th className="px-4 py-3">Payment Method</th>
                  <th className="px-4 py-3">Amount</th>
                  <th className="px-4 py-3">Order Status</th>
                  <th className="px-4 py-3">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {orders.slice(0, 5).map((order) => (
                  <tr key={order.id} className="hover:bg-slate-800/20">
                    <td className="px-4 py-3.5 font-bold text-white">{order.orderNumber}</td>
                    <td className="px-4 py-3.5">
                      <span
                        className={`inline-flex px-2 py-0.5 rounded text-[10px] font-semibold ${
                          order.fulfillmentType === 'DELIVERY'
                            ? 'bg-blue-500/10 text-blue-400'
                            : 'bg-indigo-500/10 text-indigo-400'
                        }`}
                      >
                        {order.fulfillmentType}
                      </span>
                    </td>
                    <td className="px-4 py-3.5">{order.paymentMethod}</td>
                    <td className="px-4 py-3.5 font-semibold text-white">{formatCurrency(order.total)}</td>
                    <td className="px-4 py-3.5">
                      <span
                        className={`inline-flex px-2 py-0.5 rounded text-[10px] font-semibold ${
                          order.orderStatus === 'DELIVERED' || order.orderStatus === 'PICKED_UP'
                            ? 'bg-emerald-500/10 text-emerald-400'
                            : order.orderStatus === 'CANCELLED'
                            ? 'bg-red-500/10 text-red-400'
                            : 'bg-amber-500/10 text-amber-400'
                        }`}
                      >
                        {order.orderStatus}
                      </span>
                    </td>
                    <td className="px-4 py-3.5 text-xs text-slate-400">
                      {new Date(order.createdAt).toLocaleDateString('en-IN', {
                        day: 'numeric',
                        month: 'short',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};
