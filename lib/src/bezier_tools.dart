import 'dart:math';

import 'package:bezier/bezier.dart';
import 'package:vector_math/vector_math_64.dart';

/// The roots of the Legendre polynomial for n == 30.
///
/// More information about Legendre-Gauss quadrature integral approximation
/// available at the [resource page created by Pomax]
/// (https://pomax.github.io/bezierinfo/legendre-gauss.html).
const legendrePolynomialRoots = [
  -0.0514718425553177,
  0.0514718425553177,
  -0.1538699136085835,
  0.1538699136085835,
  -0.2546369261678899,
  0.2546369261678899,
  -0.3527047255308781,
  0.3527047255308781,
  -0.4470337695380892,
  0.4470337695380892,
  -0.5366241481420199,
  0.5366241481420199,
  -0.6205261829892429,
  0.6205261829892429,
  -0.6978504947933158,
  0.6978504947933158,
  -0.7677774321048262,
  0.7677774321048262,
  -0.8295657623827684,
  0.8295657623827684,
  -0.8825605357920527,
  0.8825605357920527,
  -0.9262000474292743,
  0.9262000474292743,
  -0.9600218649683075,
  0.9600218649683075,
  -0.9836681232797472,
  0.9836681232797472,
  -0.9968934840746495,
  0.9968934840746495
];

/// The weights of the Legendre polynomial for n == 30.
const legendrePolynomialWeights = [
  0.1028526528935588,
  0.1028526528935588,
  0.1017623897484055,
  0.1017623897484055,
  0.0995934205867953,
  0.0995934205867953,
  0.0963687371746443,
  0.0963687371746443,
  0.0921225222377861,
  0.0921225222377861,
  0.0868997872010830,
  0.0868997872010830,
  0.0807558952294202,
  0.0807558952294202,
  0.0737559747377052,
  0.0737559747377052,
  0.0659742298821805,
  0.0659742298821805,
  0.0574931562176191,
  0.0574931562176191,
  0.0484026728305941,
  0.0484026728305941,
  0.0387991925696271,
  0.0387991925696271,
  0.0287847078833234,
  0.0287847078833234,
  0.0184664683110910,
  0.0184664683110910,
  0.0079681924961666,
  0.0079681924961666
];

/// True if [a] and [b] are within [precision] units of each other.
bool isApproximately(double a, double b, {double precision = 0.000001}) =>
    ((a - b).abs() <= precision);

/// True if [point] intersects [boundingBox], or is within [precision] of the border.
bool pointIntersectsBoundingBoxApproximately(Vector2 point, Aabb2 boundingBox,
    {double precision = 0.0001}) {
  final x = point.x;
  final y = point.y;
  final min = boundingBox.min;
  final max = boundingBox.max;

  final xIsInBoundingBox = ((min.x <= x) && (x <= max.x)) ||
      isApproximately(x, min.x, precision: precision) ||
      isApproximately(x, max.x, precision: precision);
  final yIsInBoundingBox = ((min.y <= y) && (y <= max.y)) ||
      isApproximately(y, min.y, precision: precision) ||
      isApproximately(y, max.y, precision: precision);

  return xIsInBoundingBox && yIsInBoundingBox;
}

/// Returns the cube root of [realNumber] from within the real numbers such that
/// the result raised to the third power equals [realNumber].
double principalCubeRoot(double realNumber) {
  if (realNumber < 0.0) {
    return -pow(-realNumber, 1.0 / 3.0) as double;
  } else {
    return pow(realNumber, 1.0 / 3.0) as double;
  }
}

/// Returns a [List] of [Vector2] describing the derivative function of the
/// polynomial function described by [points].
List<Vector2> computeDerivativePoints(List<Vector2> points) {
  final derivativePoints = <Vector2>[];

  final derivativePointsCount = points.length - 1;
  final multiplier = derivativePointsCount.toDouble();

  for (var index = 0; index < derivativePointsCount; index++) {
    final point = Vector2.copy(points[index + 1]);
    point.sub(points[index]);
    point.scale(multiplier);
    derivativePoints.add(point);
  }

  return derivativePoints;
}

