import 'dart:typed_data';

import 'package:app_auth/app_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/slot_view.dart';
import '../services/settings_service.dart';
import '../services/tanita_parser.dart';
import '../services/tanita_service.dart';
import '../services/tanita_sync.dart';
import '../widgets/status_chip.dart';

/// Wählt Dateien aus (austauschbar für Tests).
typedef FilePickFn = Future<List<ImportFile>> Function();

Future<List<ImportFile>> pickWithFilePicker() async {
  final res = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: true,
    type: FileType.custom,
    allowedExtensions: const ['csv', 'zip'],
  );
  if (res == null) return const [];
  final out = <ImportFile>[];
  for (final f in res.files) {
    final Uint8List? bytes = f.bytes;
    if (bytes != null) out.add(ImportFile(f.name, bytes));
  }
  return out;
}

/// Import: Dateien der Waage wählen, Profile aktualisieren, neue Messungen
/// ergänzen und (bei Anmeldung) mit der Cloud abgleichen.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key, this.pick = pickWithFilePicker});

  final FilePickFn pick;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final List<ImportFile> _files = [];
  ImportResult? _result;
  bool _busy = false;
  bool _cloudDone = false;

  Future<void> _pick() async {
    final picked = await widget.pick();
    if (!mounted || picked.isEmpty) return;
    setState(() {
      _files.addAll(picked);
      _result = null;
    });
  }

  Future<void> _run() async {
    final service = context.read<TanitaService>();
    final sync = context.read<TanitaSync>();
    final auth = context.read<AuthService>();
    setState(() => _busy = true);
    final result = await service.importFiles(List.of(_files));
    var cloud = false;
    if (auth.loggedIn && !result.isEmpty) {
      await sync.syncNow();
      cloud = sync.state == 'idle';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
      _cloudDone = cloud;
      _files.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('import_title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: result == null ? _pickView(context) : _resultView(context, result),
          ),
        ),
      ),
    );
  }

  List<Widget> _pickView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withAlpha(110),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 40, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              context.t('import_pick_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              context.t('import_pick_text'),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.folder_open),
                label: Text(context.t('import_pick_btn')),
              ),
            ),
          ],
        ),
      ),
      if (_files.isNotEmpty) ...[
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('import_selected', [_files.length]),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                for (final f in _files.take(12))
                  Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                if (_files.length > 12) const Text('...'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _run,
                        child: _busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(context.t('import_run')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _busy ? null : () => setState(_files.clear),
                      child: Text(context.t('import_clear')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('import_what_title'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.person_outline, text: context.t('import_what_prof')),
              _InfoRow(icon: Icons.show_chart, text: context.t('import_what_data')),
              _InfoRow(icon: Icons.cloud_outlined, text: context.t('import_what_cloud')),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _resultView(BuildContext context, ImportResult result) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsService>();
    final lang = settings.language;
    if (result.isEmpty) {
      return [
        Text(
          context.t('import_none_found'),
          style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => _result = null),
          child: Text(context.t('import_pick_btn')),
        ),
      ];
    }
    final service = context.watch<TanitaService>();
    return [
      Row(
        children: [
          Icon(Icons.check_circle, size: 28, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('import_done'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  context.t('import_files_read', [result.filesRead]),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      for (final s in result.slots)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${s.slot}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        settings.nameOf(s.slot) ??
                            (service.slot(s.slot) == null
                                ? ''
                                : profileLine(lang, service.slot(s.slot)!)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LabeledChip(
                      text: s.added > 0
                          ? context.t('import_new_chip', [s.added])
                          : context.t('import_nothing_new'),
                      background: s.added > 0
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                      foreground: s.added > 0
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (s.profileUpdated && s.profile != null)
                  Text(
                    context.t('import_slot_profile', [_profileText(s)]),
                    style: const TextStyle(fontSize: 13),
                  ),
                Text(
                  context.t('import_slot_counts', [s.read, s.added]),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      if (result.flaggedTotal > 0)
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('import_flag_title', [result.flaggedTotal]),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.t('import_flag_text'),
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ],
          ),
        ),
      if (_cloudDone)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(Icons.cloud_done_outlined, color: scheme.primary),
            title: Text(context.t('import_cloud_done')),
          ),
        ),
      Text(
        context.t('import_empty_slots'),
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.t('import_to_home')),
      ),
    ];
  }

  String _profileText(SlotImportResult s) {
    final p = s.profile!;
    final parts = <String>[
      if (p.height != null) '${p.height!.round()} cm',
      if (p.birth != null)
        '${p.birth!.day.toString().padLeft(2, '0')}.'
            '${p.birth!.month.toString().padLeft(2, '0')}.${p.birth!.year}',
    ];
    return parts.join(', ');
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
