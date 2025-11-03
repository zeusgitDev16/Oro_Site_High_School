import 'package:flutter/material.dart';
import 'dart:async';
import 'package:oro_site_high_school/services/notification_service.dart';

/// Real-time Notification Badge Widget
/// Shows unread count with pulse animation
/// Updates automatically when new notifications arrive
class NotificationBadgeWidget extends StatefulWidget {
  final String userId;
  final VoidCallback onTap;
  final Color? badgeColor;
  final Color? iconColor;

  const NotificationBadgeWidget({
    super.key,
    required this.userId,
    required this.onTap,
    this.badgeColor,
    this.iconColor,
  });

  @override
  State<NotificationBadgeWidget> createState() => _NotificationBadgeWidgetState();
}

class _NotificationBadgeWidgetState extends State<NotificationBadgeWidget>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  Timer? _pollTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupPulseAnimation();
    _loadUnreadCount();
    _startPolling();
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount(widget.userId);
      if (mounted) {
        setState(() {
          final hadNewNotification = count > _unreadCount && _unreadCount > 0;
          _unreadCount = count;
          
          // Trigger pulse animation if new notification arrived
          if (hadNewNotification) {
            _triggerPulse();
          }
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _startPolling() {
    // Poll every 10 seconds for new notifications
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadUnreadCount();
    });
  }

  void _triggerPulse() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: IconButton(
                onPressed: widget.onTap,
                icon: Icon(
                  Icons.notifications_none,
                  color: widget.iconColor,
                ),
                tooltip: 'Notifications',
              ),
            );
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.badgeColor ?? Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.badgeColor ?? Colors.red).withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
