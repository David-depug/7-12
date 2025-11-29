import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_colors.dart';

class XoxoGame extends StatefulWidget {
  const XoxoGame({super.key});

  @override
  State<XoxoGame> createState() => _XoxoGameState();
}

class _XoxoGameState extends State<XoxoGame> {
  late List<String> board;
  late bool gameOver;
  late String winner;
  late bool isAIThinking;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    board = List.filled(9, '');
    gameOver = false;
    winner = '';
    isAIThinking = false;
  }

  void _makeMove(int index) {
    if (gameOver || board[index].isNotEmpty || isAIThinking) return;

    setState(() {
      board[index] = 'X';
    });

    if (_checkWinnerFor('X')) {
      setState(() {
        winner = 'X';
        gameOver = true;
      });
      return;
    }

    if (board.every((cell) => cell.isNotEmpty)) {
      setState(() {
        gameOver = true;
        winner = 'Draw';
      });
      return;
    }

    // AI's turn
    setState(() {
      isAIThinking = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final aiMove = _getBestMove();
      if (aiMove != -1) {
        setState(() {
          board[aiMove] = 'O';
        });

        if (_checkWinnerFor('O')) {
          setState(() {
            winner = 'O';
            gameOver = true;
            isAIThinking = false;
          });
          return;
        }

        if (board.every((cell) => cell.isNotEmpty)) {
          setState(() {
            gameOver = true;
            winner = 'Draw';
            isAIThinking = false;
          });
          return;
        }
      }

      setState(() {
        isAIThinking = false;
      });
    });
  }

  int _getBestMove() {
    int bestScore = -999;
    int bestMove = -1;

    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) {
        board[i] = 'O';
        final score = _minimax(0, false);
        board[i] = '';

        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }

    return bestMove;
  }

  int _minimax(int depth, bool isMaximizing) {
    final terminalState = _getTerminalState();
    if (terminalState != null) {
      if (terminalState == 'O') return 10 - depth;
      if (terminalState == 'X') return depth - 10;
      return 0; // Draw
    }

    if (isMaximizing) {
      int bestScore = -999;
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) {
          board[i] = 'O';
          final score = _minimax(depth + 1, false);
          board[i] = '';
          bestScore = score > bestScore ? score : bestScore;
        }
      }
      return bestScore;
    } else {
      int bestScore = 999;
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) {
          board[i] = 'X';
          final score = _minimax(depth + 1, true);
          board[i] = '';
          bestScore = score < bestScore ? score : bestScore;
        }
      }
      return bestScore;
    }
  }

  String? _getTerminalState() {
    if (_checkWinnerFor('O')) return 'O';
    if (_checkWinnerFor('X')) return 'X';
    if (board.every((cell) => cell.isNotEmpty)) return 'Draw';
    return null;
  }

  bool _checkWinnerFor(String player) {
    const winningConditions = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final condition in winningConditions) {
      if (board[condition[0]] == player &&
          board[condition[1]] == player &&
          board[condition[2]] == player) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe vs AI'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status
            Text(
              gameOver
                  ? winner == 'Draw'
                      ? 'It\'s a Draw!'
                      : winner == 'X'
                          ? 'You Won!'
                          : 'AI Won!'
                  : isAIThinking
                      ? 'AI is thinking...'
                      : 'Your Turn (X)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Game Board
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.purple, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: !isAIThinking ? () => _makeMove(index) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: index % 3 != 2
                              ? BorderSide(color: AppColors.purple, width: 1)
                              : BorderSide.none,
                          bottom: index < 6
                              ? BorderSide(color: AppColors.purple, width: 1)
                              : BorderSide.none,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          board[index],
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: board[index] == 'X'
                                ? AppColors.purple
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Reset Button
            ElevatedButton(
              onPressed: () => setState(() => _initializeGame()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'New Game',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
