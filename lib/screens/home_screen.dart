import 'package:app_auth/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/format.dart';
import '../l10n/strings.dart';
import '../models/slot_view.dart';
import '../services/settings_service.dart';
import '../services/tanita_service.dart';
import '../services/tanita_sync.dart';
import '../widgets/app_menu.dart';
import '../widgets/backdrop.dart';
import 'dashboard_screen.dart';
import 'import_screen.dart';
import '../widgets/gradient_app_bar.dart';

/// Startbildschirm: Kacheln für die Slots der Waage.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openImport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ImportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final service = context.watch<TanitaService>();
    final auth = context.watch<AuthService>();
    final sync = context.watch<TanitaSync>();
    final lang = settings.language;

    final last = service.lastImport;
    final days = last == null ? null : DateTime.now().difference(last).inDays;
    final due = last == null || days! >= settings.remindDays;

    return BackdropScaffold(
      appBar: GradientAppBar(
        title: Text(context.t('app_title')),
        actions: [
          IconButton(
            tooltip: context.t('tt_account'),
            icon: Icon(
              auth.loggedIn ? Icons.account_circle : Icons.account_circle_outlined,
            ),
            onPressed: () => openAccountScreen(
              context,
              context.read<AuthService>(),
              appName: 'Tanita Anzeige',
            ),
          ),
          const AppMenuButton(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (due && !settings.dueDismissed)
                _DueBanner(
                  text: last == null
                      ? context.t('home_due_never')
                      : context.t('home_due_days', [days, settings.remindDays]),
                  onImport: () => _openImport(context),
                  onLater: settings.dismissDue,
                ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  context.t('home_profiles_n', [settings.slotCount]).toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                ),
              ),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  mainAxisExtent: 184,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                children: [
                  for (var n = 1; n <= settings.slotCount; n++)
                    _SlotTile(slotNumber: n, lang: lang),
                ],
              ),
              const SizedBox(height: 16),
              _SyncLine(
                loggedIn: auth.loggedIn,
                state: sync.state,
                lastSync: sync.lastSync,
                lang: lang,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueBanner extends StatelessWidget {
  const _DueBanner({
    required this.text,
    required this.onImport,
    required this.onLater,
  });

  final String text;
  final VoidCallback onImport;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.onTertiaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('home_due_title'),
                      style: TextStyle(
                        color: scheme.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      style: TextStyle(color: scheme.onTertiaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.folder_open),
                  label: Text(
                    context.t('home_choose'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onLater,
                child: Text(context.t('home_later')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slotNumber, required this.lang});

  final int slotNumber;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TanitaService>();
    final settings = context.watch<SettingsService>();
    final scheme = Theme.of(context).colorScheme;
    final data = service.slot(slotNumber);

    if (data == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(lang, 'home_empty_tap'))),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$slotNumber',
                style: TextStyle(
                  fontSize: 56,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: scheme.outline,
                ),
              ),
              const Spacer(),
              Text(
                tr(lang, 'home_empty'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Text(
                tr(lang, 'home_empty_sub'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final view = SlotView(data, hideSuspicious: settings.hideSuspicious);
    final lastM = view.last ?? data.last;
    final weight = lastM?['Wk'];
    final title = settings.nameOf(slotNumber) ?? profileLine(lang, data);
    final dark = Theme.of(context).brightness == Brightness.dark;
    const onBand = Colors.white;
    final band = dark
        ? const [Color(0xFF4A5A6A), Color(0xFF1E2530)]
        : const [AppColors.teal, AppColors.tealLight];
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DashboardScreen(slotNumber: slotNumber),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: band,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$slotNumber',
                    style: const TextStyle(
                      fontSize: 52,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: onBand,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        weight == null ? '–' : '${fmtNum(lang, weight)} kg',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      data.lastImport == null
                          ? ''
                          : tr(lang, 'home_import_label', [fmtDate(lang, data.lastImport!)]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncLine extends StatelessWidget {
  const _SyncLine({
    required this.loggedIn,
    required this.state,
    required this.lastSync,
    required this.lang,
  });

  final bool loggedIn;
  final String state;
  final DateTime? lastSync;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String text;
    if (!loggedIn) {
      text = tr(lang, 'home_local');
    } else {
      final status = switch (state) {
        'running' => tr(lang, 'sync_running'),
        'failed' => tr(lang, 'sync_failed'),
        _ => lastSync == null
            ? tr(lang, 'sync_idle')
            : '${tr(lang, 'sync_idle')} (${fmtDateTime(lang, lastSync!)})',
      };
      text = tr(lang, 'home_sync_in', [status]);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          loggedIn ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          size: 18,
          color: scheme.primary,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
