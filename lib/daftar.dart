import 'package:flutter/material.dart';
import 'package:laku/utils/helpers.dart';
import 'package:line_icons/line_icons.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

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
    if (_registerIndex > 0) {
      setState(() {
        _errorText.clear();
        if (_nomorPINController.text.isEmpty) {
          _errorText["pin"] = "Harap buat nomor PIN kamu!";
        } else if (_konfirmasiPINController.text.isEmpty) {
          _errorText["pin2"] = "Harap ketik ulang nomor PIN!";
        } else if (_nomorPINController.text != _konfirmasiPINController.text) {
          _errorText["pin2"] = "Nomor PIN & konfirmasi PIN tidak sama!";
        } else {
          _nomorPIN = _nomorPINController.text;
          _registerUser();
        }
      });
    } else {
      setState(() {
        _errorText.clear();
        if (_namaLengkapController.text.isEmpty) _errorText["name"] = "Harap masukkan nama lengkapmu!";
        if (_emailController.text.isEmpty) _errorText["email"] = "Harap masukkan alamat emailmu!";
        if (_tanggalLahir.isEmpty) _errorText["dob"] = "Harap masukkan tanggal lahirmu!";
      });
      if (_errorText.isEmpty) {
        setState(() {
          _registerIndex++;
          _registerScrollController.jumpTo(0);
        });
      }
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
    return WillPopScope(
      onWillPop: _batal,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              // Card(
              //   margin: EdgeInsets.zero,
              //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              //   elevation: 4,
              //   color: THEME_COLOR,
              //   child: UiCaption(
              //     ["Identitas Saya", "Buat Nomor PIN"][_registerIndex],
              //     no: _registerIndex + 1,
              //     total: 2,
              //     icon: Padding(
              //       padding: EdgeInsets.only(left: 12, right: 12),
              //       child: Icon([LineIcons.user, LineIcons.lock][_registerIndex], color: Colors.white, size: 32.0,),
              //     ),
              //     stepAction: (page) {
              //       if (_registerIndex == page) return;
              //       if (page == 0) _batal(); else _register();
              //     },
              //   ),
              // ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _registerScrollController,
                  padding: EdgeInsets.only(top: 20, right: 20, left: 20, bottom: 50),
                  child: Column(children: <Widget>[
                    IndexedStack(
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
                      ],
                    ),
                  ],),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}