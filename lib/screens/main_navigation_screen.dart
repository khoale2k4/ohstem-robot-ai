import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:robot_ai/features/main/auto_navigation/auto_navigation.dart';
import 'package:robot_ai/features/main/follow_human/follow_human_screen.dart';
import 'package:robot_ai/features/main/manual_control/manual_control_screen.dart';

class MainNavigationScreen extends HookWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(0);

    final screens = [
      const ManualControlPage(),
      const FollowHumanPage(),
      const AutoNavigationPage(),
    ];

    return Scaffold(
      body: screens[currentIndex.value],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex.value,
        onTap: (index) => currentIndex.value = index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.control_camera),
            label: 'Manual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search),
            label: 'Follow',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.navigation),
            label: 'Auto Nav',
          ),
        ],
      ),
    );
  }
} 