import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/person.dart';
import '../../utils/api.dart';
import '../../utils/helpers.dart';
import '../../utils/widgets.dart';

class ResetPIN extends StatefulWidget {
  @override
  _ResetPINState createState() => _ResetPINState();
}

class _ResetPINState extends State<ResetPIN> {
  TextEditingController _sandiLamaController;
  TextEditingController _sandiController;
  TextEditingController _konfirmSandiController;
  FocusNode _sandiLamaFocusNode;
  FocusNode _sandiFocusNode;
  FocusNode _konfirmSandiFocusNode;
  bool _isProcessing = false;

  @override
  void initState() {
    _sandiLamaController = TextEditingController();
    _sandiController = TextEditingController();
    _konfirmSandiController = TextEditingController();
    _sandiLamaFocusNode = FocusNode();
    _sandiFocusNode = FocusNode();
    _konfirmSandiFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _sandiLamaController.dispose();
    _sandiController.dispose();
    _konfirmSandiController.dispose();
    _sandiLamaFocusNode.dispose();
    _sandiFocusNode.dispose();
    _konfirmSandiFocusNode.dispose();
    super.dispose();
  }

  _submit() async {
    String pinLama = _sandiLamaController.text ?? '';
    String pinBaru = _sandiController.text ?? '';
    if (pinLama.isEmpty || pinBaru.isEmpty) {
      h.showFlashBar("Masukkan nomor PIN!", "Harap masukkan nomor PIN lama dan PIN baru.");
      _sandiFocusNode.requestFocus();
      return;
    }
    if (_konfirmSandiController.text != pinBaru) {
      h.showFlashBar("Konfirmasi nomor PIN tidak cocok!", "Harap periksa kembali PIN dan konfirmasi PIN Baru Anda.");
      _konfirmSandiFocusNode.requestFocus();
      return;
    }
    setState(() => _isProcessing = true);
    final person = Provider.of<PersonProvider>(context, listen: false);
    final user = await a.firebaseLoginEmailPassword(person.email, pinLama);
    if (user != null) user.updatePassword(pinBaru).then((_) {
      print("Firebase: Password changed successfully");
      auth('reset_password', {'uid': userSession.uid, 'pinLama': pinLama, 'pinBaru': pinBaru}).then((resetApi) {
        if (resetApi.isSuccess) {
          h.closeDialog();
          h.showFlashbarSuccess("Nomor PIN Disunting!", "Nomor PIN Anda berhasil diganti!");
        } else {
          h.failAlert("Gagal Memproses", resetApi.message ?? "Terjadi kendala saat memproses penggantian PIN Anda. Coba kembali nanti!");
        }
      }).catchError((e) {
        print("GANTI PIN ERROOOOOOOOOOOOR: $e");
        h.failAlert("Gagal Memproses", "Terjadi kendala saat memproses penggantian PIN Anda. Coba kembali nanti!");
      }).whenComplete(() {
        print("GANTI PIN DONEEEEEEEEEEEEE!");
        setState(() => _isProcessing = false);
      });
    }).catchError((error) {
      print("Firebase: Password can't be changed: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isProcessing ? Padding(
      padding: EdgeInsets.all(20),
      child: UiLoader(label: "Mengubah PIN ...",),
    ) : Column(children: <Widget>[
      UiInput("PIN Lama", isRequired: true, icon: LineIcons.lock, type: UiInputType.PIN, controller: _sandiLamaController, focusNode: _sandiLamaFocusNode),
      UiInput("PIN Baru", isRequired: true, icon: LineIcons.unlock, info: "6-digit", type: UiInputType.PIN, controller: _sandiController, focusNode: _sandiFocusNode),
      UiInput("Konfirmasi PIN Baru", isRequired: true, icon: LineIcons.unlock_alt, type: UiInputType.PIN, controller: _konfirmSandiController, focusNode: _konfirmSandiFocusNode),
      SizedBox(height: 12,),
      UiButton("Simpan", height: 46, color: Colors.green, icon: LineIcons.check, iconSize: 30, iconRight: true, onPressed: _submit,),
    ],);
  }
}