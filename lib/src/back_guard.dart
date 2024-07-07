// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BackGuard extends StatefulWidget {
  final Widget child;

  /// The snackbar to show
  final SnackBar snackBar;

  /// Condition to pop
  final Future<bool> Function()? onWillPop;

  /// Creates a widget to migrate from WillPopScope toPopScope.
  const BackGuard(
      {super.key, required this.child, this.onWillPop, required this.snackBar});

  @override
  BackGuardState createState() => BackGuardState();
}

class BackGuardState extends State<BackGuard> {
  /// Completer that gets completed whenever the current snack-bar is closed.
  var _closedCompleter = Completer<SnackBarClosedReason>()
    ..complete(SnackBarClosedReason.remove);

  /// Returns whether the current platform is Android.
  bool get _isAndroid => Theme.of(context).platform == TargetPlatform.android;

  /// Returns whether the [BackGuard.snackBar] is currently visible.
  bool get _isSnackBarVisible => !_closedCompleter.isCompleted;

  /// Returns whether the next back navigation of this route will be handled
  /// internally.
  ///
  /// Returns true when there's a widget that inserted an entry into the
  /// local-history of the current route, in order to handle pop. This is done
  /// by [Drawer], for example, so it can close on pop.
  bool get _willHandlePopInternally =>
      ModalRoute.of(context)?.willHandlePopInternally ?? false;

  @override
  Widget build(BuildContext context) {
    assert(() {
      _ensureThatContextContainsScaffold();
      return true;
    }());

    if (_isAndroid) {
      return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (kIsWeb && mounted) {
            Navigator.of(context).pop();
          }
          if (didPop) {
            return;
          }
          if (widget.onWillPop != null) {
            var p = await widget.onWillPop!();
            print(p);
            if (!p) return;
          }
          if (await _handleWillPop()) {
            if (!mounted) return;
            if (context.mounted) {
              if (!Navigator.of(context).canPop()) {
                // MoveToBackground.moveTaskToBack();
              } else {
                Navigator.of(context).pop();
              }
            }
          }
        },
        child: widget.child,
      );
    } else {
      return widget.child;
    }
  }

  /// Handles [BackGuard.onWillPop].
  Future<bool> _handleWillPop() async {
    if (_isSnackBarVisible || _willHandlePopInternally) {
      return true;
    } else {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.hideCurrentSnackBar();
      _closedCompleter = ScaffoldMessenger.of(context)
          .showSnackBar(
            widget.snackBar,
          )
          .closed
          .wrapInCompleter();
      return false;
    }
  }

  /// Throws a [FlutterError] if this widget was not wrapped in a [Scaffold].
  void _ensureThatContextContainsScaffold() {
    if (Scaffold.maybeOf(context) == null) {
      throw FlutterError(
        '`CustomPopScope` must be wrapped in a `Scaffold`.',
      );
    }
  }
}

extension<T> on Future<T> {
  /// Returns a [Completer] that allows checking for this [Future]'s completion.
  ///
  /// See https://stackoverflow.com/a/69731240/6696558.
  Completer<T> wrapInCompleter() {
    final completer = Completer<T>();
    then(completer.complete).catchError(completer.completeError);
    return completer;
  }
}
