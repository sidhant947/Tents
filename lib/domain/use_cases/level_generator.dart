import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:tents/domain/models/game_level.dart';

class LevelGenerator {
  final Map<int, GameLevel> _cache = {};
  final Set<int> _generating = {};

  GameLevel generate(int levelNumber) {
    GameLevel level;
    if (_cache.containsKey(levelNumber)) {
      level = _cache.remove(levelNumber)!;
    } else {
      level = _generateInternal(levelNumber);
    }
    _generating.remove(levelNumber);
    _pregenerateNext(levelNumber + 1);
    return level;
  }

  Future<GameLevel> generateAsync(int levelNumber) async {
    GameLevel level;
    if (_cache.containsKey(levelNumber)) {
      level = _cache.remove(levelNumber)!;
    } else {
      level = await compute(_isolateGenerate, levelNumber);
    }
    _generating.remove(levelNumber);
    _pregenerateNext(levelNumber + 1);
    return level;
  }

  GameLevel _generateInternal(int levelNumber) {
    final random = Random(levelNumber);
    final gridSize = _getGridSize(levelNumber);
    return _generateLevelWithSeed(levelNumber, gridSize, random);
  }

  void pregenerateAround(int currentLevel, {int range = 1}) {
    for (int i = 0; i <= range; i++) {
      final levelNumber = currentLevel + i;
      if (levelNumber < 1) continue;
      if (!_cache.containsKey(levelNumber) && !_generating.contains(levelNumber)) {
        _generating.add(levelNumber);
        compute(_isolateGenerate, levelNumber).then((level) {
          _cache[levelNumber] = level;
          _generating.remove(levelNumber);
        }).catchError((e) {
          _generating.remove(levelNumber);
        });
      }
    }
  }

  void _pregenerateNext(int startLevel) {
    pregenerateAround(startLevel, range: 1);
  }

  static GameLevel _isolateGenerate(int levelNumber) {
    return LevelGenerator()._generateInternal(levelNumber);
  }

  static GameLevel _isolateGenerateRandom(Map<String, int> params) {
    return LevelGenerator().generateRandom(
      gridSize: params['gridSize']!,
      seed: params['seed']!,
    );
  }

  Future<GameLevel> generateRandomAsync({required int gridSize, required int seed}) {
    return compute(_isolateGenerateRandom, {'gridSize': gridSize, 'seed': seed});
  }

  GameLevel generateRandom({required int gridSize, required int seed}) {
    final random = Random(seed);
    return _generateLevelWithSeed(-1, gridSize, random);
  }

  int _getGridSize(int level) {
    if (level <= 5) return 5;
    if (level <= 20) return 6;
    if (level <= 45) return 7;
    if (level <= 80) return 8;
    if (level <= 130) return 9;
    if (level <= 190) return 10;
    if (level <= 250) return 11;
    return 12;
  }

  int _getTargetTreeCount(int gridSize, Random random) {
    switch (gridSize) {
      case 5:
        return 4 + random.nextInt(2);
      case 6:
        return 6 + random.nextInt(2);
      case 7:
        return 7 + random.nextInt(2);
      case 8:
        return 9 + random.nextInt(3);
      case 9:
        return 11 + random.nextInt(3);
      case 10:
        return 13 + random.nextInt(3);
      case 11:
        return 15 + random.nextInt(4);
      case 12:
        return 18 + random.nextInt(4);
      default:
        return (gridSize * 1.5).round();
    }
  }

  GameLevel _generateLevelWithSeed(
    int levelNumber,
    int gridSize,
    Random random,
  ) {
    int attempt = 0;
    while (attempt < 1000) {
      attempt++;
      final subSeed = levelNumber >= 0 ? (levelNumber * 10000 + attempt) : random.nextInt(1000000);
      final subRandom = Random(subSeed);
      final targetTrees = _getTargetTreeCount(gridSize, subRandom);

      final trees = List.generate(gridSize, (_) => List<bool>.filled(gridSize, false));
      final solutionTents = List.generate(gridSize, (_) => List<bool>.filled(gridSize, false));

      final allCells = <Point<int>>[];
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          allCells.add(Point(r, c));
        }
      }
      allCells.shuffle(subRandom);

      int placedCount = 0;

      for (final cell in allCells) {
        if (placedCount >= targetTrees) break;
        final r = cell.x;
        final c = cell.y;

        if (trees[r][c] || solutionTents[r][c]) continue;

        bool touchesTent = false;
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final nr = r + dr;
            final nc = c + dc;
            if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
              if (solutionTents[nr][nc]) {
                touchesTent = true;
                break;
              }
            }
          }
          if (touchesTent) break;
        }
        if (touchesTent) continue;

        final availNeighbors = <Point<int>>[];
        final dirs = [
          Point(-1, 0),
          Point(1, 0),
          Point(0, -1),
          Point(0, 1),
        ];
        dirs.shuffle(subRandom);

        for (final d in dirs) {
          final nr = r + d.x;
          final nc = c + d.y;
          if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
            if (!trees[nr][nc] && !solutionTents[nr][nc]) {
              availNeighbors.add(Point(nr, nc));
            }
          }
        }

        if (availNeighbors.isEmpty) continue;

        final treeCell = availNeighbors.first;
        solutionTents[r][c] = true;
        trees[treeCell.x][treeCell.y] = true;
        placedCount++;
      }

      if (placedCount >= (gridSize <= 6 ? 3 : 5)) {
        final rowTentCounts = List<int>.filled(gridSize, 0);
        final colTentCounts = List<int>.filled(gridSize, 0);

        for (int r = 0; r < gridSize; r++) {
          for (int c = 0; c < gridSize; c++) {
            if (solutionTents[r][c]) {
              rowTentCounts[r]++;
              colTentCounts[c]++;
            }
          }
        }

        return GameLevel(
          levelNumber: levelNumber,
          gridSize: gridSize,
          trees: trees,
          rowTentCounts: rowTentCounts,
          colTentCounts: colTentCounts,
          solutionTents: solutionTents,
        );
      }
    }

    final fallbackTrees = List.generate(gridSize, (_) => List<bool>.filled(gridSize, false));
    final fallbackTents = List.generate(gridSize, (_) => List<bool>.filled(gridSize, false));
    fallbackTents[0][0] = true;
    fallbackTrees[0][1] = true;

    final rowCounts = List<int>.filled(gridSize, 0);
    final colCounts = List<int>.filled(gridSize, 0);
    rowCounts[0] = 1;
    colCounts[0] = 1;

    return GameLevel(
      levelNumber: levelNumber,
      gridSize: gridSize,
      trees: fallbackTrees,
      rowTentCounts: rowCounts,
      colTentCounts: colCounts,
      solutionTents: fallbackTents,
    );
  }
}
