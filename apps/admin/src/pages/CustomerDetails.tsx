import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import {
  ArrowLeft,
  Phone,
  MapPin,
  ShoppingBag,
  CheckCircle,
  XCircle,
  IndianRupee,
  Calendar,
  Truck,
  Store as StoreIcon
} from 'lucide-react';

interface CustomerProfile {
  id: string;
  phone: string;
  name: string;
  email: string | null;
  dob?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

interface CustomerStats {
  totalOrders: number;
  completedOrders: number;
  cancelledOrders: number;
  totalSpent: number;
}

interface AddressItem {
  id: string;
  title: string;
  addressLine: string;
  city: string;
  state: string;
  pincode: string;
  latitude: number;
  longitude: number;
  isDefault: boolean;
}

interface OrderHistoryItem {
  id: string;
  orderNumber: string;
  createdAt: string;
  storeName: string;
  storeId: string;
  fulfillmentType: 'DELIVERY' | 'PICKUP';
  orderStatus: string;
  paymentStatus: string;
  total: number;
}

export const CustomerDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [customer, setCustomer] = useState<CustomerProfile | null>(null);
  const [stats, setStats] = useState<CustomerStats | null>(null);
  const [addresses, setAddresses] = useState<AddressItem[]>([]);
  const [orders, setOrders] = useState<OrderHistoryItem[]>([]);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchCustomerDetails = async () => {
      if (!id) return;
      try {
        setLoading(true);
        setError(null);
        const res = await api.get(`/admin/customers/${id}`);
        const data = res.data.data;
        setCustomer(data.customer);
        setStats(data.stats);
        setAddresses(data.addresses);
        setOrders(data.orders);
      } catch (err: any) {
        console.error('Error fetching customer details:', err);
        setError(err.response?.data?.message || 'Failed to load customer profile details.');
      } finally {
        setLoading(false);
      }
    };