/// Returns the signed angle in radians between the lines formed by [cornerPoint]
/// to [firstEndpoint] and [cornerPoint] to [secondEndpoint].
double cornerAngle(Vector2 cornerPoint, Vector2 firstEndpoint, Vector2 secondEndpoint) {
  final deltaVector1 = Vector2.copy(firstEndpoint);
  deltaVector1.sub(cornerPoint);

  final deltaVector2 = Vector2.copy(secondEndpoint);
  deltaVector2.sub(cornerPoint);

  return deltaVector1.angleToSigned(deltaVector2);
}

/// Returns a [List] of [Vector2] positions from [points] translated so that
/// [lineStartPoint] is at the origin and rotated so that [lineEndPoint] is on
/// the positive X axis.
List<Vector2> alignWithLineSegment(
    List<Vector2> points, Vector2 lineStartPoint, Vector2 lineEndPoint) {
  final lineDeltaVector = Vector2.copy(lineEndPoint);
  lineDeltaVector.sub(lineStartPoint);

  final xAxis = Vector2(1.0, 0.0);

  final lineAngle = -xAxis.angleToSigned(lineDeltaVector);
  final rotationMatrix = Matrix2.rotation(lineAngle);

  final alignedPoints = <Vector2>[];
  for (final point in points) {
    final alignedPoint = Vector2.copy(point);
    alignedPoint.sub(lineStartPoint);
    rotationMatrix.transform(alignedPoint);
    alignedPoints.add(alignedPoint);
  }
  return alignedPoints;
}

/// Returns the linear parameter value for where [t] lies in the interval
/// between [min] and [max].
///
/// If [t] is equal to [min], and [max] is greater than [min], it returns zero.
/// If [t] is equal to [max], and [max] is greater than [min], it returns one.
/// If [t] is between [min] and [max], it returns a value between zero and one.
///
/// ```
/// inverseMix(1.0, 2.0, 1.0) == 0.0;
/// inverseMix(1.0, 2.0, 2.0) == 1.0;
/// inverseMix(1.0, 2.0, 1.25) == 0.25;
/// ```
double inverseMix(double min, double max, double t) => (t - min) / (max - min);

/// Returns roots for the cubic function that passes through [pa] at x == 0.0 and
/// [pd] at x == 1.0 which has control points [pb] and [pc] at x == 1.0 / 3.0 and
/// x == 2.0 / 3.0.
List<double> cubicRoots(double pa, double pb, double pc, double pd) {
  final d = -pa + 3.0 * pb - 3.0 * pc + pd;
  var a = 3.0 * pa - 6.0 * pb + 3.0 * pc;
  var b = -3.0 * pa + 3.0 * pb;
  var c = pa;

  if (isApproximately(d, 0.0)) {
    if (isApproximately(a, 0.0)) {
      if (isApproximately(b, 0.0)) {
        // no solutions:
        return [];
      }
      // linear solution:
      return [-c / b];
    }
    // quadratic solutions:
    final q = sqrt(b * b - 4.0 * a * c);
    final a2 = 2.0 * a;
    return [(q - b) / a2, (-b - q) / a2];
  }

  // cubic solutions:

  a /= d;
  b /= d;
  c /= d;

  final p = (3.0 * b - a * a) / 3.0;
  final thirdOfP = p / 3.0;
  final q = (2.0 * a * a * a - 9.0 * a * b + 27.0 * c) / 27.0;
  final halfOfQ = q / 2.0;
  final discriminant = halfOfQ * halfOfQ + thirdOfP * thirdOfP * thirdOfP;
  if (discriminant < 0.0) {
    final minusThirdOfPCubed = -(thirdOfP * thirdOfP * thirdOfP);
    final r = sqrt(minusThirdOfPCubed);
    final t = -q / (2.0 * r);
    final cosineOfPhi = t.clamp(-1.0, 1.0);
    final phi = acos(cosineOfPhi);
    final cubeRootOfR = principalCubeRoot(r);
    final t1 = 2.0 * cubeRootOfR;
    final x1 = t1 * cos(phi / 3.0) - a / 3.0;
    final x2 = t1 * cos((phi + pi * 2.0) / 3.0) - a / 3.0;
    final x3 = t1 * cos((phi + pi * 4.0) / 3.0) - a / 3.0;
    return [x1, x2, x3];
  } else if (discriminant == 0.0) {
    final u1 = -principalCubeRoot(halfOfQ);
    final x1 = 2.0 * u1 - a / 3.0;
    final x2 = -u1 - a / 3.0;
    return [x1, x2];
  } else {
    final sd = sqrt(discriminant);
    final u1 = principalCubeRoot(-halfOfQ + sd);
    final v1 = principalCubeRoot(halfOfQ + sd);
    return [u1 - v1 - a / 3.0];
  }
}

