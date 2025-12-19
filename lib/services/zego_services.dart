import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegoService {
  static const int appID = 1367841437;
  static const String appSign =
      "bf5ca79fb469242e19cc0b3d8d16a3df9ac3e32289e1ad9b35010d052613dece";

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
