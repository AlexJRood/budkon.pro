import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class Cs92Point {
  final double x;
  final double y;

  const Cs92Point(this.x, this.y);
}

class MapGeoService {
  const MapGeoService();

  String bboxFromBounds(LatLngBounds bounds) {
    return '${bounds.west},${bounds.south},${bounds.east},${bounds.north}';
  }

  Offset latLngToWebMercator(LatLng latLng) {
    const originShift = 20037508.342789244;

    final mx = latLng.longitude * originShift / 180.0;

    var my = math.log(
          math.tan((90.0 + latLng.latitude) * math.pi / 360.0),
        ) /
        (math.pi / 180.0);
    my = my * originShift / 180.0;

    return Offset(mx, my);
  }

  double _degToRad(double value) => value * math.pi / 180.0;
  double _radToDeg(double value) => value * 180.0 / math.pi;

  Cs92Point wgs84ToCs92(LatLng point) {
    const a = 6378137.0;
    const e2 = 0.00669438002290;
    const scale = 0.9993;
    final l0 = _degToRad(19.0);

    final b = _degToRad(point.latitude);
    final l = _degToRad(point.longitude);

    final sinB = math.sin(b);
    final cosB = math.cos(b);
    final tanB = math.tan(b);

    final e4 = e2 * e2;
    final e6 = e4 * e2;
    final ep2 = e2 / (1.0 - e2);

    final n2 = ep2 * cosB * cosB;
    final n = a / math.sqrt(1.0 - e2 * sinB * sinB);
    final dl = l - l0;

    final a0 = 1.0 - (e2 / 4.0) - (3.0 * e4 / 64.0) - (5.0 * e6 / 256.0);
    final a2 = (3.0 / 8.0) * (e2 + (e4 / 4.0) + (15.0 * e6 / 128.0));
    final a4 = (15.0 / 256.0) * (e4 + (3.0 * e6 / 4.0));
    final a6 = 35.0 * e6 / 3072.0;

    final sigma = a *
        (a0 * b -
            a2 * math.sin(2.0 * b) +
            a4 * math.sin(4.0 * b) -
            a6 * math.sin(6.0 * b));

    final dl2 = dl * dl;
    final dl4 = dl2 * dl2;
    final dl6 = dl4 * dl2;
    final cos2 = cosB * cosB;
    final cos4 = cos2 * cos2;

    final tan2 = tanB * tanB;
    final tan4 = tan2 * tan2;

    final xgk = sigma +
        (dl2 / 2.0) *
            n *
            sinB *
            cosB *
            (1.0 +
                (dl2 / 12.0) *
                    cos2 *
                    (5.0 - tan2 + 9.0 * n2 + 4.0 * n2 * n2) +
                (dl6 / 360.0) *
                    cos4 *
                    (61.0 -
                        58.0 * tan2 +
                        tan4 +
                        270.0 * n2 -
                        330.0 * n2 * tan2));

    final ygk = dl *
        n *
        cosB *
        (1.0 +
            (dl2 / 6.0) * cos2 * (1.0 - tan2 + n2) +
            (dl4 / 120.0) *
                cos4 *
                (5.0 - 18.0 * tan2 + tan4 + 14.0 * n2 - 58.0 * n2 * tan2));

    final x92 = xgk * scale - 5300000.0;
    final y92 = ygk * scale + 500000.0;

    return Cs92Point(x92, y92);
  }

  LatLng cs92ToWgs84(double x92, double y92) {
    const a = 6378137.0;
    const e2 = 0.00669438002290;
    const scale = 0.9993;
    final l0 = _degToRad(19.0);

    final xgk = (x92 + 5300000.0) / scale;
    final ygk = (y92 - 500000.0) / scale;

    final e4 = e2 * e2;
    final e6 = e4 * e2;
    final ep2 = e2 / (1.0 - e2);

    final a0 = 1.0 - (e2 / 4.0) - (3.0 * e4 / 64.0) - (5.0 * e6 / 256.0);
    final a2 = (3.0 / 8.0) * (e2 + (e4 / 4.0) + (15.0 * e6 / 128.0));
    final a4 = (15.0 / 256.0) * (e4 + (3.0 * e6 / 4.0));
    final a6 = 35.0 * e6 / 3072.0;

    double bf = xgk / (a * a0);

    for (int i = 0; i < 7; i++) {
      bf = (xgk +
              a *
                  (a2 * math.sin(2.0 * bf) -
                      a4 * math.sin(4.0 * bf) +
                      a6 * math.sin(6.0 * bf))) /
          (a * a0);
    }

    final sinBf = math.sin(bf);
    final cosBf = math.cos(bf);
    final tanBf = math.tan(bf);

    final n = a / math.sqrt(1.0 - e2 * sinBf * sinBf);
    final m = a * (1.0 - e2) / math.pow(1.0 - e2 * sinBf * sinBf, 1.5);
    final n2 = ep2 * cosBf * cosBf;

    final y2 = ygk * ygk;
    final y4 = y2 * y2;
    final y6 = y4 * y2;
    final n2Pow = n * n;
    final n4Pow = n2Pow * n2Pow;
    final n6Pow = n4Pow * n2Pow;

    final tan2 = tanBf * tanBf;
    final tan4 = tan2 * tan2;
    final tan6 = tan4 * tan2;

    final b = bf -
        (y2 * tanBf / (2.0 * m * n)) *
            (1.0 -
                (y2 / (12.0 * n2Pow)) *
                    (5.0 + 3.0 * tan2 + n2 - 9.0 * n2 * tan2 - 4.0 * n2 * n2) +
                (y4 / (360.0 * n4Pow)) * (61.0 + 90.0 * tan2 + 45.0 * tan4));

    final l = l0 +
        (ygk / (n * cosBf)) *
            (1.0 -
                (y2 / (6.0 * n2Pow)) * (1.0 + 2.0 * tan2 + n2) +
                (y4 / (120.0 * n4Pow)) *
                    (5.0 +
                        28.0 * tan2 +
                        24.0 * tan4 +
                        6.0 * n2 +
                        8.0 * n2 * tan2) -
                (y6 / (5040.0 * n6Pow)) *
                    (61.0 +
                        662.0 * tan2 +
                        1320.0 * tan4 +
                        720.0 * tan6));

    return LatLng(_radToDeg(b), _radToDeg(l));
  }
}