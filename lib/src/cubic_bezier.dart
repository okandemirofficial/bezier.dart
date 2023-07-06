import 'dart:math';

import 'package:vector_math/vector_math_64.dart';

import 'package:bezier/bezier.dart';

/// Concrete class of cubic Bézier curves.
class CubicBezier extends Bezier {
  /// Constructs a cubic Bézier curve from a [List] of [Vector2].  The first point
  /// in [points] will be the curve's start point, the second and third points will
  /// be its control points, and the fourth point will be its end point.
  CubicBezier(List<Vector2> points) : super(points) {
    if (points.length != 4) {
      throw ArgumentError('Cubic Bézier curves require exactly four points');
    }

    ///GPT GENERATED
    for (var i = 0; i <= 100; i++) {
      var t = i / 100.0;
      var pt = _calculateBezierVector2(t, points);
      if (i > 0) {
        var dx = pt.x - _calculateBezierVector2(t - 0.01, points).x;
        var dy = pt.y - _calculateBezierVector2(t - 0.01, points).y;
        totalLength += sqrt(dx * dx + dy * dy);
      }
      arcLengths.add(totalLength);
    }
  }

  ///GPT GENERATED
  List<double> arcLengths = [];
  double totalLength = 0.0;

  ///GPT GENERATED
  Vector2 _calculateBezierVector2(double t, List<Vector2> controlVector2s) {
    double x = 0.0, y = 0.0;

    int n = controlVector2s.length - 1;
    for (int i = 0; i <= n; i++) {
      var binCoeff = _binomialCoefficient(n, i);
      var powTerm = pow(1 - t, n - i) * pow(t, i);
      x += binCoeff * powTerm * controlVector2s[i].x;
      y += binCoeff * powTerm * controlVector2s[i].y;
    }
    return Vector2(x, y);
  }

  ///GPT Generated
  int _binomialCoefficient(int n, int k) {
    if (k < 0 || k > n) return 0;
    if (k == 0 || k == n) return 1;
    int coeff = 1;
    if (k > n - k) k = n - k;
    for (var i = 0; i < k; i++) {
      coeff *= (n - i);
      coeff ~/= (i + 1);
    }
    return coeff;
  }

  ///GPT Generated
  double _getNormalizedT(double t) {
    var targetLength = t * totalLength;
    if (arcLengths.isEmpty) {
      return 0.0; // Handle case when array is empty
    }
    var low = 0, high = arcLengths.length - 1;
    while (low < high) {
      var mid = (low + (high - low) / 2).floor();
      if (arcLengths[mid] < targetLength) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    if (low > 0 && arcLengths[low] > targetLength) {
      low--;
    }
    // Bound check to avoid index out of range
    if (low < 0) low = 0;
    if (low >= arcLengths.length - 1) low = arcLengths.length - 2;
    var lengthBefore = arcLengths[low];
    var segmentLength = arcLengths[low + 1] - lengthBefore;
    if (segmentLength <= 0) {
      return low / 100.0; // Handle division by zero case
    }
    var segmentT = (targetLength - lengthBefore) / segmentLength;
    return (low + segmentT) / 100.0;
  }

  @override
  int get order => 3;

  ///Old approach
  @override
  Vector2 pointAt(double t) {
    final t2 = t * t;
    final mt = 1.0 - t;
    final mt2 = mt * mt;

    final a = mt2 * mt;
    final b = mt2 * t * 3;
    final c = mt * t2 * 3;
    final d = t * t2;

    final point = Vector2.copy(startPoint);
    point.scale(a);
    point.addScaled(points[1], b);
    point.addScaled(points[2], c);
    point.addScaled(points[3], d);

    return point;
  }

  ///GPT GENERATED
  ///This method generates more accurate results
  Vector2 pointAtV2(double t) {
    var normalizedT = _getNormalizedT(t);
    return _calculateBezierVector2(normalizedT, points);
  }

  @override
  Vector2 derivativeAt(double t, {List<Vector2>? cachedFirstOrderDerivativePoints}) {
    final derivativePoints = cachedFirstOrderDerivativePoints ?? firstOrderDerivativePoints;
    final mt = 1.0 - t;
    final a = mt * mt;
    final b = 2.0 * mt * t;
    final c = t * t;

    final localDerivative = Vector2.copy(derivativePoints[0]);
    localDerivative.scale(a);
    localDerivative.addScaled(derivativePoints[1], b);
    localDerivative.addScaled(derivativePoints[2], c);
    return localDerivative;
  }

  @override
  String toString() => 'BDCubicBezier([${points[0]}, ${points[1]}, ${points[2]}, ${points[3]}])';
}
