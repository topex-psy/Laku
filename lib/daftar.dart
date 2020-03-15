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
  final _formKey = GlobalKey<FormState>();
  var _registerIndex = 0;

  TextEditingController _namaLengkapController;
  TextEditingController _tanggalLahirController;
  TextEditingController _emailController;
  TextEditingController _lakuTagController;
  FocusNode _namaLengkapFocusNode;
  FocusNode _tanggalLahirFocusNode;
  FocusNode _emailFocusNode;
  FocusNode _lakuTagFocusNode;
  var _namaLengkapError = '';
  var _tanggalLahirError = '';
  var _emailError = '';
  var _lakuTagError = '';
  var _jenisKelamin  = 'L';
  var _tanggalLahir  = '';
  var _lakuTag = '';

  @override
  void initState() {
    super.initState();
    _namaLengkapController = TextEditingController()..addListener(() { if (_namaLengkapController.text.isNotEmpty && _namaLengkapError.isNotEmpty) setState(() { _namaLengkapError = ''; }); });
    _tanggalLahirController = TextEditingController();
    _emailController = TextEditingController()..addListener(() { if (_emailController.text.isNotEmpty && _emailError.isNotEmpty) setState(() { _emailError = ''; }); });
    _lakuTagController = TextEditingController()..addListener(() { if (_lakuTagController.text.isNotEmpty && _lakuTagError.isNotEmpty) setState(() { _lakuTagError = ''; }); });
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
        _lakuTagError = _lakuTagController.text.isEmpty ? "Harap tentukan LakuTag kamu!" : "";
      });
      if (_lakuTagError.isEmpty && _formKey.currentState.validate()) {
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
        _namaLengkapError = _namaLengkapController.text.isEmpty ? "Harap masukkan nama lengkapmu!" : "";
        _emailError = _emailController.text.isEmpty ? "Harap masukkan alamat emailmu!" : "";
        _tanggalLahirError = _tanggalLahir.isEmpty ? "Harap masukkan tanggal lahirmu!" : "";
      });
      if (_namaLengkapError.isEmpty && _emailError.isEmpty && _tanggalLahirError.isEmpty) {
        setState(() { _registerIndex++; });
        _registerScrollController.jumpTo(0);
      }
    }
  }

  Future<bool> _batal() async {
    bool confirm = await h.showConfirm("Batal Daftar?", "Apakah kamu yakin ingin membatalkan pendaftaran?") ?? false;
    if (confirm) a.signOut();
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
                          UiInput(isRequired: true, icon: LineIcons.user, placeholder: "Nama lengkap", type: UiInputType.NAME, controller: _namaLengkapController, focusNode: _namaLengkapFocusNode, error: _namaLengkapError),
                          SizedBox(height: 4,),
                          UiInput(isRequired: true, icon: LineIcons.envelope_o, placeholder: "Alamat email", type: UiInputType.EMAIL, controller: _emailController, focusNode: _emailFocusNode, error: _emailError,),
                          SizedBox(height: 4,),
                          UiInput(isRequired: true, icon: LineIcons.calendar, placeholder: "Tanggal lahir", type: UiInputType.DATE_OF_BIRTH, controller: _tanggalLahirController, focusNode: _tanggalLahirFocusNode, error: _tanggalLahirError, onChanged: (val) {
                            try {
                              setState(() {
                                _tanggalLahir = val == null ? '' : (val as DateTime).toString().substring(0, 10);
                                _tanggalLahirError = '';
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
                        Form(
                          key: _formKey,
                          autovalidate: false,
                          onChanged: () {},
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
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
                              ? UiInput(isRequired: true, icon: LineIcons.at, placeholder: "LakuTag", info: "Tanpa spasi", type: UiInputType.TAG, controller: _lakuTagController, focusNode: _lakuTagFocusNode, error: _lakuTagError)
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
                        )
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