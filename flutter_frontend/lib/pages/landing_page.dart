import 'package:flutter/material.dart';
import 'package:flutter_frontend/pages/ai_interface.dart';
import 'package:get/get.dart';

import '../controllers/user_controller.dart';
import '../widgets/animated_app_bar.dart';
import 'ai_backend.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialize GetX controllers
    Get.put(UserController());

    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);

    // Initialize pages list here where instance methods can be accessed
    _pages = [
      const AIInterfacePage(), // AI Mind tab
      const AIChatPage(), // Interface tab
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AnimatedAppBar(
        title: '🌜CTech AGI',
      ),
      body: Column(
        children: [
          // Tab Bar below App Bar
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade300,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: const [
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('Interface'),
                    ],
                  ),
                ),
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.psychology, size: 20),
                      SizedBox(width: 8),
                      Text('AI Brain'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}
