import 'dart:ui';
import 'package:flutter/material.dart';

class AppThemes {
  static List<AppThemeData> allThemes = [
    
    // 1. أمواج دردشاتي (الأصلي)
    AppThemeData(
      name: 'dardashati_wave',
      label: 'أمواج دردشاتي',
      background: const Color(0xFFF6F3FF),
      text: const Color(0xFF2A2750),      
      button: const Color(0xFF7C6BE0),    
      card: const Color(0xFFFFFFFF).withOpacity(0.5), 
      menu: const Color(0xFFFFFFFF).withOpacity(0.85),
      buttonText: Colors.white,
      isDark: false,
    ),
    
    // 2. مودرن زجاجي
    AppThemeData(
      name: 'soft_glass',
      label: 'مودرن زجاجي',
      background: const Color(0xFFF8FAFD),
      text: const Color(0xFF1E293B),
      button: const Color(0xFF6366F1),
      card: const Color(0xFFFFFFFF).withOpacity(0.6),
      menu: const Color(0xFFF1F5F9).withOpacity(0.8),
      buttonText: Colors.white,
      isDark: false,
    ),
    
    // 3. الملكي المذهب
    AppThemeData(
      name: 'royal_gold',
      label: 'الملكي المذهب',
      background: const Color(0xFF0F0F0F),
      text: const Color(0xFFEFDEC1),
      button: const Color(0xFFD4AF37),
      card: const Color(0xFF2C2C2C).withOpacity(0.7),
      menu: const Color(0xFF1A1A1A).withOpacity(0.9),
      buttonText: const Color(0xFF1A1A1A),
      isDark: true,
    ),
    
    // 4. الغابة الليلية
    AppThemeData(
      name: 'night_forest',
      label: 'الغابة الليلية',
      background: const Color(0xFF0A0F0D),
      text: const Color(0xFFE8F5E9),
      button: const Color(0xFF2E7D32),
      card: const Color(0xFF1B2420).withOpacity(0.6),
      menu: const Color(0xFF0D1310).withOpacity(0.9),
      buttonText: Colors.white,
      isDark: true,
    ),
  ];

  static AppThemeData get defaultTheme => allThemes[0];
}

class AppThemeData {
  final String name;
  final String label;
  final Color background;
  final Color text;
  final Color card;
  final Color button;
  final Color menu;
  final Color buttonText;
  final bool isDark;

  AppThemeData({
    required this.name,
    required this.label,
    required this.background,
    required this.text,
    required this.card,
    required this.button,
    required this.menu,
    required this.buttonText,
    required this.isDark,
  });

  // توليد ألوان التدرج آلياً بناءً على لون الخلفية
  List<Color> get gradientColors => isDark 
    ? [background, const Color(0xFF1A1A1A)] 
    : [background, button.withOpacity(0.1)];
}

// إضافة ميزة الزجاج (Frozen) لكل الـ Widgets
extension GlassmorphismEffect on Widget {
  Widget frozen({
    double blur = 15.0, 
    Color? color, 
    double borderRadius = 20.0,
    double borderWidth = 1.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: borderWidth,
            ),
          ),
          child: this,
        ),
      ),
    );
  }
}
