import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'dart:developer';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription<ServiceNotificationEvent>? _subscription;
  List<ServiceNotificationEvent> events = [];
  late ScrollController controller;

  @override
  void initState() {
    controller = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Valid events are events
    var allEvents = events
        .where((element) =>
            (element.packageName?.contains('com.whatsapp') ?? false) &&
            (element.title?.trim().toLowerCase() != 'whatsapp') &&
            !(element.content
                    ?.contains(RegExp(r'^\d+ messages from \d+ chats$')) ??
                true) &&
            !(element.content?.contains(RegExp(r'^\d+ new messages$')) ?? true))
        .toList()
        .reversed;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final res = await NotificationListenerService
                            .requestPermission();
                        log("Is enabled: $res");
                      },
                      child: const Text("Request Permission"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () async {
                        final bool res = await NotificationListenerService
                            .isPermissionGranted();
                        log("Is enabled: $res");
                      },
                      child: const Text("Check Permission"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () {
                        _subscription = NotificationListenerService
                            .notificationsStream
                            .listen((event) {
                          controller.animateTo(0.0,
                              duration: const Duration(microseconds: 500),
                              curve: Curves.easeIn);
                          setState(() {
                            events.add(event);
                          });
                        });
                      },
                      child: const Text("Start Stream"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () {
                        _subscription?.cancel();
                      },
                      child: const Text("Stop Stream"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  separatorBuilder: (context, index) => const Divider(),
                  shrinkWrap: true,
                  itemCount: allEvents.length,
                  itemBuilder: (_, index) {
                    var event = allEvents.elementAt(index);
                    return ListTile(
                      onTap: () async {
                        try {
                          await event.sendReply(
                              "This is an auto response from Alfred. WIP");
                        } catch (e) {
                          log(e.toString());
                        }
                      },
                      leading: event.appIcon != null
                          ? CircleAvatar(
                              backgroundImage: MemoryImage(event.appIcon!),
                              radius: 35,
                            )
                          : event.largeIcon != null
                              ? CircleAvatar(
                                  backgroundImage:
                                      MemoryImage(event.largeIcon!),
                                  radius: 35,
                                )
                              : event.notificationIcon != null
                                  ? CircleAvatar(
                                      backgroundImage:
                                          MemoryImage(event.notificationIcon!),
                                      radius: 35,
                                    )
                                  : CircleAvatar(
                                      radius: 35,
                                      child: Text(
                                          event.title?.substring(0, 2) ??
                                              'N/A'),
                                    ),
                      title: Text(
                        event.title ?? '',
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        event.content ?? '',
                        maxLines: 1,
                      ),
                      trailing: (event.hasRemoved ?? false)
                          ? const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            )
                          : const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                    );
                    // return Padding(
                    //   padding: const EdgeInsets.only(bottom: 8.0),
                    //   child: ListTile(
                    //     onTap: () async {
                    //       // print(event);
                    //       try {
                    //         await event.sendReply(
                    //             "This is an auto response from Alfred. WIP");
                    //       } catch (e) {
                    //         log(e.toString());
                    //       }
                    //     },
                    //     trailing: event.hasRemoved!
                    //         ? const Text(
                    //             "Removed",
                    //             style: TextStyle(color: Colors.red),
                    //           )
                    //         : const SizedBox.shrink(),
                    //     leading: event.appIcon == null
                    //         ? const SizedBox.shrink()
                    //         : Image.memory(
                    //             event.appIcon!,
                    //             width: 35.0,
                    //             height: 35.0,
                    //           ),
                    //     title: Text(event.title ?? "No title"),
                    //     subtitle: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         Text(
                    //           event.content ?? "no content",
                    //           style:
                    //               const TextStyle(fontWeight: FontWeight.bold),
                    //         ),
                    //         const SizedBox(height: 8.0),
                    //         event.canReply!
                    //             ? const Text(
                    //                 "Replied with: This is an auto reply",
                    //                 style: TextStyle(color: Colors.purple),
                    //               )
                    //             : const SizedBox.shrink(),
                    //         event.largeIcon != null
                    //             ? Image.memory(
                    //                 event.largeIcon!,
                    //               )
                    //             : const SizedBox.shrink(),
                    //       ],
                    //     ),
                    //     isThreeLine: true,
                    //   ),
                    // );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
