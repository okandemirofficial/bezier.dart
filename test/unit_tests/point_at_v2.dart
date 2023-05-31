import 'package:vector_math/vector_math_64.dart';

import '../testing_tools/testing_tools.dart';

void main() {
  group('pointAtV2', () {
    test('new pointAtV2 method test', () {
      var start = Vector2(0, 0);
      var control1 = Vector2(0, -5000);
      var control2 = Vector2(10000, -5000);
      var end = Vector2(10000, 0);

      final curve = CubicBezier([start, control1, control2, end]);

      Vector2 previousPoint = start;
      double averageDistance = 1392;

      for (double t = 0.1; t <= 1.0; t += 0.1) {
        var point = curve.pointAtV2(t);

        final distance = point.distanceTo(previousPoint);
        expect(averageDistance - distance < -10, false);
        expect(averageDistance - distance > 10, false);

        previousPoint = point;
      }
    });
  });
}
