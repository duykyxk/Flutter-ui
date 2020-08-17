import 'package:beemart_app/main.dart';
import 'package:beemart_app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';

import 'base/business/baseInsider.dart';
import 'base/components/shadow.dart';
import 'bloc/bloc.dart';
import 'bloc/scan_bloc.dart';
import 'consts/colors.dart';
import 'home/homeScreen.dart';
import 'location/models/location.dart';
import 'notifi/notifiSceen.dart';
import 'product/productScreen.dart';
import 'user/userScreen.dart';

class MainTab extends StatefulWidget {
  final MainTabArgrument _args;

  MainTab(this._args);

  @override
  State<StatefulWidget> createState() {
    return MainTabScreen(_args);
  }
}

ToastFuture toast;

class MainTabScreen extends State<MainTab> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MainTabScreen(MainTabArgrument _args) {
    _selectedPage = _args?.selectedPage ?? 0;
  }
  int _selectedPage;
  ScanBloc _scanBloc;
  @override
  initState() {
    super.initState();
    _scanBloc = BlocProvider.of<ScanBloc>(context);
  }

  _onChooseTab(int index) {
    if (index == 2) {
      _onScanBarCode();
      return;
    }
    setState(() {
      _selectedPage = index;
    });
  }

  Future<void> _onScanBarCode() async {
//    String scanResult = await scanBarCode();
//    if (scanResult == null || scanResult == "-1") return;
   Location location = _scanBloc.state?.storeLocation;
   if(location != null){
     Navigator.of(context).pushNamed(Router.ScanAndGo);
   } else{
     Navigator.of(context).pushNamed(Router.ListStores, arguments: false);
   }
  }

  static BottomNavigationBarItem _buildScanButtonBottomItem() {
    return BottomNavigationBarItem(
      backgroundColor: Colors.white,
      icon: Image.asset(
        'images/scan_and_go_bottom_button.png',
        width: 50,
        height: 50,
        fit: BoxFit.contain,
      ),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Container(),
      ),
    );
  }

  static BottomNavigationBarItem _buildBottomNavBarItem({String text, String iconImage, String iconImageActive, bool advanced = false}) {
    return BottomNavigationBarItem(
      backgroundColor: Colors.white,
      activeIcon: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image.asset(
            iconImageActive,
            color: AppColors.primary,
            width: 25,
            height: 25,
          ),
          advanced
              ? BlocBuilder<AppBloc, AppState>(
                  builder: (context, state) {
                    return state.hasUnreadNoti
                        ? Positioned(
                            top: 2,
                            right: 2,
                            child: Image.asset(
                              'images/notiNewUnread.png',
                              width: 7,
                              height: 7,
                            ),
                          )
                        : Container();
                  },
                )
              : Container(),
        ],
      ),
      icon: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image.asset(
            iconImage,
            color: AppColors.text,
            width: 25,
            height: 25,
          ),
          advanced
              ? BlocBuilder<AppBloc, AppState>(
                  builder: (context, state) {
                    return state.hasUnreadNoti
                        ? Positioned(
                            top: 2,
                            right: 2,
                            child: Image.asset(
                              'images/notiNewUnread.png',
                              width: 7,
                              height: 7,
                            ),
                          )
                        : Container();
                  },
                )
              : Container(),
        ],
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Text(text),
      ),
    );
  }

  List<BottomNavigationBarItem> _listBottombBar = [
    _buildBottomNavBarItem(
      text: 'Trang chủ',
      iconImage: 'images/icon_bottom_home.png',
      iconImageActive: 'images/icon_bottom_home_active.png',
    ),
    _buildBottomNavBarItem(
      text: 'Danh mục',
      iconImage: 'images/icon_bottom_category.png',
      iconImageActive: 'images/icon_bottom_category_active.png',
    ),
    _buildScanButtonBottomItem(),
    _buildBottomNavBarItem(
      text: 'Thông báo',
      iconImage: 'images/icon_bottom_notification.png',
      iconImageActive: 'images/icon_bottom_notification_active.png',
      advanced: true,
    ),
    _buildBottomNavBarItem(
      text: 'Cá nhân',
      iconImage: 'images/icon_bottom_user.png',
      iconImageActive: 'images/icon_bottom_user_active.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedPage != 0) {
          _onChooseTab(0);
          return false;
        }
        return true; // Exit app
      },
      child: Scaffold(
        appBar: null,
        key: _scaffoldKey,
        body: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Offstage(
              offstage: _selectedPage != 0,
              child: HomeScreenState(
                callbackOpenProductTab: () => _onChooseTab(1),
              ),
            ),
            Offstage(
              offstage: _selectedPage != 1,
              child: ProductScreen(),
            ),
            Offstage(
              offstage: _selectedPage != 3,
              child: NotifiScreen(),
            ),
            Offstage(
              offstage: _selectedPage != 4,
              child: UserScreen(shouldGetPoint: _selectedPage == 4),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: shadowTop(),
          ),
          child: BottomNavigationBar(
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.text,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12.0,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(),
            currentIndex: _selectedPage,
            onTap: (index) {
              _onChooseTab(index);
              if (index == 0) {
                BaseInsider().sendHomePageInsider();
              }
            },
            items: _listBottombBar,
          ),
        ),
      ),
    );
  }
}
