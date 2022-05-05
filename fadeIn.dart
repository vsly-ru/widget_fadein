/// FadeIn animation with configurable duration, offset and fadeOut method.
/// v 1.3 | 2022-05-05
/// Created by Vasiliy Atutov aka vSLY (https://github.com/vsly-ru)
/// Based on EntranceFader by Marcin Szałek (https://fidev.io)

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Combined entrance animation with opacity (from [opacity]) and/or sliding (from an [offset])
class FadeIn extends StatefulWidget {
  /// Skip the animation entirely and return child instead (e.g. for optimization)
  final bool skipAnimation;

  /// A widget to animate
  final Widget? child;

  /// Starting offset from which the widget will move to its default (no offset) position
  final Offset offset;

  /// Delay (ms) before playing the animation; (useful for chaining)
  final int delay;

  /// duration of the animation
  final Duration duration;

  /// [0.0 - 1.0] Initial widget opacity (will be animated to 1.0)
  final double opacity;

  /// [0.0 - 1.0] Initial child scale (will be animated to 1.0)
  final double scale;

  /// play fade out animation instead
  final bool isFadeOut;

  /// child will be dismounted and container shrinked down to zero after the
  /// fadeOut animation finished
  final bool dismountAfterFadeOut;

  const FadeIn(
      {Key? key,
      this.child,
      this.offset = const Offset(0.0, 32.0),
      this.delay = 0,
      this.duration = const Duration(milliseconds: 333),
      this.skipAnimation = false,
      this.scale = 0.9,
      this.opacity = 0.0,
      this.isFadeOut = false,
      this.dismountAfterFadeOut = false})
      : super(key: key);

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
        value: widget.isFadeOut ? 1.0 : 0.0);
    _dxAnimation =
        Tween(begin: widget.offset.dx, end: 0.0).animate(_controller);
    _dyAnimation =
        Tween(begin: widget.offset.dy, end: 0.0).animate(_controller);
    _opacityAnimation =
        Tween(begin: widget.opacity, end: 1.0).animate(_controller);
    _scaleAnimation = Tween(begin: widget.scale, end: 1.0).animate(_controller);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (widget.isFadeOut) {
        playFadeOut(dismount: widget.dismountAfterFadeOut);
      } else {
        playFadeIn(null);
      }
    });
  }

  @override
  void didUpdateWidget(FadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    // log('didUpdateWidget', name: 'FadeIn');
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
      // TODO: update other fields
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
      _controller.forward(from: from);
      // calculating the expected animation duration (ms) from a current/given progress to 1.0;
      final left = 1.0 - (from ?? _controller.value);
      final duration = (left * widget.duration.inMilliseconds).ceil();
      await Future.delayed(Duration(milliseconds: duration));
    } else {
      if (kDebugMode) print('FadeIn wasn\'t mounted');
    }
  }

  /// disappear animation (could be awaited)
  /// [from] (0.0 - 1.0) – start the animation from a specific value;
  ///   null: By default uses current progress;
  /// [dismount] – will "dismount" itself (like display:none in CSS)
  /// by removing the child and shrinking itself
  FutureOr<void> playFadeOut({double? from, bool dismount = false}) async {
    if (mounted) {
      _controller.reverse(from: from);
      // calculating the expected animation duration (ms) from a current/given progress to zero;
      final leftDuration =
          (from ?? _controller.value) * (widget.duration.inMilliseconds + 1);
      await Future.delayed(Duration(milliseconds: leftDuration.ceil()));
      if (dismount) {
        // rebuild the widget without the animation builder and child
        setState(() {
          _erased = true;
        });
      }
    } else {
      if (kDebugMode) print('FadeIn wasn\'t mounted');
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