    fetchCustomerDetails();
  }, [id]);

  const getOrderStatusBadge = (status: string) => {
    switch (status) {
      case 'DELIVERED':
      case 'PICKED_UP':
        return (
          <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            {status === 'PICKED_UP' ? 'PICKED UP' : 'DELIVERED'}
          </span>
        );
      case 'CANCELLED':
        return (
          <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-red-500/10 text-red-400 border border-red-500/20">
            CANCELLED
          </span>
        );
      case 'OUT_FOR_DELIVERY':
        return (
          <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-orange-500/10 text-orange-400 border border-orange-500/20">
            OUT FOR DELIVERY
          </span>
        );
      case 'READY_FOR_PICKUP':
        return (
          <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
            READY FOR PICKUP
          </span>
        );
      case 'PREPARING':
        return (
          <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
            PREPARING
          </span>
        );
      case 'CONFIRMED':
        return (
          <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-sky-500/10 text-sky-400 border border-sky-500/20">
            CONFIRMED
          </span>
        );
      case 'PLACED':
      default:
        return (
          <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
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

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-8 w-40 bg-slate-800 rounded animate-pulse"></div>
        <div className="h-32 bg-slate-800 rounded-xl animate-pulse"></div>
        <div className="grid grid-cols-4 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-24 bg-slate-800 rounded-xl animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  if (error || !customer) {
    return (
      <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
        <p className="text-red-400 text-sm font-semibold">{error || 'Customer not found.'}</p>
        <button
          onClick={() => navigate('/admin/customers')}
          className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
        >
          Return to Customers
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Back Button */}
      <button
        onClick={() => navigate('/admin/customers')}
        className="flex items-center gap-2 text-xs font-bold text-slate-400 hover:text-white transition-colors"
      >
        <ArrowLeft className="h-4 w-4" />
        <span>Back to Customer List</span>
      </button>

      {/* Customer Header Card */}
      <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 shadow-md flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div className="flex items-start gap-4">
          <div className="h-14 w-14 rounded-2xl bg-brand-500/10 border border-brand-500/20 flex items-center justify-center text-brand-400 font-bold text-xl shrink-0">
            {customer.name.charAt(0).toUpperCase()}
          </div>
          <div>
            <div className="flex items-center gap-3">
              <h2 className="text-xl font-bold text-white">{customer.name}</h2>
              <span
                className={`px-2 py-0.5 rounded text-[10px] font-bold border ${
                  customer.isActive
                    ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                    : 'bg-red-500/10 text-red-400 border-red-500/20'
                }`}
              >
                {customer.isActive ? 'ACTIVE ACCOUNT' : 'DEACTIVATED'}
              </span>
            </div>
            <div className="flex flex-wrap items-center gap-4 mt-2 text-xs text-slate-400 font-medium">
              <span className="flex items-center gap-1.5 bg-slate-900/60 px-2.5 py-1 rounded-lg border border-slate-700/50">
                <Phone className="h-3.5 w-3.5 text-brand-400" />
                <strong className="text-white font-mono text-sm">{customer.phone}</strong>
              </span>
              <span className="flex items-center gap-1.5">
                <Calendar className="h-3.5 w-3.5 text-slate-500" />
                <span>Joined {new Date(customer.createdAt).toLocaleDateString('en-IN')}</span>
              </span>
              {customer.dob && (
                <span className="flex items-center gap-1.5">
                  <Calendar className="h-3.5 w-3.5 text-brand-400" />
                  <span>DOB: {new Date(customer.dob).toLocaleDateString('en-IN', { timeZone: 'UTC', day: '2-digit', month: 'short', year: 'numeric' })}</span>
                </span>
              )}
            </div>
          </div>
        </div>

        <div className="text-xs text-slate-500 font-mono self-start md:self-auto">
          Customer ID: <span className="text-slate-300 select-all">{customer.id}</span>
        </div>
      </div>

      {/* Stats Overview Grid */}
      {stats && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl">
            <div className="flex items-center justify-between text-slate-400 mb-2">
              <span className="text-xs font-semibold uppercase tracking-wider">Total Orders</span>
              <ShoppingBag className="h-4 w-4 text-brand-400" />
            </div>
            <p className="text-2xl font-bold text-white">{stats.totalOrders}</p>
          </div>

          <div className="bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl">
            <div className="flex items-center justify-between text-slate-400 mb-2">
              <span className="text-xs font-semibold uppercase tracking-wider">Completed</span>
              <CheckCircle className="h-4 w-4 text-emerald-400" />
            </div>
            <p className="text-2xl font-bold text-emerald-400">{stats.completedOrders}</p>
          </div>

          <div className="bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl">
            <div className="flex items-center justify-between text-slate-400 mb-2">
              <span className="text-xs font-semibold uppercase tracking-wider">Cancelled</span>
              <XCircle className="h-4 w-4 text-red-400" />
            </div>
            <p className="text-2xl font-bold text-red-400">{stats.cancelledOrders}</p>
          </div>

          <div className="bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl">
            <div className="flex items-center justify-between text-slate-400 mb-2">
              <span className="text-xs font-semibold uppercase tracking-wider">Lifetime Spend</span>
              <IndianRupee className="h-4 w-4 text-emerald-400" />
            </div>
            <p className="text-2xl font-mono font-bold text-emerald-400">
              ₹{stats.totalSpent.toLocaleString('en-IN')}
            </p>
          </div>
        </div>
      )}

      {/* Customer Stored Delivery Addresses */}
      <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 shadow-md space-y-4">
        <h3 className="text-base font-bold text-white flex items-center gap-2">
          <MapPin className="h-4.5 w-4.5 text-brand-400" />
          <span>Saved Customer Addresses</span>
        </h3>

        {addresses.length === 0 ? (
          <p className="text-xs text-slate-400 py-4 italic">No saved delivery addresses found.</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {addresses.map((addr) => (
              <div
                key={addr.id}
                className="bg-slate-900/60 border border-slate-700/40 rounded-xl p-4 space-y-1.5 relative"
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-white uppercase tracking-wider">{addr.title}</span>
                  {addr.isDefault && (
                    <span className="px-2 py-0.5 rounded text-[9px] font-bold bg-brand-500/10 text-brand-400 border border-brand-500/20">
                      DEFAULT
                    </span>
                  )}
                </div>
                <p className="text-xs text-slate-300 leading-relaxed">{addr.addressLine}</p>
                <p className="text-xs text-slate-400">
                  {addr.city}, {addr.state} - {addr.pincode}
                </p>
                <p className="text-[10px] font-mono text-slate-500 pt-1">
                  Coords: {addr.latitude}, {addr.longitude}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Historical Orders List */}
      <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 shadow-md space-y-4">
        <h3 className="text-base font-bold text-white flex items-center gap-2">
          <ShoppingBag className="h-4.5 w-4.5 text-brand-400" />
          <span>Historical Customer Orders</span>
        </h3>

        {orders.length === 0 ? (
          <p className="text-xs text-slate-400 py-6 text-center">This customer has not placed any orders yet.</p>
        ) : (
          <div className="overflow-x-auto rounded-xl border border-slate-700/50">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/50 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-5 py-3">Order Number</th>
                  <th className="px-5 py-3">Date</th>
                  <th className="px-5 py-3">Fulfillment</th>
                  <th className="px-5 py-3">Assigned Store</th>
                  <th className="px-5 py-3">Order Status</th>
                  <th className="px-5 py-3">Payment Status</th>
                  <th className="px-5 py-3 text-right">Total Amount</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {orders.map((o) => (
                  <tr key={o.id} className="hover:bg-slate-800/10">
                    <td className="px-5 py-3 font-mono font-bold text-slate-100">{o.orderNumber}</td>
                    <td className="px-5 py-3 font-mono text-xs text-slate-400">
                      {new Date(o.createdAt).toLocaleDateString('en-IN', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                      })}
                    </td>
                    <td className="px-5 py-3">
                      <span className="inline-flex items-center gap-1 text-xs font-semibold text-slate-300">
                        {o.fulfillmentType === 'DELIVERY' ? (
                          <Truck className="h-3.5 w-3.5 text-sky-400" />
                        ) : (
                          <StoreIcon className="h-3.5 w-3.5 text-amber-400" />
                        )}
                        <span>{o.fulfillmentType}</span>
                      </span>
                    </td>
                    <td className="px-5 py-3 text-xs text-slate-400">{o.storeName}</td>
                    <td className="px-5 py-3">{getOrderStatusBadge(o.orderStatus)}</td>
                    <td className="px-5 py-3">{getPaymentStatusBadge(o.paymentStatus)}</td>
                    <td className="px-5 py-3 text-right font-mono font-bold text-emerald-400">
                      ₹{o.total.toFixed(2)}
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
