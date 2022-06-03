import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';

import 'birdpress.dart';

void main() {
  // Needed to not have the default path be /#/
  setPathUrlStrategy();
  runApp(const BirdPress());
}
