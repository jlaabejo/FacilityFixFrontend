import 'dart:async';
import 'package:flutter/material.dart';

// Status Tab Selector
class TabItem {
  final String label;
  final int count;

  TabItem({required this.label, required this.count});
}

class StatusTabSelector extends StatelessWidget {
  final List<TabItem> tabs;
  final String selectedLabel;
  final ValueChanged<String> onTabSelected;

  const StatusTabSelector({
    super.key,
    required this.tabs,
    required this.selectedLabel,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: tabs.map((tab) {
          final bool isSelected = selectedLabel == tab.label;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(tab.label),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0056F8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        tab.label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFEFEFE)
                              : const Color(0xFF475467),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF95555)
                            : const Color(0xFFD0D5DD),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${tab.count}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFEFEFE),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Search and Filter Bar
class SearchAndFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedClassification;
  final List<String> classifications;
  final void Function(String) onSearchChanged;
  final void Function(String) onFilterChanged;

  const SearchAndFilterBar({
    super.key,
    required this.searchController,
    required this.selectedClassification,
    required this.classifications,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Row(
      children: [
        // Search Field (icon on left)
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignOutside,
                  color: Color(0xFFE5E7E8),
                ),
                borderRadius: borderRadius,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: Color(0xFF6E6E70)),
                const SizedBox(width: 8),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchController,
                    builder: (_, __, ___) {
                      return _DebouncedTextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          height: 1.83,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Search work orders...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Color(0xFF6E6E70),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.83,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Clear button
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (_, value, __) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF6E6E70)),
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Clear',
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Filter Button (same design; opens chip selector sheet)
        Container(
          width: 48,
          height: 48,
          decoration: ShapeDecoration(
            color: const Color(0xFFF4F5FF),
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: Color(0xFFE7E7E8)),
              borderRadius: borderRadius,
            ),
          ),
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () async {
              final picked = await _showChipFilterSheet(
                context,
                options: classifications,
                current: selectedClassification,
              );
              if (picked != null) onFilterChanged(picked);
            },
            child: const Center(
              child: Icon(Icons.tune, size: 20, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helper: bottom sheet with horizontal chips (single-select) ───────────────
Future<String?> _showChipFilterSheet(
  BuildContext context, {
  required List<String> options,
  required String current,
}) {
  String temp = current;

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final onSurface = Theme.of(ctx).colorScheme.onSurface;

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // grab handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDEE0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Text('Filter by classification',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Vertical chips
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: options.map((opt) {
                    final sel = opt == temp;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8), // spacing between chips
                      child: ChoiceChip(
                        label: Text(opt),
                        selected: sel,
                        onSelected: (_) {
                          temp = opt;
                          Navigator.pop(ctx, temp); // return immediately
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'All'),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset to All'),
                  style: TextButton.styleFrom(foregroundColor: onSurface),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── Helper: debounced TextField (for smooth typing) ──────────────────────────
class _DebouncedTextField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Duration duration;
  final InputDecoration decoration;
  final TextStyle? style;

  const _DebouncedTextField({
    required this.controller,
    required this.onChanged,
    required this.decoration,
    this.duration = const Duration(milliseconds: 250),
    this.style,
  });

  @override
  State<_DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<_DebouncedTextField> {
  Timer? _t;

  void _debounce(String v) {
    _t?.cancel();
    _t = Timer(widget.duration, () => widget.onChanged(v));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: _debounce,
      onSubmitted: widget.onChanged, // immediate on Enter
      textInputAction: TextInputAction.search,
      style: widget.style,
      decoration: widget.decoration,
    );
  }
}

// Add Button
class AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const AddButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.backgroundColor = const Color(0xFF213ED7),
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 24,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
// Filled Button
class FilledButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  final Color backgroundColor;
  final Color textColor;

  /// Optional fixed width/height; if null, sizes to parent constraints.
  final double? width;
  final double height;

  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? leadingIcon;

  final bool isLoading;
  final bool isDisabled;
  final Gradient? gradient;
  final double elevation;

  /// whether to show the outer white container with border
  final bool withOuterBorder;
  final IconData? icon;

  const FilledButton({
    super.key,
    required this.label,
    required VoidCallback onPressed,
    this.backgroundColor = const Color(0xFF005CE7),
    this.textColor = Colors.white,
    this.width,
    this.height = 48,
    this.borderRadius = 100,
    this.textStyle,
    this.leadingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.gradient,
    this.elevation = 2.0,
    this.withOuterBorder = true,
    this.icon,
  }) : onPressed = (isDisabled || isLoading) ? null : onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle = (textStyle ??
            theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            )) ??
        TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        );

    final disabled = onPressed == null;
    final baseColor = disabled ? const Color(0xFFEBECEF) : backgroundColor;
    final fgColor = disabled ? const Color(0xFF9CA3AF) : textColor;

    // Press/hover overlay color derived from base color
    Color overlay(Color c, double opacity) => c.withOpacity(opacity);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    Widget buttonCore = Material(
      elevation: elevation,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: gradient == null ? baseColor : null,
          gradient: disabled ? null : gradient,
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          splashColor: overlay(Colors.white, 0.20),
          highlightColor: overlay(Colors.black, 0.05),
          hoverColor: overlay(Colors.white, 0.06),
          focusColor: overlay(Colors.white, 0.12),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                      ),
                    )
                  : _ButtonContent(
                      key: const ValueKey('content'),
                      label: label,
                      textStyle: effectiveTextStyle.copyWith(color: fgColor),
                      leadingIcon: leadingIcon,
                      iconColor: fgColor,
                    ),
            ),
          ),
        ),
      ),
    );

    // ✅ Wrap in outer border only if enabled
    if (withOuterBorder) {
      buttonCore = Material(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(width: 1, color: Color(0xFFD0D5DD)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: buttonCore,
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: height + (withOuterBorder ? 24 : 0),
        maxWidth: width ?? double.infinity,
      ),
      child: buttonCore,
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final String label;
  final TextStyle textStyle;
  final IconData? leadingIcon;
  final Color iconColor;

  const _ButtonContent({
    super.key,
    required this.label,
    required this.textStyle,
    this.leadingIcon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = Text(label, textAlign: TextAlign.center, style: textStyle);

    if (leadingIcon == null) return content;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(leadingIcon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Flexible(child: content),
      ],
    );
  }
}


// Dropdown
class DropdownField<T> extends StatefulWidget {
  final String label;
  final T? value; // Single value
  final List<T>? values; // Multiple values
  final List<T> items;
  final void Function(T?)? onChanged; // For single select
  final void Function(List<T>)? onChangedMulti; // For multi select
  final bool isRequired;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isMultiSelect;
  final TextEditingController? otherController;

  const DropdownField({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.values,
    this.onChanged,
    this.onChangedMulti,
    this.isRequired = false,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.isMultiSelect = false,
    this.otherController,
  });

  @override
  State<DropdownField<T>> createState() => _DropdownFieldState<T>();
}

class _DropdownFieldState<T> extends State<DropdownField<T>> {
  bool showOtherInput = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isMultiSelect) {
      showOtherInput = widget.value != null && widget.value.toString() == 'Others';
    }
  }

  void _showMultiSelectDialog() async {
    final List<T> selected = List.from(widget.values ?? []);

    final result = await showDialog<List<T>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(widget.label),
            content: SingleChildScrollView(
              child: Column(
                children: widget.items.map((item) {
                  final isSelected = selected.contains(item);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(item.toString()),
                    onChanged: (checked) {
                      setStateDialog(() {
                        if (checked == true) {
                          selected.add(item);
                        } else {
                          selected.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, selected),
                child: const Text("OK"),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && widget.onChangedMulti != null) {
      widget.onChangedMulti!(result);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isRequired ? '${widget.label} *' : widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Multi-select mode
          if (widget.isMultiSelect)
            InkWell(
              onTap: _showMultiSelectDialog,
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Select ${widget.label}...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon,
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: -8,
                  children: (widget.values ?? [])
                      .map((val) => Chip(label: Text(val.toString())))
                      .toList(),
                ),
              ),
            )
          else
            DropdownButtonFormField<T>(
              value: widget.value,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Select ${widget.label}...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
              ),
              items: widget.items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  showOtherInput = val.toString() == 'Others';
                });
                widget.onChanged?.call(val);
              },
              validator: widget.isRequired
                  ? (val) => val == null ? '${widget.label} is required' : null
                  : null,
            ),

          if (showOtherInput && widget.otherController != null) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.otherController,
              decoration: InputDecoration(
                labelText: 'Please specify',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) {
                if (widget.isRequired &&
                    showOtherInput &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please specify';
                }
                return null;
              },
            ),
          ]
        ],
      ),
    );
  }
}

