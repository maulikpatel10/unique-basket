import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import type { Category } from '../types';
import { useAuth } from '../context/AuthContext';
import {
  Plus,
  Search,
  Filter,
  Edit2,
  CheckCircle,
  XCircle,
  AlertTriangle,
  X,
  Tag,
  AlignLeft,
  Image as ImageIcon,
  DollarSign,
  Briefcase
} from 'lucide-react';

interface Product {
  id: string;
  name: string;
  description: string | null;
  imageUrl: string | null;
  categoryId: string;
  category: {
    name: string;
  };
  unit: 'KG' | 'GRAM' | 'PIECE' | 'PACK' | 'DOZEN';
  price: string;
  mrp: string | null;
  isActive: boolean;
  createdAt: string;
}

export const Products: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Search & Filters
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL');
  const [categoryFilter, setCategoryFilter] = useState('ALL');

  // Modal / Drawer states
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [confirmModal, setConfirmModal] = useState<{ isOpen: boolean; product: Product | null }>({
    isOpen: false,
    product: null,
  });

  // Toasts
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Form states
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    imageUrl: '',
    categoryId: '',
    unit: 'KG' as 'KG' | 'GRAM' | 'PIECE' | 'PACK' | 'DOZEN',
    price: '',
    mrp: '',
    isActive: true,
  });
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);
      // Fetch both products and active categories in parallel
      const [productsRes, categoriesRes] = await Promise.all([
        api.get('/products'),
        api.get('/categories'),
      ]);
      setProducts(productsRes.data.data);
      setCategories(categoriesRes.data.data);
    } catch (err: any) {
      console.error('Error fetching products:', err);
      setError('Failed to retrieve products catalog. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (formErrors[name]) {
      setFormErrors((prev) => {
        const copy = { ...prev };
        delete copy[name];
        return copy;
      });
    }
  };

  const validateForm = () => {
    const errors: Record<string, string> = {};
    if (!formData.name.trim()) errors.name = 'Product Name is required';
    if (!formData.categoryId) errors.categoryId = 'Category mapping is required';
    if (!formData.price) {
      errors.price = 'Base Price is required';
    } else {
      const priceNum = parseFloat(formData.price);
      if (isNaN(priceNum) || priceNum <= 0) {
        errors.price = 'Base Price must be a positive decimal number';
      }
    }
    if (formData.mrp) {
      const mrpNum = parseFloat(formData.mrp);
      if (isNaN(mrpNum) || mrpNum < parseFloat(formData.price)) {
        errors.mrp = 'MRP must be greater than or equal to Base Price';
      }
    }
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleOpenCreateDrawer = () => {
    if (user?.role !== 'SUPER_ADMIN') {
      showToast('error', 'You do not have permission to create products.');
      return;
    }
    setEditingProduct(null);
    setFormData({
      name: '',
      description: '',
      imageUrl: '',
      categoryId: categories[0]?.id || '',
      unit: 'KG',
      price: '',
      mrp: '',
      isActive: true,
    });
    setFormErrors({});
    setIsDrawerOpen(true);
  };

  const handleOpenEditDrawer = (prod: Product) => {
    if (user?.role !== 'SUPER_ADMIN') {
      showToast('error', 'You do not have permission to edit products.');
      return;
    }
    setEditingProduct(prod);
    setFormData({
      name: prod.name,
      description: prod.description || '',
      imageUrl: prod.imageUrl || '',
      categoryId: prod.categoryId,
      unit: prod.unit,
      price: prod.price,
      mrp: prod.mrp || '',
      isActive: prod.isActive,
    });
    setFormErrors({});
    setIsDrawerOpen(true);
  };

  const handleSaveProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    setSubmitting(true);
    try {
      const payload = {
        ...formData,
        price: parseFloat(formData.price),
        mrp: formData.mrp ? parseFloat(formData.mrp) : null,
      };

      if (editingProduct) {
        await api.put(`/products/${editingProduct.id}`, payload);
        showToast('success', 'Product details saved successfully.');
      } else {
        await api.post('/products', payload);
        showToast('success', 'Product registered successfully.');
      }
      setIsDrawerOpen(false);
      fetchData();
    } catch (err: any) {
      console.error('Error saving product:', err);
      const msg = err.response?.data?.message || 'Failed to save product profile.';
      showToast('error', msg);
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleStatus = async (prod: Product) => {
    if (user?.role !== 'SUPER_ADMIN') {
      showToast('error', 'You do not have permission to change product status.');
      return;
    }
    if (prod.isActive) {
      setConfirmModal({ isOpen: true, product: prod });
    } else {
      try {
        await api.put(`/products/${prod.id}`, { isActive: true });
        showToast('success', `Product "${prod.name}" activated successfully.`);
        fetchData();
      } catch (err: any) {
        showToast('error', 'Failed to activate product.');
      }
    }
  };

  const handleConfirmDeactivate = async () => {
    if (user?.role !== 'SUPER_ADMIN') {
      showToast('error', 'You do not have permission to deactivate products.');
      return;
    }
    const prod = confirmModal.product;
    if (!prod) return;

    try {
      await api.delete(`/products/${prod.id}`);
      showToast('success', `Product "${prod.name}" deactivated successfully.`);
      setConfirmModal({ isOpen: false, product: null });
      fetchData();
    } catch (err: any) {
      showToast('error', 'Failed to deactivate product.');
    }
  };

  const formatCurrency = (val: string) => {
    return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(Number(val));
  };

  // Filter Search
  const filteredProducts = products.filter((prod) => {
    const matchesSearch =
      prod.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (prod.description && prod.description.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStatus =
      statusFilter === 'ALL' ||
      (statusFilter === 'ACTIVE' && prod.isActive) ||
      (statusFilter === 'INACTIVE' && !prod.isActive);

    const matchesCategory = categoryFilter === 'ALL' || prod.categoryId === categoryFilter;

    return matchesSearch && matchesStatus && matchesCategory;
  });

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

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white">Global Products</h2>
          <p className="text-slate-400 text-sm mt-1">Configure global product items, base pricing, and unit metrics.</p>
        </div>
        {user?.role === 'SUPER_ADMIN' && (
          <button
            onClick={handleOpenCreateDrawer}
            className="flex items-center justify-center gap-2 rounded-lg bg-brand-500 hover:bg-brand-600 text-white px-4 py-2.5 text-sm font-bold shadow-lg shadow-brand-500/20 hover:shadow-brand-500/30 transition-all duration-200"
          >
            <Plus className="h-4.5 w-4.5" />
            Add Product
          </button>
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
            placeholder="Search products by name or description..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 outline-none transition-all duration-150"
          />
        </div>

        <div className="flex flex-wrap gap-4 items-center">
          <div className="flex items-center gap-2">
            <Filter className="h-4 w-4 text-slate-400" />
            <span className="text-xs text-slate-400 uppercase font-semibold tracking-wider">Status:</span>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as any)}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="ALL">All Statuses</option>
              <option value="ACTIVE">Active Only</option>
              <option value="INACTIVE">Inactive Only</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-400 uppercase font-semibold tracking-wider">Category:</span>
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
        </div>
      </div>

      {/* Table list */}
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
            onClick={fetchData}
            className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
          >
            Try Again
          </button>
        </div>
      ) : filteredProducts.length === 0 ? (
        <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-slate-400 text-sm">No products recorded matching filters.</p>
        </div>
      ) : (
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 overflow-hidden shadow-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-6 py-4">Image</th>
                  <th className="px-6 py-4">Product Name</th>
                  <th className="px-6 py-4">Category</th>
                  <th className="px-6 py-4">Base Price</th>
                  <th className="px-6 py-4">MRP</th>
                  <th className="px-6 py-4">Unit Type</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4 text-center">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {filteredProducts.map((prod) => (
                  <tr key={prod.id} className="hover:bg-slate-800/10">
                    <td className="px-6 py-4 shrink-0">
                      {prod.imageUrl ? (
                        <img
                          src={prod.imageUrl}
                          alt={prod.name}
                          className="h-10 w-12 rounded object-cover border border-slate-700"
                          onError={(e) => {
                            (e.target as HTMLImageElement).src = 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=120&q=80';
                          }}
                        />
                      ) : (
                        <div className="h-10 w-12 rounded bg-slate-900 border border-slate-850 flex items-center justify-center text-slate-500">
                          <ImageIcon className="h-4 w-4" />
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 font-bold text-white tracking-wide">{prod.name}</td>
                    <td className="px-6 py-4 text-slate-400">{prod.category.name}</td>
                    <td className="px-6 py-4 font-mono font-bold text-brand-400">{formatCurrency(prod.price)}</td>
                    <td className="px-6 py-4 font-mono text-slate-400 line-through">
                      {prod.mrp ? formatCurrency(prod.mrp) : '—'}
                    </td>
                    <td className="px-6 py-4 text-xs font-semibold text-slate-300 tracking-wider">
                      {prod.unit}
                    </td>
                    <td className="px-6 py-4">
                      {user?.role === 'SUPER_ADMIN' ? (
                        <button
                          onClick={() => handleToggleStatus(prod)}
                          className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border transition-all duration-200 hover:scale-[1.02] ${
                            prod.isActive
                              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/25'
                              : 'bg-red-500/10 text-red-400 border-red-500/20 hover:bg-red-500/25'
                          }`}
                        >
                          {prod.isActive ? 'ACTIVE' : 'INACTIVE'}
                        </button>
                      ) : (
                        <span className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border ${prod.isActive ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : 'bg-red-500/10 text-red-400 border-red-500/20'}`}>
                          {prod.isActive ? 'ACTIVE' : 'INACTIVE'}
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-center">
                      {user?.role === 'SUPER_ADMIN' && (
                        <button
                          onClick={() => handleOpenEditDrawer(prod)}
                          title="Edit Product"
                          className="rounded p-1.5 text-slate-400 hover:bg-slate-700 hover:text-amber-400 transition-all duration-150"
                        >
                          <Edit2 className="h-4.5 w-4.5" />
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Drawer */}
      {isDrawerOpen && (
        <div className="fixed inset-0 z-50 flex justify-end">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setIsDrawerOpen(false)} />

          <div className="relative flex w-full max-w-lg flex-col bg-darkbg-800 border-l border-slate-700 text-slate-200 shadow-2xl p-6 overflow-y-auto animate-slide-in">
            <div className="flex items-center justify-between border-b border-slate-700 pb-4 mb-6">
              <h3 className="text-lg font-bold text-white">
                {editingProduct ? `Edit Product: ${editingProduct.name}` : 'Add Product'}
              </h3>
              <button
                onClick={() => setIsDrawerOpen(false)}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-700 hover:text-white"
              >
                <X className="h-5.5 w-5.5" />
              </button>
            </div>

            <form onSubmit={handleSaveProduct} className="space-y-5">
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Product Name <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <Briefcase className="h-4 w-4" />
                  </span>
                  <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    placeholder="Apple (Shimla)"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.name && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.name}</p>}
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Category Mapping <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <Tag className="h-4 w-4" />
                  </span>
                  <select
                    name="categoryId"
                    value={formData.categoryId}
                    onChange={handleInputChange}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  >
                    <option value="" disabled>Select Category mapping...</option>
                    {categories.map((cat) => (
                      <option key={cat.id} value={cat.id}>
                        {cat.name}
                      </option>
                    ))}
                  </select>
                </div>
                {formErrors.categoryId && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.categoryId}</p>}
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Unit Type <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <Filter className="h-4 w-4" />
                  </span>
                  <select
                    name="unit"
                    value={formData.unit}
                    onChange={handleInputChange}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  >
                    <option value="KG">KG</option>
                    <option value="GRAM">GRAM</option>
                    <option value="PIECE">PIECE</option>
                    <option value="PACK">PACK</option>
                    <option value="DOZEN">DOZEN</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    Base Price (₹) <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                      <DollarSign className="h-4 w-4" />
                    </span>
                    <input
                      type="text"
                      name="price"
                      value={formData.price}
                      onChange={handleInputChange}
                      placeholder="180.00"
                      className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                    />
                  </div>
                  {formErrors.price && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.price}</p>}
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    MRP (₹)
                  </label>
                  <div className="relative">
                    <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                      <DollarSign className="h-4 w-4" />
                    </span>
                    <input
                      type="text"
                      name="mrp"
                      value={formData.mrp}
                      onChange={handleInputChange}
                      placeholder="200.00"
                      className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                    />
                  </div>
                  {formErrors.mrp && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.mrp}</p>}
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Description
                </label>
                <div className="relative">
                  <span className="absolute top-3 left-3 text-slate-400">
                    <AlignLeft className="h-4 w-4" />
                  </span>
                  <textarea
                    name="description"
                    value={formData.description}
                    onChange={handleInputChange}
                    rows={3}
                    placeholder="Shimla fresh red delicious apples..."
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none resize-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Image URL
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <ImageIcon className="h-4 w-4" />
                  </span>
                  <input
                    type="text"
                    name="imageUrl"
                    value={formData.imageUrl}
                    onChange={handleInputChange}
                    placeholder="https://images.unsplash.com/..."
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                </div>
              </div>

              <div className="flex items-center gap-4 pt-6 border-t border-slate-700 mt-6">
                <button
                  type="button"
                  onClick={() => setIsDrawerOpen(false)}
                  className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-3 text-sm font-bold transition-all duration-150"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="flex-1 flex items-center justify-center rounded-lg bg-brand-500 hover:bg-brand-600 text-white py-3 text-sm font-bold shadow-lg shadow-brand-500/10 transition-all duration-150 disabled:opacity-50"
                >
                  {submitting ? (
                    <div className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                  ) : editingProduct ? (
                    'Save Changes'
                  ) : (
                    'Add Product'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      {confirmModal.isOpen && confirmModal.product && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setConfirmModal({ isOpen: false, product: null })} />

          <div className="relative w-full max-w-md rounded-2xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl animate-scale-in">
            <div className="flex items-center gap-3.5 text-amber-500 mb-4">
              <AlertTriangle className="h-8 w-8" />
              <div>
                <h4 className="text-md font-extrabold text-white">Deactivate Product?</h4>
                <p className="text-[10px] text-brand-400 font-semibold tracking-wider uppercase">Confirm Visibility Revoke</p>
              </div>
            </div>

            <p className="text-slate-300 text-xs leading-relaxed mb-6">
              Are you sure you want to deactivate <strong className="text-white">"{confirmModal.product.name}"</strong>? 
              This product will be hidden from customer search lists instantly and cannot be newly added to shopping carts or placed on new orders. Historical orders will remain unchanged.
            </p>

            <div className="flex gap-4">
              <button
                onClick={() => setConfirmModal({ isOpen: false, product: null })}
                className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-2.5 text-xs font-bold transition-all duration-150"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmDeactivate}
                className="flex-1 rounded-lg bg-red-500 hover:bg-red-650 text-white py-2.5 text-xs font-bold transition-all duration-150 shadow-md shadow-red-950/20"
              >
                Deactivate
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
