import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/models.dart';
import '../utils/providers.dart';
import '../utils/variables.dart';
import '../utils/widgets.dart';

class MapPage extends StatefulWidget {
  const MapPage(this.args, {Key? key}) : super(key: key);
  final Map<String, dynamic> args;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  GoogleMapController? _mapController;
  final _markers = <int, Marker>{};
  // var _markersIcon = <int, BitmapDescriptor>{};
  var _zoom = SETUP_MAP_DEFAULT_ZOOM;
  final _radius = SETUP_MAP_DEFAULT_RADIUS;
  var _listings = <ListingModel>[];
  var _isLoading = true;

  late LatLng _location;
  late Placemark? _address;
  late Debouncer _cameraPositionDebouncer;
  MenuModel? _category;

  Future<LatLng> _myLocation() async {
    var position = await l.myPosition();
    var latLng = LatLng(position.latitude, position.longitude);
    return latLng;
  }

  _moveLocation(LatLng latLng, {bool animate = true, Placemark? address, double? zoom}) async {
    if (!mounted) return;
    setState(() {
      _location = latLng;
      _address = address ?? _address;
      _zoom = zoom ?? _zoom;
    });

    final cameraUpdate = CameraUpdate.newCameraPosition(CameraPosition(target: _location, zoom: _zoom,));
    // final cameraUpdate = CameraUpdate.newLatLng(_location);

    if (animate) {
      _mapController?.animateCamera(cameraUpdate);
    } else {
      _mapController?.moveCamera(cameraUpdate);
    }
    // _createMyMarker();
    _getListing();
    address ??= await _getAddress(_location);
    setState(() {
      _address = address;
    });
  }

  _resetLocation() async {
    _moveLocation(await _myLocation(), zoom: SETUP_MAP_DEFAULT_ZOOM);
    // final settings = Provider.of<SettingsProvider>(context, listen: false);
    // final location = LatLng(settings.lastLatitude!, settings.lastLongitude!);
    // _moveLocation(location, address: settings.address, zoom: SETUP_MAP_DEFAULT_ZOOM);
  }

  // _goToLocation(CameraPosition newPosition, [bool animate = true]) async {
  //   var cameraUpdate = CameraUpdate.newCameraPosition(newPosition);
  //   if (animate) _mapController.animateCamera(cameraUpdate);
  //   else _mapController.moveCamera(cameraUpdate);
  // }

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
      _createMapMarker(context, listing, type: "red");
    }
  }

  _createMapMarker(BuildContext context, ListingModel listing, {String type = 'original'}) async {
    final ImageConfiguration imageConfiguration = createLocalImageConfiguration(context);
    var bitmap = await BitmapDescriptor.fromAssetImage(imageConfiguration, 'assets/images/pin/$type.png');
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

  // _createMyMarker() async {
  //   final imageConfiguration = createLocalImageConfiguration(context, size: const Size(40, 40));
  //   final bitmap = await BitmapDescriptor.fromAssetImage(imageConfiguration, 'assets/images/pin/original.png');
  //   final marker = Marker(
  //     markerId: const MarkerId("marker_me"),
  //     position: _location,
  //     icon: bitmap,
  //     draggable: true,
  //     onDragEnd: _moveLocation,
  //     onTap: () async {
  //       var zoom = await _mapController?.getZoomLevel();
  //       print("... CURRENT ZOOM = $zoom");
  //     }
  //   );
    
  //   setState(() {
  //     _markers[0] = marker;
  //   });
  // }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_location);
    return false;
  }

  @override
  void initState() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _address = settings.address;
    _location = LatLng(settings.lastLatitude!, settings.lastLongitude!);
    _cameraPositionDebouncer = Debouncer<CameraPosition>(const Duration(milliseconds: 1000), initialValue: CameraPosition(target: _location, zoom: _zoom));
    _cameraPositionDebouncer.values.listen((cameraPosition) {
      _moveLocation(cameraPosition.target);
    });
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // _createMyMarker();
      _getListing();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              MyAppBar(
                title: "Peta",
                onWillPop: _onWillPop,
                // action: IconButton(icon: const Icon(Icons.location_searching, color: APP_UI_COLOR_MAIN), onPressed: _resetLocation)
                action: MyInputSelect(
                  color: APP_UI_COLOR_MAIN.withOpacity(.1),
                  caretIcon: _category?.icon ?? LineIcons.searchLocation,
                  listMenu: listingCategories,
                  placeholder: "Semua",
                  onSelect: (menu) {
                    if (menu != null) setState(() { _category = menu; });
                  },
                ),
              ),
              Expanded(
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
                          print("MAP CREATED!!!");
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
                        onCameraMove: (cameraPosition) {
                          _cameraPositionDebouncer.value = cameraPosition;
                        },
                        onTap: (latLng) async {
                          _moveLocation(latLng);
                        },
                      ),
                    ),
                    _isLoading ? Container() : Container(
                      padding: const EdgeInsets.only(bottom: 90.0 - APP_UI_BORDER_RADIUS),
                      child: Center(
                        child: MyMapMarker(size: 40.0, onTap: _resetLocation,),
                      ),
                    ),
                    // TODO address box pake bottom sheet
                    Align(alignment: Alignment.bottomCenter, child: AddressBox(_address),),
                    // _isLoading ? Container(color: Colors.white, child: Center(child: UiLoader())) : Container(),
                    IgnorePointer(
                      ignoring: !_isLoading,
                      child: AnimatedOpacity(
                        opacity: _isLoading ? 1 : 0,
                        duration: const Duration(milliseconds: 1000),
                        child: Container(color: APP_UI_COLOR_LIGHT, child: Center(child: _isLoading ? SpinKitChasingDots(color: Colors.teal[200], size: 50,) : const SizedBox())),
                      ),
                    ),
                    // Align(
                    //   alignment: Alignment.topRight,
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(8.0),
                    //     child: MyInputSelect(
                    //       color: APP_UI_COLOR_MAIN.withOpacity(.1),
                    //       caretIcon: _category.icon,
                    //       listMenu: listingCategories,
                    //       placeholder: "Semua",
                    //       onSelect: (menu) {
                    //         if (menu != null) setState(() { _category = menu; });
                    //       },
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddressBox extends StatelessWidget {
  const AddressBox(this.address, {Key? key}) : super(key: key);
  final Placemark? address;

  @override
  Widget build(BuildContext context) {
    if (address == null) return const SizedBox();
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
              Expanded(child: Text(address!.street ?? "N/A")),
            ],),
          ),
        ),
      ),
    );
  }
}

class MyMapMarker extends StatefulWidget {
  const MyMapMarker({Key? key, this.size = 40.0, this.onTap}) : super(key: key);
  final double size;
  final VoidCallback? onTap;

  @override
  _MyMapMarkerState createState() => _MyMapMarkerState();
}

class _MyMapMarkerState extends State<MyMapMarker> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation _animation;

  @override
  void initState() {
    _animationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
    _animation = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceOut,
    ));
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _animationController.forward();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, widget.size * -0.5 + -100.0 * _animation.value),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Image.asset("assets/images/pin/original.png", width: widget.size, height: widget.size,)
        ),
      ),
    );
  }
}