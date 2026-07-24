import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ai_expense_tracker/presentation/home/dashboard_view.dart';
import 'package:ai_expense_tracker/presentation/history/audit_log_view.dart';
import 'package:ai_expense_tracker/presentation/settings/settings_view.dart';
import 'package:ai_expense_tracker/data/database.dart';
import 'package:ai_expense_tracker/data/repositories/account_repository_impl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<DashboardViewState> _dashboardKey = GlobalKey<DashboardViewState>();

  late final List<Widget> _views = [
    DashboardView(key: _dashboardKey),
    const AuditLogView(),
    const SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    final db = AppDatabase.instance;
    final accountRepo = AccountRepositoryImpl(db);
    accountRepo.ensureDefaultAccount();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _views),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        // Deliberately NOT a themed surface color: this bar floats
                        // over cards that already use the app's surface tones, so
                        // matching them makes it visually disappear into the page
                        // when content scrolls behind it. A fixed near-black tone
                        // guarantees contrast against any dynamic color palette.
                        color: Colors.black.withAlpha(210),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: colorScheme.primary.withAlpha(60),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(120),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNavItem(
                            0,
                            Icons.home_filled,
                            "Home",
                            colorScheme,
                          ),
                          _buildNavItem(
                            1,
                            Icons.receipt_long,
                            "Audit",
                            colorScheme,
                          ),
                          _buildNavItem(
                            2,
                            Icons.settings,
                            "Settings",
                            colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          ListTile(
                            leading: Icon(
                              Icons.auto_awesome,
                              color: colorScheme.primary,
                            ),
                            title: const Text(
                              'AI Assistant',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Describe a purchase in plain language',
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/chat');
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.edit_note,
                              color: colorScheme.primary,
                            ),
                            title: const Text(
                              'Manual Entry',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Enter transaction details yourself',
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/edit');
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
                backgroundColor: colorScheme.primary,
                child: Icon(Icons.add, color: colorScheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    ColorScheme colorScheme,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0 && _currentIndex != 0) {
          _dashboardKey.currentState?.refresh();
        }
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}
