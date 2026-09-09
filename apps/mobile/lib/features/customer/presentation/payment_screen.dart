import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../controllers/customer_booking_controller.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  String? _errorMessage;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'verify-razorpay-payment',
        body: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'booking_id': widget.booking.id,
        },
      );

      await ref.read(customerDashboardProvider.notifier).loadCustomerBookings();

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment verification failed: $e';
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
      _errorMessage = 'Payment failed: ${response.message}';
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optional handle external wallet
  }

  Future<void> _processRazorpayPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final FunctionResponse res = await Supabase.instance.client.functions.invoke(
        'create-razorpay-order',
        body: {
          'booking_id': widget.booking.id,
          'amount': widget.booking.totalAmount * 100,
        },
      );

      final String orderId = (res.data as Map<String, dynamic>)['id'] as String;
      final String razorpayKey = dotenv.env['RAZORPAY_API_KEY'] ?? '';

      final Map<String, dynamic> options = <String, dynamic>{
        'key': razorpayKey,
        'amount': widget.booking.totalAmount * 100,
        'name': 'Sahayog Services',
        'order_id': orderId,
        'description': widget.booking.serviceTitle,
        'prefill': <String, dynamic>{
          'contact': '9999999999',
          'email': 'customer@sahayog.coop'
        },
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to initialize payment: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: <Widget>[
                  _buildLineItem('Service', widget.booking.serviceTitle, isDark),
                  const SizedBox(height: 12),
                  _buildLineItem('Base Fare', '₹${widget.booking.baseFare}', isDark),
                  if (widget.booking.isUrgent) ...<Widget>[
                    const SizedBox(height: 12),
                    _buildLineItem('Emergency Surcharge', '₹100', isDark),
                  ],
                  const SizedBox(height: 12),
                  _buildLineItem('Cooperative Welfare (10%)', '₹${widget.booking.welfareFee}', isDark),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Total to Pay',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '₹${widget.booking.totalAmount}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodOption(
              icon: Icons.account_balance_rounded,
              title: 'UPI / Bank Transfer',
              subtitle: 'Google Pay, PhonePe, Paytm',
              isSelected: true,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodOption(
              icon: Icons.credit_card_rounded,
              title: 'Credit / Debit Card',
              subtitle: 'Visa, MasterCard, RuPay',
              isSelected: false,
              isDark: isDark,
            ),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processRazorpayPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Pay ₹${widget.booking.totalAmount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sandbox Mode: No real funds will be deducted.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
  }) {
    final Color borderColor = isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3);
    final Color bgColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.05)
        : (isDark ? AppColors.surfaceDark : Colors.white);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 28, color: isSelected ? AppColors.primary : Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Icon(
            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            color: isSelected ? AppColors.primary : Colors.grey,
          ),
        ],
      ),
    );
  }
}
