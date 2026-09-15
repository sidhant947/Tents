import 'package:tents/domain/models/game_level.dart';
import 'package:tents/ui/features/game/view_models/game_view_model.dart';

class CellRules {
  const CellRules._();


  static List<List<bool>> computeConflicts(
    List<List<CellState>> board,
    GameLevel level,
  ) {
    final n = level.gridSize;
    final conflicts = List.generate(n, (_) => List<bool>.filled(n, false));

    final rowCounts = List<int>.filled(n, 0);
    final colCounts = List<int>.filled(n, 0);
    final tents = <List<int>>[];

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (board[i][j] == CellState.tent) {
          tents.add([i, j]);
          rowCounts[i]++;
          colCounts[j]++;
        }
      }
    }

    for (final tent in tents) {
      final r = tent[0];
      final c = tent[1];

      if (rowCounts[r] > level.rowTentCounts[r]) {
        conflicts[r][c] = true;
      }
      if (colCounts[c] > level.colTentCounts[c]) {
        conflicts[r][c] = true;
      }

      bool hasAdjacentTree = false;
      final orthogonal = [
        [r - 1, c],
        [r + 1, c],
        [r, c - 1],
        [r, c + 1],
      ];
      for (final pos in orthogonal) {
        final nr = pos[0];
        final nc = pos[1];
        if (nr >= 0 && nr < n && nc >= 0 && nc < n) {
          if (board[nr][nc] == CellState.tree || level.trees[nr][nc]) {
            hasAdjacentTree = true;
            break;
          }
        }
      }
      if (!hasAdjacentTree) {
        conflicts[r][c] = true;
      }
    }

    for (int a = 0; a < tents.length; a++) {
      for (int b = a + 1; b < tents.length; b++) {
        final r1 = tents[a][0];
        final c1 = tents[a][1];
        final r2 = tents[b][0];
        final c2 = tents[b][1];

        if ((r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1) {
          conflicts[r1][c1] = true;
          conflicts[r2][c2] = true;
        }
      }
    }

    return conflicts;
  }

  static int countTents(List<List<CellState>> board) {
    int count = 0;
    for (final row in board) {
      for (final cell in row) {
        if (cell == CellState.tent) count++;
      }
    }
    return count;
  }

  static bool isComplete(List<List<CellState>> board, GameLevel level) {
    final n = level.gridSize;

    if (countTents(board) != level.totalTrees) return false;

    for (int r = 0; r < n; r++) {
      int count = 0;
      for (int c = 0; c < n; c++) {
        if (board[r][c] == CellState.tent) count++;
      }
      if (count != level.rowTentCounts[r]) return false;
    }

    for (int c = 0; c < n; c++) {
      int count = 0;
      for (int r = 0; r < n; r++) {
        if (board[r][c] == CellState.tent) count++;
      }
      if (count != level.colTentCounts[c]) return false;
    }

    final conflicts = computeConflicts(board, level);
    for (final row in conflicts) {
      for (final cell in row) {
        if (cell) return false;
      }
    }

    return _canMatchAllTreesToTents(board, level);
  }

  static bool _canMatchAllTreesToTents(List<List<CellState>> board, GameLevel level) {
    final n = level.gridSize;
    final treesList = <List<int>>[];
    final tentsList = <List<int>>[];

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (level.trees[r][c]) treesList.add([r, c]);
        if (board[r][c] == CellState.tent) tentsList.add([r, c]);
      }
    }

    if (treesList.length != tentsList.length) return false;

    final match = List<int>.filled(tentsList.length, -1);

    bool dfs(int treeIdx, List<bool> visited) {
      final tr = treesList[treeIdx][0];
      final tc = treesList[treeIdx][1];

      for (int tentIdx = 0; tentIdx < tentsList.length; tentIdx++) {
        final teR = tentsList[tentIdx][0];
        final teC = tentsList[tentIdx][1];

        final isAdj = (tr == teR && (tc - teC).abs() == 1) || (tc == teC && (tr - teR).abs() == 1);
        if (isAdj && !visited[tentIdx]) {
          visited[tentIdx] = true;
          if (match[tentIdx] < 0 || dfs(match[tentIdx], visited)) {
            match[tentIdx] = treeIdx;
            return true;
          }
        }
      }
      return false;
    }

    int matchedCount = 0;
    for (int i = 0; i < treesList.length; i++) {
      final visited = List<bool>.filled(tentsList.length, false);
      if (dfs(i, visited)) matchedCount++;
    }

    return matchedCount == treesList.length;
  }

  static List<int>? suggestHint(List<List<CellState>> board, GameLevel level) {
    final n = level.gridSize;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (level.solutionTents[r][c] && board[r][c] != CellState.tent) {
          return [r, c];
        }
      }
    }
    return null;
  }
}
