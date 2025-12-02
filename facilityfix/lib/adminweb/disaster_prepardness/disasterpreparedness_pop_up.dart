import 'package:flutter/material.dart';

class ViewFileDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const ViewFileDialog({super.key, required this.data});

  static void show(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ViewFileDialog(data: data);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final checklistCompleted = data['checklist_completed'] as List? ?? [];
    final completedCount = checklistCompleted.where((item) => item['completed'] == true).length;
    final totalCount = checklistCompleted.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return AlertDialog(
      content: Container(
        width: 550,
        height: 526,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1.23,
              color: Colors.black.withValues(alpha: 0.10),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 15,
              offset: Offset(0, 10),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 25,
              top: 25,
              child: Container(
                width: 491,
                height: 58,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Container(
                      width: 438.17,
                      height: 29.99,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0.22,
                            top: -2.55,
                            child: Text(
                              data['task_title'] ?? data['title'] ?? 'Task Details',
                              style: TextStyle(
                                color: const Color(0xFF0A0A0A),
                                fontSize: 20,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w700,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 438.17,
                      height: 19.99,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 438.17,
                            child: Text(
                              'Manage checklist items and task assignment',
                              style: TextStyle(
                                color: const Color(0xFF717182),
                                fontSize: 14,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 25,
              top: 99,
              child: Container(
                width: 500,
                height: 403,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 23.99,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Container(
                          width: 500,
                          height: 41.49,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 16.49,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 500,
                                      child: Text(
                                        'Description',
                                        style: TextStyle(
                                          color: const Color(0xFF959FA3),
                                          fontSize: 11,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 20.99,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: -0.77,
                                      child: Text(
                                        data['task_description'] ?? data['description'] ?? 'No description available',
                                        style: TextStyle(
                                          color: const Color(0xFF191B1C),
                                          fontSize: 14,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      height: 71.48,
                      padding: const EdgeInsets.only(top: 15.99, left: 15.99, right: 15.99),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF5F5F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 19.49,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 185.88,
                              children: [
                                Container(
                                  width: 93.20,
                                  height: 19.49,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Overall Progress',
                                        style: TextStyle(
                                          color: const Color(0xFF0A0A0A),
                                          fontSize: 13,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 127.09,
                                  height: 19.49,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: -2,
                                        child: SizedBox(
                                          width: 128,
                                          child: Text(
                                            '$completedCount / $totalCount completed (${(progress * 100).toInt()}%)',
                                            style: TextStyle(
                                              color: const Color(0xFF0A0A0A),
                                              fontSize: 13,
                                              fontFamily: 'Arial',
                                              fontWeight: FontWeight.w400,
                                              height: 1.50,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            height: 12,
                            padding: EdgeInsets.only(right: 500 * (1 - progress)),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFE5E7E8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(41284500),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 12,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF005CE7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(41284500),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Container(
                          width: 500,
                          height: 23.99,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 4,
                                child: Container(
                                  width: 15.99,
                                  height: 15.99,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(),
                                  child: Stack(),
                                ),
                              ),
                              Positioned(
                                left: 23.99,
                                top: -1.77,
                                child: Text(
                                  'Task Checklist',
                                  style: TextStyle(
                                    color: const Color(0xFF0A0A0A),
                                    fontSize: 16,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 500,
                          height: 206,
                          child: ListView.builder(
                            itemCount: checklistCompleted.length,
                            itemBuilder: (context, index) {
                              final item = checklistCompleted[index];
                              final isCompleted = item['completed'] == true;
                              return Container(
                                width: 500,
                                height: 46,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.only(
                                  top: 13.23,
                                  left: 13.23,
                                  right: 13.23,
                                  bottom: 1.23,
                                ),
                                decoration: ShapeDecoration(
                                  color: isCompleted ? const Color(0xFFE8F5E9) : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1.23,
                                      color: isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFE5E7E8),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 12,
                                  children: [
                                    Container(
                                      width: 15.99,
                                      height: 15.99,
                                      padding: const EdgeInsets.all(1.23),
                                      decoration: ShapeDecoration(
                                        color: isCompleted ? Colors.white : Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            width: 1.23,
                                            color: isCompleted ? const Color(0xFF2E7D32) : const Color(0xFF959FA3),
                                          ),
                                          borderRadius: BorderRadius.circular(41284500),
                                        ),
                                      ),
                                      child: isCompleted
                                          ? const Icon(Icons.check, size: 12, color: Color(0xFF2E7D32))
                                          : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        item['task'] ?? item['name'] ?? 'Unnamed task',
                                        style: TextStyle(
                                          color: isCompleted ? const Color(0xFF626C70) : const Color(0xFF191B1C),
                                          fontSize: 14,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                                          height: 1.50,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 507,
              top: 17,
              child: Opacity(
                opacity: 0.70,
                child: Container(
                  width: 18,
                  height: 16,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -44.61,
                        top: 15.22,
                        child: Container(
                          width: 1,
                          height: 1,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: Stack(
                            children: [
                              Positioned(
                                left: -1,
                                top: -1.77,
                                child: Text(
                                  'Close',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF0A0A0A),
                                    fontSize: 16,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 517,
              top: 17,
              child: Container(
                width: 15.99,
                height: 15.99,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(),
                child: Stack(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: () {
            // Add assign logic here
          },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}