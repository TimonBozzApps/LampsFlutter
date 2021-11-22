import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lamps3/game.dart';
import 'package:lamps3/theme.dart';

class HEy extends StatefulWidget {
  const HEy({ Key? key }) : super(key: key);

  @override
  _HEyState createState() => _HEyState();
}

class _HEyState extends State<HEy> {
  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}

class GameWidget extends StatefulWidget {
  final LocalGame _game;
  GameWidget(this._game);

  @override
  State<StatefulWidget> createState() {
    return GameWidgetState(_game.gameState.value);
  }
}

class GameWidgetState extends State<GameWidget>
    with SingleTickerProviderStateMixin {
  GameState gameState2;
  GameWidgetState(this.gameState2)
      : _boardPainter = BoardPainter(gameState2, 0);

  BoardPainter _boardPainter;
  Animation _animation;
  AnimationController _controller;
  bool disposed = false;

  double rotationChange = 0;
  final Duration oneFastestRotationDuration = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    widget._game.gameState.listen((event) {
      setState(() {
        gameState2 = event;
        _boardPainter = BoardPainter(gameState2, rotationChange);
      });
    });
    _controller = AnimationController(
        duration: Duration(
            milliseconds: 8 * oneFastestRotationDuration.inMilliseconds),
        vsync: this);

    _controller.forward();

    _controller.addStatusListener((status) {
      if (!disposed && status == AnimationStatus.completed) {
        _controller.reset();
      } else if (!disposed && status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _animation = Tween(begin: 0.0, end: 8 * 2 * pi).animate(_controller)
      ..addListener(() {
        setState(() {
          rotationChange = _animation.value;
          _boardPainter = BoardPainter(gameState2, rotationChange);
        });
      });
    return AspectRatio(
      aspectRatio: gameState2.sizeX / gameState2.sizeY,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: _handleTapUp,
        child: CustomPaint(
          child: Container(),
          foregroundPainter: _boardPainter,
          willChange: true,
        ),
      ),
    );
  }

  void _handleTapUp(TapUpDetails details) {
    final RenderBox referenceBox = context.findRenderObject();
    final Offset tap = referenceBox.globalToLocal(details.globalPosition);
    widget._game.makeMove(_boardPainter.tapX(tap), _boardPainter.tapY(tap));
  }

  @override
  void dispose() {
    disposed = true;
    widget._game.dispose();
    _controller.dispose();
    super.dispose();
  }
}

class BoardPainter extends CustomPainter {
  GameState _gameState;
  double rotationAngle;
  BoardPainter(this._gameState, this.rotationAngle);

  var tileSize;
  var rects = <List<Rect>>[];

  void paint(Canvas canvas, Size size) {
    tileSize = size.height / _gameState.sizeY;

    Paint gridPainter = Paint()
      ..color = isabelline
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    //draw rows
    for (int row = 1; row < _gameState.sizeY; row++) {
      canvas.drawLine(Offset(0, row * tileSize),
          Offset(size.width, row * tileSize), gridPainter);
    }
    //draw columns
    for (int column = 1; column < _gameState.sizeX; column++) {
      canvas.drawLine(Offset(column * tileSize, 0),
          Offset(column * tileSize, size.height), gridPainter);
    }

    List<Paint> playerPainters =
        List.generate(_gameState.playerColors.length, (index) {
      return Paint()
        ..style = PaintingStyle.fill
        ..strokeWidth = 5
        ..color = _gameState.playerColors[index];
    });

    rects.clear();

    //draw circles
    int x = 0;
    _gameState.board.forEach((row) {
      int y = 0;
      List<Rect> rectRow = <Rect>[];
      row.forEach((tile) {
        var rect = Rect.fromPoints(Offset(x * tileSize, y * tileSize),
            Offset((x + 1) * tileSize, (y + 1) * tileSize));
        rectRow.add(rect);
        if (tile.charge > 0) {
          if (tile.charge > tile.maxCharge) {
            //explosion
            final explosionRect = RRect.fromRectAndCorners(
                rect.deflate(tileSize * 0.05),
                topRight: Radius.circular(8),
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8));
            canvas.drawRRect(explosionRect,
                playerPainters[_gameState.players.indexOf(tile.owner)]);
          } else {
            //circles
            var chargeDiff = tile.maxCharge - tile.charge;
            if (tile.charge >= 1)
              canvas.drawCircle(
                  Offset(_calculateX(0, rect.center.dx, chargeDiff),
                      _calculateY(0, rect.center.dy, chargeDiff)),
                  circleRadius,
                  playerPainters[_gameState.players.indexOf(tile.owner)]);
            if (tile.charge == 2)
              canvas.drawCircle(
                  Offset(_calculateX(pi, rect.center.dx, chargeDiff),
                      _calculateY(pi, rect.center.dy, chargeDiff)),
                  circleRadius,
                  playerPainters[_gameState.players.indexOf(tile.owner)]);
            if (tile.charge == 3) {
              canvas.drawCircle(
                  Offset(_calculateX(2 * pi / 3, rect.center.dx, chargeDiff),
                      _calculateY(2 * pi / 3, rect.center.dy, chargeDiff)),
                  circleRadius,
                  playerPainters[_gameState.players.indexOf(tile.owner)]);
              canvas.drawCircle(
                  Offset(
                      _calculateX(2 * pi / 3 * 2, rect.center.dx, chargeDiff),
                      _calculateY(2 * pi / 3 * 2, rect.center.dy, chargeDiff)),
                  circleRadius,
                  playerPainters[_gameState.players.indexOf(tile.owner)]);
            }
          }
        }
        y++;
      });
      rects.add(rectRow);
      x++;
    });

    //draw outside lines in current players color
    //canvas.drawLine(Offset(0, 0), Offset(size.width, 0), playerPainters[_gameState.players.indexOf(_gameState.currentPlayer)]);
    //canvas.drawLine(Offset(0, 0), Offset(0, size.height), playerPainters[_gameState.players.indexOf(_gameState.currentPlayer)]);
    //canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), playerPainters[_gameState.players.indexOf(_gameState.currentPlayer)]);
    //canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), playerPainters[_gameState.players.indexOf(_gameState.currentPlayer)]);
  }

  double get alignCircleRadius => tileSize / 4;
  double get circleRadius => tileSize / 5;
  double _calculateX(double rotationOffset, double originalX, int chargeDiff) {
    if (chargeDiff == 0)
      return originalX +
          cos(rotationAngle + rotationOffset) * alignCircleRadius;
    if (chargeDiff == 1)
      return originalX +
          cos(rotationAngle / 2 + rotationOffset) * alignCircleRadius;
    if (chargeDiff == 2)
      return originalX +
          cos(rotationAngle / 8 + rotationOffset) * alignCircleRadius;
    return originalX;
  }

  double _calculateY(double rotationOffset, double originalY, int chargeDiff) {
    if (chargeDiff == 0)
      return originalY +
          sin(rotationAngle + rotationOffset) * alignCircleRadius;
    if (chargeDiff == 1)
      return originalY +
          sin(rotationAngle / 2 + rotationOffset) * alignCircleRadius;
    if (chargeDiff == 2)
      return originalY +
          sin(rotationAngle / 8 + rotationOffset) * alignCircleRadius;
    return originalY;
  }

  int tapX(Offset position) {
    int tapX = -1;
    int tapY = -1;
    outer:
    for (int x = 0; x < rects.length; x++) {
      for (int y = 0; y < rects[x].length; y++) {
        if (rects[x][y].contains(position)) {
          tapX = x;
          tapY = y;
          break outer;
        }
      }
    }
    if (tapX == -1 || tapY == -1) return null;
    return tapX;
  }

  int tapY(Offset position) {
    int tapX = -1;
    int tapY = -1;
    outer:
    for (int x = 0; x < rects.length; x++) {
      for (int y = 0; y < rects[x].length; y++) {
        if (rects[x][y].contains(position)) {
          tapX = x;
          tapY = y;
          break outer;
        }
      }
    }
    if (tapX == -1 || tapY == -1) return null;
    return tapY;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
