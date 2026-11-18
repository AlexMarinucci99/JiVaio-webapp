import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../data/jivaio_store.dart';
import '../theme/jivaio_theme.dart';

class PublicScaffold extends StatelessWidget {
  const PublicScaffold({
    required this.store,
    required this.child,
    this.showBrandMark = true,
    super.key,
  });

  final JivaioStore store;
  final Widget child;
  final bool showBrandMark;

  @override
  Widget build(BuildContext context) {
    final path = ModalRoute.of(context)?.settings.name ?? '/';
    final selected = path.startsWith('/line') ? '/lines' : path;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopNavigation(selected: selected, showBrandMark: showBrandMark),
            AnimatedBuilder(
              animation: store,
              builder: (context, _) => store.loadError == null
                  ? const SizedBox.shrink()
                  : MaterialBanner(
                      content: Text(store.loadError!),
                      actions: [
                        TextButton(
                          onPressed: () => store.refreshCloud(),
                          child: const Text('Riprova'),
                        ),
                      ],
                    ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: _MobileNavigation(selected: selected),
    );
  }
}

class _TopNavigation extends StatelessWidget {
  const _TopNavigation({required this.selected, required this.showBrandMark});
  final String selected;
  final bool showBrandMark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: JivaioColors.border),
              ),
              child: Row(
                children: [
                  if (showBrandMark) ...[
                    const BrandMark(size: 34),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    'JiVaio',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 21),
                  ),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .93),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: JivaioColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x101B3B6B),
                      blurRadius: 18,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (showBrandMark) ...[
                      const BrandMark(),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      'JiVaio',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 25),
                    ),
                    const Spacer(),
                    _NavLink(
                      label: 'Home',
                      route: '/',
                      selected: selected == '/',
                    ),
                    _NavLink(
                      label: 'Linee',
                      route: '/lines',
                      selected: selected == '/lines',
                    ),
                    _NavLink(
                      label: 'Avvisi',
                      route: '/alerts',
                      selected: selected == '/alerts',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.route,
    required this.selected,
  });
  final String label;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: TextButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed(route),
        style: TextButton.styleFrom(
          foregroundColor: selected
              ? JivaioColors.navy
              : JivaioColors.secondary,
          backgroundColor: selected
              ? JivaioColors.blueLight
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 13),
          shape: const StadiumBorder(),
          textStyle: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 15,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({required this.selected});
  final String selected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.sizeOf(context).width >= 650) {
          return const SizedBox.shrink();
        }
        final index = switch (selected) {
          '/lines' => 1,
          '/alerts' => 2,
          _ => 0,
        };
        const labels = ['Home', 'Linee', 'Avvisi'];
        const routes = ['/', '/lines', '/alerts'];
        const icons = [
          Icons.home_outlined,
          Icons.directions_bus_outlined,
          Icons.campaign_outlined,
        ];
        return SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .90),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: JivaioColors.border),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: Semantics(
                          selected: i == index,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushReplacementNamed(routes[i]),
                            style: TextButton.styleFrom(
                              foregroundColor: i == index
                                  ? JivaioColors.navy
                                  : JivaioColors.secondary,
                              backgroundColor: i == index
                                  ? JivaioColors.blueLight
                                  : Colors.transparent,
                              minimumSize: const Size(48, 58),
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icons[i], size: 22),
                                const SizedBox(height: 3),
                                Text(labels[i]),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: JivaioColors.blue,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Icon(
        Icons.directions_bus_rounded,
        color: Colors.white,
        size: size * .62,
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    required this.child,
    super.key,
    this.width = 1320,
    this.padding = const EdgeInsets.fromLTRB(24, 28, 24, 52),
  });
  final Widget child;
  final double width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    required this.title,
    required this.subtitle,
    super.key,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 14,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: JivaioColors.secondary),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class PreviewNotice extends StatelessWidget {
  const PreviewNotice({required this.store, super.key});
  final JivaioStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2DDAE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 19, color: Color(0xFF95620B)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              store.usesCloud
                  ? 'Orari in aggiornamento: verifica eventuali variazioni sui canali ufficiali AMA.'
                  : 'Dati di anteprima: gli orari locali provengono da un archivio precedente e vanno aggiornati prima della pubblicazione.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF755214),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
