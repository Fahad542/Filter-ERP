import 'package:flutter/material.dart';

import '../../../widgets/pos_widgets.dart';

/// Workshop Owner search field — matches POS cashier [PosSearchBar.workshop] styling.
class CustomSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final String hintText;
  final TextEditingController? controller;

  const CustomSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search...',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return PosSearchBar.workshop(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
    );
  }
}
