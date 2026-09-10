import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Page 21 — Cooperative Help, FAQ & Dispute Resolution Center
/// Comprehensive customer and worker assistance with knowledge base,
/// cooperative ombudsman grievance ticket creation, and immediate live chat.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  final List<String> _categories = <String>[
    'All Topics',
    'Cooperative Model',
    'Pricing & Fair Wages',
    'Welfare Fund',
    'Cancellations & Safety',
  ];

  final List<_FaqItem> _faqs = const <_FaqItem>[
    _FaqItem(
      category: 'Cooperative Model',
      question: 'How does Sahayog eliminate corporate middleman commissions?',
      answer:
          'Unlike private aggregator platforms that charge 25-35% commission on every job, Sahayog is owned collectively by the registered district workers cooperative federation. 100% of the labour charge goes directly to the worker, keeping prices fair for customers and wages livable for workers.',
    ),
    _FaqItem(
      category: 'Pricing & Fair Wages',
      question: 'How are the service base fares determined?',
      answer:
          'Service tariffs are benchmarked against official State Labour Board minimum wage standards. There is zero algorithmic surge pricing during rains, peak hours, or high demand.',
    ),
    _FaqItem(
      category: 'Welfare Fund',
      question: 'What is the 5-10% Cooperative Welfare contribution used for?',
      answer:
          'Every booking includes a transparent contribution pooled into the state-supervised Worker Welfare & Social Security Trust. This provides free medical emergency cover, occupational accident insurance (up to ₹5,00,000), tool subsidies, and children educational stipends for member artisans.',
    ),
    _FaqItem(
      category: 'Cancellations & Safety',
      question: 'Are workers background-checked and identity verified?',
      answer:
          'Yes. Every artisan is physically verified by an accredited Cooperative Primary Society Officer. Verification includes Aadhaar biometric verification, police clearance, and trade competency certification (ITI or Guild Board test).',
    ),
    _FaqItem(
      category: 'Pricing & Fair Wages',
      question: 'What happens if I am not satisfied with the quality of repair?',
      answer:
          'All cooperative services carry a 7-day workmanship re-service guarantee. You can raise a dispute ticket below, and an independent master craftsman inspector will be dispatched to resolve it at zero cost.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateTicketModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => const _CreateDisputeTicketModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<_FaqItem> displayedFaqs = _faqs.where((_FaqItem item) {
      if (_selectedCategoryIndex != 0 && item.category != _categories[_selectedCategoryIndex]) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final String q = _searchController.text.toLowerCase();
        return item.question.toLowerCase().contains(q) || item.answer.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Dispute Center', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF27272A), Color(0xFF18181B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Cooperative Member Ombudsman',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Independent community dispute arbitration board. All complaints resolved within a mandatory 2-hour window.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openCreateTicketModal(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.report_problem_outlined, size: 18),
                    label: const Text(
                      'Raise Dispute / File Complaint',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search answers, policies, welfare rules...',
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List<Widget>.generate(_categories.length, (int index) {
                final bool isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_categories[index]),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isSelected ? AppColors.onPrimary : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    onSelected: (bool sel) {
                      if (sel) setState(() => _selectedCategoryIndex = index);
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // FAQs Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text('${displayedFaqs.length} Answers', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),

          ...displayedFaqs.map((_FaqItem faq) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  faq.question,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                children: <Widget>[
                  Text(
                    faq.answer,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });

  final String category;
  final String question;
  final String answer;
}

// -------------------------------------------------------------
// DISPUTE TICKET BOTTOM SHEET MODAL
// -------------------------------------------------------------

class _CreateDisputeTicketModal extends StatefulWidget {
  const _CreateDisputeTicketModal();

  @override
  State<_CreateDisputeTicketModal> createState() => _CreateDisputeTicketModalState();
}

class _CreateDisputeTicketModalState extends State<_CreateDisputeTicketModal> {
  final TextEditingController _detailsController = TextEditingController();
  String _selectedIssueType = 'Workmanship / Incomplete Job';
  bool _isSubmitting = false;

  final List<String> _issueTypes = <String>[
    'Workmanship / Incomplete Job',
    'Pricing or Overcharging Discrepancy',
    'Delayed or No-Show by Worker',
    'Safety or Behaviour Concern',
    'Welfare Claim Query',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide details regarding the dispute')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      showDialog<void>(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: <Widget>[
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                SizedBox(width: 8),
                Text('Dispute Logged'),
              ],
            ),
            content: const Text(
              'Ticket #DISP-4820 has been assigned to the Pune Urban Cooperative Federation Ombudsman. An officer will contact you within 2 business hours.',
              style: TextStyle(fontSize: 13, height: 1.35),
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Acknowledged'),
              ),
            ],
          );
        },
      );
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
            'Raise Official Cooperative Grievance',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 4),
          const Text(
            'Governed by the Maharashtra Cooperative Societies Act resolution mandate.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Issue type dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedIssueType,
            decoration: InputDecoration(
              labelText: 'Select Grievance Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _issueTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type, style: const TextStyle(fontSize: 12.5)),
              );
            }).toList(),
            onChanged: (String? val) {
              if (val != null) setState(() => _selectedIssueType = val);
            },
          ),
          const SizedBox(height: 14),

          // Details
          TextField(
            controller: _detailsController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Describe the issue in detail',
              hintText: 'Include tracking code, date of service, and details for the arbitrator...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          // Submit
          FilledButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : const Text('Submit to Ombudsman Board', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
