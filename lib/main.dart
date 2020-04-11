import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lamps3/game.dart';
import 'package:lamps3/localgameroute.dart';
import 'package:lamps3/localsetupdialog.dart';
import 'package:lamps3/onlinegameroute.dart';
import 'package:lamps3/gamewidget.dart';
import 'package:lamps3/online.dart';
import 'package:lamps3/onlinesetupdialogs.dart';
import 'package:package_info/package_info.dart';
import 'aigame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);

  runApp(MaterialApp(
    title: 'Lamps',
    theme: ThemeData(
      cardColor: Colors.white,
      backgroundColor: Colors.grey.shade200,
      accentColor: Colors.amber,
    ),
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}
class HomeState extends State<Home> {
  OnlineApi _onlineApi = OnlineApi();
  bool _startedGame = false;
  bool _rematch = false;

  @override
  void initState() {
    super.initState();
    _initListeners();
  }
  void _initListeners(){
    _onlineApi.onlineGame.listen((onlineGame) {
      if (onlineGame != null && !_startedGame) {
        _startedGame = true;
        if (!_rematch)
          Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => OnlineGameRoute(_onlineApi, onlineGame),
          settings: RouteSettings(
            name: "onlinegame"
          )
        )).then((value) {
          print("Rematch Game id: $value");
          if (value == null) {
            print("No rematch");
            _startedGame = false;
            _onlineApi = OnlineApi();
            setState(() {
              _rematch = false;
              _initListeners();
            });
            return;
          }
          _onlineApi = OnlineApi.fromGameId(value, _onlineApi.playerName);
          _startedGame = false;
          setState(() {
            _rematch = true;
            _initListeners();
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_rematch)
      return Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                  child: Row(
                    children: <Widget>[
                      Flexible(
                          flex: 1,
                          child: Center(child: _localButtons)
                      ),
                      Container(
                        height: 300,
                        width: 1,
                        color: Colors.grey.shade800,
                      ),
                      Flexible(
                        flex: 1,
                          child: Center(child: _multiplayerButtons)
                      )
                    ],
                  )
              ),
            ),
            if (!kIsWeb)
              FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.data == null)
                      return Text("Version ???");
                    return Text("Version ${snapshot.data.version}");
                  }
              ),
            if (kIsWeb)
              Text("Web version 0.12 - Ai Ready - New engine")
          ],
        ),
      );
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget get _localButtons => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text("Local Game",
        style: Theme.of(context).textTheme.headline5,
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 48,),
      Container(
        width: 120,
        child: RaisedButton(
          elevation: 0,
          color: Colors.blue,
          child: Text("With Humans"),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => LocalGameSetup(),
            ).then((value) {
              if (value == null)
                return;
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => LocalGameRoute(
                    LocalGame(GameState(value['sizeX'], value['sizeY'], value['players']))),
              ));
            });
          },
        ),
      ),
      Container(
        width: 120,
        child: RaisedButton(
          elevation: 0,
          color: Colors.red,
          child: Text("Against Ai"),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => LocalGameRoute(
                  LocalAiGame(GameState(5, 5, {"1", "&&AI&&1"}.toList()), SimpleRuleAgent(), false)),
            ));
          },
        ),
      ),
    ],
  );

  Widget get _multiplayerButtons => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text("Online Multiplayer",
        style: Theme.of(context).textTheme.headline5,
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 48,),
      Container(
        width: 120,
        child: RaisedButton(
          elevation: 1,
          color: Colors.green,
          child: Text("Find Game"),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => LocalGameRoute(
                  LocalAiGame(GameState(8, 6, {"&&AI&&1", "&&AI&&2", "4"}.toList()), SimpleRuleAgent(), true)),
            ));
          },
        ),
      ),
      Container(
        width: 120,
        child: RaisedButton(
          elevation: 0,
          color: Colors.amber,
          child: Text("Join Game"),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => MultiplayerGameJoin(_onlineApi),
            );
          },
        ),
      ),
      Container(
        width: 120,
        child: RaisedButton(
          child: Text("Create Game"),
          elevation: 0,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => MultiplayerGameSetup(_onlineApi),
            );
          },
        ),
      ),
    ],
  );
}