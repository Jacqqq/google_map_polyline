import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoutesWithSummary {
  List<LatLng> routes;
  String? summary;
  int? distance;

  RoutesWithSummary(this.routes, {this.summary, this.distance});
}