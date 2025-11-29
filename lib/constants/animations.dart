import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  static const Duration defaultDuration = Duration(milliseconds: 600);
  static const Duration fastDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 1000);

  // Fade animations
  static Widget fadeIn(Widget child, {Duration? duration}) {
    return child.animate().fadeIn(duration: duration ?? defaultDuration);
  }

  static Widget fadeOut(Widget child, {Duration? duration}) {
    return child.animate().fadeOut(duration: duration ?? defaultDuration);
  }

  // Scale animations
  static Widget scaleIn(Widget child, {Duration? duration}) {
    return child.animate().scale(duration: duration ?? defaultDuration);
  }

  static Widget scaleOut(Widget child, {Duration? duration}) {
    return child.animate().scale(duration: duration ?? defaultDuration);
  }

  // Slide animations
  static Widget slideInLeft(Widget child, {Duration? duration}) {
    return child.animate().slideX(
      begin: -1,
      end: 0,
      duration: duration ?? defaultDuration,
    );
  }

  static Widget slideInRight(Widget child, {Duration? duration}) {
    return child.animate().slideX(
      begin: 1,
      end: 0,
      duration: duration ?? defaultDuration,
    );
  }

  static Widget slideInUp(Widget child, {Duration? duration}) {
    return child.animate().slideY(
      begin: 1,
      end: 0,
      duration: duration ?? defaultDuration,
    );
  }

  static Widget slideInDown(Widget child, {Duration? duration}) {
    return child.animate().slideY(
      begin: -1,
      end: 0,
      duration: duration ?? defaultDuration,
    );
  }

  // Rotation animations
  static Widget rotateIn(Widget child, {Duration? duration}) {
    return child.animate().rotate(
      begin: -0.5,
      end: 0,
      duration: duration ?? defaultDuration,
    );
  }

  // Pulse animation
  static Widget pulse(Widget child, {Duration? duration}) {
    return child.animate().scale(
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.1, 1.1),
      duration: duration ?? defaultDuration,
    ).then().scale(
      begin: const Offset(1.1, 1.1),
      end: const Offset(1.0, 1.0),
      duration: duration ?? defaultDuration,
    );
  }

  // Bounce animation
  static Widget bounce(Widget child, {Duration? duration}) {
    return child.animate().scale(
      begin: const Offset(0.0, 0.0),
      end: const Offset(1.0, 1.0),
      duration: duration ?? defaultDuration,
      curve: Curves.elasticOut,
    );
  }

  // Shake animation
  static Widget shake(Widget child, {Duration? duration}) {
    return child.animate().shake(
      duration: duration ?? fastDuration,
    );
  }

  // Glow animation
  static Widget glow(Widget child, {Duration? duration}) {
    return child.animate().shimmer(
      duration: duration ?? slowDuration,
    );
  }

  // Combined animations
  static Widget fadeInScale(Widget child, {Duration? duration}) {
    return child.animate()
        .fadeIn(duration: duration ?? defaultDuration)
        .scale(duration: duration ?? defaultDuration);
  }

  static Widget slideInFade(Widget child, {Duration? duration}) {
    return child.animate()
        .slideY(begin: 1, end: 0, duration: duration ?? defaultDuration)
        .fadeIn(duration: duration ?? defaultDuration);
  }

  // Staggered animations for lists
  static List<Widget> stagger(List<Widget> children, {Duration? delay}) {
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      return child.animate().fadeIn(
        delay: Duration(milliseconds: (delay?.inMilliseconds ?? 100) * index),
        duration: defaultDuration,
      );
    }).toList();
  }
}
