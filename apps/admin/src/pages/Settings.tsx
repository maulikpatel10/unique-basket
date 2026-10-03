import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/authContextStore';
import { api } from '../services/api';
import { useLoader } from '../hooks/useLoader';
import type { DeliverySettings } from '../types';
import {
  Truck,
  Banknote,
  CheckCircle,
  XCircle,
  AlertCircle,
  Save,
  RotateCcw,
  Sliders,
  ShieldCheck,
  ShieldAlert,
  Info,
  MapPin
} from 'lucide-react';
import { asApiError } from '../utils/apiError';

export const Settings: React.FC = () => {
  const { user } = useAuth();
  const isSuperAdmin = user?.role === 'SUPER_ADMIN';

  const [submitting, setSubmitting] = useState(false);

  // Form State
  const [formData, setFormData] = useState<DeliverySettings>({
    deliveryEnabled: true,
    deliveryFee: 30,
    freeDeliveryThreshold: 200,
    minimumOrderAmount: 199,
    codEnabled: true,
    codCharge: 20,
    minimumCodOrderAmount: 100,
    maximumCodOrderAmount: 5000,
    pickupCodEnabled: true,
  });

  // Snapshot of loaded settings to allow reset/cancel
  const [initialSettings, setInitialSettings] = useState<DeliverySettings | null>(null);
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const loadSettings = async () => {
    const res = await api.get('/admin/settings/fare-cod');
    const data = res.data.data;
    const parsedData: DeliverySettings = {
      id: data.id,
      deliveryEnabled: Boolean(data.deliveryEnabled),
      deliveryFee: Number(data.deliveryFee),
      freeDeliveryThreshold: Number(data.freeDeliveryThreshold),
      minimumOrderAmount: Number(data.minimumOrderAmount),
      codEnabled: Boolean(data.codEnabled),
      codCharge: Number(data.codCharge),
      minimumCodOrderAmount: Number(data.minimumCodOrderAmount),
      maximumCodOrderAmount: Number(data.maximumCodOrderAmount),
      pickupCodEnabled: Boolean(data.pickupCodEnabled),
      updatedAt: data.updatedAt,
    };
    setFormData(parsedData);
    setInitialSettings(parsedData);
  };

  // useLoader: loading/error derived from the latest request (no setState inside effects)
  const { loading, error: fetchError, reload: fetchSettings } = useLoader(loadSettings, [], {
    errorMessage: (caught) => asApiError(caught).response?.data?.message || 'Failed to load fares & COD settings.',
    onError: (message) => showToast('error', message),
  });

  const handleNumberChange = (field: keyof DeliverySettings, val: string) => {
    const num = parseFloat(val);
    setFormData((prev) => ({
      ...prev,
      [field]: isNaN(num) ? 0 : num,
    }));

    if (formErrors[field]) {
      setFormErrors((prev) => {
        const copy = { ...prev };
        delete copy[field];
        return copy;
      });
    }
  };

  const handleToggle = (field: keyof DeliverySettings) => {
    setFormData((prev) => ({
      ...prev,
      [field]: !prev[field],
    }));
  };

  const validateForm = (): boolean => {
    const errors: Record<string, string> = {};

    if (formData.deliveryFee < 0) {
      errors.deliveryFee = 'Delivery fee cannot be negative.';
    }
    if (formData.freeDeliveryThreshold < 0) {
      errors.freeDeliveryThreshold = 'Free delivery threshold cannot be negative.';
    }
    if (formData.minimumOrderAmount < 0) {
      errors.minimumOrderAmount = 'Minimum delivery order amount cannot be negative.';
    }
    if (formData.codCharge < 0) {
      errors.codCharge = 'COD charge cannot be negative.';
    }
    if (formData.minimumCodOrderAmount < 0) {
      errors.minimumCodOrderAmount = 'Minimum COD amount cannot be negative.';
    }
    if (formData.maximumCodOrderAmount < 0) {
      errors.maximumCodOrderAmount = 'Maximum COD amount cannot be negative.';
    }
    if (formData.minimumCodOrderAmount > formData.maximumCodOrderAmount) {
      errors.minimumCodOrderAmount = 'Minimum COD amount cannot exceed maximum COD amount.';
    }

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isSuperAdmin) {
      showToast('error', 'Only Super Admins have permission to modify fares & COD settings.');
      return;
    }

    if (!validateForm()) {
      showToast('error', 'Please correct validation errors before saving.');
      return;
    }

    try {
      setSubmitting(true);
      const res = await api.put('/admin/settings/fare-cod', formData);
      const updated = res.data.data;
      const parsedData: DeliverySettings = {
        id: updated.id,
        deliveryEnabled: Boolean(updated.deliveryEnabled),
        deliveryFee: Number(updated.deliveryFee),
        freeDeliveryThreshold: Number(updated.freeDeliveryThreshold),
        minimumOrderAmount: Number(updated.minimumOrderAmount),
        codEnabled: Boolean(updated.codEnabled),
        codCharge: Number(updated.codCharge),
        minimumCodOrderAmount: Number(updated.minimumCodOrderAmount),
        maximumCodOrderAmount: Number(updated.maximumCodOrderAmount),
        pickupCodEnabled: Boolean(updated.pickupCodEnabled),
        updatedAt: updated.updatedAt,
      };
      setFormData(parsedData);
      setInitialSettings(parsedData);
      showToast('success', res.data.message || 'Fares and COD settings saved successfully!');
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error saving settings:', err);
      const msg = err.response?.data?.message || 'Failed to update settings.';
      showToast('error', msg);
    } finally {
      setSubmitting(false);
    }
  };

  const handleReset = () => {
    if (initialSettings) {
      setFormData(initialSettings);
      setFormErrors({});
      showToast('success', 'Form values reset to current active settings.');
    }
  };

  if (!isSuperAdmin) {
    return (
      <div className="max-w-4xl mx-auto space-y-6">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-2.5">
            <Sliders className="h-6 w-6 text-brand-400" />
            <span>Fares & COD Configuration</span>
          </h2>
          <p className="text-slate-400 text-sm mt-1">
            Global delivery fare thresholds and Cash on Delivery parameters.
          </p>
        </div>

        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-8 shadow-md text-center space-y-4">
          <ShieldAlert className="h-12 w-12 text-amber-400 mx-auto" />
          <h3 className="text-lg font-bold text-white">Access Restricted</h3>
          <p className="text-slate-400 text-xs max-w-md mx-auto leading-relaxed">
            Fares and Cash on Delivery (COD) settings are restricted to Super Administrators only. Store Managers cannot modify these pricing parameters.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="relative space-y-6 max-w-5xl mx-auto">
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

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-2.5">
            <Sliders className="h-6 w-6 text-brand-400" />
            <span>Fares & COD Settings</span>
          </h2>
          <p className="text-slate-400 text-sm mt-1">
            Configure system-wide delivery pricing rules, free delivery limits, and Cash on Delivery eligibility.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs font-semibold px-3 py-1.5 rounded-lg bg-slate-800/80 border border-slate-700 text-slate-300">
          <ShieldCheck className="h-4 w-4 text-brand-400" />
          <span>Super Admin Access</span>
        </div>
      </div>

      {fetchError && (
        <div className="flex items-center justify-between p-4 rounded-xl bg-red-950/40 border border-red-500/30 text-red-400 text-xs font-semibold">
          <div className="flex items-center gap-2.5">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{fetchError}</span>
          </div>
          <button
            onClick={fetchSettings}
            className="px-3 py-1 bg-red-900/60 hover:bg-red-900 rounded border border-red-500/40 text-white font-bold transition-colors"
          >
            Retry
          </button>
        </div>
      )}

      {loading ? (
        <div className="space-y-6">
          <div className="h-48 bg-slate-800/60 rounded-2xl animate-pulse" />
          <div className="h-56 bg-slate-800/60 rounded-2xl animate-pulse" />
        </div>
      ) : (
        <form onSubmit={handleSave} className="space-y-6">
          {/* Delivery Settings Section */}
          <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 sm:p-8 shadow-md space-y-6">
            <div className="flex items-center justify-between border-b border-slate-700/60 pb-4">
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-sky-500/10 text-sky-400 border border-sky-500/20">
                  <Truck className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-white uppercase tracking-wide">Delivery Settings</h3>
                  <p className="text-xs text-slate-400">Configure delivery availability, base fee, and thresholds.</p>
                </div>
              </div>

              {/* Delivery Enabled Toggle */}
              <div className="flex items-center gap-3">
                <span className="text-xs font-bold text-slate-300">
                  {formData.deliveryEnabled ? 'DELIVERY ENABLED' : 'DELIVERY DISABLED'}
                </span>
                <button
                  type="button"
                  onClick={() => handleToggle('deliveryEnabled')}
                  className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                    formData.deliveryEnabled ? 'bg-emerald-500' : 'bg-slate-700'
                  }`}
                >
                  <span
                    className={`inline-block h-5 w-5 transform rounded-full bg-white shadow-lg ring-0 transition duration-200 ease-in-out ${
                      formData.deliveryEnabled ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Delivery Fee */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-2">
                  Delivery Fee (₹) <span className="text-red-400">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400 font-mono font-bold">
                    ₹
                  </span>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    required
                    value={formData.deliveryFee}
                    onChange={(e) => handleNumberChange('deliveryFee', e.target.value)}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-9 pr-4 py-2.5 text-sm font-mono focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.deliveryFee && (
                  <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.deliveryFee}</p>
                )}
                <p className="text-[10px] text-slate-500 mt-1">Standard shipping fee charged when subtotal is below threshold.</p>
              </div>

              {/* Free Delivery Threshold */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-2">
                  Free Delivery Above (₹) <span className="text-red-400">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400 font-mono font-bold">
                    ₹
                  </span>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    required
                    value={formData.freeDeliveryThreshold}
                    onChange={(e) => handleNumberChange('freeDeliveryThreshold', e.target.value)}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-9 pr-4 py-2.5 text-sm font-mono focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.freeDeliveryThreshold && (
                  <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.freeDeliveryThreshold}</p>
                )}
                <p className="text-[10px] text-slate-500 mt-1">Orders with subtotal at or above this amount receive free delivery (₹0).</p>
              </div>

              {/* Minimum Delivery Order */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-2">
                  Minimum Delivery Order (₹) <span className="text-red-400">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400 font-mono font-bold">
                    ₹
                  </span>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    required
                    value={formData.minimumOrderAmount}
                    onChange={(e) => handleNumberChange('minimumOrderAmount', e.target.value)}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-9 pr-4 py-2.5 text-sm font-mono focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.minimumOrderAmount && (
                  <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.minimumOrderAmount}</p>
                )}
                <p className="text-[10px] text-slate-500 mt-1">Minimum cart subtotal required to place a delivery order.</p>
              </div>
            </div>
          </div>

          {/* COD Settings Section */}
          <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 sm:p-8 shadow-md space-y-6">
            <div className="flex items-center justify-between border-b border-slate-700/60 pb-4">
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-orange-500/10 text-orange-400 border border-orange-500/20">
                  <Banknote className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-white uppercase tracking-wide">Cash on Delivery (COD) Settings</h3>
                  <p className="text-xs text-slate-400">Configure cash payment availability, handling charges, and min/max limits.</p>
                </div>
              </div>

              {/* COD Enabled Toggle */}
              <div className="flex items-center gap-3">
                <span className="text-xs font-bold text-slate-300">
                  {formData.codEnabled ? 'COD ENABLED' : 'COD DISABLED'}
                </span>
                <button
                  type="button"
                  onClick={() => handleToggle('codEnabled')}
                  className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                    formData.codEnabled ? 'bg-emerald-500' : 'bg-slate-700'
                  }`}
                >
                  <span
                    className={`inline-block h-5 w-5 transform rounded-full bg-white shadow-lg ring-0 transition duration-200 ease-in-out ${
                      formData.codEnabled ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* COD Charge */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-2">
                  COD Charge (₹) <span className="text-red-400">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400 font-mono font-bold">
                    ₹
                  </span>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    required
                    value={formData.codCharge}
                    onChange={(e) => handleNumberChange('codCharge', e.target.value)}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-9 pr-4 py-2.5 text-sm font-mono focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.codCharge && (
                  <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.codCharge}</p>
                )}
                <p className="text-[10px] text-slate-500 mt-1">Additional handling fee added to total order amount for COD orders.</p>
              </div>

              {/* Minimum COD Order */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-2">
                  Minimum COD Order (₹) <span className="text-red-400">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400 font-mono font-bold">
                    ₹
                  </span>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    required
                    value={formData.minimumCodOrderAmount}
                    onChange={(e) => handleNumberChange('minimumCodOrderAmount', e.target.value)}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-9 pr-4 py-2.5 text-sm font-mono focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.minimumCodOrderAmount && (
                  <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.minimumCodOrderAmount}</p>
                )}
                <p className="text-[10px] text-slate-500 mt-1">Orders below this subtotal are not eligible for COD.</p>
              </div>

              {/* Maximum COD Order */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-2">
                  Maximum COD Order (₹) <span className="text-red-400">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400 font-mono font-bold">
                    ₹
                  </span>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    required
                    value={formData.maximumCodOrderAmount}
                    onChange={(e) => handleNumberChange('maximumCodOrderAmount', e.target.value)}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-9 pr-4 py-2.5 text-sm font-mono focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.maximumCodOrderAmount && (
                  <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.maximumCodOrderAmount}</p>
                )}
                <p className="text-[10px] text-slate-500 mt-1">Orders above this subtotal must use online payment.</p>
              </div>
            </div>

            {/* Pickup COD Toggle */}
            <div className="pt-4 border-t border-slate-700/50 flex items-center justify-between">
              <div>
                <p className="text-xs font-bold text-white uppercase tracking-wider">COD for Store Pickup Orders</p>
                <p className="text-xs text-slate-400 mt-0.5">Allow customers to pay in cash during in-store pickup handover.</p>
              </div>

              <div className="flex items-center gap-3">
                <span className="text-xs font-bold text-slate-300">
                  {formData.pickupCodEnabled ? 'PICKUP COD ALLOWED' : 'PICKUP COD BLOCKED'}
                </span>
                <button
                  type="button"
                  onClick={() => handleToggle('pickupCodEnabled')}
                  className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                    formData.pickupCodEnabled ? 'bg-emerald-500' : 'bg-slate-700'
                  }`}
                >
                  <span
                    className={`inline-block h-5 w-5 transform rounded-full bg-white shadow-lg ring-0 transition duration-200 ease-in-out ${
                      formData.pickupCodEnabled ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>
            </div>
          </div>

          {/* Delivery Pincodes Card */}
          <div className="bg-darkbg-800 border border-slate-700/50 rounded-2xl p-6 shadow-md flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="p-2.5 rounded-xl bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                <MapPin className="h-5 w-5" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-white uppercase tracking-wide">Supported Delivery Pincodes</h3>
                <p className="text-xs text-slate-400 mt-0.5">Manage serviceable postal codes, activate or deactivate delivery areas in real-time.</p>
              </div>
            </div>

            <Link
              to="/admin/pincodes"
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-200 text-xs font-bold transition-colors"
            >
              <span>Manage Pincodes</span>
              <span className="text-brand-400 font-bold">→</span>
            </Link>
          </div>

          {/* Info Note Banner */}
          <div className="flex items-start gap-3 bg-slate-900/60 border border-slate-700/60 rounded-xl p-4 text-xs text-slate-400">
            <Info className="h-4 w-4 text-brand-400 shrink-0 mt-0.5" />
            <div>
              <p className="font-bold text-slate-200 mb-0.5">Pricing Engine Integrity</p>
              <p className="leading-relaxed">
                Settings changes apply strictly to new checkouts and orders. All historical orders remain immutable and retain their exact snapshot fees and payment totals. All order calculations are securely enforced server-side.
              </p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center justify-end gap-3 pt-2">
            <button
              type="button"
              disabled={submitting}
              onClick={handleReset}
              className="flex items-center gap-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 px-5 py-2.5 text-xs font-bold transition-colors disabled:opacity-50"
            >
              <RotateCcw className="h-4 w-4" />
              <span>Reset Values</span>
            </button>

            <button
              type="submit"
              disabled={submitting}
              className="flex items-center gap-2 rounded-lg bg-brand-500 hover:bg-brand-600 text-white px-6 py-2.5 text-xs font-bold transition-colors shadow-lg shadow-brand-500/20 disabled:opacity-50"
            >
              {submitting ? (
                <>
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                  <span>Saving Settings...</span>
                </>
              ) : (
                <>
                  <Save className="h-4 w-4" />
                  <span>Save Settings</span>
                </>
              )}
            </button>
          </div>
        </form>
      )}
    </div>
  );
};
