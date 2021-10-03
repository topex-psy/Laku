import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:launch_review/launch_review.dart';
import 'package:line_icons/line_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quick_actions/quick_actions.dart';
import '../utils/constants.dart';
import '../utils/models.dart';
import '../utils/variables.dart';
import '../utils/widgets.dart';

const MENU_DRAWER_PADDING = 20.0;
const MENU_DRAWER_RADIUS = 20.0;
const MENU_DRAWER_WIDTH = 0.8;
const LISTEN_POSITION_INTERVAL = 10000;

class DashboardPage extends StatefulWidget {
  const DashboardPage(this.analytics, this.args, {Key? key}) : super(key: key);
  final FirebaseAnalytics analytics;
  final Map<String, dynamic> args;

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  StreamSubscription<Position>? _listenerPosition;
  StreamSubscription<ConnectivityResult>? _listenerConnection;
  StreamSubscription<ServiceStatus>? _listenerGPSStatus;
  String? _loadingText;
  String? _version;

  var _isLoading = false;
  var _isConnected = true;
  var _isGPSActive = true;
  var _isWillExit = false;

  _listenConnection() {
    _listenerConnection = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      bool isConnected = result != ConnectivityResult.none;
      if (_isConnected != isConnected) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  _listenNotification() async {
    // create high importance channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      'This channel is used for important notifications.', // description
      importance: Importance.max,
    );
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

    // notification handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('push notif got a message whilst in the foreground!');
      print('push notif data: ${message.data}');
      print('push notif notification: ${message.notification}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If `onMessage` is triggered with a notification, construct our own
      // local notification to show to users using the created channel.
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channel.description,
              icon: android.smallIcon,
              // other properties...
            ),
          )
        );
      }
    });
  }

  _listenGPSStatus() {
    _listenerGPSStatus = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      bool isGPSActive = status == ServiceStatus.enabled;
      if (_isGPSActive != isGPSActive) {
        setState(() {
          _isGPSActive = isGPSActive;
        });
      }
    });
  }

  _listenPosition() {
    _listenerPosition = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // update tiap 5 meter
      intervalDuration: const Duration(milliseconds: LISTEN_POSITION_INTERVAL),
    ).listen((Position? position) {
      if (position != null) {
        print("current position: $position");
        _getAllData();
      } else {
        print("cannot get current position");
      }
    });
  }

  _getAllData() {
    // TODO get listing data
  }

  _create() async {
    final resultList = await u?.browsePicture(maximum: SETUP_MAX_LISTING_IMAGES) ?? [];
    if (mounted && resultList.isNotEmpty) {
      // TODO send resultList to create page
      final createResult = await Navigator.pushNamed(context, ROUTE_CREATE);
      print("createResult: $createResult");
    }
  }

  @override
  void initState() {
    super.initState();

    // launcher shortcuts
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((shortcutType) {
      switch (shortcutType) {
        case 'action_create':
          _create();
          break;
      }
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'action_create',
        localizedTitle: tr('action_create_listing'),
        icon: 'ic_webcam',
      ),
    ]);

    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
      });

      // check position permission
      final Position? position = await l.checkGPS();
      if (position is Position) {
        _listenGPSStatus();
        _listenPosition();
        _listenNotification();
        _listenConnection();
      } else {
        u?.logout();
      }
    });
  }

  @override
  void dispose() {
    _listenerPosition?.cancel();
    _listenerConnection?.cancel();
    _listenerGPSStatus?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget noConnection(String type) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: MyPlaceholder(
            retryLabel: type == "gps" ? "Pengaturan" : "Coba Lagi",
            onRetry: () async {
              if (type == "gps") await Geolocator.openLocationSettings();
              _listenerConnection?.pause();
              _listenerGPSStatus?.pause();
              setState(() {
                _isLoading = true;
                _loadingText = "Mencari koneksi";
              });
              Future.delayed(const Duration(milliseconds: 1000), () {
                _listenerConnection?.resume();
                _listenerGPSStatus?.resume();
                setState(() {
                  _isLoading = false;
                  _loadingText = null;
                });
              });
            },
            content: ContentModel(
              title: type == "internet" ? "Gagal Terhubung!" : "GPS Tidak Aktif!",
              description: type == "internet" ? "Mohon periksa jaringan internet Anda." : "Mohon aktifkan GPS untuk dapat menggunakan aplikasi.",
              image: "assets/images/no-network.png",
            ),
          ),
        ),
      );
    }

    // sedang memuat
    if (_isLoading) return MyLoader(message: _loadingText,);

    // internet putus
    if (!_isConnected) return noConnection("internet");

    // gps tidak aktif
    if (!_isGPSActive) return noConnection("gps");

    return WillPopScope(
      onWillPop: () async {
        if (screenScaffoldKey.currentState?.isEndDrawerOpen ?? false) return true;
        if (_isWillExit) {
          SystemChannels.platform.invokeMethod<bool>('SystemNavigator.pop');
          return true;
        }
        _isWillExit = true;
        h!.showToast("Tekan sekali lagi untuk menutup aplikasi.");
        Future.delayed(const Duration(milliseconds: 2000), () { _isWillExit = false; });
        return false;
      },
      child: Scaffold(
        key: screenScaffoldKey,
        resizeToAvoidBottomInset: true,
        drawerEdgeDragWidth: 20,
        endDrawer: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: MENU_DRAWER_PADDING),
            child: Container(
              width: MediaQuery.of(context).size.width * MENU_DRAWER_WIDTH,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(MENU_DRAWER_RADIUS),
                  bottomLeft: Radius.circular(MENU_DRAWER_RADIUS),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 25)
                ]
              ),
              clipBehavior: Clip.antiAlias,
              child: Drawer(
                semanticLabel: "Side menu",
                child: Container(
                  // color: MENU_DRAWER_BACKGROUND,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // TODO konten sidebar
                      // ProfileCard(avatarSize: 50,),
                      // SizedBox(height: 20,),
                      DashboardNavMenu(
                        onPressed: (menu) async {
                          print("menu pressed: ${menu.value}");
                          Navigator.of(context).pop();
                          switch (menu.value) {
                            case "feedback":
                              LaunchReview.launch();
                              break;
                            case "logout":
                              u?.logout();
                              break;
                          }
                        },
                      ),
                      const SizedBox(height: 40,),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: Row(
                          children: [
                            const MyAppLogo(size: 35, type: MyLogoType.logo),
                            const SizedBox(width: 8,),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(APP_NAME, style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4,),
                                Text(_version == null ? "" : "Ver $_version", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [

            ],),
          ),
        ),
      ),
    );
  }
}

class DashboardNavMenu extends StatelessWidget {
  const DashboardNavMenu({ required this.onPressed, this.active, Key? key }) : super(key: key);
  final void Function(MenuModel) onPressed;
  final int? active;

  @override
  Widget build(BuildContext context) {
    final _menu = <MenuModel>[
      MenuModel("Feedback", "feedback", icon: LineIcons.comments),
      MenuModel("Keluar", "logout", icon: LineIcons.alternateSignOut),
    ];
    return Column(
      children: _menu.asMap().map((index, menu) {
        return MapEntry(index, MyMenuList(
          isFirst: index == 0,
          isLast: index == _menu.length - 1,
          isActive: index == active,
          menu: menu,
          menuPaddingHorizontal: 24,
          menuPaddingVertical: 20,
          onPressed: onPressed,
        ));
      }).values.toList(),
    );
  }
}