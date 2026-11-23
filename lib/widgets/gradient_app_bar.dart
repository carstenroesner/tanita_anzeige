import 'package:flutter/material.dart';

/// Verlaufsbalken unter einer Überschrift (Design „Variante B“).
class GradientBar extends StatelessWidget {
  const GradientBar({super.key, this.height = 4});

  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final start = dark ? const Color(0xFF9CC9F2) : Colors.white;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height),
        gradient: LinearGradient(colors: [start, start.withAlpha(0)]),
      ),
    );
  }
}

/// Titelleiste mit weißer, schlanker Schrift auf einem leicht durchsichtigen
/// Feld (Glas-Optik) und Verlaufsbalken darunter.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({super.key, required this.title, this.actions});

  final Widget title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 14);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glass = dark ? const Color(0x1AFFFFFF) : const Color(0x940A5A64);
    final edge = dark ? const Color(0x2EFFFFFF) : const Color(0x73FFFFFF);
    return AppBar(
      foregroundColor: Colors.white,
      titleSpacing: 28,
      title: title,
      actions: actions,
      flexibleSpace: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: glass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: edge, width: 0.7),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(14),
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 28, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GradientBar(),
          ),
        ),
      ),
    );
  }
}
