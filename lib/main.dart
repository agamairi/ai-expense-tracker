import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:ai_expense_tracker/presentation/main_screen.dart';
import 'package:ai_expense_tracker/presentation/home/edit_transaction_view.dart'
    as ai_edit;
import 'package:ai_expense_tracker/presentation/chat/chat_view.dart';
import 'package:ai_expense_tracker/data/database.dart';
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:ai_expense_tracker/presentation/export/export_view.dart';
import 'package:ai_expense_tracker/domain/services/notification_bridge_service.dart';
import 'package:ai_expense_tracker/domain/services/slm_engine_service.dart';
import 'package:ai_expense_tracker/data/repositories/app_rule_repository_impl.dart';
import 'package:ai_expense_tracker/presentation/accounts/manage_accounts_view.dart';
import 'package:ai_expense_tracker/presentation/budgets/manage_budgets_view.dart';
import 'package:ai_expense_tracker/presentation/help/help_view.dart';
import 'package:ai_expense_tracker/presentation/rules/manage_rules_view.dart';
import 'package:ai_expense_tracker/presentation/categories/manage_categories_view.dart';
import 'package:ai_expense_tracker/domain/models/enums.dart';
import 'package:ai_expense_tracker/core/platform_channel_retry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_expense_tracker/domain/services/update_check_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();

  // Initialize notification bridge service at process startup
  final db = AppDatabase.instance;
  final ruleRepo = AppRuleRepositoryImpl(db);
  final slmService = SlmEngineService(ruleRepo);
  final transactionRepo = TransactionRepositoryImpl(db);
  final bridgeService = NotificationBridgeService(slmService, transactionRepo);
  bridgeService.start();

  runApp(const AiExpenseTrackerApp());
}

class AiExpenseTrackerApp extends StatefulWidget {
  const AiExpenseTrackerApp({super.key});

  @override
  State<AiExpenseTrackerApp> createState() => _AiExpenseTrackerAppState();
}

class _AiExpenseTrackerAppState extends State<AiExpenseTrackerApp> {
  static const _platform = MethodChannel(
    'com.agamairi.ai_expense_tracker/actions',
  );

  @override
  void initState() {
    super.initState();
    _platform.setMethodCallHandler((call) async {
      if (call.method == 'onEditDeepLink') {
        final id = call.arguments as int?;
        if (id != null) {
          _handleEditDeepLink(id);
        }
      } else if (call.method == 'onNotificationCaptured') {
        await NotificationBridgeService.handleNativeEvent(call.method, call.arguments);
      } else if (call.method == 'onNotificationAction') {
        try {
          final args = call.arguments as Map;
          final transactionId = args['transactionId'] as int;
          final action = args['action'] as String;
          
          final repo = TransactionRepositoryImpl(AppDatabase.instance);
          final transaction = await repo.getTransactionById(transactionId);
          if (transaction != null) {
            await repo.updateTransaction(transaction.copyWith(
              status: action == "approve" ? TransactionStatus.approved : TransactionStatus.rejected,
            ));
          }
        } catch (e) {
          debugPrint("Failed to handle notification action: $e");
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkColdStartIntent();
      _checkPassiveUpdate();
    });
  }

  Future<void> _checkPassiveUpdate() async {
    try {
      final service = UpdateCheckService();
      final updateInfo = await service.checkForUpdate();
      if (updateInfo != null) {
        final lastNotified = await service.getLastNotifiedVersion();
        if (lastNotified != updateInfo.latestVersion) {
          final context = navigatorKey.currentState?.context;
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('BAInk v${updateInfo.latestVersion} is available'),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () {
                    launchUrl(Uri.parse(updateInfo.releaseUrl), mode: LaunchMode.externalApplication);
                  },
                ),
              ),
            );
            await service.setLastNotifiedVersion(updateInfo.latestVersion);
          }
        }
      }
    } catch (_) {
      // Ignored for best-effort
    }
  }

  Future<void> _checkColdStartIntent() async {
    try {
      final id = await invokeMethodWithRetry<int>(
        _platform,
        'consumeLaunchTransactionId',
      );
      if (id != null) {
        _handleEditDeepLink(id);
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to consume launch transaction ID: $e");
    }
  }

  Future<void> _handleEditDeepLink(int id) async {
    try {
      final repo = TransactionRepositoryImpl(AppDatabase.instance);
      final transaction = await repo.getTransactionById(id);
      if (transaction != null) {
        navigatorKey.currentState?.pushNamed('/edit', arguments: transaction);
      }
    } catch (_) {
      debugPrint("Failed to handle edit deep link");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force Dark Mode with Neon Green Accent (#00FF66)
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00FF66),
      brightness: Brightness.dark,
      surface: const Color(0xFF121212), // Deep dark surface
      surfaceContainerHighest: const Color(
        0xFF1E1E1E,
      ), // Slightly lighter for cards
      primary: const Color(0xFF00FF66), // Neon green
      onPrimary: Colors.black,
    );

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final colorScheme = darkDynamic ?? darkColorScheme;

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'BAInk',
          theme: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          themeMode: ThemeMode.dark, // Enforce dark theme
          initialRoute: '/',
          routes: {
            '/': (context) => const MainScreen(),
            '/edit': (context) => const ai_edit.EditTransactionView(),
            '/chat': (context) => const ChatView(),
            '/export': (context) => const ExportView(),
            '/accounts': (context) => const ManageAccountsView(),
            '/budgets': (context) => const ManageBudgetsView(),
            '/rules': (context) => const ManageRulesView(),
            '/categories': (context) => const ManageCategoriesView(),
            '/help': (context) => const HelpView(),
          },
        );
      },
    );
  }
}
