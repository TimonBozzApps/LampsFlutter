import 'dart:math';

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lamps3/game.dart';
import 'package:lamps3/localgameroute.dart';
import 'package:lamps3/onlinegameroute.dart';
import 'package:lamps3/online.dart';
import 'package:lamps3/theme.dart';
import 'package:package_info/package_info.dart';
import 'aigame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);

  runApp(MaterialApp(
    title: 'Charge',
    theme: lampsTheme,
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
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

  void _initListeners() {
    _onlineApi.onlineGame.listen((onlineGame) {
      if (onlineGame != null && !_startedGame) {
        _startedGame = true;
        if (!_rematch) Navigator.pop(context);
        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        OnlineGameRoute(_onlineApi, onlineGame),
                    settings: RouteSettings(name: "onlinegame")))
            .then((value) {
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
              child: Align(
                alignment: Alignment(0, 0.45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "Charge!",
                      style: Theme.of(context).textTheme.headline1,
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Theme.of(context).accentColor,
                      ),
                      child: Text(
                        "Play now",
                        style: Theme.of(context).textTheme.button,
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocalGameRoute(LocalAiGame(
                                  generateAiGame(6, 4, {
                                    "&&AI&&AR": SimpleRuleAgentAdvanced(),
                                    "&&AI&&SR": SimpleRuleAgent(),
                                    "&&AI&&RR": RandomAgent(),
                                    "&&AI&&WR": WeightedRandomAgent(),
                                  }),
                                  {
                                    "&&AI&&AR": SimpleRuleAgentAdvanced(),
                                    "&&AI&&SR": SimpleRuleAgent(),
                                    "&&AI&&RR": RandomAgent(),
                                    "&&AI&&WR": WeightedRandomAgent(),
                                  },
                                  true)),
                            ));
                      },
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextButton(
                      child: Text(
                        "How to play",
                        style: Theme.of(context).textTheme.button,
                      ),
                      style: ButtonStyle(overlayColor:
                          MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.pressed))
                          return Color(0x40CCCCCC);
                        if (states.contains(MaterialState.hovered))
                          return Colors.transparent;
                        return null;
                      })),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ExplanationDialog(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 200,
              width: 200,
              child: FlareActor(
                "assets/explanation_dialog.flr",
                alignment: Alignment.center,
                fit: BoxFit.contain,
                animation: 'explosion',
              ),
            ),
            if (!kIsWeb)
              FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.data == null) return Text("Version ???");
                    return Text("Version ${snapshot.data.version}");
                  }),
            if (kIsWeb) Text("Web version 0.13.5 - beautiful")
          ],
        ),
      );
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  GameState generateAiGame(int sizeX, int sizeY, Map<String, Agent> aiAgents) {
    final random = Random();
    final playerCount = random.nextInt(3) + 3;
    final humanIndex = random.nextInt(playerCount);
    final players = List.generate(playerCount, (index) {
      if (humanIndex == index) return "$index";
      return "${aiAgents.keys.toList()[random.nextInt(aiAgents.length)]}$index";
    });
    final humanColor = spanishOrange;
    final aiColors = {
      lightSeaGreen,
      acidGreen,
      frenchViolet,
      goGreen,
      bluePantone,
    }.toList();
    final playerColors = List.generate(playerCount, (index) {
      if (index == humanIndex) return humanColor;
      if (index > humanIndex) index--;
      return aiColors[index];
    });
    return GameState(sizeX, sizeY, players, playerColors);
  }
}

class ExplanationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("How to play"),
      backgroundColor: Theme.of(context).canvasColor,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 200,
            width: 200,
            child: FlareActor(
              "assets/explanation_dialog.flr",
              alignment: Alignment.center,
              fit: BoxFit.contain,
              animation: 'explosion',
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Place charges in your or open tiles",
            textAlign: TextAlign.center,
          ),
          Text(
            "Create explosions to conquer enemy tiles",
            textAlign: TextAlign.center,
          ),
          Text(
            "Be the last one standing",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
