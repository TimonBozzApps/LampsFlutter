import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:lamps3/game.dart';
import 'package:rxdart/rxdart.dart';

class OnlineApi {
  Firestore _firestore = Firestore.instance;
  CloudFunctions _cloudFunctions = CloudFunctions.instance;

  String gameId;
  String _playerName;

  BehaviorSubject<OnlineGame> _onlineGame = BehaviorSubject();
  BehaviorSubject<List<Move>> _moves = BehaviorSubject();
  BehaviorSubject<List<Move>> _newMoves = BehaviorSubject();

  ValueStream<OnlineGame> get onlineGame => _onlineGame.stream;
  ValueStream<List<Move>> get moves => _moves.stream;
  ValueStream<List<Move>> get newMoves => _newMoves.stream;
  String get playerName => _playerName;

  OnlineApi();
  OnlineApi.fromGameId(this.gameId, this._playerName) {
    _initializeListeners();
  }

  Future<String> createGame(int sizeX, int sizeY, String playerName) async {
    if (sizeX < 4 ||
        sizeY < 4 ||
        sizeX > 12 ||
        sizeY > 12 ||
        playerName.trim().length == 0) return null;
    final HttpsCallable callable = _cloudFunctions.getHttpsCallable(
      functionName: 'createGame',
    );
    final response = await callable.call(<String, dynamic>{
      "sizeX": sizeX,
      "sizeY": sizeY,
      "playerName": playerName.trim()
    });
    _playerName = playerName.trim();
    gameId = response.data['gameId'];
    _initializeListeners();
    return gameId;
  }

  Future<String> joinGame(String gameId, String playerName) async {
    if (gameId.trim().length != 6 || playerName.trim().length == 0) return null;
    final HttpsCallable callable = _cloudFunctions.getHttpsCallable(
      functionName: 'joinGame',
    );
    final response = await callable.call(
        <String, dynamic>{"gameId": gameId, "playerName": playerName.trim()});
    _playerName = response.data['playerName'];
    this.gameId = response.data['gameId'];
    _initializeListeners();
    return gameId;
  }

  Future<String> findMatchMakingGame(String playerName) async {
    if (playerName.trim().length == 0) return null;
    final HttpsCallable callable = _cloudFunctions.getHttpsCallable(
      functionName: 'findGame',
    );
    final response =
        await callable.call(<String, dynamic>{"playerName": playerName.trim()});
    _playerName = response.data['playerName'];
    this.gameId = response.data['gameId'];
    _initializeListeners();
    return gameId;
  }

  Future<String> leaveGame() async {
    final HttpsCallable callable = _cloudFunctions.getHttpsCallable(
      functionName: 'leaveGame',
    );
    final response = await callable.call(
        <String, dynamic>{"playerName": playerName.trim(), "gameId": gameId});
    dispose();
    return response.data['gameId'];
  }

  Future<String> startGame(String gameId) async {
    if (gameId.trim().length != 6) return null;
    final HttpsCallable callable = _cloudFunctions.getHttpsCallable(
      functionName: 'startGame',
    );
    await callable
        .call(<String, dynamic>{"gameId": gameId, "playerName": _playerName});
    return gameId;
  }

  void makeMove(Move move) {
    _firestore.collection('servers/1/games/$gameId/moves').add({
      "posX": move.posX,
      "posY": move.posY,
      "player": move.player,
      "time": FieldValue.serverTimestamp()
    });
  }

  Future<String> createRematchGame() async {
    if (onlineGame.value != null &&
        onlineGame.value.players.indexOf(playerName) == 0) {
      final HttpsCallable callable = _cloudFunctions.getHttpsCallable(
        functionName: 'createGame',
      );
      final response = await callable.call(<String, dynamic>{
        "sizeX": onlineGame.value.sizeX,
        "sizeY": onlineGame.value.sizeY,
        "playerName": playerName.trim()
      });
      var rematchId = response.data['gameId'];
      _firestore
          .document("servers/1/games/$gameId")
          .updateData({"rematchGame": rematchId});
      return rematchId;
    }
    return null;
  }

  Future<String> joinRematchGame() async {
    if (onlineGame.value != null && onlineGame.value.rematchGame != null) {
      final HttpsCallable callable = _cloudFunctions.getHttpsCallable(
        functionName: 'joinGame',
      );
      final response = await callable.call(<String, dynamic>{
        "gameId": onlineGame.value.rematchGame,
        "playerName": playerName.trim()
      });
      return response.data['gameId'];
    }
    return null;
  }

  void _initializeListeners() {
    getGame().listen((snapshot) {
      if (snapshot.exists)
        _onlineGame.add(OnlineGame(
            snapshot.documentID,
            snapshot.data['players'].cast<String>().toList(),
            snapshot.data['state'],
            snapshot.data['sizeX'],
            snapshot.data['sizeY'],
            snapshot.data['rematchGame']));
    });
    getMoves().listen((querySnapshot) {
      List<Move> moves = <Move>[];
      querySnapshot.documents.forEach((element) {
        if (element.exists) {
          moves.add(Move(element.data['posX'], element.data['posY'],
              element.data['player']));
        }
      });
      if (!_moves.isClosed) _moves.add(moves);
      List<Move> newMoves = <Move>[];
      querySnapshot.documentChanges.forEach((element) {
        if (element.type == DocumentChangeType.added)
          newMoves.add(Move(element.document.data['posX'],
              element.document.data['posY'], element.document.data['player']));
      });
      if (!_newMoves.isClosed) _newMoves.add(newMoves);
    });
  }

  Stream<DocumentSnapshot> getGame() {
    return _firestore.document('servers/1/games/$gameId').snapshots();
  }

  Stream<QuerySnapshot> getMoves() {
    return _firestore
        .collection('servers/1/games/$gameId/moves')
        .orderBy('time', descending: false)
        .snapshots();
  }

  void dispose() {
    _onlineGame.close();
    _moves.close();
    _newMoves.close();
  }
}

class OnlineGame {
  String gameId;
  List<String> players;
  int state; //0 - not started ; 1 - started
  int sizeX;
  int sizeY;
  String rematchGame;
  OnlineGame(this.gameId, this.players, this.state, this.sizeX, this.sizeY,
      this.rematchGame);
}
