import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:launch_review/launch_review.dart';
import 'package:line_icons/line_icons.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/widgets.dart';

enum MenuNavVal {
  profile,
  feedback,
  settings,
  upgrade,
  logout,
}

class MenuNavItem {
  MenuNavItem({@required this.value, this.icon, this.teks = '', this.isFirst = false, this.isLast = false});
  final MenuNavVal value;
  final IconData icon;
  final String teks;
  final bool isFirst;
  final bool isLast;
}

class MenuNavContent extends StatefulWidget {
  @override
  _MenuNavContentState createState() => _MenuNavContentState();
}

class _MenuNavContentState extends State<MenuNavContent> {
  MenuNavVal _inProgress;

  _aksiMenu(BuildContext context, MenuNavVal val) async {
    switch (val) {
      case MenuNavVal.feedback:
        Navigator.of(context).pop();
        LaunchReview.launch();
        break;
      case MenuNavVal.profile:
        // TODO edit profil (identitas, kontak, foto)
        final results = await Navigator.of(context).pushNamed(ROUTE_PROFIL) as Map;
        print(" ... ROUTE PROFIL result: $results");
        break;
      case MenuNavVal.settings:
        // TODO ganti password, bind akun, hapus akun
        break;
      case MenuNavVal.upgrade:
        // TODO upgrade akun
        break;
      case MenuNavVal.logout:
        Navigator.of(context).pop();
        bool confirm = await h.showConfirm("Akhiri Sesi?", "Apakah kamu yakin ingin mengakhiri sesi?") ?? false;
        if (confirm) a.signOut();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MenuNavItem> _menu = [
      MenuNavItem(value: MenuNavVal.upgrade, icon: LineIcons.certificate, teks: 'menu_upgrade'.tr()),
      MenuNavItem(value: MenuNavVal.profile, icon: LineIcons.user, teks: 'menu_profile'.tr()),
      MenuNavItem(value: MenuNavVal.settings, icon: LineIcons.cog, teks: 'menu_settings'.tr()),
      MenuNavItem(value: MenuNavVal.feedback, icon: LineIcons.comment_o, teks: 'menu_feedback'.tr()),
      MenuNavItem(value: MenuNavVal.logout, icon: LineIcons.sign_out, teks: 'menu_logout'.tr()),
    ];
    
    return Column(children: _menu.map((MenuNavItem menu) {
      bool _isFirst = menu.isFirst || _menu.indexOf(menu) == 0;
      bool _isLast = menu.isLast || _menu.indexOf(menu) == _menu.length - 1;
      return UiMenuList(
        isFirst: _isFirst,
        isLast: _isLast,
        icon: menu.icon,
        teks: menu.teks,
        value: menu.value,
        aksi: menu.value == _inProgress ? null : (val) {
          _aksiMenu(context, val as MenuNavVal);
        },
      );
    }).toList(),);
  }
}