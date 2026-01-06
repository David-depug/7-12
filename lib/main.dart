import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';
import 'config.dart';
import 'models/mission_model.dart';
import 'models/user_model.dart';
import 'models/auth_model.dart';
import 'models/parental_control_model.dart';
import 'models/screen_time_model.dart';
import 'models/sleep_model.dart';
import 'models/step_counter_model.dart';
import 'models/journal_model.dart';
import 'screens/challenges_screen.dart';
import 'screens/community_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/parental_control_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/mini_games_screen.dart';
import 'screens/sleep_tracker_screen.dart';
import 'screens/step_tracker_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/mood_tracker_screen.dart';
import 'services/screen_time_service.dart';
import 'services/journal_api_service.dart';
import 'services/journal_local_service.dart';
import 'services/journal_service.dart';
import 'services/mood_api_service.dart';
import 'services/mood_local_service.dart';
import 'services/mood_service.dart';
import 'services/notification_service.dart';
import 'models/mood_model.dart';
import 'package:flutter/services.dart'; // للـ MethodChannel

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first (required for Firestore)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await Hive.initFlutter();

  final journalLocalService = JournalLocalService();
  await journalLocalService.init();
  final journalService = JournalService(
    localService: journalLocalService,
    apiService: JournalApiService(),
  );

  final moodLocalService = MoodLocalService();
  await moodLocalService.init();
  final moodService = MoodService(
    localService: moodLocalService,
    apiService: MoodApiService(),
  );

  // Initialize notifications and schedule reminders.
  await NotificationService.initialize();
  await NotificationService.scheduleDailyJournalReminder();
  await NotificationService.scheduleDailyMoodReminder();
  runApp(MindQuestApp(
    journalService: journalService,
    moodService: moodService,
  ));
}

class MindQuestApp extends StatelessWidget {
  const MindQuestApp({
    super.key,
    required this.journalService,
    required this.moodService,
  });

  final JournalService journalService;
  final MoodService moodService;

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.interTextTheme();
    } catch (e) {
      textTheme = ThemeData.light().textTheme;
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthModel()),
        ChangeNotifierProvider(
          create: (_) => UserModel(
            username: 'MindQuest User',
            xp: 120,
            level: 3,
            streakDays: 3,
            badges: 5,
            rank: 42,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MissionsModel()),
        ChangeNotifierProvider(create: (_) => ParentalControlModel()),
        ChangeNotifierProvider(create: (_) => SleepModel()),
        ChangeNotifierProvider(create: (_) => StepCounterModel()),
        ChangeNotifierProvider(create: (_) {
          final screenTimeModel = ScreenTimeModel();
          ScreenTimeService.initialize(screenTimeModel);
          return screenTimeModel;
        }),
        ChangeNotifierProvider(
          create: (_) => JournalModel(journalService)..loadEntries(),
        ),
        ChangeNotifierProvider(
          create: (_) => MoodModel(moodService)..loadEntries(),
        ),
      ],
      child: MaterialApp(
        title: 'MindQuest',
        theme: buildTheme(Brightness.light).copyWith(textTheme: textTheme),
        darkTheme: buildTheme(Brightness.dark).copyWith(textTheme: textTheme),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthModel>(
      builder: (context, authModel, child) {
        if (authModel.isAuthenticated) {
          return const RootNav();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

final GlobalKey<ScaffoldState> rootNavScaffoldKey = GlobalKey<ScaffoldState>();

class _RootNavState extends State<RootNav> {
  int _index = 0;
  static const platform = MethodChannel('com.appguard.native_calls');

  final _screens = [
    const HomeScreen(),
    const ChallengesScreen(),
    const MiniGamesScreen(),
    const CommunityScreen(),
    const AnalyticsScreen(),
    const SleepTrackerScreen(),
    const StepTrackerScreen(),
    const ParentalControlScreen(),
    const ProfileScreen(),
    const JournalScreen(),
    const MoodTrackerScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: LucideIcons.home, label: 'Home', index: 0),
    _NavItem(icon: LucideIcons.target, label: 'Challenges', index: 1),
    _NavItem(icon: LucideIcons.gamepad2, label: 'Mini Games', index: 2),
    _NavItem(icon: LucideIcons.users, label: 'Community', index: 3),
    _NavItem(icon: LucideIcons.barChart3, label: 'Analytics', index: 4),
    _NavItem(icon: LucideIcons.moon, label: 'Sleep Tracker', index: 5),
    _NavItem(icon: LucideIcons.footprints, label: 'Step Tracker', index: 6),
    _NavItem(icon: LucideIcons.shield, label: 'Parental', index: 7),
    _NavItem(icon: LucideIcons.user, label: 'Profile', index: 8),
    _NavItem(icon: LucideIcons.bookOpen, label: 'Journaling', index: 9),
    _NavItem(icon: LucideIcons.smile, label: 'Mood Tracker', index: 10),
  ];

  void _navigateTo(int index) {
    setState(() => _index = index);
    Navigator.of(context).pop(); // Close drawer
  }

  @override
  void initState() {
    super.initState();
    startGuardService(); // تشغيل الخدمة عند فتح التطبيق
  }

  Future<void> startGuardService() async {
    try {
      await platform.invokeMethod('startGuardService');
      debugPrint("GuardService started successfully");
    } on PlatformException catch (e) {
      debugPrint("Failed to start GuardService: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.purple;

    return Scaffold(
      key: rootNavScaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFF1B1B1B),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purple.withOpacity(0.3),
                      AppColors.purple.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [AppColors.purple, Color(0xFFF97316)],
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.sparkles,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MindQuest',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Navigation Menu',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _navItems.length,
                  itemBuilder: (context, i) {
                    final item = _navItems[i];
                    final isSelected = _index == item.index;
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected ? selectedColor : Colors.white70,
                        size: 24,
                      ),
                      title: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          color: isSelected ? selectedColor : Colors.white,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: selectedColor.withOpacity(0.1),
                      onTap: () => _navigateTo(item.index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[_index],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
