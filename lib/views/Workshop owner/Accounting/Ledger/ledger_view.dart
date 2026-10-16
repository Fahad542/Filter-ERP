import 'package:flutter/material.dart';
import '../../widgets/owner_ui_constants.dart';

import '../../../../widgets/custom_button.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../widgets/owner_shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LedgerView
// ─────────────────────────────────────────────────────────────────────────────

class LedgerView extends StatefulWidget {
  const LedgerView({super.key});

  @override
  State<LedgerView> createState() => _LedgerViewState();
}

class LedgerEntry {
  final String date;
  final String entryNumber;
  final String type;
  final String description;
  final String source;
  final double? debit;
  final double? credit;
  final double runningBalance;

  const LedgerEntry({
    required this.date,
    required this.entryNumber,
    required this.type,
    required this.description,
    required this.source,
    this.debit,
    this.credit,
    required this.runningBalance,
  });
}

class _LedgerViewState extends State<LedgerView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedAccount;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;

  final List<String> _accounts = [
    'Cash Account',
    'Accounts Receivable',
    'Inventory',
    'Fixed Assets',
    'Accounts Payable',
    'Revenue',
    'Expenses',
  ];

  // Always show entries — auto-refresh when any filter changes
  List<LedgerEntry> _entries = const [];

  final List<LedgerEntry> _mockEntries = const [
    LedgerEntry(
      date: '01/06/2026',
      entryNumber: 'JE-001',
      type: 'Opening',
      description: 'Opening balance for June',
      source: 'System',
      debit: null,
      credit: 5000.00,
      runningBalance: 5000.00,
    ),
    LedgerEntry(
      date: '05/06/2026',
      entryNumber: 'JE-002',
      type: 'Sale',
      description: 'Invoice #INV-204 — Service charge',
      source: 'Sales',
      debit: null,
      credit: 1200.00,
      runningBalance: 6200.00,
    ),
    LedgerEntry(
      date: '08/06/2026',
      entryNumber: 'JE-003',
      type: 'Expense',
      description: 'Monthly staff salaries — June 2026',
      source: 'Payroll',
      debit: 4500.00,
      credit: null,
      runningBalance: 1700.00,
    ),
    LedgerEntry(
      date: '10/06/2026',
      entryNumber: 'JE-004',
      type: 'Purchase',
      description: 'Spare parts — Main Branch',
      source: 'Purchasing',
      debit: 750.00,
      credit: null,
      runningBalance: 950.00,
    ),
    LedgerEntry(
      date: '12/06/2026',
      entryNumber: 'JE-005',
      type: 'Sale',
      description: 'Invoice #INV-205 — Oil change service',
      source: 'Sales',
      debit: null,
      credit: 320.00,
      runningBalance: 1270.00,
    ),
    LedgerEntry(
      date: '14/06/2026',
      entryNumber: 'JE-006',
      type: 'Rent',
      description: 'Monthly rent — Workshop space',
      source: 'Expenses',
      debit: 600.00,
      credit: null,
      runningBalance: 670.00,
    ),
  ];

  // ── Auto-refresh: called whenever any filter changes ──────────────────────
  Future<void> _refreshEntries() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _entries = _mockEntries; // TODO: apply actual filter logic here
      _isLoading = false;
    });
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFF5A623),
            onPrimary: Colors.black,
            surface: Color(0xFFFFFFFF),
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
      _refreshEntries();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'dd/mm/yyyy';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  void initState() {
    super.initState();
    // Load entries immediately on open
    _refreshEntries();
    _searchController.addListener(_refreshEntries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: 'Ledger',
        showBackButton: false,
        showNotification: true,
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Filter panel ───────────────────────────────────────────────────────────

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search ────────────────────────────────────────────────────────
          _buildLabel('SEARCH'),
          const SizedBox(height: 6),
          _buildSearchField(),
          const SizedBox(height: 14),

          // ── Account dropdown ──────────────────────────────────────────────
          _buildLabel('ACCOUNT'),
          const SizedBox(height: 6),
          _buildAccountDropdown(),
          const SizedBox(height: 14),

          // ── Date range ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('FROM'),
                    const SizedBox(height: 6),
                    _buildDateButton(isFrom: true),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('TO'),
                    const SizedBox(height: 6),
                    _buildDateButton(isFrom: false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8A8A9A),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: OwnerUi.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: 'Description / reference...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ── Account dropdown ───────────────────────────────────────────────────
  Widget _buildAccountDropdown() {
    final hasSelection = _selectedAccount != null;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: OwnerUi.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: hasSelection
            ? Border.all(color: const Color(0xFFF5A623), width: 1.5)
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedAccount,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: hasSelection ? const Color(0xFFF5A623) : Colors.grey.shade400,
          ),
          hint: Text(
            'All Accounts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Accounts'),
            ),
            ..._accounts.map(
                  (acc) => DropdownMenuItem<String?>(
                value: acc,
                child: Text(acc),
              ),
            ),
          ],
          onChanged: (value) {
            _selectedAccount = value;
            _refreshEntries();
          },
        ),
      ),
    );
  }

  Widget _buildDateButton({required bool isFrom}) {
    final date = isFrom ? _fromDate : _toDate;
    final hasDate = date != null;

    return GestureDetector(
      onTap: () => _pickDate(isFrom),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: OwnerUi.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
          border: hasDate
              ? Border.all(color: const Color(0xFFF5A623), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: hasDate ? const Color(0xFFF5A623) : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 13,
                color: hasDate ? const Color(0xFF1A1A2E) : Colors.grey.shade400,
                fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body / results ─────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const OwnerTablePageShimmer(showKpi: false, showTabs: false);
    }

    if (_entries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        message: 'No entries found for the selected filters.',
      );
    }

    return Column(
      children: [
        _buildResultsHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _entries.length,
            itemBuilder: (_, i) => _buildEntryCard(_entries[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Text(
            '${_entries.length} entries',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A4A6A),
            ),
          ),
          const Spacer(),
          if (_selectedAccount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedAccount!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB07900),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(LedgerEntry entry, int index) {
    final isDebit = entry.debit != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.entryNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: OwnerUi.scaffoldBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.type,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4A6A),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  entry.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                entry.description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [_cardMeta('SOURCE', entry.source)],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: OwnerUi.scaffoldBackground, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: _amountCell(
                    label: 'DEBIT',
                    amount: entry.debit,
                    isActive: isDebit,
                    activeColor: const Color(0xFFFF6B6B),
                  ),
                ),
                Container(width: 1, height: 36, color: const Color(0xFFE5E5EA)),
                Expanded(
                  child: _amountCell(
                    label: 'CREDIT',
                    amount: entry.credit,
                    isActive: !isDebit,
                    activeColor: const Color(0xFF4CD9A0),
                  ),
                ),
                Container(width: 1, height: 36, color: const Color(0xFFE5E5EA)),
                Expanded(
                  child: _amountCell(
                    label: 'BALANCE',
                    amount: entry.runningBalance,
                    isActive: true,
                    activeColor: const Color(0xFFF5A623),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8A8A9A),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _amountCell({
    required String label,
    required double? amount,
    required bool isActive,
    required Color activeColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8A8A9A),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount != null ? 'SAR ${amount.toStringAsFixed(2)}' : '—',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive && amount != null ? activeColor : const Color(0xFFC4C4CE),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: const Color(0xFFF5A623)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8A8A9A),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}