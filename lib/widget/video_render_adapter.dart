import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoRendererAdapter {
  String _mid;
  bool _local;
  RTCVideoRenderer? _renderer;
  MediaStream _stream;
  RTCVideoViewObjectFit _objectFit =
      RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
  VideoRendererAdapter(this._mid, this._stream, this._local);

  setupSrcObject() async {
    if (_renderer == null) {
      _renderer = new RTCVideoRenderer();
      await _renderer?.initialize();
    }
    _renderer?.srcObject = _stream;
    if (_local) {
      _objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    }
  }

  switchObjFit() {
    _objectFit =
        (_objectFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain)
            ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
            : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
  }

  set objectFit(RTCVideoViewObjectFit objectFit) {
    _objectFit = objectFit;
  }

  dispose() async {
    if (_renderer != null) {
      print('dispose for texture id ' + _renderer!.textureId.toString());
      _renderer?.srcObject = null;
      await _renderer?.dispose();
      _renderer = null;
    }
  }

  get local => _local;

  get mid => _mid;

  get renderer => _renderer;

  get stream => _stream;
}
