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
    super(key: key);

  final Address address;

  @override
  _PetaState createState() => _PetaState(address);
}

class _PetaState extends State<Peta> {
  _PetaState(this._initialAddress)
  : _initialLocation = LatLng(_initialAddress.coordinates.latitude, _initialAddress.coordinates.longitude),
    _address = _initialAddress;
  
  final LatLng _initialLocation;
  final Address _initialAddress;
  final _cameraPositionDebouncer = Debouncer<CameraPosition>(Duration(milliseconds: 1000));
  final _initialZoom = 18.0;

  GoogleMapController _mapController;
  CameraPosition _location;
  var _isLoading = true;
  // var _isGranted = false;
  Address _address;

  _goToLocation(CameraPosition newPosition, [bool animate = true]) async {
    var cameraUpdate = CameraUpdate.newCameraPosition(newPosition);
    if (animate) _mapController.animateCamera(cameraUpdate);
    else _mapController.moveCamera(cameraUpdate);
  }

  _setLocation(CameraPosition cameraPosition) async {
    if (!mounted) return;
    print("... SET LOCATION: $cameraPosition");
    setState(() {
      _location = cameraPosition;
    });
    _goToLocation(_location, false);
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

  @override
  void initState() {
    // _address = _initialAddress;
    _cameraPositionDebouncer.values.listen((cameraPosition) {
      _setLocation(cameraPosition);
    });
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // var isGranted = await Permission.location.request().isGranted;
      // setState(() {
      //   _isGranted = isGranted;
      //   _isLoading = false;
      // });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _location?.target ?? _initialLocation,
                zoom: _location?.zoom ?? _initialZoom,
                bearing: 0.0,
                tilt: 0.0,
              ),
              mapType: MapType.normal,
              onMapCreated: (googleMapController) {
                _mapController = googleMapController;
                rootBundle.loadString('assets/map_style.txt').then((json) {
                  _mapController.setMapStyle(json);
                  setState(() {
                    _isLoading = false;
                  });
                });
              },
              onCameraMove: (cameraPosition) {
                _cameraPositionDebouncer.value = cameraPosition;
              },
              onTap: (latLng) {
                _goToLocation(CameraPosition(target: latLng, zoom: _initialZoom,));
              },
            ),
            _isLoading ? Container() : UiMapMarker(size: 50.0, onTap: () {
              _goToLocation(CameraPosition(target: _initialLocation, zoom: _initialZoom,));
              setState(() {
                _address = _initialAddress;
              });
            },),
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
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
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
              // Expanded(child: Text(address.addressLine, style: style.textM,)),
              // SizedBox(width: 8,),
              // Icon(LineIcons.edit, size: 20, color: THEME_COLOR,),
            ],),
          ),
        ),
      ),
    );
  }
}