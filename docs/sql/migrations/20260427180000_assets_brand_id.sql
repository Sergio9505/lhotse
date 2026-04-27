-- assets.brand_id: la firma propietaria del activo.
-- Nullable porque un activo puede crearse antes de saber a qué firma pertenece.
-- ON DELETE SET NULL para no perder activos si una firma se elimina.
ALTER TABLE assets
  ADD COLUMN brand_id UUID NULL REFERENCES brands(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_assets_brand_id ON assets(brand_id);

-- Backfill: asignar la firma del contrato de adquisición más reciente a los
-- activos que ya tenían operación, para no obligar al admin a reasignar
-- manualmente lo que ya estaba implícito en el contrato.
WITH latest_pc AS (
  SELECT DISTINCT ON (asset_id) asset_id, brand_id
  FROM purchase_contracts
  ORDER BY asset_id, created_at DESC
)
UPDATE assets a
SET brand_id = pc.brand_id
FROM latest_pc pc
WHERE a.id = pc.asset_id AND a.brand_id IS NULL;

NOTIFY pgrst, 'reload schema';
