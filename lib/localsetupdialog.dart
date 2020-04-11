import 'package:flutter/material.dart';

class LocalGameSetup extends StatefulWidget {
  LocalGameSetup();

  @override
  State<StatefulWidget> createState() {
    return LocalGameSetupState();
  }
}

class LocalGameSetupState extends State<LocalGameSetup>{
  double sizeX = 8;
  double sizeY = 6;
  double players = 2;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("Players: ${players.toInt()}"),
          Slider(
            divisions: 8,
            min: 2,
            max: 10,
            activeColor: Colors.blue,
            inactiveColor: Colors.blue,
            value: players,
            onChanged: (value) {
              setState(() {
                players = value;
              });
            },
          ),
          SizedBox(height: 16),
          Text("Board size: ${sizeX.toInt()} x ${sizeY.toInt()}"),
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
              });
            },
          ),
          SizedBox(height: 8,),
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
              });
            },
          )
        ],
      ),
      actions: <Widget>[
        RaisedButton(
          child: Text("Play"),
          color: Colors.amber,
          elevation: 0,
          onPressed: () {
            Navigator.pop(context, {
              "sizeX": sizeX.toInt(),
              "sizeY": sizeY.toInt(),
              "players": List<String>.generate(players.toInt(), (index) => "$index")
            });
          },
        )
      ],
      title: Text("New Local Game"),
    );
  }
}