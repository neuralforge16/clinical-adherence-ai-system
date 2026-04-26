import 'package:flutter/material.dart';
import '../core/api_service.dart';

/// Drop-in replacement for the plain bell icon in the top bar.
/// Shows a red badge when there are alerts, and a dropdown list on tap.
/// Usage: replace the existing bell Container with NotificationBell()
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _cardBg = Colors.white;
  static const Color _mutedText = Color(0xFF6B7280);
  static const Color _pageBg = Color(0xFFF5F7FB);

  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final data = await ApiService.getAlerts();
      if (mounted) {
        setState(() {
          _alerts = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDropdown(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _cardBg,
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _DropdownContent(
            alerts: _alerts,
            loading: _loading,
            onRefresh: () {
              Navigator.pop(context);
              setState(() => _loading = true);
              _loadAlerts();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAlerts = _alerts.isNotEmpty;

    return Tooltip(
      message: hasAlerts
          ? '${_alerts.length} alert${_alerts.length == 1 ? '' : 's'}'
          : 'Notifications',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showDropdown(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasAlerts ? const Color(0xFFFFF1F2) : _cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasAlerts
                        ? const Color(0xFFFDA4AF)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Icon(
                  hasAlerts ? Icons.notifications : Icons.notifications_none,
                  color: hasAlerts ? const Color(0xFFEF4444) : _mutedText,
                  size: 18,
                ),
              ),
              // Red badge
              if (hasAlerts)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _alerts.length > 9 ? '9+' : '${_alerts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownContent extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final bool loading;
  final VoidCallback onRefresh;

  const _DropdownContent({
    required this.alerts,
    required this.loading,
    required this.onRefresh,
  });

  static const Color _mutedText = Color(0xFF6B7280);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _primary = Color(0xFF1E4ED8);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                const Text(
                  'Alerts',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 16, color: _mutedText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: _primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No alerts right now',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All patients are on track.',
                    style: TextStyle(color: _mutedText, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final alert = alerts[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert['patient']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert['message']?.toString() ?? '',
                              style: const TextStyle(
                                color: _mutedText,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Alerts are based on recent dose logs.',
              style: TextStyle(
                color: _mutedText.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
