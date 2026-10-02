import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import {
  ScrollText,
  Search,
  Filter,
  Calendar,
  Eye,
  ChevronLeft,
  ChevronRight,
  Shield,
  Activity,
  X
} from 'lucide-react';
import { asApiError } from '../utils/apiError';

interface AuditLogItem {
  id: string;
  adminUserId: string | null;
  action: string;
  details: string | null;
  createdAt: string;
  adminUser?: {
    id: string;
    name: string;
    email: string;
    role: string;
  } | null;
}

interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export const AuditLogs: React.FC = () => {
  const [logs, setLogs] = useState<AuditLogItem[]>([]);
  const [actions, setActions] = useState<string[]>([]);
  const [pagination, setPagination] = useState<PaginationMeta>({
    total: 0,
    page: 1,
    limit: 15,
    totalPages: 1,
  });

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedAction, setSelectedAction] = useState('ALL');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Detail inspection modal
  const [selectedLog, setSelectedLog] = useState<AuditLogItem | null>(null);

  // Fetch distinct actions on mount
  useEffect(() => {
    const fetchActions = async () => {
      try {
        const res = await api.get('/admin/audit-logs/actions');
        setActions(res.data.data);
      } catch (err) {
        console.error('Failed to load audit actions:', err);
      }
    };
    fetchActions();
  }, []);

  const fetchLogs = async (page: number = 1) => {
    try {
      setLoading(true);
      setError(null);

      const params: Record<string, unknown> = {
        page,
        limit: 15,
      };

      if (searchTerm.trim()) params.search = searchTerm.trim();
      if (selectedAction !== 'ALL') params.action = selectedAction;
      if (startDate) params.startDate = startDate;
      if (endDate) params.endDate = endDate;

      const res = await api.get('/admin/audit-logs', { params });
      setLogs(res.data.data.auditLogs);
      setPagination(res.data.data.pagination);
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error fetching audit logs:', err);
      setError(err.response?.data?.message || 'Failed to load system audit logs.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs(1);
  }, [selectedAction, startDate, endDate]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchLogs(1);
  };

  const getActionBadgeColor = (action: string) => {
    if (action.includes('CREATE')) {
      return 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20';
    }
    if (action.includes('DELETE') || action.includes('DEACTIVATE') || action.includes('CANCEL')) {
      return 'bg-red-500/10 text-red-400 border-red-500/20';
    }
    if (action.includes('UPDATE') || action.includes('STATUS')) {
      return 'bg-sky-500/10 text-sky-400 border-sky-500/20';
    }
    return 'bg-amber-500/10 text-amber-400 border-amber-500/20';
  };

  return (
    <div className="relative space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-2.5">
            <ScrollText className="h-6 w-6 text-brand-400" />
            <span>System Audit Logs</span>
          </h2>
          <p className="text-slate-400 text-sm mt-1">
            Immutable tracking log for all administrative modifications, cancellations, and security events.
          </p>
        </div>
      </div>

      {/* Filters Bar */}
      <div className="flex flex-col md:flex-row gap-4 bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl shadow-md">
        <form onSubmit={handleSearchSubmit} className="relative flex-1">
          <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
            <Search className="h-4 w-4" />
          </span>
          <input
            type="text"
            placeholder="Search action, details, admin name, or email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
          />
        </form>

        <div className="flex flex-wrap gap-3 items-center">
          <div className="flex items-center gap-2">
            <Filter className="h-4 w-4 text-slate-400" />
            <select
              value={selectedAction}
              onChange={(e) => setSelectedAction(e.target.value)}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none max-w-xs"
            >
              <option value="ALL">All Actions ({actions.length})</option>
              {actions.map((act) => (
                <option key={act} value={act}>
                  {act}
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-center gap-2 bg-slate-900 border border-slate-700 rounded-lg px-2.5 py-1.5 text-xs text-slate-300">
            <Calendar className="h-3.5 w-3.5 text-slate-400" />
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="bg-transparent text-slate-200 outline-none text-xs"
              title="Start Date"
            />
            <span className="text-slate-500">to</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="bg-transparent text-slate-200 outline-none text-xs"
              title="End Date"
            />
            {(startDate || endDate) && (
              <button
                type="button"
                onClick={() => {
                  setStartDate('');
                  setEndDate('');
                }}
                className="text-slate-400 hover:text-white"
                title="Clear Dates"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Audit Logs Table */}
      {loading ? (
        <div className="space-y-4">
          <div className="h-10 bg-slate-800 rounded-lg animate-pulse" />
          {[1, 2, 3, 4, 5].map((i) => (
            <div key={i} className="h-16 bg-slate-800/60 rounded-lg animate-pulse" />
          ))}
        </div>
      ) : error ? (
        <div className="text-center py-12 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-red-400 text-sm font-semibold">{error}</p>
          <button
            onClick={() => fetchLogs(1)}
            className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
          >
            Retry
          </button>
        </div>
      ) : logs.length === 0 ? (
        <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <Activity className="h-10 w-10 text-slate-600 mx-auto mb-3" />
          <p className="text-slate-400 text-sm font-medium">No audit log records match your filter criteria.</p>
        </div>
      ) : (
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 overflow-hidden shadow-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-5 py-4">Timestamp</th>
                  <th className="px-5 py-4">Action</th>
                  <th className="px-5 py-4">Performed By</th>
                  <th className="px-5 py-4">Activity Description</th>
                  <th className="px-5 py-4 text-center">Inspect</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {logs.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-800/10 transition-colors">
                    <td className="px-5 py-4 whitespace-nowrap font-mono text-xs text-slate-300">
                      {new Date(log.createdAt).toLocaleString('en-IN', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                        second: '2-digit',
                      })}
                    </td>
                    <td className="px-5 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border font-mono ${getActionBadgeColor(
                          log.action
                        )}`}
                      >
                        {log.action}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      {log.adminUser ? (
                        <div>
                          <p className="font-bold text-white text-xs">{log.adminUser.name}</p>
                          <p className="text-[10px] font-mono text-slate-400">{log.adminUser.email}</p>
                        </div>
                      ) : (
                        <span className="text-slate-500 text-xs italic">System / Unassigned</span>
                      )}
                    </td>
                    <td className="px-5 py-4">
                      <p className="text-xs text-slate-300 line-clamp-2 max-w-lg leading-relaxed">
                        {log.details || '—'}
                      </p>
                    </td>
                    <td className="px-5 py-4 text-center">
                      <button
                        onClick={() => setSelectedLog(log)}
                        title="View Full Audit Record"
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
              Showing page <strong className="text-slate-200">{pagination.page}</strong> of{' '}
              <strong className="text-slate-200">{pagination.totalPages}</strong> ({pagination.total} total audit records)
            </div>

            <div className="flex items-center gap-2">
              <button
                disabled={pagination.page <= 1}
                onClick={() => fetchLogs(pagination.page - 1)}
                className="p-1.5 rounded bg-slate-800 hover:bg-slate-750 text-slate-300 disabled:opacity-40"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <button
                disabled={pagination.page >= pagination.totalPages}
                onClick={() => fetchLogs(pagination.page + 1)}
                className="p-1.5 rounded bg-slate-800 hover:bg-slate-750 text-slate-300 disabled:opacity-40"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Inspect Audit Log Modal */}
      {selectedLog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setSelectedLog(null)} />

          <div className="relative w-full max-w-lg rounded-2xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-700 pb-3">
              <div className="flex items-center gap-2">
                <Shield className="h-5 w-5 text-brand-400" />
                <h3 className="text-base font-bold text-white">Audit Log Record</h3>
              </div>
              <button
                onClick={() => setSelectedLog(null)}
                className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-slate-700"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-slate-900/60 p-3 rounded-xl border border-slate-700/50">
                  <span className="text-[10px] uppercase font-bold text-slate-400">Action</span>
                  <p className="mt-1 font-mono font-bold text-white">{selectedLog.action}</p>
                </div>
                <div className="bg-slate-900/60 p-3 rounded-xl border border-slate-700/50">
                  <span className="text-[10px] uppercase font-bold text-slate-400">Timestamp</span>
                  <p className="mt-1 font-mono text-slate-300">
                    {new Date(selectedLog.createdAt).toLocaleString('en-IN')}
                  </p>
                </div>
              </div>

              <div className="bg-slate-900/60 p-3 rounded-xl border border-slate-700/50 space-y-1">
                <span className="text-[10px] uppercase font-bold text-slate-400">Performed By</span>
                {selectedLog.adminUser ? (
                  <div>
                    <p className="font-bold text-white">{selectedLog.adminUser.name}</p>
                    <p className="text-slate-400 font-mono text-[11px]">{selectedLog.adminUser.email} ({selectedLog.adminUser.role})</p>
                    <p className="text-[10px] font-mono text-slate-500 mt-0.5">Admin ID: {selectedLog.adminUser.id}</p>
                  </div>
                ) : (
                  <p className="text-slate-500 italic">System / Unassigned</p>
                )}
              </div>

              <div className="bg-slate-900/60 p-3 rounded-xl border border-slate-700/50 space-y-1">
                <span className="text-[10px] uppercase font-bold text-slate-400">Log Details</span>
                <p className="text-slate-200 whitespace-pre-wrap leading-relaxed font-mono text-[11px]">
                  {selectedLog.details || 'No additional details logged.'}
                </p>
              </div>

              <div className="bg-slate-900/60 p-3 rounded-xl border border-slate-700/50">
                <span className="text-[10px] uppercase font-bold text-slate-400">Audit Record ID</span>
                <p className="mt-1 font-mono text-[10px] text-slate-400 select-all">{selectedLog.id}</p>
              </div>
            </div>

            <div className="flex justify-end pt-2">
              <button
                type="button"
                onClick={() => setSelectedLog(null)}
                className="rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-5 py-2 text-xs font-bold"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
