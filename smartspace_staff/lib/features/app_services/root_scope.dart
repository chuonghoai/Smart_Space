import 'package:flutter/material.dart';

final rootProviderScopeKeyNotifier = ValueNotifier<Key>(UniqueKey());

/// Resets the root Riverpod ProviderScope, disposing all cached state and notifiers.
void resetRootProviderScope() {
  rootProviderScopeKeyNotifier.value = UniqueKey();
}

