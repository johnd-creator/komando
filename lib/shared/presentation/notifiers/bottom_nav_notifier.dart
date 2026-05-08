import 'package:flutter/material.dart';

class BottomNavNotifier extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void goToTab(int index) {
    if (_index != index) {
      _index = index;
      notifyListeners();
    }
  }
}

class BottomNavScope extends InheritedNotifier<BottomNavNotifier> {
  const BottomNavScope({
    required super.child,
    required BottomNavNotifier notifier,
    super.key,
  }) : super(notifier: notifier);

  static BottomNavNotifier of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BottomNavScope>();
    assert(scope != null,
        'No BottomNavScope found in context. Make sure to wrap with BottomNavScope.');
    return scope!.notifier!;
  }
}
