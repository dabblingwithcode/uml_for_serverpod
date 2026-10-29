import 'dart:math' as math;

/// Width and height of a block to place, in points.
class BlockSize {
  final double width;
  final double height;
  const BlockSize(this.width, this.height);

  @override
  String toString() => 'BlockSize($width × $height)';
}

/// Top-left corner of a placed block, in points, y growing downwards.
class BlockOffset {
  final double x;
  final double y;
  const BlockOffset(this.x, this.y);

  @override
  String toString() => 'BlockOffset($x, $y)';
}

/// How blocks share a grid.
enum GridMode {
  /// Each row is packed left to right with each block's own width; the row is
  /// as tall as its tallest block. Dense when block sizes vary.
  rows,

  /// A true grid: every column is as wide as its widest block and every row as
  /// tall as its tallest block. Aligned, but wasteful when sizes vary.
  cells;

  static GridMode parse(String value) => switch (value) {
        'rows' => GridMode.rows,
        'cells' => GridMode.cells,
        _ => throw ArgumentError.value(
            value, 'layout.grid.mode', 'must be rows or cells'),
      };
}

/// The result of placing blocks: one offset per block, in input order, and the
/// overall extent.
class GridPlacement {
  final List<BlockOffset> offsets;
  final int columns;
  final double width;
  final double height;
  const GridPlacement({
    required this.offsets,
    required this.columns,
    required this.width,
    required this.height,
  });

  double get aspectRatio => height == 0 ? 0 : width / height;
}

/// Places [sizes] row-major on a grid with [columns] columns and [gap] points
/// between neighbouring blocks.
GridPlacement placeWithColumns(
  List<BlockSize> sizes, {
  required int columns,
  required double gap,
  GridMode mode = GridMode.rows,
}) {
  if (columns < 1) {
    throw ArgumentError.value(columns, 'columns', 'must be at least 1');
  }
  if (sizes.isEmpty) {
    return const GridPlacement(offsets: [], columns: 0, width: 0, height: 0);
  }
  final cols = math.min(columns, sizes.length);
  final rowCount = (sizes.length / cols).ceil();

  final rowHeights = List<double>.filled(rowCount, 0);
  final colWidths = List<double>.filled(cols, 0);
  for (var i = 0; i < sizes.length; i++) {
    final row = i ~/ cols;
    final col = i % cols;
    rowHeights[row] = math.max(rowHeights[row], sizes[i].height);
    colWidths[col] = math.max(colWidths[col], sizes[i].width);
  }

  final offsets = <BlockOffset>[];
  var y = 0.0;
  var width = 0.0;
  for (var row = 0; row < rowCount; row++) {
    var x = 0.0;
    for (var col = 0; col < cols; col++) {
      final i = row * cols + col;
      if (i >= sizes.length) break;
      offsets.add(BlockOffset(x, y));
      final advance = mode == GridMode.cells ? colWidths[col] : sizes[i].width;
      x += advance + gap;
    }
    width = math.max(width, x - gap);
    y += rowHeights[row] + gap;
  }
  return GridPlacement(
    offsets: offsets,
    columns: cols,
    width: width,
    height: y - gap,
  );
}

/// Places [sizes] row-major choosing the column count whose overall
/// width / height comes closest to [aspectRatio] (1.0 square, 0.6 portrait).
GridPlacement placeWithAspectRatio(
  List<BlockSize> sizes, {
  required double aspectRatio,
  required double gap,
  GridMode mode = GridMode.rows,
}) {
  if (aspectRatio <= 0) {
    throw ArgumentError.value(aspectRatio, 'aspectRatio', 'must be positive');
  }
  if (sizes.isEmpty) {
    return const GridPlacement(offsets: [], columns: 0, width: 0, height: 0);
  }
  GridPlacement? best;
  var bestScore = double.infinity;
  for (var cols = 1; cols <= sizes.length; cols++) {
    final candidate =
        placeWithColumns(sizes, columns: cols, gap: gap, mode: mode);
    final score = (math.log(candidate.aspectRatio / aspectRatio)).abs();
    if (score < bestScore - 1e-9) {
      best = candidate;
      bestScore = score;
    }
  }
  return best!;
}

/// Places [sizes] with explicit [columns] when given, else by [aspectRatio].
GridPlacement placeOnGrid(
  List<BlockSize> sizes, {
  int? columns,
  required double aspectRatio,
  required double gap,
  GridMode mode = GridMode.rows,
}) =>
    columns != null
        ? placeWithColumns(sizes, columns: columns, gap: gap, mode: mode)
        : placeWithAspectRatio(sizes,
            aspectRatio: aspectRatio, gap: gap, mode: mode);
