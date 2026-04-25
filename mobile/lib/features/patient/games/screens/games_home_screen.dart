import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alz_ai/features/patient/games/screens/memory_game_screen.dart';
import 'package:alz_ai/features/patient/games/screens/word_association_screen.dart';
import 'package:alz_ai/features/patient/games/screens/photo_recognition_screen.dart';
import 'package:alz_ai/features/patient/games/screens/number_sequence_screen.dart';
import 'package:alz_ai/features/patient/games/screens/pattern_matching_screen.dart';

class GamesHomeScreen extends ConsumerWidget {
  const GamesHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    
    final labels = {
      'en': 'Cognitive Hub',
      'hi': 'संज्ञानात्मक केंद्र',
      'mr': 'संज्ञानात्मक केंद्र',
    }[lang] ?? 'Cognitive Hub';

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                labels.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF2D31FA)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.psychology_rounded,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildGameTile(context, index, lang);
                },
                childCount: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile(BuildContext context, int index, String lang) {
    final games = [
      {
        'title': {'en': 'Memory', 'hi': 'याददाश्त', 'mr': 'स्मरणशक्ती'},
        'icon': Icons.extension_rounded,
        'color': const Color(0xFF5D62FB),
        'screen': const MemoryGameScreen(),
      },
      {
        'title': {'en': 'Words', 'hi': 'शब्द', 'mr': 'शब्द'},
        'icon': Icons.spellcheck_rounded,
        'color': const Color(0xFFFF9500),
        'screen': const WordAssociationScreen(),
      },
      {
        'title': {'en': 'Photos', 'hi': 'फोटो', 'mr': 'फोटो'},
        'icon': Icons.camera_rounded,
        'color': const Color(0xFF34C759),
        'screen': const PhotoRecognitionScreen(),
      },
      {
        'title': {'en': 'Numbers', 'hi': 'नंबर', 'mr': 'नंबर'},
        'icon': Icons.onetwothree_rounded,
        'color': const Color(0xFF2D31FA),
        'screen': const NumberSequenceScreen(),
      },
      {
        'title': {'en': 'Patterns', 'hi': 'पैटर्न', 'mr': 'पैटर्न'},
        'icon': Icons.grid_view_rounded,
        'color': const Color(0xFFFF3B30),
        'screen': const PatternMatchingScreen(),
      },
    ];

    final game = games[index];
    final title = (game['title'] as Map<String, String>)[lang] ?? (game['title'] as Map<String, String>)['en']!;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => game['screen'] as Widget)),
      child: Container(
        decoration: AppTheme.glassDecoration().copyWith(
          border: Border.all(color: (game['color'] as Color).withValues(alpha: 0.2), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (game['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(game['icon'] as IconData, size: 40, color: game['color'] as Color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ).animate().scale(delay: (100 * index).ms).fadeIn(),
    );
  }
}
