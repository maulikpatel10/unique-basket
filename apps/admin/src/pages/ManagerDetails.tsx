import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import {
  ArrowLeft,
  User,
  Mail,
  Shield,
  Clock,
  Store as StoreIcon,
  MapPin,
  AlertCircle
} from 'lucide-react';

interface ManagerDetailsData {
  id: string;
  name: string;
  email: string;
  role: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  storeId: string | null;
  storeIdString: string | null;
  storeName: string | null;
  storeAddress: string | null;
}

export const ManagerDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [manager, setManager] = useState<ManagerDetailsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchManagerDetails = async () => {
      try {
        setLoading(true);
        setError(null);
        const res = await api.get(`/admin/managers/${id}`);
        setManager(res.data.data);
      } catch (err: any) {
        console.error('Error fetching manager profile details:', err);
        setError('Failed to load store manager profile. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    if (id) {
      fetchManagerDetails();
    }
  }, [id]);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <div className="h-8 w-8 bg-slate-800 rounded-full animate-pulse"></div>
          <div className="h-8 w-48 bg-slate-800 rounded-lg animate-pulse"></div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="h-64 bg-slate-800 rounded-xl animate-pulse"></div>
          <div className="h-64 bg-slate-800 rounded-xl animate-pulse"></div>
        </div>
      </div>
    );
  }

  if (error || !manager) {
    return (
      <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl space-y-4">
        <AlertCircle className="h-10 w-10 text-red-400 mx-auto" />
        <p className="text-red-400 text-sm font-semibold">{error || 'Store Manager profile not found.'}</p>
        <button
          onClick={() => navigate('/admin/managers')}
          className="flex items-center gap-2 mx-auto rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Managers
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header Bar */}
      <div className="flex items-center justify-between border-b border-slate-700 pb-4">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate('/admin/managers')}
            className="rounded-lg p-2 text-slate-400 hover:bg-slate-800 hover:text-white transition-all duration-150"
          >
            <ArrowLeft className="h-5 w-5" />
          </button>
          <div>
            <div className="flex items-center gap-3">
              <h2 className="text-2xl font-bold text-white">{manager.name}</h2>
              <span
                className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border ${
                  manager.isActive
                    ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                    : 'bg-red-500/10 text-red-400 border-red-500/20'
                }`}
              >
                {manager.isActive ? 'ACTIVE' : 'INACTIVE'}
              </span>
            </div>
            <p className="text-slate-400 text-xs mt-1">Role Type: {manager.role.replace('_', ' ')}</p>
          </div>
        </div>
      </div>

      {/* Details Grid layout */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Profile Card */}
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md">
          <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6 flex items-center gap-2">
            <User className="h-4.5 w-4.5 text-brand-400" />
            Manager Credentials & Meta
          </h3>

          <div className="space-y-5">
            <div className="flex gap-3">
              <Mail className="h-5 w-5 text-slate-400 mt-0.5 shrink-0" />
              <div>
                <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Email Address</p>
                <p className="text-sm text-slate-200 mt-1">{manager.email}</p>
              </div>
            </div>

            <div className="flex gap-3">
              <Shield className="h-5 w-5 text-slate-400 mt-0.5 shrink-0" />
              <div>
                <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Security Access Level</p>
                <p className="text-sm text-brand-400 font-bold mt-1 uppercase tracking-wide">
                  Store isolated manager
                </p>
                <p className="text-[10px] text-slate-400 mt-0.5 leading-relaxed">
                  Has operational CRUD controls restricted to the assigned store only. Bypasses are blocked by the database.
                </p>
              </div>
            </div>

            <div className="flex gap-3">
              <Clock className="h-5 w-5 text-slate-400 mt-0.5 shrink-0" />
              <div>
                <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Registered Since</p>
                <p className="text-sm text-slate-200 mt-1">
                  {new Date(manager.createdAt).toLocaleDateString('en-IN', {
                    day: 'numeric',
                    month: 'long',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Assigned Store Details Card */}
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-6 shadow-md">
          <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6 flex items-center gap-2">
            <StoreIcon className="h-4.5 w-4.5 text-brand-400" />
            Assigned Store Outlet Mapping
          </h3>

          {manager.storeId ? (
            <div className="space-y-5">
              <div>
                <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Assigned Store ID</p>
                <p className="text-base font-bold text-white mt-1 font-mono">{manager.storeIdString}</p>
              </div>

              <div>
                <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Outlet Name</p>
                <p className="text-sm font-bold text-slate-200 mt-1">{manager.storeName}</p>
              </div>

              <div className="flex gap-2 text-slate-300">
                <MapPin className="h-5 w-5 text-slate-400 mt-0.5 shrink-0" />
                <div>
                  <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Physical Address</p>
                  <p className="text-xs text-slate-300 mt-1 whitespace-pre-line leading-relaxed">
                    {manager.storeAddress || 'No address logged'}
                  </p>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-12 border border-dashed border-slate-700 rounded-lg">
              <p className="text-slate-400 text-sm">This manager has no active store assignment.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
