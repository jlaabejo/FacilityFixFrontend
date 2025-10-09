
import 'package:facilityfix/models/cards.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/notification.dart';
import 'package:facilityfix/staff/view_details/workorder.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const Color kPrimary = Color(0xFF005CE7);
  static const Color kPrimaryDark = Color(0xFF003E9C);
  static const Color kMutedText = Color(0xFF667085);

  int _selectedIndex = 3;
  DateTime _selectedDate = DateTime.now();
  final EasyDatePickerController _controller = EasyDatePickerController();

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  // Sample data
  final List<WorkOrder> _all = [
    WorkOrder(
      title: 'Leaking faucet',
      id: 'CS-2025-005',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
      statusTag: 'Pending',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Concern Slip',
      unitId: 'A 1001',
    ),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
      setState(() => _selectedIndex = index);
    }
  }

  // Helper to get tasks per day
  List<WorkOrder> _tasksFor(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _all.where((w) {
      final dt = w.createdAt;
      return DateTime(dt.year, dt.month, dt.day) == normalized;
    }).toList();
  }

  Widget _buildItem(WorkOrder w) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          leading: Icon(Icons.home_repair_service, color: kPrimary),
          title: Text(w.title),
          subtitle: Text('${w.requestTypeTag} • Unit ${w.unitId}'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  WorkOrderDetailsPage(selectedTabLabel: 'concern slip assigned'),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tasks = _tasksFor(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Calendar',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // === Date timeline with header ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: EasyTheme(
                    data: EasyTheme.of(context).copyWith(
                      dayBorder: WidgetStatePropertyAll(
                        BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: EasyDateTimeLinePicker.itemBuilder(
                      controller: _controller,
                      firstDate: DateTime(2025, 1, 1),
                      lastDate: DateTime(2030, 12, 31),
                      focusedDate: _selectedDate,
                      itemExtent: 64.0,
                      headerOptions: HeaderOptions(
                        // ✅ Jump-to-today icon moved to the RIGHT side
                        headerBuilder: (context, date, onTap) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: onTap,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    DateFormat.yMMMM().format(date),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _controller.jumpToDate(DateTime.now()),
                                icon:
                                    const Icon(Icons.today, color: kPrimary),
                                tooltip: 'Jump to Today',
                              ),
                            ],
                          );
                        },
                      ),
                      monthYearPickerOptions: MonthYearPickerOptions(
                        initialCalendarMode: EasyDatePickerMode.month,
                        cancelText: 'Cancel',
                        confirmText: 'Confirm',
                      ),
                      itemBuilder: (context, date, isSelected, isDisabled,
                          isToday, onTap) {
                        final isSameDay = date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day;
                        final dayLabel =
                            DateFormat.E().format(date).toUpperCase();

                        final BoxDecoration decoration;
                        if (isSameDay) {
                          decoration = BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: const [kPrimary, kPrimaryDark],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          );
                        } else if (isSelected) {
                          decoration = BoxDecoration(
                            color: kPrimary.withOpacity(.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: kPrimary.withOpacity(.35)),
                          );
                        } else {
                          decoration = BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade200),
                          );
                        }

                        final textColor = isSameDay
                            ? Colors.white
                            : (isSelected ? kPrimary : Colors.black87);

                        return InkResponse(
                          onTap: onTap,
                          highlightColor: Colors.transparent,
                          splashColor: kPrimary.withOpacity(.10),
                          child: Container(
                            width: 64,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            decoration: decoration,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      onDateChange: (date) =>
                          setState(() => _selectedDate = date),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // === Tasks list ===
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: tasks.isEmpty
                        ? const Center(
                            child: Text(
                              'No tasks for this day.',
                              style: TextStyle(color: kMutedText),
                            ),
                          )
                        : ListView.separated(
                            itemCount: tasks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => _buildItem(tasks[i]),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
