import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../main.dart';

class AppInfo {
  final String appName;
  final String packageName;
  bool isBlocked;

  AppInfo({
    required this.appName,
    required this.packageName,
    required this.isBlocked,
  });

  Map<String, dynamic> toJson() => {
    'appName': appName,
    'packageName': packageName,
    'isBlocked': isBlocked,
  };

  factory AppInfo.fromJson(Map<String, dynamic> json) => AppInfo(
    appName: json['appName'],
    packageName: json['packageName'],
    isBlocked: false, // Will be set later
  );
}

class BlockAppsScreen extends StatefulWidget {
  const BlockAppsScreen({super.key});

  @override
  State<BlockAppsScreen> createState() => _BlockAppsScreenState();
}

class _BlockAppsScreenState extends State<BlockAppsScreen> {
  static const platform = MethodChannel('com.appguard.native_calls');
  List<AppInfo> _installedApps = [];
  List<AppInfo> _filteredApps = [];
  List<String> _blockedApps = [];
  bool _isLoading = true;
  bool _hasUsagePermission = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _checkPermissions();
    await _loadInstalledApps();
    await _loadBlockedApps();
    setState(() => _isLoading = false);
  }

  Future<void> _checkPermissions() async {
    try {
      final result = await platform.invokeMethod('checkAccessibilityPermission');
      setState(() => _hasUsagePermission = result ?? false);
    } catch (e) {
      debugPrint('Error checking accessibility permission: $e');
      setState(() => _hasUsagePermission = false);
    }
  }

  Future<void> _requestUsagePermission() async {
    try {
      await platform.invokeMethod('requestAccessibilityPermission');
      // Re-check after request
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermissions();
    } catch (e) {
      debugPrint('Error requesting accessibility permission: $e');
    }
  }

  Future<void> _loadInstalledApps() async {
    try {
      final result = await platform.invokeMethod('getInstalledApps');
      if (result != null && result is List) {
        final apps = result.map((app) => AppInfo.fromJson(Map<String, dynamic>.from(app))).toList();
        setState(() => _installedApps = apps);
        _filterApps();
      }
    } catch (e) {
      debugPrint('Error loading installed apps: $e');
    }
  }

  void _filterApps() {
    if (_searchQuery.isEmpty) {
      _filteredApps = List.from(_installedApps);
    } else {
      _filteredApps = _installedApps.where((app) {
        return app.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  Future<void> _loadBlockedApps() async {
    try {
      final result = await platform.invokeMethod('getBlockedApps');
      if (result != null && result is List) {
        setState(() => _blockedApps = List<String>.from(result));
        // Update app statuses
        for (var app in _installedApps) {
          app.isBlocked = _blockedApps.contains(app.packageName);
        }
        _filterApps();
      }
    } catch (e) {
      debugPrint('Error loading blocked apps: $e');
    }
  }

  Future<void> _toggleAppBlock(String packageName, bool isBlocked) async {
    try {
      await platform.invokeMethod('setAppBlockStatus', {
        'packageName': packageName,
        'isBlocked': isBlocked,
      });

      setState(() {
        if (isBlocked) {
          _blockedApps.add(packageName);
        } else {
          _blockedApps.remove(packageName);
        }
        final app = _installedApps.firstWhere((app) => app.packageName == packageName);
        app.isBlocked = isBlocked;
      });

      // Save to local storage for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('blocked_apps', _blockedApps);

      _filterApps(); // Refresh filtered list
    } catch (e) {
      debugPrint('Error toggling app block: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update app block status')),
      );
    }
  }

  Future<void> _startBlockingService() async {
    // Accessibility service is enabled/disabled in settings
    // This method is kept for compatibility but not used
  }

  Future<void> _stopBlockingService() async {
    // Accessibility service is enabled/disabled in settings
    // This method is kept for compatibility but not used
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.menu,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            rootNavScaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Menu',
        ),
        title: Text(
          'Block Apps',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: Colors.white),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasUsagePermission
              ? _buildPermissionRequired()
              : _buildAppList(),
    );
  }

  Widget _buildPermissionRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.shield,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              'Accessibility Permission Required',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To block apps, we need accessibility permission to monitor app switches. Please grant the permission in settings.',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _requestUsagePermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Grant Permission',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white.withOpacity(0.05),
          child: Row(
            children: [
              Text(
                '${_blockedApps.length} apps blocked',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white70),
                onPressed: _loadInstalledApps,
                tooltip: 'Refresh apps',
              ),
              if (_hasUsagePermission)
                const Icon(LucideIcons.shieldCheck, color: Colors.green, size: 20)
              else
                IconButton(
                  icon: const Icon(LucideIcons.shield, color: Colors.orange),
                  onPressed: _requestUsagePermission,
                  tooltip: 'Grant accessibility permission',
                ),
            ],
          ),
        ),
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _filterApps();
            },
            decoration: InputDecoration(
              hintText: 'Search apps...',
              hintStyle: GoogleFonts.inter(color: Colors.white70),
              prefixIcon: const Icon(LucideIcons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredApps.length,
            itemBuilder: (context, index) {
              final app = _filteredApps[index];
              return _buildAppTile(app);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppTile(AppInfo app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: app.isBlocked ? Colors.red.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            LucideIcons.grid,
            color: Colors.white70,
          ),
        ),
        title: Text(
          app.appName,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          app.packageName,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: app.isBlocked,
          onChanged: (value) => _toggleAppBlock(app.packageName, value),
          activeColor: Colors.red,
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Check Permissions',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              trailing: const Icon(LucideIcons.shield, color: Colors.white),
              onTap: () {
                Navigator.pop(context);
                _checkPermissions();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }
}