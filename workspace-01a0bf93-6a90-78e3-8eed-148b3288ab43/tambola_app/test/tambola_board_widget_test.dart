import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tambola_board/models/cell_visual_state.dart';
import 'package:tambola_board/state/tambola_controller.dart';
import 'package:tambola_board/theme/app_theme.dart';
import 'package:tambola_board/widgets/control_panel.dart';
import 'package:tambola_board/widgets/number_grid.dart';
import 'package:tambola_board/widgets/number_tile.dart';

/// Small harness that renders the two main sections in landscape, exactly the
/// way `TambolaScreen` arranges them.
Widget _landscapeHarness(TambolaController controller) {
  return MaterialApp(
    theme: buildTambolaTheme(),
    home: Scaffold(
      body: Row(
        children: <Widget>[
          Expanded(
            child: NumberGrid(
              controller: controller,
              onTileTap: controller.toggleQueuedNumber,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 260,
            child: ControlPanel(
              controller: controller,
              onToggleMute: (_) {},
              onShare: () {},
              onReset: () {},
              onGenerate: controller.callNextNumber,
              onShowHistory: () {},
              onRepeatCurrent: () {},
            ),
          ),
        ],
      ),
    ),
  );
}

/// Physical size of a typical landscape phone in the tests below.
const Size _phoneLandscape = Size(1600, 720);

void _useLandscapePhone(WidgetTester tester, [Size size = _phoneLandscape]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  group('Board widgets', () {
    late TambolaController controller;

    setUp(() => controller = TambolaController());
    tearDown(() => controller.dispose());

    testWidgets('renders all 90 tiles on a landscape phone', (
      WidgetTester tester,
    ) async {
      _useLandscapePhone(tester);

      await tester.pumpWidget(_landscapeHarness(controller));
      await tester.pumpAndSettle();

      expect(find.byType(NumberTile), findsNWidgets(90));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('90'), findsOneWidget);
      expect(find.text('Generate'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on a small landscape phone', (
      WidgetTester tester,
    ) async {
      _useLandscapePhone(tester, const Size(1280, 600));

      await tester.pumpWidget(_landscapeHarness(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('generating a number paints the tile red and shows it big', (
      WidgetTester tester,
    ) async {
      _useLandscapePhone(tester);

      await tester.pumpWidget(_landscapeHarness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      final int called = controller.currentNumber!;
      expect(controller.stateOf(called), CellVisualState.latest);
      // The number appears twice: on its tile and inside the round display.
      expect(find.text('$called'), findsNWidgets(2));
    });
  });

  group('Queue is invisible (discreet mode, the default)', () {
    late TambolaController controller;

    setUp(() => controller = TambolaController());
    tearDown(() => controller.dispose());

    testWidgets('tapping a tile gives no visual queue marker at all', (
      WidgetTester tester,
    ) async {
      _useLandscapePhone(tester);

      await tester.pumpWidget(_landscapeHarness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('54'));
      await tester.pumpAndSettle();

      // The queue recorded it...
      expect(controller.queueDelayOf(54), 2);
      // ...but nothing on screen changed: no badge, no snack bar, plain green.
      expect(find.text('IN 2'), findsNothing);
      expect(find.textContaining('queued'), findsNothing);
      expect(controller.stateOf(54), CellVisualState.uncalled);

      final NumberTile tile = tester.widget<NumberTile>(
        find.widgetWithText(NumberTile, '54'),
      );
      expect(tile.state, CellVisualState.uncalled);
      expect(tile.queueDelay, 2); // data is available, just not painted
    });

    testWidgets('tapping twice silently cancels the queued number', (
      WidgetTester tester,
    ) async {
      _useLandscapePhone(tester);

      await tester.pumpWidget(_landscapeHarness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('54'));
      await tester.pump();
      await tester.tap(find.text('54'));
      await tester.pumpAndSettle();

      expect(controller.queueLength, 0);
      expect(find.text('IN 2'), findsNothing);
    });

    testWidgets('the pre-selected number is still called after 2 others', (
      WidgetTester tester,
    ) async {
      _useLandscapePhone(tester);

      await tester.pumpWidget(_landscapeHarness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('54'));
      await tester.pump();
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();
      expect(controller.currentNumber, isNot(54));
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();
      expect(controller.currentNumber, isNot(54));
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      expect(controller.currentNumber, 54);
      expect(controller.stateOf(54), CellVisualState.latest);
    });
  });

  group('Queue markers (showQueueHints: true)', () {
    late TambolaController controller;

    setUp(() => controller = TambolaController(showQueueHints: true));
    tearDown(() => controller.dispose());

    testWidgets('tapping a tile queues it, tapping again cancels it', (
      WidgetTester tester,
    ) async {
      _useLandscapePhone(tester);

      await tester.pumpWidget(_landscapeHarness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('54'));
      await tester.pump();
      expect(controller.stateOf(54), CellVisualState.queued);
      expect(find.text('IN 2'), findsOneWidget);

      await tester.tap(find.text('54'));
      await tester.pump();
      expect(controller.stateOf(54), CellVisualState.uncalled);
      expect(find.text('IN 2'), findsNothing);
    });
  });
}
