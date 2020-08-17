import 'dart:async';
import 'package:blife/blocs/authen_bloc.dart';
import 'package:blife/model/beans/user/MemberData.dart';
import 'package:blife/model/remote/utils/api_response.dart';
import 'package:blife/utils/app_constant.dart';
import 'package:blife/views/home/model/post_feed.dart';
import 'package:blife/views/main/main_view.dart';
import 'package:blife/widget/notification_global.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:blife/utils/color_utils.dart';
import 'package:blife/views/user/signin_account_view.dart';
import 'package:blife/views/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
    if (message.containsKey('notification')) {
      // Handle notification message
      final notification = message['notification'] as Map<dynamic,dynamic>;
      if(notification.containsKey('title') && notification.containsKey('body')){
        handleShowNotification(notification['title'] as String,notification['body'] as String);
      }
    }
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }
  // Or do other work.
}

NotificationAppLaunchDetails notificationAppLaunchDetails;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var appDocDirectory = await getApplicationDocumentsDirectory();
  Hive
    ..init(appDocDirectory.path);
//  init notification
  await Hive.openBox(AppConstants.HIVE_USER_BOX);
  await Hive.openBox(AppConstants.HIVE_HOME_FEED);
  notificationAppLaunchDetails =
  await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  var initializationSettingsAndroid = AndroidInitializationSettings('mipmap/ic_launcher');
  // Note: permissions aren't requested here just to demonstrate that can be done later using the `requestPermissions()` method
  // of the `IOSFlutterLocalNotificationsPlugin` class
  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:null);
  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final authenBloc = AuthenBloc();
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: ColorUtils.MAIN_GRADIENT_1
    ));

    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        if (message.containsKey('notification')) {
          // Handle notification message
          final notification = message['notification'] as Map<dynamic, dynamic>;
          if (notification.containsKey('title') &&
              notification.containsKey('body')) {
            handleShowNotification(notification['title'] as String,
                notification['body'] as String);
          }
        }
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        if (message.containsKey('notification')) {
          // Handle notification message
          final notification = message['notification'] as Map<dynamic, dynamic>;
          if (notification.containsKey('title') &&
              notification.containsKey('body')) {
            handleShowNotification(notification['title'] as String,
                notification['body'] as String);
          }
        }
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        if (message.containsKey('notification')) {
          // Handle notification message
          final notification = message['notification'] as Map<dynamic, dynamic>;
          if (notification.containsKey('title') &&
              notification.containsKey('body')) {
            handleShowNotification(notification['title'] as String,
                notification['body'] as String);
          }
        }
      },
    );

    firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });

    authenBloc.loadData();
    return MaterialApp(
      title: 'Belife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'SFUIText'),
      builder: (BuildContext context, Widget child) {
        final data = MediaQuery.of(context).copyWith(textScaleFactor: 1.0);
        return MediaQuery(data: data, child: child);
      },
      home: StreamBuilder<ApiResponse<MemberData>>(
        stream: authenBloc.subjectAuthenData.stream,
        builder: (context, snapshot) {
          final response = snapshot.data;
          if (response != null && response.status == Status.SUCCESS) {
            authenBloc.disposeAuthenDataSubject();
            if(response.data != null) {
              return MainView();
            }
            return SigninAccountView();
          }
          return SplashView();
        },
      ),
    );
  }
}
final userBox = Hive.box(AppConstants.HIVE_USER_BOX);
