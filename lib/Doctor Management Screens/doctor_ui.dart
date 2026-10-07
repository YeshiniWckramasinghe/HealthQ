import 'package:flutter/material.dart';

import '../services/doctor_availability_service.dart';
import '../services/doctor_profile_service.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colours (built on the shared AppColors so the module matches the rest of the
// app)
// ─────────────────────────────────────────────────────────────────────────────

class DoctorColors {
  DoctorColors._();

  static const Color bg = AppColors.primary100;
  static const Color teal = AppColors.primary300;
  static const Color tealDark = AppColors.primary400;
  static const Color tealSoft = Color(0xFFE3F1F0);
  static const Color ink = AppColors.textDark;
  static const Color muted = AppColors.gray400;
  static const Color hint = AppColors.gray300;
  static const Color line = Color(0xFFE5ECEB);

  static const Color green = Color(0xFF1E8E3E);
  static const Color greenBg = Color(0xFFE6F4EA);
  static const Color amber = Color(0xFFD99A00);
  static const Color amberBg = Color(0xFFFFF4CC);
  static const Color orange = AppColors.statusWaitingText;
  static const Color orangeBg = AppColors.statusWaitingBg;
  static const Color blue = Color(0xFF2F80ED);
  static const Color blueBg = Color(0xFFE3F0FF);
  static const Color red = AppColors.statusAbsentText;
  static const Color redBg = AppColors.statusAbsentBg;
  static const Color grayBg = Color(0xFFEDEDED);
}

class StatusStyle {
  final String label;
  final Color fg;
  final Color bg;
  const StatusStyle(this.label, this.fg, this.bg);
}

class DoctorStatus {
  DoctorStatus._();

  static const StatusStyle _waiting =
      StatusStyle('Waiting', DoctorColors.orange, DoctorColors.orangeBg);

  /// [waiting] = true labels 'next' / 'upcoming' as "Waiting" (home + queue).
  static StatusStyle appointment(String status, {bool waiting = false}) {
    switch (status) {
      case 'completed':
        return const StatusStyle(
            'Completed', DoctorColors.green, DoctorColors.greenBg);
      case 'in_progress':
        return const StatusStyle(
            'In Progress', DoctorColors.amber, DoctorColors.amberBg);
      case 'next':
        return waiting
            ? _waiting
            : const StatusStyle('Next', DoctorColors.blue, DoctorColors.blueBg);
      default:
        return waiting
            ? _waiting
            : const StatusStyle(
                'Upcoming', DoctorColors.muted, DoctorColors.grayBg);
    }
  }

  static StatusStyle slot(String displayStatus) {
    switch (displayStatus) {
      case 'unavailable':
        return const StatusStyle(
            'Unavailable', DoctorColors.red, DoctorColors.redBg);
      case 'pending':
        return const StatusStyle(
            'Pending', DoctorColors.amber, DoctorColors.amberBg);
      case 'approved':
        return const StatusStyle(
            'Approved', DoctorColors.blue, DoctorColors.blueBg);
      case 'rejected':
        return const StatusStyle(
            'Rejected', DoctorColors.red, DoctorColors.redBg);
      default:
        return const StatusStyle(
            'Available', DoctorColors.green, DoctorColors.greenBg);
    }
  }

  static StatusStyle request(String status) {
    switch (status) {
      case 'approved':
        return const StatusStyle(
            'Approved', DoctorColors.green, DoctorColors.greenBg);
      case 'rejected':
        return const StatusStyle(
            'Rejected', DoctorColors.red, DoctorColors.redBg);
      case 'cancelled':
        return const StatusStyle(
            'Cancelled', DoctorColors.muted, DoctorColors.grayBg);
      default:
        return const StatusStyle(
            'Pending', DoctorColors.amber, DoctorColors.amberBg);
    }
  }

  /// Colour used for "Available" / "Unavailable" text.
  static Color availability(String status) =>
      status == 'unavailable' ? DoctorColors.red : DoctorColors.green;

