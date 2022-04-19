import 'package:flutter/material.dart';

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
    scale = const AlwaysStoppedAnimation(1.0);
  }

  void move(Animation<double> parent, int x, int y) {
    // tween from current location to the desired location
    animatedX = Tween(begin: this.x.toDouble(), end: x.toDouble())
        .animate(CurvedAnimation(parent: parent, curve: const Interval(0, 0.5)));
    animatedY = Tween(begin: this.y.toDouble(), end: y.toDouble())
        .animate(CurvedAnimation(parent: parent, curve: const Interval(0, 0.5)));
  }

  // small "pop" animation at the end of a merge
  void bounce(Animation<double> parent) {
    scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1.0),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1.0)
    ]).animate(CurvedAnimation(parent: parent, curve: const Interval(0.5, 1.0)));
  }

  // animation for new tile appearing
  void appear(Animation<double> parent) {
    scale = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: parent, curve: const Interval(0.5, 1.0)));
  }

  void changeTileValue(Animation<double> parent, int newValue) {
    animatedValue = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(value), weight: 0.01),
      TweenSequenceItem(tween: ConstantTween(newValue), weight: 0.99)
    ]).animate(CurvedAnimation(parent: parent, curve: const Interval(0.5, 1.0)));
  }
}
