import 'package:flutter/material.dart';
import '../../core/services/locale_provider.dart';

class _LanguageItem {
  final Locale? locale;
  final String label;
  const _LanguageItem(this.locale, this.label);
}

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  @override
  Widget build(BuildContext context) {
    final provider = LocaleProvider.instance;
    final current = provider.locale;

    final items = <_LanguageItem>[
      const _LanguageItem(null, 'System default'),
      const _LanguageItem(Locale('en'), 'English'),
      const _LanguageItem(Locale('vi'), 'Tiếng Việt'),
      const _LanguageItem(Locale('ja'), '日本語'),
      const _LanguageItem(Locale('zh'), '中文'),
      const _LanguageItem(Locale('ko'), '한국어'),
    ];

    return DropdownButton<Locale?>(
      value: current,
      onChanged: (Locale? v) {
        provider.setLocale(v);
        setState(() {});
      },
      items: items.map((it) => DropdownMenuItem<Locale?>(value: it.locale, child: Text(it.label))).toList(),
    );
  }
}
