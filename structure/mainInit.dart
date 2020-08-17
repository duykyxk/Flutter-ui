import 'dart:convert';
import 'dart:io';

import 'package:beemart_app/bloc/scan_bloc.dart';
import 'package:beemart_app/consts/env.dart';
import 'package:beemart_app/region/model/region.dart';
import 'package:beemart_app/region/service/apiRegion.dart';
import 'package:beemart_app/router.dart';
import 'package:beemart_app/user/model/infomationUser.dart';
import 'package:beemart_app/utils/apnsUtils.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_insider/enum/InsiderCallbackAction.dart';
import 'package:flutter_insider/flutter_insider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/scheduler.dart' as Scheduler;
import 'package:oktoast/oktoast.dart';
import 'package:package_info/package_info.dart';
import 'base/business/routerDirect.dart';
import 'base/business/validator.dart';
import 'base/components/notificationHandler.dart';
import 'base/components/popupChooseRegion.dart';
import 'base/components/showToast.dart';
import 'bloc/app_bloc.dart';
import 'bloc/bloc.dart';
import 'consts/colors.dart';
import 'main.dart';
import 'mainTab.dart';
import 'notifi/model/notificationData.dart';
import 'services/banner/bannerImages.dart';
import 'user/service/apiLoyaltieService.dart';
import 'utils/launchOtherAppUtils.dart';

class MainInit extends StatefulWidget {
  MainInit({Key key}) : super(key: key);

  @override
  _MainInitState createState() => _MainInitState();
}

class _MainInitState extends State<MainInit> {
  final _firebaseMessaging = FirebaseMessaging();
  final _apnsUtils = ApnsUtils();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AppBloc _bloc;
  ScanBloc _scanBloc;

