import 'package:facilityfix/widgets/modals.dart';
import 'package:flutter/material.dart';

class AvailabilityTabWidget extends StatefulWidget {
  const AvailabilityTabWidget({
    Key? key,
    required this.tabs,
    required this.selectedLabel,
    required this.onTabSelected,
  }) : super(key: key);

  final List<String> tabs;
  final String selectedLabel;
  final Function(String) onTabSelected;

  @override
  State<AvailabilityTabWidget> createState() => _AvailabilityTabWidgetState();
}

class _AvailabilityTabWidgetState extends State<AvailabilityTabWidget> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final tabHeight = isMobile ? 40.0 : 50.0;

    // Build a Figma-style rounded pill tab widget with a pale-blue background.
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: const Color(0xFFDBEAFE), // pale-blue background per Figma
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children:
            widget.tabs.map((tab) {
              final isSelected = widget.selectedLabel == tab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTabSelected(tab),
                  child: Container(
                    height:
                        tabHeight - 10, // inner height fits the design (approx)
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: ShapeDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          width: 1.26,
                          color:
                              isSelected
                                  ? Colors.transparent
                                  : Colors
                                      .transparent, // invisible stroke as per Figma
                        ),
                      ),
                      shadows:
                          isSelected
                              ? const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        tab,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF0A0A0A),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight:
                              isSelected ? FontWeight.w400 : FontWeight.w400,
                          height: 1.43,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// Schedule Availability Card
class ScheduleAvailabilityWidget extends StatefulWidget {
  const ScheduleAvailabilityWidget({super.key});

  @override
  State<ScheduleAvailabilityWidget> createState() =>
      _ScheduleAvailabilityWidgetState();
}

