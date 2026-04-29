-- Relax FK constraints so deleting an asset or project never blocks.
-- Affected FKs go from NO ACTION / RESTRICT to SET NULL.
-- All four columns drop their NOT NULL to allow the SET NULL action.

BEGIN;

-- projects.asset_id: already SET NULL but column was NOT NULL.
ALTER TABLE projects ALTER COLUMN asset_id DROP NOT NULL;

-- rental_contracts.asset_id: NO ACTION → SET NULL
ALTER TABLE rental_contracts ALTER COLUMN asset_id DROP NOT NULL;
ALTER TABLE rental_contracts DROP CONSTRAINT rental_contracts_asset_id_fkey;
ALTER TABLE rental_contracts
  ADD CONSTRAINT rental_contracts_asset_id_fkey
  FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE SET NULL;

-- purchase_contracts.asset_id: NO ACTION → SET NULL
ALTER TABLE purchase_contracts ALTER COLUMN asset_id DROP NOT NULL;
ALTER TABLE purchase_contracts DROP CONSTRAINT purchase_contracts_asset_id_fkey;
ALTER TABLE purchase_contracts
  ADD CONSTRAINT purchase_contracts_asset_id_fkey
  FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE SET NULL;

-- coinvestment_contracts.project_id: RESTRICT → SET NULL
ALTER TABLE coinvestment_contracts ALTER COLUMN project_id DROP NOT NULL;
ALTER TABLE coinvestment_contracts DROP CONSTRAINT investments_project_id_fkey;
ALTER TABLE coinvestment_contracts
  ADD CONSTRAINT coinvestment_contracts_project_id_fkey
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL;

NOTIFY pgrst, 'reload schema';

COMMIT;
