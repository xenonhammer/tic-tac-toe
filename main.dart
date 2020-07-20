import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';

main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tic tac',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SocketIO socketIO;
  bool myTurn = true;
  String symbol;
  bool tie = false; // ничья
  String opponentName;
  String _messageText = 'Set your name';
  bool visibilityInp = true;
  TextEditingController textController;
  bool opponentStep = false;
  String position;

  Map<dynamic, String> checked = {
    0: "",
    1: "",
    2: "",
    3: "",
    4: "",
    5: "",
    6: "",
    7: "",
    8: ""
  };
  Map<String, String> obj = {
    'r0c0': '',
    'r0c1': '',
    'r0c2': '',
    'r1c0': '',
    'r1c1': '',
    'r1c2': '',
    'r2c0': '',
    'r2c1': '',
    'r2c2': ''
  };
  @override
  void initState() {
    super.initState();
    _connectSocket01();
    textController = TextEditingController();
  }

  renderTurnMessage() {
    if (!myTurn) {
      // If not player's turn disable the board
      setState(() {
        _messageText = '$opponentName`s turn';
        opponentStep = true;
      });
    } else {
      // Enable it otherwise
      setState(() {
        _messageText = 'Your turn.';
        opponentStep = false;
      });
    }
  }

  _connectSocket01() {
    //update your domain before using
    /*socketIO = new SocketIO("http://127.0.0.1:3000", "/",
        query: "userId=21031", socketStatusCallback: _socketStatus);*/
    socketIO = SocketIOManager().createSocketIO(
        "https://tic-tac-flutter.herokuapp.com", "/",
        query: "", socketStatusCallback: _socketStatus);

    //call init socket before doing anything
    socketIO.init();

    //subscribe event
    socketIO.subscribe("socket_info", _onSocketInfo);
    socketIO.subscribe("opponent.left", _onOpponentLeft);
    socketIO.subscribe("game.begin", _onGameBegin);
    socketIO.subscribe("move.made", _onMoveMade);

    //connect socket
    socketIO.connect();
  }

  _onSocketInfo(dynamic data) {
    // print("Socket info: ");
  }

  _socketStatus(dynamic data) {
//    print("Socket status: " + data);
  }

  _onMoveMade(dynamic data) {
    data = jsonDecode(data);

    int index = 0;
    obj.forEach((key, value) => {
          setState(() {
            if (key == data['position']) {
              checked[index] = data['symbol'];
            }
            index++;
          })
        });

    setState(() {
      opponentStep = false; // Disable board  makeMove()
    });

    myTurn = data['symbol'] != symbol;

    if (!isGameOver(checked)) {
      // If game isn't over show who's turn is this
      renderTurnMessage();
    } else {
      // Else show win/lose/tie message
      if (tie) {
        setState(() {
          _messageText = "It's a tie!";
        });
      } else {
        if (myTurn) {
          setState(() {
            _messageText = '$opponentName won!';
          });
        } else {
          setState(() {
            _messageText = "You won!";
          });
        }
      }
    }
  }

// Bind on event for opponent leaving the game
  _onOpponentLeft(dynamic data) {
    print('opponent.left');
      setState(() {
        _messageText = '$opponentName left the game.';
        opponentStep = true; // Disable board
      });
  }

