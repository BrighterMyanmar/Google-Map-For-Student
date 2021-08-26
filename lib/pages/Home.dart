import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gmap/utils/Constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import "package:google_maps_webservice/places.dart";
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool posReady = false;
  late LatLng _center;
  MapType _currentMapType = MapType.normal;
  final Set<Marker> _markers = {};
  final places = GoogleMapsPlaces(apiKey: Constants.API_KEY);

  late GoogleMapController mapController;
  late BitmapDescriptor sourceIcon;
  late BitmapDescriptor destIcon;

  Set<Polyline> _ploylines = {};
  List<LatLng> ploylineCoordinate = [];
  PolylinePoints polylinePoints = PolylinePoints();

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _getMyPos() async {
    var loki = await Geolocator.getCurrentPosition();
    setState(() {
      _center = LatLng(loki.latitude, loki.longitude);
      posReady = true;
      _getNearByPlace();

      // _addMarkerCurrentPos();
    });
  }

  void _addMarkerCurrentPos() {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId(_center.toString()),
          position: _center,
          icon: sourceIcon));
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _center = position.target;
      _addMarkerCurrentPos();
    });
  }

  void _getNearByPlace() async {
    PlacesSearchResponse _response = await places.searchNearbyWithRadius(
        new Location(lat: _center.latitude, lng: _center.longitude), 30000,
        type: "restaurant");
    Set<Marker> _resaturentMarkers = _response.results
        .map((res) =>
        Marker(
            markerId: MarkerId(res.name),
            icon: destIcon,
            onTap: () {
              setPloyLines(res.geometry?.location.lat ?? 0,
                  res.geometry?.location.lng ?? 0);
            },
            infoWindow: InfoWindow(
                title: res.name,
                snippet: "Rating" + (res.rating?.toString() ?? "Not Rated")),
            position: LatLng(
              res.geometry?.location.lat ?? 0,
              res.geometry?.location.lng ?? 0,
            )))
        .toSet();
    setState(() {
      _markers.addAll(_resaturentMarkers);
    });
  }

  setPloyLines(lat, len) async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Constants.API_KEY,
      PointLatLng(_center.latitude, _center.longitude),
      PointLatLng(lat, len),
    );
    result.points.forEach((point) {
      ploylineCoordinate.add(LatLng(
          point.latitude, point.longitude));
    });
    setState(() {
      Polyline ployline = Polyline(
          polylineId: PolylineId('destpli'),
          color: Colors.red,
          points: ploylineCoordinate
      );
      Set<Polyline> pls = {};
      pls.add(ployline);
      _ploylines = pls;
    });

  }

  void _generateBitmapIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 0.5), 'assets/images/m.png');
    destIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 0.5), 'assets/images/dest.png');
  }

  @override
  void initState() {
    super.initState();
    _generateBitmapIcons();
    _getMyPos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("My Loki"),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentMapType = _currentMapType == MapType.normal
                        ? MapType.satellite
                        : MapType.normal;
                  });
                },
                child: Icon(Icons.map),
              ),
            )
          ],
        ),
        body: posReady
            ? GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition:
          CameraPosition(target: _center, zoom: 11.0),
          mapType: _currentMapType,
          markers: _markers,
          onCameraMove: _onCameraMove,
          polylines: _ploylines,
        )
            : Center(child: CircularProgressIndicator()));
  }
}
