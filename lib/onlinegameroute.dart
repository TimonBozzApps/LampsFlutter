import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lamps3/game.dart';
import 'package:lamps3/gamewidget.dart';
import 'package:lamps3/online.dart';

class OnlineGameRoute extends StatefulWidget{
  OnlineApi onlineApi;
  OnlineGame onlineGame;
  OnlineGameRoute(this.onlineApi, this.onlineGame);

  @override
  State<StatefulWidget> createState() {
    return OnlineGameRouteState(onlineGame);
  }
}

class OnlineGameRouteState extends State<OnlineGameRoute>{
  OnlineGame _onlineGame;
  MultiplayerGame _multiplayerGame;
  bool winDialogShown = false;
  GameState gameState;

  OnlineGameRouteState(this._onlineGame);

  @override
  void initState() {
    super.initState();
    widget.onlineApi.onlineGame.listen((event) {
      if (event == null) {
        Navigator.pop(context);
      }
      if (event.state == 1) {
        _multiplayerGame = MultiplayerGame(widget.onlineApi, _onlineGame);
        _multiplayerGame.gameState.listen((gameState) {
          if (gameState.playersStillInTheGame.length == 1 &&
              gameState.movesMade > gameState.players.length &&
              !winDialogShown){
            String winner = gameState.playersStillInTheGame[0];
            winDialogShown = true;
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => OnlineWinDialog(winner, widget.onlineApi, _onlineGame)
            ).then((value) => Navigator.pop(context, value));
          }
          setState(() {
            this.gameState = gameState;
          });
        });
      }
      setState(() {
        _onlineGame = event;
        if (_multiplayerGame != null)
          this.gameState = _multiplayerGame.gameState.value;
      });
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
        aspectRatio: _onlineGame.sizeX/_onlineGame.sizeY,
        child: Card(
          child: Center(
            child: _mainBoardContent(),
          ),
        ),
      ),
    ),
  );
  Widget _mainBoardContent() {
    if (_onlineGame.state == 1 && _multiplayerGame != null) {
      return GameWidget(_multiplayerGame);
    }
    return SelectableText(
      "${_onlineGame.gameId}",
      toolbarOptions: ToolbarOptions(copy: true),
      style: TextStyle(
        fontSize: 36,
        letterSpacing: 8,
        fontWeight: FontWeight.bold,
      ),
    );
  }

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
        Expanded(
          child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(top: 16),
              itemCount: _onlineGame.players.length,
              itemBuilder: (context, index) {
                var color = Colors.white;
                if (_multiplayerGame != null && gameState.players.indexOf(gameState.currentPlayer) == index)
                  color = Colors.grey.shade100;
                var subtitle = "";
                if (_multiplayerGame != null) {
                  subtitle = "${gameState.playerOwnedTiles[index].length} tiles";
                  if (gameState.movesMade > gameState.players.length
                      && gameState.playerOwnedTiles[index].length == 0)
                    subtitle = "Game over";
                }
                var fontWeight = FontWeight.normal;
                if (_onlineGame.players.indexOf(widget.onlineApi.playerName) == index)
                  fontWeight = FontWeight.bold;
                return Container(
                  color: color,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: BoardPainter.playerColors[index],
                      radius: 12,
                    ),
                    title: Text(_onlineGame.players[index], style: TextStyle(fontWeight: fontWeight),),
                    subtitle: Text(subtitle),
                  ),
                );
              }
          ),
        ),
        if (_onlineGame.players.length > 1
            && _onlineGame.players.indexOf(widget.onlineApi.playerName) == 0
            && _onlineGame.state == 0)
          Container(
            margin: EdgeInsets.all(16),
            child: RaisedButton(
                child: Text("Start Game"),
                elevation: 0,
                color: Colors.amber,
                onPressed: () {
                  widget.onlineApi.startGame(_onlineGame.gameId);
                }
            ),
          ),
        Container(
          margin: EdgeInsets.all(16),
          child: RaisedButton(
              child: Text("Leave Game"),
              elevation: 0,
              color: Colors.red,
              onPressed: () {
                showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => AlertDialog(
                      title: Text("Confirm to leave"),
                      content: Text("You will not be able to return"),
                      actions: <Widget>[
                        RaisedButton(
                          color: Colors.red,
                            elevation: 0,
                            child: Text("Leave the game"),
                            onPressed: () {
                              Navigator.pop(context, true);
                            }
                        )
                      ],
                    )
                ).then((value) async{
                  if (value == true) {
                    await widget.onlineApi.leaveGame();
                    Navigator.pop(context, null);
                  }
                });
              }
          ),
        )
      ],
    ),
  );
}

class OnlineWinDialog extends StatefulWidget{
  String winner;
  OnlineApi onlineApi;
  OnlineGame onlineGame;
  OnlineWinDialog(this.winner, this.onlineApi, this.onlineGame);

  @override
  State<StatefulWidget> createState() {
    return OnlineWinDialogState(onlineGame);
  }
}
class OnlineWinDialogState extends State<OnlineWinDialog>{
  OnlineGame _onlineGame;

  OnlineWinDialogState(this._onlineGame);

  @override
  void initState() {
    super.initState();
    widget.onlineApi.onlineGame.listen((event) {
      setState(() {
        _onlineGame = event;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("${widget.winner} is the Champion!"),
      actions: <Widget>[
        RaisedButton(
            child: Text("Leave"),
            elevation: 0,
            onPressed: Navigator.of(context).pop
        ),
        if (_onlineGame.players.indexOf(widget.onlineApi.playerName) == 0 && _onlineGame.rematchGame == null)
          RaisedButton(
            elevation: 0,
            color: Colors.green,
            child: Text("Create rematch"),
            onPressed: () async{
              String rematchGameId = await widget.onlineApi.createRematchGame();
              Navigator.pop(context, rematchGameId);
            },
          )
        else if (_onlineGame.rematchGame != null)
          RaisedButton(
            elevation: 0,
            color: Colors.green,
            child: Text("Join rematch"),
            onPressed: () async{
              String rematchGameId = await widget.onlineApi.joinRematchGame();
              Navigator.pop(context, rematchGameId);
            },
          )
      ],
    );
  }

}