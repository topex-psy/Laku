import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/basic.dart';
import 'models/user.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _listSteps = <IconLabel>[
    IconLabel(LineIcons.user, "Identitas Diri"),
    IconLabel(LineIcons.unlock, "Buat Nomor PIN"),
    IconLabel(LineIcons.map_o, "Tentukan Lokasi"),
  ];
  final _scrollControllers = [
    ScrollController(),
    ScrollController(),
  ];
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
  var _alamat = '';
  double _lat, _lng;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
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

  _navigate(index) async {
    print(" ... NAVIGATE: $index");
    var isGranted = true;
    if (index == 2) { // form lokasi
      isGranted = await Permission.location.request().isGranted;
      if (!isGranted) {
        h.showFlashBar("Izin Anda Dibutuhkan", "Anda harus mengizinkan akses lokasi untuk melanjutkan pendaftaran.", action: () => _navigate(index), actionLabel: "Izinkan");
      }
    }

    if (isGranted) setState(() {
      _registerIndex = index;
      if (index < 2) _scrollControllers[index].jumpTo(0);
    });
  }

  _submit() async {
    final registerData = <String, String>{
      'uid': userSession.uid,
      'phone': userSession.phone.replaceFirst(APP_COUNTRY_CODE, ''),
      'namaLengkap': _namaLengkapController.text,
      'gender': _jenisKelamin,
      'tanggalLahir': _tanggalLahir,
      'email': _emailController.text,
      'pin': _nomorPIN,
      'address': _alamat,
      'lat': _lat.toString(),
      'lng': _lng.toString(),
    };
    h.loadAlert();
    var registerApi = await auth('register', registerData);
    if (registerApi.isSuccess) {
      a.firebaseUpdateProfile(namaLengkap: registerData['namaLengkap']);
      a.firebaseLinkWithEmail(
        registerData['email'],
        registerData['pin'],
      );
      // Navigator.of(context).popUntil((route) => route.settings.name == ROUTE_LOGIN);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pop();
      h.failAlert("Gagal Memproses", "Terjadi kendala saat memproses pendaftaran akun Anda.");
    }
  }

  _register() async {
    print(" ... REGISTER");
    // var errorString = <String, String>{};
    var invalidIndex = -1;
    if (_registerIndex == 2) {
    }
    if (_registerIndex >= 1 && invalidIndex < 0) {
      if (_nomorPINController.text.isEmpty) {
        _errorText["pin"] = "Harap buat nomor PIN kamu!";
      } else if (_konfirmasiPINController.text.isEmpty) {
        _errorText["pin2"] = "Harap ketik ulang nomor PIN!";
      } else if (_nomorPINController.text != _konfirmasiPINController.text) {
        _errorText["pin2"] = "Nomor PIN & konfirmasi PIN tidak sama!";
      } else {
        _nomorPIN = _nomorPINController.text;
      }
      if (_errorText.isNotEmpty) {
        invalidIndex = 1;
      }
    }
    if (_registerIndex >= 0 && invalidIndex < 0) {
      if (_namaLengkapController.text.isEmpty) _errorText["name"] = "Harap masukkan nama lengkapmu!";
      if (_emailController.text.isEmpty) _errorText["email"] = "Harap masukkan alamat emailmu!";
      else if (!f.isValidEmail(_emailController.text)) _errorText["email"] = "Harap masukkan alamat email valid!";
      if (_tanggalLahir.isEmpty) _errorText["dob"] = "Harap masukkan tanggal lahirmu!";
      if (_errorText.isNotEmpty) {
        invalidIndex = 0;
      }
    }
    print(" ... REGISTER invalidIndex = $invalidIndex");
    if (invalidIndex >= 0) {
      print(" ... REGISTER cond = 1");
      _navigate(invalidIndex);
    } else if (_registerIndex == _listSteps.length - 1) {
      print(" ... REGISTER cond = 2");
      _submit();
    } else {
      print(" ... REGISTER cond = 3");
      _navigate(_registerIndex + 1);
    }
  }

  Future<bool> _batal() async {
    if (_registerIndex > 0) {
      _navigate(_registerIndex - 1);
    } else {
      if (await h.showConfirm("Batal Daftar?", "Apakah kamu yakin ingin membatalkan pendaftaran?")) a.signOut();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _batal,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              UiCaption(steps: _listSteps, currentIndex: _registerIndex, stepAction: _navigate,),
              Expanded(
                child: IndexedStack(
                  index: _registerIndex,
                  children: <Widget>[
                    // register step 1: identitas
                    SingleChildScrollView(
                      controller: _scrollControllers[0],
                      padding: EdgeInsets.only(top: 20, right: 20, left: 20, bottom: 50),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
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
                        UiInput("Alamat email", isRequired: true, icon: LineIcons.envelope_o, type: UiInputType.EMAIL, controller: _emailController, focusNode: _emailFocusNode, error: _errorText["email"],),
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
                        UiButton("Lanjut", height: style.heightButtonL, color: Colors.green, icon: LineIcons.check_circle_o, textStyle: style.textButtonL, iconRight: true, onPressed: _register,),
                      ],),
                    ),
                    // register step 2: buat pin
                    SingleChildScrollView(
                      controller: _scrollControllers[1],
                      padding: EdgeInsets.only(top: 20, right: 20, left: 20, bottom: 50),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
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
                        UiButton("Daftar", height: style.heightButtonL, color: Colors.green, icon: LineIcons.check, textStyle: style.textButtonL, iconRight: true, onPressed: _register,),
                      ],),
                    ),
                    // register step 3: lokasi
                    FormLocation(
                      isStarted: _registerIndex == _listSteps.length - 1,
                      onSubmit: (address, latLng) {
                        _alamat = address;
                        _lat = latLng.latitude;
                        _lng = latLng.longitude;
                        _register();
                      },
                    ),
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

class FormLocation extends StatefulWidget {
  FormLocation({Key key, this.isStarted = false, @required this.onSubmit}) : super(key: key);
  final bool isStarted;
  final void Function(String, LatLng) onSubmit;

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
      if (!oldWidget.isStarted && widget.isStarted) _getMyLocation();
      else if (!widget.isStarted) setState(() {
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
    return Stack(
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
            print(" -> tap location: $latLng");
            _goToLocation(CameraPosition(target: latLng, zoom: _defaultZoom),);
          },
        ),
        _location == null ? Container() : UiMapMarker(size: 50.0, onTap: () => _goToLocation(_myLocation),),
        _address == null ? Container() : Align(alignment: Alignment.bottomCenter, child: Container(
          height: 150,
          child: Card(
            color: Colors.white,
            elevation: 4,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Row(children: <Widget>[
                      Icon(LineIcons.map_marker, size: 30, color: THEME_COLOR,),
                      SizedBox(width: 8,),
                      Expanded(child: Text(_address,)),
                      SizedBox(width: 8,),
                      IconButton(
                        icon: Icon(LineIcons.edit),
                        iconSize: 20,
                        color: THEME_COLOR,
                        onPressed: () async {
                          var address = await h.showAlert(title: "Alamat Anda", showButton: false, body: FormAddress(address: _address),);
                          if (address != null && address.isNotEmpty) {
                            print(" ... ON SET ADDRESS = $address");
                            setState(() {
                              _address = address;
                            });
                          }
                        },
                      ),
                    ],),
                  ),
                  SizedBox(height: 8),
                  UiButton(
                    "Daftar",
                    height: style.heightButtonL,
                    color: Colors.green,
                    icon: LineIcons.check,
                    textStyle: style.textButtonL,
                    iconRight: true,
                    onPressed: _address == null ? null : () => widget.onSubmit(_address, _location.target),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),),
        _address == null ? Container(width: double.infinity, color: THEME_BACKGROUND, child: UiLoader(label: "Memuat lokasi ...")) : Container()
      ],
    );
  }
}

