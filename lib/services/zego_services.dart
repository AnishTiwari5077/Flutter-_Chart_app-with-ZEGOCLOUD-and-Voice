import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import '../core/env_config.dart';

class ZegoService {
  static int get appID => EnvConfig.zegoAppId;
  static String get appSign => EnvConfig.zegoAppSign;

  static bool _isInitialized = false;

  static Future<void> initializeZego({
    required String userId,
    required String userName,
  }) async {
    if (appID == 0 || appSign.isEmpty) {
      throw Exception('ZEGO credentials not configured');
    }

    if (_isInitialized) return;

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
    if (!_isInitialized) return;
    await ZegoUIKitPrebuiltCallInvitationService().uninit();
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;
}
