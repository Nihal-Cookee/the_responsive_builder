import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

void main() {
  void resetView(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetViewPadding();
    tester.view.resetPadding();
    tester.view.resetViewInsets();
    tester.view.resetSystemGestureInsets();
  }

  Future<void> pumpResponsiveApp(
    WidgetTester tester, {
    required Size physicalSize,
    double devicePixelRatio = 1.0,
    FakeViewPadding? viewPadding,
    FakeViewPadding? padding,
    FakeViewPadding? viewInsets,
    FakeViewPadding? systemGestureInsets,
    MediaQueryData Function(MediaQueryData data)? mediaQueryOverride,
    required Widget child,
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = devicePixelRatio;

    if (viewPadding != null) {
      tester.view.viewPadding = viewPadding;
    }
    if (padding != null) {
      tester.view.padding = padding;
    }
    if (viewInsets != null) {
      tester.view.viewInsets = viewInsets;
    }
    if (systemGestureInsets != null) {
      tester.view.systemGestureInsets = systemGestureInsets;
    }

    addTearDown(() => resetView(tester));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            if (mediaQueryOverride == null) {
              return child;
            }

            return MediaQuery(
              data: mediaQueryOverride(MediaQuery.of(context)),
              child: child,
            );
          },
        ),
      ),
    );

    await tester.pump();
  }

  testWidgets(
      'responsive sizing uses FlutterView metrics and preserves ambient insets',
      (tester) async {
    late Size responsiveSize;
    late Orientation responsiveOrientation;
    late EdgeInsets mediaQueryPadding;
    late EdgeInsets mediaQueryViewPadding;
    late EdgeInsets mediaQueryViewInsets;
    late EdgeInsets mediaQuerySystemGestureInsets;
    late double scaledText;

    await pumpResponsiveApp(
      tester,
      physicalSize: const Size(1080, 1920),
      devicePixelRatio: 3.0,
      mediaQueryOverride: (data) => data.copyWith(
        size: const Size(999, 777),
        padding: const EdgeInsets.only(top: 11, bottom: 22),
        viewPadding: const EdgeInsets.only(top: 33, bottom: 44),
        viewInsets: const EdgeInsets.only(bottom: 55),
        systemGestureInsets: const EdgeInsets.only(bottom: 66),
        textScaler: TextScaler.noScaling,
      ),
      child: TheResponsiveBuilder(
        baselineWidth: 360,
        baselineHeight: 640,
        metricsSettleDelay: Duration.zero,
        builder: (context, orientation, screenType) {
          responsiveSize =
              Size(TheResponsiveHelper.width, TheResponsiveHelper.height);
          responsiveOrientation = orientation;
          mediaQueryPadding = MediaQuery.of(context).padding;
          mediaQueryViewPadding = MediaQuery.of(context).viewPadding;
          mediaQueryViewInsets = MediaQuery.of(context).viewInsets;
          mediaQuerySystemGestureInsets =
              MediaQuery.of(context).systemGestureInsets;
          scaledText = 16.sp;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(responsiveSize, const Size(360, 640));
    expect(responsiveOrientation, Orientation.portrait);
    expect(mediaQueryPadding, const EdgeInsets.only(top: 11, bottom: 22));
    expect(
      mediaQueryViewPadding,
      const EdgeInsets.only(top: 33, bottom: 44),
    );
    expect(mediaQueryViewInsets, const EdgeInsets.only(bottom: 55));
    expect(
      mediaQuerySystemGestureInsets,
      const EdgeInsets.only(bottom: 66),
    );
    expect(scaledText, 16);
  });

  testWidgets('rotation updates responsive metrics from the live FlutterView',
      (tester) async {
    final List<Orientation> orientations = <Orientation>[];
    final List<Size> sizes = <Size>[];
    final List<double> dps = <double>[];

    await pumpResponsiveApp(
      tester,
      physicalSize: const Size(376, 812),
      child: TheResponsiveBuilder(
        baselineWidth: 376,
        baselineHeight: 812,
        metricsSettleDelay: Duration.zero,
        builder: (context, orientation, screenType) {
          orientations.add(orientation);
          sizes.add(Size(TheResponsiveHelper.width, TheResponsiveHelper.height));
          dps.add(16.dp);
          return const SizedBox.shrink();
        },
      ),
    );

    tester.view.physicalSize = const Size(812, 376);
    tester.binding.handleMetricsChanged();
    await tester.pump();
    await tester.pump();

    expect(
      orientations,
      <Orientation>[Orientation.portrait, Orientation.landscape],
    );
    expect(sizes, <Size>[const Size(376, 812), const Size(812, 376)]);
    expect(dps[1], dps[0]);
  });

  testWidgets('keyboard insets update through MediaQuery without changing size',
      (tester) async {
    late BuildContext capturedContext;
    final List<Size> responsiveSizes = <Size>[];
    final List<EdgeInsets> viewInsetsHistory = <EdgeInsets>[];

    await pumpResponsiveApp(
      tester,
      physicalSize: const Size(1080, 1920),
      devicePixelRatio: 3.0,
      viewInsets: FakeViewPadding.zero,
      child: TheResponsiveBuilder(
        metricsSettleDelay: Duration.zero,
        builder: (context, orientation, screenType) {
          capturedContext = context;
          responsiveSizes.add(Size(TheResponsiveHelper.width, TheResponsiveHelper.height));
          viewInsetsHistory.add(MediaQuery.of(context).viewInsets);
          return Builder(
            builder: (context) {
              viewInsetsHistory.add(MediaQuery.of(context).viewInsets);
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );

    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    tester.binding.handleMetricsChanged();
    await tester.pump();
    await tester.pump();

    responsiveSizes.add(Size(TheResponsiveHelper.width, TheResponsiveHelper.height));
    viewInsetsHistory.add(MediaQuery.of(capturedContext).viewInsets);

    expect(responsiveSizes, isNotEmpty);
    expect(
      responsiveSizes.every((size) => size == const Size(360, 640)),
      isTrue,
    );
    expect(viewInsetsHistory.first, EdgeInsets.zero);
    expect(viewInsetsHistory.last, const EdgeInsets.only(bottom: 300));
  });

  testWidgets('edge-to-edge padding and gesture insets are preserved',
      (tester) async {
    late EdgeInsets padding;
    late EdgeInsets viewPadding;
    late EdgeInsets systemGestureInsets;

    await pumpResponsiveApp(
      tester,
      physicalSize: const Size(1080, 2400),
      devicePixelRatio: 3.0,
      padding: const FakeViewPadding(top: 144),
      viewPadding: const FakeViewPadding(top: 144, bottom: 96),
      systemGestureInsets: const FakeViewPadding(bottom: 48),
      child: TheResponsiveBuilder(
        metricsSettleDelay: Duration.zero,
        builder: (context, orientation, screenType) {
          final MediaQueryData data = MediaQuery.of(context);
          padding = data.padding;
          viewPadding = data.viewPadding;
          systemGestureInsets = data.systemGestureInsets;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(padding, const EdgeInsets.only(top: 48));
    expect(viewPadding, const EdgeInsets.only(top: 48, bottom: 32));
    expect(systemGestureInsets, const EdgeInsets.only(bottom: 16));
  });

  testWidgets('screen type stays mobile when a phone rotates', (tester) async {
    ScreenType? portraitScreenType;
    ScreenType? landscapeScreenType;

    await pumpResponsiveApp(
      tester,
      physicalSize: const Size(400, 800),
      child: TheResponsiveBuilder(
        builder: (context, orientation, screenType) {
          portraitScreenType = screenType;
          return const SizedBox.shrink();
        },
      ),
    );

    await pumpResponsiveApp(
      tester,
      physicalSize: const Size(800, 400),
      child: TheResponsiveBuilder(
        builder: (context, orientation, screenType) {
          landscapeScreenType = screenType;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(portraitScreenType, ScreenType.mobile);
    expect(landscapeScreenType, ScreenType.mobile);
  });

  testWidgets('desktop mode is opt-in to preserve legacy tablet behavior',
      (tester) async {
    ScreenType? legacyScreenType;
    ScreenSizeTier? legacyTier;

    await pumpResponsiveApp(
      tester,
      physicalSize: const Size(1400, 900),
      child: TheResponsiveBuilder(
        builder: (context, orientation, screenType) {
          legacyScreenType = screenType;
          legacyTier = context.screenSizeTier;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(legacyScreenType, ScreenType.tablet);
    expect(legacyTier, ScreenSizeTier.tablet);
  });

  testWidgets('desktop mode exposes a desktop tier when enabled',
      (tester) async {
    ScreenType? screenType;
    ScreenSizeTier? tier;

    await pumpResponsiveApp(
      tester,
      physicalSize: const Size(1400, 1200),
      child: TheResponsiveBuilder(
        enableDesktopMode: true,
        builder: (context, orientation, resolvedScreenType) {
          screenType = resolvedScreenType;
          tier = context.screenSizeTier;
          return Text('${context.screenSizeTier}');
        },
      ),
    );

    expect(screenType, ScreenType.tablet);
    expect(tier, ScreenSizeTier.desktop);
    expect(find.text('${ScreenSizeTier.desktop}'), findsOneWidget);
  });
}
