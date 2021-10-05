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
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:launch_review/launch_review.dart';
import 'package:line_icons/line_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'dashboard/home.dart';
import 'dashboard/browse.dart';
import 'dashboard/broadcast.dart';
import 'dashboard/profile.dart';
import '../utils/api.dart';
import '../utils/constants.dart';
import '../utils/models.dart';
import '../utils/providers.dart';
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
  bool? _isLocationGranted;

  var _pageIndex = 0;
  var _isLoading = false;
  var _isConnected = true;
  var _isGPSActive = true;
  var _isWillExit = false;
  var _isReady = false;

  final _listActions = [
    MenuModel(tr('action_create.listing'), 'listing', icon: LineIcons.camera, color: Colors.blue),
    MenuModel(tr('action_create.broadcast'), 'broadcast', icon: LineIcons.bullhorn, color: Colors.yellow),
  ];

  _openPage(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _pageIndex = index;
    });
    int page = (screenPageController.page ?? 0).round();
    if (page != index) {
      print("page move: $page -> $index");
      u!.navigatePage(index);
    }
  }

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
      desiredAccuracy: LocationAccuracy.high,
      distanceFilter: 3, // update tiap 3 meter
      intervalDuration: const Duration(milliseconds: LISTEN_POSITION_INTERVAL),
    ).listen((Position? position) async {
      if (position != null) {
        print("current position: $position");
        Provider.of<SettingsProvider>(context, listen: false).setSettings(
          lastLatitude: position.latitude,
          lastLongitude: position.longitude
        );
        final putLocationResult = await ApiProvider(context).api("user", method: "put", withLog: true, data: {
          'id': session!.id,
          'last_latitude': position.latitude,
          'last_longitude': position.longitude,
        });
        if (putLocationResult.isSuccess) {
          if (!_isReady) {
            setState(() {
              _isReady = true;
            });
          }
          u!.loadNotif();
        }
      } else {
        print("cannot get current position");
      }
    });
  }

  _checkLocationPermission() async {
    setState(() {
      _isLocationGranted = null;
    });
    final Position? position = await l.checkGPS();
    setState(() {
      _isLocationGranted = position is Position;
    });
    if (_isLocationGranted!) {
      _runListeners();
    }
  }

  _runListeners() {
    _listenGPSStatus();
    _listenPosition();
    _listenNotification();
    _listenConnection();
  }

  _create(String what) async {
    final resultList = await u?.browsePicture(maximum: SETUP_MAX_LISTING_IMAGES) ?? [];
    if (resultList.isNotEmpty) {
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
        case 'action_create_listing':
          _create('listing');
          break;
        case 'action_create_broadcast':
          _create('broadcast');
          break;
      }
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'action_create_listing',
        localizedTitle: tr('action_create.listing'),
        icon: 'ic_webcam',
      ),
      ShortcutItem(
        type: 'action_create_broadcast',
        localizedTitle: tr('action_create.broadcast'),
        icon: 'ic_notepad',
      ),
    ]);

    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
      });

      // check position permission
      _checkLocationPermission();
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
    if (_isLocationGranted == null) return const MyLoader();

    // permission lokasi belum diizinkan
    if (!_isLocationGranted!) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: MyPlaceholder(
            content: ContentModel(
              title: "Izin Dibutuhkan",
              description: "Harap izinkan aplikasi untuk mengakses lokasi Anda saat ini.",
            ),
            retryLabel: "Izinkan",
            onRetry: _checkLocationPermission,
          ),
        ),
      );
    }

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

    final _listPages = <PageModel>[
      PageModel(title: tr('menu_bottom.home'), icon: LineIcons.home, content: HomePage(key: Key("HomePage$_isReady"), isOpen: _pageIndex == TAB_HOME,),),
      PageModel(title: tr('menu_bottom.browse'), icon: LineIcons.search, content: BrowsePage(isOpen: _pageIndex == TAB_BROWSE,),), // favorit, featured ad, last viewed
      PageModel(title: tr('menu_bottom.broadcast'), icon: LineIcons.bullhorn, content: BroadcastPage(isOpen: _pageIndex == TAB_BROADCAST,),),
      PageModel(title: tr('menu_bottom.profile'), icon: LineIcons.user, content: ProfilePage(isOpen: _pageIndex == TAB_PROFILE,),),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (screenScaffoldKey.currentState?.isEndDrawerOpen ?? false) return true;
        if ((screenPageController.page ?? 0).round() > 0) {
          _openPage(0);
          return false;
        }
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
                        menus: [
                          MenuModel("Feedback", "feedback", icon: LineIcons.comments, onPressed: () {
                            LaunchReview.launch();
                          }),
                          MenuModel("Keluar", "logout", icon: LineIcons.alternateSignOut, onPressed: () {
                            u?.logout();
                          }),
                        ],
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
          child: PreloadPageView.builder(
            preloadPagesCount: 2,
            controller: screenPageController,
            itemCount: _listPages.length,
            itemBuilder: (context, index) => _listPages[index].content,
            onPageChanged: _openPage,
          ),
        ),
        bottomNavigationBar: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(blurRadius: 20, color: Colors.grey[800]!.withOpacity(0.5))]
              ),
              padding: const EdgeInsets.all(8.0),
              child: GNav(
                gap: 8,
                iconSize: 24,
                activeColor: Colors.white,
                color: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                duration: const Duration(milliseconds: 500),
                tabBackgroundColor: APP_UI_COLOR_ACCENT,
                tabs: _listPages.map((page) => GButton(icon: page.icon, text: page.title)).toList(),
                selectedIndex: _pageIndex,
                onTabChange: (index) => _openPage(index),
              ),
            ),
            // Transform.translate(
            //   offset: const Offset(35, -45),
            //   child: AnimatedOpacity(
            //     opacity: _isPopNotif ? 1 : 0,
            //     duration: const Duration(milliseconds: 1000),
            //     child: const MyTooltip(label: "2 Baru",),
            //   ),
            // ),
          ],
        ),
        floatingActionButton: AnimatedSwitcher(
          duration: const Duration(milliseconds: 1000),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.linear,
          // transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(child: child, scale: animation,),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final  offsetAnimation = Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(animation);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          child: _pageIndex > 0 ? const SizedBox() : MyFabCircular(
            LineIcons.plus,
            _listActions,
            _create,
            getSize: (i) => 48.0 - 6 * i,
            getOffset: (i) {
              double x = 0.0, y = 0.0;
              if (i == 1) {
                x = -25;
                y = 8;
              }
              return Offset(x, y);
            },
          ),
        ),
      ),
    );
  }
}

class DashboardNavMenu extends StatelessWidget {
  const DashboardNavMenu({ required this.menus, this.active, Key? key }) : super(key: key);
  final List<MenuModel> menus;
  final int? active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: menus.asMap().map((index, menu) {
        return MapEntry(index, MyMenuList(
          isFirst: index == 0,
          isLast: index == menus.length - 1,
          isActive: index == active,
          menu: menu,
          menuPaddingHorizontal: 24,
          menuPaddingVertical: 20,
        ));
      }).values.toList(),
    );
  }
}