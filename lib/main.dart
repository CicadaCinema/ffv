import 'dart:io';
import 'package:crypto/crypto.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: "ffv",
      color: Colors.blue,
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      home: ExampleDragTarget(),
    );
  }
}

class ExampleDragTarget extends StatefulWidget {
  const ExampleDragTarget({Key? key}) : super(key: key);

  @override
  _ExampleDragTargetState createState() => _ExampleDragTargetState();
}

class _ExampleDragTargetState extends State<ExampleDragTarget> {
  List<XFile> _fileList = [];
  List<String> _fileHashes = [];
  int _filesChosen = 0;

  bool _dragging = false;
  int _currentIndex = 0;
  bool? _hashResult = null;

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
        print("File $filename does not exist.");
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
    return NavigationView(
      content: NavigationBody(index: _currentIndex, children: [
        Container(
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
                            ? "Loading..."
                            : _hashResult!
                                ? "MATCH"
                                : "NO MATCH",
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
                        child: const Text("Refresh"),
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
                  child: Container(
                    child: Center(
                      child: Text(
                        (_filesChosen + 1).toString(),
                        style: _bigStyle,
                      ),
                    ),
                  ),
                ),
        ),
        const Center(
          child: Text("Settings!"),
        )
      ]),
    );
  }
}
