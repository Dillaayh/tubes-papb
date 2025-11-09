// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // Priority list
  static const List<String> priorities = [
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];

  // Icon mapping untuk kategori (by name)
  static const Map<String, IconData> categoryIcons = {
    'Kuliah': Icons.school,
    'Rumah': Icons.home,
    'Belanja': Icons.shopping_cart,
    'Lainnya': Icons.category,
  };

  // Color mapping untuk kategori (by name)
  static const Map<String, Color> categoryColors = {
    'Kuliah': Color(0xFF6366F1), // Indigo
    'Rumah': Color(0xFF10B981), // Green
    'Belanja': Color(0xFFF59E0B), // Orange
    'Lainnya': Color(0xFF8B5CF6), // Purple
  };

  // Priority colors
  static const Map<String, Color> priorityColors = {
    'Low': Color(0xFF10B981), // Green
    'Medium': Color(0xFFF59E0B), // Orange
    'High': Color(0xFFEF4444), // Red
    'Urgent': Color(0xFF991B1B), // Dark Red
  };

  // Priority icons
  static const Map<String, IconData> priorityIcons = {
    'Low': Icons.flag_outlined,
    'Medium': Icons.flag,
    'High': Icons.flag,
    'Urgent': Icons.flag,
  };

  // Helper methods
  static IconData getCategoryIcon(String categoryName) {
    return categoryIcons[categoryName] ?? Icons.category;
  }

  static Color getCategoryColor(String categoryName) {
    return categoryColors[categoryName] ?? const Color(0xFF6B7280);
  }

  static Color getPriorityColor(String priority) {
    return priorityColors[priority] ?? const Color(0xFF6B7280);
  }

  static IconData getPriorityIcon(String priority) {
    return priorityIcons[priority] ?? Icons.flag_outlined;
  }
}
