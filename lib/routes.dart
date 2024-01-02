import 'package:ava/main.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

class Routes {
  static final Handler _homehandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
    return const MyHomePage();
  });

  static final Handler _viewHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
    int id = int.parse(params['id']?.first);
    return MyHomePage(id: id);
  });

  static void configureRoutes(FluroRouter router) {
    router.define('/', handler: _homehandler);
    router.define('/:id', handler: _viewHandler);
  }
}
