import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import type { PaginationMeta } from '../utils/pagination';

interface PaginationProps {
  pagination: PaginationMeta;
  itemLabel: string;
  onPageChange: (page: number) => void;
}

/** Server-side pagination footer shared by admin list tables. */
export const Pagination: React.FC<PaginationProps> = ({ pagination, itemLabel, onPageChange }) => {
  const totalPages = Math.max(1, pagination.totalPages);

  return (
    <div className="flex items-center justify-between px-5 py-4 bg-slate-900/40 border-t border-slate-800 text-xs text-slate-400">
      <div>
        Showing page <strong className="text-slate-200">{pagination.page}</strong> of{' '}
        <strong className="text-slate-200">{totalPages}</strong> ({pagination.total} total {itemLabel})
      </div>

      <div className="flex items-center gap-2">
        <button
          type="button"
          aria-label="Previous page"
          disabled={pagination.page <= 1}
          onClick={() => onPageChange(pagination.page - 1)}
          className="p-1.5 rounded bg-slate-800 hover:bg-slate-750 text-slate-300 disabled:opacity-40"
        >
          <ChevronLeft className="h-4 w-4" />
        </button>
        <button
          type="button"
          aria-label="Next page"
          disabled={pagination.page >= totalPages}
          onClick={() => onPageChange(pagination.page + 1)}
          className="p-1.5 rounded bg-slate-800 hover:bg-slate-750 text-slate-300 disabled:opacity-40"
        >
          <ChevronRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
};
