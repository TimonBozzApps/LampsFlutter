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
import 'package:lamps3/theme.dart';
import 'package:package_info/package_info.dart';
import 'aigame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);

  runApp(MaterialApp(
    title: 'Lamps',
    theme: lampsTheme,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("Charge!", style: Theme.of(context).textTheme.headline1,),
                    SizedBox(height: 40,),
                    RaisedButton(
                      elevation: 1,
                      color: Theme.of(context).accentColor,
                      colorBrightness: Theme.of(context).accentColorBrightness,
                      child: Text("Play now", style: Theme.of(context).textTheme.button,),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => LocalGameRoute(
                              LocalAiGame(
                                  GameState(6, 4, {"&&AI&&1", "&&AI&&2", "4", "&&AI&&3"}.toList()),
                                  SimpleRuleAgent(), true)),
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(),
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
              Text("Web version 0.13.1 - beautiful")
          ],
        ),
      );
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}