/// Returns the roots for the quadratic function that passes through [a] at x == 0.0,
/// [c] at x == 1.0 and has a control point [b] at x == 0.5.
List<double> quadraticRoots(double a, double b, double c) {
  final d = a - 2.0 * b + c;
  if (d != 0.0) {
    final m1 = -sqrt(b * b - a * c);
    final m2 = -a + b;
    final v1 = -(m1 + m2) / d;
    final v2 = -(-m1 + m2) / d;
    return <double>[v1, v2];
  } else if ((b != c) && (d == 0.0)) {
    return <double>[(2.0 * b - c) / (2.0 * (b - c))];
  } else {
    return <double>[];
  }
}

/// Returns the root for the line passing through [a] at x == 0.0 and [b] at x == 1.0.
List<double> linearRoots(double a, double b) {
  if (a == b) {
    return <double>[];
  } else {
    return <double>[a / (a - b)];
  }
}

/// Returns an unfiltered [List] of roots for the polynomial function described
/// by [polynomial].
List<double> polynomialRoots(List<double> polynomial) {
  if (polynomial.length == 4) {
    return cubicRoots(polynomial[0], polynomial[1], polynomial[2], polynomial[3]);
  } else if (polynomial.length == 3) {
    return quadraticRoots(polynomial[0], polynomial[1], polynomial[2]);
  } else if (polynomial.length == 2) {
    return linearRoots(polynomial[0], polynomial[1]);
  } else if (polynomial.length < 2) {
    return <double>[];
  } else {
    throw UnsupportedError('Fourth and higher order polynomials not supported.');
  }
}

/// Returns the roots of the polynomial equation derived after aligning [points] along
/// the line passing through [lineStart] and [lineEnd].
List<double> rootsAlongLine(List<Vector2> points, Vector2 lineStart, Vector2 lineEnd) {
  final alignedPoints = alignWithLineSegment(points, lineStart, lineEnd);

  final yValues = <double>[];
  for (final point in alignedPoints) {
    yValues.add(point.y);
  }

  final roots = polynomialRoots(yValues);

  roots.retainWhere((t) => ((t >= 0.0) && (t <= 1.0)));

  return roots;
}

/// Returns the intersection point between two lines.
///
/// The first line passes through [p1] and [p2].  The second line passes through
/// [p3] and [p4].  Returns [null] if the lines are parallel or coincident.
Vector2? intersectionPointBetweenTwoLines(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4) {
  final cross1 = (p1.x * p2.y - p1.y * p2.x);
  final cross2 = (p3.x * p4.y - p3.y * p4.x);

  final xNumerator = cross1 * (p3.x - p4.x) - (p1.x - p2.x) * cross2;
  final yNumerator = cross1 * (p3.y - p4.y) - (p1.y - p2.y) * cross2;
  final denominator = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
  if (denominator == 0.0) {
    return null;
  }
  return Vector2(xNumerator / denominator, yNumerator / denominator);
}

/// Returns true if the dimensions of [box] when added together are smaller than
/// [maxSize].
bool boundingBoxIsSmallerThanSize(Aabb2 box, double maxSize) {
  final boxSize = box.max - box.min;
  return (boxSize.x + boxSize.y < maxSize);
}

