import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Contribute extends StatefulWidget {
  const Contribute({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContributeState();
}

class _ContributeState extends State<Contribute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: const Text('آوای گنجور')),
        body: Builder(
            builder: (context) => Container(
                decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                child: Align(
                    alignment: Alignment.topRight,
                    child: Column(children: [
                      Expanded(
                        child: Text(
                          'شرایط انتشار خوانش اشعار در گنجور به شرح زیر است:\r\n' '۱. فایل صوتی شعر می‌بایست در قالب mp3 تهیه شده باشد.\r\n' '۲. می‌بایست با گنجور رومیزی متن شعر را با فایل صوتی همگام کنید و از آن خروجی xml بگیرید.\r\n' 
                              '۳. از طریق پیشخان خوانشگران گنجور فایلهای mp3 و xml را ارسال کنید.\r\n',
                          style: Theme.of(context).primaryTextTheme.titleLarge,
                        ),
                      ),
                      Center(
                          child: ElevatedButton(
                        child: const Text(
                            'برای مطالعهٔ کامل دستورالعمل مشارکت اینجا را ببینید'),
                        onPressed: () async {
                          var url = 'http://ava.ganjoor.net/about/';
                          if (await canLaunchUrlString(url)) {
                            await launchUrlString(url);
                          } else {
                            throw 'خطا در نمایش نشانی $url';
                          }
                        },
                      )),
                    ])))));
  }
}
