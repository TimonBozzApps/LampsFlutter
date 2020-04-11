import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lamps3/game.dart';
import 'package:rxdart/rxdart.dart';

class GameState {
  List<List<Tile>> tiles;
  int turnCount = 0;
  GameState(this.tiles, this.turnCount);

  int get getPlayerTurn => turnCount % 2;

  bool get isTerminated { //todo: not extremely optimized
    if (turnCount < 3)
      return false;
    playerLoop: for (int player in {0, 1}){
      for (List<Tile> tiles in tiles)
        for (Tile tile in tiles)
          if (tile.owner == player.toString())
            continue playerLoop;
      return true;
    }
    return false;
  }

  int evaluate(int player){
    int value = 0;
    for (List<Tile> tiles in tiles) {
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

class AiGame implements Game{
  GameState _state = AiElements.initialState;
  Agent _agent;

  @override
  String currentPlayer = "0";

  @override
  int movesMade = 0;

  @override
  List<List<Tile>> playerOwnedTiles = List<List<Tile>>();

  @override
  List<String> players = {"0", "1"}.toList();

  @override
  int sizeX = 5;

  @override
  int sizeY = 5;

  BehaviorSubject<List<List<Tile>>> _board = BehaviorSubject();
  @override
  Stream<List<List<Tile>>> get board => _board;

  BehaviorSubject<List<Tile>> _exploadingTiles = BehaviorSubject.seeded(List<Tile>());
  @override
  Stream<List<Tile>> get exploadingTiles => _exploadingTiles;

  AiGame(this._agent){
    _board.add(_state.tiles);
    currentPlayer = players[0];
    playerOwnedTiles = List<List<Tile>>.generate(players.length, (index) => List<Tile>());
  }

  @override
  void dispose() {
    _board.close();
    _exploadingTiles.close();
  }

  @override
  bool makeMove(Move move, bool animate) {
    if (makeMoveCheck(move)) {
      updateForMove(move);
      return true;
    }
    return false;
  }
  void updateForMove(Move move) async{
    _state = await AiElements.result(_state, move);
    movesMade = _state.turnCount;
    currentPlayer = _state.getPlayerTurn.toString();
    playerOwnedTiles = List<List<Tile>>.generate(players.length, (index) => List<Tile>());
    for (List<Tile> tiles in _state.tiles)
      for (Tile tile in tiles)
        if (tile.owner != "") {
          playerOwnedTiles[players.indexOf(tile.owner)].add(tile);
        }
    _board.add(_state.tiles);
    if (_state.getPlayerTurn == 1 && !_state.isTerminated)
      _agent.chooseAction(_state).then(updateForMove);
  }

  @override
  bool makeMoveCheck(Move move) {
    return _state.getPlayerTurn == 0 &&
        (_state.tiles[move.posX][move.posY].owner == _state.getPlayerTurn.toString() ||
            _state.tiles[move.posX][move.posY].owner == "");
  }

}

class GameState2 {
  final int sizeX;
  final int sizeY;
  final List<String> players;

  List<List<Tile>> board;
  List<Tile> exploadingTiles;

  String currentPlayer;
  int movesMade;

  GameState2(this.sizeX, this.sizeY, this.players){
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
  GameState2.fromPreviousVersionAndBoard(GameState2 gameState2, this.board):
    sizeX = gameState2.sizeX,
    sizeY = gameState2.sizeY,
    players = gameState2.players,
    exploadingTiles = gameState2.exploadingTiles,
    currentPlayer = gameState2.currentPlayer,
    movesMade = gameState2.movesMade;
  GameState2.fromPreviousVersionAndExploadingTiles(GameState2 gameState2, this.exploadingTiles):
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
}
class Game2 {
  bool _readyForNextMove = true;
  Duration _animationDuration = Duration(milliseconds: 300);
  BehaviorSubject<GameState2> _gameState = BehaviorSubject(); //var

  ValueStream<GameState2> get gameState => _gameState.stream;

  Game2(GameState2 gameState2, this._animationDuration){
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
        _gameState.add(GameState2.fromPreviousVersionAndExploadingTiles(_gameState.value, exploadedTiles));
        await Future.delayed(_animationDuration, () {
          return _gameState.add(GameState2.fromPreviousVersionAndBoard(_gameState.value, newBoard));
        });
      }else {
        _gameState.value.exploadingTiles = exploadedTiles;
        _gameState.add(GameState2.fromPreviousVersionAndBoard(_gameState.value, newBoard));
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
      _gameState.add(GameState2.fromPreviousVersionAndBoard(_gameState.value, newBoard));
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
class LocalGame2 extends Game2{
  LocalGame2(GameState2 gameState2, Duration animationDuration) : super(gameState2, animationDuration);

  bool makeMove(int posX, int posY){
    return _makeMove(Move(posX, posY, gameState.value.currentPlayer), true);
  }
}

class AiElements{
  //5*5 board
  static GameState get initialState =>
      GameState(List.generate(5, (x) => List.generate(5, (y) {
        int maxCharge = 3;
        if (x == 0 || x == 5-1)
          maxCharge--;
        if (y == 0 || y == 5-1)
          maxCharge--;
        return Tile("", 0, maxCharge, x, y);
      })), 0);

  static int player(GameState state) => state.getPlayerTurn;

  static List<Move> actions(GameState state){
    List<Move> actions = List<Move>();
    for (List<Tile> tiles in state.tiles){
      for (Tile tile in tiles) {
        if (tile.owner == "" || tile.owner == player(state).toString())
          actions.add(Move(tile.posX, tile.posY, player(state).toString()));
      }
    }
    return actions;
  }

  static Future<GameState> result(GameState state, Move move) async{
    var newBoard = List.generate(5, (x) => List.generate(5, (y) {
      if (move.posX == x && move.posY == y)
        return Tile(move.player, state.tiles[x][y].charge+1, state.tiles[x][y].maxCharge, x, y);
      return state.tiles[x][y];
    }));
    return GameState(await _updateBoard(newBoard, false), state.turnCount+1);
  }
  static Future<List<List<Tile>>> _updateBoard(List<List<Tile>> board, bool animate) async{
    List<List<Tile>> newBoard = List.generate(5, (x) => List.generate(5, (y) {
      int maxCharge = 3;
      if (x == 0 || x == 5-1)
        maxCharge--;
      if (y == 0 || y == 5-1)
        maxCharge--;
      return Tile("", 0, maxCharge, x, y);
    }));
    List<Tile> exploadedTiles = List<Tile>();
    board.forEach((row) {
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
          } if (tile.posX + 1 < 5) {
            newBoard[tile.posX + 1][tile.posY].charge++;
            newBoard[tile.posX + 1][tile.posY].owner = tile.owner;
          } if (tile.posY + 1 < 5) {
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
      return await _updateBoard(newBoard, animate);  //recurse
    }
    return newBoard;
  }
}

class LocalAiGame implements LocalGame{
  AiGame _game;
  LocalAiGame() {
    //CHANGE THE AGENT HERE
    _game = AiGame(RandomAgent());
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

class Agent{
  Future<Move> chooseAction(GameState state) async => null;
}
class MinimaxAgent implements Agent{
  int maxDepth;
  int player;

  MinimaxAgent(this.maxDepth, this.player);

  Future<Move> chooseAction(GameState state) async{
    print("choose action");
    Move selectedAction = (await minimax(0, state, true)).value;
    return selectedAction;
  }

  Future<MapEntry<int, Move>> minimax(int currentDepth, GameState state, bool isMaxTurn) async{
    if (currentDepth == maxDepth || state.isTerminated)
      return MapEntry(state.evaluate(player), null);

    List<Move> actions = AiElements.actions(state);
    actions.shuffle();
    int bestValue = isMaxTurn ? -9999999 : 9999999;
    Move bestAction;
    for (Move move in actions){
      GameState newState = await AiElements.result(state, move);

      var result = await minimax(currentDepth+1, newState, !isMaxTurn);
      int evalChild = result.key;

      if (isMaxTurn && bestValue < evalChild) {
        bestValue = evalChild;
        bestAction = move;
      }else if (!isMaxTurn && bestValue > bestValue){
        bestValue = evalChild;
        bestAction = move;
      }
    }

    return MapEntry(bestValue, bestAction);
  }
}
class RandomAgent implements Agent{
  @override
  Future<Move> chooseAction(GameState state) async{
    List<Move> actions = AiElements.actions(state);
    actions.shuffle();
    return actions[0];
  }
}
class WeightedRandomAgent implements Agent{
  @override
  Future<Move> chooseAction(GameState state) async{
    List<Move> actions = AiElements.actions(state);
    actions.shuffle();
    List<Move> weightedActions = List<Move>();
    for (Move move in actions){
      if (Random().nextInt(4) == 1) //1/5 random: +1
        weightedActions.add(move);
      if (move.posX == 0 || move.posX == 5-1) //side: +1
        weightedActions.add(move);
      if (move.posY == 0 || move.posY == 5-1) //side: +1
        weightedActions.add(move);
      if (state.tiles[move.posX][move.posY].maxCharge == 1){ //corner: +3
        weightedActions.add(move);
        weightedActions.add(move);
        weightedActions.add(move);
      }
      if (state.tiles[move.posX][move.posY].owner == move.player) //already owned: +1
        weightedActions.add(move);
      if (state.tiles[move.posX][move.posY].maxCharge == state.tiles[move.posX][move.posY].charge) //exploades: +1
        weightedActions.add(move);
    }
    if (weightedActions.isEmpty) //in case no move gets a bonus and no move get random
      weightedActions.add(actions[0]);
    weightedActions.shuffle();
    return weightedActions[0];
  }

}


