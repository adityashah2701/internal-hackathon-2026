import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Page 20 — Cooperative Safety & Emergency SOS Center
/// High-priority safety dispatch modal with live GPS broadcasting,
/// one-tap police emergency calling, and cooperative grievance cell helpline.
class SafetySosModal extends StatefulWidget {
  const SafetySosModal({super.key});

  @override
  State<SafetySosModal> createState() => _SafetySosModalState();
}

class _SafetySosModalState extends State<SafetySosModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isSosTriggered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerSosAlert() {
    setState(() => _isSosTriggered = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: <Widget>[
            Icon(Icons.shield_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'EMERGENCY SOS BROADCASTED! Cooperative Rapid Response Cell & 112 alerted with live GPS.',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _simulateDial(String number, String agency) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Dial $agency ($number)'),
          content: Text(
            'In production, this initiates a direct mobile phone call to $number with automatic cooperative incident logging.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Call Now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          // Sheet Drag Handle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const SizedBox(width: 40),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: <Widget>[
                  // SOS Pulsing Button Hero
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (BuildContext ctx, Widget? child) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error.withValues(alpha: 0.12 + (_pulseController.value * 0.1)),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.3 * _pulseController.value),
                              blurRadius: 28,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: _triggerSosAlert,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Icon(Icons.sos_rounded, color: Colors.white, size: 36),
                                Text(
                                  _isSosTriggered ? 'ACTIVE' : 'HOLD SOS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Cooperative Safety & Distress Center',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pressing SOS transmits your active booking, live GPS coordinates, and contact details to the district emergency monitoring cell.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54, height: 1.3),
                  ),
                  const SizedBox(height: 20),

                  // Active Location Tracking Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.share_location_rounded, color: AppColors.success, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Live GPS Safety Telemetry: ACTIVE',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '18.5074° N, 73.8077° E • Paud Road, Kothrud',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Emergency Helplines Direct Dial List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Direct Emergency Helplines',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('24x7 Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _buildHelplineCard(
                    title: 'National Emergency Helpline (Police/Fire)',
                    number: '112',
                    description: 'Direct priority line to Pune Police Control Room',
                    icon: Icons.local_police_rounded,
                    color: Colors.redAccent,
                    onTap: () => _simulateDial('112', 'National Emergency Police Helpline'),
                    isDark: isDark,
                  ),
                  _buildHelplineCard(
                    title: 'Cooperative Trust Safety & Rapid Response',
                    number: '1800-233-0890',
                    description: 'District Federation On-field Patrol & Artisan Support',
                    icon: Icons.shield_rounded,
                    color: AppColors.primary,
                    onTap: () => _simulateDial('1800-233-0890', 'Cooperative Rapid Response Cell'),
                    isDark: isDark,
                  ),
                  _buildHelplineCard(
                    title: 'Women Safety & Anti-Harassment Helpline',
                    number: '1091',
                    description: 'State commission dedicated helpline for women',
                    icon: Icons.support_agent_rounded,
                    color: Colors.purpleAccent,
                    onTap: () => _simulateDial('1091', 'Women Safety Helpline'),
                    isDark: isDark,
                  ),
                  _buildHelplineCard(
                    title: 'Emergency Medical & Ambulance Care',
                    number: '108',
                    description: 'State Health Authority Medical Response',
                    icon: Icons.medical_services_rounded,
                    color: AppColors.success,
                    onTap: () => _simulateDial('108', 'Emergency Ambulance Dispatch'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineCard({
    required String title,
    required String number,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white54 : Colors.black54),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.call, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                number,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
