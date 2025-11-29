import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_colors.dart';

class SudokuGame extends StatefulWidget {
  const SudokuGame({super.key});

  @override
  State<SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends State<SudokuGame> {
  late List<List<int>> board;
  late List<List<int>> originalBoard;
  late List<List<bool>> isFixed;
  int? selectedRow;
  int? selectedCol;

  @override
  void initState() {
    super.initState();
    _generateSudoku();
  }

  void _generateSudoku() {
    // Generate a simple Sudoku puzzle
    board = [
      [5, 3, 0, 0, 7, 0, 0, 0, 0],
      [6, 0, 0, 1, 9, 5, 0, 0, 0],
      [0, 9, 8, 0, 0, 0, 0, 6, 0],
      [8, 0, 0, 0, 6, 0, 0, 0, 3],
      [4, 0, 0, 8, 0, 3, 0, 0, 1],
      [7, 0, 0, 0, 2, 0, 0, 0, 6],
      [0, 6, 0, 0, 0, 0, 2, 8, 0],
      [0, 0, 0, 4, 1, 9, 0, 0, 5],
      [0, 0, 0, 0, 8, 0, 0, 7, 9],
    ];
    
    originalBoard = [
      [5, 3, 0, 0, 7, 0, 0, 0, 0],
      [6, 0, 0, 1, 9, 5, 0, 0, 0],
      [0, 9, 8, 0, 0, 0, 0, 6, 0],
      [8, 0, 0, 0, 6, 0, 0, 0, 3],
      [4, 0, 0, 8, 0, 3, 0, 0, 1],
      [7, 0, 0, 0, 2, 0, 0, 0, 6],
      [0, 6, 0, 0, 0, 0, 2, 8, 0],
      [0, 0, 0, 4, 1, 9, 0, 0, 5],
      [0, 0, 0, 0, 8, 0, 0, 7, 9],
    ];

    isFixed = List.generate(
      9,
      (i) => List.generate(9, (j) => originalBoard[i][j] != 0),
    );
  }

  void _placeNumber(int number) {
    if (selectedRow != null && selectedCol != null) {
      if (!isFixed[selectedRow!][selectedCol!]) {
        setState(() {
          if (board[selectedRow!][selectedCol!] == number) {
            board[selectedRow!][selectedCol!] = 0;
          } else {
            board[selectedRow!][selectedCol!] = number;
          }
        });
      }
    }
  }

  bool _isValidMove(int row, int col, int number) {
    // Check row
    if (board[row].contains(number)) return false;

    // Check column
    for (int i = 0; i < 9; i++) {
      if (board[i][col] == number) return false;
    }

    // Check 3x3 box
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (board[i][j] == number) return false;
      }
    }

    return true;
  }

  bool _isSolved() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] == 0) return false;
      }
    }
    return true;
  }

  void _resetGame() {
    setState(() {
      _generateSudoku();
      selectedRow = null;
      selectedCol = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status
              if (_isSolved())
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Congratulations! You solved it!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                Text(
                  'Fill the grid',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.purple,
                      ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              // Game Board
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.purple, width: 3),
                ),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemCount: 81,
                  itemBuilder: (context, index) {
                    int row = index ~/ 9;
                    int col = index % 9;
                    bool isSelected = selectedRow == row && selectedCol == col;
                    bool isBoxStart = row % 3 == 0 && col % 3 == 0;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRow = row;
                          selectedCol = col;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.purple.withOpacity(0.3)
                              : Colors.transparent,
                          border: Border(
                            top: (row == 0 || row % 3 == 0)
                                ? BorderSide(color: AppColors.purple, width: 2)
                                : BorderSide(
                                    color: Colors.grey,
                                    width: 0.5,
                                  ),
                            left: (col == 0 || col % 3 == 0)
                                ? BorderSide(color: AppColors.purple, width: 2)
                                : BorderSide(
                                    color: Colors.grey,
                                    width: 0.5,
                                  ),
                            right: (col == 8 || col % 3 == 2)
                                ? BorderSide(color: AppColors.purple, width: 2)
                                : BorderSide.none,
                            bottom: (row == 8 || row % 3 == 2)
                                ? BorderSide(color: AppColors.purple, width: 2)
                                : BorderSide.none,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            board[row][col] == 0 ? '' : '${board[row][col]}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isFixed[row][col]
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isFixed[row][col]
                                  ? Colors.black
                                  : AppColors.purple,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Number Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(
                  9,
                  (index) => SizedBox(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _placeNumber(index + 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Clear Button
              ElevatedButton(
                onPressed: () {
                  if (selectedRow != null && selectedCol != null) {
                    _placeNumber(0);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              // Reset Button
              ElevatedButton(
                onPressed: _resetGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'New Game',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
