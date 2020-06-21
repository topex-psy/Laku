import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'models/basic.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';


const jenisKelaminLbl  = <String>['Laki-laki', 'Perempuan'];
const jenisKelaminVal  = <String>['L', 'P'];

class Daftar extends StatefulWidget {
  @override
  _DaftarState createState() => _DaftarState();
}

class _DaftarState extends State<Daftar> {
  final _registerScrollController = ScrollController();
  var _registerIndex = 0;

  TextEditingController _namaLengkapController;
  TextEditingController _tanggalLahirController;
  TextEditingController _emailController;
  TextEditingController _nomorPINController;
  TextEditingController _konfirmasiPINController;
  FocusNode _namaLengkapFocusNode;
  FocusNode _tanggalLahirFocusNode;
  FocusNode _emailFocusNode;
  FocusNode _nomorPINFocusNode;
  FocusNode _konfirmasiPINFocusNode;
  var _errorText = <String, String>{};
  var _jenisKelamin  = 'L';
  var _tanggalLahir  = '';
  var _nomorPIN = '';

  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) setState(() {
      _errorText.remove(tag);
    });
  }

  @override
  void initState() {
    super.initState();
    _namaLengkapController = TextEditingController()..addListener(() => _dismissError("name"));
    _tanggalLahirController = TextEditingController();
    _emailController = TextEditingController()..addListener(() => _dismissError("email"));
    _nomorPINController = TextEditingController()..addListener(() => _dismissError("pin"));
    _konfirmasiPINController = TextEditingController()..addListener(() => _dismissError("pin2"));
    _namaLengkapFocusNode = FocusNode();
    _tanggalLahirFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _nomorPINFocusNode = FocusNode();
    _konfirmasiPINFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _tanggalLahirController.dispose();
    _emailController.dispose();
    _nomorPINController.dispose();
    _konfirmasiPINController.dispose();
    _namaLengkapFocusNode.dispose();
    _tanggalLahirFocusNode.dispose();
    _emailFocusNode.dispose();
    _nomorPINFocusNode.dispose();
    _konfirmasiPINFocusNode.dispose();
    super.dispose();
  }

  _registerUser() async {
    // var cekApi = await auth('tag_check', {'tag': tag});
    final registerData = <String, String>{
      'uid': currentPerson.uid,
      'phone': currentPerson.phone,
      'namaLengkap': _namaLengkapController.text,
      'gender': _jenisKelamin,
      'tanggalLahir': _tanggalLahir,
      'email': _emailController.text,
      'pin': _nomorPIN,
    };
    h.loadAlert();
    await auth('register', registerData);
    Navigator.of(context).popUntil((route) => route.settings.name == ROUTE_LOGIN);
  }

  _register() async {
    setState(() {
      _errorText.clear();
      switch(_registerIndex) {
        case 2:
          break;
        case 1:
          if (_nomorPINController.text.isEmpty) {
            _errorText["pin"] = "Harap buat nomor PIN kamu!";
          } else if (_konfirmasiPINController.text.isEmpty) {
            _errorText["pin2"] = "Harap ketik ulang nomor PIN!";
          } else if (_nomorPINController.text != _konfirmasiPINController.text) {
            _errorText["pin2"] = "Nomor PIN & konfirmasi PIN tidak sama!";
          } else {
            _nomorPIN = _nomorPINController.text;
          }
          break;
        default:
          if (_namaLengkapController.text.isEmpty) _errorText["name"] = "Harap masukkan nama lengkapmu!";
          if (_emailController.text.isEmpty) _errorText["email"] = "Harap masukkan alamat emailmu!";
          if (_tanggalLahir.isEmpty) _errorText["dob"] = "Harap masukkan tanggal lahirmu!";
      }
    });
    if (_errorText.isEmpty) {
      _lanjut();
    }
  }

  _lanjut() async {
    if (_registerIndex == 2) {
      _registerUser();
      return;
    }
    var _isValid = false;
    if (_registerIndex == 1) {
      if (await Permission.location.request().isGranted) {
        _isValid = true;
      } else {
        h.showFlashBar("Izin Anda Dibutuhkan", "Anda harus mengizinkan akses lokasi untuk melanjutkan pendaftaran.", action: _lanjut, actionLabel: "Izinkan");
      }
    } else {
      _isValid = true;
    }
    if (_isValid) {
      setState(() {
        _registerIndex++;
        _registerScrollController.jumpTo(0);
      });
    }
  }

  Future<bool> _batal() async {
    if (_registerIndex > 0) {
      setState(() {
        _registerIndex--;
        _registerScrollController.jumpTo(0);
      });
    } else {
      if (await h.showConfirm("Batal Daftar?", "Apakah kamu yakin ingin membatalkan pendaftaran?")) a.signOut();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {

    final _listSteps = <IconLabel>[
      IconLabel(LineIcons.user, "Identitas"),
      IconLabel(LineIcons.unlock, "Nomor PIN"),
      IconLabel(LineIcons.map_marker, "Lokasi"),
    ];

    return WillPopScope(
      onWillPop: _batal,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                elevation: 4,
                color: THEME_COLOR,
                child: UiCaption(
                  steps: _listSteps,
                  currentIndex: _registerIndex,
                  stepAction: (index) {
                    if (index == _registerIndex - 1) _batal();
                    else if (index == _registerIndex + 1) _register();
                  },
                ),
              ),

              // SizedBox(height: 30,),
              
              // UiStepIndicator(list: _listSteps, currentIndex: _registerIndex, onTapDot: (index) {
              //   if (index == _registerIndex - 1) _batal();
              //   else if (index == _registerIndex + 1) _register();
              // },),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: _registerScrollController,
                  padding: EdgeInsets.only(top: 20, right: 20, left: 20, bottom: 50),
                  child: IndexedStack(
                    index: _registerIndex,
                    children: <Widget>[
                      // register step 1: identitas
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        SizedBox(height: 10,),
                        Row(children: <Widget>[
                          GestureDetector(
                            child: Icon(LineIcons.sign_in, color: THEME_COLOR, size: 69,),
                            onTap: () => _batal(),
                          ),
                          SizedBox(width: 20,),
                          Expanded(child: Text("Silakan lengkapi data diri untuk dapat memulai menggunakan aplikasi $APP_NAME.", style: TextStyle(color: Colors.grey[600], fontSize: 14),)),
                        ],),
                        SizedBox(height: 30,),
                        UiInput("Nama lengkap", isRequired: true, icon: LineIcons.user, type: UiInputType.NAME, controller: _namaLengkapController, focusNode: _namaLengkapFocusNode, error: _errorText["name"],),
                        SizedBox(height: 4,),
                        UiInput("Alamat email", isRequired: true, icon: LineIcons.envelope_o, type: UiInputType.EMAIL, controller: _emailController, focusNode: _emailFocusNode, error: _errorText["email"],),
                        SizedBox(height: 4,),
                        UiInput("Tanggal lahir", isRequired: true, icon: LineIcons.calendar, type: UiInputType.DATE_OF_BIRTH, controller: _tanggalLahirController, focusNode: _tanggalLahirFocusNode, error: _errorText["dob"], onChanged: (val) {
                          try {
                            setState(() {
                              _tanggalLahir = val == null ? '' : (val as DateTime).toString().substring(0, 10);
                              if (_errorText.containsKey("dob")) _errorText.remove("dob");
                            });
                          } catch (e) {
                            print("DATETIME PICKER ERROR = $e");
                          }
                        },),
                        SizedBox(height: 4,),
                        Text("Jenis kelamin:", style: style.textLabel),
                        SizedBox(height: 8.0,),
                        SizedBox(
                          height: 45.0,
                          child: ToggleButtons(
                            borderRadius: BorderRadius.circular(THEME_BORDER_RADIUS),
                            children: <Widget>[
                              Row(children: <Widget>[
                                SizedBox(width: 20.0),
                                Icon(LineIcons.male, size: 17,),
                                SizedBox(width: 8.0),
                                Text(jenisKelaminLbl[0], style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),),
                                SizedBox(width: 15.0),
                              ],),
                              Row(children: <Widget>[
                                SizedBox(width: 15.0),
                                Icon(LineIcons.female, size: 17,),
                                SizedBox(width: 8.0),
                                Text(jenisKelaminLbl[1], style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),),
                                SizedBox(width: 20.0),
                              ],),
                            ],
                            onPressed: (int index) {
                              setState(() {
                                _jenisKelamin = jenisKelaminVal[index];
                              });
                            },
                            isSelected: <bool>[
                              _jenisKelamin == jenisKelaminVal[0],
                              _jenisKelamin == jenisKelaminVal[1],
                            ],
                          ),
                        ),
                        SizedBox(height: 30,),
                        Center(child: UiButton("Lanjut", height: style.heightButtonL, color: Colors.green, icon: LineIcons.check_circle_o, textStyle: style.textButtonL, iconRight: true, onPressed: _register,),),
                      ],),
                      // register step 2: buat pin
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        SizedBox(height: 10,),
                        Row(children: <Widget>[
                          Icon(LineIcons.info_circle, color: THEME_COLOR, size: 69,),
                          SizedBox(width: 20,),
                          Expanded(child: Text("Buat kode 6-digit angka rahasia Anda untuk dapat mengakses aplikasi $APP_NAME.", style: TextStyle(color: Colors.grey[600], fontSize: 14),)),
                        ],),
                        SizedBox(height: 20,),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber[200],
                            borderRadius: BorderRadius.circular(10)
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: RichText(text: TextSpan(
                            style: Theme.of(context).textTheme.bodyText1,
                            children: <TextSpan>[
                              TextSpan(text: 'PENTING: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: 'Harap ingat nomor PIN Anda!', style: TextStyle(color: Colors.grey[600]),)
                            ],
                          ),),
                        ),
                        SizedBox(height: 30,),
                        UiInput("Buat Nomor PIN", info: "6-digit", textStyle: style.textInputL, isRequired: true, icon: LineIcons.unlock_alt, type: UiInputType.PIN, controller: _nomorPINController, focusNode: _nomorPINFocusNode, error: _errorText["pin"],),
                        SizedBox(height: 4,),
                        UiInput("Konfirmasi Nomor PIN", textStyle: style.textInputL, isRequired: true, icon: LineIcons.unlock, type: UiInputType.PIN, controller: _konfirmasiPINController, focusNode: _konfirmasiPINFocusNode, error: _errorText["pin2"],),
                        SizedBox(height: 20,),
                        Center(child: UiButton("Daftar", height: style.heightButtonL, color: Colors.green, icon: LineIcons.check, textStyle: style.textButtonL, iconRight: true, onPressed: _register,),),
                      ],),
                      // register step 3: lokasi
                      // FormLocation(isStarted: _registerIndex == _listSteps.length - 1,),
                      Container()
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormLocation extends StatefulWidget {
  FormLocation({Key key, this.isStarted = false}) : super(key: key);
  final bool isStarted;

  @override
  _FormLocationState createState() => _FormLocationState();
}

