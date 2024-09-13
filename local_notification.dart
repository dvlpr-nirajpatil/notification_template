import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:reshimgathi/main.dart';
import 'package:reshimgathi/controllers/authentication.dart';
import 'package:reshimgathi/views/auth_screens/signin_screen/signin_screen.dart';
import 'package:reshimgathi/views/home-screen/home_screen.dart';
import 'package:reshimgathi/views/payment_gateway/payment_screen.dart';
import 'package:reshimgathi/views/profile_details_screen/profile_detail_screen.dart';
import 'package:reshimgathi/views/profile_registration_form/registration_screen.dart';
import 'package:reshimgathi/views/profile_requests/profile_request_screen.dart';

class LocalNotificationService {
  static LocalNotificationService instance =
      LocalNotificationService.internal();
  LocalNotificationService.internal();

  factory LocalNotificationService() => instance;

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('flutter_logo');

    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {
          log(body.toString(), name: "NOTIFICATION DATA");
          log("Notification Get Clicked !!!", name: "LOCAL NOTIFICATION");
        });

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {
      log(notificationResponse.payload.toString(), name: "NOTIFICATION DATA");
      log("Notification Get Clicked !!!", name: "LOCAL NOTIFICATION");
    });
  }

  notificationDetails() {
    return const NotificationDetails(
        android: AndroidNotificationDetails('channelId', 'channelName',
            importance: Importance.max),
        iOS: DarwinNotificationDetails());
  }

  Future showNotification(
      {int id = 0, String? title, String? body, String? payLoad}) async {
    return notificationsPlugin.show(
        id, title, body, await notificationDetails());
  }

  navigateUserViaNotification(RemoteMessage message) {
    if (appUser.isLogin) {
      switch (message.data['type']) {
        case "profile-request":
          GoRouter.of(navigatorKey.currentState!.context)
              .goNamed(ProfileRequestScreen.id);
          break;

        case "profile-accept":
          GoRouter.of(navigatorKey.currentState!.context).goNamed(
            ProfileDetailScreen.id,
            pathParameters: {
              "id": message.data['id'],
            },
          );
          break;

        case "verification_sucesss":
          GoRouter.of(navigatorKey.currentState!.context)
              .goNamed(MembershipScreen.id);
          break;

        case "verification_failed":
          GoRouter.of(navigatorKey.currentState!.context)
              .goNamed(RegistrationScreen.id);
          break;

        default:
          GoRouter.of(navigatorKey.currentState!.context).goNamed(
            HomeScreen.id,
          );
      }
    } else {
      GoRouter.of(navigatorKey.currentState!.context).goNamed(SignInScreen.id);
    }
  }
}
