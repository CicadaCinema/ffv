import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:ffv/bridge_generated.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';

import 'ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'ffv',
      color: Colors.blue,
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<XFile> _fileList = [];
  final List<String> _fileHashes = [];
  int _filesChosen = 0;

  bool _dragging = false;
  int _currentIndex = 0;
  bool? _hashResult;

  final TextStyle _bigStyle = const TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.bold,
  );

  Future<void> _executeComparison() async {
    for (final file in _fileList) {
      // copied from
      // https://github.com/dart-lang/crypto/blob/master/example/example.dart
      var filename = file.path;
      var input = File(filename);

      if (!input.existsSync()) {
        if (kDebugMode) {
          print('File $filename does not exist.');
        }
        exit(66);
      }

      var value = await sha512.bind(input.openRead()).first;
      _fileHashes.add(value.toString());
    }

    _hashResult = _fileHashes[0] == _fileHashes[1];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // TODO: remove this test
    api.add(left: 3, right: 38).then((value) => print(value));
    return NavigationView(
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
        displayMode: PaneDisplayMode.top,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.check_mark),
            title: const Text('Verify'),
            body: Container(
              color: _dragging ? Colors.blue : Colors.white,
              child: _filesChosen == 2
                  ? Container(
                      width: MediaQuery.of(context).size.width,
                      color: _hashResult == null
                          ? null
                          : _hashResult!
                              ? Colors.green
                              : Colors.red,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _hashResult == null
                                ? 'Loading...'
                                : _hashResult!
                                    ? 'MATCH'
                                    : 'NO MATCH',
                            style: _bigStyle,
                          ),
                          Button(
                            onPressed: () {
                              _fileList.clear();
                              _fileHashes.clear();
                              _filesChosen = 0;
                              _hashResult = null;
                              setState(() {});
                            },
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : DropTarget(
                      onDragDone: (detail) {
                        setState(() {
                          // hard exit if the user has dropped more than one file
                          if (detail.files.length != 1) {
                            exit(0);
                          }
                          // TODO: add support for multiple files
                          // _list.addAll(detail.files);

                          _fileList.add(detail.files[0]);
                          _filesChosen += 1;

                          if (_filesChosen == 2) {
                            _executeComparison();
                          }
                        });
                      },
                      onDragEntered: (detail) {
                        setState(() {
                          _dragging = true;
                        });
                      },
                      onDragExited: (detail) {
                        setState(() {
                          _dragging = false;
                        });
                      },
                      child: Center(
                        child: Text(
                          (_filesChosen + 1).toString(),
                          style: _bigStyle,
                        ),
                      ),
                    ),
            ),
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
    );
  }
}
