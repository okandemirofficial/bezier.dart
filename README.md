**bezier.dart** is a simple open-source [Dart](https://www.dartlang.org/) library for handling 2D [Bézier curve](https://en.wikipedia.org/wiki/B%C3%A9zier_curve) math.

The library was developed, documented, and published by [Aaron Barrett](https://www.aaronbarrett.com) and Isaac Barrett.  It is based heavily on the work of [Pomax](https://pomax.github.io/), including his excellent [Primer on Bézier Curves](https://pomax.github.io/bezierinfo/) and his original JavaScript library, [Bezier.js](https://pomax.github.io/bezierjs/).


## FORK CHANGES
- Dependency on vector_math_64 instead of vector_math
- .Vector2AtV2() GPT generated method which gives more accurate results

Distance between in every t = 0.10 (should be similar for more accurate results)

  - Vector2 AT V1
 distance = 0.0, t = 0.0, normalized = 0.0
 distance = 1384.1232613901564,
 distance = 1384.3627465296693,
 distance = 1389.1657056485542,
 distance = 1391.5993962911414,
 distance = 1392.5654873072713,
 distance = 1392.5654873072745,
 distance = 1391.5993962911366,
 distance = 1389.1657056485572,
 distance = 1384.362746529668,
 distance = 1384.1232613901586,
 executed in 0:00:00.016899

- Vector2 AT V2

 distance = 0.0, t = 0.0
 distance = 1378.731300870478,
 distance = 1296.1867149450352,
 distance = 1347.9243302203572,
 distance = 1432.515270424717,
 distance = 1487.5819305167695,
 distance = 1487.581930516769,
 distance = 1432.5152704247162,
 distance = 1347.9243302203588,
 distance = 1296.1867149450343,
 distance = 1378.7313008704773,
 executed in 0:00:00.008565


 ## IT'S NOT ACCURATE ENOUGH?

 try this:
 ```

class BezierCurve {
  List<Vector2> controlVector2s;
  List<double> arcLengths = [];
  double totalLength = 0.0;

  BezierCurve(this.controlVector2s) {
    for (var i = 0; i <= 1000; i++) {  // Change here: increased to 1000 steps
      var t = i / 1000.0;  // Change here: decreased step size to 0.001
      var pt = calculateBezierVector2(t, controlVector2s);
      if (i > 0) {
        var dx = pt.x - calculateBezierVector2(t - 0.001, controlVector2s).x;  // Change here: decreased step size to 0.001
        var dy = pt.y - calculateBezierVector2(t - 0.001, controlVector2s).y;  // Change here: decreased step size to 0.001
        totalLength += sqrt(dx * dx + dy * dy);
      }
      arcLengths.add(totalLength);
    }
  }

  // ... rest of the BezierCurve class remains unchanged ...

  double getNormalizedT(double t) {
    var targetLength = t * totalLength;
    var low = 0, high = arcLengths.length;
    while (low < high) {
      var mid = (low + (high - low) / 2).floor();
      if (arcLengths[mid] < targetLength) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    if (arcLengths[low] > targetLength) low--;
    var lengthBefore = arcLengths[low];
    var segmentLength = arcLengths[low + 1] - lengthBefore;

    var segmentT = (targetLength - lengthBefore) / segmentLength;
    return (low + segmentT) / 1000.0;  // Change here: adjusted for 1000 steps
  }
}

 ```