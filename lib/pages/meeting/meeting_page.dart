import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ion/controllers/ion_controller.dart';
import 'package:get/get.dart';

class MeetingBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeetingController>(() => MeetingController());
    Get.lazyPut<IonController>(() => IonController());
  }
}

class VideoRendererAdapter {
  String mid;
  bool local;
  RTCVideoRenderer? renderer;
  MediaStream stream;
  RTCVideoViewObjectFit _objectFit =
      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
  VideoRendererAdapter._internal(this.mid, this.stream, this.local);

  static Future<VideoRendererAdapter> create(
      String mid, MediaStream stream, bool local) async {
    var renderer = VideoRendererAdapter._internal(mid, stream, local);
    await renderer.setupSrcObject();
    return renderer;
  }

  setupSrcObject() async {
    if (renderer == null) {
      renderer = new RTCVideoRenderer();
      await renderer?.initialize();
    }
    renderer?.srcObject = stream;
    if (local) {
      _objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    }
  }

  switchObjFit() {
    _objectFit =
        (_objectFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain)
            ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
            : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
  }

  RTCVideoViewObjectFit get objFit => _objectFit;

  set objectFit(RTCVideoViewObjectFit objectFit) {
    _objectFit = objectFit;
  }

  dispose() async {
    if (renderer != null) {
      print('dispose for texture id ' + renderer!.textureId.toString());
      renderer?.srcObject = null;
      await renderer?.dispose();
      renderer = null;
    }
  }
}

class MeetingController extends GetxController {
  final _helper = Get.find<IonController>();
  late SharedPreferences prefs;
  final videoRenderers = Rx<List<VideoRendererAdapter>>([]);
  LocalStream? _localStream;
  IonConnector? get ion => _helper.ion;
  var _cameraOff = false.obs;
  var _microphoneOff = false.obs;
  var _speakerOn = true.obs;
  var _scaffoldkey = GlobalKey<ScaffoldState>();
  var name = ''.obs;
  var room = ''.obs;
  @override
  @mustCallSuper
  void onInit() async {
    super.onInit();
    prefs = await _helper.prefs();

    if (ion == null) {
      print(":::IonHelper is not initialized!:::");
      print("Goback to /login");
      Get.offNamed('/login');
      return;
    }

    ion?.onJoin = (bool success, String reason) async {
      this._showSnackBar(":::Join success:::");
      if (success) {
        try {
            var resolution = prefs.getString('resolution') ?? 'hd';
            var codec = prefs.getString('codec') ?? 'vp8';

          _localStream = await LocalStream.getUserMedia(
              constraints: Constraints.defaults
              ..simulcast = false
              ..resolution = resolution
              ..codec = codec);
          ion?.sfu!.publish(_localStream!);
          _addAdapter(await VideoRendererAdapter.create(
              _localStream!.stream.id, _localStream!.stream, true));
        } catch (error) {
          print('publish err ${error.toString()}');
        }
      }
    };

    ion?.onLeave = (String reason) {
      this._showSnackBar(":::Leave success:::");
    };

    ion?.onPeerEvent = (PeerEvent event) {
      var name = event.peer.info['name'];
      var state = '';
      switch (event.state) {
        case PeerState.NONE:
          break;
        case PeerState.JOIN:
          state = 'join';
          break;
        case PeerState.UPDATE:
          state = 'upate';
          break;
        case PeerState.LEAVE:
          state = 'leave';
          break;
      }
      this._showSnackBar(":::Peer [${event.peer.uid}:$name] $state:::");
    };

    ion?.onStreamEvent = (StreamEvent event) async {
      switch (event.state) {
        case StreamState.NONE:
          break;
        case StreamState.ADD:
          if (event.streams.isNotEmpty) {
            var mid = event.streams[0].id;
            this._showSnackBar(":::stream-add [$mid]:::");
          }
          break;
        case StreamState.REMOVE:
          if (event.streams.isNotEmpty) {
            var mid = event.streams[0].id;
            this._showSnackBar(":::stream-remove [$mid]:::");
            _removeAdapter(mid);
          }
          break;
      }
    };

    ion?.onTrack = (MediaStreamTrack track, RemoteStream stream) async {
      if (track.kind == 'video') {
        _addAdapter(
            await VideoRendererAdapter.create(stream.id, stream.stream, false));
      }
    };

    name.value = prefs.getString('display_name') ?? 'Guest';
    room.value = prefs.getString('room') ?? 'room1';
    _helper.join(room.value, name.value);
  }

  _removeAdapter(String mid) {
    videoRenderers.value.removeWhere((element) => element.mid == mid);
    videoRenderers.update((val) {});
  }

