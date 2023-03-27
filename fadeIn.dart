/// FadeIn animation with configurable duration and offset.
/// v 1.4 | 2023-03-27
/// Created by Vasiliy Atutov aka vSLY-ru (https://github.com/vsly-ru)
/// Based on EntranceFader by Marcin Szałek (https://fidev.io)

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Combined entrance animation with opacity (from [opacity]) and/or sliding (from an [offset])
class FadeIn extends StatefulWidget {
  const FadeIn({
    Key? key,
    this.child,
    this.offset = const Offset(0.0, 32.0),
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 333),
    this.skipAnimation = false,
    this.scale = 0.9,
    this.opacity = 0.0,
  }) : super(key: key);

  /// Skip the animation entirely and return the child instead (e.g. if animations are disabled by settings)
  final bool skipAnimation;

  /// A widget to animate
  final Widget? child;

  /// Starting offset from which the widget will move to its default (no offset) position
  final Offset offset;

  /// Delay (ms) before playing the animation
  final Duration delay;

  /// duration of the animation
  final Duration duration;

  /// [0.0 - 1.0] Initial widget opacity (will be animated to 1.0)
  final double opacity;

  /// [0.0 - 1.0] Initial child scale (will be animated to 1.0)
  final double scale;

  @override
  FadeInState createState() => FadeInState();
}

class FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation _dxAnimation;
  late Animation _dyAnimation;
  late Animation _opacityAnimation;
  late Animation _scaleAnimation;

  // determine when the child shouldn't be mounted
  bool _erased = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 0.0,
    );
    _dxAnimation =
        Tween(begin: widget.offset.dx, end: 0.0).animate(_controller);
    _dyAnimation =
        Tween(begin: widget.offset.dy, end: 0.0).animate(_controller);
    _opacityAnimation =
        Tween(begin: widget.opacity, end: 1.0).animate(_controller);
    _scaleAnimation = Tween(begin: widget.scale, end: 1.0).animate(_controller);
    Future.delayed(widget.delay, () => playFadeIn(null));
  }

  @override
  void didUpdateWidget(FadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    // log('didUpdateWidget', name: 'FadeIn');
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  /// play the fade in animation (could be awaited)
  /// [from] (0.0 - 1.0) – start the animation from a specific value;
  ///   null: By default uses current progress;
  FutureOr<void> playFadeIn(double? from) async {
    if (mounted) {
      if (_erased) {
        // if the widget was previously "dismounted", rebuild the widget using animation controller.
        setState(() {
          _erased = false;
        });
      }
      unawaited(_controller.forward(from: from));
      // calculating the expected animation duration (ms) from a current/given progress to 1.0;
      final left = 1.0 - (from ?? _controller.value);
      final duration = (left * widget.duration.inMilliseconds).ceil();
      await Future.delayed(Duration(milliseconds: duration));
    } else {
      if (kDebugMode) print("FadeIn wasn't mounted");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Widget none = SizedBox.shrink();
    if (_erased) return none;
    if (widget.skipAnimation) return widget.child ?? none;
    return AnimatedBuilder(
      key: ValueKey<bool>(_erased),
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacityAnimation.value,
        child: Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.identity()
            ..translate(_dxAnimation.value, _dyAnimation.value)
            ..scale(_scaleAnimation.value),
          child: widget.child,
        ),
      ),
    );
  }
}
