import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'online.dart';

class MultiplayerGameSetup extends StatefulWidget {
  final OnlineApi _onlineApi;
  MultiplayerGameSetup(this._onlineApi);

  @override
  State<StatefulWidget> createState() {
    return MultiplayerGameSetupState();
  }
}

class MultiplayerGameSetupState extends State<MultiplayerGameSetup> {
  final _formKey = GlobalKey<FormState>();
  final _playerNameController = TextEditingController();
  double sizeX = 8;
  double sizeY = 6;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            playerNameTextField,
            SizedBox(height: 16),
            Text("Board size: $sizeX x $sizeY"),
            Slider(
              divisions: 8,
              min: 4,
              max: 12,
              activeColor: Colors.green,
              inactiveColor: Colors.green,
              value: sizeX,
              onChanged: (value) {
                setState(() {
                  sizeX = value;
                  if (value < sizeY) sizeY = value;
                });
              },
            ),
            SizedBox(
              height: 8,
            ),
            Slider(
              divisions: 8,
              min: 4,
              max: 12,
              activeColor: Colors.green,
              inactiveColor: Colors.green,
              value: sizeY,
              onChanged: (value) {
                setState(() {
                  sizeY = value;
                  if (value > sizeX) sizeX = value;
                });
              },
            )
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text("Create game"),
          style: ElevatedButton.styleFrom(
            primary: Colors.amber,
          ),
          onPressed: () {
            if (_formKey.currentState.validate())
              widget._onlineApi.createGame(
                  sizeX.toInt(), sizeY.toInt(), _playerNameController.text);
          },
        )
      ],
      title: Text("New Online Game"),
    );
  }

  Widget get playerNameTextField => TextFormField(
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
          fillColor: Colors.green,
          hintText: "Nickname",
        ),
        controller: _playerNameController,
        autofocus: true,
        validator: (value) {
          if (value.length == 0) return "Enter a nickname";
          if (value.length > 24) return "Nickname too long";
          final validCharacters =
              RegExp(r'(^[a-zA-Z0-9]+$)|(^[a-zA-Z0-9][a-zA-Z0-9 ]+$)');
          if (!validCharacters.hasMatch(value))
            return "Name is not valid (only numbers, letters, space allowed)";
          return null;
        },
      );

  @override
  void dispose() {
    super.dispose();
    _playerNameController.dispose();
  }
}

class MultiplayerGameJoin extends StatefulWidget {
  final OnlineApi _onlineApi;
  MultiplayerGameJoin(this._onlineApi);

  @override
  State<StatefulWidget> createState() {
    return MultiplayerGameJoinState();
  }
}

class MultiplayerGameJoinState extends State<MultiplayerGameJoin> {
  final _formKey = GlobalKey<FormState>();
  final _gameIdController = TextEditingController();
  final _playerNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Join Game"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            playerNameTextField,
            SizedBox(
              height: 16,
            ),
            gameIdTextField,
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text("Join Game"),
          style: ElevatedButton.styleFrom(
            primary: Colors.amber,
          ),
          onPressed: () {
            if (_formKey.currentState.validate())
              widget._onlineApi.joinGame(_gameIdController.text.toUpperCase(),
                  _playerNameController.text);
          },
        )
      ],
    );
  }

  Widget get gameIdTextField => TextFormField(
        textAlign: TextAlign.center,
        style: TextStyle(
            letterSpacing: 16, fontSize: 18, fontWeight: FontWeight.bold),
        maxLength: 6,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
          fillColor: Colors.blue,
          hintText: "GameId",
        ),
        controller: _gameIdController,
        validator: (value) {
          if (value.length != 6) return "Enter game id (6 chars)";
          final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
          if (!validCharacters.hasMatch(value))
            return "Only use letters and numbers";
          return null;
        },
      );
  Widget get playerNameTextField => TextFormField(
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
          fillColor: Colors.green,
          hintText: "Nickname",
        ),
        controller: _playerNameController,
        autofocus: true,
        validator: (value) {
          if (value.length == 0) return "Enter a nickname";
          if (value.length > 24) return "Nickname too long";
          final validCharacters =
              RegExp(r'(^[a-zA-Z0-9]+$)|(^[a-zA-Z0-9][a-zA-Z0-9 ]+$)');
          if (!validCharacters.hasMatch(value))
            return "Name is not valid (only numbers, letters, space allowed)";
          return null;
        },
      );

  @override
  void dispose() {
    super.dispose();
    _playerNameController.dispose();
    _gameIdController.dispose();
  }
}

class MultiplayerGameFind extends StatefulWidget {
  final OnlineApi _onlineApi;
  MultiplayerGameFind(this._onlineApi);

  @override
  State<StatefulWidget> createState() {
    return MultiplayerGameFindState();
  }
}

class MultiplayerGameFindState extends State<MultiplayerGameFind> {
  final _formKey = GlobalKey<FormState>();
  final _gameIdController = TextEditingController();
  final _playerNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Find Game"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text("You will play against random players from around the world"),
            SizedBox(
              height: 8,
            ),
            playerNameTextField,
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text("Find Game"),
          style: ElevatedButton.styleFrom(
            primary: Colors.amber,
          ),
          onPressed: () {
            if (_formKey.currentState.validate())
              widget._onlineApi.findMatchMakingGame(_playerNameController.text);
          },
        )
      ],
    );
  }

  Widget get playerNameTextField => TextFormField(
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
          fillColor: Colors.green,
          hintText: "Nickname",
        ),
        controller: _playerNameController,
        autofocus: true,
        validator: (value) {
          if (value.length == 0) return "Enter a nickname";
          if (value.length > 24) return "Nickname too long";
          final validCharacters =
              RegExp(r'(^[a-zA-Z0-9]+$)|(^[a-zA-Z0-9][a-zA-Z0-9 ]+$)');
          if (!validCharacters.hasMatch(value))
            return "Name is not valid (only numbers, letters, space allowed)";
          return null;
        },
      );

  @override
  void dispose() {
    super.dispose();
    _playerNameController.dispose();
    _gameIdController.dispose();
  }
}
