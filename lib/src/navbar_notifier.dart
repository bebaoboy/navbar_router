import 'dart:async';

import 'package:flutter/material.dart';
import 'package:navbar_router/src/navbar_router.dart';

class NavbarNotifier extends ChangeNotifier {
  static final NavbarNotifier _singleton = NavbarNotifier._internal();

  static NavbarNotifier get instance => _singleton;

  NavbarNotifier._internal();

  static int? _index;

  static int get currentIndex => _index!;

  static int? _length;

  static set length(int x) {
    _length = x;
  }

  static int get length => _length!;

  static bool _hideBottomNavBar = false;

  static final List<int> _navbarStackHistory = [];

  static List<GlobalKey<NavigatorState>> _keys = [];

  static void setKeys(List<GlobalKey<NavigatorState>> value) {
    _keys = value;
  }

  static List<GlobalKey<NavigatorState>> get keys => _keys;

  set index(int x) {
    _index = x;
    if (_navbarStackHistory.contains(x)) {
      _navbarStackHistory.remove(x);
    }
    _navbarStackHistory.add(x);
    notifyIndexChangeListeners(x);
    _singleton.notify();
  }

  static List<int> get stackHistory => _navbarStackHistory;

  static bool get isNavbarHidden => _hideBottomNavBar;

  set hideBottomNavBar(bool x) {
    _hideBottomNavBar = x;
    _singleton.notify();
  }

  // adds a listener to the list of listeners
  void addIndexChangeListener(Function(int) listener) {
    _indexChangeListeners.add(listener);
  }

  // removes the last listener that was added
  static void removeLastListener() {
    _indexChangeListeners.removeLast();
  }

  static final List<Function(int)> _indexChangeListeners = [];

  static void notifyIndexChangeListeners(int index) {
    for (Function(int) listener in _indexChangeListeners) {
      listener(index);
    }
  }

  // pop routes from the nested navigator stack and not the main stack
  // this is done based on the currentIndex of the bottom navbar
  // if the backButton is pressed on the initial route the app will be terminated
  FutureOr<bool> onBackButtonPressed(
      {BackButtonBehavior behavior =
          BackButtonBehavior.rememberHistory}) async {
    bool exitingApp = true;
    NavigatorState? currentState = _keys[_index!].currentState;
    if (currentState != null && currentState.canPop()) {
      currentState.pop();
      exitingApp = false;
    } else {
      if (behavior == BackButtonBehavior.rememberHistory) {
        if (_navbarStackHistory.length > 1) {
          _navbarStackHistory.removeLast();
          _index = _navbarStackHistory.last;
          _singleton.notify();
          exitingApp = false;
        } else {
          return exitingApp;
        }
      } else {
        return exitingApp;
      }
    }
    return exitingApp;
  }

  static void popRoute(int index) {
    NavigatorState? currentState;
    currentState = _keys[index].currentState;
    if (currentState != null && currentState.canPop()) {
      currentState.pop();
    }
  }

  // pops all routes except first, if there are more than 1 route in each navigator stack
  static void popAllRoutes(int index) {
    NavigatorState? currentState;
    for (int i = 0; i < _keys.length; i++) {
      if (_index == i) {
        currentState = _keys[i].currentState;
      }
    }
    if (currentState != null && currentState.canPop()) {
      currentState.popUntil((route) => route.isFirst);
    }
  }

  void notify() {
    notifyListeners();
  }

  static void clear() {
    _indexChangeListeners.clear();
    _navbarStackHistory.clear();
    _keys.clear();
    _index = null;
    _length = null;
  }
}
