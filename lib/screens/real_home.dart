import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';

class RealHome extends StatelessWidget {
  const RealHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Real Home"),
        backgroundColor: AppColors.purple,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1B1B1B),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purple.withOpacity(0.3),
                      AppColors.purple.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [AppColors.purple, Color(0xFFF97316)],
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.sparkles,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'MindQuest',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: const [
                    ListTile(
                      leading: Icon(LucideIcons.home, color: Colors.white70),
                      title: Text('Home', style: TextStyle(color: Colors.white)),
                    ),
                    ListTile(
                      leading: Icon(LucideIcons.target, color: Colors.white70),
                      title: Text('Challenges', style: TextStyle(color: Colors.white)),
                    ),
                    ListTile(
                      leading: Icon(LucideIcons.users, color: Colors.white70),
                      title: Text('Community', style: TextStyle(color: Colors.white)),
                    ),
                    ListTile(
                      leading: Icon(LucideIcons.user, color: Colors.white70),
                      title: Text('Profile', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, color: Colors.blue, size: 80),
            SizedBox(height: 20),
            Text(
              "Welcome to the Real App!",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "This is the main interface of your application. "
                    "All app features are accessible here.",
                style: TextStyle(color: Colors.black54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B1B1B),
        selectedItemColor: AppColors.purple,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.target), label: 'Challenges'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
        currentIndex: 0,
        onTap: (index) {
          // Navigation logic يمكن إضافته لاحقًا
        },
      ),
    );
  }
}
