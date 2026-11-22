import 'package:flutter/material.dart';

import '../../../../i18n/app_language.dart';
import '../home_hero_content.dart';

class HomeHero extends StatefulWidget {
  const HomeHero({required this.onOpenLines, super.key});
  final VoidCallback onOpenLines;
  @override
  State<HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<HomeHero> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _search.text.trim();
    if (query.isEmpty) {
      widget.onOpenLines();
      return;
    }
    Navigator.of(context).pushNamed('/lines', arguments: query);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 650;
    return Column(
      key: const Key('home-hero-layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, HomeHeroContent.title).replaceAll('\n', ' '),
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontSize: compact ? 32 : 48, letterSpacing: -1.2),
        ),
        const SizedBox(height: 8),
        TText(
          HomeHeroContent.description,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontSize: compact ? 16 : 19),
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: TextField(
            controller: _search,
            onSubmitted: (_) => _submit(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: tr(context, 'Cerca linea, fermata o destinazione'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(5),
                child: IconButton.filled(
                  tooltip: tr(context, 'Cerca linea, fermata o destinazione'),
                  onPressed: _submit,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