  _addAdapter(VideoRendererAdapter adapter) {
    videoRenderers.value.add(adapter);
    videoRenderers.update((val) {});
  }

  _swapAdapter(adapter) {
    var index = videoRenderers.value
        .indexWhere((element) => element.mid == adapter.mid);
    if (index != -1) {
      var temp = videoRenderers.value.elementAt(index);
      videoRenderers.value[0] = videoRenderers.value[index];
      videoRenderers.value[index] = temp;
    }
  }

  //Switch speaker/earpiece
  _switchSpeaker() {
    if (_localVideo != null) {
      _speakerOn.value = !_speakerOn.value;
      MediaStreamTrack audioTrack = _localVideo!.stream.getAudioTracks()[0];
      audioTrack.enableSpeakerphone(_speakerOn.value);
      _showSnackBar(":::Switch to " +
          (_speakerOn.value ? "speaker" : "earpiece") +
          ":::");
    }
  }

  VideoRendererAdapter? get _localVideo {
    VideoRendererAdapter? renderrer;
    videoRenderers.value.forEach((element) {
      if (element.local) {
        renderrer = element;
        return;
      }
    });
    return renderrer;
  }

  List<VideoRendererAdapter> get _remoteVideos {
    List<VideoRendererAdapter> renderers = ([]);
    videoRenderers.value.forEach((element) {
      if (!element.local) {
        renderers.add(element);
      }
    });
    return renderers;
  }

  //Switch local camera
  _switchCamera() {
    if (_localVideo != null &&
        _localVideo!.stream.getVideoTracks().length > 0) {
      _localVideo?.stream.getVideoTracks()[0].switchCamera();
    } else {
      _showSnackBar(":::Unable to switch the camera:::");
    }
  }

  //Open or close local video
  _turnCamera() {
    if (_localVideo != null &&
        _localVideo!.stream.getVideoTracks().length > 0) {
      var muted = !_cameraOff.value;
      _cameraOff.value = muted;
      _localVideo?.stream.getVideoTracks()[0].enabled = !muted;
    } else {
      _showSnackBar(":::Unable to operate the camera:::");
    }
  }

  //Open or close local audio
  _turnMicrophone() {
    if (_localVideo != null &&
        _localVideo!.stream.getAudioTracks().length > 0) {
      var muted = !_microphoneOff.value;
      _microphoneOff.value = muted;
      _localVideo?.stream.getAudioTracks()[0].enabled = !muted;
      _showSnackBar(":::The microphone is ${muted ? 'muted' : 'unmuted'}:::");
    } else {}
  }

  _cleanUp() async {
    var ion = _helper.ion;

    if (_localVideo != null) {
      await _localStream!.unpublish();
    }

    videoRenderers.value.forEach((item) async {
      var stream = item.stream;
      try {
        ion?.sfu!.close();
        await stream.dispose();
      } catch (error) {}
    });
    videoRenderers.value.clear();
    await _helper.close();

    Get.back();
  }

  _showSnackBar(String message) {
    print(message);
    /*
    _scaffoldkey.currentState!.showSnackBar(SnackBar(
      content: Container(
        //color: Colors.white,
        decoration: BoxDecoration(
            color: Colors.black38,
            border: Border.all(width: 2.0, color: Colors.black),
            borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.fromLTRB(45, 0, 45, 45),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(message,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center),
        ),
      ),
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      duration: Duration(
        milliseconds: 1000,
      ),
    ));*/
  }

  _hangUp() {
    Get.dialog(AlertDialog(
        title: Text("Hangup"),
        content: Text("Are you sure to leave the room?"),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Get.back();
            },
          ),
          TextButton(
            child: Text(
              "Hangup",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Get.back();
              _cleanUp();
            },
          )
        ]));
  }
}

class BoxSize {
  BoxSize({required this.width, required this.height});
  double width;
  double height;
}

class MeetingView extends GetView<MeetingController> {
  IonConnector? get ion => controller.ion;
  List<VideoRendererAdapter> get remoteVideos => controller._remoteVideos;
  VideoRendererAdapter? get localVideo => controller._localVideo;

  final double localWidth = 114.0;
  final double localHeight = 72.0;

  BoxSize localVideoBoxSize(Orientation orientation) {
    return BoxSize(
      width: (orientation == Orientation.portrait) ? localHeight : localWidth,
      height: (orientation == Orientation.portrait) ? localWidth : localHeight,
    );
  }

  Widget _buildMajorVideo() {
    return Obx(() {
      if (remoteVideos.isEmpty) {
        return Image.asset(
          'assets/images/loading.jpeg',
          fit: BoxFit.cover,
        );
      }
      var adapter = remoteVideos[0];
      return GestureDetector(
          onDoubleTap: () {
            adapter.switchObjFit();
          },
          child: RTCVideoView(adapter.renderer!, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain));
    });
  }

