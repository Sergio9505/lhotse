-- Repoint rental_contracts.user_id FK from auth.users(id) to public.user_profiles(id).
--
-- The constraint already existed but targeted the auth schema, which PostgREST
-- does not expose for resource embedding. As a result, queries like
-- `select=*,user_profiles!user_id(...)` returned PGRST200 and the asset detail
-- timeline silently dropped rental events.
--
-- Sister tables (purchase_contracts, coinvestment_contracts, fixed_income_contracts,
-- kyc_documents, notifications, notification_preferences) already point at
-- public.user_profiles. user_profiles.id itself is FK-bound to auth.users.id,
-- so transitive integrity is preserved.
--
-- Existing data has been verified to satisfy the constraint (every
-- rental_contracts.user_id maps to an existing user_profiles.id).

ALTER TABLE public.rental_contracts
  DROP CONSTRAINT rental_contracts_user_id_fkey;

ALTER TABLE public.rental_contracts
  ADD CONSTRAINT rental_contracts_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.user_profiles(id);

NOTIFY pgrst, 'reload schema';
