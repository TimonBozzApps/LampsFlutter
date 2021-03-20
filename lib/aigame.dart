import 'dart:math';

import 'package:lamps3/game.dart';

class AiElements{

  static List<Move> actions(GameState state){
    List<Move> actions = [];
    for (List<Tile> tiles in state.board){
      for (Tile tile in tiles) {
        if (tile.owner == "" || tile.owner == state.currentPlayer)
          actions.add(Move(tile.posX, tile.posY, state.currentPlayer));
      }
    }
    return actions;
  }

  @deprecated
  static Future<GameState> result(GameState state, Move move) async{
    var newBoard = List.generate(5, (x) => List.generate(5, (y) {
      if (move.posX == x && move.posY == y)
        return Tile(move.player, state.board[x][y].charge+1, state.board[x][y].maxCharge, x, y);
      return state.board[x][y];
    }));
    var newState = GameState.fromPreviousVersionAndBoard(state, newBoard);
    newState.movesMade = state.movesMade+1;
    return newState;
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
      if (state.board[move.posX][move.posY].maxCharge == 1){ //corner: +3
        weightedActions.add(move);
        weightedActions.add(move);
        weightedActions.add(move);
      }
      if (state.board[move.posX][move.posY].owner == move.player) //already owned: +1
        weightedActions.add(move);
      if (state.board[move.posX][move.posY].maxCharge
          == state.board[move.posX][move.posY].charge) //explodes: +1
        weightedActions.add(move);
    }
    if (weightedActions.isEmpty) //in case no move gets a bonus and no move get random
      weightedActions.add(actions[0]);
    weightedActions.shuffle();
    return weightedActions[0];
  }
}
class SimpleRuleAgent implements Agent{
  @override
  Future<Move> chooseAction(GameState state) async {
    List<Move> actions = AiElements.actions(state);
    actions.shuffle();

    //explode own tile if charged enemy tile around
    for (Move move in actions){
      if (state.board[move.posX][move.posY].maxCharge == state.board[move.posX][move.posY].charge
          && maxChargedEnemyTilesAround(move, state)){
          return move;
      }
    }
    actions.shuffle();

    //corner if no enemy tile around and if not charged
    for (Move move in actions){
      if (state.board[move.posX][move.posY].maxCharge == 1
          && !maxChargedEnemyTilesAround(move, state)
          && state.board[move.posX][move.posY].charge == 0) {
        return move;
      }
    }
    actions.shuffle();

    //explode own tile if enemy tile around
    for (Move move in actions){
      if (state.board[move.posX][move.posY].maxCharge == state.board[move.posX][move.posY].charge
          && enemyTilesAround(move, state)){
          return move;
      }
    }
    actions.shuffle();

    //charge own tile if no enemy tile around
    for (Move move in actions){
      if (state.board[move.posX][move.posY].maxCharge == state.board[move.posX][move.posY].charge+1
          && !maxChargedEnemyTilesAround(move, state)){
        return move;
      }
    }
    actions.shuffle();

    return actions[0];
  }

