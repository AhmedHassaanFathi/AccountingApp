import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Accounting 360',
      'login': 'Login',
      'email': 'Email',
      'password': 'Password',
      'registerNew': 'Register as a new employee',
      'dashboard': 'Dashboard',
      'delegates': 'Delegates',
      'transactions': 'Transactions',
      'reports': 'Reports',
      'settings': 'Settings',
      'theme': 'Theme',
      'lightTheme': 'Light Theme',
      'darkTheme': 'Dark Theme',
      'language': 'Language',
      'arabic': 'Arabic',
      'english': 'English',
      'logout': 'Logout',
      'addDelegate': 'Add Delegate',
      'editDelegate': 'Edit Delegate',
      'addRecord': 'Add Daily Record',
      'totalCollected': 'Total Collected',
      'amountPaid': 'Amount Paid',
      'officeShare': 'Office Share',
      'delegateShare': 'Delegate Share',
      'remaining': 'Remaining',
      'previousDebt': 'Previous Debt',
      'remFromThis': 'Rem. from this',
      'save': 'Save',
      'cancel': 'Cancel',
      'newRecord': 'New Daily Record',
      'delegateDetails': 'Delegate Details',
      'totalMade': 'Total Made',
      'name': 'Name',
      'type': 'Type',
      'percentageBased': 'Percentage-based',
      'halfBased': 'Half-based',
      'officePercentage': 'Office Percentage',
      'delegatePercentage': 'Delegate Percentage',
      'noDelegates': 'No delegates found.',
      'exportPdf': 'Export PDF',
      'selectDateRange': 'Select Date Range',
    },
    'ar': {
      'appTitle': 'حسابات 360',
      'login': 'تسجيل الدخول',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'registerNew': 'موظف חדש',
      'dashboard': 'لوحة التحكم',
      'delegates': 'المناديب',
      'transactions': 'المعاملات والتوريد',
      'reports': 'التقارير',
      'settings': 'الإعدادات',
      'theme': 'المظهر',
      'lightTheme': 'مظهر فاتح',
      'darkTheme': 'مظهر داكن',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      'logout': 'تسجيل الخروج',
      'addDelegate': 'إضافة مندوب',
      'editDelegate': 'تعديل مستندات المندوب',
      'addRecord': 'إضافة يومية جديدة',
      'totalCollected': 'المبلغ الإجمالي المحصل',
      'amountPaid': 'المبلغ المورد (المدفوع)',
      'officeShare': 'إجمالي نسبة المكتب',
      'delegateShare': 'صافي حصة المندوب',
      'remaining': 'المتبقي',
      'previousDebt': 'الديون المتراكمة',
      'remFromThis': 'متبقي مع المندوب',
      'save': 'حفظ العملية',
      'cancel': 'تراجع',
      'newRecord': 'تصفية وتقفيل حساب اليوم',
      'delegateDetails': 'تفاصيل المندوب',
      'totalMade': 'صافي الإيرادات',
      'name': 'اسم المندوب',
      'type': 'نظام الحساب',
      'percentageBased': 'نظام عمولة كلية',
      'halfBased': 'نص بالنص (نظام 50%)',
      'officePercentage': 'حصة المكتب (%)',
      'delegatePercentage': 'نسبة المندوب (%)',
      'noDelegates': 'لا يوجد مناديب مسجلين. أضف مندوباً جديداً الآن!',
      'exportPdf': 'طباعة تقرير PDF',
      'selectDateRange': 'تحديد فترة التقرير',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsExtension on BuildContext {
  String loc(String key) {
    return AppLocalizations.of(this).translate(key);
  }
}
