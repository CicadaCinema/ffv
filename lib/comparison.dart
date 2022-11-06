import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as path;

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
  List<XFile> _files1 = [];
  List<XFile> _files2 = [];

  var _dragging = false;
  late bool? _hashResult;

  var _currentState = ComparisonState.choosing1;

  // used by the progress indicator
  var completedSize = 0;
  var totalSize = 0;
  var fileCount = 0;

  Future<void> executeComparison() async {
    void invalidateResult() {
      setState(() {
        _hashResult = null;
        _currentState = ComparisonState.result;
      });
    }

    /// Return a list containing all the files listed in [filesAndDirectories]
    /// as well as the (recursive) contents of any directories given in the input list.
    List<XFile> traverseDirectories(List<XFile> filesAndDirectories) {
      // TODO: can we do this by mutating filesAndDirectories directory instead of returning a value?
      final List<XFile> newFiles = [];
      filesAndDirectories.removeWhere((xFile) {
        final potentialDir = Directory(xFile.path);
        if (potentialDir.existsSync()) {
          newFiles.addAll(potentialDir
              .listSync(recursive: true)
              .whereType<File>()
              .map((e) => XFile(e.path)));
          return true;
        }
        return false;
      });
      return [...filesAndDirectories, ...newFiles];
    }

    // if any directories are to be compared, traverse them and add their contents
    _files1 = traverseDirectories(_files1);
    _files2 = traverseDirectories(_files2);

    setState(() {
      fileCount = _files1.length;
    });

    // ensure the file count is consistent
    if (_files1.length != _files2.length) {
      invalidateResult();
      return;
    }

    // sort files canonically by their path
    sortByPath(XFile a, XFile b) =>
        path.canonicalize(a.path).compareTo(path.canonicalize(b.path));
    _files1.sort(sortByPath);
    _files2.sort(sortByPath);

    // ensure the file sizes are consistent
    for (var i = 0; i < _files1.length; i++) {
      if ((await _files1[i].length()) != (await _files2[i].length())) {
        invalidateResult();
        return;
      }
      totalSize += await _files1[i].length();
    }

    // compare file hashes one by one
    // TODO: implement multithreading according to the number of available cores
    for (var i = 0; i < _files1.length; i++) {
      // if any pair of files have different hashes, terminate the comparison immediately
      if (!(await api.compare(
        left: _files1[i].path,
        right: _files2[i].path,
      ))) {
        setState(() {
          _hashResult = false;
          _currentState = ComparisonState.result;
        });
        return;
      }

      // update the progress bar
      final fileSize = await _files1[i].length();
      setState(() {
        completedSize += fileSize;
      });
    }

    setState(() {
      _hashResult = true;
      _currentState = ComparisonState.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _dragging ? Colors.blue : Colors.white,
      child: _currentState == ComparisonState.choosing1 ||
              _currentState == ComparisonState.choosing2
          ? DropTarget(
              onDragDone: (detail) {
                if (_currentState == ComparisonState.choosing1) {
                  // the files on one side of the comparison
                  _files1.addAll(detail.files);
                  setState(() {
                    _currentState = ComparisonState.choosing2;
                  });

                  return;
                } else {
                  // the files on the other side of the comparison
                  _files2.addAll(detail.files);
                  setState(() {
                    _currentState = ComparisonState.loading;
                  });
                }

                // both lists of files are now populated
                executeComparison();
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
                  // an invalid comparison counts as a fail
                  : _hashResult ?? false
                      ? Colors.green
                      : Colors.red,
              child: _currentState == ComparisonState.loading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'LOADING',
                          style: _bigStyle,
                        ),
                        Text('Comparing $fileCount files...'),
                        ProgressBar(
                          value: totalSize == 0
                              ? 0
                              : (completedSize / totalSize) * 100,
                        )
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _hashResult == null
                              ? 'INVALID'
                              : _hashResult!
                                  ? 'MATCH'
                                  : 'NO MATCH',
                          style: _bigStyle,
                        ),
                        Button(
                          onPressed: () {
                            _files1.clear();
                            _files2.clear();
                            completedSize = 0;
                            totalSize = 0;
                            fileCount = 0;
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
