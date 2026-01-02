// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mindquest/main.dart';
import 'package:mindquest/services/journal_local_service.dart';
import 'package:mindquest/services/journal_api_service.dart';
import 'package:mindquest/services/journal_service.dart';
import 'package:mindquest/services/mood_local_service.dart';
import 'package:mindquest/services/mood_api_service.dart';
import 'package:mindquest/services/mood_service.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Minimal wiring for required services in tests.
    final journalService = JournalService(
      localService: JournalLocalService(),
      apiService: JournalApiService(),
    );

    final moodService = MoodService(
      localService: MoodLocalService(),
      apiService: MoodApiService(),
    );

    await tester.pumpWidget(MindQuestApp(
      journalService: journalService,
      moodService: moodService,
    ));

    // Verify that the app loads
    expect(find.text('MindQuest'), findsOneWidget);
  });
}
