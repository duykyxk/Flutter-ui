import 'package:beemart_app/consts/env.dart';
import 'package:beemart_app/main.dart';

void main() {
  Constants.setEnvironment(Environment.STAGING);
  mainDelegate();
}
