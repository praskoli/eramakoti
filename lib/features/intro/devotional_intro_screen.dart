import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class DevotionalIntroScreen extends StatefulWidget {
  const DevotionalIntroScreen({
    super.key,
    required this.nextScreen,
    this.audioAssetPath = 'audio/jai_shri_ram_intro.mp3',
    this.imageAssetPath = 'assets/images/ram_intro.png',
    this.duration = const Duration(milliseconds: 3200),
    this.backgroundColor = Colors.black,
    this.enableParticles = true,
    this.enableAudio = true,
  });

  final Widget nextScreen;
  final String audioAssetPath;
  final String imageAssetPath;
  final Duration duration;
  final Color backgroundColor;
  final bool enableParticles;
  final bool enableAudio;

  @override
  State<DevotionalIntroScreen> createState() => _DevotionalIntroScreenState();
}

class _DevotionalIntroScreenState extends State<DevotionalIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _zoomController;
  late final AnimationController _fadeController;
  late final AnimationController _glowController;
  late final AnimationController _particleController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _screenFadeAnimation;
  late final Animation<double> _imageFadeAnimation;
  late final Animation<double> _glowAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _navigationTimer;
  bool _navigated = false;

  static const List<_ParticleSpec> _particleSpecs = [
    _ParticleSpec(
      alignment: Alignment(-0.78, -0.62),
      size: 8,
      dx: 10,
      dy: -18,
      durationMs: 2300,
      delayMs: 0,
    ),
    _ParticleSpec(
      alignment: Alignment(-0.52, 0.18),
      size: 5,
      dx: 7,
      dy: -14,
      durationMs: 2100,
      delayMs: 200,
    ),
    _ParticleSpec(
      alignment: Alignment(0.64, -0.28),
      size: 7,
      dx: -8,
      dy: -16,
      durationMs: 2500,
      delayMs: 450,
    ),
    _ParticleSpec(
      alignment: Alignment(0.72, 0.36),
      size: 5,
      dx: -6,
      dy: -12,
      durationMs: 2200,
      delayMs: 650,
    ),
    _ParticleSpec(
      alignment: Alignment(-0.08, -0.12),
      size: 4,
      dx: 4,
      dy: -10,
      durationMs: 2000,
      delayMs: 900,
    ),
    _ParticleSpec(
      alignment: Alignment(0.18, 0.26),
      size: 6,
      dx: -5,
      dy: -13,
      durationMs: 2400,
      delayMs: 1100,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _zoomController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.035,
    ).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: Curves.easeInOut,
      ),
    );

    _screenFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(_fadeController);

    _imageFadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0.88),
        weight: 25,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.18,
      end: 0.32,
    ).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _startIntro();
  }

  Future<void> _startIntro() async {
    unawaited(_zoomController.forward());
    unawaited(_fadeController.forward());
    unawaited(_glowController.repeat(reverse: true));

    if (widget.enableParticles) {
      unawaited(_particleController.repeat());
    }

    if (widget.enableAudio) {
      unawaited(_playAudio());
    }

    _navigationTimer = Timer(widget.duration, _goNext);
  }

  Future<void> _playAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(AssetSource(widget.audioAssetPath));
    } catch (_) {
      // Silent fail: intro should still continue even if audio is unavailable.
    }
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _audioPlayer.dispose();
    _zoomController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _zoomController,
          _fadeController,
          _glowController,
          _particleController,
        ]),
        builder: (context, _) {
          return Opacity(
            opacity: _screenFadeAnimation.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: widget.backgroundColor),
                _buildBackgroundGlow(),
                if (widget.enableParticles) _buildParticles(),
                _buildImage(),
                _buildTopVignette(),
                _buildBottomVignette(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage() {
    return Center(
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: Opacity(
          opacity: _imageFadeAnimation.value,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              const Color(0xFFFFC46B).withOpacity(0.06),
              BlendMode.softLight,
            ),
            child: Image.asset(
              widget.imageAssetPath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'Intro image not found',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    final glowOpacity = _glowAnimation.value;

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.20),
            radius: 0.78,
            colors: [
              const Color(0xFFFFD27A).withOpacity(glowOpacity),
              const Color(0xFFFFA726).withOpacity(glowOpacity * 0.42),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.44, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildTopVignette() {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Color(0xAA000000),
              Color(0x22000000),
              Color(0x00000000),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomVignette() {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00000000),
              Color(0x16000000),
              Color(0xCC000000),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticles() {
    return IgnorePointer(
      child: Stack(
        children: _particleSpecs.map(_buildParticle).toList(),
      ),
    );
  }

  Widget _buildParticle(_ParticleSpec spec) {
    final rawT = ((_particleController.value * 2600) - spec.delayMs) /
        spec.durationMs;
    final t = rawT.clamp(0.0, 1.0);

    final eased = Curves.easeOut.transform(t);
    final opacity = rawT < 0 || rawT > 1 ? 0.0 : (1.0 - eased) * 0.75;

    return Align(
      alignment: spec.alignment,
      child: Transform.translate(
        offset: Offset(spec.dx * eased, spec.dy * eased),
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: spec.size,
            height: spec.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFE39B),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD27A).withOpacity(0.85),
                  blurRadius: spec.size * 2.4,
                  spreadRadius: spec.size * 0.25,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticleSpec {
  const _ParticleSpec({
    required this.alignment,
    required this.size,
    required this.dx,
    required this.dy,
    required this.durationMs,
    required this.delayMs,
  });

  final Alignment alignment;
  final double size;
  final double dx;
  final double dy;
  final int durationMs;
  final int delayMs;
}