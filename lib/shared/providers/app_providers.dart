import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../models/language.dart';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';

// Theme Mode Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Accent Color Provider
final accentColorProvider = StateProvider<AppAccentColor>((ref) => AppAccentColor.blue);

// User State Provider
final userProvider = StateProvider<UserModel?>((ref) => const UserModel(
  id: 'usr_10294',
  name: 'Alex Johnson',
  email: 'alex.johnson@polylingo.ai',
  avatarUrl: null,
  isGuest: false,
  plan: 'Pro Plan',
  translationsThisMonth: 23,
  translationsMonthlyLimit: 50,
  storageUsedGb: 1.2,
  storageTotalGb: 5.0,
));

// Languages Provider
final languagesProvider = FutureProvider<List<Language>>((ref) async {
  return await ApiClient.getLanguages();
});

// Selected Source Language Provider
final sourceLanguageProvider = StateProvider<Language>((ref) => const Language(
  code: 'auto', name: 'Auto Detect', nativeName: 'Auto Detect', flag: '🌐', popular: true,
));

// Selected Target Language Provider
final targetLanguageProvider = StateProvider<Language>((ref) => const Language(
  code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸', popular: true,
));

// Current Main Navigation Index Provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Current Active Translation Type Subtab (Text, PDF, Image, Word, Excel, Scan)
final activeTranslateTabProvider = StateProvider<String>((ref) => 'text');
