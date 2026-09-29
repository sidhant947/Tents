import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:tents/ui/core/theme/app_colors.dart';
import 'package:tents/ui/core/widgets/tangible_button.dart';
import 'package:tents/ui/core/widgets/tents_widgets.dart';
import 'package:tents/ui/features/game/view_models/game_view_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tents/ui/providers.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({
    super.key,
    required this.levelNumber,
    this.isRandom = false,
    this.randomDifficulty = 'Easy',
  });

  final int levelNumber;
  final bool isRandom;
  final String randomDifficulty;

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView> {
  CellState? _dragTargetState;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      if (widget.isRandom) {
        ref.read(gameViewModelProvider.notifier).loadRandomLevel(widget.randomDifficulty);
      } else {
        ref.read(gameViewModelProvider.notifier).loadLevel(widget.levelNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final state = ref.watch(gameViewModelProvider);
    AppColors.currentTheme = settings.theme;

    ref.listen<GameViewModelState>(gameViewModelProvider, (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        _onLevelComplete(next);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        iconSize: 18,
                        onTap: () => Navigator.pop(context),
                      ),
                      Text(
                        state.isRandomMode
                            ? '${state.level?.gridSize ?? state.randomGridSize ?? 5}x${state.level?.gridSize ?? state.randomGridSize ?? 5}'
                            : 'Level ${widget.levelNumber}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headingDark,
                        ),
                      ),
                      _circleButton(
                        icon: Icons.refresh_rounded,
                        iconSize: 20,
                        onTap: () => ref
                            .read(gameViewModelProvider.notifier)
                            .resetLevel(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.error != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(state.error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => ref
                                        .read(gameViewModelProvider.notifier)
                                        .resetLevel(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _buildGame(state),
                ),
              ],
            ),
            ConfettiExplosion(trigger: state.isComplete),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(GameViewModelState state) {
    final settings = ref.watch(settingsProvider);
    final level = state.level;
    if (level == null) return const SizedBox.shrink();

    int tentCount = 0;
    for (int r = 0; r < level.gridSize; r++) {
      for (int c = 0; c < level.gridSize; c++) {
        if (state.board[r][c] == CellState.tent) {
          tentCount++;
        }
      }
    }

    final N = level.gridSize;

    final colTentsCurrent = List<int>.filled(N, 0);
    final rowTentsCurrent = List<int>.filled(N, 0);
    for (int r = 0; r < N; r++) {
      for (int c = 0; c < N; c++) {
        if (state.board[r][c] == CellState.tent) {
          rowTentsCurrent[r]++;
          colTentsCurrent[c]++;
        }
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('Moves', '${state.moveCount}', Icons.trending_up_rounded),
              _verticalDivider(),
              _stat('Time', _formatTime(state.elapsedSeconds), Icons.timer_outlined),
              _verticalDivider(),
              _stat('Tents', '$tentCount/${level.totalTrees}', Icons.cabin_rounded),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: LayoutBuilder(
                  builder: (context, outerConstraints) {
                    final headerSize = 28.0;
                    final gridWidth = outerConstraints.maxWidth - headerSize;
                    final gridHeight = outerConstraints.maxHeight - headerSize;
                    final sideLength = math.min(gridWidth, gridHeight);

                    return SizedBox(
                      width: sideLength + headerSize,
                      height: sideLength + headerSize,
                      child: Column(
                        children: [
                          SizedBox(
                            height: headerSize,
                            child: Row(
                              children: [
                                SizedBox(width: headerSize),
                                SizedBox(
                                  width: sideLength,
                                  child: Row(
                                    children: List.generate(N, (c) {
                                      final target = level.colTentCounts[c];
                                      return Expanded(
                                        child: Center(
                                          child: Text(
                                            '$target',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.headingDark,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: headerSize,
                                  height: sideLength,
                                  child: Column(
                                    children: List.generate(N, (r) {
                                      final target = level.rowTentCounts[r];
                                      return Expanded(
                                        child: Center(
                                          child: Text(
                                            '$target',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.headingDark,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                SizedBox(
                                  width: sideLength,
                                  height: sideLength,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return GestureDetector(
                                        onPanStart: (details) {
                                          _handlePan(details.localPosition, constraints, N, isStart: true);
                                        },
                                        onPanUpdate: (details) {
                                          _handlePan(details.localPosition, constraints, N, isStart: false);
                                        },
                                        onPanEnd: (details) {
                                          _dragTargetState = null;
                                        },
                                        child: Column(
                                          children: List.generate(N, (r) {
                                            return Expanded(
                                              child: Row(
                                                children: List.generate(N, (c) {
                                                  final cellState = state.board[r][c];
                                                  final isTree = level.trees[r][c];
                                                  final isHinted = state.hintCell == r * N + c;

                                                  return Expanded(
                                                    child: TentsCell(
                                                      cellState: cellState,
                                                      isTree: isTree,
                                                      isHinted: isHinted,
                                                      onTap: () {
                                                        ref.read(gameViewModelProvider.notifier).toggleCell(r, c);
                                                      },
                                                      onLongPress: () {
                                                        ref.read(gameViewModelProvider.notifier).toggleCross(r, c);
                                                      },
                                                    ),
                                                  );
                                                }),
                                              ),
                                            );
                                          }),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (state.isComplete)
          _buildCompletionBottomBar(state)
        else ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: (state.canUndo && !state.isComplete)
                    ? () {
                        HapticFeedback.lightImpact();
                        ref.read(gameViewModelProvider.notifier).undo();
                      }
                    : null,
                child: Opacity(
                  opacity: (state.canUndo && !state.isComplete) ? 1.0 : 0.35,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (state.canUndo && !state.isComplete)
                            ? AppColors.border
                            : AppColors.border.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.headingDark.withValues(alpha: 0.08),
                          offset: const Offset(0, 3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.undo_rounded,
                          color: AppColors.headingDark,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Undo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.headingDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (settings.isHintEnabled) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: (state.hintsRemaining > 0 && !state.isComplete)
                      ? () => ref.read(gameViewModelProvider.notifier).revealHint()
                      : null,
                  child: Opacity(
                    opacity: (state.hintsRemaining > 0 && !state.isComplete) ? 1.0 : 0.35,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: state.hintsRemaining > 0
                              ? AppColors.border
                              : AppColors.border.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.headingDark.withValues(alpha: 0.08),
                            offset: const Offset(0, 3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: Color(0xFFFFCC00),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hint (${state.hintsRemaining}/2)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.headingDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: settings.isCheckButtonEnabled ? 10 : 16),
            child: Text(
              'Tap: Tent  |  Long press: Cross',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.subtext,
              ),
            ),
          ),
          if (settings.isCheckButtonEnabled) ...[
            GestureDetector(
              onTap: !state.isComplete
                  ? () {
                      HapticFeedback.lightImpact();
                      final solved = ref.read(gameViewModelProvider.notifier).checkSolution();
                      if (!solved) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Not solved yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.headingDark,
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppColors.border, width: 1.0),
                            ),
                            backgroundColor: AppColors.surface,
                          ),
                        );
                      }
                    }
                  : null,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'Check Solution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  void _handlePan(Offset localPosition, BoxConstraints constraints, int N, {bool isStart = false}) {
    final cellWidth = constraints.maxWidth / N;
    final cellHeight = constraints.maxHeight / N;

    final c = (localPosition.dx / cellWidth).floor();
    final r = (localPosition.dy / cellHeight).floor();

    if (r >= 0 && r < N && c >= 0 && c < N) {
      final stateProvider = ref.read(gameViewModelProvider);
      final level = stateProvider.level;
      if (level != null && level.trees[r][c]) return;

      final current = stateProvider.board[r][c];

      if (isStart) {
        if (current == CellState.empty || current == CellState.x) {
          _dragTargetState = CellState.tent;
        } else if (current == CellState.tent) {
          _dragTargetState = CellState.empty;
        } else {
          _dragTargetState = null;
        }
      }

      if (_dragTargetState != null && current != _dragTargetState) {
        if (current == CellState.tree) return;
        ref.read(gameViewModelProvider.notifier).setCellState(r, c, _dragTargetState!);
      }
    }
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 20,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? () {
        HapticFeedback.selectionClick();
        onTap();
      } : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.headingDark.withValues(alpha: 0.08),
                offset: const Offset(0, 3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: AppColors.headingDark,
          ),
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.headingDark,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.headingDark,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.subtext,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.gridLines,
    );
  }

  Future<void> _onLevelComplete(GameViewModelState state) async {
    await ref.read(gameViewModelProvider.notifier).completeLevel();
  }

  Widget _buildCompletionBottomBar(GameViewModelState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Congratulations!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.headingDark,
            ),
          ),
          const SizedBox(height: 10),
          TangibleButton(
            text: state.isRandomMode ? 'Play Again' : 'Next Level',
            height: 42,
            backgroundColor: AppColors.primary,
            textColor: AppColors.headingDark,
            borderColor: AppColors.border,
            onPressed: () {
              final notifier = ref.read(gameViewModelProvider.notifier);
              if (state.isRandomMode) {
                notifier.loadRandomLevel(state.randomDifficulty ?? 'Easy');
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameView(levelNumber: widget.levelNumber + 1),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          TangibleButton(
            text: 'Home',
            isSecondary: true,
            height: 42,
            backgroundColor: AppColors.surface,
            textColor: AppColors.headingDark,
            borderColor: AppColors.border,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
          TangibleButton(
            text: 'Buy Me a Coffee',
            isSecondary: true,
            height: 42,
            backgroundColor: AppColors.surface,
            textColor: AppColors.headingDark,
            borderColor: AppColors.border,
            onPressed: _openKoFiUrl,
          ),
        ],
      ),
    );
  }

  Future<void> _openKoFiUrl() async {
    final Uri uri = Uri.parse('https://ko-fi.com/sidhant947');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}
    }
  }
}

class TentsCell extends ConsumerStatefulWidget {
  const TentsCell({
    super.key,
    required this.cellState,
    required this.isTree,
    required this.isHinted,
    required this.onTap,
    required this.onLongPress,
  });

  final CellState cellState;
  final bool isTree;
  final bool isHinted;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  ConsumerState<TentsCell> createState() => _TentsCellState();
}

class _TentsCellState extends ConsumerState<TentsCell> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    if (widget.cellState != CellState.empty) {
      _controller.value = 1.0;
    }

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant TentsCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cellState != widget.cellState) {
      if (widget.cellState != CellState.empty) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse(from: 1.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isTree ? null : widget.onTap,
      onLongPress: widget.isTree ? null : widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: widget.cellState == CellState.tent
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.headingDark.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = math.min(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: widget.isHinted
                          ? AppColors.accent.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: widget.isHinted
                          ? Border.all(color: AppColors.accent, width: 2.0)
                          : null,
                    ),
                  ),
                ),
                _buildContent(cellSize),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(double cellSize) {
    final pieceSize = (cellSize * 0.72).clamp(16.0, 56.0);

    if (widget.isTree || widget.cellState == CellState.tree) {
      return TreeWidget(
        size: pieceSize,
      );
    } else if (widget.cellState == CellState.tent) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: pieceSize,
                  height: pieceSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: _glowAnimation.value / 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            TentWidget(
              size: pieceSize,
            ),
          ],
        ),
      );
    } else if (widget.cellState == CellState.x) {
      final xSize = (cellSize * 0.55).clamp(14.0, 48.0);
      return ScaleTransition(
        scale: _scaleAnimation,
        child: CrossWidget(
          size: xSize,
          color: AppColors.subtext,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double rotation;
  double rotationSpeed;
  Color color;
  bool isCircle;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.isCircle,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 300.0 * dt;
    vx *= math.pow(0.98, dt * 60);
    vy *= math.pow(0.98, dt * 60);
    rotation += rotationSpeed * dt;
  }
}

class ConfettiExplosion extends StatefulWidget {
  final bool trigger;
  const ConfettiExplosion({super.key, required this.trigger});

  @override
  State<ConfettiExplosion> createState() => _ConfettiExplosionState();
}

class _ConfettiExplosionState extends State<ConfettiExplosion> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(_tick);

    if (widget.trigger) {
      _burst();
    }
  }

  @override
  void didUpdateWidget(covariant ConfettiExplosion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _burst();
    }
  }

  void _burst() {
    _particles.clear();
    final List<Color> colors = [
      Colors.white,
      Colors.white70,
      Colors.white54,
      Colors.white30,
      const Color(0xFF888888),
      const Color(0xFFCCCCCC),
      const Color(0xFF555555),
      const Color(0xFFAAAAAA),
    ];

    for (int i = 0; i < 80; i++) {
      final double angle = _random.nextDouble() * 2 * math.pi;
      final double speed = 150 + _random.nextDouble() * 250;
      _particles.add(ConfettiParticle(
        x: 0.5,
        y: 0.4,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 150,
        size: 6 + _random.nextDouble() * 8,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        color: colors[_random.nextInt(colors.length)],
        isCircle: _random.nextBool(),
      ));
    }
    _controller.forward(from: 0.0);
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      for (final p in _particles) {
        p.update(0.016);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: ConfettiPainter(particles: _particles),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final double px = p.x * size.width;
      final double py = p.y * size.height;

      if (px < 0 || px > size.width || py > size.height) continue;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      final Paint paint = Paint()..color = p.color;

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
