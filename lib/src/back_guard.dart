// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackGuard extends StatefulWidget {
  final Widget child;

  /// Condition to pop
  final Future<bool> Function()? onWillPop;

  /// Creates a widget to migrate from WillPopScope toPopScope.
  const BackGuard({super.key, required this.child, this.onWillPop});

  @override
  BackGuardState createState() => BackGuardState();
}

class BackGuardState extends State<BackGuard> {
  bool get _isAndroid => Theme.of(context).platform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (Scaffold.maybeOf(context) == null) {
        throw FlutterError(
          '`CustomPopScope` must be wrapped in a `Scaffold`.',
        );
      }
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

          /// Returns whether the next back navigation of this route will be handled
          /// internally.
          /// This is done by [Drawer], for example, so it can close on pop.
          // if (ModalRoute.of(context)?.willHandlePopInternally ?? false) {
          //   Navigator.of(context).pop();
          //   return;
          // }

          if (widget.onWillPop != null) {
            var p = await widget.onWillPop!();
            log("$p");
            if (!p) return;
          }
          if (!mounted) return;
          if (context.mounted) {
            if (!Navigator.of(context).canPop()) {
              // MoveToBackground.moveTaskToBack();

              // This won't work for PopScope. See https://github.com/flutter/flutter/issues/147919
              // Navigator.of(context).pop();

              // Exit the app
              SystemNavigator.pop();
            } else {
              Navigator.of(context).pop();
            }
          }
        },
        child: widget.child,
      );
    } else {
      return widget.child;
    }
  }
}
