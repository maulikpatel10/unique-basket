export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export const ADMIN_PAGE_SIZE = 20;

export const emptyPagination: PaginationMeta = { total: 0, page: 1, limit: ADMIN_PAGE_SIZE, totalPages: 1 };
