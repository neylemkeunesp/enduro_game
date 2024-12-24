import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'road_painter.dart';
import 'car_widget.dart';
import 'dashboard_painter.dart';

void main() {
  runApp(const EnduroGame());
}

class EnduroGame extends StatelessWidget {
  const EnduroGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enduro Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _carController;
  late Animation<double> _carAnimation;
  double _carX = 0; // Screen position, will be set in initState
  double _carBaseX = 0; // Base position before perspective, will be set in initState
  double _carY = 450; // Position car near bottom
  double _roadWidth = 300;
  double _roadHeight = 600; // Back to original height
  double _roadX = 0; // Will be set in initState based on screen width
  double _roadY = 0; // Will be set in initState based on screen height
  double _carSpeed = 0;
  double _maxSpeed = 300;
  double _acceleration = 10;
  double _deceleration = 5;
  double _obstacleSpeed = 100;
  List<Obstacle> _obstacles = [];
  Random _random = Random();
  bool _isGameOver = false;
  bool _isGameStarted = false;
  int _score = 0;
  int _distance = 0;
  int _level = 1;
  Timer? _gameTimer;
  Timer? _collisionTimer;

  double _calculateScale(double position) {
    // Match the car widget scaling for consistent sizes
    return 0.4 + (0.8 * position * position);
  }