class _ScheduleAvailabilityWidgetState
    extends State<ScheduleAvailabilityWidget> {
  // State for day selections - true means available
  Map<String, bool> _dayAvailability = {
    'Mon': true,
    'Tue': true,
    'Wed': true,
    'Thu': true,
    'Fri': true,
    'Sat': false,
  };

  void _toggleDay(String day) {
    setState(() {
      _dayAvailability[day] = !_dayAvailability[day]!;
    });
  }

  void _selectAllDays() {
    setState(() {
      _dayAvailability.updateAll((key, value) => true);
    });
  }

  void _selectWeekdaysOnly() {
    setState(() {
      _dayAvailability['Mon'] = true;
      _dayAvailability['Tue'] = true;
      _dayAvailability['Wed'] = true;
      _dayAvailability['Thu'] = true;
      _dayAvailability['Fri'] = true;
      _dayAvailability['Sat'] = false;
    });
  }

  void _submitAvailability() {
    // TODO: Implement submit logic
    print('Submitting availability: $_dayAvailability');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth - 32; // Account for padding
    final cardWidth = containerWidth - 32; // Account for internal padding

    // Don't embed its own scroll view — parent (ProfilePage) already provides scrolling.
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main container
          Container(
            width: containerWidth,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Color(0xFF005CE7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'This Week',
                                style: TextStyle(
                                  color: Color(0xFF191B1C),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nov 18 - Nov 24, 2024',
                            style: TextStyle(
                              color: Color(0xFF626C70),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.50,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_dayAvailability.values.where((v) => v).length}/7',
                          style: const TextStyle(
                            color: Color(0xFF005CE7),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.50,
                          ),
                        ),
                        const Text(
                          'Days',
                          style: TextStyle(
                            color: Color(0xFF626C70),
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Days list
                Column(children: _buildDayCards(cardWidth)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Select buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectAllDays,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1.27,
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Select All Days',
                        style: TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.43,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Submit button
          GestureDetector(
            onTap: _submitAvailability,
            child: Container(
              width: containerWidth,
              height: 56,
              decoration: ShapeDecoration(
                color: const Color(0xFF005CE7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Center(
                child: Text(
                  'Submit Availability',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDayCards(double cardWidth) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final fullDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    return List.generate(days.length, (index) {
      final day = days[index];
      final fullDay = fullDays[index];
      final isAvailable = _dayAvailability[day]!;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _toggleDay(day),
          child: Container(
            width: cardWidth,
            height: 66.52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ShapeDecoration(
              color:
                  isAvailable
                      ? const Color(0xFFE7F7EF)
                      : const Color(0xFFF5F6F7),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1.27,
                  color:
                      isAvailable
                          ? const Color(0xFF0FAF62)
                          : const Color(0xFFE5E6E8),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: ShapeDecoration(
                          color:
                              isAvailable
                                  ? const Color(0xFF0FAF62)
                                  : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color:
                                  isAvailable
                                      ? Colors.white
                                      : const Color(0xFF959FA3),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullDay,
                              style: const TextStyle(
                                color: Color(0xFF191B1C),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              isAvailable ? 'Available' : 'Unavailable',
                              style: const TextStyle(
                                color: Color(0xFF626C70),
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 32,
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: ShapeDecoration(
                    color:
                        isAvailable
                            ? const Color(0xFF005CE7) // Active (blue)
                            : const Color(0xFFCBCED4), // Inactive (muted gray)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 150),
                    alignment:
                        isAvailable
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: OvalBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// Day Off Requests Card
class DayOffRequestsWidget extends StatelessWidget {
  const DayOffRequestsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      height: isMobile ? 100 : 120.93,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: const Color(0xFF005CE7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Opacity(
              opacity: 0.30,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: isMobile ? 100 : 120.93,
              ),
            ),
          ),
          Positioned(
            left: isMobile ? 16 : 23.99,
            top: isMobile ? 16 : 23.99,
            right: isMobile ? 16 : 0,
            child: Container(
              height: isMobile ? 68 : 72.96,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 3.98,
                      children: [
                        Text(
                          'Day Off Requests',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 20,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.50,
                          ),
                        ),
                        Text(
                          'Request time off and track your submissions',
                          style: TextStyle(
                            color: const Color(0xCCFFFEFE),
                            fontSize: isMobile ? 12 : 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final DayOffResult? res =
                            await showModalBottomSheet<DayOffResult>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => const DayOffRequest(),
                            );

                        if (res != null && context.mounted) {
                          final days = res.selectedDates.length;
                          final reason = res.reason;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Day off request submitted: $days day(s) — $reason',
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: 8,
                        ),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              size: isMobile ? 14 : 16,
                              color: const Color(0xFF005CE7),
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'New Request',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF005CE7),
                                fontSize: isMobile ? 12 : 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                height: 1.43,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Day Off Card Details
enum DayOffStatus { pending, approved, rejected }

class DayOffRequestCard extends StatelessWidget {
  final String date;
  final String timeAgo;
  final DayOffStatus status;
  final String reason;
  final String? adminNote;

  const DayOffRequestCard({
    Key? key,
    required this.date,
    required this.timeAgo,
    required this.status,
    required this.reason,
    this.adminNote,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (status) {
      case DayOffStatus.pending:
        return const Color(0xFFFFFAEB);
      case DayOffStatus.approved:
        return const Color(0xFFE8F7F1);
      case DayOffStatus.rejected:
        return const Color(0xFFFDEDED);
    }
  }

  Color _getStatusTextColor() {
    switch (status) {
      case DayOffStatus.pending:
        return const Color(0xFFF79009);
      case DayOffStatus.approved:
        return const Color(0xFF19B36E);
      case DayOffStatus.rejected:
        return const Color(0xFFE84545);
    }
  }

  String _getStatusText() {
    switch (status) {
      case DayOffStatus.pending:
        return 'Pending';
      case DayOffStatus.approved:
        return 'Approved';
      case DayOffStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.26, color: Color(0xFFE5E7E8)),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(19.98),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 11.99,
              children: [
                // Header with date and status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        spacing: 11.99,
                        children: [
                          // Avatar placeholder
                          Container(
                            width: 47.99,
                            height: 47.99,
                            decoration: ShapeDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment(0.00, 0.00),
                                end: Alignment(1.00, 1.00),
                                colors: [Color(0xFFEEF5FE), Color(0xFFDAEAFE)],
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF0066CC),
                              size: 24,
                            ),
                          ),
                          // Date and time info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 3.98,
                              children: [
                                Text(
                                  date,
                                  style: const TextStyle(
                                    color: Color(0xFF191B1C),
                                    fontSize: 15,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                                Text(
                                  timeAgo,
                                  style: const TextStyle(
                                    color: Color(0xFF959FA3),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: _getStatusColor(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusTextColor(),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.50,
                        ),
                      ),
                    ),
                  ],
                ),
                // Reason section
                Padding(
                  padding: const EdgeInsets.only(left: 59.99),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3.98,
                    children: [
                      Text(
                        'REASON',
                        style: const TextStyle(
                          color: Color(0xFF626C70),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                      Text(
                        reason,
                        style: const TextStyle(
                          color: Color(0xFF191B1C),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                    ],
                  ),
                ),
                // Admin note for rejected status
                if (status == DayOffStatus.rejected && adminNote != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 59.99),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13.25),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFDEDED),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1.26,
                            color: Color(0xFFE84545),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 3.98,
                        children: [
                          const Text(
                            'Rejected by Admin',
                            style: TextStyle(
                              color: Color(0xFFE84545),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.50,
                            ),
                          ),
                          Text(
                            adminNote!,
                            style: const TextStyle(
                              color: Color(0xFF4A5154),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
