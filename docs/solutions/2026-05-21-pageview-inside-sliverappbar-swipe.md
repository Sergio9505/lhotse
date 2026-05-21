---
date: 2026-05-21
tags: [flutter, ui, gesture-arena, sliver, pageview, hero-carousel, listener, body-level-gestures]
related_adrs: [ADR-70, ADR-71]
---

# Hero carousel swipe + tap broken — final fix: ALL gestures at Scaffold.body level

## Symptom
En `news_detail_screen` y `project_detail_screen`, el `MediaHeroCarousel` mostraba los dots correctamente pero el swipe horizontal NO respondía. Adicionalmente, una iteración intermedia introdujo regresión: el tap-to-fullscreen sobre el hero con vídeo dejó de funcionar. Vertical scroll funcionaba siempre (colapso del hero, header beige). Persistió a través de seis arquitecturas distintas en `MediaHeroCarousel`.

## Diagnosis
**Cualquier gesture handler empotrado en el subárbol de `MediaHeroCarousel` no recibe pointer events en este árbol.** Da igual donde se ponga dentro del widget — falla en todos los casos:
- `PageView.builder` con su HDR interno: dots aparecen, swipe muerto.
- `GestureDetector(opaque, onHorizontalDragUpdate)` envoltorio interno: cero events.
- `Listener(opaque)` + `PageView(NeverScrollable)` + `position.jumpTo`: cero events.
- `Listener(opaque)` con Stack custom de Positioned: cero events.
- `Listener(translucent)` con Stack custom (v5): cero events.

La causa exacta es opaca desde fuera de Flutter — el widget tree es limpio (sin `IgnorePointer`/`AbsorbPointer`/recognizers competidores), las screens están dentro de un `_fadePage` con `FadeTransition` benigna, el `Scaffold` no bloquea, ningún wrapper global intercepta. Pero los handlers empotrados en `MediaHeroCarousel` simplemente no se disparan.

## Fix
Mover **TODOS los gestos del hero** (swipe horizontal del carousel + tap-to-fullscreen del vídeo) a un único `Listener(behavior: HitTestBehavior.translucent)` al nivel `Scaffold.body`, envolviendo el `Stack` de 3 capas (CustomScrollView + carousel overlay + toolbar overlay). El body es la posición más alta del árbol controlado por la app — `MaterialApp.builder` solo añade `MediaQuery + AnnotatedRegion` (benigno), `Navigator` no bloquea, `Scaffold` no bloquea, `FadeTransition` no bloquea. Aquí los pointer events SÍ llegan.

`MediaHeroCarousel` se convierte en `StatelessWidget` pure renderer — recibe `galleryOffset: double` y `galleryIndex: int` como props del screen y solo renderiza el `Stack` de `Positioned` (uno por imagen, `left: i * pageWidth - galleryOffset`). Slot 0 mantiene `Hero(tag: heroTag)` para el shared-element flight. **Sin gesture handling interno.**

El screen mantiene el estado del carousel (`_carouselOffset`, `_carouselIndex`, `_carouselAnim` AnimationController) y los handlers del Listener:

```dart
Listener(
  behavior: HitTestBehavior.translucent,  // events propagan a descendientes (CustomScrollView, GestureDetectors del body)
  onPointerDown: _onPointerDown,
  onPointerMove: (e) => _onPointerMove(e, pageWidth, count, hasGallery),
  onPointerUp: (e) => _onPointerUp(e, pageWidth, count, hasVideo, hasGallery, signedVideoUrl, ...),
  onPointerCancel: (e) => _onPointerCancel(e, pageWidth, count),
  child: Stack(children: [L0, L1, L2]),
)
```

Handlers (resumen):
- **`onPointerDown`**: gate `e.position.dy < _heroHeight` (touch en zona hero). Guarda start position + timestamp.
- **`onPointerMove`**: direction lock por slop (8px). Horizontal → si `hasGallery` + `scrollOffset <= 4` (completamente expandido), actualiza `_carouselOffset` vía setState. Vertical → ignore (propaga a CustomScrollView via translucent).
- **`onPointerUp`**: si direction=horizontal → snap a página más cercana con AnimationController (`easeOutCubic`, 280ms). Si direction=null (tap) + duración <300ms + `belowToolbar` (e.position.dy > topPadding + kToolbarHeight, excluye back button) + `hasVideo` + `signedVideoUrl != null` → `_openVideoPlayer(...)`.
- **`onPointerCancel`**: si direction=horizontal → snap.

