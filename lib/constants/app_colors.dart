import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand per spec
  static const Color purple = Color(0xFF7C3AED); // Purple primary
  static const Color blue = Color(0xFF3B82F6);   // Blue accent
  static const Color teal = Color(0xFF14B8A6);   // Teal
  static const Color orange = Color(0xFFF97316); // Orange
  static const Color pink = Color(0xFFEC4899);   // Pink
  static const Color green = Color(0xFF45D9A8);  // Green
  static const Color red = Color(0xFFFF6B6B);    // Red

  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceDark = Color(0xFF111318);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);

  // ============================================
  // Mental Health Light Theme Colors
  // ============================================
  static const Color morningMist = Color(0xFFF4F7F5);      // Scaffold background
  static const Color pureWhite = Color(0xFFFFFFFF);        // Card/surface color
  static const Color sereneTeal = Color(0xFF4A90E2);       // Primary brand
  static const Color warmSunset = Color(0xFFFFB347);       // Accent/progress
  static const Color deepCharcoal = Color(0xFF2D3436);     // Text color
  static const Color mutedCoral = Color(0xFFE57373);       // Emergency buttons
  static const Color inputFill = Color(0xFFEDF2F4);        // Form field fill
  static const Color lightBorder = Color(0xFFE0E0E0);      // Input borders

  // Focus Blocker Colors
  static const Color primary = Color(0xFF6B46C1);
  static const Color secondary = Color(0xFF45D9A8);
  static const Color background = Color(0xFF0F0F23);
  static const Color card = Color(0xFF16213E);
  static const Color textMuted = Color(0xFF808080);
  static const Color success = Color(0xFF45D9A8);
  static const Color warning = Color(0xFFFFB347);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF4ECDC4);

  // Focus Blocker Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF6B46C1),
    Color(0xFF8B5CF6),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF45D9A8),
    Color(0xFF4ECDC4),
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFF0F0F23),
    Color(0xFF1A1A2E),
  ];

  // Gradient combinations for backgrounds
  static const List<Color> purpleToTeal = [purple, teal];

  static const List<Color> orangeToPink = [orange, pink];

  static LinearGradient backgroundPurpleTeal({Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) =>
      LinearGradient(begin: begin, end: end, colors: purpleToTeal);

  static LinearGradient backgroundOrangePink({Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) =>
      LinearGradient(begin: begin, end: end, colors: orangeToPink);
}

/// Main theme builder - dispatches to light or dark theme
ThemeData buildTheme(Brightness brightness) {
  return brightness == Brightness.light 
      ? _buildLightTheme() 
      : _buildDarkTheme();
}

/// Professional Mental Health App Design System (Light Theme)
ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // ============================================
    // COLOR SCHEME - Uplifting & Calming
    // ============================================
    colorScheme: ColorScheme.light(
      primary: AppColors.sereneTeal,           // Serene Teal for primary actions
      secondary: AppColors.warmSunset,         // Warm accent
      surface: AppColors.pureWhite,            // Card backgrounds
      background: AppColors.morningMist,       // Scaffold background
      error: AppColors.mutedCoral,             // Gentle error color
      onPrimary: Colors.white,                 // Text on primary buttons
      onSecondary: Colors.white,               // Text on accent
      onSurface: AppColors.deepCharcoal,       // Text on surfaces
      onBackground: AppColors.deepCharcoal,    // Text on scaffold
      onError: Colors.white,                   // Text on error surfaces
    ),
    
    scaffoldBackgroundColor: AppColors.morningMist,
    
    // ============================================
    // TYPOGRAPHY - High Contrast & Readable
    // ============================================
    textTheme: TextTheme(
      // Headings
      displayLarge: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.0,
      ),
      displayMedium: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.0,
      ),
      displaySmall: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.0,
      ),
      
      // Headlines
      headlineLarge: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
      ),
      headlineMedium: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
      ),
      headlineSmall: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
      ),
      
      // Titles
      titleLarge: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
      ),
      titleMedium: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      titleSmall: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      
      // Body text - INCREASED letter spacing for readability
      bodyLarge: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        letterSpacing: 0.2,  // Enhanced for anxious users
      ),
      bodyMedium: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        letterSpacing: 0.2,  // Enhanced for anxious users
      ),
      bodySmall: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        letterSpacing: 0.2,  // Enhanced for anxious users
      ),
      
      // Labels
      labelLarge: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        letterSpacing: 0.1,
      ),
      labelMedium: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        letterSpacing: 0.1,
      ),
      labelSmall: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        letterSpacing: 0.1,
      ),
    ),
    
    // ============================================
    // CARDS - Soft Glow Shadow
    // ============================================
    cardTheme: CardThemeData(
      color: AppColors.pureWhite,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),  // Soft glow
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),  // 12px as specified
      ),
      clipBehavior: Clip.antiAlias,
    ),
    
    // Shadow for elevated cards
    shadowColor: Colors.black.withOpacity(0.05),
    
    // ============================================
    // BUTTONS - Primary, Outlined, Text
    // ============================================
    
    // Elevated Button (Primary Actions)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.sereneTeal,      // Serene Teal background
        foregroundColor: Colors.white,              // White text/icons
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),  // 16px radius
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    // Outlined Button (Secondary Actions)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.sereneTeal,      // Serene Teal text
        backgroundColor: Colors.transparent,         // Transparent background
        side: const BorderSide(
          color: AppColors.sereneTeal,
          width: 1.5,                                // 1.5px border
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    // Text Button (For Emergency/Support - Muted Coral)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.mutedCoral,      // Muted Coral text by default
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    // ============================================
    // FORM INPUTS - Filled with Focus States
    // ============================================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,              // #EDF2F4
      
      // Label styling
      labelStyle: const TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontSize: 16,
      ),
      floatingLabelStyle: const TextStyle(
        inherit: true,
        color: AppColors.sereneTeal,               // Teal when focused
        fontSize: 14,
      ),
      
      // Hint text
      hintStyle: TextStyle(
        color: AppColors.deepCharcoal.withOpacity(0.5),
        fontSize: 15,
      ),
      
      // Content padding
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      
      // Border - Enabled state (thin light grey)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.lightBorder,             // Light grey
          width: 1.0,
        ),
      ),
      
      // Border - Focused state (Serene Teal, 2px)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.sereneTeal,              // Serene Teal
          width: 2.0,                                // 2px as specified
        ),
      ),
      
      // Border - Error state
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.mutedCoral,
          width: 1.0,
        ),
      ),
      
      // Border - Focused error state
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.mutedCoral,
          width: 2.0,
        ),
      ),
      
      // Error text styling
      errorStyle: const TextStyle(
        color: AppColors.mutedCoral,
        fontSize: 12,
      ),
    ),
    
    // ============================================
    // ICONS - Deep Charcoal by Default
    // ============================================
    iconTheme: IconThemeData(
      color: AppColors.deepCharcoal,               // Default icon color
      size: 24,
    ),
    
    // ============================================
    // APP BAR
    // ============================================
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: AppColors.morningMist,      // Match scaffold
      foregroundColor: AppColors.deepCharcoal,     // Text and icons
      iconTheme: IconThemeData(
        color: AppColors.deepCharcoal,
      ),
      titleTextStyle: TextStyle(
        inherit: true,
        color: AppColors.deepCharcoal,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
      ),
    ),
    
    // ============================================
    // BOTTOM NAVIGATION
    // ============================================
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.pureWhite,
      selectedItemColor: AppColors.sereneTeal,     // Selected: Serene Teal
      unselectedItemColor: AppColors.deepCharcoal.withOpacity(0.6),
      showUnselectedLabels: true,
      elevation: 8,
      selectedLabelStyle: const TextStyle(
        inherit: true,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: const TextStyle(
        inherit: true,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
      ),
    ),
    
    // ============================================
    // FLOATING ACTION BUTTON
    // ============================================
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.sereneTeal,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // ============================================
    // DIVIDER
    // ============================================
    dividerTheme: DividerThemeData(
      color: AppColors.deepCharcoal.withOpacity(0.1),
      thickness: 1,
      space: 1,
    ),
    
    // ============================================
    // PROGRESS INDICATORS
    // ============================================
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.warmSunset,                 // Warm Sunset for progress
      linearTrackColor: AppColors.inputFill,
      circularTrackColor: AppColors.inputFill,
    ),
    
    // ============================================
    // SNACKBAR
    // ============================================
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.deepCharcoal,
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}

/// Preserve existing dark theme exactly as is
ThemeData _buildDarkTheme() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surfaceDark,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
  );
}