  Widget _buildVideoList() {
    return Obx(() {
      if (remoteVideos.length <= 1) {
        return Container();
      }
      return ListView(
          scrollDirection: Axis.horizontal,
          children:
              remoteVideos.getRange(1, remoteVideos.length).map((adapter) {
            adapter.objectFit =
                RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
            return _buildMinorVideo(adapter);
          }).toList());
    });
  }

  Widget _buildLocalVideo(Orientation orientation) {
    return Obx(() {
      if (localVideo == null) {
        return Container();
      }
      var size = localVideoBoxSize(orientation);
      return SizedBox(
          width: size.width,
          height: size.height,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(
                color: Colors.white,
                width: 0.5,
              ),
            ),
            child: GestureDetector(
                onTap: () {
                  controller._switchCamera();
                },
                onDoubleTap: () {
                  localVideo?.switchObjFit();
                },
                child: RTCVideoView(localVideo!.renderer!, objectFit: localVideo!.objFit)),
          ));
    });
  }

  Widget _buildMinorVideo(VideoRendererAdapter adapter) {
    return SizedBox(
      width: 120,
      height: 90,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(
            color: Colors.white,
            width: 1.0,
          ),
        ),
        child: GestureDetector(
            onTap: () => controller._swapAdapter(adapter),
            onDoubleTap: () => adapter.switchObjFit(),
            child: RTCVideoView(adapter.renderer!, objectFit: adapter.objFit)),
      ),
    );
  }

  //Leave current video room

  Widget _buildLoading() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Text(
            'Waiting for others to join...',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22.0,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  //tools
  List<Widget> _buildTools() {
    return <Widget>[
      SizedBox(
        width: 36,
        height: 36,
        child: RawMaterialButton(
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Obx(() => Icon(
                controller._cameraOff.value
                    ? CommunityMaterialIcons.video_off
                    : CommunityMaterialIcons.video,
                color: controller._cameraOff.value ? Colors.red : Colors.white,
              )),
          onPressed: controller._turnCamera,
        ),
      ),
      SizedBox(
        width: 36,
        height: 36,
        child: RawMaterialButton(
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Icon(
            CommunityMaterialIcons.video_switch,
            color: Colors.white,
          ),
          onPressed: controller._switchCamera,
        ),
      ),
      SizedBox(
        width: 36,
        height: 36,
        child: RawMaterialButton(
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Obx(() => Icon(
                controller._microphoneOff.value
                    ? CommunityMaterialIcons.microphone_off
                    : CommunityMaterialIcons.microphone,
                color:
                    controller._microphoneOff.value ? Colors.red : Colors.white,
              )),
          onPressed: controller._turnMicrophone,
        ),
      ),
      SizedBox(
        width: 36,
        height: 36,
        child: RawMaterialButton(
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Obx(() => Icon(
                controller._speakerOn.value
                    ? CommunityMaterialIcons.volume_high
                    : CommunityMaterialIcons.speaker_off,
                color: Colors.white,
              )),
          onPressed: controller._switchSpeaker,
        ),
      ),
      SizedBox(
        width: 36,
        height: 36,
        child: RawMaterialButton(
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Icon(
            CommunityMaterialIcons.phone_hangup,
            color: Colors.red,
          ),
          onPressed: controller._hangUp,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return SafeArea(
        child: Scaffold(
            key: controller._scaffoldkey,
            body: Container(
              color: Colors.black87,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: Container(
                              child: _buildMajorVideo(),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 48,
                            child: Container(
                              child: _buildLocalVideo(orientation),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 48,
                            height: 90,
                            child: Container(
                              margin: EdgeInsets.all(6.0),
                              child: _buildVideoList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Obx(() =>
                      (remoteVideos.isEmpty) ? _buildLoading() : Container()),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 48,
                    child: Stack(
                      children: <Widget>[
                        Opacity(
                          opacity: 0.5,
                          child: Container(
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          height: 48,
                          margin: EdgeInsets.all(0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _buildTools(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 48,
                    child: Stack(
                      children: <Widget>[
                        Opacity(
                          opacity: 0.5,
                          child: Container(
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.all(0.0),
                          child: Center(
                            child: Obx(() => Text(
                              'ION Conference [${controller.room.value}]',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                              ),
                            )),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(
                                Icons.people,
                                size: 28.0,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),
                            //Chat message
                            IconButton(
                              icon: Icon(
                                Icons.chat_bubble_outline,
                                size: 28.0,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Get.toNamed('/chat');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      );
    });
  }
}
