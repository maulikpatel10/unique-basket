import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import type { Store, Order } from '../types';
import {
  ArrowLeft,
  Store as StoreIcon,
  MapPin,
  Clock,
  Phone,
  Mail,
  User,
  ShoppingBag,
  TrendingUp,
  AlertCircle,
  Compass
} from 'lucide-react';
import { asApiError } from '../utils/apiError';

interface StoreDetailWithManager extends Store {
  managers?: Array<{
    adminUser: {
      id: string;
      name: string;
      email: string;
    };
  }>;
}

export const StoreDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [store, setStore] = useState<StoreDetailWithManager | null>(null);
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchStoreAndOrders = async () => {
      try {
        setLoading(true);
        setError(null);

        // Fetch store details (backend includes managers)
        const storeRes = await api.get(`/stores/${id}`);
        setStore(storeRes.data.data);

        // Fetch orders to calculate dynamic store performance metrics
        const ordersRes = await api.get('/admin/orders');
        setOrders(ordersRes.data.data);
      } catch (caught: unknown) {
        const err = asApiError(caught);
        console.error('Error loading store details:', err);
        setError('Failed to load store profile details. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    if (id) {
      fetchStoreAndOrders();
    }
  }, [id]);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <div className="h-8 w-8 bg-slate-800 rounded-full animate-pulse"></div>
          <div className="h-8 w-48 bg-slate-800 rounded-lg animate-pulse"></div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="md:col-span-2 h-64 bg-slate-800 rounded-xl animate-pulse"></div>
          <div className="h-64 bg-slate-800 rounded-xl animate-pulse"></div>
        </div>
      </div>
    );
  }

  if (error || !store) {
    return (
      <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl space-y-4">
        <AlertCircle className="h-10 w-10 text-red-400 mx-auto" />
        <p className="text-red-400 text-sm font-semibold">{error || 'Store not found.'}</p>
        <button
          onClick={() => navigate('/admin/stores')}
          className="flex items-center gap-2 mx-auto rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Stores
        </button>
      </div>
    );
  }

  // Filter orders matching this store
  const storeOrders = orders.filter((o) => o.store?.storeId === store.storeId);
  const totalOrders = storeOrders.length;
  const completedOrders = storeOrders.filter((o) => o.orderStatus === 'DELIVERED' || o.orderStatus === 'PICKED_UP');
  const salesRevenue = completedOrders.reduce((sum, o) => sum + Number(o.total), 0);
  const pendingOrders = storeOrders.filter(
    (o) => o.orderStatus === 'PLACED' || o.orderStatus === 'CONFIRMED' || o.orderStatus === 'PREPARING'
  ).length;

  const assignedManager = store.managers?.[0]?.adminUser;

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(val);
  };

  return (
    <div className="space-y-6">
      {/* Header Bar */}
      <div className="flex items-center justify-between border-b border-slate-700 pb-4">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate('/admin/stores')}
            className="rounded-lg p-2 text-slate-400 hover:bg-slate-800 hover:text-white transition-all duration-150"
          >
            <ArrowLeft className="h-5 w-5" />
          </button>
          <div>
            <div className="flex items-center gap-3">
              <h2 className="text-2xl font-bold text-white">{store.name}</h2>
              <span
                className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border ${
                  store.isActive
                    ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                    : 'bg-red-500/10 text-red-400 border-red-500/20'
                }`}
              >
                {store.isActive ? 'ACTIVE' : 'INACTIVE'}
              </span>
            </div>
            <p className="text-slate-400 text-xs mt-1">Branch Store ID: {store.storeId}</p>
          </div>
        </div>
      </div>

      {/* Main Grid Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Side: Store profile information */}
        <div className="lg:col-span-2 space-y-6">
          <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md">
            <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6 flex items-center gap-2">
              <StoreIcon className="h-4.5 w-4.5 text-brand-400" />
              Outlet Profile Information
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="flex gap-3">
                <MapPin className="h-5 w-5 text-slate-400 shrink-0 mt-0.5" />
                <div>
                  <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Street Address</p>
                  <p className="text-sm text-slate-200 mt-1 whitespace-pre-line leading-relaxed">{store.address}</p>
                  <p className="text-xs text-slate-400 mt-0.5">
                    {store.city}, {store.state} - {store.pincode}
                  </p>
                </div>
              </div>

              <div className="flex gap-3">
                <Clock className="h-5 w-5 text-slate-400 shrink-0 mt-0.5" />
                <div>
                  <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Operating Timings</p>
                  <p className="text-sm text-slate-200 mt-1 font-semibold">
                    {store.openingTime} to {store.closingTime}
                  </p>
                  <p className="text-xs text-slate-400 mt-0.5">Local Standard Time</p>
                </div>
              </div>

              <div className="flex gap-3">
                <Phone className="h-5 w-5 text-slate-400 shrink-0 mt-0.5" />
                <div>
                  <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Contact Phone</p>
                  <p className="text-sm text-slate-200 mt-1 font-semibold">{store.phone}</p>
                </div>
              </div>

              <div className="flex gap-3">
                <Mail className="h-5 w-5 text-slate-400 shrink-0 mt-0.5" />
                <div>
                  <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Email Address</p>
                  <p className="text-sm text-slate-200 mt-1">{store.email || 'No email recorded'}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Location & Delivery radius */}
          <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md">
            <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6 flex items-center gap-2">
              <Compass className="h-4.5 w-4.5 text-brand-400" />
              Geolocation & Delivery Coverage
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
              <div className="bg-slate-900/40 border border-slate-700/30 rounded-lg p-4">
                <p className="text-[9px] text-slate-400 uppercase font-bold tracking-wider">Latitude</p>
                <p className="text-base font-bold text-white mt-1 font-mono">{Number(store.latitude)}</p>
              </div>

              <div className="bg-slate-900/40 border border-slate-700/30 rounded-lg p-4">
                <p className="text-[9px] text-slate-400 uppercase font-bold tracking-wider">Longitude</p>
                <p className="text-base font-bold text-white mt-1 font-mono">{Number(store.longitude)}</p>
              </div>

              <div className="bg-slate-900/40 border border-slate-700/30 rounded-lg p-4 border-brand-500/20">
                <p className="text-[9px] text-brand-400 uppercase font-bold tracking-wider">Delivery Radius</p>
                <p className="text-base font-bold text-white mt-1">{Number(store.deliveryRadiusKm)} km</p>
              </div>
            </div>
          </div>
        </div>

        {/* Right Side Cards */}
        <div className="space-y-6">
          {/* Manager Details Card */}
          <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md">
            <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-4 flex items-center gap-2">
              <User className="h-4.5 w-4.5 text-brand-400" />
              Assigned Store Manager
            </h3>

            {assignedManager ? (
              <div className="space-y-3 bg-slate-900/30 rounded-lg p-4 border border-slate-700/40">
                <div>
                  <p className="text-[9px] text-slate-400 uppercase font-bold tracking-wider">Manager Name</p>
                  <p className="text-sm font-bold text-white mt-0.5">{assignedManager.name}</p>
                </div>
                <div>
                  <p className="text-[9px] text-slate-400 uppercase font-bold tracking-wider">Contact Email</p>
                  <p className="text-xs text-slate-300 mt-0.5">{assignedManager.email}</p>
                </div>
              </div>
            ) : (
              <div className="text-center py-6 border border-dashed border-slate-700 rounded-lg">
                <p className="text-slate-400 text-xs">No store manager assigned yet.</p>
              </div>
            )}
          </div>

          {/* Sales Performance Card */}
          <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md space-y-4">
            <h3 className="text-sm font-bold text-white uppercase tracking-wider flex items-center gap-2">
              <TrendingUp className="h-4.5 w-4.5 text-brand-400" />
              Sales & Orders Summary
            </h3>

            <div className="space-y-4">
              <div className="flex items-center justify-between border-b border-slate-800 pb-3">
                <span className="text-slate-400 text-xs">Total Sales Revenue</span>
                <span className="text-md font-bold text-emerald-400">{formatCurrency(salesRevenue)}</span>
              </div>

              <div className="flex items-center justify-between border-b border-slate-800 pb-3">
                <span className="text-slate-400 text-xs">Total Orders Received</span>
                <span className="text-md font-bold text-white flex items-center gap-1">
                  <ShoppingBag className="h-4 w-4 text-slate-400" />
                  {totalOrders}
                </span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-slate-400 text-xs">Pending Actions</span>
                <span className="text-md font-bold text-amber-400">{pendingOrders}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
