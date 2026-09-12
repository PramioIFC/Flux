// dart_io_stub.dart
// Este arquivo é usado apenas na compilação web (dart.library.html).
// Ele fornece stubs vazios das classes do dart:io que não existem no web,
// evitando erros de compilação.

class File {
  final String path;
  File(this.path);
  Future<bool> exists() async => false;
  Future<String> readAsString() async => '';
  Future<File> writeAsBytes(List<int> bytes) async => this;
  Directory get parent => Directory('');
}

class Directory {
  final String path;
  Directory(this.path);
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isWindows => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
  static bool get isFuchsia => false;
  static bool get isWeb => true;
}
