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

// Search and Filter
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
    return Row(
      children: [

        // Search Field
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
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
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.search, size: 24, color: Color(0xFF6E6E70)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Filter Button
        Container(
          width: 48,
          height: 48,
          decoration: ShapeDecoration(
            color: const Color(0xFFF4F5FF), // background color here
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: Color(0xFFE7E7E8)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt_outlined, size: 20, color: Colors.black),
            onSelected: onFilterChanged,
            itemBuilder: (BuildContext context) {
              return classifications.map((String value) {
                return PopupMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                );
              }).toList();
            },
          ),
        )

      ],
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

// Text Button
class FilledButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;

  const FilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF005CE7),
    this.textColor = Colors.white,
    this.width = 375,
    this.height = 80,
    this.borderRadius = 100,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(
        side: BorderSide(
        width: 1,
        color: const Color(0xFFD0D5DD),
        ),
        ),
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: ShapeDecoration(
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: textStyle ??
                TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.43,
                  letterSpacing: 0.10,
                ),
          ),
        ),
      ),
    );
  }
}




