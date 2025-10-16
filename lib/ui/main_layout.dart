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
  String? _newSessionImagePath;
  String? _selectedDbPath;

  void _onImageSelected(String path) {
    setState(() {
      _newSessionImagePath = path;
      _selectedDbPath = null;
    });
  }

  void _onDbSelected(String dbPath) {
    setState(() {
      _selectedDbPath = dbPath;
      _newSessionImagePath = null;
    });
  }

  Widget _buildMainContent() {
    if (_newSessionImagePath != null) {
      return ResultsPage(
        key: ValueKey(_newSessionImagePath),
        imagePath: _newSessionImagePath!,
      );
    }
    if (_selectedDbPath != null) {
      return Center(child: Text("Viewing old session: $_selectedDbPath"));
    }
    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          DbSidebar(
            onDbSelected: _onDbSelected,
            onImageSelected: _onImageSelected, // Pass the new callback
            selectedDbPath: _selectedDbPath,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }
}