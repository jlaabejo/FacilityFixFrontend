import 'package:flutter/material.dart';

/// Delete Confirmation Dialog
Future<bool> showDeleteDialog(
  BuildContext context, {
  String? itemName,
  String? description,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => DeleteDialog(
      itemName: itemName,
      description: description,
    ),
  );
  return result ?? false;
}

/// Delete Dialog Widget
class DeleteDialog extends StatefulWidget {
  final String? itemName;
  final String? description;

  const DeleteDialog({
    super.key,
    this.itemName,
    this.description,
  });

  @override
  State<DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<DeleteDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close(bool result) async {
    await _controller.reverse();
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: DialogContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                const DeleteIcon(),
                const SizedBox(height: 24),
                DialogTitle(text: 'Delete ${widget.itemName ?? 'Item'}?'),
                const SizedBox(height: 12),
                DialogDescription(
                  text: widget.description ??
                      'This action cannot be undone. All associated data will be permanently removed from the system.',
                ),
                const SizedBox(height: 32),
                DialogActions(
                  onCancel: () => _close(false),
                  onDelete: () => _close(true),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog Container
class DialogContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const DialogContainer({
    super.key,
    required this.child,
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Delete Icon
class DeleteIcon extends StatelessWidget {
  final double size;
  final double iconSize;
  final Color bg;
  final Color fg;

  const DeleteIcon({
    super.key,
    this.size = 72,
    this.iconSize = 36,
    this.bg = const Color(0xFFFEE2E2),
    this.fg = const Color(0xFFEF4444),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(Icons.delete_outline_rounded, size: iconSize, color: fg),
    );
  }
}

/// Dialog Title
class DialogTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  const DialogTitle({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.fontWeight = FontWeight.w700,
    this.color = const Color(0xFF1F2937),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFamily: 'Inter',
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

/// Dialog Description
class DialogDescription extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  const DialogDescription({
    super.key,
    required this.text,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w400,
    this.color = const Color(0xFF6B7280),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.5,
          color: color,
          fontFamily: 'Inter',
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

/// Dialog Actions
class DialogActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final EdgeInsets padding;
  final double spacing;

  const DialogActions({
    super.key,
    required this.onCancel,
    required this.onDelete,
    this.padding = const EdgeInsets.symmetric(horizontal: 32),
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: DialogButton(
              label: 'Cancel',
              onPressed: onCancel,
              bg: const Color(0xFFF3F4F6),
              fg: const Color(0xFF374151),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: DialogButton(
              label: 'Delete',
              onPressed: onDelete,
              bg: const Color(0xFFEF4444),
              fg: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog Button
class DialogButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color bg;
  final Color fg;
  final double height;
  final double radius;
  final double fontSize;
  final FontWeight fontWeight;

  const DialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.bg,
    required this.fg,
    this.height = 50,
    this.radius = 12,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
  });

  @override
  State<DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<DialogButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: widget.bg.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                color: widget.fg,
                fontFamily: 'Inter',
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}