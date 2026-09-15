import 'package:flutter/material.dart';

@immutable
class GameLevel {
  const GameLevel({
    required this.levelNumber,
    required this.gridSize,
    required this.trees,
    required this.rowTentCounts,
    required this.colTentCounts,
    required this.solutionTents,
  });

  final int levelNumber;
  final int gridSize;
  final List<List<bool>> trees;
  final List<int> rowTentCounts;
  final List<int> colTentCounts;
  final List<List<bool>> solutionTents;

  int get totalTrees {
    int count = 0;
    for (final row in trees) {
      for (final cell in row) {
        if (cell) count++;
      }
    }
    return count;
  }

  GameLevel copyWith({
    int? levelNumber,
    int? gridSize,
    List<List<bool>>? trees,
    List<int>? rowTentCounts,
    List<int>? colTentCounts,
    List<List<bool>>? solutionTents,
  }) {
    return GameLevel(
      levelNumber: levelNumber ?? this.levelNumber,
      gridSize: gridSize ?? this.gridSize,
      trees: trees ?? this.trees,
      rowTentCounts: rowTentCounts ?? this.rowTentCounts,
      colTentCounts: colTentCounts ?? this.colTentCounts,
      solutionTents: solutionTents ?? this.solutionTents,
    );
  }
}
