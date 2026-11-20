import 'package:flutter/material.dart';

import '../theme/jivaio_theme.dart';

/// Visual defaults scoped to the administrative screens and their dialogs.
ThemeData adminTheme(ThemeData base) {
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(6),
    side: const BorderSide(color: JivaioColors.border),
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: const BorderSide(color: JivaioColors.border),
  );
  return base.copyWith(
    cardTheme: CardThemeData(
      color: JivaioColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: shape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: JivaioColors.surface,
      elevation: 0,
      shape: shape,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: JivaioColors.blue, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    ),
  );
}
