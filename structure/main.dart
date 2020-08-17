/*
  ****@****
  @copyright 2019 Sapo Technology JSC. All rights reserved.
  @name: Beemart-App, Flutter 
  @date: Create by Cuonghd2 on 25/6/2019
  @

*/

import 'package:beemart_app/bee_voucher/beeVoucherScreen.dart';
import 'package:beemart_app/bloc/scan_bloc.dart';
import 'package:beemart_app/checkout/chooseReceiveMethod.dart';
import 'package:beemart_app/checkout/listStoreScreen.dart';
import 'package:beemart_app/midAutumn/midAutumnScreen.dart';
import 'package:beemart_app/notifi/model/notifiProvider.dart';
import 'package:beemart_app/router.dart';
import 'package:beemart_app/scan_and_go/cart_shopping_scan_and_go.dart';
import 'package:beemart_app/scan_and_go/checkoutScanAndGo.dart';
import 'package:beemart_app/scan_and_go/checkoutShippingAddressScanAndGo.dart';
import 'package:beemart_app/scan_and_go/scan_code_screen.dart';
import 'package:beemart_app/user/couponCodeUser.dart';
import 'package:beemart_app/scan_and_go/scan_and_go_screen.dart';
import 'package:beemart_app/user/model/addressProvider.dart';
import 'package:beemart_app/user/model/infoUserProvider.dart';

import 'bloc/bloc.dart';
import 'bloc/memory.dart';
import 'cart/cartShopping.dart';
import 'cart/couponCode.dart';
import 'cart/couponCodeDetail.dart';
import 'checkout/checkout.dart';
import 'checkout/checkoutPaymentMethod.dart';
import 'checkout/checkoutShippingAddress.dart';
import 'checkout/informationPay.dart';
import 'consts/common.dart';

import 'getBlocState.dart';
import 'home/beeId/beeID.dart';
import 'home/trademarkScreen/anchor.dart';
import 'home/trademarkScreen/bobsRedMill.dart';
import 'home/trademarkScreen/Bluestone.dart';
import 'home/trademarkScreen/Chefmaster.dart';
import 'home/trademarkScreen/Puratos.dart';
import 'home/trademarkScreen/Richs.dart';
import 'home/trademarkScreen/luminarc.dart';
import 'home/trademarkScreen/markal.dart';
import 'notifi/activeNotification.dart';
import 'notifi/promotionNotiScreen.dart';
import 'notifi/updateShopScreen.dart';
import 'order/orderCanceled.dart';
import 'order/orderScreen.dart';
import 'product/detailProduct/carousel.dart';
import 'product/detailProduct/detailProductScreen.dart';
import 'product/listProducts/listProductFavorite.dart';
import 'product/listProducts/listProductSmallest.dart';
import 'search/searchScreen.dart';
import 'user/contact/contact.dart';
import 'user/faq/faqAnswerScreen.dart';
import 'user/faq/faqScreen.dart';
import 'user/infoUser/choosePlace.dart';
import 'user/infoUser/editAddressUser.dart';
import 'user/infoUser/infoUser.dart';
import 'user/infoUser/listAddressUser.dart';
import 'user/login/insertPhoneNumber.dart';
import 'user/login/loginScreen.dart';
import 'user/memberBenefit.dart';
import 'user/paymentMethod/paymentMethodScreen.dart';
import 'user/pointUser/pointUser.dart';
import 'user/policy/detailPolicyScreen.dart';
import 'user/policy/policyScreen.dart';
import 'user/support/supportUser.dart';
import 'user/terms/terms.dart';

import 'mainInit.dart';
import 'mainTab.dart';
import 'order/lineItem.dart';
import 'order/models/order.dart';
import 'order/orderStatus.dart';
import 'product/categoryProduct/categoryProduct.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class Choices {
  Choices(this.name, this.icon);
  String name;
  String icon;
}

