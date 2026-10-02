import 'dart:async';
import 'package:flutter/material.dart';

class AppToast {
  static OverlayEntry? _currentEntry;

  static void showError(BuildContext context, String message) {
    _show(context, message, background: Theme.of(context).colorScheme.error, icon: Icons.error_outline);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, background: Theme.of(context).colorScheme.tertiary, icon: Icons.check_circle_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, background: Theme.of(context).colorScheme.secondary, icon: Icons.info_outline);
  }

  static void _show(BuildContext context, String message, {required Color background, IconData? icon}) {
    // Remove any existing toast
    _removeCurrent();

    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        background: background,
        icon: icon,
        duration: const Duration(seconds: 3),
        onDismissed: () {
          _removeCurrent();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _removeCurrent() {
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color background;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastWidget({Key? key, required this.message, required this.background, this.icon, required this.duration, required this.onDismissed}) : super(key: key);

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<Offset> _offset = Tween(begin: const Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, () async {
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).viewPadding.top + 8.0;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offset,
        child: Material(
          color: widget.background,
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white),
                  const SizedBox(width: 12),
                ],
                Expanded(child: Text(widget.message, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
