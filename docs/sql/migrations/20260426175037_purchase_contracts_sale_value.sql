-- Add sale_value column to purchase_contracts.
--
-- Until now, the purchase contract had purchase_value (buy price) and
-- total_return (net amount the investor took home) but no explicit sale_value.
-- Mixing both into total_return loses the disposal price and makes
-- accounting confusing. Splitting:
--   - purchase_value : what we paid to acquire
--   - sale_value     : net price received on disposal (NULL until sold)
--   - total_return   : full return for the investor (sale_value + accumulated
--                      rents/dividends − fees, etc.)
--
-- All three are nullable except purchase_value (already NOT NULL). The new
-- column is NULL by default; existing rows are unaffected.

ALTER TABLE public.purchase_contracts
  ADD COLUMN sale_value NUMERIC NULL;

NOTIFY pgrst, 'reload schema';
