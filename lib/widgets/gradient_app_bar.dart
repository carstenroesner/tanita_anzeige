import 'package:flutter/material.dart';

/// Verlaufsbalken unter einer Überschrift (Design „Variante B“).
class GradientBar extends StatelessWidget {
  const GradientBar({super.key, this.height = 4});

  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final start = dark ? const Color(0xFF9CC9F2) : const Color(0xFF0E7C86);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height),
        gradient: LinearGradient(colors: [start, start.withAlpha(0)]),
      ),
    );
  }
}

/// Titelleiste mit heller, schlanker Schrift und Verlaufsbalken darunter.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({super.key, required this.title, this.actions});

  final Widget title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 14);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(14),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GradientBar(),
          ),
        ),
      ),
    );
  }
}