class FormAddress extends StatefulWidget {
  FormAddress({Key key, this.address}) : super(key: key);
  final String address;

  @override
  _FormAddressState createState() => _FormAddressState();
}

class _FormAddressState extends State<FormAddress> {
  TextEditingController _addressController;
  FocusNode _addressFocusNode;
  var _addressError = '';

  @override
  void initState() {
    _addressController = TextEditingController();
    _addressFocusNode = FocusNode();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _addressController.text = widget.address;
      _addressFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  _submit() {
    FocusScope.of(context).unfocus();
    var address = _addressController.text;
    setState(() {
      if (address == null || address.isEmpty) {
        _addressError = 'Harap masukkan alamat Anda';
      } else {
        _addressError = '';
        Navigator.of(context).pop(address);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Text("Berikan alamat terang termasuk kelurahan, kecamatan, dan kode pos.", style: TextStyle(color: Colors.grey, fontSize: 12)),
      SizedBox(height: 12,),
      UiInput(
        "Alamat",
        type: UiInputType.NOTE,
        isRequired: true,
        height: 150,
        borderRadius: BorderRadius.circular(12),
        showLabel: false,
        controller: _addressController,
        focusNode: _addressFocusNode,
        error: _addressError,
        onSubmit: (address) => _submit(),
      ),
      SizedBox(height: 8,),
      UiButton("OK", width: 100, height: 45, color: THEME_COLOR, onPressed: _submit,),
    ],);
  }
}