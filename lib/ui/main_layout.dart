import 'package:flutter/material.dart';
import 'package:kisandost_app/ui/pages/results_page.dart';
import 'package:kisandost_app/ui/widgets/db_sidebar.dart';
import 'package:kisandost_app/ui/widgets/welcome_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String? _selectedDbPath;

  void _onDbSelected(String dbPath) {
    setState(() {
      _selectedDbPath = dbPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          DbSidebar(
            onDbSelected: _onDbSelected,
            selectedDbPath: _selectedDbPath,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: _selectedDbPath == null
                ? const WelcomeScreen()
                : ResultsPage(
                    key: ValueKey(_selectedDbPath),
                    dbPath: _selectedDbPath!,
                  ),
          ),
        ],
      ),
    );
  }
}