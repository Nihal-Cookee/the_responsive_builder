import 'dart:async';
import 'dart:ui' show FlutterView, Size;

import 'package:flutter/material.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

/// A typedef for a function that returns a widget based on the BuildContext, current Orientation, and ScreenType.
typedef ResponsiveBuild = Widget Function(
  BuildContext,
  Orientation,
  ScreenType,
);

/// This is a custom widget that helps in building responsive UI based on the screen size and orientation.
class TheResponsiveBuilder extends StatefulWidget {
  /// Constructor to initialize the ResponsiveBuilder with a required builder function.
  const TheResponsiveBuilder({
    super.key,
    this.mobileBreakPoint = 600.0,
    this.desktopBreakPoint = 1024.0,
    this.enableDesktopMode = false,
    this.enableTextScaleFactor = true,
    required this.builder,
    this.baselineWidth = 375.0,
    this.baselineHeight = 667.0,
    this.metricsSettleDelay = const Duration(milliseconds: 120),
  });

  /// The builder function which will be used to create the responsive UI.
  final ResponsiveBuild builder;

  final bool enableTextScaleFactor;
  final bool enableDesktopMode;

  final double baselineWidth;
  final double baselineHeight;

  /// The breakPoint is the width at which the UI should switch from mobile to tablet mode.
  final double mobileBreakPoint;
  final double desktopBreakPoint;

  /// How long to wait after the last viewport metrics change before treating
  /// the rotation as settled and triggering a rebuild.
  ///
  /// Android/iOS report several transient intermediate sizes while a rotation
  /// animation is in progress. Debouncing ensures we only rebuild once the
  /// size has actually settled, so widgets that compute `.w`/`.h`/`.dp`
  /// inline in build() always see the correct final value.
  final Duration metricsSettleDelay;

  @override
  State<TheResponsiveBuilder> createState() => _TheResponsiveBuilderState();
}

class _TheResponsiveBuilderState extends State<TheResponsiveBuilder>
    with WidgetsBindingObserver {
  Timer? _settleTimer;
  Size? _lastLogicalSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Seed the tracked size from the current view so the very first
    // didChangeMetrics (which always fires shortly after startup) is a no-op.
    _lastLogicalSize = _currentLogicalSize();
  }

  Size? _currentLogicalSize() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final FlutterView? view =
        WidgetsBinding.instance.platformDispatcher.implicitView ??
            (views.isNotEmpty ? views.first : null);
    if (view == null) return null;
    return Size(
      view.physicalSize.width / view.devicePixelRatio,
      view.physicalSize.height / view.devicePixelRatio,
    );
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final Size? logicalSize = _currentLogicalSize();
    if (logicalSize == null) return;
    // Ignore metrics changes that do not change the actual view size (e.g.
    // keyboard insets) so we only react to real size changes like rotation.
    if (logicalSize == _lastLogicalSize) return;
    _lastLogicalSize = logicalSize;

    _settleTimer?.cancel();
    _settleTimer = Timer(widget.metricsSettleDelay, () {
      if (!mounted) return;
      // Plain rebuild only - deliberately NOT changing any Key here.
      // Changing a Key on an ancestor of MaterialApp.router would force a
      // full dispose+remount of the Navigator/Router below it (route stack,
      // guards, redirects), which shows up as the whole app restarting from
      // splash on every rotation. A normal setState is enough to make every
      // widget that computes `.w`/`.h`/`.dp` inline in build() pick up the
      // now-settled size.
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    /// LayoutBuilder gives us access to the parent widget's constraints, like max and min width/height.
    return LayoutBuilder(
      builder: (context, constraints) {
        /// Before building the responsive UI, we set the screen size and orientation in our helper class.
        TheResponsiveHelper.setScreenSize(
          context: context,
          constraints: constraints,
          mobileBreakpoint: widget.mobileBreakPoint,
          desktopBreakpoint: widget.desktopBreakPoint,
          enableDesktopMode: widget.enableDesktopMode,
          enableTextScaleFactor: widget.enableTextScaleFactor,
          baseWidth: widget.baselineWidth,
          baseHeight: widget.baselineHeight,
        );

        /// Now, using the provided builder function, we return the appropriate widget based on the current screen properties.
        /// This builder function will likely contain the responsive logic, deciding how the UI should look based on the screen type.
        return widget.builder(
          context,
          TheResponsiveHelper.orientation,
          TheResponsiveHelper.screenType,
        );
      },
    );
  }
}