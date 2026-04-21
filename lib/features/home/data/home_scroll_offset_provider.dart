import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preserves the Home feed page when the user briefly switches to another
/// tab. If the user returns within [ttl], the feed restores to the same card;
/// after that it resets to the first card (they came back for a fresh look).
class HomeFeedPosition {
  const HomeFeedPosition({required this.pageIndex, required this.savedAt});
  final int pageIndex;
  final DateTime savedAt;
}

const _ttl = Duration(minutes: 2);

final homeFeedPositionProvider =
    StateProvider<HomeFeedPosition?>((_) => null);

bool isHomeFeedPositionFresh(HomeFeedPosition? snapshot) {
  if (snapshot == null) return false;
  return DateTime.now().difference(snapshot.savedAt) < _ttl;
}
