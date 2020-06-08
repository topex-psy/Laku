import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:geocoder/geocoder.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:line_icons/line_icons.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'utils/helpers.dart';
import 'utils/constants.dart';
// import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

class Peta extends StatefulWidget {
  Peta(Map arguments, {Key key})
  : address = arguments['address'],
    radius = arguments['radius'],
    super(key: key);

  final Address address;
  final int radius;

  @override
  _PetaState createState() => _PetaState(address, radius);
}

class _PetaState extends State<Peta> {
  _PetaState(this._initialAddress, this._initialRadius)
  : _initialLocation = LatLng(_initialAddress.coordinates.latitude, _initialAddress.coordinates.longitude),
    _address = _initialAddress;
  
  final LatLng _initialLocation;
  final Address _initialAddress;
  final int _initialRadius;

  final _cameraPositionDebouncer = Debouncer<CameraPosition>(Duration(milliseconds: 1000));
  final _initialZoom = 18.0;

  GoogleMapController _mapController;
  BitmapDescriptor _markerIcon;
  CameraPosition _location;
  var _isLoading = true;
  Address _address;

  _goToLocation(dynamic location, {double zoom, bool animate = true}) async {
    var cameraUpdate;
    if (location is LatLng) {
      cameraUpdate = zoom == null ? CameraUpdate.newLatLng(location) : CameraUpdate.newLatLngZoom(location, zoom);
    } else if (location is CameraPosition) {
      cameraUpdate = CameraUpdate.newCameraPosition(location);
    }
    if (cameraUpdate == null) return;
    if (animate) _mapController.animateCamera(cameraUpdate);
    else _mapController.moveCamera(cameraUpdate);
  }

  _setLocation(CameraPosition cameraPosition) async {
    if (!mounted) return;
    print("... SET LOCATION: $cameraPosition");
    setState(() {
      _location = cameraPosition;
    });
    // _goToLocation(_location, false);
    // _goToLocation(_location.target, _location.zoom, false);
    _goToLocation(_location, animate: false);
    var address = await _getAddress(_location.target);
    setState(() {
      _address = address;
    });
  }

  Future<Address> _getAddress(LatLng latLng) async {
    final coordinates = Coordinates(latLng.latitude, latLng.longitude);
    var address = _address;
    try {
      var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
      address = addresses.first;
      print("... GET ADDRESS result"
        "\n name: ${address.featureName}"
        "\n address: ${address.addressLine}"
      );
    } catch(e) {
      print("... GET ADDRESS error: $e");
    }
    return address;
  }

  Set<Marker> _createMarker() {
    return <Marker>[
      Marker(
        markerId: MarkerId("marker_1"),
        position: LatLng(-7.9279722, 112.637929),
        icon: _markerIcon,
      ),
      Marker(
        markerId: MarkerId("marker_2"),
        position: LatLng(-7.9280678, 112.6383046),
        icon: _markerIcon,
      ),
    ].toSet();
  }

  Future<void> _createMarkerImageFromAsset(BuildContext context) async {
    if (_markerIcon != null) return;
    final ImageConfiguration imageConfiguration = createLocalImageConfiguration(context);
    BitmapDescriptor.fromAssetImage(imageConfiguration, 'images/pin.png').then((bitmap) {
      setState(() {
        _markerIcon = bitmap;
      });
    });
  }

  @override
  void initState() {
    _location = CameraPosition(target: _initialLocation, zoom: _initialZoom);
    _cameraPositionDebouncer.values.listen((cameraPosition) {
      _setLocation(cameraPosition);
    });
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createMarkerImageFromAsset(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Circle circle = Circle(
      circleId: CircleId('radius'),
      strokeColor: Colors.teal[300].withOpacity(0.6),
      fillColor: Colors.teal[300].withOpacity(0.2),
      strokeWidth: 1,
      center: _location.target,
      radius: _initialRadius.toDouble(), // meter
      // consumeTapEvents: true,
      // onTap: () {
      //   _onCircleTapped(circleId);
      // },
    );
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(bottom: 90.0 - THEME_BORDER_RADIUS),
              child: GoogleMap(
                padding: EdgeInsets.only(bottom: THEME_BORDER_RADIUS),
                initialCameraPosition: CameraPosition(
                  target: _location?.target ?? _initialLocation,
                  zoom: _location?.zoom ?? _initialZoom,
                  bearing: 0.0,
                  tilt: 0.0,
                ),
                mapType: MapType.normal,
                markers: _createMarker(),
                circles: Set<Circle>.of([circle]),
                onMapCreated: (googleMapController) {
                  _mapController = googleMapController;
                  rootBundle.loadString('assets/map_style.txt').then((json) {
                    _mapController.setMapStyle(json);
                    Future.delayed(Duration(milliseconds: 1000), () {
                      setState(() {
                        _isLoading = false;
                      });
                    });
                  });
                },
                onCameraMove: (cameraPosition) {
                  _cameraPositionDebouncer.value = cameraPosition;
                },
                onTap: (latLng) {
                  _goToLocation(latLng);
                },
              ),
            ),
            _isLoading ? Container() : Container(
              padding: EdgeInsets.only(bottom: 90.0 - THEME_BORDER_RADIUS),
              child: Center(
                child: UiMapMarker(size: 50.0, onTap: () {
                  _goToLocation(_initialLocation, zoom: _initialZoom);
                  setState(() {
                    _address = _initialAddress;
                  });
                },),
              ),
            ),
            // TODO address box pake bottom sheet
            _address == null ? Container() : Align(alignment: Alignment.bottomCenter, child: AddressBox(_address.addressLine),),
            _isLoading ? Container(child: Center(child: UiLoader())) : Container(),
            Align(alignment: Alignment.topLeft, child: Material(
              color: Colors.transparent,
              shape: CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(padding: EdgeInsets.all(15), icon: Icon(LineIcons.arrow_left), color: Colors.black, iconSize: 30, onPressed: () {
                Navigator.of(context).pop();
              },),
            ),)
          ],
        ),
      ),
    );
  }
}

class AddressBox extends StatelessWidget {
  AddressBox(this.address, {Key key}) : super(key: key);
  final String address;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      child: Card(
        color: Colors.white,
        elevation: THEME_ELEVATION_BUTTON,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(THEME_BORDER_RADIUS), topRight: Radius.circular(THEME_BORDER_RADIUS))
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: Row(children: <Widget>[
              Icon(LineIcons.map_marker, size: 30, color: THEME_COLOR,),
              SizedBox(width: 8,),
              Expanded(child: Text(address)),
            ],),
          ),
        ),
      ),
    );
  }
}