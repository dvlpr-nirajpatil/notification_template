import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:reshimgathi/consts/consts.dart';
import 'package:reshimgathi/main.dart';
import 'package:reshimgathi/controllers/authentication.dart';
import 'package:reshimgathi/services/device_info.dart';
import 'package:reshimgathi/services/notification/local_notification.dart';
import 'package:reshimgathi/views/home-screen/home_screen.dart';
import 'package:reshimgathi/views/payment_gateway/payment_screen.dart';
import 'package:reshimgathi/views/profile_details_screen/profile_detail_screen.dart';
import 'package:reshimgathi/views/profile_registration_form/registration_screen.dart';
import 'package:reshimgathi/views/profile_requests/profile_request_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService().init();
  LocalNotificationService().showNotification(
    title: message.data['title'],
    body: message.data['body'],
  );

  log("Background process started", name: "BG Process Init");
}

class NotificationService {
  String? token;
  NotificationService.internal();
  static NotificationService _instance = NotificationService.internal();
  static NotificationService get instance => _instance;

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  void init() async {
    NotificationSettings settings = await messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          criticalAlert: true,
          provisional: true);
      log(settings.authorizationStatus.toString(), name: "PERMISSON STATUS");
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      token = Platform.isAndroid
          ? await messaging.getToken()
          : await messaging.getAPNSToken();

      log(token.toString(), name: "FCM TOKEN");
      storeFcmToken();

      messaging.onTokenRefresh.listen((token) {
        this.token = token;
        storeFcmToken();
      });

      FirebaseMessaging.instance.subscribeToTopic("promotion");

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        LocalNotificationService().showNotification(
          title: message.data['title'],
          body: message.data['body'],
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        navigateUserViaNotification(message);
      });

      RemoteMessage? initalMessage =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initalMessage != null) {
        navigateUserViaNotification(initalMessage);
      }
    }
  }

  storeFcmToken() {
    if (appUser.isLogin) {
      FirebaseFirestore.instance.collection('tokens').doc(appUser.uid).set(
        {
          DeviceInfoService.instance.deviceInfo.id!: {
            'token': token,
            'device_model': DeviceInfoService.instance.deviceInfo.model,
            'device_name': DeviceInfoService.instance.deviceInfo.name
          }
        },
        SetOptions(
          merge: true,
        ),
      ).then((value) {
        log("TOKEN STORED IN DATABASE", name: "PUSH NOTIFICATION SERVICE");
      });
    }
  }

  deleteFcmToken() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('tokens')
        .doc(appUser.uid)
        .get();

    Map data = snapshot.data() as Map;

    data.remove(DeviceInfoService.instance.deviceInfo.id);

    await FirebaseFirestore.instance
        .collection('tokens')
        .doc(appUser.uid)
        .set(
          data as Map<String, dynamic>,
        )
        .then((value) {
      log("FCM TOKEN DELETED FROM DATABASE", name: "PUSH NOTIFICATION SERVICE");
    });
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
