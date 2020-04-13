import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:lamps3/online.dart';
import 'package:rxdart/rxdart.dart';
import 'aigame.dart';

class Tile {
  String owner;
  int charge;
  int maxCharge;
  int posX;
  int posY;
  Tile(this.owner, this.charge, this.maxCharge, this.posX, this.posY);
}
class Move {
  int posX;
  int posY;
  String player;
  Move(this.posX, this.posY, this.player);
}

class GameState {
  final int sizeX;
  final int sizeY;
  final List<String> players;

  List<List<Tile>> board;
  List<Tile> exploadingTiles;

  String currentPlayer;
  int movesMade;

  GameState(this.sizeX, this.sizeY, this.players){
    board = List.generate(sizeX, (x) => List.generate(sizeY, (y) {
      int maxCharge = 3;
      if (x == 0 || x == sizeX-1)
        maxCharge--;
      if (y == 0 || y == sizeY-1)
        maxCharge--;
      return Tile("", 0, maxCharge, x, y);
    }));
    exploadingTiles = List<Tile>();
    currentPlayer = players[0];
    movesMade = 0;
  }
  GameState.fromPreviousVersionAndBoard(GameState gameState2, this.board):
        sizeX = gameState2.sizeX,
        sizeY = gameState2.sizeY,
        players = gameState2.players,
        exploadingTiles = gameState2.exploadingTiles,
        currentPlayer = gameState2.currentPlayer,
        movesMade = gameState2.movesMade;
  GameState.fromPreviousVersionAndExploadingTiles(GameState gameState2, this.exploadingTiles):
        sizeX = gameState2.sizeX,
        sizeY = gameState2.sizeY,
        players = gameState2.players,
        board = gameState2.board,
        currentPlayer = gameState2.currentPlayer,
        movesMade = gameState2.movesMade;

  List<List<Tile>> get playerOwnedTiles {
    var playerOwnedTiles = List<List<Tile>>.generate(players.length, (index) => List<Tile>());
    for (List<Tile> tiles in board)
      for (Tile tile in tiles)
        if (tile.owner != "") {
          playerOwnedTiles[players.indexOf(tile.owner)].add(tile);
        }
    return playerOwnedTiles;
  }
  List<String> get playersStillInTheGame =>
      playerOwnedTiles.where((element) => element.length > 0).map((e) => e[0].owner).toList();

  bool get isTerminated => movesMade > players.length && playersStillInTheGame.length < 2;

  int evaluate(int player){
    int value = 0;
    for (List<Tile> tiles in board) {
      for (Tile tile in tiles) {
        if (tile.charge == 0)
          continue;
        int tileValue = tile.charge + 1;
        if (tile.posX == 0 || tile.posX == 4)
          tileValue*2;
        if (tile.posY == 0 || tile.posY == 4)
          tileValue*2;
        if (tile.owner == player.toString())
          value += tileValue;
        else
          value -= tileValue;
      }
    }
    return value;
  }
}
class Game {
  bool _readyForNextMove = true;
  Duration _animationDuration = Duration(milliseconds: 300);
  BehaviorSubject<GameState> _gameState = BehaviorSubject(); //var

  ValueStream<GameState> get gameState => _gameState.stream;

  Game(GameState gameState2, this._animationDuration){
    _gameState.add(gameState2);
  }

  //returns whether move was made
  bool _makeMove(Move move, bool animate){
    if (!makeMoveCheck(move))
      return false;
    _gameState.value.board[move.posX][move.posY].charge++;
    _gameState.value.board[move.posX][move.posY].owner = move.player;
    _gameState.value.movesMade++;
    Future.sync(() => _updateBoard(animate));
    return true;
  }
  bool makeMoveCheck(Move move){
    if (!_readyForNextMove)
      return false;
    if (!_gameState.value.players.contains(move.player)) {
      return false; //player is already out
    }
    if (_gameState.value.currentPlayer != move.player) {
      return false; //not player's turn
    }
    if (_gameState.value.board[move.posX][move.posY].owner != "" && //ok if no one owns it
        _gameState.value.board[move.posX][move.posY].owner != move.player) {
      return false; //not player's tile
    }
    return true;
  }

