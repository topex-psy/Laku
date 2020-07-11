import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:launch_review/launch_review.dart';
import 'package:line_icons/line_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../utils/helpers.dart';
import '../utils/styles.dart' as style;
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
        h.showAlert(title: "Upgrade Akun", showButton: true, buttonText: "Tutup", listView: ListView.separated(
          padding: EdgeInsets.all(12),
          itemBuilder: (context, index) {
            var tier = userTiers[index];
            var isMine = tier.tier == userSession.tier.tier;
            var isNext = tier.tier == userSession.tier.tier + 1;
            var isPast = tier.tier < userSession.tier.tier;
            var color = Colors.grey[100];
            if (isPast) color = Colors.amber[100];
            if (isMine) color = Colors.green[50];
            if (isNext) color = Colors.blue[50];
            return Transform.scale(
              scale: isNext ? 1.1 : 1.0,
              child: Card(
                margin: isNext ? EdgeInsets.symmetric(vertical: 14, horizontal: 6) : EdgeInsets.symmetric(vertical: 4),
                shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(30)),
                clipBehavior: Clip.antiAlias,
                color: color,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(children: <Widget>[
                          Expanded(child: Text(tier.judul, style: style.textTitle,)),
                          isMine ? Icon(MdiIcons.checkCircle, color: Colors.green) : SizedBox(),
                        ],),
                        isPast ? SizedBox() : Column(
                          children: <Widget>[
                            SizedBox(height: 6,),
                            Row(children: <Widget>[
                              Text("Maksimal Radius", style: style.textS),
                              Spacer(),
                              Text(f.distanceLabel(tier.radius.toDouble()), textAlign: TextAlign.end, style: style.textCaption,)
                            ],),
                            Row(children: <Widget>[
                              Text("Maksimal Lokasi", style: style.textS),
                              Spacer(),
                              Text(f.formatNumber(tier.maxShop), textAlign: TextAlign.end, style: style.textCaption,)
                            ],),
                            Row(children: <Widget>[
                              Text("Maksimal Foto per Iklan", style: style.textS),
                              Spacer(),
                              Text(f.formatNumber(tier.maxListingPic), textAlign: TextAlign.end, style: style.textCaption,)
                            ],),
                            Row(children: <Widget>[
                              Text("Maksimal Deskripsi Iklan", style: style.textS),
                              Spacer(),
                              Text(f.formatNumber(tier.maxListingDesc), textAlign: TextAlign.end, style: style.textCaption,)
                            ],),
                            isNext
                              ? Padding(
                                padding: EdgeInsets.only(top: 12, bottom: 8),
                                child: Text(f.formatPrice2(tier.hargaUpgrade), style: style.textCaption,),
                              )
                              : SizedBox(),
                            isNext
                              ? Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: UiButton("Upgrade", height: style.heightButtonL, color: Colors.blue, icon: LineIcons.check_circle_o, textStyle: style.textButtonL, iconRight: true, onPressed: () {},),
                              )
                              : SizedBox()
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => Container(),
          itemCount: userTiers.length
        ));
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