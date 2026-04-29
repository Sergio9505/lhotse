-- Migration: user_delete_set_null_contracts
-- Make user_id nullable on all contract tables so deleting a user
-- anonymises contracts instead of blocking (or cascading) the delete.
-- Purely personal data (kyc, notifications, prefs, onboarding, documents,
-- profile) already cascade-deletes correctly; no changes needed there.

ALTER TABLE coinvestment_contracts ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE purchase_contracts      ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE rental_contracts        ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE fixed_income_contracts  ALTER COLUMN user_id DROP NOT NULL;

-- Recreate FKs with ON DELETE SET NULL
ALTER TABLE coinvestment_contracts
  DROP CONSTRAINT investments_user_id_fkey,
  ADD  CONSTRAINT investments_user_id_fkey
       FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE SET NULL;

ALTER TABLE purchase_contracts
  DROP CONSTRAINT purchase_contracts_user_id_fkey,
  ADD  CONSTRAINT purchase_contracts_user_id_fkey
       FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE SET NULL;

ALTER TABLE rental_contracts
  DROP CONSTRAINT rental_contracts_user_id_fkey,
  ADD  CONSTRAINT rental_contracts_user_id_fkey
       FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE SET NULL;

ALTER TABLE fixed_income_contracts
  DROP CONSTRAINT fixed_income_contracts_user_id_fkey,
  ADD  CONSTRAINT fixed_income_contracts_user_id_fkey
       FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE SET NULL;

NOTIFY pgrst, 'reload schema';
