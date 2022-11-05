import 'package:ffv/comparison.dart';
import 'package:fluent_ui/fluent_ui.dart';

void main() {
  runApp(const MainScreen());
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'ffv',
      color: Colors.blue,
      home: NavigationView(
        pane: NavigationPane(
          selected: _currentIndex,
          onChanged: (index) => setState(() => _currentIndex = index),
          displayMode: PaneDisplayMode.top,
          items: [
            PaneItem(
              icon: const Icon(FluentIcons.check_mark),
              title: const Text('Verify'),
              body: const ComparisonScreen(),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.settings),
              title: const Text('Settings'),
              body: const Center(
                child: Text('Settings!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
