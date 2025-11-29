import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import 'games/xoxo_game.dart';
import 'games/sudoku_game.dart';

class MiniGamesScreen extends StatefulWidget {
  const MiniGamesScreen({super.key});

  @override
  State<MiniGamesScreen> createState() => _MiniGamesScreenState();
}

class _MiniGamesScreenState extends State<MiniGamesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Mini Games',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                    ),
              ),
            ),
            // Games Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  GameCard(
                    title: 'Tic Tac Toe',
                    icon: LucideIcons.grid,
                    gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
                    onTap: () => _navigateToGame(context, const XoxoGame()),
                  ),
                  GameCard(
                    title: 'Sudoku',
                    icon: LucideIcons.squareDot,
                    gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
                    onTap: () => _navigateToGame(context, const SudokuGame()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context, Widget game) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => game),
    );
  }
}

class GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const GameCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
