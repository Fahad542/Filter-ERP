import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import 'supplier_invoices_issued_view_model.dart';

class SupplierInvoicesIssuedView extends StatelessWidget {
  final VoidCallback? onBack;
  const SupplierInvoicesIssuedView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && !isDesktop;
    final isLargeScreen = isDesktop || isTablet;

    return ChangeNotifierProvider(
      create: (_) => SupplierInvoicesIssuedViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isLargeScreen ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: isDesktop
              ? null
              : PosScreenAppBar(
                  title: 'Invoices Issued',
                  onBack:
                      onBack ??
                      () => Navigator.popUntil(
                        context,
                        ModalRoute.withName('/supplier'),
                      ),
                ),
          body: Consumer<SupplierInvoicesIssuedViewModel>(
            builder: (context, vm, _) {
              return SafeArea(
                top: isDesktop,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 32 : 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDesktop) ...[
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: AppColors.secondaryLight,
                              ),
                              onPressed:
                                  onBack ??
                                  () => Navigator.popUntil(
                                    context,
                                    ModalRoute.withName('/supplier'),
                                  ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Invoices Issued',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondaryLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Header Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryLight.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: AppColors.primaryLight,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Invoices',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${vm.invoices.length} Issued',
                                  style: AppTextStyles.h2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Filters section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.filter_list_rounded,
                                  size: 20,
                                  color: AppColors.secondaryLight,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Filter Invoices',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.secondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: DropdownButtonFormField<String>(
                                    value: vm.selectedBranch,
                                    decoration: InputDecoration(
                                      labelText: 'Branch',
                                      labelStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FD),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.secondaryLight,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondaryLight,
                                      fontSize: 15,
                                    ),
                                    items: ['All', 'Riyadh', 'Jeddah']
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      vm.selectedBranch = v ?? 'All';
                                      vm.notifyListeners();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 180,
                                  child: DropdownButtonFormField<String>(
                                    value: vm.selectedStatus,
                                    decoration: InputDecoration(
                                      labelText: 'Status',
                                      labelStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FD),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.secondaryLight,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondaryLight,
                                      fontSize: 15,
                                    ),
                                    items: ['All', 'Pending', 'Paid']
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      vm.selectedStatus = v ?? 'All';
                                      vm.notifyListeners();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // List Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.list_alt_rounded,
                              color: AppColors.secondaryLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Invoice Records',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (vm.invoices.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_rounded,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No invoices match your filters',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (isDesktop)
                        _buildDesktopDataTable(vm)
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: vm.invoices.length,
                          itemBuilder: (context, i) =>
                              _InvoiceCard(invoice: vm.invoices[i], vm: vm),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopDataTable(SupplierInvoicesIssuedViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FD)),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLight,
              fontSize: 13,
            ),
            dataTextStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryLight,
              fontSize: 14,
            ),
            columnSpacing: 48,
            columns: const [
              DataColumn(label: Text('Invoice ID')),
              DataColumn(label: Text('Branch')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: vm.invoices.map((o) {
              final isPending = o.status == 'Pending';
              final statusColor = isPending
                  ? Colors.orange.shade700
                  : AppColors.primaryLight;

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_rounded,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          o.id,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      o.branch,
                      style: const TextStyle(color: AppColors.secondaryLight),
                    ),
                  ),
                  DataCell(
                    Text(o.date, style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  DataCell(
                    Text(
                      o.amount,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        o.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility_rounded,
                            size: 20,
                            color: AppColors.secondaryLight,
                          ),
                          onPressed: () {},
                          tooltip: 'View Details',
                        ),
                        if (isPending)
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_active_rounded,
                              size: 20,
                              color: Colors.orange,
                            ),
                            onPressed: () => vm.sendReminder(o.id),
                            tooltip: 'Send Reminder',
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => vm.downloadPdf(o.id),
                          tooltip: 'Download PDF',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceIssuedItem invoice;
  final SupplierInvoicesIssuedViewModel vm;
  const _InvoiceCard({required this.invoice, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isPending = invoice.status == 'Pending';
    final statusColor = isPending
        ? Colors.orange.shade700
        : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_rounded,
                    color: AppColors.secondaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    invoice.id,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    invoice.status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      invoice.branch,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      invoice.date,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Amount',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        invoice.amount,
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.visibility_rounded, size: 18),
                        label: const Text(
                          'View',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondaryLight,
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => vm.downloadPdf(invoice.id),
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'PDF',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade700,
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.red.shade200,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isPending) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => vm.sendReminder(invoice.id),
                      icon: const Icon(
                        Icons.notifications_active_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Send Reminder',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade50,
                        foregroundColor: Colors.orange.shade800,
                        elevation: 0,
                        side: BorderSide(color: Colors.orange.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
