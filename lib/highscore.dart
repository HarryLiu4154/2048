// credit for most of this class goes to medium.com
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Highscore {
  final String username;
  final int score;

  Highscore({
    required this.username,
    required this.score
  });

  Map<String, dynamic> toMap() {
    return {
      "username": username,
      "score": score,
    };
  }

  factory Highscore.fromMap(Map<String, dynamic> map) {
    return Highscore(username: map['username'] as String, score: map['score'] as int);
  }

  void saveScore() async {
    final prefs = await SharedPreferences.getInstance();

    String? initialHighscores = prefs.getString("highscores");
    List currentHighScores = [];
    Map map = toMap();

    if (initialHighscores != null) {
      currentHighScores = jsonDecode(initialHighscores);
    }

    currentHighScores.add(map);

    currentHighScores.sort((int1, int2) => (int2["score"]).compareTo(int1["score"]));
    currentHighScores = currentHighScores.take(10).toList();

    await prefs.setString("highscores", jsonEncode(currentHighScores));
  }
}
