import 'package:flutter/material.dart';

/// Akzentfarben der App.
class AppColors {
  AppColors._();

  static const Color teal = Color(0xFF0E7C86);
  static const Color tealLight = Color(0xFF1FB5B0);
  static const Color orange = Color(0xFFFF8A3D);
}

/// Unscharfer, überbelichteter Sport-Hintergrund (abstrakte Silhouetten, keine
/// erkennbaren Personen).
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: Image.asset('assets/bg_sport.jpg', fit: BoxFit.cover),
        ),
        ColoredBox(color: surface.withAlpha(dark ? 215 : 40)),
      ],
    );
  }
}

/// Scaffold mit [AppBackdrop] dahinter und durchsichtiger Titelleiste.
class BackdropScaffold extends StatelessWidget {
  const BackdropScaffold({super.key, this.appBar, required this.body});

  final PreferredSizeWidget? appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackdrop(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
        ),
      ],
    );
  }
}
