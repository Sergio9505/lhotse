---
date: 2026-06-08
tags: [auth, recovery, supabase, gotrue, lhotse_admin, phone]
related_adrs: [ADR-63, ADR-93]
---

# Investor se ve como viewer / no ve inversiones tras recuperar contraseña (cuentas-fantasma solo-teléfono)

## Symptom
`diegosole@llabe.com` (y otros inversores) entran en la app, se ven como **viewer** y no ven sus
inversiones. En `auth.users` aparecían cuentas creadas sin email ni nombre, pero con móvil verificado.

## Diagnosis
Cadena de 3 fallos:
1. **Causa raíz (`lhotse_admin`):** el panel creaba/editaba usuarios escribiendo el teléfono **solo en
   `user_profiles.phone`**, nunca en `auth.users.phone`. `createUser` no pasaba `phone` a
   `auth.admin.createUser`; `updateUserProfile` hacía `.from("user_profiles").update({ phone })` sin
   tocar `auth`. Pero `auth.users.phone` es la **fuente de verdad** del login/recovery por SMS y
   `user_profiles.phone` es solo un espejo sincronizado por trigger desde `auth` (ADR-63).
2. **Síntoma (`lhotse_app`):** `AuthRepository.sendPhoneOtp` llamaba `signInWithOtp(phone:)` sin
   `shouldCreateUser`. En gotrue la rama de teléfono usa `create_user: true` por defecto → si el
   teléfono no existe en `auth.users`, **crea una cuenta-fantasma vacía** (viewer, sin email, sin
   contratos) y le manda el OTP.
3. El inversor reseteaba la contraseña en la fantasma y quedaba logueado ahí; su cuenta real (con
   contratos y rol `investor`) quedaba intacta pero inaccesible.

Verificado en prod: 8 fantasmas creadas, 50 cuentas *recovery-broken* (teléfono en perfil pero no en
`auth`), 5 cuentas con teléfono en colisión (UNIQUE de `auth.users.phone`).

## Fix
- **DB (migración `20260608190000_auth_phone_backfill_remove_ghosts.sql`):** borrar las 8 fantasma
  (CASCADE limpia perfil/onboarding/consent/sesiones), backfillear `auth.users.phone` desde el espejo
  para 45 cuentas con teléfono único, y nulificar el espejo de las 5 en colisión (quedan en el listado
  "sin móvil" para asignación manual).
- **`lhotse_app` (`features/auth/data/auth_repository.dart`):** `signInWithOtp(phone:, shouldCreateUser:
  false)`. El screen de recovery ya capturaba `AuthException` sin filtrar si el teléfono existe.
- **`lhotse_admin`:** `createUser` pasa `phone` + `phone_confirm` a `auth.admin.createUser`;
  `updateUserProfile` escribe el teléfono con `auth.admin.updateUserById` (y deja que el trigger
  sincronice el espejo) en vez de escribir `user_profiles.phone` directamente; campo teléfono añadido
  al form de alta y al `userCreateSchema`.

## Lesson
`auth.users.phone` es la única fuente de verdad para identidad por teléfono. Escribir el teléfono en el
espejo (`user_profiles.phone`) sin escribirlo en `auth` deja la cuenta irrecuperable por SMS. Y
`signInWithOtp(phone:)` **crea usuario por defecto** — siempre `shouldCreateUser: false` en flujos de
recovery/login que deben encontrar cuentas existentes. Ver ADR-93.

## How to avoid next time
- Regla: toda alta/edición de usuario (en cualquier cliente) escribe el teléfono vía la **Auth Admin
  API** (`createUser`/`updateUserById`), nunca con un UPDATE directo a `user_profiles.phone`.
- Audit query (debe dar 0): `SELECT count(*) FROM public.user_profiles p JOIN auth.users u ON u.id=p.id
  WHERE p.email IS NOT NULL AND p.phone IS NOT NULL AND p.phone<>'' AND u.phone IS NULL;`
- Cualquier `signInWithOtp`/`signUp` por teléfono pasa `shouldCreateUser` explícito.