  void _updateBoard(bool animate) async{
    _readyForNextMove = false;
    List<List<Tile>> newBoard = List.generate(_gameState.value.sizeX, (x) => List.generate(_gameState.value.sizeY, (y) {
      int maxCharge = 3;
      if (x == 0 || x == _gameState.value.sizeX-1)
        maxCharge--;
      if (y == 0 || y == _gameState.value.sizeY-1)
        maxCharge--;
      return Tile("", 0, maxCharge, x, y);
    }));
    List<Tile> exploadedTiles = List<Tile>();
    _gameState.value.board.forEach((row) {
      row.forEach((tile) {
        if (tile.charge > tile.maxCharge) {
          //explode
          exploadedTiles.add(tile);
          if (tile.posX - 1 >= 0) {
            newBoard[tile.posX - 1][tile.posY].charge++;
            newBoard[tile.posX - 1][tile.posY].owner = tile.owner;
          } if (tile.posY - 1 >= 0) {
            newBoard[tile.posX][tile.posY - 1].charge++;
            newBoard[tile.posX][tile.posY - 1].owner = tile.owner;
          } if (tile.posX + 1 < _gameState.value.sizeX) {
            newBoard[tile.posX + 1][tile.posY].charge++;
            newBoard[tile.posX + 1][tile.posY].owner = tile.owner;
          } if (tile.posY + 1 < _gameState.value.sizeY) {
            newBoard[tile.posX][tile.posY + 1].charge++;
            newBoard[tile.posX][tile.posY + 1].owner = tile.owner;
          }
        }else{
          //don't explode, just add charges
          newBoard[tile.posX][tile.posY].charge += tile.charge;
          if (newBoard[tile.posX][tile.posY].owner == "") //because explosions obtain tiles
            newBoard[tile.posX][tile.posY].owner = tile.owner;
        }
      });
    });

    if (exploadedTiles.isNotEmpty) {
      if (animate){
        _gameState.add(GameState.fromPreviousVersionAndExploadingTiles(_gameState.value, exploadedTiles));
        await Future.delayed(_animationDuration, () {
          return _gameState.add(GameState.fromPreviousVersionAndBoard(_gameState.value, newBoard));
        });
      }else {
        _gameState.value.exploadingTiles = exploadedTiles;
        _gameState.add(GameState.fromPreviousVersionAndBoard(_gameState.value, newBoard));
      }
      _updateBoard(animate);  //recurse
    }else {
      //find next player
      bool isCurrentPlayerOwningTile = _gameState.value.movesMade < _gameState.value.players.length; //because in the first round nobody owns a tile
      do {
        int nextPlayerIndex = _gameState.value.players.indexOf(_gameState.value.currentPlayer) + 1;
        if (nextPlayerIndex >= _gameState.value.players.length)
          nextPlayerIndex = 0;
        _gameState.value.currentPlayer = _gameState.value.players[nextPlayerIndex];
        //find if current player still has tiles
        if (_gameState.value.playerOwnedTiles[nextPlayerIndex].length > 0)
          isCurrentPlayerOwningTile = true; //can't set it to false because of initial condition (^see above^)
      } while  (!isCurrentPlayerOwningTile);
      _gameState.value.exploadingTiles = exploadedTiles;
      _gameState.add(GameState.fromPreviousVersionAndBoard(_gameState.value, newBoard));
      _readyForNextMove = true;
    }
  }

  void printGame(){
    print("------------------------");
    var board = _gameState.value.board;
    for (List<Tile> row in board){
      String rowString = "";
      for (Tile tile in row)
        rowString += tile.charge.toString();
      print(rowString);
    }
  }

  void dispose(){
    _gameState.close();
  }
}
class LocalGame extends Game{
  LocalGame(GameState gameState) : super(gameState, Duration(milliseconds: 400));

  bool makeMove(int posX, int posY){
    return _makeMove(Move(posX, posY, gameState.value.currentPlayer), true);
  }
}

class MultiplayerGame extends Game implements LocalGame{
  OnlineApi _onlineApi;

  MultiplayerGame(this._onlineApi, OnlineGame onlineGame)
      : super(GameState(onlineGame.sizeX, onlineGame.sizeY, onlineGame.players),
      Duration(milliseconds: 400)){
    _onlineApi.newMoves.listen((newMoves) {
      //new move
      newMoves.forEach((element) {
        queueMove(element);
      });
    });
  }

  ValueStream<OnlineGame> get onlineGame => _onlineApi.onlineGame;

  bool makeMove(int posX, int posY){
    if (makeMoveCheck(Move(posX, posY, _onlineApi.playerName))) {
      _onlineApi.makeMove(Move(posX, posY, _onlineApi.playerName));
      return true;
    }
    return false;
  }

  void dispose(){
    super.dispose();
    _onlineApi.dispose();
  }

  List<Move> moveQueue = List<Move>();
  void queueMove(Move move){
    if (_readyForNextMove)
      moveQueue.add(move);
    else
      _makeMove(move, true);
  }
  void boardUpdate(List<List<Tile>> newBoard){
    if (_readyForNextMove && moveQueue.isNotEmpty){
      _makeMove(moveQueue[0], true);
      moveQueue.removeAt(0);
    }
  }
}

class LocalAiGame extends Game implements LocalGame{
  Agent agent;
  bool simulateOnline;

  LocalAiGame(GameState gameState, this.agent, this.simulateOnline)
      : super(gameState, Duration(milliseconds: 200)){
    if (gameState.currentPlayer.startsWith("&&AI&&"))
      doUiTurn(gameState);
  }

  StreamSubscription aiSub;
  bool makeMove(int posX, int posY){ //used for the human input
    if (gameState.value.currentPlayer.startsWith("&&AI&&"))
      return false;
    return _makeMoveAndStartAi(posX, posY);
  }
  bool _makeMoveAndStartAi(int posX, int posY){
    final result = _makeMove(Move(posX, posY, gameState.value.currentPlayer), true);
    if (!result)
      return result;
    if (aiSub != null)
      aiSub.cancel();
    aiSub = gameState.listen((event) async{ //to wait for animations to be done
      if (_readyForNextMove){
        aiSub.cancel();
        if (!event.currentPlayer.startsWith("&&AI&&") || event.isTerminated) //not ai's turn
          return;
        //let ai think
        doUiTurn(event);
      }
    });
    return result;
  }

  List<int> onlineDelays = {
    100,
    2000,
    300,
    500,
    800,
    250,
    400
  }.toList();
  void doUiTurn(GameState state) async{
    if (simulateOnline)
      await Future.delayed(Duration(milliseconds: onlineDelays[Random().nextInt(onlineDelays.length)]));
    final action = await agent.chooseAction(state);
    if (_makeMoveAndStartAi(action.posX, action.posY))
      print("Ai not allowed");
  }
}
