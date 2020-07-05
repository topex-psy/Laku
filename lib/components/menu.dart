import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:launch_review/launch_review.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../utils/helpers.dart';
import '../utils/widgets.dart';

enum MenuNavVal {
  shop,
  feedback,
  settings,
  upgrade,
  logout,
}

class DrawerMenuItem {
  DrawerMenuItem({@required this.value, this.icon, this.teks = '', this.isFirst = false, this.isLast = false});
  final MenuNavVal value;
  final IconData icon;
  final String teks;
  final bool isFirst;
  final bool isLast;
}

class DrawerMenu extends StatefulWidget {
  @override
  _DrawerMenuState createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  MenuNavVal _inProgress;

  _aksiMenu(BuildContext context, MenuNavVal val) async {
    switch (val) {
      case MenuNavVal.feedback:
        Navigator.of(context).pop();
        LaunchReview.launch();
        break;
      case MenuNavVal.shop:
        a.openMyShop();
        break;
      case MenuNavVal.settings:
        // TODO ganti password, bind akun, hapus akun
        break;
      case MenuNavVal.upgrade:
        // TODO upgrade akun
        break;
      case MenuNavVal.logout:
        Navigator.of(context).pop();
        a.logout();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DrawerMenuItem> _menu = [
      DrawerMenuItem(value: MenuNavVal.upgrade, icon: MdiIcons.certificateOutline, teks: 'menu_upgrade'.tr()),
      DrawerMenuItem(value: MenuNavVal.shop, icon: MdiIcons.storefrontOutline, teks: 'menu_shop'.tr()),
      DrawerMenuItem(value: MenuNavVal.settings, icon: MdiIcons.cogOutline, teks: 'menu_settings'.tr()),
      DrawerMenuItem(value: MenuNavVal.feedback, icon: MdiIcons.commentCheckOutline, teks: 'menu_feedback'.tr()),
      DrawerMenuItem(value: MenuNavVal.logout, icon: MdiIcons.logout, teks: 'menu_logout'.tr()),
    ];
    
    return Column(children: _menu.map((DrawerMenuItem menu) {
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