import 'package:dio/dio.dart';
import 'package:google_map_polyline/src/polyline_request.dart';
import 'package:google_map_polyline/src/route_mode.dart';
import 'package:google_map_polyline/src/routes_with_summary.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolylineUtils {
  PolylineRequestData? _data;

  PolylineUtils(this._data);

  Future<RoutesWithSummary?> getCoordinates() async {
    RoutesWithSummary? routesWithSummary;

    var qParam = {
      'mode': getMode(_data!.mode),
      'key': _data!.apiKey,
    };

    if (_data!.locationText!) {
      qParam['origin'] = _data!.originText;
      qParam['destination'] = _data!.destinationText;
    } else {
      qParam['origin'] =
          "${_data!.originLoc!.latitude},${_data!.originLoc!.longitude}";
      qParam['destination'] =
          "${_data!.destinationLoc!.latitude},${_data!.destinationLoc!.longitude}";
    }

    Response _response;
    Dio _dio = new Dio();
    _response = await _dio.get(
        "https://maps.googleapis.com/maps/api/directions/json",
        queryParameters: qParam);

    try {
      if (_response.statusCode == 200) {
        if (_response.data["status"] == "REQUEST_DENIED") {
          throw Exception(_response.data["error_message"]);
        }
        routesWithSummary = RoutesWithSummary(
          decodeEncodedPolyline(_response.data['routes'][0]['overview_polyline']['points']),
          summary: _response.data['routes'][0]['summary'],
          distance: _response.data['routes'][0]['legs'][0]['distance']['value'],
        );
      }
    } catch (e) {
      print('error!!!! $e');
      throw e;
    }

    return routesWithSummary;
  }

  Future<List<RoutesWithSummary>> getCoordinatesWithAlternatives() async {
    List<RoutesWithSummary> routesWithSummary = [];

    var qParam = {
      'mode': getMode(_data!.mode),
      'key': _data!.apiKey,
      'alternatives': true,
    };

    if (_data!.locationText!) {
      qParam['origin'] = _data!.originText;
      qParam['destination'] = _data!.destinationText;
    } else {
      qParam['origin'] =
      "${_data!.originLoc!.latitude},${_data!.originLoc!.longitude}";
      qParam['destination'] =
      "${_data!.destinationLoc!.latitude},${_data!.destinationLoc!.longitude}";
    }

    Response _response;
    Dio _dio = new Dio();
    _response = await _dio.get(
        "https://maps.googleapis.com/maps/api/directions/json",
        queryParameters: qParam);

    try {
      if (_response.statusCode == 200) {
        var amountOfRoutes = _response.data['routes'].length;
        for (int i = 0; i < amountOfRoutes; i++) {
          routesWithSummary.add(RoutesWithSummary(decodeEncodedPolyline(
              _response.data['routes'][i]['overview_polyline']['points']),
              summary: _response.data['routes'][i]['summary'],
              distance: _response.data['routes'][i]['legs'][0]['distance']['value']),
          );
        }
      }
    } catch (e) {
      print('error');
    }
    return routesWithSummary;
  }

  List<LatLng> decodeEncodedPolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      LatLng p = new LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  String? getMode(RouteMode? _mode) {
    switch (_mode) {
      case RouteMode.driving:
        return 'driving';
      case RouteMode.walking:
        return 'walking';
      case RouteMode.bicycling:
        return 'bicycling';
        case RouteMode.transit:
        return 'transit';
      default:
        return null;
    }
  }
}