  @override
  void initState() {
    super.initState();

    _bloc = BlocProvider.of<AppBloc>(context);
    _scanBloc = BlocProvider.of<ScanBloc>(context);

    _bloc.add(SyncCartWhenOpenApp(bloc: _scanBloc));
    _bloc.add(UpdateRegion());

    Scheduler.SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_bloc.state.isLoginSuccess &&
          _bloc.state.userLogin?.accountUser?.name == null) {
        _editInfoUserWhenNull();
      }
    });

    _initInsider();
    _getBannerImages();
    _checkOutOfDateJWT();
    _checkConnectInternet();
    _getListRegion();
    if (Constants.environment == Environment.PROD) _initRemoteConfig(context);

    // CONFIG NOTI IOS
    _apnsUtils.config(onToken: (token) async {
      if (Platform.isIOS) {
        _updateDeviceInfoIfNeeded(token);
      }
    }, onMessage: (message) async {
      if (message['source'] == 'Insider') {
        onSelectNotificationInsider(message['contentScreen'],
            int.parse(message['value'] ?? '0'), context);
      } else {
        NotificationDataIOS noti;
        try {
          noti = NotificationDataIOS.fromJson(message);
        } catch (e) {
        }
        onSelectNotification(noti.data, context);
      }
    });

    _apnsUtils.requestNotificationPermissions().then((granted) {
    });

    _firebaseMessaging.getToken().then((token) {
      if (Platform.isAndroid) {
        _updateDeviceInfoIfNeeded(token);
      }
    });

    // CONFIG NOTI ANDROID
    var android =
        AndroidInitializationSettings('@drawable/beemart_notification');
    var initSetting = InitializationSettings(android, null);
    flutterLocalNotificationsPlugin.initialize(
      initSetting,
      onSelectNotification: (payload) => onSelectNotification(payload, context),
    );
    if (!Constants.isFirebaseConfigured) {
      Constants.isFirebaseConfigured = true;
      _firebaseMessaging.configure(
        onMessage: (message) async {
          // NotifiProvider().checkHasUnreadNoti();
          // khi đang trong app nhận noti phải get lại noti
          var android = AndroidNotificationDetails(
            "notifiBeemart",
            "Thông báo Beemart",
            "Thông báo của Beemart đến người dùng",
            importance: Importance(5),
            priority: Priority(2),
            style: AndroidNotificationStyle.Default,
          );

          // var key = message['data'];
          String source = message['data']['source'];

          if (source != null && source == 'Insider') {
            // noti của insider
            Map<String, dynamic> mapData = {
              'content_screen': message['data']['contentScreen'],
              'content_id': message['data']['value']
            };
            await flutterLocalNotificationsPlugin.show(
              0,
              message['data']['title'],
              message['data']['message'],
              NotificationDetails(android, null),
              payload: json.encode(mapData),
            );
          } else {
            // noti của core sapo
            NotificationMessage noti;
            noti = NotificationMessage.fromJson(message);
            await flutterLocalNotificationsPlugin.show(
              0,
              noti.data.titleLocKey,
              noti.data.bodyLocKey,
              NotificationDetails(android, null),
              payload: noti.data.data,
            );
          }
        },
        onResume: (Map<String, dynamic> message) async {
          NotificationMessage noti;
          try {
            noti = NotificationMessage.fromJson(message);
          } catch (e) {
          }
          onSelectNotification(noti.data.data, context);
        },
        onLaunch: (Map<String, dynamic> message) async {
          NotificationMessage noti;
          try {
            noti = NotificationMessage.fromJson(message);
          } catch (e) {
          }
          onSelectNotification(noti.data.data, context);
        },
      );
    }
    _firebaseMessaging.requestNotificationPermissions();

    if (_bloc.state.isLoginSuccess && _bloc.state.isUserInfoNeeded) {
      _bloc.add(SendInfoUserInsider());
    }
  }

  // var _platformVersion;
  Future<void> _initInsider() async {
    if (!mounted) return;
    await FlutterInsider.Instance.init(
      "beemartvn",
      "group.com.beemart.insider.notifications",
      (int type, dynamic data) {
        switch (type) {
          case InsiderCallbackAction.NOTIFICATION_OPEN:
            break;
          case InsiderCallbackAction.INAPP_BUTTON_CLICK:
            // contentScreen => dẫn đến 1 màn nào đó
            // param => dữ liệu truyền đến màn đó, ví dụ mã coupon, mã hay danh mục
            RouterDirect.routerDirect(
              data['contentScreen'],
              context,
              int.parse(data['value'] ?? '0'),
              _bloc.state.isLoginSuccess,
              _bloc.state.userLogin?.accountUser ?? AccountUser(),
            );
            break;
          case InsiderCallbackAction.TEMP_STORE_PURCHASE:
            break;
          case InsiderCallbackAction.TEMP_STORE_ADDED_TO_CART:
            break;
          case InsiderCallbackAction.TEMP_STORE_CUSTOM_ACTION:
            break;
          default:
            break;
        }
      },
    );

    // This is an utility method, if you want to handle the push permission in iOS own your own you can omit the following method.
    FlutterInsider.Instance.registerWithQuietPermission(false);
  }

  _updateDeviceInfoIfNeeded(String token) {
    if (token == _bloc.state.tokenNotifi) return;
    _bloc.add(AddTokenNotifi(token));
    if (!_bloc.state.isLoginSuccess) return;
    NotificationHandler.updateDeviceInfo(
      _bloc.state.userLogin.accountUser.id,
      token,
    );
  }

  _checkOutOfDateJWT() {
    if (_bloc.state.isLoginSuccess) {
      ApiLoyaltieService().getLoyaltieService().then(
        (response) {
          if (response.data != null &&
              response.data != _bloc.state.availablePoint) {
            _bloc.add(AvailablePoint(availablePoint: response.data));
          } else if (response.statusCode == 403) {
            _bloc.add(LogOut());
            _scanBloc.add(LogOutScanAndGo());
            showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: new Text("Thông báo"),
                  content: new Text(
                    "Phiên đăng nhập của bạn đã hết hạn. Vui lòng đăng nhập lại để tiếp tục mua hàng.",
                  ),
                );
              },
            );
          }
        },
      );
    }
  }

  _getListRegion() {
    // lấy lại danh sách khu vực đề phòng có sự thay đổi
    ApiRegion().getListRegion().then((response) {
      if (response.statusCode == 200) {
        if (_bloc.state.isLoginSuccess && _bloc.state.region != null) {
          // id của region thì cố định nhưng list location trong region có thể thay đổi nên cần cập nhật lại region lưu trong máy
          Region newRegion = response.data.items
              .singleWhere((item) => item.id == _bloc.state.region.id);
          _bloc.add(UpdateRegion(region: newRegion));
        }
        if (!_bloc.state.isLoginSuccess || _bloc.state.region == null) {
          Region northRegion = response.data.items.singleWhere((item) => item.id == ApiRegion.idNorthernRegion);
          _bloc.add(UpdateRegion(region: northRegion));
          // nếu chưa đăng nhập hoặc chưa từng chọn khu vực nào thì hiện popup chọn khu vực
          showPopupChooseRegion(context);
        }
      }
    });
  }

  _editInfoUserWhenNull() {
    // chỗ này xử lý login nhưng tên null
    Navigator.of(context)
        .pushNamed(Router.InfoUser, arguments: _bloc.state.userLogin.accountUser)
        .then((onValue) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        Router.Tab,
        (Route<dynamic> route) => false,
        arguments: MainTabArgrument(
          selectedPage: 3,
        ),
      );
      if (_bloc.state.region == null) {
        showPopupChooseRegion(context);
      } else {
        _bloc.add(UpdateRegion());
      }
    });
  }

  _getBannerImages() {
    BannerImage().getBannerImage(limit: 5, page: 1).then((result) {
      if (result.statusCode == 200) {
        _bloc.add(AddListBanner(result.data.items));
      }
    });
  }

  onSelectNotification(String payload, BuildContext context) {
    // chỗ này đang nhảy vào 2 lần bật 2 màn hình noti lên
    Map valueMap = json.decode(payload);
    String contentScreen = valueMap["content_screen"];
    String contentId = valueMap["content_id"] ?? '0';
    // đây là id của noti bắn về, cần truyền sang màn contentScreen để gọi api see noti
    // nhưng hiện tại bên core chưa hỗ trợ trả về id này nên nó sẽ null
    // => hiện tại chưa làm đc tình huống click vào noti bắn về và see noti luôn
    // int notiId = valueMap["id"];
    RouterDirect.routerDirect(
      contentScreen,
      context,
      int.parse(contentId),
      _bloc.state.isLoginSuccess,
      _bloc.state.userLogin?.accountUser ?? AccountUser(),
    );
  }

  onSelectNotificationInsider(
    // van de khi đăng nhập moi vao dc noti
    String contentScreen,
    int contentId,
    BuildContext context,
  ) {
    RouterDirect.routerDirect(
      contentScreen,
      context,
      contentId,
      _bloc.state.isLoginSuccess,
      _bloc.state.userLogin?.accountUser ?? AccountUser(),
    );
  }

  _initRemoteConfig(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    final defaults = <String, dynamic>{'version': '2.4.9', 'constraint': false};
    await remoteConfig.setDefaults(defaults);
    await remoteConfig.fetch(expiration: Duration(hours: 1));
    await remoteConfig.activateFetched();
    if (Validator.compareVersion(packageInfo.version ?? '', (remoteConfig.getString('version') ?? ''))) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text("Thông báo"),
            content: Text("Đã có phiên bản mới nhất. Nhấn cập nhật để tải về."),
            actions: <Widget>[
              FlatButton(
                textColor: AppColors.destructive,
                child: Text("CẬP NHẬT"),
                onPressed: () {
                  // Navigator.of(context).pop();
                  // dẫn đến google play hoặc appstore để cập nhật
                  LaunchOtherAppUtils().openStore();
                },
              ),
              remoteConfig.getBool('constraint')
                  ? Container()
                  : FlatButton(
                      child: Text("HỦY"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  _checkConnectInternet() async {
    // có 2 cách để check sự kiện kết nối internet. cách 1 an toàn hơn, cách 2 có thể lỗi get response từ google sinh ra lỗi

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        _bloc.add(DisConnectedInternet());
      } else {
        _bloc.add(ConnectedInternet());
      }
    });
    // Connectivity()
    //     .onConnectivityChanged
    //     .listen((ConnectivityResult connectResult) async {
    //   try {
    //     final result = await InternetAddress.lookup('google.com');
    //     if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
    //       _bloc.add(ConnectedInternet());
    //     } else {
    //       _bloc.add(DisConnectedInternet());
    //     }
    //   } on SocketException catch (_) {
    //     _bloc.add(DisConnectedInternet());
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          MainTab(
            MainTabArgrument(
              selectedPage: 0,
            ),
          ),
          BlocListener<AppBloc, AppState>(
            listener: (context, state) {
              if (state.isDisConnectInternet) {
                toast = showToastWidget(
                  showToastConnectionInternet(
                      'Không có kết nối Internet.', Icons.error),
                  duration: Duration(seconds: 5),
                  dismissOtherToast: true,
                );
              } else {
                toast?.dismiss();
              }
            },
            child: Container(),
          )
        ],
      ),
    );
  }
}
