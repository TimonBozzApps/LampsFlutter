/*import 'package:flutter/material.dart';
import 'package:lamps3/game.dart';

import 'gamewidget.dart';
import 'aigame.dart';

class LocalGameRoute extends StatefulWidget{
  LocalGame2 localGame;
  LocalGameRoute(this.localGame);

  @override
  State<StatefulWidget> createState() {
    return LocalGameRouteState();
  }
}

class LocalGameRouteState extends State<LocalGameRoute>{
  bool winDialogShown = false;

  LocalGameRouteState();

  @override
  void initState() {
    super.initState();
    widget.localGame.game.listen((game) {
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
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          Flexible(
            flex: 80,
            child: _mainBoard,
          ),
          Flexible(
            flex: 20,
            child: _playersList,
          )
        ],
      ),
    );
  }

  Widget get _mainBoard => Container(
    margin: EdgeInsets.all(12),
    child: Center(
      child: AspectRatio(
        aspectRatio: widget.localGame.sizeX/widget.localGame.sizeY,
        child: Card(
          child: Center(
            child: GameWidget(widget.localGame),
          ),
        ),
      ),
    ),
  );

  Widget get _playersList => Container(
    decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black,
              blurRadius: 8,
              spreadRadius: -4
          )
        ]
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.only(top: 16),
            itemCount: widget.localGame.players.length,
            itemBuilder: (context, index) {
              var color = Colors.white;
              if (widget.localGame.players.indexOf(widget.localGame.currentPlayer) == index)
                color = Colors.grey.shade100;
              var title = "${widget.localGame.playerOwnedTiles[index].length} tiles";
              if (widget.localGame.movesMade > widget.localGame.players.length
                  && widget.localGame.playerOwnedTiles[index].length == 0)
                title = "Game over";
              return Container(
                color: color,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: BoardPainter.playerColors[index],
                    radius: 12,
                  ),
                  title: Text(title),
                ),
              );
            }
        ),
      ],
    ),
  );
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

}*/