/// Returns the indices of pairs of curve segments that overlap from [pairLeftSides]
/// and [pairRightSides].
List<int> indicesOfOverlappingSegmentPairs(
    List<BezierSlice> pairLeftSides, List<BezierSlice> pairRightSides) {
  final overlappingIndices = <int>[];
  for (var pairIndex = 0; pairIndex < pairLeftSides.length; pairIndex++) {
    final leftSegment = pairLeftSides[pairIndex].subcurve;
    final rightSegment = pairRightSides[pairIndex].subcurve;
    if (leftSegment.overlaps(rightSegment)) {
      overlappingIndices.add(pairIndex);
    }
  }

  return overlappingIndices;
}

/// Returns a [List] of intersections between [curve1] and [curve2] using a
/// threshold of [curveIntersectionThreshold].  It divides the bounding boxes
/// of the [Bezier] curves in half and calls itself recursively with
/// overlapping pairs of divided curve segments.
List<Intersection> locateIntersectionsRecursively(
    BezierSlice curve1, BezierSlice curve2, double curveIntersectionThreshold) {
  final curve1Box = curve1.subcurve.boundingBox;
  final curve2Box = curve2.subcurve.boundingBox;

  if (boundingBoxIsSmallerThanSize(curve1Box, curveIntersectionThreshold) &&
      boundingBoxIsSmallerThanSize(curve2Box, curveIntersectionThreshold)) {
    final firstIntersectionT = (curve1.t1 + curve1.t2) / 2.0;
    final secondIntersectionT = (curve2.t1 + curve2.t2) / 2.0;
    return [Intersection(firstIntersectionT, secondIntersectionT)];
  }

  final centerT = 0.5;
  final curve1CenterT = mix(curve1.t1, curve1.t2, centerT);
  final curve2CenterT = mix(curve2.t1, curve2.t2, centerT);

  final curve1LeftSegment = curve1.subcurve.leftSubcurveAt(centerT);
  final curve1Left = BezierSlice(curve1LeftSegment, curve1.t1, curve1CenterT);

  final curve1RightSegment = curve1.subcurve.rightSubcurveAt(centerT);
  final curve1Right = BezierSlice(curve1RightSegment, curve1CenterT, curve1.t2);

  final curve2LeftSegment = curve2.subcurve.leftSubcurveAt(centerT);
  final curve2Left = BezierSlice(curve2LeftSegment, curve2.t1, curve2CenterT);

  final curve2RightSegment = curve2.subcurve.rightSubcurveAt(centerT);
  final curve2Right = BezierSlice(curve2RightSegment, curve2CenterT, curve2.t2);

  final pairLeftSides = [curve1Left, curve1Left, curve1Right, curve1Right];
  final pairRightSides = [curve2Left, curve2Right, curve2Left, curve2Right];

  final overlappingPairIndices = indicesOfOverlappingSegmentPairs(pairLeftSides, pairRightSides);

  final results = <Intersection>[];
  if (overlappingPairIndices.isEmpty) {
    return results;
  }

  overlappingPairIndices.forEach((pairIndex) {
    final left = pairLeftSides[pairIndex];
    final right = pairRightSides[pairIndex];
    results.addAll(locateIntersectionsRecursively(left, right, curveIntersectionThreshold));
  });

  return results;
}

/// Returns the index of the point in [points] that is closest (in terms of
/// geometric distance) to [targetPoint].
int indexOfNearestPoint(List<Vector2> points, Vector2 targetPoint) {
  if (points.isEmpty) {
    throw ArgumentError.value('points', 'must contain at least one point');
  }

  var minSquaredDistance = double.maxFinite;
  var index;

  final pointsCount = points.length;
  for (var pointIndex = 0; pointIndex < pointsCount; pointIndex++) {
    final point = points[pointIndex];
    final squaredDistance = targetPoint.distanceToSquared(point);
    if (squaredDistance < minSquaredDistance) {
      minSquaredDistance = squaredDistance;
      index = pointIndex;
    }
  }

  return index;
}