  void startGame() {
    setState(() {
      _isGameStarted = true;
      _carSpeed = 20;
      _score = 0;
      _distance = 0;
      _level = 1;
      _obstacles.clear();
    });
    
    _gameTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!_isGameOver) {
        setState(() {
          _distance += (_carSpeed / 10).round();
          if (_distance % 1000 == 0) {
            _level++;
            _maxSpeed += 50;
            _obstacleSpeed += 20;
          }
          _score = _distance ~/ 10;
        });
      }
    });

    _collisionTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (_isGameStarted && !_isGameOver) {
        _checkCollisions();
      }
    });
    
    _generateObstacle();
    _startObstacleAnimation();
  }

  // Calculate x position with perspective
  double _calculateXPosition(double baseX, double y) {
    final vanishingPointX = _roadWidth / 2 + _roadX;
    final perspective = y / _roadHeight;
    return vanishingPointX + (baseX - vanishingPointX) * perspective;
  }

  @override
  void initState() {
    super.initState();
    
    // Get screen width to center the road
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      setState(() {
        final screenHeight = MediaQuery.of(context).size.height;
        _roadX = (screenWidth - _roadWidth) / 2;
        _roadY = (screenHeight - _roadHeight) / 2;
        // Center the car in the middle lane
        _carBaseX = _roadX + (_roadWidth / 2) - 40;
        _carY = _roadY + _roadHeight - 150; // Position car near bottom of road
        _carX = _calculateXPosition(_carBaseX, _carY);
      });
    });
    
    _carController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _carAnimation = Tween<double>(begin: 0, end: 1).animate(_carController)
      ..addListener(() {
        setState(() {});
      });
    _carController.repeat();
  }

  void _generateObstacle() {
    if (_isGameStarted && !_isGameOver) {
      int lane = _random.nextInt(3);
      double laneWidth = _roadWidth / 3;
      // Calculate base position for each lane
      double baseX = _roadX;
      switch (lane) {
        case 0: // Left lane
          baseX = _roadX + (laneWidth / 2) - 40;
          break;
        case 1: // Middle lane
          baseX = _roadX + (_roadWidth / 2) - 40;
          break;
        case 2: // Right lane
          baseX = _roadX + _roadWidth - (laneWidth / 2) - 40;
          break;
      }
      double obstacleX = _calculateXPosition(baseX, _roadY);
      double obstacleY = _roadY;
      _obstacles.add(Obstacle(x: obstacleX, y: obstacleY, baseX: baseX));
    }
    Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(1000)), () {
      _generateObstacle();
    });
  }

  void _startObstacleAnimation() {
    Future.delayed(Duration(milliseconds: 16), () {
      setState(() {
        if (!_isGameOver) {
          for (var obstacle in _obstacles) {
            obstacle.y += _obstacleSpeed * 0.01;
            // Update x position with perspective
            obstacle.x = _calculateXPosition(obstacle.baseX, obstacle.y);
          }
          _obstacles.removeWhere((obstacle) => obstacle.y > _roadY + _roadHeight);
        }
      });
      _startObstacleAnimation();
    });
  }

  @override
  void dispose() {
    _carController.dispose();
    _gameTimer?.cancel();
    _collisionTimer?.cancel();
    super.dispose();
  }

  void _handleKeyDown(RawKeyEvent event) {
    if (!_isGameStarted) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        startGame();
      }
      return;
    }

    if (_isGameOver) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_carSpeed < _maxSpeed) {
          _carSpeed += _acceleration;
        }
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _carSpeed = max(0, _carSpeed - _deceleration);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _carBaseX = max(_roadX, _carBaseX - 10);
        _carX = _calculateXPosition(_carBaseX, _carY);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _carBaseX = min(_roadX + _roadWidth - 80, _carBaseX + 10);
        _carX = _calculateXPosition(_carBaseX, _carY);
      });
    }
  }

  void _checkCollisions() {
    if (!_isGameStarted || _isGameOver) return;

    final carScale = _calculateScale((_carY - _roadY) / _roadHeight);
    final carHitbox = RRect.fromRectAndRadius(
      Rect.fromLTWH(_carX + 10, _carY + 10, 60 * carScale, 60 * carScale),
      Radius.circular(20),
    );

    for (var obstacle in _obstacles) {
      final obstacleScale = _calculateScale((obstacle.y - _roadY) / _roadHeight);
      final obstacleHitbox = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          obstacle.x + 10,
          obstacle.y + 10,
          40 * obstacleScale,
          40 * obstacleScale,
        ),
        Radius.circular(20),
      );

      if (_checkRRectCollision(carHitbox, obstacleHitbox)) {
        setState(() {
          _isGameOver = true;
          _gameTimer?.cancel();
          _collisionTimer?.cancel();
        });

        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            _isGameOver = false;
            _isGameStarted = false;
            _carBaseX = _roadX + (_roadWidth / 2) - 40;
            _carX = _calculateXPosition(_carBaseX, _carY);
            _carY = _roadY + _roadHeight - 150; // Reset to starting position
            _carSpeed = 0;
            _obstacles.clear();
          });
        });
        break;
      }
    }
  }

  bool _checkRRectCollision(RRect a, RRect b) {
    if (a.left > b.right || b.left > a.right) return false;
    if (a.top > b.bottom || b.top > a.bottom) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyDown,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enduro Game'),
        ),
        body: Stack(
          children: [
            // Road background
            Positioned(
              left: _roadX,
              top: _roadY,
              child: Container(
                width: _roadWidth,
                height: _roadHeight,
                color: Colors.grey[800],
                child: CustomPaint(
                  painter: RoadPainter(
                    laneWidth: _roadWidth / 3,
                    animate: _isGameStarted && !_isGameOver,
                    speed: _carSpeed,
                  ),
                ),
              ),
            ),
            // Player Car
            Positioned(
              left: _carX,
              top: _carY,
              child: EnduroCar(
                isPlayer: true,
                screenPosition: _carY / _roadHeight,
              ),
            ),
            // Enemy Cars
            ..._obstacles.map((obstacle) => Positioned(
              left: obstacle.x,
              top: obstacle.y,
              child: EnduroCar(
                isPlayer: false,
                screenPosition: obstacle.y / _roadHeight,
              ),
            )),
            // Dashboard
            Positioned(
              left: _roadX + _roadWidth + 10,
              top: _roadY,
              child: Container(
                width: 200,
                height: 300,
                child: CustomPaint(
                  painter: DashboardPainter(
                    speed: _carSpeed,
                    distance: _distance,
                    level: _level,
                  ),
                ),
              ),
            ),
            if (!_isGameStarted && !_isGameOver)
              Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Enduro Racing',
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Press SPACE to start\n'
                        'Use arrow keys to control:\n'
                        '↑ Accelerate\n'
                        '↓ Brake\n'
                        '← → Steer',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            
            if (_isGameOver)
              Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Game Over!',
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Final Score: $_score',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Obstacle {
  double x;
  double y;
  double baseX; // Store the base x position before perspective
  Obstacle({required this.x, required this.y, required this.baseX});
}