El gate `belowToolbar` evita que un tap sobre el back button (que tiene su propio `GestureDetector(opaque)` en L2) dispare DOBLE acción (back navigation + open video). Stack hit-test resuelve el back button normalmente; nuestro Listener (translucent) recibe el mismo evento pero filtra por posición.

`HitTestBehavior.translucent` garantiza que los pointer events propaguen a descendientes — todos los `GestureDetector` del body content (showAllGallery, showMediaGallery items, DESCARGAR FOLLETO) y el back button reciben taps normalmente sin interferencia.

## Antipatrones intentados (los seis fallaron antes de la solución final)

1. **`PageView.gestureRecognizers`** — API inexistente en `PageView` público. Compila fail.
2. **`GestureDetector(opaque) + NeverScrollable + jumpTo`** dentro de `FlexibleSpaceBar.background` — cero events.
3. **Drop `FlexibleSpaceBar`, `PageView` vanilla directo como `flexibleSpace:`** — HDR interno muerto + regresión del beige header.
4. **`Listener(opaque) + PageView(NeverScrollable) + jumpTo`** dentro de `MediaHeroCarousel` con `FlexibleSpaceBar` — cero events.
5. **Stack custom (sin PageView) + `Listener(opaque)`** dentro de `MediaHeroCarousel` en un Stack overlay a nivel `Scaffold.body` — cero events.
6. **Stack custom + `Listener(translucent)` + direction lock + `canSwipe` gate** dentro de `MediaHeroCarousel` — cero events.

Conclusión empírica tras los seis intentos: **el subárbol bajo `MediaHeroCarousel` bloquea gesture handlers por motivos opacos no identificables sin tocar internals de Flutter**. La única salida es mover los handlers al nivel `Scaffold.body`.

## Lesson
Para gestos complejos en heroes interactivos dentro de detail screens, **el Listener vive en `Scaffold.body`**, no empotrado en el widget del hero. El widget del hero es un pure renderer (`StatelessWidget`) que recibe estado del screen vía props. El estado de gestos (offset, index, animation, pointer tracking) vive en el `State` del screen.

Esto:
- Garantiza que pointer events lleguen (Scaffold.body es la posición más alta).
- Unifica swipe + tap en un solo handler.
- Mantiene `HitTestBehavior.translucent` para que body content sigan recibiendo taps (showAllGallery, DESCARGAR FOLLETO, back button, etc.).

Regla general: **si un gesture handler empotrado en un subárbol no se dispara y la causa no es identificable**, mueve el handler al nivel del Scaffold.body. No insistas con técnicas internas más sofisticadas — el árbol bloquea por motivos que no puedes ver.

## How to avoid next time
- **Patrón canónico** para gestos en heroes complejos: Listener al nivel `Scaffold.body`, hero como `Positioned` overlay en un Stack, manual translate-on-scroll con `AnimatedBuilder(scrollController)`, manual toolbar overlay con `AnimatedContainer(color: _heroGone ? beige : transparent)`.
- **Diagnóstico rápido**: si añades `print()` en `onPointerDown` de un Listener empotrado y NO se dispara con clean build → el árbol está bloqueando, mueve al Scaffold.body level. No iteres con detector internos.
- **Verificación end-to-end**: cualquier hero con `imageUrls.length > 1` debe pasar tres tests — (a) swipe horizontal (carrusel avanza con finger-follow + snap, solo cuando completamente expandido), (b) tap-to-video (sobre el hero con vídeo, abre fullscreen), (c) vertical scroll (colapsa hero, dots fade-out, background beige aparece tras el threshold), (d) back button (vuelve atrás sin disparar tap-to-video).
- **Audit-friendly**: el body content (sliver section gestures, CTAs) sigue funcionando con `translucent` Listener — confirmado por construcción del hit-test propagation.
