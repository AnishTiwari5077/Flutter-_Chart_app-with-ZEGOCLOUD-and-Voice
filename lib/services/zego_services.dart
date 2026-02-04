import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegoService {
  static const int appID = ; //your appID
  static const String appSign =
      "";//your appsignid

  static bool _isInitialized = false;

  static Future<void> initializeZego({
    required String userId,
    required String userName,
  }) async {
    if (appID == 0 || appSign.isEmpty) {
      return;
    }

    if (_isInitialized) {
      return;
    }

    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: appID,
      appSign: appSign,
      userID: userId,
      userName: userName,

      plugins: [ZegoUIKitSignalingPlugin()],

      requireConfig: (ZegoCallInvitationData data) {
        final bool isGroup = data.invitees.length > 1;

        final bool isVideo = data.type == ZegoCallInvitationType.videoCall;

        if (isGroup) {
          return isVideo
              ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
              : ZegoUIKitPrebuiltCallConfig.groupVoiceCall();
        } else {
          return isVideo
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
        }
      },
    );

    _isInitialized = true;
  }

  static Future<void> uninitializeZego() async {
    if (!_isInitialized) {
      return;
    }

    await ZegoUIKitPrebuiltCallInvitationService().uninit();
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;
}
