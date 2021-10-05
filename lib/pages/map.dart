import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/models.dart';
import '../utils/providers.dart';
import '../utils/variables.dart';
import '../utils/widgets.dart';

const DEFAULT_RADIUS = 10000;
const DEFAULT_ZOOM = 16.34;

class MapPage extends StatefulWidget {
  const MapPage(this.analytics, this.args, {Key? key}) : super(key: key);
  final FirebaseAnalytics analytics;
  final Map<String, dynamic> args;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // final _cameraPositionDebouncer = Debouncer<CameraPosition>(Duration(milliseconds: 1000));

  GoogleMapController? _mapController;
  final _markers = <int, Marker>{};
  // var _markersIcon = <int, BitmapDescriptor>{};
  final _zoom = DEFAULT_ZOOM;
  final _radius = DEFAULT_RADIUS;
  var _listings = <ListingModel>[];
  var _isLoading = true;

  late LatLng _location;
  late Placemark? _address;
  late MenuModel _category;

  Future<LatLng> _myLocation() async {
    var position = await l.myPosition();
    var latLng = LatLng(position.latitude, position.longitude);
    return latLng;
  }

  _moveLocation(LatLng latLng) async {
    setState(() {
      _location = latLng;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(_location));
    _createMyMarker();
    _getListing();
    var address = await _getAddress(_location);
    setState(() {
      _address = address;
    });
  }

  Future<Placemark> _getAddress(LatLng latLng) async {
    List<Placemark> addresses = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
    return addresses.first;
  }

  _getListing() {
    // TODO api get iklan by _location
    setState(() {
      _listings = [];
    });

    // create ad marker
    for (var listing in _listings) {
      _createAdMarker(context, listing, color: "red");
    }
  }

  _createAdMarker(BuildContext context, ListingModel listing, {String color = 'original'}) async {
    final ImageConfiguration imageConfiguration = createLocalImageConfiguration(context);
    var bitmap = await BitmapDescriptor.fromAssetImage(imageConfiguration, 'images/pin/$color.png');
    setState(() {
      _markers[listing.id] = Marker(
        markerId: MarkerId("marker_${listing.id}"),
        position: LatLng(listing.latitude, listing.longitude),
        icon: bitmap,
        infoWindow: InfoWindow(
          title: listing.title,
          snippet: listing.description,
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
      markerId: const MarkerId("marker_me"),
      position: _location,
      icon: bitmap,
      draggable: true,
      onDragEnd: _moveLocation,
      onTap: () async {
        var zoom = await _mapController?.getZoomLevel();
        print("... CURRENT ZOOM = $zoom");
      }
    );
    
    setState(() {
      _markers[0] = marker;
    });
  }

  @override
  void initState() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _address = settings.address;
    _location = LatLng(settings.lastLatitude!, settings.lastLongitude!);
    _category = listingCategories[0];
    // _cameraPositionDebouncer.values.listen((cameraPosition) {
    //   _setLocation(cameraPosition);
    // });
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _createMyMarker();
      _getListing();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(bottom: 90.0 - APP_UI_BORDER_RADIUS),
              child: GoogleMap(
                padding: const EdgeInsets.only(bottom: APP_UI_BORDER_RADIUS),
                initialCameraPosition: CameraPosition(
                  target: _location,
                  zoom: _zoom,
                  bearing: 0.0,
                  tilt: 0.0,
                ),
                mapType: MapType.normal,
                markers: _markers.values.toSet(),
                circles: <Circle>{Circle(
                  circleId: const CircleId('radius'),
                  strokeColor: Colors.teal[300]!.withOpacity(0.6),
                  fillColor: Colors.teal[300]!.withOpacity(0.1),
                  strokeWidth: 1,
                  center: _location,
                  radius: _radius.toDouble(), // meter
                  // consumeTapEvents: true,
                  // onTap: () {
                  //   _onCircleTapped(circleId);
                  // },
                )},
                onMapCreated: (googleMapController) {
                  _mapController = googleMapController;
                  rootBundle.loadString('assets/map_style.txt').then((json) {
                    _mapController!.setMapStyle(json);
                    Future.delayed(const Duration(milliseconds: 3000), () {
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
            //   padding: EdgeInsets.only(bottom: 90.0 - APP_UI_BORDER_RADIUS),
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
            _address == null ? Container() : Align(alignment: Alignment.bottomCenter, child: AddressBox(_address!, onMyLocation: () async {
              _moveLocation(await _myLocation());
            }),),
            // _isLoading ? Container(color: Colors.white, child: Center(child: UiLoader())) : Container(),
            IgnorePointer(
              ignoring: !_isLoading,
              child: AnimatedOpacity(
                opacity: _isLoading ? 1 : 0,
                duration: const Duration(milliseconds: 1000),
                child: Container(color: APP_UI_COLOR_LIGHT, child: Center(child: _isLoading ? SpinKitChasingDots(color: Colors.teal[200], size: 50,) : const SizedBox())),
              ),
            ),
            Align(alignment: Alignment.topCenter, child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(padding: const EdgeInsets.all(15), icon: const Icon(Icons.arrow_back), color: APP_UI_COLOR_MAIN, iconSize: 30, onPressed: () {
                    Navigator.of(context).pop();
                  },),
                ),
                const Spacer(),
                MyInputSelect(icon: _category.icon, listMenu: listingCategories, placeholder: "Pilih kategori", onSelect: (menu) {
                  if (menu != null) setState(() { _category = menu; });
                },),
                const SizedBox(width: 8)
              ],
            ),)
          ],
        ),
      ),
    );
  }
}

class AddressBox extends StatelessWidget {
  const AddressBox(this.address, {Key? key, this.onMyLocation}) : super(key: key);
  final Placemark address;
  final VoidCallback? onMyLocation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Card(
        color: Colors.white,
        elevation: APP_UI_CARD_ELEVATION,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(APP_UI_BORDER_RADIUS), topRight: Radius.circular(APP_UI_BORDER_RADIUS))
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // TODO cari nama tempat atau lokasi
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: Row(children: <Widget>[
              const Icon(LineIcons.mapMarker, size: 30, color: APP_UI_COLOR_MAIN,),
              const SizedBox(width: 8,),
              Expanded(child: Text(address.street ?? "N/A")),
              // TODO fix iconbutton sizing
              onMyLocation == null ? const SizedBox() : IconButton(icon: const Icon(LineIcons.locationArrow, color: APP_UI_COLOR_MAIN), onPressed: onMyLocation)
            ],),
          ),
        ),
      ),
    );
  }
}