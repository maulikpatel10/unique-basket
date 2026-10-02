import { Request } from 'express';

/**
 * Express 5 types route params as `string | string[]`.
 * Returns a single string value for a named route param.
 */
export function getParam(req: Request, name: string): string {
  const value = req.params[name];
  if (Array.isArray(value)) {
    return value[0] ?? '';
  }
  return value ?? '';
}
