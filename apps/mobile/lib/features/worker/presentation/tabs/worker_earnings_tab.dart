import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';
import '../../../common/presentation/widgets/invoice_modal.dart';
import '../../controllers/worker_controller.dart';

/// Page 14 — Worker Earnings & Payouts Hub
/// Features comprehensive income analytics, cooperative welfare contributions,
/// weekly guild incentive tracker, instant UPI withdrawal modal, and itemized payout history.
class WorkerEarningsTab extends ConsumerStatefulWidget {
  const WorkerEarningsTab({super.key});

  @override
  ConsumerState<WorkerEarningsTab> createState() => _WorkerEarningsTabState();
}

class _WorkerEarningsTabState extends ConsumerState<WorkerEarningsTab> {
  String _timeframe = 'This Week';
  double _withdrawableBalance = 2840.0;
  final String _upiId = 'ramesh.sharma@okhdfcbank';

  final List<String> _timeframes = <String>['Today', 'This Week', 'This Month', 'Lifetime'];

  void _openWithdrawModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return _WithdrawUpiModal(
          currentBalance: _withdrawableBalance,
          upiId: _upiId,
          onWithdrawSuccess: (double amount) {
            setState(() {
              _withdrawableBalance = (_withdrawableBalance - amount).clamp(0.0, double.infinity);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('₹${amount.toStringAsFixed(0)} successfully transferred to $_upiId via IMPS/UPI!'),
                backgroundColor: AppColors.success,
              ),
            );
          },
        );
      },
    );
  }

  void _openInvoiceDemo(BuildContext context, _EarningsTransaction tx) {
    final Booking booking = Booking(
      id: tx.trackingCode,
      trackingCode: tx.trackingCode,
      customerId: 'demo-cust',
      customerName: tx.customerName,
      workerId: 'demo-worker',
      workerName: 'Ramesh Sharma',
      cooperativeName: 'Pune Electrical Workers Coop #4182',
      serviceCategory: 'Electrical',
      serviceTitle: tx.serviceTitle,
      scheduledDate: tx.date,
      serviceAddress: 'Paud Road, Kothrud, Pune - 411038',
      baseFare: tx.grossAmount.round(),
      welfareFee: tx.welfareContribution.round(),
      totalAmount: tx.netEarned.round(),
      status: BookingStatus.completed,
    );
    InvoiceModal.show(context, booking);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final WorkerDashboardState state = ref.watch(workerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Payouts', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Payouts',
            onPressed: () => ref.read(workerDashboardProvider.notifier).loadDashboard(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(workerDashboardProvider.notifier).loadDashboard();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Timeframe Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timeframes.map((String tf) {
                  final bool isSelected = _timeframe == tf;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tf),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isSelected ? AppColors.onPrimary : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onSelected: (bool sel) {
                        if (sel) setState(() => _timeframe = tf);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Hero Withdrawable Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFF27272A),
                    Color(0xFF18181B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'WITHDRAWABLE BALANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white70,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '0% Payout Fee',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      const Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _withdrawableBalance.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.account_balance_wallet_rounded, size: 13, color: Colors.white60),
                      const SizedBox(width: 5),
                      Text(
                        'Linked UPI: $_upiId',
                        style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _withdrawableBalance > 0 ? () => _openWithdrawModal(context) : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text(
                        'Withdraw to UPI Instantly',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Performance Metrics 2x2 Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: <Widget>[
                _buildMetricCard(
                  title: 'Gross Revenue',
                  value: '₹14,200',
                  subtitle: '+18% vs last cycle',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.success,
                  isDark: isDark,
                ),
                _buildMetricCard(
                  title: 'Welfare Saved (5%)',
                  value: '₹710',
                  subtitle: 'Health & accident cover',
                  icon: Icons.health_and_safety_rounded,
                  iconColor: AppColors.primary,
                  isDark: isDark,
                ),
                _buildMetricCard(
                  title: 'Completed Jobs',
                  value: '${state.historicalBookings.length + 28}',
                  subtitle: '100% on-time arrival',
                  icon: Icons.task_alt_rounded,
                  iconColor: Colors.blueAccent,
                  isDark: isDark,
                ),
                _buildMetricCard(
                  title: 'Average Fare',
                  value: '₹480',
                  subtitle: 'Fair wage benchmark',
                  icon: Icons.handshake_rounded,
                  iconColor: Colors.purpleAccent,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Weekly Cooperative Guild Bonus Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFB45309), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Guild Weekly Challenge',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '₹750 BONUS',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.onPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Complete 10 cooperative bookings with rating ≥ 4.8 to unlock the Federation Welfare Incentive Pool bonus.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.7,
                      minHeight: 8,
                      backgroundColor: Color(0xFFFDE68A),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '7 of 10 Completed (70%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        '3 jobs left • Ends Sun',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payout History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Recent Transactions & Payouts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${_demoTransactions.length} Records',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transactions List
            ..._demoTransactions.map((_EarningsTransaction tx) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tx.isWithdrawal
                          ? Colors.purple.withValues(alpha: 0.12)
                          : AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tx.isWithdrawal ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: tx.isWithdrawal ? Colors.purple : AppColors.success,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          tx.serviceTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${tx.isWithdrawal ? '-' : '+'}₹${tx.netEarned.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: tx.isWithdrawal ? Colors.purple : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          '${tx.trackingCode} • ${tx.date.day}/${tx.date.month}',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                        if (!tx.isWithdrawal)
                          InkWell(
                            onTap: () => _openInvoiceDemo(context, tx),
                            child: const Text(
                              'View Receipt',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else
                          Text(
                            'IMPS Settled',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// WITHDRAW TO UPI BOTTOM SHEET MODAL
// -------------------------------------------------------------

class _WithdrawUpiModal extends StatefulWidget {
  const _WithdrawUpiModal({
    required this.currentBalance,
    required this.upiId,
    required this.onWithdrawSuccess,
  });

  final double currentBalance;
  final String upiId;
  final ValueChanged<double> onWithdrawSuccess;

  @override
  State<_WithdrawUpiModal> createState() => _WithdrawUpiModalState();
}

class _WithdrawUpiModalState extends State<_WithdrawUpiModal> {
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.currentBalance > 0 ? widget.currentBalance.toStringAsFixed(0) : '0';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleWithdraw() {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Please enter a valid amount');
      return;
    }
    if (amount > widget.currentBalance) {
      setState(() => _errorText = 'Amount exceeds available balance');
      return;
    }

    setState(() {
      _errorText = null;
      _isProcessing = true;
    });

    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      widget.onWithdrawSuccess(amount);
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Instant Payout to UPI',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Disbursed through the Pune Cooperative Federation Direct Settlement Rail.',
            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 16),

          // Linked UPI ID card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'VERIFIED UPI ACCOUNT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                      ),
                      Text(
                        widget.upiId,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ACTIVE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.success)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
              labelText: 'Withdrawal Amount',
              errorText: _errorText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Amount Pills
          Row(
            children: <Widget>[
              ...<double>[500, 1000, 2000].map((double val) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text('₹${val.toStringAsFixed(0)}'),
                    onPressed: () => setState(() => _amountController.text = val.toStringAsFixed(0)),
                  ),
                );
              }),
              ActionChip(
                label: const Text('All Balance'),
                onPressed: () => setState(() => _amountController.text = widget.currentBalance.toStringAsFixed(0)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Submit button
          FilledButton(
            onPressed: _isProcessing ? null : _handleWithdraw,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : const Text('Transfer Now (Instant IMPS)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _EarningsTransaction {
  const _EarningsTransaction({
    required this.trackingCode,
    required this.serviceTitle,
    required this.customerName,
    required this.date,
    required this.grossAmount,
    required this.welfareContribution,
    required this.netEarned,
    this.isWithdrawal = false,
  });

  final String trackingCode;
  final String serviceTitle;
  final String customerName;
  final DateTime date;
  final double grossAmount;
  final double welfareContribution;
  final double netEarned;
  final bool isWithdrawal;
}

final List<_EarningsTransaction> _demoTransactions = <_EarningsTransaction>[
  _EarningsTransaction(
    trackingCode: 'TX-9812',
    serviceTitle: 'Main Switchboard Repair & MCB Replacement',
    customerName: 'Aditya Shah',
    date: DateTime.now().subtract(const Duration(hours: 4)),
    grossAmount: 480,
    welfareContribution: 24,
    netEarned: 456,
  ),
  _EarningsTransaction(
    trackingCode: 'TX-9784',
    serviceTitle: 'Instant Withdrawal to UPI',
    customerName: 'Ramesh Sharma',
    date: DateTime.now().subtract(const Duration(days: 1)),
    grossAmount: 1500,
    welfareContribution: 0,
    netEarned: 1500,
    isWithdrawal: true,
  ),
  _EarningsTransaction(
    trackingCode: 'TX-9750',
    serviceTitle: 'Ceiling Fan Installation & Regulator Rewiring',
    customerName: 'Pooja Kulkarni',
    date: DateTime.now().subtract(const Duration(days: 2)),
    grossAmount: 350,
    welfareContribution: 17.5,
    netEarned: 332.5,
  ),
  _EarningsTransaction(
    trackingCode: 'TX-9721',
    serviceTitle: 'Inverter Battery Terminal Cleaning & Inspection',
    customerName: 'Mahesh Deshmukh',
    date: DateTime.now().subtract(const Duration(days: 3)),
    grossAmount: 420,
    welfareContribution: 21,
    netEarned: 399,
  ),
];