  bool maxChargedEnemyTilesAround(Move move, GameState state){
    if (move.posX < state.sizeX-1 &&
        state.board[move.posX+1][move.posY].owner != state.currentPlayer &&
        state.board[move.posX+1][move.posY].maxCharge == state.board[move.posX+1][move.posY].charge)
      return true;
    if (move.posX > 0 &&
        state.board[move.posX-1][move.posY].owner != state.currentPlayer &&
        state.board[move.posX-1][move.posY].maxCharge == state.board[move.posX-1][move.posY].charge)
      return true;
    if (move.posY < state.sizeY-1 &&
        state.board[move.posX][move.posY+1].owner != state.currentPlayer &&
        state.board[move.posX][move.posY+1].maxCharge == state.board[move.posX][move.posY+1].charge)
      return true;
    if (move.posY > 0 &&
        state.board[move.posX][move.posY-1].owner != state.currentPlayer &&
        state.board[move.posX][move.posY-1].maxCharge == state.board[move.posX][move.posY-1].charge)
      return true;
    return false;
  }
  bool enemyTilesAround(Move move, GameState state){
    if (move.posX < state.sizeX-1 &&
        state.board[move.posX+1][move.posY].owner != state.currentPlayer &&
        state.board[move.posX+1][move.posY].owner != "")
      return true;
    if (move.posX > 0 &&
        state.board[move.posX-1][move.posY].owner != state.currentPlayer&&
        state.board[move.posX-1][move.posY].owner != "")
      return true;
    if (move.posY < state.sizeY-1 &&
        state.board[move.posX][move.posY+1].owner != state.currentPlayer&&
        state.board[move.posX][move.posY+1].owner != "")
      return true;
    if (move.posY > 0 &&
        state.board[move.posX][move.posY-1].owner != state.currentPlayer&&
        state.board[move.posX][move.posY-1].owner != "")
      return true;
    return false;
  }
}
class SimpleRuleAgentAdvanced implements Agent{
  @override
  Future<Move> chooseAction(GameState state) async {
    List<Move> actions = AiElements.actions(state);
    actions.shuffle();

    //explode own tile if charged enemy tile around
    for (Move move in actions){
      if (state.board[move.posX][move.posY].maxCharge == state.board[move.posX][move.posY].charge
          && maxChargedEnemyTilesAround(move, state)){
        return move;
      }
    }
    actions.shuffle();

    //corner if no charged enemy tile around
    for (Move move in actions){
      if (state.board[move.posX][move.posY].maxCharge == 1
          && !maxChargedEnemyTilesAround(move, state)
          && state.board[move.posX][move.posY].charge == 0) {
        return move;
      }
    }
    actions.shuffle();

    //explode own tile if enemy tile around
    //and no charged enemy tile is around the attacked tile
    for (Move move in actions){
      if (state.board[move.posX][move.posY].maxCharge == state.board[move.posX][move.posY].charge
          && enemyTilesAround(move, state)){
        Move enemyTileMove = enemyTilesAroundMove(move, state);
        if (!maxChargedEnemyTilesAround(enemyTileMove, state)) {
          return move;
        }
      }
    }
    actions.shuffle();

    //charge own tile if enemy tile around further away from explosion
    for (Move move in actions){
      if (enemyTilesAround(move, state)) {
        Move enemyTileMove = enemyTilesAroundMove(move, state);
        Tile enemyTile = state.board[enemyTileMove.posX][enemyTileMove.posY];
        if (state.board[move.posX][move.posY].maxCharge -
            state.board[move.posX][move.posY].charge >= enemyTile.maxCharge - enemyTile.charge){
          return move;
        }
      }
    }
    actions.shuffle();

    //charge own tile if no enemy tile around
    for (Move move in actions){
      if (state.board[move.posX][move.posY].charge > 0
          && !enemyTilesAround(move, state)){
        return move;
      }
    }
    actions.shuffle();

    return actions[0];
  }

  bool maxChargedEnemyTilesAround(Move move, GameState state){
    if (move.posX < state.sizeX-1 &&
        state.board[move.posX+1][move.posY].owner != state.currentPlayer &&
        state.board[move.posX+1][move.posY].maxCharge == state.board[move.posX+1][move.posY].charge)
      return true;
    if (move.posX > 0 &&
        state.board[move.posX-1][move.posY].owner != state.currentPlayer &&
        state.board[move.posX-1][move.posY].maxCharge == state.board[move.posX-1][move.posY].charge)
      return true;
    if (move.posY < state.sizeY-1 &&
        state.board[move.posX][move.posY+1].owner != state.currentPlayer &&
        state.board[move.posX][move.posY+1].maxCharge == state.board[move.posX][move.posY+1].charge)
      return true;
    if (move.posY > 0 &&
        state.board[move.posX][move.posY-1].owner != state.currentPlayer &&
        state.board[move.posX][move.posY-1].maxCharge == state.board[move.posX][move.posY-1].charge)
      return true;
    return false;
  }

  bool enemyTilesAround(Move move, GameState state){
    if (move.posX < state.sizeX-1 &&
        state.board[move.posX+1][move.posY].owner != state.currentPlayer &&
        state.board[move.posX+1][move.posY].owner != "")
      return true;
    if (move.posX > 0 &&
        state.board[move.posX-1][move.posY].owner != state.currentPlayer&&
        state.board[move.posX-1][move.posY].owner != "")
      return true;
    if (move.posY < state.sizeY-1 &&
        state.board[move.posX][move.posY+1].owner != state.currentPlayer&&
        state.board[move.posX][move.posY+1].owner != "")
      return true;
    if (move.posY > 0 &&
        state.board[move.posX][move.posY-1].owner != state.currentPlayer&&
        state.board[move.posX][move.posY-1].owner != "")
      return true;
    return false;
  }
  Move enemyTilesAroundMove(Move move, GameState state){
    if (move.posX < state.sizeX-1 &&
        state.board[move.posX+1][move.posY].owner != state.currentPlayer &&
        state.board[move.posX+1][move.posY].owner != "")
      return Move(move.posX+1, move.posY, move.player);
    if (move.posX > 0 &&
        state.board[move.posX-1][move.posY].owner != state.currentPlayer&&
        state.board[move.posX-1][move.posY].owner != "")
      return Move(move.posX-1, move.posY, move.player);
    if (move.posY < state.sizeY-1 &&
        state.board[move.posX][move.posY+1].owner != state.currentPlayer&&
        state.board[move.posX][move.posY+1].owner != "")
      return Move(move.posX, move.posY+1, move.player);
    if (move.posY > 0 &&
        state.board[move.posX][move.posY-1].owner != state.currentPlayer&&
        state.board[move.posX][move.posY-1].owner != "")
      return Move(move.posX, move.posY-1, move.player);
    return null;
  }
}