void mainDelegate() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Crashlytics.instance.enableInDevMode = false;
  FlutterError.onError = Crashlytics.instance.recordFlutterError;
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  CommonConsts.bundleId = packageInfo.packageName;

  final navigatorKey = GlobalKey<NavigatorState>();
  Memory.prefs = await SharedPreferences.getInstance();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(
          create: (context) {
            GlobalAppBloc.set(AppBloc(Memory.loadAppState()));
            return GlobalAppBloc.get();
          },
        ),
        BlocProvider<ScanBloc>(
          create: (context) {
            GlobalAppBloc.setScanBloc(ScanBloc(Memory.loadScanCartState()));
            return GlobalAppBloc.getScanBloc();
          },
        )
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<Order>(
            create: (_) => Order(),
          ),
          ChangeNotifierProvider<NotifiProvider>(
            create: (_) => NotifiProvider(),
          ),
        ],
        child: OKToast(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            home: MainInit(),
            routes: {
              Router.CartShopping: (context) => CartShopping(),
              Router.OrderScreen: (context) => OrderScreen(),
              Router.LoginScreen: (context) => LoginScreen(),
              // '/insertNumberPhone': (context) => InsertPhoneNumber(),
              Router.ListAddress: (context) => ChangeNotifierProvider<AddressProvider>(
                    create: (_) => AddressProvider(),
                    child: ListAddress(),
                  ),
              Router.SupportUser: (context) => SupportUser(),
              Router.ContactUser: (context) => ContactUser(),
              Router.PointUser: (context) => PointUser(),
              Router.FaqScreen: (context) => FAQScreen(),
              Router.BeeID: (context) => BeeId(),
              Router.Terms: (context) => TermsAndCondition(),
              Router.MemberBenefits: (context) => MemberBenefitsBee(),
              // '/checkout': (context) => CheckoutScreen(),
              Router.CheckoutShippingAddress: (context) => ShippingAddressScreen(),
              Router.ListFavoriteProduct: (context) => ListFavoriteProduct(),
              Router.PolicyScreen: (context) => PolicyScreen(),
              Router.PaymentMethod: (context) => PaymentMethodScreen(),
              Router.OrderCanceled: (context) => OrderCanceled(),
              Router.ChooseReceiveMethod: (context) => ChooseReceiveMethodScreen(),
              // Router.ListStores: (context) => ListStoreScreen(),
              Router.MidAutumn: (context) => MidAutumnScreen(),
              Router.ScanAndGo: (context) => ScanAndGoScreen(),
              Router.ScanCode: (context) =>ScanCodeScreen(),
              Router.CartShoppingScanAndGo: (context) => CartShoppingScanAndGo(),
              Router.CheckoutShippingAddressScanAndGo: (context) => ShippingAddressScanAndGo(),
              Router.BeeVoucher: (context)=> BeeVoucherScreen()
            },
            onGenerateRoute: (settings) {
              if (settings.name == Router.Tab) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => MainTab(settings.arguments),
                );
              }
              if (settings.name == Router.CategoryProduct) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => CategoryProduct(settings.arguments),
                );
              }
              if (settings.name == Router.DetailPolicyScreen) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => DetailPolicyScreen(settings.arguments),
                );
              }
              if (settings.name == Router.InsertPhoneNumber) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => InsertPhoneNumber(settings.arguments),
                );
              }
              if (settings.name == Router.InfoUser) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => ChangeNotifierProvider<InfoUserProvider>(
                    create: (_) => InfoUserProvider(),
                    child: InfoUser(settings.arguments),
                  ),
                );
              }
              if (settings.name == Router.AcceptPay) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => InformationPay(settings.arguments),
                );
              }
              if (settings.name == Router.ChoosePlace) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => ChoosePlace(settings.arguments),
                );
              }
              if (settings.name == Router.OrderStatus) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => OrderStatus(
                    settings.arguments,
                  ),
                );
              }
              if (settings.name == Router.EditAddress) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => ChangeNotifierProvider<AddressProvider>(
                    create: (_) => AddressProvider(),
                    child: EditAddress(settings.arguments),
                  ),
                );
              }
              if (settings.name == Router.Carousel) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => CarouselProduct(
                    settings.arguments,
                  ),
                );
              }
              if (settings.name == Router.Product) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => DetailProductScreen(settings.arguments),
                );
              }
              if (settings.name == Router.SearchScreen) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => SearchScreen(paramSearching: settings.arguments),
                );
              }
              if (settings.name == Router.ListProduct) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => ListProductSmallest(settings.arguments),
                );
              }
              if (settings.name == Router.FaqAnswer) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => FAQAnswerScreen(settings.arguments),
                );
              }
              if (settings.name == Router.ActiveNoti) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => ActiveNotificationScreen(settings.arguments),
                );
              }
              if (settings.name == Router.Promotion) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => PromotionNotiScreen(settings.arguments),
                );
              }
              if (settings.name == Router.UpdateShop) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => UpdateShopScreen(settings.arguments),
                );
              }
              if (settings.name == Router.CouponCode) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => CouponCode(settings.arguments),
                );
              }
              if (settings.name == Router.CouponCodeUser) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => CouponCodeUser(settings.arguments),
                );
              }
              if (settings.name == Router.CouponDetail) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => CouponCodeDetail(settings.arguments),
                );
              }
              if (settings.name == Router.CheckoutPaymentMethod) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => ChoosePaymentMethodScreen(settings.arguments),
                );
              }
              if (settings.name == Router.Checkout) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => CheckoutScreen(settings.arguments),
                );
              }
              if (settings.name == Router.CheckoutScanAndGo) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => CheckoutScanAndGoScreen(settings.arguments),
                );
              }
              if (settings.name == Router.ListStores) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => ListStoreScreen(fromScanAndGoScreen: settings.arguments),
                );
              }
              if (settings.name == Router.TrademarkBluestone) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => Bluestone(settings.arguments),
                );
              }
              if (settings.name == Router.TrademarkPuratos) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => Puratos(settings.arguments),
                );
              }
              if (settings.name == Router.TrademarkRichs) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => Richs(settings.arguments),
                );
              }
              if (settings.name == Router.TrademarkChefmaster) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => Chefmaster(settings.arguments),
                );
              }
              if (settings.name == Router.TrademarkAnchor) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => Anchor(settings.arguments),
                );
              }
              if (settings.name == Router.TrademarkMarkal) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => Markal(settings.arguments),
                );
              }
              if (settings.name == Router.TrademarkBobsRedMill) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => BobsRedMill(settings.arguments),
                );
              }
              if (settings.name == Router.TrademarkLuminarc) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => Luminarc(settings.arguments),
                );
              }
              if (settings.name == Router.LineItem) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => LineItem(settings.arguments),
                );
              }

              return null;
            },
          ),
        ),
      ),
    ),
  );
}

class MainTabArgrument {
  MainTabArgrument({this.selectedPage});
  final dynamic selectedPage;
}
