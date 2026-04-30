---
date: 2026-04-30
tags: [riverpod, async, ux, error-handling, valueOrNull, when]
related_adrs: []
---

# `valueOrNull ?? []` en contenido principal — error silenciado como "lista vacía"

## Symptom

Una pantalla muestra contenido vacío ("sin resultados", lista a cero) cuando en realidad hubo un error de red o de RLS. El usuario no ve mensaje de error ni botón de reintento; simplemente ve que "no hay nada". Difícil de diagnosticar porque el síntoma (vacío) es idéntico al estado de datos legítimamente vacíos.

## Diagnosis

`ref.watch(provider).valueOrNull ?? const []` aplasta los tres estados de `AsyncValue<T>` en uno:

```
AsyncLoading  →  []
AsyncError    →  []
AsyncData([]) →  []
```

La causa raíz del bug del L3 Docs (ver `2026-04-30-l3-docs-multi-scope.md`) permaneció invisible semanas porque este patrón ocultaba el error de la query. El mismo anti-pattern estaba replicado en 11 callsites de contenido primario en 5 pantallas.

## Fix

Barrido completo del repo (66 ocurrencias de `valueOrNull`). Para cada callsite de **contenido principal** (el que define lo que el usuario vino a ver), migrar a `.when(loading, error, data)` o a un if/else explícito sobre `isLoading`/`hasError`:

```dart
newsAsync.when(
  loading: () => const LhotseAsyncLoading(),
  error: (_, _) => LhotseAsyncError(
    message: 'No se pudieron cargar las noticias.',
    onRetry: () => ref.invalidate(newsProvider),
  ),
  data: (_) => ... /* lista o "SIN RESULTADOS" */,
)
```

Widget compartido `lib/core/widgets/lhotse_async_list_states.dart` → `LhotseAsyncLoading` + `LhotseAsyncError` para mantener el grammar Sotheby's-luxe consistente en todas las pantallas migradas.

Callsites migrados: `search_screen.dart`, `news_archive_body.dart`, `projects_archive_body.dart`, `notifications_sheet.dart`, `investments_screen.dart`, `brand_investments_screen.dart`.

## Lesson

"Ocultar errores = mejor UX" es un malentendido. El usuario ve un estado peor ("la app olvidó mis datos") que un mensaje calmado con retry. El error es parte del UX, no contra él.

## Cuándo SÍ usar `valueOrNull`

| Caso | Razón |
|---|---|
| Auth-gating dentro de providers (`currentUserIdProvider.valueOrNull`) | Guard interno, no UI |
| Hero-transition-gap (`?? widget.initialProject`) | Patrón intencional para evitar parpadeo en transiciones |
| Counters/badges de notificación | Decoración: degradar a "sin badge" es correcto |
| Mapas de iconos/categorías | Decoración: fallback a icono genérico pre-implementado |
| Subtítulos contextuales (contratos para enriquecer docs) | Decoración: el doc se ve sin subtítulo |
| Settings con defaults razonables (NotificationPreferences) | Si falla, default = todo desactivado (sensato) |

## How to avoid next time

Antes de escribir `ref.watch(myProvider).valueOrNull ?? const []`, pregúntate: "Si este provider falla, ¿el usuario sabrá que algo fue mal?". Si la respuesta es no, usar `.when()`. Regla en `docs/CONVENTIONS.md § State Management (Riverpod)`.
