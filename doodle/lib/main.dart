import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'screens/start_screen.dart';
import 'services/game_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GameState'i başlat
  final gameState = GameState();
  await gameState.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: GameState().languageNotifier,
      builder: (context, language, child) {
        return MaterialApp(
          title: GameState().t('app_title'),
          theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
          debugShowCheckedModeBanner: false,
          home: const StartScreen(),
        );
      },
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animasyonlu GIF arka plan
        Positioned.fill(
          child: Image.asset('assets/images/1.gif', fit: BoxFit.cover),
        ),
        // Oyun
        GameWidget<ZiplayanOyun>(
          game: ZiplayanOyun(),
          overlayBuilderMap: {
            'GameOverMenu': (BuildContext context, ZiplayanOyun game) {
              return Stack(
                children: [
                  // Blur Effect
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(color: Colors.black.withOpacity(0.4)),
                    ),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.purple.shade900.withOpacity(0.9),
                            Colors.deepPurple.shade800.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sentiment_very_dissatisfied,
                            size: 60,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            game.gameState.t('game_over'),
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.red.withOpacity(0.5),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  game.gameState.t('your_score'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '${game.score.toInt()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            '${game.gameState.t('high_score_title')}: ${game.highScore.toInt()}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGameButton(
                                icon: Icons.home_rounded,
                                color: Colors.blueGrey,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 20),
                              _buildGameButton(
                                icon: Icons.refresh_rounded,
                                color: Colors.green,
                                onTap: () => game.resetGame(),
                                isLarge: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          },
        ),
      ],
    );
  }

  Widget _buildGameButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 20 : 15),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: isLarge ? 40 : 30),
      ),
    );
  }
}

class ZiplayanOyun extends FlameGame with HasCollisionDetection, PanDetector {
  late Player player;
  late TextComponent scoreText;
  TextComponent? boostTimerText;
  final GameState gameState = GameState();
  double score = 0;
  double highScore = 0;
  double generatedHeight = 0;
  Random random = Random();
  bool isGameOver = false;

  // Accelerometer
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _accelerometerX = 0;

  // Boost State
  double scoreMultiplier = 1.0;
  bool isRocketActive = false;
  double rocketTimer = 0;
  double scoreBoostTimer = 0;
  static const double rocketDuration = 2.0; // 2 saniye
  static const double scoreBoostDuration = 3.0; // 3 saniye

  // Şeffaf arka plan ile başlat
  ZiplayanOyun() : super();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await images.loadAll(['tavsan.png', 'platform.png', 'dusman.png']);

    // Load High Score
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getDouble('highScore') ?? 0;

    // Start accelerometer if gyroscope mode is enabled
    _startAccelerometer();

