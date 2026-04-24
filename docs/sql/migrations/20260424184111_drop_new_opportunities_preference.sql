-- ============================================================================
-- Migration: drop_new_opportunities_preference
-- Principles applied: #4 (dead column removal — consumer removed).
-- Consumers: none after this migration.
-- Co-loaded pairs: n/a.
-- Dead fields dropped:
--   notification_preferences.new_opportunities
--     Consumer removed: NotificationPreferences.newOpportunities field,
--     _ToggleRow "Nuevas oportunidades" in NotificationsScreen — both
--     deleted in the same commit that removes the opportunities feature.
-- New fields added: none.
-- Denormalization justifications: n/a.
-- Rollback: ALTER TABLE notification_preferences ADD COLUMN new_opportunities BOOLEAN NOT NULL DEFAULT TRUE;
-- ============================================================================

ALTER TABLE notification_preferences DROP COLUMN IF EXISTS new_opportunities;

NOTIFY pgrst, 'reload schema';