class _FormLocationState extends State<FormLocation> {
  final _cameraPositionDebouncer = Debouncer<CameraPosition>(Duration(milliseconds: 1000));
  final _defaultLocation = LatLng(-7.928461, 112.6385513);
  final _defaultZoom = 18.0;

  GoogleMapController _mapController;
  CameraPosition _myLocation;
  CameraPosition _location;
  String _address;

  var _isGettingLocation = false;

  @override
  void initState() {
    _cameraPositionDebouncer.values.listen((cameraPosition) {
      _setLocation(cameraPosition);
    });
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isStarted) _getMyLocation();
    });
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

  @override
  void didUpdateWidget(FormLocation oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!oldWidget.isStarted && widget.isStarted) _getMyLocation(); else setState(() {
        _location = null;
        _address = null;
      });
    });
  }

  _getMyLocation() async {
    if (_location != null || _isGettingLocation) return;
    _isGettingLocation = true;
    print("... GETTING MY LOCATION");
    var position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    var latLng = LatLng(position.latitude, position.longitude);
    print("... GETTING MY LOCATION result: $latLng");
    Future.delayed(Duration.zero, () {
      _myLocation = CameraPosition(target: latLng, zoom: _defaultZoom,);
      _isGettingLocation = false;
      _setLocation(_myLocation);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  _goToLocation(CameraPosition newPosition, [bool animate = true]) async {
    var cameraUpdate = CameraUpdate.newCameraPosition(newPosition);
    if (animate) _mapController.animateCamera(cameraUpdate);
    else _mapController.moveCamera(cameraUpdate);
  }

  Future<String> _getAddress(LatLng latLng) async {
    final coordinates = Coordinates(latLng.latitude, latLng.longitude);
    var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    print(
      "... GET ADDRESS RESULT"
      "\n name: ${first.featureName}"
      "\n address: ${first.addressLine}"
    );
    return first.addressLine;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text("Di mana lokasi Anda?", textAlign: TextAlign.center, style: style.textWhite),
        SizedBox(height: 12,),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _location?.target ?? _defaultLocation,
                  zoom: _location?.zoom ?? _defaultZoom,
                  bearing: 0.0,
                  tilt: 0.0,
                ),
                mapType: MapType.normal,
                onMapCreated: (googleMapController) {
                  _mapController = googleMapController;
                  rootBundle.loadString('assets/map_style.txt').then((json) {
                    _mapController.setMapStyle(json);
                  });
                },
                onCameraMove: (cameraPosition) {
                  _cameraPositionDebouncer.value = cameraPosition;
                },
                onTap: (latLng) {
                  // var cameraUpdate = CameraUpdate.newCameraPosition(CameraPosition(target: latLng,),);
                  // _mapController?.animateCamera(cameraUpdate);
                  _goToLocation(CameraPosition(target: latLng,),);
                },
              ),
              _location == null ? Container() : UiMapMarker(size: 50.0, onTap: () => _goToLocation(_myLocation),),
              _address == null ? Container() : Align(alignment: Alignment.bottomCenter, child: AddressBox(address: _address, onSetAddress: (address) => setState(() { _address = address; }),),),
              _address == null ? UiLoader(label: "Memuat lokasi ...",) : Container()
            ],
          ),
        ),
      ],
    );
  }
}

