import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

void main() {
  Future<void> pumpResponsiveApp(
    WidgetTester tester, {
    required Size size,
    required Widget child,
  }) async {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = size;
    binding.window.devicePixelRatioTestValue = 1.0;

    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: child,
        ),
      ),
    );
  }

  testWidgets('screen type stays mobile when a phone rotates', (tester) async {
    ScreenType? portraitScreenType;
    ScreenType? landscapeScreenType;

    await pumpResponsiveApp(
      tester,
      size: const Size(400, 800),
      child: TheResponsiveBuilder(
        builder: (context, orientation, screenType) {
          portraitScreenType = screenType;
          return const SizedBox.shrink();
        },
      ),
    );

    await pumpResponsiveApp(
      tester,
      size: const Size(800, 400),
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

  testWidgets('nested builders use the real screen size for classification',
      (tester) async {
    ScreenType? outerScreenType;
    ScreenType? innerScreenType;

    await pumpResponsiveApp(
      tester,
      size: const Size(900, 700),
      child: TheResponsiveBuilder(
        builder: (context, orientation, screenType) {
          outerScreenType = screenType;
          return Center(
            child: SizedBox(
              width: 280,
              child: TheResponsiveBuilder(
                builder: (context, orientation, screenType) {
                  innerScreenType = screenType;
                  return Text('${context.screenType}');
                },
              ),
            ),
          );
        },
      ),
    );

    expect(outerScreenType, ScreenType.tablet);
    expect(innerScreenType, ScreenType.tablet);
    expect(find.text('${ScreenType.tablet}'), findsOneWidget);
  });

  testWidgets('desktop mode is opt-in to preserve legacy tablet behavior',
      (tester) async {
    ScreenType? legacyScreenType;
    ScreenSizeTier? legacyTier;

    await pumpResponsiveApp(
      tester,
      size: const Size(1400, 900),
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

  testWidgets('desktop mode exposes a desktop tier when enabled', (tester) async {
    ScreenType? screenType;
    ScreenSizeTier? tier;

    await pumpResponsiveApp(
      tester,
      size: const Size(1400, 900),
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
