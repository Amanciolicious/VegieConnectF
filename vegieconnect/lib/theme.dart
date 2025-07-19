import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';


// Color palette
class AppColors {
  static const Color background = Color(0xFFF8FAF5); // Soft white/greenish
  static const Color primaryGreen = Color(0xFF6CA04A); // Lettuce green
  static const Color accentGreen = Color(0xFFA7C957); // Avocado green
  static const Color oliveGreen = Color(0xFF8D9773); // Olive
  static const Color earthyBrown = Color(0xFF8D6748); // Earthy brown
  static const Color softYellow = Color(0xFFFFF8E1); // Soft yellow
  static const Color accentYellow = Color(0xFFFFF176); // Highlight yellow
  static const Color accentRed = Color(0xFFE57373);
  static const Color card = Color(0xFFFFFFFF);
  static const Color shadowLight = Color(0xFFE0F2F1);
  static const Color shadowDark = Color(0xFFB0BEC5);
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF757575);
  static const Color badgeRed = Color(0xFFFF3B30);

  static var primaryRed;
}

// Text styles
class AppTextStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'Poppins',
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    fontFamily: 'Poppins',
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    fontFamily: 'Poppins',
  );
  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryGreen,
    fontFamily: 'Poppins',
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontFamily: 'Poppins',
  );
}

// Neumorphic style helpers
class AppNeumorphic {
  static NeumorphicStyle card = NeumorphicStyle(
    depth: 5,
    color: AppColors.card,
    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(24)),
    shadowLightColor: AppColors.shadowLight,
    shadowDarkColor: AppColors.shadowDark,
    intensity: 0.8,
    surfaceIntensity: 0.25,
    border: NeumorphicBorder(
      color: AppColors.oliveGreen.withOpacity(0.08),
      width: 1.2,
    ),
  );

  static NeumorphicStyle button = NeumorphicStyle(
    depth: 7,
    color: AppColors.primaryGreen,
    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
    shadowLightColor: AppColors.shadowLight,
    shadowDarkColor: AppColors.shadowDark,
    intensity: 0.85,
    surfaceIntensity: 0.35,
    border: NeumorphicBorder(
      color: AppColors.oliveGreen.withOpacity(0.10),
      width: 1.5,
    ),
  );

  static NeumorphicStyle inset = NeumorphicStyle(
    depth: -5,
    color: AppColors.card,
    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
    shadowLightColor: AppColors.shadowLight,
    shadowDarkColor: AppColors.shadowDark,
    intensity: 0.7,
    surfaceIntensity: 0.25,
    border: NeumorphicBorder(
      color: AppColors.oliveGreen.withOpacity(0.08),
      width: 1.2,
    ),
  );
}

// App ThemeData for Material widgets fallback
final ThemeData appThemeData = ThemeData(
  fontFamily: 'Poppins',
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primaryGreen,
  colorScheme: ColorScheme.light(
    primary: AppColors.primaryGreen,
    secondary: AppColors.accentGreen,
    background: AppColors.background,
    error: AppColors.accentRed,
    onPrimary: Colors.white, // For text/icons on primary
    onSecondary: AppColors.textPrimary,
    onBackground: AppColors.textPrimary,
    onError: Colors.white,
    surface: AppColors.card,
    onSurface: AppColors.textPrimary,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primaryGreen,
    foregroundColor: Colors.white,
    elevation: 0.5,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: AppTextStyles.headline.copyWith(color: Colors.white),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.primaryGreen,
    unselectedItemColor: AppColors.textSecondary,
    elevation: 8,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
    unselectedLabelStyle: AppTextStyles.body,
  ),
  cardColor: AppColors.card,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      textStyle: AppTextStyles.button,
    ),
  ),
); 