/// A reusable outlined pill-shaped button with optional icon.
/// - Honors [height] and [borderRadius].
/// - Disabled when [onPressed] is null or [isLoading] is true.
/// - Supports loading spinner and tooltip.
/// - Uses Ink ripple clipped to the rounded outline.
class OutlinedPillButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;

  final bool isLoading;

  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  final Color? backgroundColor; // fill behind outline (usually white/transparent)
  final Color? foregroundColor; // icon/text color
  final Color? borderColor;
  final double borderWidth;
  final Color? splashColor;

  final String? tooltip;

  const OutlinedPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 100,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.splashColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final enabled = onPressed != null && !isLoading;

    // Sensible defaults pulled from theme
    final Color fg = (foregroundColor ??
        (enabled ? const Color(0xFF374151) : theme.disabledColor));
    final Color bg = backgroundColor ?? Colors.white;
    final Color br = borderColor ??
        (enabled ? const Color(0xFFD0D5DD) : theme.disabledColor.withOpacity(0.5));
    final Color splash = splashColor ?? theme.colorScheme.primary.withOpacity(0.12);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: br, width: borderWidth),
    );

    Widget button = ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Material(
        color: Colors.transparent,
        shape: shape, // for proper ink clipping
        child: Ink(
          decoration: ShapeDecoration(color: bg, shape: shape),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            customBorder: shape,
            splashColor: splash,
            highlightColor: splash.withOpacity(0.6),
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.trim().isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }

    // Add semantics for accessibility (announce disabled/loading states)
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      value: isLoading ? 'Loading' : null,
      child: button,
    );
  }
}
