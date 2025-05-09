import 'dart:convert';
import 'dart:io';

import 'package:delivery_delivery/features/auth/controllers/auth_controller.dart';
import 'package:delivery_delivery/features/chat/controllers/chat_controller.dart';
import 'package:delivery_delivery/features/notification/controllers/notification_controller.dart';
import 'package:delivery_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:delivery_delivery/features/order/controllers/order_controller.dart';
import 'package:delivery_delivery/helper/route_helper.dart';
import 'package:delivery_delivery/util/app_constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationHelper {
  static Future<void> initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidInitialize =
        const AndroidInitializationSettings('notification_icon');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .requestNotificationsPermission();
    flutterLocalNotificationsPlugin.initialize(initializationsSettings,
        onDidReceiveNotificationResponse: (load) async {
      try {
        if (load.payload!.isNotEmpty) {
          NotificationBodyModel payload =
              NotificationBodyModel.fromJson(jsonDecode(load.payload!));

          if (payload.notificationType == NotificationType.order) {
            Get.offAllNamed(RouteHelper.getOrderDetailsRoute(payload.orderId,
                fromNotification: true));
          } else if (payload.notificationType ==
              NotificationType.order_request) {
            Get.toNamed(RouteHelper.getMainRoute('order-request'));
          } else if (payload.notificationType == NotificationType.general) {
            Get.offAllNamed(
                RouteHelper.getNotificationRoute(fromNotification: true));
          } else {
            Get.offAllNamed(RouteHelper.getChatRoute(
                notificationBody: payload,
                conversationId: payload.conversationId,
                fromNotification: true));
          }
        }
      } catch (_) {}
      return;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
            "onMessage: ${message.notification!.title}/${message.notification!.body}/${message.notification!.titleLocKey}");
        print("onMessage message type:${message.data['type']}");
        print("onMessage message:${message.data}");
      }

      if (message.data['type'] == 'message' &&
          Get.currentRoute.startsWith(RouteHelper.chatScreen)) {
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
          if (Get.find<ChatController>()
                  .messageModel!
                  .conversation!
                  .id
                  .toString() ==
              message.data['conversation_id'].toString()) {
            Get.find<ChatController>().getMessages(
              1,
              NotificationBodyModel(
                notificationType: NotificationType.message,
                customerId:
                    message.data['sender_type'] == AppConstants.user ? 0 : null,
                vendorId: message.data['sender_type'] == AppConstants.vendor
                    ? 0
                    : null,
              ),
              null,
              int.parse(message.data['conversation_id'].toString()),
            );
          } else if (message.data['type'] != 'incoming_call' &&
              message.data['type'] != 'call_ended') {
            NotificationHelper.showNotification(
                message, flutterLocalNotificationsPlugin);
          }
        }
      } else if (message.data['type'] == 'message' &&
          Get.currentRoute.startsWith(RouteHelper.conversationListScreen)) {
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
        }
        NotificationHelper.showNotification(
            message, flutterLocalNotificationsPlugin);
      } else if (message.data['type'] != 'incoming_call' &&
          message.data['type'] != 'call_ended') {
        String? type = message.data['type'];

        if (type != 'assign' &&
            type != 'new_order' &&
            type != 'order_request') {
          NotificationHelper.showNotification(
              message, flutterLocalNotificationsPlugin);
          Get.find<OrderController>().getCurrentOrders();
          Get.find<OrderController>().getLatestOrders();
          Get.find<NotificationController>().getNotificationList();
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
            "onOpenApp: ${message.notification!.title}/${message.notification!.body}/${message.notification!.titleLocKey}");
        print("onOpenApp message type:${message.data['type']}");
      }
      try {
        if (message.data.isNotEmpty) {
          NotificationBodyModel notificationBody =
              convertNotification(message.data)!;

          if (notificationBody.notificationType == NotificationType.order) {
            Get.toNamed(RouteHelper.getOrderDetailsRoute(
                int.parse(message.data['order_id'])));
          } else if (notificationBody.notificationType ==
              NotificationType.order_request) {
            Get.toNamed(RouteHelper.getMainRoute('order-request'));
          } else if (notificationBody.notificationType ==
              NotificationType.general) {
            Get.toNamed(RouteHelper.getNotificationRoute());
          } else if (message.data['type'] != 'incoming_call' &&
              message.data['type'] != 'call_ended') {
            Get.toNamed(RouteHelper.getChatRoute(
                notificationBody: notificationBody,
                conversationId: notificationBody.conversationId));
          }
        }
      } catch (_) {}
    });
  }

  static Future<void> showNotification(
      RemoteMessage message, FlutterLocalNotificationsPlugin fln) async {
    if (!GetPlatform.isIOS) {
      String? title;
      String? body;
      String? image;
      NotificationBodyModel? notificationBody;

      title = message.notification!.title;
      body = message.notification!.body;
      notificationBody = convertNotification(message.data);

      if (GetPlatform.isAndroid) {
        image = (message.notification!.android!.imageUrl != null &&
                message.notification!.android!.imageUrl!.isNotEmpty)
            ? message.notification!.android!.imageUrl!.startsWith('http')
                ? message.notification!.android!.imageUrl
                : '${AppConstants.baseUrl}/storage/app/public/notification/${message.notification!.android!.imageUrl}'
            : null;
      } else if (GetPlatform.isIOS) {
        image = (message.notification!.apple!.imageUrl != null &&
                message.notification!.apple!.imageUrl!.isNotEmpty)
            ? message.notification!.apple!.imageUrl!.startsWith('http')
                ? message.notification!.apple!.imageUrl
                : '${AppConstants.baseUrl}/storage/app/public/notification/${message.notification!.apple!.imageUrl}'
            : null;
      }

      if (image != null &&
          image
              .isNotEmpty /*&& _notificationBody.notificationType != NotificationType.message*/) {
        try {
          await showBigPictureNotificationHiddenLargeIcon(
              title, body, notificationBody, image, fln);
        } catch (e) {
          await showBigTextNotification(title, body!, notificationBody, fln);
        }
      } else {
        await showBigTextNotification(title, body!, notificationBody, fln);
      }
    }
  }

  static Future<void> showTextNotification(
      String title,
      String body,
      NotificationBodyModel notificationBody,
      FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '6ammart',
      '6ammart',
      playSound: true,
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('notification'),
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: jsonEncode(notificationBody.toJson()));
  }

  static Future<void> showBigTextNotification(
      String? title,
      String body,
      NotificationBodyModel? notificationBody,
      FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '6ammart',
      '6ammart',
      importance: Importance.max,
      styleInformation: bigTextStyleInformation,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null
            ? jsonEncode(notificationBody.toJson())
            : null);
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(
      String? title,
      String? body,
      NotificationBodyModel? notificationBody,
      String image,
      FlutterLocalNotificationsPlugin fln) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath =
        await _downloadAndSaveFile(image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: body,
      htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '6ammart',
      '6ammart',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      priority: Priority.max,
      playSound: true,
      styleInformation: bigPictureStyleInformation,
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null
            ? jsonEncode(notificationBody.toJson())
            : null);
  }

  static Future<String> _downloadAndSaveFile(
      String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static NotificationBodyModel? convertNotification(Map<String, dynamic> data) {
    if (data['type'] == 'general') {
      return NotificationBodyModel(notificationType: NotificationType.general);
    } else if (data['type'] == 'order_status') {
      return NotificationBodyModel(
          orderId: int.parse(data['order_id']),
          notificationType: NotificationType.order);
    } else if (data['type'] == 'order_request') {
      return NotificationBodyModel(
          orderId: int.parse(data['order_id']),
          notificationType: NotificationType.order_request);
    } else if (data['type'] == 'message') {
      return NotificationBodyModel(
        conversationId: (data['conversation_id'] != null &&
                data['conversation_id'].isNotEmpty)
            ? int.parse(data['conversation_id'])
            : null,
        notificationType: NotificationType.message,
        type: data['sender_type'] == AppConstants.user
            ? AppConstants.user
            : AppConstants.vendor,
      );
    } else {
      return null;
    }
  }
}

Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print(
        "onBackground: ${message.notification!.title}/${message.notification!.body}/${message.notification!.titleLocKey}");
  }
}