class AddressBox extends StatefulWidget {
  AddressBox({Key key, @required this.address, @required this.onSetAddress}) : super(key: key);
  final String address;
  final void Function(String) onSetAddress;

  @override
  _AddressBoxState createState() => _AddressBoxState();
}

class _AddressBoxState extends State<AddressBox> {
  TextEditingController _companyAddressController;
  FocusNode _companyAddressFocusNode;
  var _companyAddressError = '';

  @override
  void initState() {
    _companyAddressController = TextEditingController();
    _companyAddressFocusNode = FocusNode();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  @override
  void dispose() {
    _companyAddressController.dispose();
    _companyAddressFocusNode.dispose();
    super.dispose();
  }

  _setAddress() {
    var _newAddress = _companyAddressController.text;
    setState(() {
      if (_newAddress == null || _newAddress.isEmpty) {
        _companyAddressError = 'Harap masukkan alamat usaha Anda';
      } else {
        _companyAddressError = '';
        widget.onSetAddress(_newAddress);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var _isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Container(
      height: _isPortrait ? 90 : 70,
      child: Card(
        color: Colors.white,
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            _companyAddressController.text = widget.address;
            h.showAlert(title: "Alamat Usaha Anda", showButton: false, body: Column(children: <Widget>[
              Text("Berikan alamat terang termasuk kelurahan, kecamatan, dan kode pos.", style: TextStyle(color: Colors.grey)),
              UiInput("Alamat Usaha", type: UiInputType.NOTE, isRequired: true, height: 100, borderRadius: BorderRadius.circular(12), icon: LineIcons.map_marker, controller: _companyAddressController, focusNode: _companyAddressFocusNode, error: _companyAddressError,),
              SizedBox(height: 8,),
              UiButton("OK", width: 100, height: 45, color: THEME_COLOR, onPressed: () {
                FocusScope.of(context).requestFocus(FocusNode());
                h.closeDialog();
                _setAddress();
              },),
            ],),);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: Row(children: <Widget>[
              Icon(LineIcons.map_marker, size: 30, color: THEME_COLOR,),
              SizedBox(width: 8,),
              Expanded(child: Text(widget.address,)),
              SizedBox(width: 8,),
              Icon(LineIcons.edit, size: 20, color: THEME_COLOR,),
            ],),
          ),
        ),
      ),
    );
  }
}