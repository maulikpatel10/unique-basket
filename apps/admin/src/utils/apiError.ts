/** Shape of the error fields the admin pages read from failed API calls (axios errors or thrown Errors). */
export interface ApiErrorLike {
  message?: string;
  response?: {
    status?: number;
    data?: {
      message?: string;
      errorCode?: string;
    };
  };
}

/** Narrows an unknown caught value to the fields the UI reads, without using `any`. */
export const asApiError = (caught: unknown): ApiErrorLike =>
  typeof caught === 'object' && caught !== null ? (caught as ApiErrorLike) : {};
