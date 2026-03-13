class BuildInfo {
  static const String buildTime =
  String.fromEnvironment('BUILD_TIME', defaultValue: '');

  static const String gitHash =
  String.fromEnvironment('GIT_HASH', defaultValue: '');
}