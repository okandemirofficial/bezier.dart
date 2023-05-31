import 'package:vector_math/vector_math_64.dart';

import '../testing_tools/testing_tools.dart';

void main() {
  group('constructor', () {
    test('constructor with three-entry look up table', () {
      final lookUpTable = <Vector2>[Vector2(0.0, 0.0), Vector2(2.0, 0.0), Vector2(3.0, 0.0)];
      final object = EvenSpacer(lookUpTable);
      expect(object, TypeMatcher<EvenSpacer>());
    });
  });
}
