import 'package:flutter/foundation.dart';

String getBuildModeLabel() {
  if (kReleaseMode) return 'release';
  if (kProfileMode) return 'profile';
  return 'debug';
}