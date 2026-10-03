import { describe, expect, it } from 'vitest';
import { describeQuantityRule, quantityConfigPayload, validateQuantityConfig } from './quantityRules';

// D-012: admin-side validation of product quantity rules.
const cfg = (minQuantity: string, maxQuantity: string, quantityStep: string) => ({ minQuantity, maxQuantity, quantityStep });

describe('validateQuantityConfig', () => {
  it('accepts the example configurations', () => {
    expect(validateQuantityConfig('KG', cfg('1', '10', '0.25'))).toEqual({});
    expect(validateQuantityConfig('KG', cfg('0.5', '5', '0.25'))).toEqual({});
    expect(validateQuantityConfig('GRAM', cfg('250', '2000', '250'))).toEqual({});
    expect(validateQuantityConfig('PIECE', cfg('1', '10', '1'))).toEqual({});
  });

  it('allows leaving all fields empty', () => {
    expect(validateQuantityConfig('KG', cfg('', '', ''))).toEqual({});
  });

  it('requires all three fields together', () => {
    expect(validateQuantityConfig('KG', cfg('1', '', '0.25')).maxQuantity).toMatch(/required/);
  });

  it('rejects zero/negative/non-numeric values', () => {
    expect(validateQuantityConfig('KG', cfg('0', '10', '0.25')).minQuantity).toMatch(/greater than 0/);
    expect(validateQuantityConfig('KG', cfg('1', '10', '-1')).quantityStep).toMatch(/greater than 0/);
    expect(validateQuantityConfig('KG', cfg('abc', '10', '1')).minQuantity).toMatch(/greater than 0/);
  });

  it('rejects max below min, oversized step and unreachable max', () => {
    expect(validateQuantityConfig('KG', cfg('5', '2', '0.5')).maxQuantity).toMatch(/greater than or equal/);
    expect(validateQuantityConfig('KG', cfg('1', '1.5', '1')).quantityStep).toMatch(/larger than the range/);
    expect(validateQuantityConfig('KG', cfg('1', '10', '0.4')).maxQuantity).toMatch(/reachable/);
  });

  it('enforces unit precision', () => {
    expect(validateQuantityConfig('PIECE', cfg('1', '10', '0.5')).quantityStep).toMatch(/whole number/);
    expect(validateQuantityConfig('GRAM', cfg('250.5', '2000', '250')).minQuantity).toMatch(/whole number/);
    expect(validateQuantityConfig('KG', cfg('0.0001', '1', '0.25')).minQuantity).toMatch(/at most 3 decimals/);
  });
});

describe('quantityConfigPayload / describeQuantityRule', () => {
  it('builds the request payload', () => {
    expect(quantityConfigPayload(cfg('1', '10', '0.25'))).toEqual({ minQuantity: 1, maxQuantity: 10, quantityStep: 0.25 });
    expect(quantityConfigPayload(cfg('', '', ''))).toEqual({ minQuantity: null, maxQuantity: null, quantityStep: null });
  });

  it('summarises a configured rule and reports unconfigured products', () => {
    expect(describeQuantityRule('KG', { minQuantity: '1.000', maxQuantity: '10.000', quantityStep: '0.250' })).toBe('1–10 KG · step 0.25');
    expect(describeQuantityRule('KG', { minQuantity: null, maxQuantity: null, quantityStep: null })).toBeNull();
  });
});
