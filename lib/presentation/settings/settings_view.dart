import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:ai_expense_tracker/domain/services/slm_engine_service.dart';
import 'package:ai_expense_tracker/domain/services/chart_preferences_service.dart';
import 'package:ai_expense_tracker/domain/models/enums.dart';
import 'package:ai_expense_tracker/domain/services/category_colors.dart';
import 'package:ai_expense_tracker/core/platform_channel_retry.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with WidgetsBindingObserver {
  final _chartPrefs = ChartPreferencesService();
  ChartType _chartType = ChartType.area;
  ChartDataMode _dataMode = ChartDataMode.cashflow;
  List<TransactionCategory> _compareCategories = [];

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isModelReady = false;

  static const platform = MethodChannel('com.agamairi.ai_expense_tracker/actions');
  
  bool _isNotificationListenerEnabled = false;
  bool _isPostNotificationsGranted = false;
  bool _isIgnoringBatteryOptimizations = false;
  
  final TextEditingController _regexController = TextEditingController();
  final TextEditingController _testTitleController = TextEditingController(text: 'Test Bank');
  final TextEditingController _testTextController = TextEditingController();

  
  List<Map<String, String>> _installedApps = [];
  bool _isLoadingApps = true;
  bool _appsLoadFailed = false;
  String _appSearchQuery = '';
  final TextEditingController _appSearchController = TextEditingController();
  
  final List<String> _commonKeywords = [
    'debited', 'credited', 'spent', 'withdrawn', 'paid', 
    'transfer', 'purchase', 'charged', 'refund', 'sent', 'received'
  ];
  Set<String> _selectedKeywords = {};
  String _customRegexNote = '';
  final TextEditingController _customKeywordController = TextEditingController();

  Set<String> _whitelist = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appSearchController.addListener(() {
      setState(() {
        _appSearchQuery = _appSearchController.text;
      });
    });
    _loadSettings();
    _checkModelStatus();
    _loadChartPrefs();
  }

  Future<void> _loadChartPrefs() async {
    final ct = await _chartPrefs.getChartType();
    final dm = await _chartPrefs.getDataMode();
    final compareCats = await _chartPrefs.getCompareCategories();
    if (mounted) {
      setState(() {
        _chartType = ct;
        _dataMode = dm;
        _compareCategories = compareCats;
      });
    }
  }

  Future<void> _checkModelStatus() async {
    try {
      final models = await FlutterGemma.listInstalledModels();
      if (mounted) {
        setState(() {
          _isModelReady = models.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint("Failed to check model status: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _regexController.dispose();
    _appSearchController.dispose();
    _customKeywordController.dispose();
    _testTitleController.dispose();
    _testTextController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _loadSettings() async {
    if (mounted) {
      setState(() {
        _isLoadingApps = true;
        _appsLoadFailed = false;
      });
    }
    try {
      final bool isEnabled = await invokeMethodWithRetry(platform, 'isNotificationListenerEnabled');
      final bool isPostGranted = await invokeMethodWithRetry(platform, 'isPostNotificationsGranted');
      final bool isIgnoring = await invokeMethodWithRetry(platform, 'isIgnoringBatteryOptimizations');
      final List<dynamic> whitelistDynamic = await invokeMethodWithRetry(platform, 'getPackageWhitelist');
      final String regex = await invokeMethodWithRetry(platform, 'getNotificationRegex');
      
      final List<dynamic> appsDynamic = await invokeMethodWithRetry(platform, 'getInstalledApps');
      final List<Map<String, String>> apps = appsDynamic.map((e) => Map<String, String>.from(e as Map)).toList();
      
      Set<String> selectedKw = {};
      List<String> extraKw = [];
      String customNote = '';
      if (regex.isNotEmpty) {
        final parts = regex.split('|');
        if (parts.every((p) => RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(p))) {
          selectedKw = parts.toSet();
          for (var p in parts) {
            if (!_commonKeywords.contains(p)) {
              extraKw.add(p);
            }
          }
        } else {
          customNote = regex;
        }
      }

      if (mounted) {
        setState(() {
          _isNotificationListenerEnabled = isEnabled;
          _isPostNotificationsGranted = isPostGranted;
          _isIgnoringBatteryOptimizations = isIgnoring;
          _whitelist = whitelistDynamic.cast<String>().toSet();
          _regexController.text = regex;
          _installedApps = apps;
          
          _selectedKeywords = selectedKw;
          for (var kw in extraKw) {
            if (!_commonKeywords.contains(kw)) _commonKeywords.add(kw);
          }
          _customRegexNote = customNote;
        });
      }
    } catch (e) {
      debugPrint("Failed to load settings: '$e'.");
      if (mounted) {
        setState(() {
          _appsLoadFailed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingApps = false;
        });
      }
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final bool isEnabled = await platform.invokeMethod('isNotificationListenerEnabled');
      final bool isPostGranted = await platform.invokeMethod('isPostNotificationsGranted');
      final bool isIgnoring = await platform.invokeMethod('isIgnoringBatteryOptimizations');
      setState(() {
        _isNotificationListenerEnabled = isEnabled;
        _isPostNotificationsGranted = isPostGranted;
        _isIgnoringBatteryOptimizations = isIgnoring;
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to check permissions: '${e.message}'.");
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      await platform.invokeMethod('requestIgnoreBatteryOptimizations');
    } on PlatformException catch (e) {
      debugPrint("Failed to request battery exemption: '${e.message}'.");
    }
  }

  Future<void> _openNotificationSettings() async {
    try {
      await platform.invokeMethod('openNotificationListenerSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open settings: '${e.message}'.");
    }
  }

  Future<void> _requestPostNotifications() async {
    try {
      await platform.invokeMethod('requestPostNotificationsPermission');
    } on PlatformException catch (e) {
      debugPrint("Failed to request permission: '${e.message}'.");
    }
  }

  Future<void> _togglePackage(String packageName, bool isEnabled) async {
    final newWhitelist = Set<String>.from(_whitelist);
    if (isEnabled) {
      newWhitelist.add(packageName);
    } else {
      newWhitelist.remove(packageName);
    }
    
    try {
      await platform.invokeMethod('setPackageWhitelist', {'whitelist': newWhitelist.toList()});
      setState(() {
        _whitelist = newWhitelist;
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to update whitelist: '${e.message}'.");
    }
  }

  Future<void> _saveRegex(String pattern) async {
    try {
      RegExp(pattern);
      await platform.invokeMethod('setNotificationRegex', {'regex': pattern});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Regex saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Regex pattern')),
        );
      }
    }
  }

  Future<void> _saveKeywords(Set<String> keywords) async {
    final pattern = keywords.join('|');
    setState(() {
      _selectedKeywords = keywords;
    });
    await _saveRegex(pattern);
  }
  
  Future<void> _addCustomKeyword() async {
    final kw = _customKeywordController.text.trim();
    if (kw.isNotEmpty && RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(kw)) {
      if (!_commonKeywords.contains(kw)) {
        setState(() {
          _commonKeywords.add(kw);
        });
      }
      final newSelected = Set<String>.from(_selectedKeywords)..add(kw);
      await _saveKeywords(newSelected);
      _customKeywordController.clear();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
  
  void _showAddKeywordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Custom Keyword"),
        content: TextField(
          controller: _customKeywordController,
          decoration: const InputDecoration(
            hintText: "e.g., invoiced",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: _addCustomKeyword,
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await FlutterGemma.installModel(
        modelType: SlmModelConfig.modelType,
        fileType: SlmModelConfig.fileType,
      )
      .fromNetwork(SlmModelConfig.url)
      .withProgress((progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress / 100;
          });
        }
      })
      .install();

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isModelReady = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FunctionGemma (270M) model downloaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _sendTestNotification(String title, String text) async {
    try {
      await platform.invokeMethod('postTestNotification', {
        'title': title,
        'text': text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent')),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send test notification: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 130.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text("Settings", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListTile(
                  leading: Icon(Icons.help_outline, color: colorScheme.primary),
                  title: const Text("How to Use This App"),
                  subtitle: const Text("A quick guide to getting started", style: TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  onTap: () {
                    Navigator.pushNamed(context, '/help');
                  },
                ),
              ),
              const SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy, color: colorScheme.primary, size: 32),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("AI Engine", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                              Text("FunctionGemma (270M)", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Download the small language model to your device to enable offline, private transaction categorization. Size: ~271MB",
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    if (_isDownloading) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Downloading...", style: TextStyle(fontWeight: FontWeight.w500)),
                          Text("${(_downloadProgress * 100).toInt()}%", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _downloadProgress,
                          minHeight: 8,
                          backgroundColor: colorScheme.primary.withAlpha(51),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                    ] else if (_isModelReady) ...[
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 24),
                          SizedBox(width: 8),
                          Text("Model ready", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startDownload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text("Download AI Model", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text("Notification Interceptor", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: colorScheme.primary, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Listener Access", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                              Text(
                                _isNotificationListenerEnabled ? "Granted" : "Not Granted",
                                style: TextStyle(color: _isNotificationListenerEnabled ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        ),
                        if (!_isNotificationListenerEnabled)
                          ElevatedButton(
                            onPressed: _openNotificationSettings,
                            child: const Text("Settings"),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _requestPostNotifications,
                      child: const Text("Request Notification Permission"),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.notifications, color: colorScheme.primary, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Post Notifications", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                              Text(
                                _isPostNotificationsGranted ? "Granted" : "Not Granted",
                                style: TextStyle(color: _isPostNotificationsGranted ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        ),
                        if (!_isPostNotificationsGranted)
                          ElevatedButton(
                            onPressed: _requestPostNotifications,
                            child: const Text("Request"),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.battery_alert, color: colorScheme.primary, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Background Reliability", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                              Text(
                                _isIgnoringBatteryOptimizations ? "Granted" : "Not Granted",
                                style: TextStyle(color: _isIgnoringBatteryOptimizations ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        ),
                        if (!_isIgnoringBatteryOptimizations)
                          ElevatedButton(
                            onPressed: _requestBatteryOptimizationExemption,
                            child: const Text("Request"),
                          )
                      ],
                    ),
                    const Divider(height: 48),

                    const Text("Match Pattern (Keywords)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (_customRegexNote.isNotEmpty) ...[
                      Text("Custom pattern in use: $_customRegexNote", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._commonKeywords.map((kw) {
                          final isSelected = _selectedKeywords.contains(kw);
                          return FilterChip(
                            label: Text(kw),
                            selected: isSelected,
                            onSelected: (selected) {
                              final newSelected = Set<String>.from(_selectedKeywords);
                              if (selected) {
                                newSelected.add(kw);
                              } else {
                                newSelected.remove(kw);
                              }
                              _saveKeywords(newSelected);
                            },
                          );
                        }),
                        ActionChip(
                          label: const Text("+ Add custom keyword"),
                          onPressed: _showAddKeywordDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text("Monitored Apps (Whitelist)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text("If empty, all apps are monitored.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    if (_isLoadingApps)
                      const Center(child: CircularProgressIndicator())
                    else if (_appsLoadFailed && _installedApps.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const Text("Failed to load installed apps.", style: TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadSettings,
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      TextField(
                        controller: _appSearchController,
                        decoration: const InputDecoration(
                          hintText: "Search apps...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        final filtered = _installedApps.where((app) => app['label']!.toLowerCase().contains(_appSearchQuery.toLowerCase())).toList();
                        filtered.sort((a, b) {
                          final aWhitelisted = _whitelist.contains(a['packageName']);
                          final bWhitelisted = _whitelist.contains(b['packageName']);
                          if (aWhitelisted && !bWhitelisted) return -1;
                          if (!aWhitelisted && bWhitelisted) return 1;
                          return a['label']!.toLowerCase().compareTo(b['label']!.toLowerCase());
                        });
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final app = filtered[index];
                              return SwitchListTile(
                                title: Text(app['label']!),
                                subtitle: Text(app['packageName']!, style: const TextStyle(fontSize: 12)),
                                value: _whitelist.contains(app['packageName']),
                                onChanged: (val) => _togglePackage(app['packageName']!, val),
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text("Data Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListTile(
                  leading: Icon(Icons.download, color: colorScheme.primary),
                  title: const Text("Export Data"),
                  subtitle: const Text("Export transactions to CSV or JSON", style: TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  onTap: () {
                    Navigator.pushNamed(context, '/export');
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListTile(
                  leading: Icon(Icons.account_balance_wallet, color: colorScheme.primary),
                  title: const Text("Manage Accounts"),
                  subtitle: const Text("Add, edit, or remove accounts", style: TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  onTap: () {
                    // Navigate to ManageAccountsView
                    Navigator.pushNamed(context, '/accounts');
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListTile(
                  leading: Icon(Icons.pie_chart, color: colorScheme.primary),
                  title: const Text("Manage Budgets"),
                  subtitle: const Text("Set monthly spending limits per category", style: TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  onTap: () {
                    Navigator.pushNamed(context, '/budgets');
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListTile(
                  leading: Icon(Icons.rule, color: colorScheme.primary),
                  title: const Text("Manage Category Rules"),
                  subtitle: const Text("Auto-categorize transactions by merchant", style: TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  onTap: () {
                    Navigator.pushNamed(context, '/rules');
                  },
                ),
              ),
              const SizedBox(height: 32),
              _buildChartInsightsSection(colorScheme),
              const SizedBox(height: 32),
              if (kDebugMode) ...[
                const Text("Developer Tools", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Test Notifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () => _sendTestNotification(
                              "Chase Bank", 
                              "You spent \$42.50 at Starbucks. Available balance: \$1,203.11"
                            ),
                            child: const Text("Chase (Debit)"),
                          ),
                          ElevatedButton(
                            onPressed: () => _sendTestNotification(
                              "Bank of America", 
                              "A debit card purchase of \$18.99 was made at Trader Joe's"
                            ),
                            child: const Text("BofA (Debit)"),
                          ),
                          ElevatedButton(
                            onPressed: () => _sendTestNotification(
                              "Wells Fargo Alert", 
                              "You paid \$65.00 to Shell Gas Station"
                            ),
                            child: const Text("Wells Fargo (Paid)"),
                          ),
                          ElevatedButton(
                            onPressed: () => _sendTestNotification(
                              "Venmo", 
                              "You received \$25.00 from John Doe"
                            ),
                            child: const Text("Venmo (Credit)"),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text("Custom Test Notification", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _testTitleController,
                        decoration: const InputDecoration(
                          labelText: "Title",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _testTextController,
                        decoration: const InputDecoration(
                          labelText: "Text",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _sendTestNotification(
                            _testTitleController.text,
                            _testTextController.text,
                          ),
                          child: const Text("Send Custom Test Notification"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartInsightsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Chart & Insights", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chart Type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildSettingsChartTypeSelector(colorScheme),
              if (_chartType != ChartType.pie) ...[
                const SizedBox(height: 24),
                const Text("Data Mode", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildDataModeSelector(colorScheme),
                if (_dataMode == ChartDataMode.compareCategories) ...[
                  const SizedBox(height: 24),
                  const Text("Compare Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TransactionCategory.values.map((cat) {
                      final isSelected = _compareCategories.contains(cat);
                      final catColor = categoryColor(cat);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _compareCategories.remove(cat);
                            } else {
                              _compareCategories.add(cat);
                            }
                          });
                          _chartPrefs.setCompareCategories(_compareCategories);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? catColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? catColor : Colors.white.withAlpha(15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            cat.name.replaceFirst(cat.name[0], cat.name[0].toUpperCase()),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[400],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsChartTypeSelector(ColorScheme colorScheme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
      ),
      child: Row(
        children: [
          _buildSettingsChartTypeChip(ChartType.line, "Line", colorScheme),
          _buildSettingsChartTypeChip(ChartType.area, "Area", colorScheme),
          _buildSettingsChartTypeChip(ChartType.bar, "Bar", colorScheme),
          _buildSettingsChartTypeChip(ChartType.pie, "Pie", colorScheme),
        ],
      ),
    );
  }

  Widget _buildSettingsChartTypeChip(ChartType type, String label, ColorScheme colorScheme) {
    final isSelected = _chartType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _chartType = type);
          _chartPrefs.setChartType(type);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataModeSelector(ColorScheme colorScheme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
      ),
      child: Row(
        children: [
          _buildDataModeChip(ChartDataMode.cashflow, "Overall Cashflow", colorScheme),
          _buildDataModeChip(ChartDataMode.compareCategories, "Compare Categories", colorScheme),
        ],
      ),
    );
  }

  Widget _buildDataModeChip(ChartDataMode mode, String label, ColorScheme colorScheme) {
    final isSelected = _dataMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _dataMode = mode);
          _chartPrefs.setDataMode(mode);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
