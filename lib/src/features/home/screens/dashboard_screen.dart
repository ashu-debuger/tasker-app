import 'package:flutter/material.dart';

import '../widgets/plugin_action_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          PluginActionBar(),
          Expanded(child: Center(child: Text('Dashboard content goes here'))),
        ],
      ),
    );
  }
}
