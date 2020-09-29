import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:injectable_generator/model/micro_package_model.dart';

/// Builds a json file that aggregates all the micro_package.json files
/// that exist in /features folder
/// The json file should be compliant with [MicroPackageModuleModel] structure
/// TODO make 'features' folder configurable
/// TODO make outputFileName configurable
class InjectableMicroPackagesConfigAggregator implements Builder {
  static const generatedOutputFileName = "micro_packages.json";

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    log.fine('Starting build w/ buildStep ${buildStep}');

    if (!await Directory(Directory.current.path + '/features').exists()) {
      //if the folder doesn't exist we are not supporting micropackages or maybe we are inside one... just leave
      return;
    }
    var featureUriSet = await Future.wait(
        await Directory(Directory.current.path + '/features')
            .list(recursive: true)
            .where((file) =>
                _getExtension(file.path, dept: 2) == 'micropackage.json')
            .map((file) async => await _toMicroPackageModuleModel(file))
            .toList());

    log.warning(
        "Found ${featureUriSet.length} micro packages with micropackage.json file");

    return await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'lib/${generatedOutputFileName}'),
        jsonEncode(featureUriSet));
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        r'$lib$': [generatedOutputFileName],
      };

  /// Returns text after the .(dot) in given path
  /// Example this.file.dart
  /// for dept = 1 => .dart
  /// for dept = 2 => .file.dart
  /// returns empty_string if no . is found
  String _getExtension(String path, {int dept = 1}) {
    if (!path.contains('.')) return "";
    var lastIndex = -1;
    var tempPath = path;
    for (var i = 0; i < dept; i++) {
      int curLastIndex = tempPath.lastIndexOf('.');
      if (curLastIndex > -1) {
        tempPath = tempPath.substring(0, curLastIndex);
        lastIndex = tempPath.length + 1;
      }
    }
    return path.substring(lastIndex);
  }

  Future<MicroPackageModuleModel> _toMicroPackageModuleModel(
      FileSystemEntity file) async {
    var jsonString = await new File(file.path).readAsString();
    Map<String, dynamic> map = jsonDecode(jsonString);
    return MicroPackageModuleModel.fromJson(map);
  }
}
