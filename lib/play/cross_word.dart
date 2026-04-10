import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:elearningapp_flutter/services/firebase_leaderboard_service.dart';
import 'package:elearningapp_flutter/services/audio_service.dart'; // ← ADDED

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class CrosswordWord {
  final String word;
  final String clue;
  final String dir;
  int row;
  int col;
  int number;
  bool solved;

  CrosswordWord({
    required this.word,
    required this.clue,
    required this.dir,
    this.row = 0,
    this.col = 0,
    this.number = 0,
    this.solved = false,
  });
}

class CrosswordTopic {
  final String id;
  final String name;
  final String icon;
  final String desc;
  final List<CrosswordWord> words;

  const CrosswordTopic({
    required this.id,
    required this.name,
    required this.icon,
    required this.desc,
    required this.words,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME DATA  (Grade-6 friendly clues)
// ─────────────────────────────────────────────────────────────────────────────

class CrosswordGameData {
  static final List<CrosswordTopic> topics = [
    CrosswordTopic(
      id: 'photosynthesis',
      name: 'Photosynthesis',
      icon: '🌱',
      desc: 'How plants make food',
      words: [
        CrosswordWord(
          word: 'CHLOROPHYLL',
          clue: 'The green stuff inside leaves that catches sunlight',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'SUNLIGHT',
          clue: 'The bright energy from the sky that plants need to grow',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'GLUCOSE',
          clue: 'The sweet sugar a plant makes using sunlight and water',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'OXYGEN',
          clue: 'The gas plants release that we breathe in every day',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'CARBON',
          clue: 'The "C" in CO2 — a gas plants suck in from the air',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'STOMATA',
          clue: 'Tiny holes on the bottom of leaves that let air in and out',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'LEAF',
          clue: 'The flat green part of a plant where most food is made',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'WATER',
          clue: 'Plants drink this through their roots from the soil',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'ENERGY',
          clue: 'Plants get this from sunlight to power food-making',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'ROOT',
          clue: 'The underground part of a plant that soaks up water',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'STEM',
          clue: 'The stalk that carries water up from roots to leaves',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'VAPOR',
          clue: 'Tiny invisible water droplets that plants breathe out',
          dir: 'down',
        ),
      ],
    ),
    CrosswordTopic(
      id: 'solar',
      name: 'Solar System',
      icon: '🪐',
      desc: 'Planets and space',
      words: [
        CrosswordWord(
          word: 'MERCURY',
          clue: 'The smallest planet and the closest one to the Sun',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'VENUS',
          clue: 'The hottest planet — even hotter than Mercury!',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'ORBIT',
          clue: 'The curved path a planet travels around the Sun',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'GRAVITY',
          clue:
              'The invisible pulling force that keeps planets circling the Sun',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'ASTEROID',
          clue: 'A big rocky chunk floating in space between Mars and Jupiter',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'COMET',
          clue: 'A ball of ice and rock with a bright glowing tail',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'GALAXY',
          clue:
              'A giant family of billions of stars — we live in the Milky Way',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'SATURN',
          clue: 'The planet with beautiful rings made of ice and rock',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'MOON',
          clue: 'A natural object that circles a planet — Earth has one!',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'LIGHT',
          clue: 'It takes 8 minutes for this to travel from the Sun to Earth',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'MARS',
          clue:
              'The red planet — scientists dream of sending people there someday',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'STAR',
          clue: 'A huge ball of burning gas in space — our Sun is one of these',
          dir: 'down',
        ),
      ],
    ),
    CrosswordTopic(
      id: 'matter',
      name: 'Changes of Matter',
      icon: '💧',
      desc: 'States and changes',
      words: [
        CrosswordWord(
          word: 'SOLID',
          clue: 'Ice is this state — it has a fixed shape you can hold',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'LIQUID',
          clue: 'Water is this state — it flows and fills any container',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'MELTING',
          clue: 'What happens to ice cream left out on a hot sunny day',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'FREEZING',
          clue: 'When liquid water turns into ice in the freezer',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'EVAPORATION',
          clue: 'Why puddles slowly disappear on a warm sunny day',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'CONDENSATION',
          clue: 'The water droplets that form on the outside of a cold glass',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'DENSITY',
          clue:
              'How heavy something is for its size — iron sinks but wood floats',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'ATOMS',
          clue:
              'The super-tiny building blocks that make up everything around you',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'MIXTURE',
          clue:
              'Salt and pepper stirred together — they are not chemically joined',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'SOLUTION',
          clue:
              'What you get when salt stirs into water and seems to disappear',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'PLASMA',
          clue: 'The super-hot fourth state of matter found inside stars',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'MOLECULE',
          clue: 'Two or more atoms stuck together — H2O is one for water',
          dir: 'down',
        ),
      ],
    ),
    CrosswordTopic(
      id: 'foodchain',
      name: 'Food Chain',
      icon: '🦁',
      desc: 'Energy in ecosystems',
      words: [
        CrosswordWord(
          word: 'PRODUCER',
          clue:
              'A plant that makes its own food using sunlight — starts every food chain',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'CONSUMER',
          clue: 'Any animal that has to eat other things to get energy',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'HERBIVORE',
          clue: 'An animal that only munches on plants — like a rabbit or cow',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'CARNIVORE',
          clue: 'An animal that only eats other animals — like a lion or shark',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'PREDATOR',
          clue: 'The hunter in a food chain that chases and catches others',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'PREY',
          clue: 'The animal being chased and eaten by a predator',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'DECOMPOSER',
          clue:
              'Mushrooms and bacteria that break down dead plants and animals',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'ENERGY',
          clue: 'This gets passed from plants to animals along a food chain',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'ECOSYSTEM',
          clue:
              'All the living things in one place and how they help each other',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'HABITAT',
          clue:
              'The natural home where an animal lives — like a rainforest or reef',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'OMNIVORE',
          clue:
              'An animal that eats both plants and meat — like a bear or human',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'NICHE',
          clue: 'The special job or role an organism plays in its ecosystem',
          dir: 'down',
        ),
      ],
    ),
    CrosswordTopic(
      id: 'watercycle',
      name: 'Water Cycle',
      icon: '🌊',
      desc: "Earth's water journey",
      words: [
        CrosswordWord(
          word: 'EVAPORATION',
          clue:
              'When the Sun heats water in the ocean and turns it into invisible vapour',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'CONDENSATION',
          clue: 'When water vapour cools high in the sky and forms clouds',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'PRECIPITATION',
          clue: 'Rain, snow, sleet, or hail — all water falling from clouds',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'RUNOFF',
          clue:
              'Rainwater that flows over the ground and into rivers and streams',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'GROUNDWATER',
          clue: 'Rain that soaks deep into the earth and is stored underground',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'TRANSPIRATION',
          clue:
              'When plants release water vapour through tiny holes in their leaves',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'INFILTRATION',
          clue: 'When rainwater soaks slowly down through soil and rock',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'GLACIER',
          clue: 'A massive slow-moving river of ice found in cold mountains',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'WATERSHED',
          clue: 'All the land that drains its rain into the same river or lake',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'HUMIDITY',
          clue:
              'How much water vapour is in the air — a muggy day has lots of this',
          dir: 'down',
        ),
        CrosswordWord(
          word: 'AQUIFER',
          clue: 'An underground layer of rock that stores water like a sponge',
          dir: 'across',
        ),
        CrosswordWord(
          word: 'CLOUD',
          clue:
              'A fluffy white mass of tiny water droplets floating in the sky',
          dir: 'down',
        ),
      ],
    ),
  ];

  static const Map<String, Map<String, dynamic>> difficulties = {
    'easy': {'words': 5, 'time': 180, 'label': 'Easy'},
    'medium': {'words': 8, 'time': 240, 'label': 'Medium'},
    'hard': {'words': 12, 'time': 360, 'label': 'Hard'},
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// CROSSWORD BUILDER
// ─────────────────────────────────────────────────────────────────────────────

class CrosswordBuilder {
  static const int SIZE = 30;

  static List<CrosswordWord> buildPuzzle(List<CrosswordWord> words) {
    final grid = List.generate(SIZE, (_) => List<String?>.filled(SIZE, null));
    final placed = <CrosswordWord>[];

    bool canPlace(CrosswordWord w, int r, int c) {
      for (int i = 0; i < w.word.length; i++) {
        final rr = w.dir == 'across' ? r : r + i;
        final cc = w.dir == 'down' ? c : c + i;
        if (rr < 0 || rr >= SIZE || cc < 0 || cc >= SIZE) return false;
        final cell = grid[rr][cc];
        if (cell != null && cell != w.word[i]) return false;
        if (w.dir == 'across') {
          if (i == 0 && cc > 0 && grid[rr][cc - 1] != null) return false;
          if (i == w.word.length - 1 &&
              cc + 1 < SIZE &&
              grid[rr][cc + 1] != null)
            return false;
          if (cell != w.word[i]) {
            if (rr > 0 && grid[rr - 1][cc] != null) return false;
            if (rr + 1 < SIZE && grid[rr + 1][cc] != null) return false;
          }
        } else {
          if (i == 0 && rr > 0 && grid[rr - 1][cc] != null) return false;
          if (i == w.word.length - 1 &&
              rr + 1 < SIZE &&
              grid[rr + 1][cc] != null)
            return false;
          if (cell != w.word[i]) {
            if (cc > 0 && grid[rr][cc - 1] != null) return false;
            if (cc + 1 < SIZE && grid[rr][cc + 1] != null) return false;
          }
        }
      }
      return true;
    }

    void doPlace(CrosswordWord w, int r, int c) {
      w.row = r;
      w.col = c;
      for (int i = 0; i < w.word.length; i++) {
        final rr = w.dir == 'across' ? r : r + i;
        final cc = w.dir == 'down' ? c : c + i;
        grid[rr][cc] = w.word[i];
      }
      placed.add(w);
    }

    final mid = SIZE ~/ 2;
    final first = words[0];
    doPlace(first, mid, mid - first.word.length ~/ 2);

    final rng = Random();
    for (int wi = 1; wi < words.length; wi++) {
      final w = words[wi];
      int bestScore = -1, bestR = 0, bestC = 0;
      for (final p in placed) {
        for (int pi = 0; pi < p.word.length; pi++) {
          final ch = p.word[pi];
          for (int wi2 = 0; wi2 < w.word.length; wi2++) {
            if (w.word[wi2] != ch) continue;
            int r, c;
            if (w.dir == 'across' && p.dir == 'down') {
              r = p.row + pi;
              c = p.col - wi2;
            } else if (w.dir == 'down' && p.dir == 'across') {
              r = p.row - wi2;
              c = p.col + pi;
            } else {
              continue;
            }
            if (canPlace(w, r, c)) {
              final score = wi2 + pi;
              if (score > bestScore) {
                bestScore = score;
                bestR = r;
                bestC = c;
              }
            }
          }
        }
      }
      if (bestScore >= 0) {
        doPlace(w, bestR, bestC);
      } else {
        bool placedFallback = false;
        for (int attempt = 0; attempt < 200 && !placedFallback; attempt++) {
          final r = rng.nextInt(SIZE);
          final c = rng.nextInt(SIZE);
          if (canPlace(w, r, c)) {
            doPlace(w, r, c);
            placedFallback = true;
          }
        }
      }
    }

    int minR = SIZE, maxR = 0, minC = SIZE, maxC = 0;
    for (final p in placed) {
      minR = min(minR, p.row);
      maxR = max(maxR, p.dir == 'down' ? p.row + p.word.length - 1 : p.row);
      minC = min(minC, p.col);
      maxC = max(maxC, p.dir == 'across' ? p.col + p.word.length - 1 : p.col);
    }
    const pad = 1;
    minR = max(0, minR - pad);
    minC = max(0, minC - pad);
    for (final p in placed) {
      p.row -= minR;
      p.col -= minC;
    }

    final starts = <String, List<CrosswordWord>>{};
    for (final p in placed) {
      starts.putIfAbsent('${p.row},${p.col}', () => []).add(p);
    }
    int num = 1;
    final rows = (maxR - minR + 1 + pad * 2).clamp(1, SIZE);
    final cols = (maxC - minC + 1 + pad * 2).clamp(1, SIZE);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final key = '$r,$c';
        if (starts.containsKey(key)) {
          for (final p in starts[key]!) p.number = num;
          num++;
        }
      }
    }
    return placed;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

class _C {
  static const bg = Color(0xFF0D102C);
  static const surface = Color(0xFF1C1F3E);
  static const surface2 = Color(0xFF252850);
  static const accent = Color(0xFF534AB7);
  static const accentBright = Color(0xFF7B4DFF);
  static const accentLight = Color(0xFF9B8DFF);
  static const green = Color(0xFF1D9E75);
  static const greenDark = Color(0xFF1D4A2A);
  static const amber = Color(0xFFEF9F27);
  static const amberDark = Color(0xFFBA7517);
  static const red = Color(0xFFA32D2D);
  static const redLight = Color(0xFFE24B4A);
  static const white = Colors.white;
  static const w90 = Color(0xFFE8E8F0);
  static const w70 = Color(0xFFB0AFCC);
  static const w54 = Color(0xFF8A89A8);
  static const w38 = Color(0xFF5E5D7A);
  static const w12 = Color(0xFF1E2045);
  static const w08 = Color(0xFF161835);
  static const solved = Color(0xFF1D4A2A);
  static const solvedText = Color(0xFF4CAF50);
  static const active = Color(0xFF2D2560);
  static const timerOk = Color(0xFF534AB7);
  static const timerWarn = Color(0xFFBA7517);
  static const timerBad = Color(0xFFA32D2D);

  // ── Grid-specific ──────────────────────────────────────────────────────────
  // Darker background behind the grid so cells stand out clearly
  static const gridBg = Color(0xFF07091A);
  // Visible border between cells
  static const gridLine = Color(0xFF3A3D6A);
  // Border for active-word cells
  static const gridLineActive = Color(0xFF7B4DFF);
  // Empty cell (not part of any word) fill — very subtle, just enough to show gaps
  static const gridEmpty = Color(0xFF0A0C1F);
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class ScienceCrosswordScreen extends StatefulWidget {
  final String role;
  const ScienceCrosswordScreen({super.key, required this.role});

  @override
  State<ScienceCrosswordScreen> createState() => _ScienceCrosswordScreenState();
}

enum GamePhase { topicSelect, playing, result }

class _ScienceCrosswordScreenState extends State<ScienceCrosswordScreen>
    with TickerProviderStateMixin {
  GamePhase _phase = GamePhase.topicSelect;

  CrosswordTopic? _selectedTopic;
  String? _selectedDiff;

  List<CrosswordWord> _puzzleWords = [];
  Map<String, String> _userLetters = {};
  Set<int> _solvedIndices = {};
  int _activeWordIdx = 0;
  int _score = 0;
  int _hintsLeft = 5;
  int _hintsUsed = 0;
  int _wrongAttempts = 0;
  int _timeLeft = 0;
  int _maxTime = 0;
  Timer? _timer;

  List<List<String?>> _grid = [];
  int _gridH = 0;
  int _gridW = 0;

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _gridScrollCtrl = ScrollController();

  int _finalScore = 0;
  int _timeBonus = 0;

  Map<String, Color> _flashCells = {};

  @override
  void dispose() {
    _timer?.cancel();
    _inputCtrl.dispose();
    _gridScrollCtrl.dispose();
    super.dispose();
  }

  // ── Start game ────────────────────────────────────────────────────────────

  void _startGame() {
    final topic = _selectedTopic!;
    final diff = _selectedDiff!;
    final count = CrosswordGameData.difficulties[diff]!['words'] as int;
    final timeAlloc = CrosswordGameData.difficulties[diff]!['time'] as int;

    final pool = [...topic.words]..shuffle(Random());
    final picked =
        pool
            .take(count)
            .map((w) => CrosswordWord(word: w.word, clue: w.clue, dir: w.dir))
            .toList();

    final placed = CrosswordBuilder.buildPuzzle(picked);

    int maxR = 0, maxC = 0;
    for (final p in placed) {
      maxR = max(maxR, p.dir == 'down' ? p.row + p.word.length - 1 : p.row);
      maxC = max(maxC, p.dir == 'across' ? p.col + p.word.length - 1 : p.col);
    }
    _gridH = maxR + 2;
    _gridW = maxC + 2;
    _grid = List.generate(_gridH, (_) => List.filled(_gridW, null));
    for (final p in placed) {
      for (int i = 0; i < p.word.length; i++) {
        final r = p.dir == 'across' ? p.row : p.row + i;
        final c = p.dir == 'down' ? p.col : p.col + i;
        if (r < _gridH && c < _gridW) _grid[r][c] = p.word[i];
      }
    }

    setState(() {
      _puzzleWords = placed;
      _userLetters = {};
      _solvedIndices = {};
      _flashCells = {};
      _activeWordIdx = 0;
      _score = 0;
      _hintsLeft = 5;
      _hintsUsed = 0;
      _wrongAttempts = 0;
      _timeLeft = timeAlloc;
      _maxTime = timeAlloc;
      _phase = GamePhase.playing;
    });
    _inputCtrl.clear();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _timer?.cancel();
        _finishGame(false);
      }
    });
  }

  // ── Answer logic ──────────────────────────────────────────────────────────

  void _checkAnswer() {
    final input = _inputCtrl.text.trim().toUpperCase();
    if (input.isEmpty) return;
    final pw = _puzzleWords[_activeWordIdx];
    if (_solvedIndices.contains(_activeWordIdx)) {
      _showSnack('Already solved!', _C.accent);
      return;
    }
    if (input == pw.word) {
      // ── CORRECT ──────────────────────────────────────────────────────────
      AudioService.playSoundEffect('tile.wav'); // ← CORRECT SOUND
      final base = pw.word.length * 5;
      final bonus = (_timeLeft / _maxTime * pw.word.length * 3).floor();
      final pts = base + bonus;
      _solvedIndices.add(_activeWordIdx);

      final cells = <String>[];
      for (int i = 0; i < pw.word.length; i++) {
        final r = pw.dir == 'across' ? pw.row : pw.row + i;
        final c = pw.dir == 'down' ? pw.col : pw.col + i;
        _userLetters['$r,$c'] = pw.word[i];
        cells.add('$r,$c');
      }

      setState(() {
        _score += pts;
        for (final k in cells) _flashCells[k] = _C.green;
      });

      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          for (final k in cells) _flashCells.remove(k);
        });
      });

      _showSnack('Correct! +$pts pts', _C.green);
      _inputCtrl.clear();
      HapticFeedback.mediumImpact();

      if (_solvedIndices.length == _puzzleWords.length) {
        _timer?.cancel();
        Future.delayed(
          const Duration(milliseconds: 600),
          () => _finishGame(true),
        );
      } else {
        Future.delayed(const Duration(milliseconds: 400), _autoNextWord);
      }
    } else {
      // ── WRONG ────────────────────────────────────────────────────────────
      AudioService.playSoundEffect('error.wav'); // ← WRONG SOUND
      setState(() => _wrongAttempts++);
      _showSnack('Not quite — try again!', _C.amber);
      HapticFeedback.lightImpact();
    }
  }

  void _useHint() {
    if (_hintsLeft <= 0) {
      _showSnack('No hints remaining!', _C.red);
      return;
    }
    final pw = _puzzleWords[_activeWordIdx];
    if (_solvedIndices.contains(_activeWordIdx)) {
      _showSnack('Already solved!', _C.accent);
      return;
    }

    final unrevealed = <int>[];
    for (int i = 0; i < pw.word.length; i++) {
      final r = pw.dir == 'across' ? pw.row : pw.row + i;
      final c = pw.dir == 'down' ? pw.col : pw.col + i;
      if (_userLetters['$r,$c'] != pw.word[i]) unrevealed.add(i);
    }
    if (unrevealed.isEmpty) {
      _showSnack('All letters already revealed!', _C.accent);
      return;
    }

    final ri = unrevealed[Random().nextInt(unrevealed.length)];
    final r = pw.dir == 'across' ? pw.row : pw.row + ri;
    final c = pw.dir == 'down' ? pw.col : pw.col + ri;

    AudioService.playSoundEffect('hint.wav'); // ← HINT SOUND

    setState(() {
      _userLetters['$r,$c'] = pw.word[ri];
      _hintsLeft--;
      _hintsUsed++;
      _score = max(0, _score - 10);
      _flashCells['$r,$c'] = _C.amber;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _flashCells.remove('$r,$c'));
    });
    _showSnack('Letter revealed! -10 pts | $_hintsLeft hints left', _C.amber);
  }

  void _autoNextWord() {
    for (int i = 1; i <= _puzzleWords.length; i++) {
      final ni = (_activeWordIdx + i) % _puzzleWords.length;
      if (!_solvedIndices.contains(ni)) {
        setState(() => _activeWordIdx = ni);
        _inputCtrl.clear();
        return;
      }
    }
  }

  void _finishGame(bool completed) async {
    final timeBonus = completed ? (_timeLeft * 0.5).floor() : 0;
    final finalScore = _score + timeBonus;
    setState(() {
      _finalScore = finalScore;
      _timeBonus = timeBonus;
      _score = finalScore;
      _phase = GamePhase.result;
    });
    try {
      await FirebaseLeaderboardService.saveScore(
        gameName: FirebaseLeaderboardService.GAME_CROSSWORD,
        score: finalScore,
        metadata: {
          'topic': _selectedTopic!.name,
          'difficulty': _selectedDiff,
          'solved': _solvedIndices.length,
          'total': _puzzleWords.length,
          'hintsUsed': _hintsUsed,
          'wrongAttempts': _wrongAttempts,
          'completed': completed,
        },
      );
    } catch (e) {
      debugPrint('Leaderboard save error: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'crossword_lb';
      final entries = jsonDecode(prefs.getString(key) ?? '[]') as List;
      entries.add({
        'topic': _selectedTopic!.name,
        'diff': _selectedDiff,
        'score': finalScore,
        'date': DateTime.now().toIso8601String(),
        'solved': _solvedIndices.length,
        'total': _puzzleWords.length,
      });
      entries.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      await prefs.setString(key, jsonEncode(entries.take(50).toList()));
    } catch (e) {
      debugPrint('Local save error: $e');
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _timerStr {
    final m = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    final pct = _maxTime > 0 ? _timeLeft / _maxTime : 1.0;
    if (pct > 0.4) return _C.timerOk;
    if (pct > 0.2) return _C.timerWarn;
    return _C.timerBad;
  }

  bool _cellBelongsToActive(int r, int c) {
    if (_activeWordIdx >= _puzzleWords.length) return false;
    final pw = _puzzleWords[_activeWordIdx];
    for (int i = 0; i < pw.word.length; i++) {
      final rr = pw.dir == 'across' ? pw.row : pw.row + i;
      final cc = pw.dir == 'down' ? pw.col : pw.col + i;
      if (rr == r && cc == c) return true;
    }
    return false;
  }

  int? _wordIndexForCell(int r, int c) {
    for (int i = 0; i < _puzzleWords.length; i++) {
      if (_solvedIndices.contains(i)) continue;
      final pw = _puzzleWords[i];
      for (int j = 0; j < pw.word.length; j++) {
        final rr = pw.dir == 'across' ? pw.row : pw.row + j;
        final cc = pw.dir == 'down' ? pw.col : pw.col + j;
        if (rr == r && cc == c) return i;
      }
    }
    return null;
  }

  int? _numberAtCell(int r, int c) {
    for (final pw in _puzzleWords) {
      if (pw.row == r && pw.col == c) return pw.number;
    }
    return null;
  }

  bool _isSolvedCell(int r, int c) {
    for (final i in _solvedIndices) {
      final pw = _puzzleWords[i];
      for (int j = 0; j < pw.word.length; j++) {
        final rr = pw.dir == 'across' ? pw.row : pw.row + j;
        final cc = pw.dir == 'down' ? pw.col : pw.col + j;
        if (rr == r && cc == c) return true;
      }
    }
    return false;
  }

  bool _cellBelongsToAny(int r, int c) {
    for (final pw in _puzzleWords) {
      for (int j = 0; j < pw.word.length; j++) {
        final rr = pw.dir == 'across' ? pw.row : pw.row + j;
        final cc = pw.dir == 'down' ? pw.col : pw.col + j;
        if (rr == r && cc == c) return true;
      }
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case GamePhase.topicSelect:
        return _buildTopicSelect();
      case GamePhase.playing:
        return _buildGameScreen();
      case GamePhase.result:
        return _buildResultScreen();
    }
  }

  // ── Topic Select ──────────────────────────────────────────────────────────

  Widget _buildTopicSelect() {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _appBar('Science Crossword'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Choose a Topic',
                    style: TextStyle(
                      color: _C.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Then pick a difficulty to begin',
                    style: TextStyle(color: _C.w54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: CrosswordGameData.topics.length,
              itemBuilder: (ctx, i) {
                final t = CrosswordGameData.topics[i];
                final sel = _selectedTopic?.id == t.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTopic = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: sel ? _C.accent.withOpacity(0.18) : _C.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel ? _C.accentBright : _C.w12,
                        width: sel ? 2 : 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t.icon, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 8),
                        Text(
                          t.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: sel ? _C.accentLight : _C.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t.desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _C.w54, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Difficulty',
              style: TextStyle(
                color: _C.w70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children:
                  CrosswordGameData.difficulties.entries.map((e) {
                    final sel = _selectedDiff == e.key;
                    final words = e.value['words'];
                    final time = e.value['time'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDiff = e.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.only(
                            right: e.key != 'hard' ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color:
                                sel ? _C.accent.withOpacity(0.15) : _C.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? _C.accentBright : _C.w12,
                              width: sel ? 2 : 0.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                e.value['label'] as String,
                                style: TextStyle(
                                  color: sel ? _C.accentLight : _C.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$words words',
                                style: const TextStyle(
                                  color: _C.w54,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${time}s',
                                style: const TextStyle(
                                  color: _C.w38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),
            AnimatedOpacity(
              opacity:
                  _selectedTopic != null && _selectedDiff != null ? 1.0 : 0.45,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed:
                    _selectedTopic != null && _selectedDiff != null
                        ? _startGame
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.accent,
                  disabledBackgroundColor: _C.surface,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedTopic != null && _selectedDiff != null
                      ? 'Start — ${_selectedTopic!.name} (${CrosswordGameData.difficulties[_selectedDiff!]!['label']})'
                      : 'Select a topic and difficulty',
                  style: const TextStyle(
                    color: _C.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.w12, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'How to score',
                    style: TextStyle(
                      color: _C.w70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _ScoringRow(icon: '✦', text: 'Word length × 5 base points'),
                  _ScoringRow(
                    icon: '⚡',
                    text: 'Speed bonus for answering early',
                  ),
                  _ScoringRow(
                    icon: '🏁',
                    text: 'Time bonus when puzzle is fully solved',
                  ),
                  _ScoringRow(
                    icon: '💡',
                    text: 'Hints cost 10 pts each — max 5 per game',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Game Screen ───────────────────────────────────────────────────────────

  Widget _buildGameScreen() {
    if (_puzzleWords.isEmpty) return const Scaffold(backgroundColor: _C.bg);
    final pw = _puzzleWords[_activeWordIdx];
    final pct = _maxTime > 0 ? _timeLeft / _maxTime : 0.0;
    final solvedCount = _solvedIndices.length;
    final total = _puzzleWords.length;

    return Scaffold(
      backgroundColor: _C.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _C.white),
          onPressed: () {
            _timer?.cancel();
            setState(() {
              _selectedTopic = null;
              _selectedDiff = null;
              _phase = GamePhase.topicSelect;
            });
          },
        ),
        title: Row(
          children: [
            Text(_selectedTopic!.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              _selectedTopic!.name,
              style: const TextStyle(
                color: _C.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        actions: [
          _HudChip(label: 'Score', value: '$_score', color: _C.accentLight),
          const SizedBox(width: 6),
          _HudChip(label: 'Hints', value: '$_hintsLeft/5', color: _C.amber),
          const SizedBox(width: 6),
          _HudChip(label: 'Time', value: _timerStr, color: _timerColor),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: _C.w08,
              valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Grid header ──────────────────────────────────────────
                  Row(
                    children: [
                      const Text(
                        'Crossword',
                        style: TextStyle(
                          color: _C.w70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _C.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _C.green.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '$solvedCount/$total',
                          style: const TextStyle(
                            color: _C.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? solvedCount / total : 0,
                            minHeight: 5,
                            backgroundColor: _C.w12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _C.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Grid container ───────────────────────────────────────
                  // Uses _C.gridBg (very dark) so the lighter cells pop out
                  Container(
                    decoration: BoxDecoration(
                      color: _C.gridBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.gridLine, width: 1),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildGrid(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Active clue card ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _C.accentBright.withOpacity(0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _C.accent.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${pw.number}-${pw.dir == "across" ? "Across" : "Down"}',
                                style: const TextStyle(
                                  color: _C.accentLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              pw.dir == 'across'
                                  ? Icons.arrow_forward
                                  : Icons.arrow_downward,
                              size: 14,
                              color: _C.accentLight,
                            ),
                            const Spacer(),
                            Text(
                              '${pw.word.length} letters',
                              style: const TextStyle(
                                color: _C.w38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pw.clue,
                          style: const TextStyle(
                            color: _C.w90,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: List.generate(pw.word.length, (i) {
                            final r = pw.dir == 'across' ? pw.row : pw.row + i;
                            final c = pw.dir == 'down' ? pw.col : pw.col + i;
                            final letter = _userLetters['$r,$c'] ?? '';
                            final filled = letter.isNotEmpty;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 26,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    filled
                                        ? _C.accentBright.withOpacity(0.15)
                                        : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: filled ? _C.accentBright : _C.w38,
                                    width: filled ? 2 : 1.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                letter,
                                style: TextStyle(
                                  color: filled ? _C.accentLight : _C.w54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Input row ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            color: _C.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                          onSubmitted: (_) => _checkAnswer(),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Type your answer…',
                            hintStyle: const TextStyle(
                              color: _C.w38,
                              letterSpacing: 0,
                              fontWeight: FontWeight.normal,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: _C.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: _C.accentBright,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            suffixIcon:
                                _inputCtrl.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      color: _C.w38,
                                      onPressed:
                                          () => setState(
                                            () => _inputCtrl.clear(),
                                          ),
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _checkAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Check',
                          style: TextStyle(
                            color: _C.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Nav + Hint ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _NavBtn(
                          label: '← Prev',
                          onPressed: () {
                            for (int i = 1; i <= _puzzleWords.length; i++) {
                              final ni =
                                  (_activeWordIdx - i + _puzzleWords.length) %
                                  _puzzleWords.length;
                              if (!_solvedIndices.contains(ni)) {
                                setState(() => _activeWordIdx = ni);
                                _inputCtrl.clear();
                                return;
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _NavBtn(
                          label: 'Next →',
                          onPressed: _autoNextWord,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _NavBtn(
                          label: '💡 Hint ($_hintsLeft)',
                          onPressed: _hintsLeft > 0 ? _useHint : null,
                          accentColor: _C.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildClueList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid ─────────────────────────────────────────────────────────────────
  // KEY CHANGES vs original:
  //   • gridBg container (very dark) makes cells contrast clearly
  //   • null cells use _C.gridEmpty (near-black) instead of transparent —
  //     stops them from blending into the container background
  //   • active cell border uses _C.gridLineActive (bright purple)
  //   • inactive cell border uses _C.gridLine (mid-tone, clearly visible)

  Widget _buildGrid() {
    const cellSize = 28.0; // slightly larger for better readability

    return Column(
      children: List.generate(_gridH, (r) {
        return Row(
          children: List.generate(_gridW, (c) {
            // ── Empty / spacer cell ──────────────────────────────────────
            if (_grid[r][c] == null) {
              return Container(
                width: cellSize,
                height: cellSize,
                color: _C.gridEmpty, // very dark but not transparent
              );
            }

            // ── Active word cell ─────────────────────────────────────────
            final isActive = _cellBelongsToActive(r, c);
            final isSolved = _isSolvedCell(r, c);
            final flashCol = _flashCells['$r,$c'];
            final numAtCell = _numberAtCell(r, c);
            final letter = _userLetters['$r,$c'] ?? '';

            Color bg;
            if (flashCol != null) {
              bg = flashCol.withOpacity(0.55);
            } else if (isSolved) {
              bg = _C.solved;
            } else if (isActive) {
              bg = _C.active;
            } else {
              bg = _C.surface; // noticeably lighter than gridBg
            }

            Color letterColor;
            if (isSolved) {
              letterColor = _C.solvedText;
            } else if (isActive) {
              letterColor = _C.accentLight;
            } else {
              letterColor = _C.w70;
            }

            // Border: bright for active, visible mid-tone for inactive
            final borderColor = isActive ? _C.gridLineActive : _C.gridLine;
            final borderWidth = isActive ? 1.5 : 1.0;

            return GestureDetector(
              onTap: () {
                final idx = _wordIndexForCell(r, c);
                if (idx != null) {
                  setState(() => _activeWordIdx = idx);
                  _inputCtrl.clear();
                } else if (_cellBelongsToAny(r, c)) {
                  for (int i = 0; i < _puzzleWords.length; i++) {
                    final pw = _puzzleWords[i];
                    for (int j = 0; j < pw.word.length; j++) {
                      final rr = pw.dir == 'across' ? pw.row : pw.row + j;
                      final cc = pw.dir == 'down' ? pw.col : pw.col + j;
                      if (rr == r && cc == c) {
                        setState(() => _activeWordIdx = i);
                        return;
                      }
                    }
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: Stack(
                  children: [
                    // Number badge
                    if (numAtCell != null)
                      Positioned(
                        top: 1,
                        left: 1.5,
                        child: Text(
                          '$numAtCell',
                          style: TextStyle(
                            color: isActive ? _C.accentLight : _C.w54,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Letter
                    Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          color: letterColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                    // Cursor bar for empty active cells
                    if (isActive && letter.isEmpty)
                      Positioned(
                        bottom: 0,
                        left: 4,
                        right: 4,
                        child: Container(
                          height: 2,
                          color: _C.accentBright.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  // ── Clue List ─────────────────────────────────────────────────────────────

  Widget _buildClueList() {
    final across =
        _puzzleWords.where((p) => p.dir == 'across').toList()
          ..sort((a, b) => a.number.compareTo(b.number));
    final down =
        _puzzleWords.where((p) => p.dir == 'down').toList()
          ..sort((a, b) => a.number.compareTo(b.number));

    Widget clueSection(String title, List<CrosswordWord> list, Color accent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withOpacity(0.2), width: 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  title == 'ACROSS'
                      ? Icons.arrow_forward
                      : Icons.arrow_downward,
                  size: 13,
                  color: accent,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${list.where((w) => _solvedIndices.contains(_puzzleWords.indexOf(w))).length}/${list.length}',
                  style: TextStyle(
                    color: accent.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...list.map((pw) {
            final idx = _puzzleWords.indexOf(pw);
            final isSolved = _solvedIndices.contains(idx);
            final isActive = idx == _activeWordIdx;
            return GestureDetector(
              onTap: () {
                setState(() => _activeWordIdx = idx);
                _inputCtrl.clear();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? _C.accent.withOpacity(0.12)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isActive
                            ? _C.accentBright.withOpacity(0.25)
                            : Colors.transparent,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color:
                            isSolved
                                ? _C.green.withOpacity(0.2)
                                : isActive
                                ? _C.accent
                                : _C.w08,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child:
                          isSolved
                              ? const Icon(
                                Icons.check,
                                color: _C.green,
                                size: 13,
                              )
                              : Text(
                                '${pw.number}',
                                style: TextStyle(
                                  color: isActive ? _C.white : _C.w54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pw.clue,
                        style: TextStyle(
                          color:
                              isSolved
                                  ? _C.w38
                                  : isActive
                                  ? _C.w90
                                  : _C.w70,
                          fontSize: 12,
                          decoration:
                              isSolved ? TextDecoration.lineThrough : null,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        clueSection('ACROSS', across, _C.accentBright),
        clueSection('DOWN', down, _C.green),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Result Screen ─────────────────────────────────────────────────────────

  Widget _buildResultScreen() {
    final pct =
        _puzzleWords.isNotEmpty
            ? (_solvedIndices.length / _puzzleWords.length * 100).round()
            : 0;
    final perfect = _solvedIndices.length == _puzzleWords.length;
    final goodJob = pct >= 50;
    final title =
        perfect
            ? 'Puzzle Complete!'
            : goodJob
            ? 'Good Effort!'
            : 'Keep Practicing!';
    final starCount =
        perfect
            ? 3
            : goodJob
            ? 2
            : 1;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _appBar('Results', automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    i < starCount
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < starCount ? _C.amber : _C.w38,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: _C.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedTopic!.icon}  ${_selectedTopic!.name}  ·  ${CrosswordGameData.difficulties[_selectedDiff!]!['label']}',
              style: const TextStyle(color: _C.w54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _C.accentBright.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total score',
                    style: TextStyle(color: _C.w54, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_finalScore',
                    style: const TextStyle(
                      color: _C.accentLight,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_timeBonus > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _C.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'includes +$_timeBonus time bonus',
                        style: const TextStyle(color: _C.green, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _StatCard(
                  '${_solvedIndices.length}/${_puzzleWords.length}',
                  'Words solved',
                  icon: Icons.grid_view_rounded,
                  color: _C.accentBright,
                ),
                _StatCard(
                  '$pct%',
                  'Completion',
                  icon: Icons.pie_chart_rounded,
                  color: _C.green,
                ),
                _StatCard(
                  '$_hintsUsed',
                  'Hints used',
                  icon: Icons.lightbulb_outline_rounded,
                  color: _C.amber,
                ),
                _StatCard(
                  '$_wrongAttempts',
                  'Wrong attempts',
                  icon: Icons.close_rounded,
                  color: _C.redLight,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.replay_rounded, size: 18, color: _C.white),
              label: const Text(
                'Play Again',
                style: TextStyle(
                  color: _C.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.accent,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed:
                  () => setState(() {
                    _selectedTopic = null;
                    _selectedDiff = null;
                    _phase = GamePhase.topicSelect;
                  }),
              icon: const Icon(Icons.grid_view_rounded, size: 16),
              label: const Text('Choose Another Topic'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.w70,
                side: const BorderSide(color: _C.w38, width: 0.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Shared AppBar ─────────────────────────────────────────────────────────

  AppBar _appBar(String title, {bool automaticallyImplyLeading = true}) {
    return AppBar(
      backgroundColor: _C.surface,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading:
          automaticallyImplyLeading
              ? IconButton(
                icon: const Icon(Icons.arrow_back, color: _C.w70),
                onPressed: () => Navigator.pop(context),
              )
              : null,
      title: Text(
        title,
        style: const TextStyle(
          color: _C.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _HudChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _HudChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? _C.white).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (color ?? _C.white).withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color ?? _C.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: _C.w38, fontSize: 9)),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? accentColor;
  const _NavBtn({required this.label, this.onPressed, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final col = accentColor ?? _C.w70;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        opacity: onPressed != null ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: col.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: col.withOpacity(0.25), width: 0.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: col,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoringRow extends StatelessWidget {
  final String icon;
  final String text;
  const _ScoringRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _C.w54, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard(
    this.value,
    this.label, {
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _C.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: _C.w54,
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
