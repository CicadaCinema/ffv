import 'package:fluent_ui/fluent_ui.dart';

import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';

import 'ffi.dart';

enum ComparisonState {
  choosing1,
  choosing2,
  loading,
  result,
}

const TextStyle _bigStyle = TextStyle(
  fontSize: 64,
  fontWeight: FontWeight.bold,
);

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({Key? key}) : super(key: key);

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final List<XFile> _files1 = [];
  final List<XFile> _files2 = [];

  var _dragging = false;
  late bool _hashResult;

  var _currentState = ComparisonState.choosing1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _dragging ? Colors.blue : Colors.white,
      child: _currentState == ComparisonState.choosing1 ||
              _currentState == ComparisonState.choosing2
          ? DropTarget(
              onDragDone: (detail) {
                // hard exit if the user has dropped more than one file
                // TODO: add support for multiple files
                if (detail.files.length != 1) {
                  exit(0);
                }

                if (_currentState == ComparisonState.choosing1) {
                  _files1.addAll(detail.files);
                  setState(() {
                    _currentState = ComparisonState.choosing2;
                  });
                } else {
                  _files2.addAll(detail.files);
                  setState(() {
                    _currentState = ComparisonState.loading;
                  });
                  api
                      .compare(
                        left: _files1.first.path,
                        right: _files2.first.path,
                      )
                      .then((value) => setState(() {
                            _hashResult = value;
                            _currentState = ComparisonState.result;
                          }));
                }
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
                  _currentState == ComparisonState.choosing1 ? '1' : '2',
                  style: _bigStyle,
                ),
              ),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              color: _currentState == ComparisonState.loading
                  ? null
                  : _hashResult
                      ? Colors.green
                      : Colors.red,
              child: _currentState == ComparisonState.loading
                  ? const Center(
                      child: Text(
                        'Loading...',
                        style: _bigStyle,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _hashResult ? 'MATCH' : 'NO MATCH',
                          style: _bigStyle,
                        ),
                        Button(
                          onPressed: () {
                            _files1.clear();
                            _files2.clear();
                            setState(() {
                              _currentState = ComparisonState.choosing1;
                            });
                          },
                          child: const Text('Refresh'),
                        )
                      ],
                    ),
            ),
    );
  }
}
