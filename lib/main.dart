import 'package:flutter/material.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'dart:math';
import 'tile.dart';

const Color gridColor = Color.fromARGB(255, 187, 173, 160);
const Color emptyTileColor = Color.fromARGB(255, 205, 193, 180);
const Color tileTextColor = Color.fromARGB(255, 119, 110, 101);
const Color backgroundColor = Color.fromARGB(255, 250, 248, 239);
const Color tempC = Color.fromARGB(255, 238, 228, 218);

const Map<int, Color> numTileColor = {
  2: Color.fromARGB(255, 238, 228, 218),
  4: Color.fromARGB(255, 238, 225, 201),
  8: Color.fromARGB(255, 243, 178, 122),
  16: Color.fromARGB(255, 246, 150, 100),
  32: Color.fromARGB(255, 247, 124, 95),
  64: Color.fromARGB(255, 247, 96, 59),
  128: Color.fromARGB(255, 237, 208, 115),
  256: Color.fromARGB(255, 237, 204, 98),
  512: Color.fromARGB(255, 237, 201, 80),
  1024: Color.fromARGB(255, 237, 197, 63),
  2048: Color.fromARGB(255, 237, 194, 46),
  4096: Color.fromARGB(255, 16, 6, 0),
  8192: Color.fromARGB(255, 16, 6, 0),
};

void main() {
  runApp(GameApp());
}

class GameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2080 With Friends',
      home: Game(),
    );
  }
}

