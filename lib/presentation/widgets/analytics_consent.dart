import 'package:flutter/material.dart';

import '../../core/services/visitor_analytics.dart';
import '../../l10n/app_localizations.dart';

bool _prompting = false;

Future<void> promptAnalyticsConsent(BuildContext context) async {
  if (_prompting) return;
  _prompting = true;
  try {
    await VisitorAnalytics.instance.init();
    if (!context.mounted || VisitorAnalytics.instance.hasChoice) return;
    final strings = AppLocalizations.of(context)!;
    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.analyticsConsentTitle),
        content: Text(strings.analyticsConsentDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.analyticsConsentDecline),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.analyticsConsentAllow),
          ),
        ],
      ),
    );
    if (allowed != null) await VisitorAnalytics.instance.setConsent(allowed);
  } finally {
    _prompting = false;
  }
}

class AnalyticsConsentTile extends StatelessWidget {
  const AnalyticsConsentTile({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: VisitorAnalytics.instance,
    builder: (context, _) => SwitchListTile(
      title: Text(AppLocalizations.of(context)!.analyticsConsentTitle),
      subtitle: Text(AppLocalizations.of(context)!.analyticsConsentDescription),
      value: VisitorAnalytics.instance.enabled,
      onChanged: (enabled) async {
        await VisitorAnalytics.instance.setConsent(enabled);
      },
    ),
  );
}