    startGame();
  }

  void _startAccelerometer() {
    _accelerometerSubscription?.cancel();
    if (gameState.useGyroscope) {
      _accelerometerSubscription = accelerometerEventStream().listen((event) {
        // event.x is negative when tilting right, positive when tilting left
        _accelerometerX = event.x;
      });
    }
  }

  @override
  void onRemove() {
    _accelerometerSubscription?.cancel();
    super.onRemove();
  }

  void startGame() {
    removeAll(children);
    isGameOver = false;
    score = 0;
    generatedHeight = 0;

    // Reset boost states
    scoreMultiplier = 1.0;
    isRocketActive = false;
    rocketTimer = 0;
    scoreBoostTimer = 0;

    resumeEngine();

    // 1. Başlangıç Platformu (Tam Orta Alt)
    double currentY = size.y - 100;
    add(Platform(position: Vector2(size.x / 2, currentY)));

    // 2. --- KRİTİK DÜZELTME: BAŞLANGIÇ PLATFORMLARI ---
    // Ekranın en tepesine kadar (hatta biraz daha yukarı) platform dolduruyoruz.
    // Böylece karakterin zıplayacak yeri oluyor.
    while (currentY > -500) {
      // Ekranın 500 birim yukarısına kadar üret
      currentY -= 100; // Platform aralığını 100'e düşürdüm (Daha sık platform)
      double x = random.nextDouble() * (size.x - 80) + 40;
      add(Platform(position: Vector2(x, currentY)));
    }

    // 3. Oyuncu
    player = Player();
    player.position = Vector2(
      size.x / 2,
      size.y - 250,
    ); // İlk platformun üzerine bırak
    add(player);

    // 4. Skor
    scoreText = TextComponent(
      text: '${gameState.t('score')}: 0',
      position: Vector2(20, 50),
      textRenderer: TextPaint(
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(
              blurRadius: 4,
              color: Colors.black54,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
    );
    add(scoreText);
  }

  void resetGame() {
    overlays.remove('GameOverMenu');
    startGame();
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    // Gyroscope kontrolü
    if (gameState.useGyroscope) {
      // Sensitivity factor for accelerometer movement
      const double sensitivity = 3.0;
      double moveX = -_accelerometerX * sensitivity * dt * 60;
      player.position.x += moveX;

      // Ekrandan taşma (Sonsuz geçiş)
      if (player.position.x > size.x) player.position.x = 0;
      if (player.position.x < 0) player.position.x = size.x;

      // Sprite yönünü güncelle
      if (moveX < -0.5 && !player.isFlippedHorizontally) {
        player.flipHorizontally();
      } else if (moveX > 0.5 && player.isFlippedHorizontally) {
        player.flipHorizontally();
      }
    }

    // Boost Timer Updates
    if (scoreBoostTimer > 0) {
      scoreBoostTimer -= dt;
      _updateBoostTimerDisplay();
      if (scoreBoostTimer <= 0) {
        scoreMultiplier = 1.0;
        scoreBoostTimer = 0;
        _removeBoostTimerDisplay();
      }
    }

    if (rocketTimer > 0) {
      rocketTimer -= dt;
      // Rocket modunda hızlı yukarı git
      player.velocityY = -800; // Güçlü yukarı kuvvet
      _updateBoostTimerDisplay();
      if (rocketTimer <= 0) {
        isRocketActive = false;
        rocketTimer = 0;
        _removeBoostTimerDisplay();
      }
    }

    // Kamera ve Dünya Kaydırma
    // Karakter ekranın yarısından yukarı çıkarsa dünya aşağı kayar
    if (player.position.y < size.y / 2) {
      double diff = (size.y / 2) - player.position.y;
      player.position.y += diff;

      // Tüm nesneleri aşağı kaydır
      children.whereType<Platform>().forEach((p) {
        p.position.y += diff;
        // Ekranın çok altına inen platformları hemen silme, geri düşme şansı tanı
        if (p.position.y > size.y * 2) p.removeFromParent();
      });

      children.whereType<Enemy>().forEach((e) {
        e.position.y += diff;
        if (e.position.y > size.y * 2) e.removeFromParent();
      });

      // Boost'ları da kaydır
      children.whereType<ScoreBoost>().forEach((b) {
        b.position.y += diff;
        if (b.position.y > size.y * 2) b.removeFromParent();
      });
      children.whereType<RocketBoost>().forEach((b) {
        b.position.y += diff;
        if (b.position.y > size.y * 2) b.removeFromParent();
      });
      children.whereType<NegativeBoost>().forEach((b) {
        b.position.y += diff;
        if (b.position.y > size.y * 2) b.removeFromParent();
      });

      score += diff * scoreMultiplier;

      // Score text'i güncelle (multiplier varsa göster)
      if (scoreMultiplier > 1) {
        scoreText.text =
            '${gameState.t('score')}: ${score.toInt()} (x${scoreMultiplier.toInt()})';
      } else {
        scoreText.text = '${gameState.t('score')}: ${score.toInt()}';
      }

      // Yeni platform üretme mekanizması
      generatePlatforms(diff);
      spawnEnemies(diff);
      spawnBoosts(diff);
    }

    // Ölme kontrolü (Ekranın altı)
    if (player.position.y > size.y + 100) {
      gameOver();
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isGameOver) return;
    // Gyroscope modu açıksa touch kontrolü devre dışı
    if (gameState.useGyroscope) return;

    player.position.x += info.delta.global.x;

    // Ekrandan taşma (Sonsuz geçiş)
    if (player.position.x > size.x) player.position.x = 0;
    if (player.position.x < 0) player.position.x = size.x;

    if (info.delta.global.x < 0 && !player.isFlippedHorizontally) {
      player.flipHorizontally();
    } else if (info.delta.global.x > 0 && player.isFlippedHorizontally) {
      player.flipHorizontally();
    }
  }

  // Oyun sırasında yeni platform üretme
  void generatePlatforms(double dy) {
    generatedHeight += dy;

    // Dynamic Difficulty: Platform Gap
    // Başlangıçta 100, her 1000 puanda 10 artar, max 180 (zıplama limiti ~210)
    double gap = 100 + (score / 1000) * 10;
    if (gap > 180) gap = 180;

    while (generatedHeight > gap) {
      double x = random.nextDouble() * (size.x - 80) + 40;
      // Yeni platformu ekranın en tepesinin biraz üstüne koyuyoruz
      add(Platform(position: Vector2(x, -20)));
      generatedHeight -= gap;
    }
  }

  void spawnEnemies(double dy) {
    // Dynamic Difficulty: Enemy Spawn Rate
    // Başlangıçta %0.5, her 1000 puanda %0.2 artar, max %3
    double spawnChance = 0.5 + (score / 1000) * 0.2;
    if (spawnChance > 5.0) spawnChance = 5.0;

    if (random.nextDouble() * 100 < spawnChance) {
      double x = random.nextDouble() * (size.x - 50);
      add(Enemy(position: Vector2(x, -100)));
    }
  }

  void spawnBoosts(double dy) {
    // Ekranda zaten boost varsa spawn etme
    final existingBoosts =
        children.whereType<ScoreBoost>().length +
        children.whereType<RocketBoost>().length +
        children.whereType<NegativeBoost>().length;
    if (existingBoosts > 0) return;

    // Nadir spawn - %0.3 şans
    if (random.nextDouble() * 100 < 0.3) {
      double x = random.nextDouble() * (size.x - 50) + 25;
      // %33 ScoreBoost, %33 RocketBoost, %33 NegativeBoost
      int boostType = random.nextInt(3);
      if (boostType == 0) {
        add(ScoreBoost(position: Vector2(x, -50)));
      } else if (boostType == 1) {
        add(RocketBoost(position: Vector2(x, -50)));
      } else {
        add(NegativeBoost(position: Vector2(x, -50)));
      }
    }
  }

  void activateScoreBoost() {
    scoreMultiplier = 2.0;
    scoreBoostTimer = scoreBoostDuration;
  }

  void activateRocketBoost() {
    isRocketActive = true;
    rocketTimer = rocketDuration;
  }

  void activateNegativeBoost() {
    // -1000 puan
    score -= 1000;
    if (score < 0) score = 0;
    scoreText.text = '${gameState.t('score')}: ${score.toInt()}';

    // Tehlike göstergesi
    _showDangerWarning();
  }

  void _showDangerWarning() {
    final dangerText = TextComponent(
      text: '☠️ -1000',
      position: Vector2(size.x / 2, size.y / 3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: GoogleFonts.poppins(
          color: Colors.red,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(
              blurRadius: 6,
              color: Colors.black,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
    );
    add(dangerText);

    // 1.5 saniye sonra kaldır
    Future.delayed(const Duration(milliseconds: 1500), () {
      dangerText.removeFromParent();
    });
  }

  void _updateBoostTimerDisplay() {
    // En uzun süreyi göster
    double displayTime = 0;
    String emoji = '';

    if (rocketTimer > scoreBoostTimer) {
      displayTime = rocketTimer;
      emoji = '🚀';
    } else if (scoreBoostTimer > 0) {
      displayTime = scoreBoostTimer;
      emoji = '⭐';
    }

    if (displayTime > 0) {
      if (boostTimerText == null) {
        boostTimerText = TextComponent(
          text: '$emoji ${displayTime.toStringAsFixed(1)}s',
          position: Vector2(size.x - 100, 50),
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        add(boostTimerText!);
      } else {
        boostTimerText!.text = '$emoji ${displayTime.toStringAsFixed(1)}s';
      }
    }
  }

  void _removeBoostTimerDisplay() {
    // Her iki boost da bitmediyse kaldırma
    if (rocketTimer > 0 || scoreBoostTimer > 0) return;

    boostTimerText?.removeFromParent();
    boostTimerText = null;
  }

  void gameOver() async {
    if (isGameOver) return;
    isGameOver = true;

    if (score > highScore) {
      highScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('highScore', highScore);
    }

    pauseEngine();
    overlays.add('GameOverMenu');
  }
}

// --- PLAYER ---
class Player extends SpriteComponent
    with HasGameRef<ZiplayanOyun>, CollisionCallbacks {
  double velocityY = 0;
  final double gravity = 1000;
  final double jumpForce = -650; // Zıplama gücünü biraz artırdım

  Player() : super(size: Vector2(60, 60), anchor: Anchor.center, priority: 10);

  @override
  Future<void> onLoad() async {
    // GameState'den seçili karakteri bul
    final selectedId = GameState().selectedCharacterId;
    final selectedItem = GameState().allItems.firstWhere(
      (item) => item.id == selectedId,
      orElse: () =>
          GameState().allItems.firstWhere((item) => item.id == 'char_default'),
    );

    // Asset path'i düzelt (MarketScreen'deki mantığa benzer)
    String assetPath = selectedItem.assetPath;
    if (assetPath.contains('/')) {
      // Eğer tam yol verilmişse (örn: karakterler/ahtapot.png)
      // Flame assets prefix'i (assets/images/) otomatik ekler, o yüzden sadece dosya adını veya alt klasörü vermeliyiz.
      // Ancak Flame'de loadSprite doğrudan assets/images altına bakar.
      // GameItem'da 'karakterler/ahtapot.png' olarak kayıtlı.
      // Bu yüzden direkt kullanabiliriz.
    } else {
      // Sadece dosya adı varsa (eski kayıtlar için)
      if (!assetPath.endsWith('.png')) {
        assetPath = '$assetPath.png';
      }
    }

    try {
      sprite = await gameRef.loadSprite(assetPath);
    } catch (e) {
      print('Error loading sprite: $e');
      sprite = await gameRef.loadSprite('tavsan.png');
    }

    // Hitbox'ı biraz küçülttüm ki kenarlardan takılmasın
    add(
      CircleHitbox(
        radius: 15,
        position: Vector2(15, 25),
        anchor: Anchor.topLeft,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    velocityY += gravity * dt;
    position.y += velocityY * dt;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Platform) {
      // Rocket modunda platformlara çarpma (zaten yukarı gidiyor)
      if (gameRef.isRocketActive) return;

      bool isFalling = velocityY > 0;
      // Zıplama toleransı: Karakter platformun içine girse bile (hızlı düşüşlerde) zıplasın
      // Karakterin merkezi, platformun alt kenarından yukarıdaysa kabul et
      bool isAbove = (position.y < other.position.y + other.height);

      if (isFalling && isAbove) {
        velocityY = jumpForce;
      }
    }

    if (other is Enemy) {
      // Rocket modunda düşmanlardan etkilenme
      if (gameRef.isRocketActive) return;
      gameRef.gameOver();
    }

    // Boost collision
    if (other is ScoreBoost) {
      gameRef.activateScoreBoost();
      other.removeFromParent();
    }

    if (other is RocketBoost) {
      gameRef.activateRocketBoost();
      other.removeFromParent();
    }

    if (other is NegativeBoost) {
      gameRef.activateNegativeBoost();
      other.removeFromParent();
    }
  }
}

// --- PLATFORM ---
class Platform extends SpriteComponent
    with HasGameRef<ZiplayanOyun>, CollisionCallbacks {
  Platform({required Vector2 position})
    : super(
        position: position,
        size: Vector2(80, 25),
        anchor: Anchor.topCenter,
        priority: 0,
      );

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('platform.png');
    add(RectangleHitbox());
  }
}

// --- ENEMY ---
class Enemy extends SpriteComponent
    with HasGameRef<ZiplayanOyun>, CollisionCallbacks {
  double speed = 60; // Daha yavaş düşsün (istek üzerine)
  Enemy({required Vector2 position})
    : super(
        position: position,
        size: Vector2(50, 50),
        anchor: Anchor.center,
        priority: 5,
      );

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('dusman.png');
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    angle += dt * 2;
  }
}

// --- SCORE BOOST ---
class ScoreBoost extends SpriteComponent
    with HasGameRef<ZiplayanOyun>, CollisionCallbacks {
  ScoreBoost({required Vector2 position})
    : super(
        position: position,
        size: Vector2(40, 40),
        anchor: Anchor.center,
        priority: 8,
      );

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('x2.png');
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Hafif dönme animasyonu
    angle += dt * 3;
  }
}

// --- ROCKET BOOST ---
class RocketBoost extends SpriteComponent
    with HasGameRef<ZiplayanOyun>, CollisionCallbacks {
  RocketBoost({required Vector2 position})
    : super(
        position: position,
        size: Vector2(40, 40),
        anchor: Anchor.center,
        priority: 8,
      );

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('roket.png');
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Hafif yukarı aşağı hareket
    position.y += sin(gameRef.score / 10) * 0.3;
  }
}

// --- NEGATIVE BOOST ---
class NegativeBoost extends SpriteComponent
    with HasGameRef<ZiplayanOyun>, CollisionCallbacks {
  double speed = 80; // Aşağı hareket hızı

  NegativeBoost({required Vector2 position})
    : super(
        position: position,
        size: Vector2(40, 40),
        anchor: Anchor.center,
        priority: 8,
      );

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('1000.png');
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Aşağı doğru hareket (düşmanlar gibi)
    position.y += speed * dt;
    // Hafif sallanma
    angle = sin(position.y / 20) * 0.15;
  }
}
