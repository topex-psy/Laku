import 'package:flutter/material.dart';
import 'package:laku/utils/helpers.dart';
import 'package:line_icons/line_icons.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

const jenisKelaminLbl  = <String>['Laki-laki', 'Perempuan'];
const jenisKelaminVal  = <String>['L', 'P'];
const golonganDarahVal = <String>['A', 'B', 'O', 'AB'];
const listProfesi = <String>[
  'Pengusaha',
  'Pegawai negeri',
  'Pegawai swasta',
  'Pekerja lepas',
  'Mahasiswa',
  'Pelajar',
  'Tidak bekerja',
  'Lainnya'
];

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
  TextEditingController _lakuTagController;
  FocusNode _namaLengkapFocusNode;
  FocusNode _tanggalLahirFocusNode;
  FocusNode _emailFocusNode;
  FocusNode _lakuTagFocusNode;
  var _errorText = <String, String>{};
  var _jenisKelamin  = 'L';
  var _tanggalLahir  = '';
  var _lakuTag = '';

  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) setState(() { _errorText.remove(tag); });
  }

  @override
  void initState() {
    super.initState();
    _namaLengkapController = TextEditingController()..addListener(() => _dismissError("name"));
    _tanggalLahirController = TextEditingController();
    _emailController = TextEditingController()..addListener(() => _dismissError("email"));
    _lakuTagController = TextEditingController()..addListener(() => _dismissError("tag"));
    _namaLengkapFocusNode = FocusNode();
    _tanggalLahirFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _lakuTagFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _tanggalLahirController.dispose();
    _emailController.dispose();
    _lakuTagController.dispose();
    _namaLengkapFocusNode.dispose();
    _tanggalLahirFocusNode.dispose();
    _emailFocusNode.dispose();
    _lakuTagFocusNode.dispose();
    super.dispose();
  }

  _register() async {
    if (_registerIndex > 0) {
      if (_lakuTag.isNotEmpty) {
        final registerData = <String, String>{
          'uid': currentPersonUid,
          'namaLengkap': _namaLengkapController.text,
          'gender': _jenisKelamin,
          'tanggalLahir': _tanggalLahir,
          'email': _emailController.text,
          'tag': _lakuTag,
        };
        Navigator.of(context).pop(registerData);
        return;
      }
      setState(() {
        _errorText.clear();
        if (_lakuTagController.text.isEmpty) _errorText["tag"] = "Harap tentukan LakuTag kamu!";
      });
      if (_errorText.isEmpty) {
        h.loadAlert("Memeriksa ...");
        var cekApi = await auth('tag_check', {'tag': _lakuTagController.text});
        print("cekApi = $cekApi");
        h.closeDialog();
        if (cekApi != null && cekApi["status"] == 1) {
          setState(() {
            _lakuTag = _lakuTagController.text;
          });
        }
      }
    } else {
      setState(() {
        _errorText.clear();
        if (_namaLengkapController.text.isEmpty) _errorText["name"] = "Harap masukkan nama lengkapmu!";
        if (_emailController.text.isEmpty) _errorText["email"] = "Harap masukkan alamat emailmu!";
        if (_tanggalLahir.isEmpty) _errorText["dob"] = "Harap masukkan tanggal lahirmu!";
      });
      if (_errorText.isEmpty) {
        setState(() { _registerIndex++; });
        _registerScrollController.jumpTo(0);
      }
    }
  }

  Future<bool> _batal() async {
    if (_registerIndex > 0) {
      setState(() { _registerIndex--; });
      _registerScrollController.jumpTo(0);
    } else {
      bool confirm = await h.showConfirm("Batal Daftar?", "Apakah kamu yakin ingin membatalkan pendaftaran?") ?? false;
      if (confirm) a.signOut();
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
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                elevation: 4,
                color: THEME_COLOR,
                child: UiCaption(
                  no: _registerIndex + 1,
                  total: 2,
                  icon: Padding(
                    padding: EdgeInsets.only(left: 12, right: 12),
                    child: Icon([LineIcons.user, LineIcons.at][_registerIndex], color: Colors.white, size: 32.0,),
                  ),
                  teks: ["Identitas Saya", "Buat LakuTag"][_registerIndex],
                  stepAction: (page) {
                    setState(() { _registerIndex = page; });
                    _registerScrollController.jumpTo(0);
                  },
                ),
              ),
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
                          Row(children: <Widget>[
                            GestureDetector(
                              child: Icon(LineIcons.sign_in, color: THEME_COLOR, size: 69,),
                              onTap: () => _batal(),
                            ),
                            SizedBox(width: 20,),
                            Expanded(child: Text("Silakan lengkapi data diri untuk dapat memulai menggunakan aplikasi $APP_NAME.", style: TextStyle(color: Colors.grey[600], fontSize: 14),)),
                          ],),
                          SizedBox(height: 20,),
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
                              borderRadius: BorderRadius.circular(50.0),
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
                          Center(child: SizedBox(width: 150, height: 46, child: UiButton(color: Colors.green, label: "Lanjut", icon: LineIcons.check_circle_o, textStyle: style.textButtonL, iconRight: true, onPressed: _register,),)),
                        ],),
                        // register step 2: buat pin
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Row(children: <Widget>[
                            Icon(LineIcons.at, color: THEME_COLOR, size: 72,),
                            SizedBox(width: 20,),
                            Expanded(child: RichText(text: TextSpan(
                              style: Theme.of(context).textTheme.bodyText1,
                              children: <TextSpan>[
                                TextSpan(text: 'Buat LakuTag Kamu! ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: 'LakuTag adalah identitas unikmu di aplikasi $APP_NAME. Kamu bisa pakai nama kamu, nama usaha, merek, atau nama unik lainnya.', style: TextStyle(color: Colors.blueGrey),)
                              ],
                            ),),),
                          ],),
                          SizedBox(height: 20,),
                          _lakuTag.isEmpty
                            ? UiInput("LakuTag", info: "Tanpa spasi", isRequired: true, icon: LineIcons.at, type: UiInputType.TAG, controller: _lakuTagController, focusNode: _lakuTagFocusNode, error: _errorText["tag"],)
                            : Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                                // TODO FIXME wrap text
                                Text("@$_lakuTag", style: style.textHeadline),
                                SizedBox(width: 0,),
                                IconButton(icon: Icon(LineIcons.edit), onPressed: () {
                                  setState(() {
                                    _lakuTag = '';
                                  });
                                },),
                              ],),
                          _lakuTag.isEmpty ? SizedBox() : Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                              Icon(Icons.check_circle, color: Colors.green, size: 16,),
                              SizedBox(width: 8,),
                              Text("Selamat, LakuTag tersedia!"),
                            ],),
                          ),
                          SizedBox(height: 12,),
                          Center(child: SizedBox(width: 150, height: 46, child: UiButton(color: Colors.green, label: _lakuTag.isEmpty ? "Daftar" : "Mulai", icon: LineIcons.check, textStyle: style.textButtonL, iconRight: true, onPressed: _register,),),),
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