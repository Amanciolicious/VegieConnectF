import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';


// Color palette
class AppColors {
  static const Color background = Color(0xFFF8FAF5); // Soft white/greenish
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color accentOrange = Color(0xFFFFB74D);
  static const Color accentYellow = Color(0xFFFFF176);
  static const Color accentRed = Color(0xFFE57373);
  static const Color card = Colors.white;
  static const Color shadowLight = Color(0xFFE0F2F1);
  static const Color shadowDark = Color(0xFFB0BEC5);
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF757575);
}

// Text styles
class AppTextStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'Montserrat',
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    fontFamily: 'Montserrat',
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    fontFamily: 'Montserrat',
  );
  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryGreen,
    fontFamily: 'Montserrat',
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontFamily: 'Montserrat',
  );
}

// Neumorphic style helpers
class AppNeumorphic {
  static NeumorphicStyle card = NeumorphicStyle(
    depth: 4,
    color: AppColors.card,
    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
    shadowLightColor: AppColors.shadowLight,
    shadowDarkColor: AppColors.shadowDark,
    intensity: 0.7,
    surfaceIntensity: 0.2,
  );

  static NeumorphicStyle button = NeumorphicStyle(
    depth: 6,
    color: AppColors.primaryGreen,
    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
    shadowLightColor: AppColors.shadowLight,
    shadowDarkColor: AppColors.shadowDark,
    intensity: 0.8,
    surfaceIntensity: 0.3,
  );

  static NeumorphicStyle inset = NeumorphicStyle(
    depth: -4,
    color: AppColors.card,
    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
    shadowLightColor: AppColors.shadowLight,
    shadowDarkColor: AppColors.shadowDark,
    intensity: 0.6,
    surfaceIntensity: 0.2,
  );
}

// App ThemeData for Material widgets fallback
final ThemeData appThemeData = ThemeData(
  fontFamily: 'Montserrat',
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primaryGreen,
  colorScheme: ColorScheme.light(
    primary: AppColors.primaryGreen,
    secondary: AppColors.accentGreen,
    background: AppColors.background,
    error: AppColors.accentRed,
  ),
  textTheme: const TextTheme(
    titleLarge: AppTextStyles.headline,
    titleMedium: AppTextStyles.subtitle,
    bodyMedium: AppTextStyles.body,
    labelLarge: AppTextStyles.button,
  ),
  cardColor: AppColors.card,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: AppTextStyles.button,
    ),
  ),
); 