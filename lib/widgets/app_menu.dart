import 'package:app_auth/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../screens/feature_overview_screen.dart';
import '../screens/settings_screen.dart';
import '../services/issue_link.dart';
import '../services/settings_service.dart';

enum _MenuAction { account, settings, features, report, about }

/// Standard-Dreipunktemenü (⋮) der App.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  PopupMenuItem<_MenuAction> _item(
    _MenuAction value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<_MenuAction>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _handle(BuildContext context, _MenuAction action) {
    switch (action) {
      case _MenuAction.account:
        openAccountScreen(
          context,
          context.read<AuthService>(),
          appName: 'Tanita Anzeige',
        );
      case _MenuAction.settings:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
        );
      case _MenuAction.features:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const FeatureOverviewScreen()),
        );
      case _MenuAction.report:
        showDialog<void>(
          context: context,
          builder: (_) => const _ReportIssueDialog(),
        );
      case _MenuAction.about:
        showDialog<void>(context: context, builder: (_) => const _AboutDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthService>().loggedIn;
    return PopupMenuButton<_MenuAction>(
      tooltip: context.t('tt_menu'),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _handle(context, action),
      itemBuilder: (_) => [
        _item(
          _MenuAction.account,
          Icons.account_circle_outlined,
          context.t(loggedIn ? 'menu_account_in' : 'menu_account'),
        ),
        _item(_MenuAction.settings, Icons.settings_outlined, context.t('menu_settings')),
        _item(_MenuAction.features, Icons.checklist, context.t('menu_features')),
        _item(_MenuAction.report, Icons.bug_report_outlined, context.t('menu_report')),
        _item(_MenuAction.about, Icons.info_outline, context.t('menu_about')),
      ],
    );
  }
}

class _ReportIssueDialog extends StatefulWidget {
  const _ReportIssueDialog();

  @override
  State<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<_ReportIssueDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _isProblem = true;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final lang = context.read<SettingsService>().language;
    final uri = buildIssueUri(
      isProblem: _isProblem,
      title: _title.text,
      body: _description.text,
    );
    final navigator = Navigator.of(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (ok) {
      navigator.pop();
    } else {
      setState(() => _error = tr(lang, 'report_browser_error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.t('report_title')),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(context.t('report_problem')),
                    icon: const Icon(Icons.bug_report_outlined),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(context.t('report_idea')),
                    icon: const Icon(Icons.lightbulb_outline),
                  ),
                ],
                selected: {_isProblem},
                onSelectionChanged: (s) => setState(() => _isProblem = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: context.t('report_title_label'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: context.t('report_desc_label'),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.t('report_hint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('cancel')),
        ),
        FilledButton.icon(
          onPressed: _open,
          icon: const Icon(Icons.open_in_new),
          label: Text(context.t('report_open')),
        ),
      ],
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.t('app_title')),
      content: Text(context.t('about_text', [DateTime.now().year])),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('close')),
        ),
      ],
    );
  }
}
