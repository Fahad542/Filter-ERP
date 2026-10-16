import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/owner_data_service.dart';

/// Registers a per-tab reload callback on [OwnerDataService].
///
/// - Branch change → shell calls only the **current** tab's reloader.
/// - Tab switch → shell calls the newly selected tab's reloader; the VM
///   no-ops if data is already for the selected branch.
class OwnerBranchReloadRegistrar extends StatefulWidget {
  final int tabIndex;
  final Future<void> Function(BuildContext context) onReload;
  final Widget child;

  const OwnerBranchReloadRegistrar({
    super.key,
    required this.tabIndex,
    required this.onReload,
    required this.child,
  });

  @override
  State<OwnerBranchReloadRegistrar> createState() =>
      _OwnerBranchReloadRegistrarState();
}

class _OwnerBranchReloadRegistrarState
    extends State<OwnerBranchReloadRegistrar> {
  OwnerDataService? _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = context.read<OwnerDataService>();
    if (!identical(_data, data)) {
      _data?.unregisterTabReloader(widget.tabIndex);
      _data = data;
      _data!.registerTabReloader(
        widget.tabIndex,
        () => widget.onReload(context),
      );
    }
  }

  @override
  void dispose() {
    _data?.unregisterTabReloader(widget.tabIndex);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
