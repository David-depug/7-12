import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/parental_control_model.dart';
import '../main.dart';

class ParentalControlScreen extends StatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> {
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _keywordController = TextEditingController();
  final _appNameController = TextEditingController();
  final _timeLimitController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _newPasswordController.dispose();
    _keywordController.dispose();
    _appNameController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {Color? color}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color ?? const Color(0xFF333333),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _authenticateParent() async {
    if (_passwordController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    final parentalModel = Provider.of<ParentalControlModel>(context, listen: false);
    final success = await parentalModel.verifyParentPassword(_passwordController.text);
    
    setState(() => _isLoading = false);
    
    if (!success) {
      _showSnackbar('Invalid parent password', color: Colors.red);
    } else {
      _passwordController.clear();
    }
  }

  void _setParentPassword() async {
    if (_newPasswordController.text.length < 6) {
      _showSnackbar('Password must be at least 6 characters', color: Colors.red);
      return;
    }
    
    setState(() => _isLoading = true);
    
    final parentalModel = Provider.of<ParentalControlModel>(context, listen: false);
    final success = await parentalModel.setParentPassword(_newPasswordController.text);
    
    setState(() => _isLoading = false);
    
    if (success) {
      _newPasswordController.clear();
      _showSnackbar('Parent password set successfully', color: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        title: Text(
          'Parental Control',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      ),
      body: Consumer<ParentalControlModel>(
        builder: (context, parentalModel, child) {
          if (!parentalModel.isParentalControlEnabled) {
            return _buildSetupScreen();
          }
          
          if (!parentalModel.isParentalControlEnabled) {
            return _buildLoginScreen();
          }
          
          return _buildDashboard(parentalModel);
        },
      ),
    );
  }

  Widget _buildSetupScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFF97316)],
              ),
            ),
            child: const Icon(
              LucideIcons.shield,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Parental Control Setup',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Set up parental controls to protect your family',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 40),
          
          // Password Setup Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'Create Parent Password',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: 'Parent Password',
                        hint: 'Enter a secure password',
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _setParentPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Setup Parental Control',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFF97316)],
              ),
            ),
            child: const Icon(
              LucideIcons.lock,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Parent Access',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter parent password to access controls',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 40),
          
          // Login Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildPasswordField(
                        controller: _passwordController,
                        label: 'Parent Password',
                        hint: 'Enter your parent password',
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _authenticateParent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Access Parental Controls',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(ParentalControlModel parentalModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Control Toggles
          _buildControlCard(
            icon: LucideIcons.shield,
            title: 'Content Filtering',
            subtitle: 'Block adult content and inappropriate websites',
            isEnabled: parentalModel.isContentFilteringEnabled,
            onToggle: () => parentalModel.toggleContentFiltering(),
          ),
          const SizedBox(height: 16),
          
          _buildControlCard(
            icon: LucideIcons.clock,
            title: 'App Time Limits',
            subtitle: 'Set daily time limits for apps',
            isEnabled: parentalModel.isAppLimitingEnabled,
            onToggle: () => parentalModel.toggleAppLimiting(),
          ),
          const SizedBox(height: 16),
          
          _buildControlCard(
            icon: LucideIcons.lock,
            title: 'Anti-Removal Protection',
            subtitle: 'Prevent app uninstallation',
            isEnabled: parentalModel.isAntiRemovalEnabled,
            onToggle: () => parentalModel.toggleAntiRemoval(),
          ),
          const SizedBox(height: 24),
          
          // Blocked Apps Section
          _buildSectionCard(
            title: 'Blocked Apps',
            icon: LucideIcons.xCircle,
            child: Column(
              children: [
                _buildAddItemField(
                  controller: _appNameController,
                  hint: 'Enter app name to block',
                  onAdd: () {
                    if (_appNameController.text.isNotEmpty) {
                      parentalModel.addBlockedApp(_appNameController.text);
                      _appNameController.clear();
                      _showSnackbar('App blocked successfully');
                    }
                  },
                ),
                const SizedBox(height: 12),
                ...parentalModel.blockedApps.map((app) => _buildListItem(
                  title: app,
                  onRemove: () => parentalModel.removeBlockedApp(app),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Blocked Keywords Section
          _buildSectionCard(
            title: 'Blocked Keywords',
            icon: LucideIcons.filter,
            child: Column(
              children: [
                _buildAddItemField(
                  controller: _keywordController,
                  hint: 'Enter keyword to block',
                  onAdd: () {
                    if (_keywordController.text.isNotEmpty) {
                      parentalModel.addBlockedKeyword(_keywordController.text);
                      _keywordController.clear();
                      _showSnackbar('Keyword blocked successfully');
                    }
                  },
                ),
                const SizedBox(height: 12),
                ...parentalModel.blockedKeywords.map((keyword) => _buildListItem(
                  title: keyword,
                  onRemove: () => parentalModel.removeBlockedKeyword(keyword),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // App Time Limits Section
          _buildSectionCard(
            title: 'App Time Limits',
            icon: LucideIcons.clock,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _appNameController,
                        hint: 'App name',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _timeLimitController,
                        hint: 'Minutes',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_appNameController.text.isNotEmpty && 
                            _timeLimitController.text.isNotEmpty) {
                          parentalModel.setAppTimeLimit(
                            _appNameController.text,
                            int.parse(_timeLimitController.text),
                          );
                          _appNameController.clear();
                          _timeLimitController.clear();
                          _showSnackbar('Time limit set successfully');
                        }
                      },
                      child: const Icon(LucideIcons.plus),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...parentalModel.appTimeLimits.entries.map((entry) => _buildListItem(
                  title: '${entry.key}: ${entry.value} minutes',
                  onRemove: () => parentalModel.setAppTimeLimit(entry.key, 0),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white.withOpacity(0.1),
            ),
            child: Icon(icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (_) => onToggle(),
            activeColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !_isPasswordVisible,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            LucideIcons.lock,
            color: Colors.white70,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAddItemField({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: controller,
            hint: hint,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildListItem({
    required String title,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              LucideIcons.x,
              color: Colors.red,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

