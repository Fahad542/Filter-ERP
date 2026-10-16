import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';


class AppFabSheetButton<T extends ChangeNotifier> extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  final T viewModel;
  final VoidCallback onClear;

  final Widget Function(BuildContext context, T vm) sheetBuilder;

  const AppFabSheetButton({
    super.key,
    required this.label,
    required this.icon,
    required this.viewModel,
    required this.onClear,
    required this.sheetBuilder,
    this.backgroundColor,
    this.foregroundColor,
  });

  void _openSheet(BuildContext context) {
    onClear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: sheetBuilder(context, viewModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openSheet(context),
      backgroundColor: backgroundColor ?? AppColors.primaryLight,
      foregroundColor: foregroundColor ?? AppColors.secondaryLight,
      elevation: 4,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: foregroundColor ?? AppColors.secondaryLight,
        ),
      ),
    );
  }
}