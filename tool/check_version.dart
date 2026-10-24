import 'dart:io';

void main(List<String> arguments) {
  final content = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)\+([1-9]\d*)\s*$',
    multiLine: true,
  ).firstMatch(content);
  if (match == null) {
    _fail('Use version: MAJOR.MINOR.PATCH+BUILD em pubspec.yaml.');
  }

  final version = match.group(1)!;
  final build = match.group(2)!;
  final expectedTag = 'v$version-demo.$build';
  if (arguments.length == 1 && arguments.single == '--print-demo-tag') {
    stdout.writeln(expectedTag);
    return;
  }
  if (arguments.isNotEmpty) {
    _fail('Uso: dart tool/check_version.dart [--print-demo-tag]');
  }

  final releaseTag = Platform.environment['RELEASE_TAG'] ?? '';
  if (releaseTag.isNotEmpty && releaseTag != expectedTag) {
    _fail(
      'A tag $releaseTag não corresponde a $version+$build. '
      'A tag demo esperada é $expectedTag.',
    );
  }
  stdout.writeln(
    'Versão $version+$build válida'
    '${releaseTag.isEmpty ? '' : ' para $releaseTag'}.',
  );
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
