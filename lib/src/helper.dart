import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

/// Enumeration to define the two types of screen sizes we want to cater to.
enum ScreenType { mobile, tablet }

/// Enumeration to define screen sizes when desktop layouts are needed.
enum ScreenSizeTier { mobile, tablet, desktop }

class TheResponsiveHelper {
  static final FlutterView _view =
      WidgetsBinding.instance.platformDispatcher.views.first;
  static final Size _fallbackLogicalSize = Size(
    _view.physicalSize.width / _view.devicePixelRatio,
    _view.physicalSize.height / _view.devicePixelRatio,
  );

  /// These properties define the size and characteristics of the current screen.
  static BoxConstraints boxConstraints = const BoxConstraints();
  static Orientation orientation =
      _fallbackLogicalSize.width >= _fallbackLogicalSize.height
          ? Orientation.landscape
          : Orientation.portrait;
  static ScreenType screenType =
      _fallbackLogicalSize.shortestSide < 600
          ? ScreenType.mobile
          : ScreenType.tablet;
  static ScreenSizeTier screenSizeTier =
      _fallbackLogicalSize.shortestSide < 600
          ? ScreenSizeTier.mobile
          : ScreenSizeTier.tablet;
  static double height = _fallbackLogicalSize.height;
  static double width = _fallbackLogicalSize.width;

  /// Reference baseline values for width and height.
  static double baselineWidth = 375.0;
  static double baselineHeight = 667.0;

  static bool enableScaleFactor = true;

  /// Get scaling factors for width and height compared to the baseline.
  static double get horizontalScaling => width / baselineWidth;
  static double get verticalScaling => height / baselineHeight;

  static bool get enableTextScaleFactor => enableScaleFactor;

  /// Get the aspect ratio of the current screen.
  static double get aspectRatio => width / height;

  /// Get the device's pixel density.
  static double get devicePixelRatio =>
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  /// Calculate screen density using devicePixelRatio and aspectRatio.
  static double get screenDensity => devicePixelRatio * aspectRatio;

  /// Get the text scale factor, considering user preferences.
  static double get textScaleFactor =>
      WidgetsBinding.instance.platformDispatcher.textScaleFactor;

  /// Determine the type of screen (mobile or tablet) based on width, height, and orientation.
  static void setScreenSize({
    required BuildContext context,
    required BoxConstraints constraints,
    required double mobileBreakpoint,
    required double desktopBreakpoint,
    required bool enableDesktopMode,
    required bool enableTextScaleFactor,
    required double baseWidth,
    required double baseHeight,
  }) {
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    final Size screenSize = mediaQuery?.size ?? _fallbackLogicalSize;
    final Orientation resolvedOrientation =
        mediaQuery?.orientation ??
        (screenSize.width >= screenSize.height
            ? Orientation.landscape
            : Orientation.portrait);

    boxConstraints = constraints;
    orientation = resolvedOrientation;
    enableScaleFactor = enableTextScaleFactor;
    baselineWidth = baseWidth;
    baselineHeight = baseHeight;
    width = screenSize.width;
    height = screenSize.height;
    final double shortestSide = screenSize.shortestSide;

    if (shortestSide < mobileBreakpoint) {
      screenSizeTier = ScreenSizeTier.mobile;
      screenType = ScreenType.mobile;
    } else if (enableDesktopMode && shortestSide >= desktopBreakpoint) {
      screenSizeTier = ScreenSizeTier.desktop;
      // Preserve the legacy API contract for older applications.
      screenType = ScreenType.tablet;
    } else {
      screenSizeTier = ScreenSizeTier.tablet;
      screenType = ScreenType.tablet;
    }

    assert(() {
      debugPrint("=============================================");
      debugPrint("         The Responsive Builder              ");
      debugPrint("=============================================");
      debugPrint("Scale Factor : $textScaleFactor");
      debugPrint("Device Pixel Ratio : $devicePixelRatio");
      debugPrint("Horizontal scaling : $horizontalScaling");
      debugPrint("Vertical scaling : $verticalScaling");
      debugPrint("Screen Density : $screenDensity");
      debugPrint("Screen Aspect Ratio : $aspectRatio");
      debugPrint("Baseline Width : $baselineWidth");
      debugPrint("Baseline Height : $baselineHeight");
      debugPrint("Screen Width : $width");
      debugPrint("Screen Height : $height");
      debugPrint("Screen Type : $screenType");
      debugPrint("Screen Size Tier : $screenSizeTier");
      debugPrint("=============================================");
      return true;
    }());
  }

  /// Calculate the text size scaled based on the horizontal scaling factor and user's text preferences.
  // static double scaledTextSize(double size) {
  //   return size *
  //       min(horizontalScaling, verticalScaling) *
  //       (enableScaleFactor ? textScaleFactor : 1);
  // }
  static double scaledTextSize(double size) {
    final double scaleFactor = min(horizontalScaling, verticalScaling).clamp(
      0.0,
      1.0,
    );

    return size * scaleFactor * (enableScaleFactor ? textScaleFactor : 1);
  }

  /// Lock the orientation to portrait mode.
  static void lockToPortrait(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  /// Lock the orientation to landscape mode.
  static void lockToLandscape(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  /// Unlock the orientation to allow both portrait and landscape modes.
  static void unlockOrientation(BuildContext context) {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }
}

/// Utility class to fetch adaptive measurements using the ResponsiveHelper.
class Adaptive {
  static double h(num height) => height.h;

  /// Fetch the adaptive height.
  static double w(num width) => width.w;

  /// Fetch the adaptive width.
  static double sp(num scalablePixel) => scalablePixel.sp;

  /// Fetch the adaptive scalable pixel for text.
  static double dp(num scalablePixel) => scalablePixel.dp;

  /// Fetch the adaptive density pixel.
}
