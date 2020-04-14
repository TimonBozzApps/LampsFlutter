import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lamps3/game.dart';
import 'package:lamps3/theme.dart';
import 'package:vibration/vibration.dart';

import 'gamewidget.dart';
import 'aigame.dart';

class LocalGameRoute extends StatefulWidget{
  LocalGame localGame;
  LocalGameRoute(this.localGame);

  @override
  State<StatefulWidget> createState() {
    return LocalGameRouteState(localGame.gameState.value);
  }
}

class LocalGameRouteState extends State<LocalGameRoute>{
  bool winDialogShown = false;
  GameState gameState;

  LocalGameRouteState(this.gameState);

  @override
  void initState() {
    super.initState();
    widget.localGame.gameState.listen((game) {
      if (game.playersStillInTheGame.length == 1 &&
          game.movesMade > game.players.length &&
          !winDialogShown){
        String winner = game.playersStillInTheGame[0];
        winDialogShown = true;
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => LocalWinDialog(game.players.indexOf(winner))
        ).then((value) => Navigator.pop(context, value));
      }
      if (game.exploadingTiles.length > 0)
        Vibration.vibrate(duration: 50);
      if (!game.currentPlayer.startsWith("&&AI&&") && game.exploadingTiles.length == 0)
        Vibration.vibrate(duration: 150);
      setState(() {
        this.gameState = game;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) => RotatedBox(
            child: Row(
              children: <Widget>[
                Expanded(
                    child: _mainBoard
                ),
                Center(
                  child: _turnDisplay(orientation)
                )
              ],
            ),
          quarterTurns: orientation == Orientation.portrait ? 1 : 0,
        ),
      ),
    );
  }

  Widget get _mainBoard => Container(
    margin: EdgeInsets.all(12),
    child: Center(
      child: AspectRatio(
        aspectRatio: gameState.sizeX/gameState.sizeY,
        child: Card(
          child: Center(
            child: GameWidget(widget.localGame),
          ),
        ),
      ),
    ),
  );

  Widget _turnDisplay(Orientation orientation) {
    int playerCount = gameState.playersStillInTheGame.length;
    if (gameState.movesMade < gameState.players.length)
      playerCount = gameState.players.length;
    return Container(
      //width: 48,
      margin: EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        verticalDirection: orientation == Orientation.portrait
            ? VerticalDirection.up : VerticalDirection.up, //because ltr when rotated
        children: List.generate(playerCount, (index) {
          if (gameState.movesMade >= gameState.players.length)
            index = gameState.players.indexOf(gameState.playersStillInTheGame[index]);
          bool humanPlayer = !gameState.players[index].startsWith("&&AI&&");
          bool currentPlayer = gameState.players[index] == gameState.currentPlayer;
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              color: currentPlayer ? Theme.of(context).cardColor : Colors.transparent
            ),
            child: _playerCircle(index, currentPlayer, humanPlayer),
          );
        }),
      ),
    );
  }

  Widget _playerCircle(int index, bool currentPlayer, bool humanPlayer){
    return Container(
        margin: EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
              CircleAvatar(
                backgroundColor: humanPlayer ? isabelline : Colors.transparent,
                radius: 16,
              ),
            CircleAvatar(
              backgroundColor: BoardPainter.playerColors[index],
              radius: 12,
            ),
          ],
        )
    );
  }

}
class LocalWinDialog extends StatelessWidget{
  int winnerIndex;
  LocalWinDialog(this.winnerIndex);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Player ${winnerIndex+1} is the Champion"),
      content: CircleAvatar(
        backgroundColor: BoardPainter.playerColors[winnerIndex],
        radius: 12,
      ),
      actions: <Widget>[
        RaisedButton(
          elevation: 0,
            onPressed: Navigator.of(context).pop,
          child: Text("Back to home"),
        )
      ],
    );
  }

}