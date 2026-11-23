import 'package:app_auth/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/settings_service.dart';
import '../services/tanita_sync.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final auth = context.watch<AuthService>();
    final sync = context.watch<TanitaSync>();
    final scheme = Theme.of(context).colorScheme;

    Widget header(String key) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            context.t(key).toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 0.6,
                ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(context.t('set_title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            children: [
              header('set_account'),
              ListTile(
                leading: Icon(
                  auth.loggedIn ? Icons.account_circle : Icons.account_circle_outlined,
                ),
                title: Text(
                  auth.loggedIn
                      ? context.t('set_account_in', [auth.email ?? ''])
                      : context.t('set_account_out'),
                ),
                trailing: TextButton(
                  onPressed: () => openAccountScreen(
                    context,
                    context.read<AuthService>(),
                    appName: 'Tanita Anzeige',
                  ),
                  child: Text(context.t('set_account_btn')),
                ),
              ),
              if (auth.loggedIn)
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: Text(context.t('set_sync_now')),
                  trailing: sync.state == 'running'
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: sync.state == 'running' ? null : sync.syncNow,
                ),
              header('set_language'),
              for (final code in kLanguages)
                ListTile(
                  leading: Icon(
                    code == s.language
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: code == s.language ? scheme.primary : null,
                  ),
                  title: Text(kLanguageNames[code] ?? code),
                  onTap: () => s.setLanguage(code),
                ),
              header('set_import'),
              ListTile(
                title: Text(context.t('set_remind')),
                subtitle: Text(context.t('set_remind_sub')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: s.remindDays > 1
                          ? () => s.setRemindDays(s.remindDays - 1)
                          : null,
                    ),
                    Text(context.t('set_days', [s.remindDays])),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: s.remindDays < 90
                          ? () => s.setRemindDays(s.remindDays + 1)
                          : null,
                    ),
                  ],
                ),
              ),
              header('set_display'),
              ListTile(
                title: Text(context.t('set_slots')),
                subtitle: Text(context.t('set_slots_sub')),
                trailing: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 4, label: Text('4')),
                    ButtonSegment(value: 8, label: Text('8')),
                  ],
                  selected: {s.slotCount},
                  onSelectionChanged: (v) => s.setSlotCount(v.first),
                ),
              ),
              SwitchListTile(
                title: Text(context.t('set_hide')),
                subtitle: Text(context.t('set_hide_sub')),
                value: s.hideSuspicious,
                onChanged: s.setHideSuspicious,
              ),
              SwitchListTile(
                title: Text(context.t('set_smooth')),
                subtitle: Text(context.t('set_smooth_sub')),
                value: s.smoothDefault,
                onChanged: s.setSmoothDefault,
              ),
              ListTile(
                title: Text(context.t('set_ranges')),
                subtitle: Text(context.t('set_ranges_sub')),
              ),
              ExpansionTile(
                title: Text(context.t('set_names')),
                subtitle: Text(context.t('set_names_sub')),
                children: [
                  for (var n = 1; n <= s.slotCount; n++)
                    _NameField(slot: n, settings: s),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField({required this.slot, required this.settings});

  final int slot;
  final SettingsService settings;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.settings.nameOf(widget.slot) ?? '');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _c,
        maxLength: 24,
        decoration: InputDecoration(
          prefixText: '${widget.slot}   ',
          labelText: context.t('set_name_hint'),
          border: const OutlineInputBorder(),
          counterText: '',
        ),
        onChanged: (v) => widget.settings.setName(widget.slot, v),
      ),
    );
  }
}
