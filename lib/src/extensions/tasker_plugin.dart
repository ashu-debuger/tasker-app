import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Metadata describing a plugin.
class TaskerPluginMetadata {
  const TaskerPluginMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    this.homepage,
  });

  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  final Uri? homepage;
}

/// Context provided to plugins when they are registered.
class PluginContext {
  const PluginContext({required this.ref});

  final Ref ref;
}

typedef PluginActionHandler =
    FutureOr<void> Function(WidgetRef ref, BuildContext context);

typedef PluginVisibilityPredicate =
    bool Function(WidgetRef ref, BuildContext context);

/// Describes a command or shortcut contributed by a plugin.
class PluginAction {
  const PluginAction({
    required this.id,
    required this.label,
    required this.onSelected,
    this.icon,
    this.description,
    this.isVisible,
  });

  final String id;
  final String label;
  final IconData? icon;
  final String? description;
  final PluginActionHandler onSelected;
  final PluginVisibilityPredicate? isVisible;
}

/// Optional theme overrides contributed by a plugin.
class PluginThemeExtension extends ThemeExtension<PluginThemeExtension> {
  const PluginThemeExtension({
    this.accentColor,
    this.surfaceTint,
    this.cardRadius,
  });

  final Color? accentColor;
  final Color? surfaceTint;
  final double? cardRadius;

  @override
  PluginThemeExtension copyWith({
    Color? accentColor,
    Color? surfaceTint,
    double? cardRadius,
  }) {
    return PluginThemeExtension(
      accentColor: accentColor ?? this.accentColor,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      cardRadius: cardRadius ?? this.cardRadius,
    );
  }

  @override
  PluginThemeExtension lerp(
    covariant ThemeExtension<PluginThemeExtension>? other,
    double t,
  ) {
    if (other is! PluginThemeExtension) {
      return this;
    }

    return PluginThemeExtension(
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t),
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t),
    );
  }

  ThemeData applyTo(ThemeData base) {
    final colorScheme = base.colorScheme.copyWith(
      secondary: accentColor ?? base.colorScheme.secondary,
      surfaceTint: surfaceTint ?? base.colorScheme.surfaceTint,
    );

    final cardTheme = base.cardTheme.copyWith(
      shape: cardRadius == null
          ? base.cardTheme.shape
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius!),
            ),
    );

    return base.copyWith(colorScheme: colorScheme, cardTheme: cardTheme);
  }
}

abstract class TaskerPlugin {
  TaskerPluginMetadata get metadata;

  /// Called when the plugin is registered. Override to perform setup.
  void onRegister(PluginContext context) {}

  /// Optional cleanup hook.
  void onDispose() {}

  /// Actions exposed by this plugin.
  List<PluginAction> get actions => const [];

  /// Theme overrides exposed by this plugin.
  PluginThemeExtension? get themeExtension => null;
}
