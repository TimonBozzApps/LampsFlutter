import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:lamps3/online.dart';
import 'package:rxdart/rxdart.dart';

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

class Game {
  bool _readyForNextMove = true;
  Duration _animationDuration = Duration(milliseconds: 300);
  int sizeX;
  int sizeY;
  BehaviorSubject<List<List<Tile>>> _board = BehaviorSubject();
  BehaviorSubject<List<Tile>> _exploadingTiles = BehaviorSubject();
  List<String> players;
  List<List<Tile>> playerOwnedTiles;
  String currentPlayer;
  int movesMade = 0;

  Stream<List<List<Tile>>> get board => _board.stream;
  Stream<List<Tile>> get exploadingTiles => _exploadingTiles.stream;

  Game(this.sizeX, this.sizeY, this.players, this._animationDuration){
    List<List<Tile>> board = List.generate(sizeX, (x) => List.generate(sizeY, (y) {
      int maxCharge = 3;
      if (x == 0 || x == sizeX-1)
        maxCharge--;
      if (y == 0 || y == sizeY-1)
        maxCharge--;
      return Tile("", 0, maxCharge, x, y);
    }));
    _board.add(board);
    currentPlayer = players[0];
    playerOwnedTiles = List<List<Tile>>.generate(players.length, (index) => List<Tile>());
  }

  //returns whether move was made
  bool makeMove(Move move, bool animate){
    if (!makeMoveCheck(move))
      return false;
    _board.value[move.posX][move.posY].charge++;
    _board.value[move.posX][move.posY].owner = move.player;
    movesMade++;
    Future.sync(() => _updateBoard(animate));
    return true;
  }
  bool makeMoveCheck(Move move){
    if (!_readyForNextMove)
      return false;
    if (!players.contains(move.player)) {
      return false; //player is already out
    }
    if (currentPlayer != move.player) {
      return false; //not player's turn
    }
    if (_board.value[move.posX][move.posY].owner != "" && //ok if no one owns it
        _board.value[move.posX][move.posY].owner != move.player) {
      return false; //not player's tile
    }
    return true;
  }

  void _updateBoard(bool animate) async{
    _readyForNextMove = false;
    List<List<Tile>> newBoard = List.generate(sizeX, (x) => List.generate(sizeY, (y) {
      int maxCharge = 3;
      if (x == 0 || x == sizeX-1)
        maxCharge--;
      if (y == 0 || y == sizeY-1)
        maxCharge--;
      return Tile("", 0, maxCharge, x, y);
    }));
    List<Tile> exploadedTiles = List<Tile>();
    _board.value.forEach((row) {
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
          } if (tile.posX + 1 < sizeX) {
            newBoard[tile.posX + 1][tile.posY].charge++;
            newBoard[tile.posX + 1][tile.posY].owner = tile.owner;
          } if (tile.posY + 1 < sizeY) {
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
    //determine amount of tiles a player owns
    playerOwnedTiles = List<List<Tile>>.generate(players.length, (index) => List<Tile>());
    newBoard.forEach((row) {
      row.forEach((tile) {
        if (tile.owner != "")
          playerOwnedTiles[players.indexOf(tile.owner)].add(tile);
      });
    });

    if (exploadedTiles.isNotEmpty) {
      if (animate){
        _exploadingTiles.add(exploadedTiles);
        await Future.delayed(_animationDuration, () {
          return _board.add(newBoard);
        });
      }
      _board.add(newBoard);
      _updateBoard(animate);  //recurse
    }else {
      _board.add(newBoard);
      //find next player
      bool isCurrentPlayerOwningTile = movesMade < players.length; //because in the first round nobody owns a tile
      do {
        int nextPlayerIndex = players.indexOf(currentPlayer) + 1;
        if (nextPlayerIndex >= players.length)
          nextPlayerIndex = 0;
        currentPlayer = players[nextPlayerIndex];
        //find if current player still has tiles
        if (playerOwnedTiles[nextPlayerIndex].length > 0)
          isCurrentPlayerOwningTile = true; //can't set it to false because of initial condition (^see above^)
      } while  (!isCurrentPlayerOwningTile);
      _readyForNextMove = true;
    }
  }

  void dispose(){
    _board.close();
    _exploadingTiles.close();
  }
}

class LocalGame {
  Game _game;
  LocalGame(int sizeX, int sizeY, List<String> players) {
    _game = Game(sizeX, sizeY, players, Duration(milliseconds: 400));
  }

  ValueStream<List<List<Tile>>> get board => _game.board;
  ValueStream<List<Tile>> get exploadingTiles => _game.exploadingTiles;

  int get sizeX => _game.sizeX;
  int get sizeY => _game.sizeY;
  int get movesMade => _game.movesMade;
  List<String> get players => _game.players;
  String get currentPlayer => _game.currentPlayer;
  List<List<Tile>> get playerOwnedTiles => _game.playerOwnedTiles;
  List<String> get playersStillInTheGame =>
      playerOwnedTiles.where((element) => element.length > 0).map((e) => e[0].owner).toList();

  bool makeMove(int posX, int posY){
    return _game.makeMove(Move(posX, posY, currentPlayer), true);
  }

  void dispose(){
    _game.dispose();
  }
}

class MultiplayerGame implements LocalGame{
  Game _game;
  OnlineApi _onlineApi;

  MultiplayerGame(this._onlineApi, OnlineGame onlineGame){
    _game = Game(onlineGame.sizeX, onlineGame.sizeY, onlineGame.players, Duration(milliseconds: 400));
    _game.board.listen(boardUpdate);
    _onlineApi.newMoves.listen((newMoves) {
      //new move
      newMoves.forEach((element) {
        queueMove(element);
      });
    });
  }

  ValueStream<List<List<Tile>>> get board => _game.board;
  ValueStream<List<Tile>> get exploadingTiles => _game.exploadingTiles;

  ValueStream<OnlineGame> get onlineGame => _onlineApi.onlineGame;
  int get sizeX => _game.sizeX;
  int get sizeY => _game.sizeY;
  int get movesMade => _game.movesMade;
  List<String> get players => _game.players;
  String get currentPlayer => _game.currentPlayer;
  List<List<Tile>> get playerOwnedTiles => _game.playerOwnedTiles;
  List<String> get playersStillInTheGame =>
      playerOwnedTiles.where((element) => element.length > 0).map((e) => e[0].owner).toList();

  bool makeMove(int posX, int posY){
    if (_game.makeMoveCheck(Move(posX, posY, _onlineApi.playerName))) {
      _onlineApi.makeMove(Move(posX, posY, _onlineApi.playerName));
      return true;
    }
    return false;
  }

  void dispose(){
    _game.dispose();
    _onlineApi.dispose();
  }

  List<Move> moveQueue = List<Move>();
  void queueMove(Move move){
    if (_game == null || !_game._readyForNextMove)
      moveQueue.add(move);
    else
      _game.makeMove(move, true);
  }
  void boardUpdate(List<List<Tile>> newBoard){
    if (_game._readyForNextMove && moveQueue.isNotEmpty){
      _game.makeMove(moveQueue[0], true);
      moveQueue.removeAt(0);
    }
  }
}