  static String availabilityLabel(String status) =>
      status == 'unavailable' ? 'Unavailable' : 'Available';
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatting (no intl dependency)
// ─────────────────────────────────────────────────────────────────────────────

class DoctorFmt {
  DoctorFmt._();

  static const List<String> _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];
  static const List<String> _days = <String>[
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
    'Sunday'
  ];

  static String _mon3(int m) => _months[m - 1].substring(0, 3);
  static String _day3(int wd) => _days[wd - 1].substring(0, 3);

  static DateTime? parseDate(String iso) => DateTime.tryParse(iso);

  /// "09:30" -> ["09:30", "AM"]
  static List<String> time12Parts(String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return <String>[hhmm, ''];
    final h = int.tryParse(p[0].trim());
    final m = int.tryParse(p[1].trim());
    if (h == null || m == null) return <String>[hhmm, ''];
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return <String>[
      '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
      h >= 12 ? 'PM' : 'AM',
    ];
  }

  /// "13:05" -> "01:05 PM"
  static String time12(String hhmm) {
    final p = time12Parts(hhmm);
    return p[1].isEmpty ? p[0] : '${p[0]} ${p[1]}';
  }

  /// "2026-09-20" -> "20 September 2026"
  static String dateLong(String iso) {
    final d = parseDate(iso);
    if (d == null) return iso;
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// "2026-09-20" -> "20 September 2026 - Sunday"
  static String dateLongWithDay(String iso) {
    final d = parseDate(iso);
    if (d == null) return iso;
    return '${dateLong(iso)} - ${_days[d.weekday - 1]}';
  }

  /// "2026-09-20" -> "20 Sep 2026"
  static String dateShort(String iso) {
    final d = parseDate(iso);
    if (d == null) return iso;
    return '${d.day} ${_mon3(d.month)} ${d.year}';
  }

  /// DateTime -> "19 Sep 2026"
  static String dateShortOf(DateTime d) => '${d.day} ${_mon3(d.month)} ${d.year}';

  /// "2026-09-20" -> "20 Sep"
  static String dayMonth(String iso) {
    final d = parseDate(iso);
    if (d == null) return iso;
    return '${d.day} ${_mon3(d.month)}';
  }

  /// "2026-09-20" -> "Sun"
  static String weekdayShort(String iso) {
    final d = parseDate(iso);
    return d == null ? '' : _day3(d.weekday);
  }

  /// "Tue, 29 Apr 2025"
  static String headerDate(DateTime d) =>
      '${_day3(d.weekday)}, ${d.day} ${_mon3(d.month)} ${d.year}';

  /// "19 Sep 2026, 10:30 AM"
  static String dateTime(DateTime d) {
    final hhmm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${d.day} ${_mon3(d.month)} ${d.year}, ${time12(hhmm)}';
  }

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

/// Safe initials: never throws on empty / double-spaced names.
String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

void showDoctorSnack(BuildContext context, String message,
    {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? DoctorColors.red : DoctorColors.green,
      content: Text(message),
    ),
  );
}

String cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');

/// Standard confirm dialog. Returns true only when the user taps confirm.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w800, color: DoctorColors.ink)),
      content: Text(message,
          style: const TextStyle(color: DoctorColors.muted, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel,
              style: const TextStyle(color: DoctorColors.muted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: danger ? DoctorColors.red : DoctorColors.teal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Session scope - gives every doctor screen the logged-in doctor's live profile
// ─────────────────────────────────────────────────────────────────────────────

class DoctorSessionScope extends InheritedWidget {
  final DoctorProfile profile;
  final String today; // yyyy-MM-dd
  final ValueChanged<int> switchTab;
  final VoidCallback logout;

  const DoctorSessionScope({
    super.key,
    required this.profile,
    required this.today,
    required this.switchTab,
    required this.logout,
    required super.child,
  });

  static DoctorSessionScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<DoctorSessionScope>();
    assert(scope != null,
        'DoctorSessionScope not found - doctor screens must live under DoctorDashboardScreen.');
    return scope!;
  }

  @override
  bool updateShouldNotify(DoctorSessionScope oldWidget) =>
      profile != oldWidget.profile || today != oldWidget.today;
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Scaffold used by every screen inside the dashboard. The dashboard already
/// resizes for the keyboard and owns the bottom bar, so inner scaffolds must
/// not do either (otherwise the inset is applied twice).
class DoctorScaffold extends StatelessWidget {
  final Widget child;
  const DoctorScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorColors.bg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(bottom: false, child: child),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;

  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.color = DoctorColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class DoctorHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const DoctorHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          if (onBack != null) ...[
            RoundIconButton(icon: Icons.arrow_back, onTap: onBack),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: DoctorColors.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                        fontSize: 13, color: DoctorColors.muted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Header with a back arrow that pops the current route.
class DoctorPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const DoctorPageHeader(
      {super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return DoctorHeader(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onBack: () => Navigator.of(context).maybePop(),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  const DoctorCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

class StatusChip extends StatelessWidget {
  final StatusStyle style;
  const StatusChip(this.style, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: style.fg,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DoctorColors.ink,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DoctorColors.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DoctorColors.teal.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

class OutlineActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final double height;

  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = DoctorColors.teal,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: Colors.white,
          side: BorderSide(color: color, width: 1.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style:
                  const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: DoctorColors.hint),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DoctorColors.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final Object error;
  const ErrorState(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      message: 'Could not load data.\n${cleanError(error)}',
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  final bool rounded; // true = circle, false = rounded square
  final Color textColor;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 52,
    this.color = DoctorColors.teal,
    this.rounded = true,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: rounded ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: rounded ? null : BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// The doctor's own avatar: photo (if one is ever stored) or coloured initials.
class DoctorAvatar extends StatelessWidget {
  final DoctorProfile profile;
  final double size;
  const DoctorAvatar({super.key, required this.profile, this.size = 92});

  @override
  Widget build(BuildContext context) {
    final color = profile.avatarColor != null
        ? Color(profile.avatarColor!)
        : DoctorColors.teal;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: color,
      child: Text(
        profile.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
    );

    final photo = profile.photoUrl;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DoctorColors.teal, width: 2.5),
        color: Colors.white,
      ),
      child: ClipOval(
        child: photo == null
            ? fallback
            : Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications (bell) - recent decisions on availability requests
// ─────────────────────────────────────────────────────────────────────────────

class DoctorBell extends StatelessWidget {
  const DoctorBell({super.key});

  @override
  Widget build(BuildContext context) {
    return RoundIconButton(
      icon: Icons.notifications_none_rounded,
      onTap: () => showDoctorNotifications(context),
    );
  }
}

void showDoctorNotifications(BuildContext context) {
  final doctorId = DoctorSessionScope.of(context).profile.staffId;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DoctorColors.ink),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<AvailabilityRequest>>(
                stream: DoctorAvailabilityService.instance
                    .requestsStream(doctorId),
                builder: (context, snap) {
                  final decided = (snap.data ?? const <AvailabilityRequest>[])
                      .where((r) =>
                          r.status == 'approved' || r.status == 'rejected')
                      .take(6)
                      .toList();
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (decided.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('You\'re all caught up.',
                            style: TextStyle(color: DoctorColors.muted)),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final r in decided)
                        _NotificationTile(request: r),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _NotificationTile extends StatelessWidget {
  final AvailabilityRequest request;
  const _NotificationTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final approved = request.status == 'approved';
    final style = DoctorStatus.request(request.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: style.bg, shape: BoxShape.circle),
            child: Icon(
              approved ? Icons.check_rounded : Icons.close_rounded,
              color: style.fg,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request ${request.id} ${approved ? 'approved' : 'rejected'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: DoctorColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DoctorFmt.dateShort(request.date)} · ${request.slotLabel}',
                  style: const TextStyle(
                      fontSize: 12, color: DoctorColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