class Game extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<Game> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // outside is y axis, inside is x axis
  List<List<Tile>> _grid =
      List.generate(4, (y) => List.generate(4, (x) => Tile(x, y, 0)));
  List<Tile> _toAdd = [];

  // flattening a list of lists, turning into 1D
  Iterable<Tile> get _flatGrid => _grid.expand((element) => element);

  // grid as a list of columns for swiping implementation
  Iterable<List<Tile>> get _columns =>
      List.generate(4, (x) => List.generate(4, (y) => _grid[y][x]));

  Iterable<Tile> get _allTiles => [_flatGrid, _toAdd].expand((element) => element);

  late final List<BottomNavigationBarItem> bnbItems;
  int _currentIndex = 0;

  bool _gameOver = false;
  int _currentScore = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //check later
        for (var element in _toAdd) {
          _grid[element.y][element.x].value = element.value;
        }

        for (var element in _flatGrid) {
          element.resetAnimations();
        }

        _toAdd.clear();
      }
    });

    // generates first two tiles
    var rng = Random();
    var initialX1 = rng.nextInt(4);
    var initialY1 = rng.nextInt(4);
    var initialX2 = rng.nextInt(4);
    var initialY2 = rng.nextInt(4);
    _grid[initialY1][initialX1].value = (rng.nextInt(10) == 9) ? 4 : 2;
    while (initialX2 == initialX1 && initialY2 == initialY1) {
      initialX2 = rng.nextInt(4);
      initialY2 = rng.nextInt(4);
    }
    _grid[initialY2][initialX2].value = (rng.nextInt(10) == 9) ? 4 : 2;

    for (var element in _flatGrid) {
      element.resetAnimations();
      _currentScore += element.value;
    }
  }

  bool canSwipe(List<Tile> tiles) {
    for (int i = 0; i < tiles.length; ++i) {
      // if there is an empty spot
      if (tiles[i].value == 0) {
        // checks if rest of the tiles are not 0, "is there a tile to move"
        if (tiles.skip(i + 1).any((element) => element.value != 0)) {
          return true;
        }
      } else {
        Tile? nextNonZero =
            tiles.skip(i + 1).firstWhereOrNull((element) => element.value != 0);

        // check this later
        // tiles can merge
        if (nextNonZero != null && nextNonZero.value == tiles[i].value) {
          return true;
        }
      }
    }
    return false;
  }

  bool canSwipeUp() => _columns.any(canSwipe);

  bool canSwipeDown() => _columns.map((e) => e.reversed.toList()).any(canSwipe);

  bool canSwipeLeft() => _grid.any(canSwipe);

  bool canSwipeRight() => _grid.map((e) => e.reversed.toList()).any(canSwipe);

  // find empty spaces to add a new tile in, tile can be 2 or 4
  void addNewTile() {
    List<Tile> empty = _flatGrid.where((element) => element.value == 0).toList();
    empty.shuffle();

    var rng = Random();
    var newTileNum = (rng.nextInt(10) == 9) ? 4 : 2;

    _currentScore += newTileNum;

    // calling constructor and then appear animation
    _toAdd.add(Tile(empty.first.x, empty.first.y, newTileNum)..appear(_controller));
  }

  void doSwipe(void Function() swipeDirectionFunction) {
    setState(() {
      swipeDirectionFunction();

      addNewTile();

      _controller.forward(from: 0);
    });

    if (!canSwipeUp() &&
        !canSwipeDown() &&
        !canSwipeLeft() &&
        !canSwipeRight()) {
      confirmResetGame(
        context,
        const Text("Game Over"),
        const Text("Do you wish to start a new game?"),
      );
    }
  }

  // This is a decently complicated algorithm which I have mostly sourced from THKP
  // The credit of the logic goes to them
  void mergeTiles(List<Tile> tiles) {
    for (int i = 0; i < tiles.length; ++i) {
      // this is assuming that we have already confirmed a merge/swipe, so we
      // ignore empty spaces
      Iterable<Tile> toCheck =
          tiles.skip(i).skipWhile((value) => value.value == 0);
      if (toCheck.isNotEmpty) {
        Tile t = toCheck.first;
        Tile? mergeT =
            toCheck.skip(1).firstWhereOrNull((element) => element.value != 0);
        if (mergeT != null && mergeT.value != t.value) {
          mergeT = null;
        }
        if (tiles[i] != t || mergeT != null) {
          int resultValue = t.value;
          t.move(_controller, tiles[i].x, tiles[i].y);
          if (mergeT != null) {
            resultValue += mergeT.value;

            //plays animations
            mergeT.move(_controller, tiles[i].x, tiles[i].y);
            mergeT.bounce(_controller);
            mergeT.changeTileValue(_controller, resultValue);

            mergeT.value = 0;
            t.changeTileValue(_controller, 0);
          }
          t.value = 0;
          tiles[i].value = resultValue;
        }
      }
    }
  }

  void swipeUp() => _columns.forEach(mergeTiles);

  void swipeDown() =>
      _columns.map((e) => e.reversed.toList()).forEach(mergeTiles);

  void swipeLeft() => _grid.forEach(mergeTiles);

  void swipeRight() =>
      _grid.map((e) => e.reversed.toList()).forEach(mergeTiles);

  void resetGame() {
    setState(() {
      _flatGrid.forEach((t) {
        t.value = 0;
        t.resetAnimations();
      });
      _toAdd.clear();
      addNewTile();
      addNewTile();
      _controller.forward(from: 0);
    });
  }

  void confirmResetGame(BuildContext context, Text title, Text content) {
    var alertDialog = AlertDialog(
      title: title,
      content: content,
      actions: [
        TextButton(
            onPressed: () {
              resetGame();
              Navigator.pop(context);
            },
            child: const Text("Ok")),
        TextButton(onPressed: () {Navigator.pop(context);}, child: const Text("Cancel"))
      ],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        });
  }

  @override
  Widget build(BuildContext context) {
    // adding some space between grid and edge of screen
    double gridSize = MediaQuery.of(context).size.width - (16.0 * 2);
    double tileSize = (gridSize - (4.0 * 2)) / 4.0;

    List<Widget> stackItems = [];
    stackItems.addAll(_flatGrid.map((e) => Positioned(
          left: e.x * tileSize,
          top: e.y * tileSize,
          width: tileSize,
          height: tileSize,
          child: Center(
              child: Container(
            width: tileSize - 4.0 * 2,
            height: tileSize - 4.0 * 2,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: emptyTileColor),
          )),
        )));

    stackItems.addAll([_flatGrid, _toAdd].expand((element) => element).map((e) => AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => e.animatedValue.value == 0 ? const SizedBox() : Positioned(
        left: e.animatedX.value * tileSize,
        top: e.animatedY.value * tileSize,
        width: tileSize,
        height: tileSize,
          child: Center(
              child: Container(
                width: (tileSize - 4.0 * 2) * e.scale.value,
                height: (tileSize - 4.0 * 2) * e.scale.value,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: numTileColor[e.animatedValue.value]
                ),
                child: Center(
                  child: Text("${e.animatedValue.value}",
                  style: TextStyle(
                    color: e.animatedValue.value <= 4 ? tileTextColor : Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.w900,
                    )
                  ),
                ),
              )
            ),
          )
        )
      )
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("2048 With Friends"),
        backgroundColor: backgroundColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: tileTextColor,
          fontSize: 35,
          fontWeight: FontWeight.w900,
        ),
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          const SizedBox(width: double.infinity, height: 50.0),
          SizedBox(
            width: gridSize,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      primary: gridColor,
                      side: const BorderSide(color: gridColor, width: 2.0),
                      backgroundColor: tempC,
                    ),
                    child: const Text(
                      "New Game",
                      style: TextStyle(
                          color: tileTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      confirmResetGame(
                        context,
                        const Text("Confirm"),
                        const Text("Are you sure you wish to start a new game?"),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      primary: gridColor,
                      side: const BorderSide(color: gridColor, width: 2.0),
                      backgroundColor: tempC,
                    ),
                    child: const Text(
                      "Share",
                      style: TextStyle(
                          color: tileTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: double.infinity, height: 10),
          Center(
              child: Container(
            width: gridSize,
            height: gridSize,
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0), color: gridColor),
            child: GestureDetector(
              child: Stack(children: stackItems),
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy < -200 &&
                    canSwipeUp()) {
                  doSwipe(swipeUp);
                } else if (details.velocity.pixelsPerSecond.dy > 200 &&
                    canSwipeDown()) {
                  doSwipe(swipeDown);
                }
              },
              onHorizontalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dx < -200 &&
                    canSwipeLeft()) {
                  doSwipe(swipeLeft);
                } else if (details.velocity.pixelsPerSecond.dx > 200 &&
                    canSwipeRight()) {
                  doSwipe(swipeRight);
                }
              },
            ),
          )),
          const SizedBox(width: double.infinity, height: 10.0),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: gridSize,
                    padding: const EdgeInsets.only(
                        top: 10.0, bottom: 10.0, left: 10.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: gridColor, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                        color: tempC),
                    child: Text(
                      "Score: " + _currentScore.toString(),
                      style: const TextStyle(
                          color: tileTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: double.infinity, height: 5.0),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: gridSize,
                    padding: const EdgeInsets.only(
                        top: 10.0, bottom: 10.0, left: 10.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: gridColor, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                        color: tempC),
                    child: Text(
                      "Highscore: " + _currentScore.toString(),
                      style: const TextStyle(
                          color: tileTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: double.infinity, height: 5.0),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: gridColor,
        type: BottomNavigationBarType.shifting,
        iconSize: 20.0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.play_arrow),
              label: "Game",
              backgroundColor: gridColor),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: "Leaderboards",
              backgroundColor: gridColor),
          BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: "Friends",
              backgroundColor: gridColor),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
              backgroundColor: gridColor),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// class CircularFabWidget extends StatefulWidget {
//   const CircularFabWidget({Key? key}) : super(key: key);
//
//   @override
//   _CircularFabWidgetState createState() => _CircularFabWidgetState();
// }
//
// class _CircularFabWidgetState extends State<CircularFabWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return Flow(
//       delegate: FlowMenuDelegate(),
//       children: <IconData> [
//         Icons.play_arrow,
//         Icons.person,
//         Icons.emoji_events,
//         Icons.call
//       ].map<Widget>(buildFAB).toList(),
//     );
//   }
//
//   Widget buildFAB(IconData icon) {
//     return FloatingActionButton();
//   }
// }
//
// class FlowMenuDelegate extends FlowDelegate {
//   @override
//   void paintChildren(FlowPaintingContext context) {
//
//   }
//
//   @override
//   bool shouldRepaint(FlowMenuDelegate oldDelegate) {
//     return false;
//   }
// }
