import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'models/iklan.dart';
import 'providers/settings.dart';
// import 'utils/helpers.dart';
import 'utils/constants.dart';
// import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

const DEFAULT_RADIUS = 10000;
const DEFAULT_ZOOM = 16.34;

class Peta extends StatefulWidget {
  @override
  _PetaState createState() => _PetaState();
}

class _PetaState extends State<Peta> {
  // final _cameraPositionDebouncer = Debouncer<CameraPosition>(Duration(milliseconds: 1000));

  GoogleMapController _mapController;
  LatLng _location;
  var _listMarkers = <int, Marker>{};
  // var _listMarkersIcon = <int, BitmapDescriptor>{};
  var _listIklan = <IklanModel>[];
  var _isLoading = true;
  Address _address;
  double _zoom = DEFAULT_ZOOM;
  int _radius;
  KategoriIklanModel _kategori;
  final _listKategori = <KategoriIklanModel>[
    KategoriIklanModel('Semua', LineIcons.at),
    KategoriIklanModel('Jual-Beli', LineIcons.at),
    KategoriIklanModel('Event', LineIcons.at),
    KategoriIklanModel('Loker', LineIcons.at),
    KategoriIklanModel('Jodoh', LineIcons.at),
    KategoriIklanModel('Lainnya', LineIcons.at),
  ];

  Future<LatLng> _myLocation() async {
    print("... GETTING MY LOCATION");
    var position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    var latLng = LatLng(position.latitude, position.longitude);
    print("... GETTING MY LOCATION result: $latLng");
    return latLng;
  }

  _moveLocation(LatLng latLng) async {
    setState(() {
      _location = latLng;
    });
    _mapController.animateCamera(CameraUpdate.newLatLng(_location));
    _createMyMarker();
    _getIklan();
    var address = await _getAddress(_location);
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

  _getIklan() {
    // TODO api get iklan by _location
    setState(() {
      _listIklan = <IklanModel>[
        IklanModel(id: 1, judul: "Pet Shop Bagus", lat: -7.9279722, lng: 112.637929),
        IklanModel(id: 2, judul: "Warung Bagus", lat: -7.9280678, lng: 112.6383046),
      ];
    });

    // create ad marker
    _listIklan.forEach((ad) {
      _createAdMarker(context, ad, color: "red");
    });
  }

  _createAdMarker(BuildContext context, IklanModel ad, {String color = 'original'}) async {
    final ImageConfiguration imageConfiguration = createLocalImageConfiguration(context);
    var bitmap = await BitmapDescriptor.fromAssetImage(imageConfiguration, 'images/pin/$color.png');
    setState(() {
      _listMarkers[ad.id] = Marker(
        markerId: MarkerId("marker_${ad.id}"),
        position: LatLng(ad.lat, ad.lng),
        icon: bitmap,
        infoWindow: InfoWindow(
          title: ad.judul,
          snippet: ad.deskripsi,
          onTap: () {
            // TODO buka iklan
          }
        ),
      );
    });
  }

  _createMyMarker() async {
    // create my marker
    final ImageConfiguration imageConfiguration = createLocalImageConfiguration(context);
    var bitmap = await BitmapDescriptor.fromAssetImage(imageConfiguration, 'images/pin/original.png');
    var marker = Marker(
      markerId: MarkerId("marker_me"),
      position: _location,
      icon: bitmap,
      draggable: true,
      onDragEnd: _moveLocation,
      onTap: () async {
        var zoom = await _mapController.getZoomLevel();
        print("... CURRENT ZOOM = $zoom");
      }
    );
    
    setState(() {
      _listMarkers[0] = marker;
    });
  }

  @override
  void initState() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _address = settings.address;
    _location = LatLng(_address.coordinates.latitude, _address.coordinates.longitude);
    _radius = settings.radius;
    _kategori = _listKategori[0];
    // _cameraPositionDebouncer.values.listen((cameraPosition) {
    //   _setLocation(cameraPosition);
    // });
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _createMyMarker();
      _getIklan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Circle circle = Circle(
      circleId: CircleId('radius'),
      strokeColor: Colors.teal[300].withOpacity(0.6),
      fillColor: Colors.teal[300].withOpacity(0.1),
      strokeWidth: 1,
      center: _location,
      radius: _radius.toDouble(), // meter
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
                  target: _location,
                  zoom: _zoom,
                  bearing: 0.0,
                  tilt: 0.0,
                ),
                mapType: MapType.normal,
                markers: _listMarkers.values.toSet(),
                circles: Set<Circle>.of([circle]),
                onMapCreated: (googleMapController) {
                  _mapController = googleMapController;
                  rootBundle.loadString('assets/map_style.txt').then((json) {
                    _mapController.setMapStyle(json);
                    Future.delayed(Duration(milliseconds: 3000), () {
                      setState(() {
                        _isLoading = false;
                      });
                    });
                  });
                },
                // onCameraMove: (cameraPosition) {
                //   _cameraPositionDebouncer.value = cameraPosition;
                // },
                onTap: (latLng) async {
                  // _goToLocation(latLng);
                  _moveLocation(latLng);
                },
              ),
            ),
            // _isLoading ? Container() : Container(
            //   padding: EdgeInsets.only(bottom: 90.0 - THEME_BORDER_RADIUS),
            //   child: Center(
            //     child: UiMapMarker(size: 50.0, onTap: () {
            //       _goToLocation(_initialLocation, zoom: _zoom);
            //       setState(() {
            //         _address = _initialAddress;
            //       });
            //     },),
            //   ),
            // ),
            // TODO address box pake bottom sheet
            _address == null ? Container() : Align(alignment: Alignment.bottomCenter, child: AddressBox(_address.addressLine, onMyLocation: () async {
              var myLocation = await _myLocation();
              _moveLocation(myLocation);
            }),),
            // _isLoading ? Container(color: Colors.white, child: Center(child: UiLoader())) : Container(),
            IgnorePointer(
              ignoring: !_isLoading,
              child: AnimatedOpacity(
                opacity: _isLoading ? 1 : 0,
                duration: Duration(milliseconds: 1000),
                child: Container(color: THEME_BACKGROUND, child: Center(child: _isLoading ? SpinKitChasingDots(color: Colors.teal[200], size: 50,) : SizedBox())),
              ),
            ),
            Align(alignment: Alignment.topCenter, child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  shape: CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(padding: EdgeInsets.all(15), icon: Icon(LineIcons.arrow_left), color: THEME_COLOR, iconSize: 30, onPressed: () {
                    Navigator.of(context).pop();
                  },),
                ),
                Spacer(),
                UiSelect(simple: true, icon: _kategori.icon, listMenu: _listKategori, initialValue: _kategori, placeholder: "Pilih kategori", onSelect: (val) {
                  setState(() { _kategori = val; });
                },),
                SizedBox(width: 8)
              ],
            ),)
          ],
        ),
      ),
    );
  }
}

class AddressBox extends StatelessWidget {
  AddressBox(this.address, {Key key, this.onMyLocation}) : super(key: key);
  final String address;
  final void Function() onMyLocation;

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
            // TODO cari nama tempat atau lokasi
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: Row(children: <Widget>[
              Icon(LineIcons.map_marker, size: 30, color: THEME_COLOR,),
              SizedBox(width: 8,),
              Expanded(child: Text(address)),
              onMyLocation == null ? SizedBox() : UiButtonIcon(LineIcons.location_arrow, iconColor: THEME_COLOR, size: 60, onPressed: onMyLocation)
            ],),
          ),
        ),
      ),
    );
  }
}