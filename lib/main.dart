import 'package:flutter/material.dart';
import 'dart:async';
import 'package:collection/collection.dart';

const Color gridColor = Color.fromARGB(255, 187, 173, 160);
const Color emptyTileColor = Color.fromARGB(255, 205, 193, 180);
const Color tileTextColor = Color.fromARGB(255, 119, 110, 101);
const Color backgroundColor = Color.fromARGB(255, 250, 248, 239);

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

class Tile {
  int x;//
  int y;//
  int value;

  late Animation<double> animatedX; //
  late Animation<double> animatedY;
  late Animation<int> animatedValue;
  late Animation<double> scale;

  Tile(this.x, this.y, this.value) {
    resetAnimations();
  }

  void resetAnimations() {
    animatedX = AlwaysStoppedAnimation(x.toDouble());
    animatedY = AlwaysStoppedAnimation(y.toDouble());
    animatedValue = AlwaysStoppedAnimation(value);
    scale = AlwaysStoppedAnimation(1.0);

  }
}

class Game extends StatefulWidget {

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<Game> with SingleTickerProviderStateMixin {

  late AnimationController controller;

  // outside is y axis, inside is x axis
  List<List<Tile>> grid = List.generate(4, (y) =>
      List.generate(4, (x) =>
        Tile(x, y, 0)
      )
  );

  // flattening a list of lists, turning into 1D
  Iterable<Tile> get flatGrid => grid.expand((element) => element);
  // grid as a list of columns for swiping implementation
  Iterable<List<Tile>> get columns => List.generate(4, (x) =>
      List.generate(4, (y) => grid[y][x]));

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    controller.addStatusListener((status) {
      if ( status == AnimationStatus.completed) {
        //check later
        for (var element in flatGrid) {
          element.resetAnimations();
        }
      }
    });

    grid[1][2].value = 4;
    grid[3][2].value = 16;

    flatGrid.forEach((element) => element.resetAnimations());
  }

  @override
  Widget build(BuildContext context) {
    // adding some space between grid and edge of screen
    double gridSize = MediaQuery.of(context).size.width - (16.0 * 2);
    double tileSize = (gridSize - (4.0 * 2)) / 4.0;

    List<Widget> stackItems = [];
    stackItems.addAll(flatGrid.map((e) => Positioned(
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
              color: emptyTileColor
          ),
        )
      ),
    )));

    stackItems.addAll(flatGrid.map((e) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) => e.animatedValue.value == 0 ? SizedBox() : Positioned(
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
        ))));

    bool canSwipe(List<Tile> tiles) {
      for (int i = 0; i < tiles.length; ++i) {
        // if there is an empty spot
        if (tiles[i].value == 0) {
          // checks if rest of the tiles are not 0, "is there a tile to move"
          if (tiles.skip(i + 1).any((element) => element.value != 0)) {
            return true;
          }
        }
        else {
          Tile? nextNonZero = tiles.skip(i + 1).firstWhereOrNull((element) =>
          element.value != 0);

          // check this later
          // tiles can merge
          if (nextNonZero != null && nextNonZero.value == tiles[i].value) {
            return true;
          }
        }
      }
      return false;
    }

    bool canSwipeUp() => columns.any(canSwipe);
    bool canSwipeDown() => columns.map((e) => e.reversed.toList()).any(canSwipe);
    bool canSwipeLeft() => grid.any(canSwipe);
    bool canSwipeRight() => grid.map((e) => e.reversed.toList()).any(canSwipe);

    void doSwipe(void Function() swipeDirectionFunction) {
      setState(() {
        swipeDirectionFunction();

        controller.forward(from: 0);
      });
    }

    // This is a decently complicated algorithm which I have mostly sourced from THKP
    // The credit of the logic goes to them
    void mergeTiles(List<Tile> tiles) {
      for (int i = 0; i < tiles.length; ++i) {
        // this is assuming that we have already confirmed a merge/swipe, so we
        // ignore empty spaces
        Iterable<Tile> toCheck = tiles.skip(i).skipWhile((value) => value.value == 0);
        if (toCheck.isNotEmpty) {
          Tile t = toCheck.first;
          Tile? mergeT = toCheck.skip(1).firstWhereOrNull((element) => element.value != 0);
          if (mergeT != null && mergeT.value != t.value) {
            mergeT = null;
          }
          if (tiles[i] != t || mergeT != null) {
            int resultValue = t.value;
            if (mergeT != null) {
              resultValue += mergeT.value;
              mergeT.value = 0;
            }
            t.value = 0;
            tiles[i].value = resultValue;
          }
        }
      }
    }

    void swipeUp() => columns.forEach(mergeTiles);
    void swipeDown() => columns.map((e) => e.reversed.toList()).forEach(mergeTiles);
    void swipeLeft() => grid.forEach(mergeTiles);
    void swipeRight() => grid.map((e) => e.reversed.toList()).forEach(mergeTiles);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Container(
          width: gridSize,
          height: gridSize,
          padding: const EdgeInsets.all(4.0),//
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: gridColor
          ),
          child: GestureDetector(
            child: Stack(children: stackItems),
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -200 && canSwipeUp()) {
                doSwipe(swipeUp);
              }
              else if (details.velocity.pixelsPerSecond.dy > 200 && canSwipeDown()) {
                doSwipe(swipeDown);
              }
            },
            onHorizontalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dx < -200 && canSwipeLeft()) {
                doSwipe(swipeLeft);
              }
              else if (details.velocity.pixelsPerSecond.dx > 200 && canSwipeRight()) {
                doSwipe(swipeRight);
              }
            },
          ),
        )
      ),
    );
  }
}