// Bind event for game begin
  _onGameBegin(dynamic data) {
    data = jsonDecode(data);
    setState(() {
      symbol = data['symbol']; // The server is assigning the symbol
      myTurn = symbol == "X"; // 'X' starts first
      opponentName = data['opponentName'];
    });
    renderTurnMessage();
  }

  getBoardState(checked) {
    int i = 0;
    obj.forEach((key, value) {
      if (key != "") {
        setState(() {
          obj[key] = checked[i];
        });
        i++;
      }
    });

    return obj;
  }

  isGameOver(checked) {
    var state = getBoardState(checked);
    List<String> matches = ["XXX", "OOO"];

    List<String> rows = [
      state['r0c0'] + state['r0c1'] + state['r0c2'], // 1st line
      state['r1c0'] + state['r1c1'] + state['r1c2'], // 2nd line
      state['r2c0'] + state['r2c1'] + state['r2c2'], // 3rd line
      state['r0c0'] + state['r1c0'] + state['r2c0'], // 1st column
      state['r0c1'] + state['r1c1'] + state['r2c1'], // 2nd column
      state['r0c2'] + state['r1c2'] + state['r2c2'], // 3rd column
      state['r0c0'] + state['r1c1'] + state['r2c2'], // Primary diagonal
      state['r0c2'] + state['r1c1'] + state['r2c0'] // Secondary diagonal
    ];
    for (var i = 0, k = 0; i < rows.length; i++) {
      print(rows[i]);
      if (rows[i].length == 3) {
        k++;

        if (k == rows.length &&
            !(rows[i] == matches[0] || rows[i] == matches[1])) {
          //Если все поле занято, а победителя нет, то будет ничья
          setState(() {
            opponentStep = true;
          });
          return tie = true;
        }
      }

      if (rows[i] == matches[0] || rows[i] == matches[1]) {
        setState(() {
          opponentStep = true;
        });
        return true;
      }
    }

    return false;
  }

  makeMove(int positionNum) {
    if (!myTurn) {
      return; // Shouldn't happen since the board is disabled
    }

    if (checked[positionNum] == "") {
      setState(() {
        checked[positionNum] = symbol;
      });
    } else {
      return;
    }

    int index = 0;
    obj.forEach((key, value) {
      if (obj[key] == "" && positionNum == index) {
        setState(() {
          position = key;
        });
      }

      index++;
    });

    var resJson = jsonEncode({'symbol': symbol, 'position': position});
    socketIO.sendMessage(
        'make.move', resJson); // Valid move (on client side) -> emit to server
  }

  Widget buildInputName() {
    final _formKey = GlobalKey<FormState>();
    return Container(
      child: Form(
        key: _formKey,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: visibilityInp
                ? <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) {},
                        controller: textController,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: RaisedButton(
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              socketIO.sendMessage('set.name',
                                  jsonEncode({'name': textController.text}));
                              setState(() {
                                visibilityInp = false;
                                _messageText = 'Waiting for an opponent...';
                              });
                            }
                          },
                          child: Text('Submit'),
                        ),
                      ),
                    ),
                  ]
                : List()),
      ),
    );
  }

  Widget buildGridContainer() {
    return  visibilityInp 
          ? Container()
          : opponentStep
            ? Container(
                padding: EdgeInsets.all(15.0),
                height: 500.0,
                child: GridView.count(
                  crossAxisCount: 3,
                  children: List<Widget>.generate(9, (positionNum) {
                    return GridTile(
                      child: GestureDetector(
                        child: Card(
                            color: Colors.blue.shade100,
                            child: Center(
                              child: Text(
                                checked[positionNum],
                                style: TextStyle(fontSize: 40.0),
                              ),
                            )),
                      ),
                    );
                  }),
                ),
              )
            :Container(
                padding: EdgeInsets.all(15.0),
                height: 500.0,
                child: GridView.count(
                  crossAxisCount: 3,
                  children: List<Widget>.generate(9, (positionNum) {
                    return GridTile(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            opponentStep = true; // Disable board
                          });
                          makeMove(positionNum);
                          renderTurnMessage();
                          isGameOver(checked);
                        },
                        child: Card(
                            color: Colors.blue.shade100,
                            child: Center(
                              child: Text(
                                checked[positionNum],
                                style: TextStyle(fontSize: 40.0),
                              ),
                            )),
                      ),
                    );
                  }),
                ),
              );


  }

  Widget buildMessage() {
    return Container(
        child: Center(
            child: Container(
      margin: EdgeInsets.all(20.0),
      width: 250.0,
      child: Text(
        _messageText,
        style: TextStyle(fontSize: 20.0),
      ),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar:  AppBar(
        title:  Text('Крестики-Нолики'),
      ),
      body: Container(
          child: ListView(
        children: <Widget>[
          buildMessage(),
          buildInputName(),
          buildGridContainer(),
        ],
      )),
    );
  }
}
