import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: buildAppBar(), // search and filter
    body: Column(
      children: [
        const SizedBox(height: 40), 
        Center( 
          child: Container(
            width: 287,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1,
                  color: Color(0xFFE5E7E8),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: 'Search work orders...',
                      hintStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                        height: 1.83,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.black54,
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


  AppBar buildAppBar() { //breadcrumbs
    return AppBar(
      title: const Text(
        'Repair Request Management',
        style: TextStyle(
          color: Color.fromARGB(255, 0, 0, 0),
          fontSize: 18,
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: false,
      leading: GestureDetector(
        onTap: () {
          // Handle profile icon tap
        },
        child: Container(
          margin: const EdgeInsets.all(10),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/profile.svg',
            height: 40,
            width: 40,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5FF),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            // Handle notification icon tap
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            alignment: Alignment.center,
            width: 37,
            child: SvgPicture.asset(
              'assets/icons/notification.svg',
              height: 20,
              width: 20,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5FF),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }
}
