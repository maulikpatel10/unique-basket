import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import type { Store, Category } from '../types';
import {
  Search,
  Filter,
  CheckCircle,
  XCircle,
  Sliders,
  History,
  X,
  Store as StoreIcon,
  ArrowRight
} from 'lucide-react';

interface StoreProductInventory {
  id: string;
  name: string;
  description: string | null;
  imageUrl: string | null;
  categoryId: string;
  categoryName: string;
  unit: string;
  price: string;
  mrp: string | null;
  stockQuantity: number;
  lowStockThreshold: number;
  isAvailable: boolean;
}

interface InventoryTransaction {
  id: string;
  previousQuantity: string;
  changeQuantity: string;
  newQuantity: string;
  type: 'STOCK_ADDED' | 'STOCK_REMOVED' | 'STOCK_ADJUSTED' | 'ORDER_DEDUCTION' | 'ORDER_CANCELLATION_RESTORE';
  reason: string | null;
  createdAt: string;
  store: { name: string; storeId: string };
  product: { name: string; unit: string };
  performedByAdmin: { name: string; email: string } | null;
}

export const Inventory: React.FC = () => {
  const { user } = useAuth();
  const isSuperAdmin = user?.role === 'SUPER_ADMIN';

  const [stores, setStores] = useState<Store[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedStoreId, setSelectedStoreId] = useState('');
  const [inventory, setInventory] = useState<StoreProductInventory[]>([]);
  
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Search & Filters
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('ALL');
  const [stockStatusFilter, setStockStatusFilter] = useState<'ALL' | 'IN_STOCK' | 'LOW_STOCK' | 'OUT_OF_STOCK'>('ALL');

  // Modals / Overlays
  const [adjustModal, setAdjustModal] = useState<{ isOpen: boolean; product: StoreProductInventory | null }>({
    isOpen: false,
    product: null,
  });
  const [historyModal, setHistoryModal] = useState<{ isOpen: boolean; product: StoreProductInventory | null }>({
    isOpen: false,
    product: null,
  });
  const [transactions, setTransactions] = useState<InventoryTransaction[]>([]);
  const [loadingHistory, setLoadingHistory] = useState(false);

  // Form states for stock adjustment
  const [adjustType, setAdjustType] = useState<'ADD' | 'REMOVE' | 'SET'>('ADD');
  const [adjustQty, setAdjustQty] = useState('');
  const [adjustReason, setAdjustReason] = useState('');
  const [adjustThreshold, setAdjustThreshold] = useState('');
  const [adjustAvailable, setAdjustAvailable] = useState(true);
  const [formError, setFormError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Toast notifications
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  // Load stores list and categories list
  useEffect(() => {
    const initData = async () => {
      try {
        setLoading(true);
        const [storesRes, categoriesRes] = await Promise.all([
          api.get('/stores'),
          api.get('/categories'),
        ]);

        const storesList = storesRes.data.data;
        setStores(storesList);
        setCategories(categoriesRes.data.data);

        // Lock store selection based on role claims
        if (isSuperAdmin) {
          if (storesList.length > 0) {
            setSelectedStoreId(storesList[0].id);
          }
        } else {
          // Store Manager: Lock store to manager claim storeId
          setSelectedStoreId(user?.storeId || '');
        }
      } catch (err) {
        console.error('Error fetching stores/categories:', err);
        setError('Failed to load stores metadata. Please try again.');
      }
    };
    initData();
  }, [user, isSuperAdmin]);

  // Load store-specific inventories when selectedStoreId updates
  const fetchInventory = async () => {
    if (!selectedStoreId) return;
    try {
      setLoading(true);
      setError(null);
      const res = await api.get(`/products/store/${selectedStoreId}`);
      setInventory(res.data.data);
    } catch (err: any) {
      console.error('Error fetching store inventory:', err);
      setError('Failed to load store inventory catalog.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchInventory();
  }, [selectedStoreId]);

  // Handle live stock adjustment preview maths
  const getResultingStock = () => {
    if (!adjustModal.product) return 0;
    const current = adjustModal.product.stockQuantity;
    const adjust = parseFloat(adjustQty) || 0;

    if (adjustType === 'ADD') return current + adjust;
    if (adjustType === 'REMOVE') return current - adjust;
    return adjust;
  };

  useEffect(() => {
    if (adjustType === 'REMOVE' && adjustModal.product) {
      const resulting = getResultingStock();
      if (resulting < 0) {
        setFormError('Resulting stock quantity cannot be negative.');
      } else {
        setFormError(null);
      }
    } else {
      setFormError(null);
    }
  }, [adjustQty, adjustType, adjustModal.product]);

  const handleOpenAdjustModal = (prod: StoreProductInventory) => {
    setAdjustModal({ isOpen: true, product: prod });
    setAdjustType('ADD');
    setAdjustQty('');
    setAdjustReason('');
    setAdjustThreshold(prod.lowStockThreshold.toString());
    setAdjustAvailable(prod.isAvailable);
    setFormError(null);
  };

  const handleOpenHistoryModal = async (prod: StoreProductInventory) => {
    setHistoryModal({ isOpen: true, product: prod });
    setLoadingHistory(true);
    try {
      const res = await api.get('/admin/inventory/transactions', {
        params: { storeId: selectedStoreId, productId: prod.id },
      });
      setTransactions(res.data.data);
    } catch (err) {
      console.error('Error loading inventory transactions:', err);
      showToast('error', 'Failed to retrieve transaction history logs.');
    } finally {
      setLoadingHistory(false);
    }
  };

  const handleSaveAdjustment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adjustModal.product) return;

    const resulting = getResultingStock();
    if (resulting < 0) {
      showToast('error', 'Inventory stock cannot become negative.');
      return;
    }

    setSubmitting(true);
    try {
      const payload: any = {
        lowStockThreshold: parseFloat(adjustThreshold) || 5.0,
        isAvailable: adjustAvailable,
      };

      if (adjustQty) {
        payload.adjustmentType = adjustType;
        payload.quantity = parseFloat(adjustQty);
        payload.reason = adjustReason || 'Manual adjustment override';
      }

      await api.put(`/products/store/${selectedStoreId}/inventory/${adjustModal.product.id}`, payload);
      showToast('success', 'Store inventory adjusted successfully.');
      setAdjustModal({ isOpen: false, product: null });
      fetchInventory();
    } catch (err: any) {
      console.error('Error adjusting inventory:', err);
      const msg = err.response?.data?.message || 'Failed to adjust store stock levels.';
      showToast('error', msg);
    } finally {
      setSubmitting(false);
    }
  };

  // Filter Search
  const filteredInventory = inventory.filter((item) => {
    const matchesSearch =
      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.description && item.description.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesCategory = categoryFilter === 'ALL' || item.categoryId === categoryFilter;

    // Status: ALL, IN_STOCK (qty > threshold), LOW_STOCK (0 < qty <= threshold), OUT_OF_STOCK (qty === 0)
    let matchesStatus = true;
    if (stockStatusFilter === 'OUT_OF_STOCK') {
      matchesStatus = item.stockQuantity === 0;
    } else if (stockStatusFilter === 'LOW_STOCK') {
      matchesStatus = item.stockQuantity > 0 && item.stockQuantity <= item.lowStockThreshold;
    } else if (stockStatusFilter === 'IN_STOCK') {
      matchesStatus = item.stockQuantity > item.lowStockThreshold;
    }

    return matchesSearch && matchesCategory && matchesStatus;
  });

  const getStockStatusBadge = (item: StoreProductInventory) => {
    if (item.stockQuantity === 0) {
      return (
        <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-red-500/10 text-red-400 border border-red-500/20">
          OUT OF STOCK
        </span>
      );
    }
    if (item.stockQuantity <= item.lowStockThreshold) {
      return (
        <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20 animate-pulse">
          LOW STOCK
        </span>
      );
    }
    return (
      <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
        IN STOCK
      </span>
    );
  };

  return (
    <div className="relative space-y-6">
      {/* Toast popup alerts */}
      {toast && (
        <div
          className={`fixed top-4 right-4 z-50 flex items-center gap-3 rounded-lg px-5 py-3 shadow-lg border text-sm font-semibold transition-all duration-300 animate-slide-in ${
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
          <h2 className="text-2xl font-bold text-white">Store Inventory Controls</h2>
          <p className="text-slate-400 text-sm mt-1">Configure physical warehouse counts and low stock warnings.</p>
        </div>

        {/* Store Selector */}
        {isSuperAdmin ? (
          <div className="flex items-center gap-3 bg-darkbg-800 border border-slate-700/50 rounded-lg px-4 py-2 text-sm shadow-md">
            <StoreIcon className="h-4.5 w-4.5 text-brand-400" />
            <span className="text-slate-300 font-semibold shrink-0">Outlet Store:</span>
            <select
              value={selectedStoreId}
              onChange={(e) => setSelectedStoreId(e.target.value)}
              className="rounded bg-slate-900 border border-slate-700 text-slate-200 px-2.5 py-1.5 text-xs font-semibold focus:border-brand-500 outline-none"
            >
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
            <span>Assigned Outlet:</span>
            <strong className="text-slate-200 uppercase">
              {stores.find((s) => s.id === selectedStoreId)?.name || 'Central Store'}
            </strong>
          </div>
        )}
      </div>

      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-4 bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl shadow-md">
        <div className="relative flex-1">
          <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
            <Search className="h-4 w-4" />
          </span>
          <input
            type="text"
            placeholder="Search inventory products by keyword..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 outline-none transition-all duration-150"
          />
        </div>

        <div className="flex flex-wrap gap-4 items-center">
          <div className="flex items-center gap-2">
            <Filter className="h-4 w-4 text-slate-400" />
            <span className="text-xs text-slate-400 uppercase font-semibold tracking-wider">Department:</span>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="ALL">All Categories</option>
              {categories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-400 uppercase font-semibold tracking-wider">Availability:</span>
            <select
              value={stockStatusFilter}
              onChange={(e) => setStockStatusFilter(e.target.value as any)}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="ALL">All Stock Levels</option>
              <option value="IN_STOCK">In Stock Only</option>
              <option value="LOW_STOCK">Low Stock Warnings</option>
              <option value="OUT_OF_STOCK">Out of Stock Only</option>
            </select>
          </div>
        </div>
      </div>

      {/* Inventory Table List */}
      {loading ? (
        <div className="space-y-4">
          <div className="h-10 bg-slate-800 rounded-lg animate-pulse"></div>
          {[1, 2].map((i) => (
            <div key={i} className="h-16 bg-slate-800/65 rounded-lg animate-pulse"></div>
          ))}
        </div>
      ) : error ? (
        <div className="text-center py-12 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-red-400 text-sm font-semibold">{error}</p>
          <button
            onClick={fetchInventory}
            className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
          >
            Try Again
          </button>
        </div>
      ) : filteredInventory.length === 0 ? (
        <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-slate-400 text-sm">No items in inventory match your criteria.</p>
        </div>
      ) : (
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 overflow-hidden shadow-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-6 py-4">Product Name</th>
                  <th className="px-6 py-4">Category</th>
                  <th className="px-6 py-4">Available Stock</th>
                  <th className="px-6 py-4">Unit</th>
                  <th className="px-6 py-4">Low Stock Limit</th>
                  <th className="px-6 py-4">Stock Status</th>
                  <th className="px-6 py-4">Store Status</th>
                  <th className="px-6 py-4 text-center">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {filteredInventory.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-800/10">
                    <td className="px-6 py-4 font-bold text-white tracking-wide">{item.name}</td>
                    <td className="px-6 py-4 text-slate-400 text-xs">{item.categoryName}</td>
                    <td className="px-6 py-4 font-mono font-bold text-slate-100">{item.stockQuantity}</td>
                    <td className="px-6 py-4 text-xs font-semibold text-slate-400">{item.unit}</td>
                    <td className="px-6 py-4 font-mono text-slate-400">{item.lowStockThreshold}</td>
                    <td className="px-6 py-4">{getStockStatusBadge(item)}</td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex px-1.5 py-0.5 rounded text-[9px] font-bold border ${
                          item.isAvailable
                            ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/10'
                            : 'bg-red-500/10 text-red-400 border-red-500/10'
                        }`}
                      >
                        {item.isAvailable ? 'BUYABLE' : 'UNAVAILABLE'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-center gap-3">
                        <button
                          onClick={() => handleOpenAdjustModal(item)}
                          title="Adjust Inventory Stock"
                          className="rounded p-1.5 text-slate-400 hover:bg-slate-700 hover:text-brand-400 transition-all duration-150"
                        >
                          <Sliders className="h-4.5 w-4.5" />
                        </button>
                        <button
                          onClick={() => handleOpenHistoryModal(item)}
                          title="View Transaction Logs"
                          className="rounded p-1.5 text-slate-400 hover:bg-slate-700 hover:text-cyan-400 transition-all duration-150"
                        >
                          <History className="h-4.5 w-4.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Adjustment Dialog Modal */}
      {adjustModal.isOpen && adjustModal.product && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setAdjustModal({ isOpen: false, product: null })} />

          <form
            onSubmit={handleSaveAdjustment}
            className="relative w-full max-w-md rounded-2xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl animate-scale-in space-y-4"
          >
            <div className="flex items-center justify-between border-b border-slate-700 pb-3">
              <h3 className="text-base font-bold text-white">Manual Stock Adjustment</h3>
              <button
                type="button"
                onClick={() => setAdjustModal({ isOpen: false, product: null })}
                className="text-slate-400 hover:text-white"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div>
              <p className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">Product Name</p>
              <p className="text-sm font-bold text-white mt-0.5">{adjustModal.product.name}</p>
            </div>

            <div className="grid grid-cols-3 gap-4 bg-slate-900/40 border border-slate-700/30 rounded-lg p-3 text-center">
              <div>
                <p className="text-[8px] text-slate-400 uppercase font-semibold">Current</p>
                <p className="text-xs font-bold text-slate-200 mt-0.5">
                  {adjustModal.product.stockQuantity} {adjustModal.product.unit}
                </p>
              </div>
              <div className="flex items-center justify-center text-slate-500">
                <ArrowRight className="h-4 w-4" />
              </div>
              <div>
                <p className="text-[8px] text-brand-400 uppercase font-semibold">Resulting</p>
                <p className="text-xs font-bold text-emerald-400 mt-0.5">
                  {getResultingStock()} {adjustModal.product.unit}
                </p>
              </div>
            </div>

            {/* Adjust Type */}
            <div className="grid grid-cols-3 gap-2">
              {(['ADD', 'REMOVE', 'SET'] as const).map((type) => (
                <button
                  key={type}
                  type="button"
                  onClick={() => setAdjustType(type)}
                  className={`py-2 rounded-lg text-xs font-bold border transition-all duration-150 ${
                    adjustType === type
                      ? 'bg-brand-500/10 text-brand-400 border-brand-500/30'
                      : 'bg-slate-900 border-slate-700 text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {type === 'ADD' ? '+ Add' : type === 'REMOVE' ? '- Remove' : '= Set'}
                </button>
              ))}
            </div>

            {/* Quantity */}
            <div>
              <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                Quantity to Adjust ({adjustModal.product.unit})
              </label>
              <input
                type="text"
                value={adjustQty}
                onChange={(e) => setAdjustQty(e.target.value)}
                placeholder="0.00"
                className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3 py-2 text-sm focus:border-brand-500 outline-none"
              />
              {formError && <p className="text-red-400 text-xs mt-1 font-semibold">{formError}</p>}
            </div>

            {/* Reason */}
            <div>
              <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                Reason / Remarks
              </label>
              <input
                type="text"
                value={adjustReason}
                onChange={(e) => setAdjustReason(e.target.value)}
                placeholder="Stock receipt invoice #..."
                className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3 py-2 text-sm focus:border-brand-500 outline-none"
              />
            </div>

            {/* Threshold & Availability */}
            <div className="grid grid-cols-2 gap-4 border-t border-slate-800 pt-4 mt-2">
              <div>
                <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1">
                  Low Stock Threshold
                </label>
                <input
                  type="number"
                  value={adjustThreshold}
                  onChange={(e) => setAdjustThreshold(e.target.value)}
                  className="w-full rounded bg-slate-900 border border-slate-750 text-slate-200 px-2 py-1.5 text-xs outline-none"
                />
              </div>

              <div className="flex flex-col justify-end">
                <label className="flex items-center gap-2 cursor-pointer py-1">
                  <input
                    type="checkbox"
                    checked={adjustAvailable}
                    onChange={(e) => setAdjustAvailable(e.target.checked)}
                    className="rounded bg-slate-900 border-slate-700 text-brand-500 focus:ring-0"
                  />
                  <span className="text-[10px] font-bold text-slate-300 uppercase tracking-wider">Is Available</span>
                </label>
              </div>
            </div>

            <div className="flex gap-4 border-t border-slate-800 pt-4 mt-4">
              <button
                type="button"
                onClick={() => setAdjustModal({ isOpen: false, product: null })}
                className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-2.5 text-xs font-bold"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={submitting || !!formError}
                className="flex-1 flex items-center justify-center rounded-lg bg-brand-500 hover:bg-brand-600 text-white py-2.5 text-xs font-bold disabled:opacity-50"
              >
                {submitting ? (
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                ) : (
                  'Confirm Adjust'
                )}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* History Transactions Modal */}
      {historyModal.isOpen && historyModal.product && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setHistoryModal({ isOpen: false, product: null })} />

          <div className="relative w-full max-w-3xl rounded-2xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl animate-scale-in flex flex-col max-h-[80vh]">
            <div className="flex items-center justify-between border-b border-slate-700 pb-3 mb-4">
              <div>
                <h3 className="text-base font-bold text-white">Stock Transaction History</h3>
                <p className="text-xs text-slate-400 mt-0.5">Product: {historyModal.product.name}</p>
              </div>
              <button
                onClick={() => setHistoryModal({ isOpen: false, product: null })}
                className="text-slate-400 hover:text-white"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {loadingHistory ? (
              <div className="py-16 text-center">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-brand-500 border-t-transparent mx-auto mb-3"></div>
                <p className="text-slate-400 text-xs">Loading transaction logs...</p>
              </div>
            ) : transactions.length === 0 ? (
              <div className="py-16 text-center text-slate-400 text-xs border border-dashed border-slate-700 rounded-lg">
                No inventory transaction logs recorded for this product.
              </div>
            ) : (
              <div className="overflow-y-auto flex-1 pr-1 border border-slate-800 rounded-lg">
                <table className="w-full text-left text-xs text-slate-300">
                  <thead className="bg-slate-900/40 text-[10px] font-bold text-slate-400 uppercase sticky top-0 border-b border-slate-700">
                    <tr>
                      <th className="px-4 py-3">Date</th>
                      <th className="px-4 py-3">Action Type</th>
                      <th className="px-4 py-3 text-right">Previous</th>
                      <th className="px-4 py-3 text-right">Change</th>
                      <th className="px-4 py-3 text-right">New Stock</th>
                      <th className="px-4 py-3">Remarks / Reason</th>
                      <th className="px-4 py-3">Performed By</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800">
                    {transactions.map((t) => {
                      const isPositive = parseFloat(t.changeQuantity) >= 0;
                      return (
                        <tr key={t.id} className="hover:bg-slate-800/10">
                          <td className="px-4 py-3 font-mono text-[10px] text-slate-400">
                            {new Date(t.createdAt).toLocaleDateString('en-IN', {
                              day: '2-digit',
                              month: 'short',
                              hour: '2-digit',
                              minute: '2-digit',
                            })}
                          </td>
                          <td className="px-4 py-3">
                            <span
                              className={`inline-flex px-1.5 py-0.5 rounded text-[8px] font-extrabold border ${
                                t.type === 'STOCK_ADDED' || t.type === 'ORDER_CANCELLATION_RESTORE'
                                  ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/10'
                                  : t.type === 'STOCK_REMOVED' || t.type === 'ORDER_DEDUCTION'
                                  ? 'bg-red-500/10 text-red-400 border-red-500/10'
                                  : 'bg-amber-500/10 text-amber-400 border-amber-500/10'
                              }`}
                            >
                              {t.type.replace(/_/g, ' ')}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-right font-mono text-slate-300">
                            {t.previousQuantity} {t.product.unit}
                          </td>
                          <td
                            className={`px-4 py-3 text-right font-mono font-bold ${
                              isPositive ? 'text-emerald-400' : 'text-red-400'
                            }`}
                          >
                            {isPositive ? `+${t.changeQuantity}` : t.changeQuantity} {t.product.unit}
                          </td>
                          <td className="px-4 py-3 text-right font-mono text-slate-100 font-bold">
                            {t.newQuantity} {t.product.unit}
                          </td>
                          <td className="px-4 py-3 text-slate-400 max-w-xs truncate" title={t.reason || ''}>
                            {t.reason || '—'}
                          </td>
                          <td className="px-4 py-3">
                            {t.performedByAdmin ? (
                              <div>
                                <p className="font-bold text-slate-200">{t.performedByAdmin.name}</p>
                                <p className="text-[9px] text-slate-400 leading-none">{t.performedByAdmin.email}</p>
                              </div>
                            ) : (
                              <span className="text-slate-500">System (Customer Checkout)</span>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}

            <div className="mt-4 pt-3 border-t border-slate-800 flex justify-end">
              <button
                onClick={() => setHistoryModal({ isOpen: false, product: null })}
                className="rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
              >
                Close History
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
