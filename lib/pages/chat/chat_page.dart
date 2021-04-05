import 'package:flutter/material.dart';
import 'package:date_format/date_format.dart';
import 'package:ion/controllers/ion_controller.dart';
import 'package:ion/pages/chat/chat_message.dart';
import 'package:flutter_ion/flutter_ion.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
  }
}

class ChatController extends GetxController {
  final _helper = Get.find<IonController>();
  late SharedPreferences prefs;
  var _historyMessage = [];
  String _displayName = "";
  final TextEditingController textEditingController = TextEditingController();
  final _messages = Rx<List<ChatMessage>>([]);
  FocusNode textFocusNode = FocusNode();

  @override
  @mustCallSuper
  void onInit() async {
    super.onInit();
    prefs = await _helper.prefs();
    for (int i = 0; i < _historyMessage.length; i++) {
      var hisMsg = _historyMessage[i];
      ChatMessage message = ChatMessage(
        hisMsg['uid'],
        hisMsg['text'],
        hisMsg['name'],
        formatDate(DateTime.now(), [HH, ':', nn, ':', ss]),
        hisMsg['uid'] == _helper.uid ? true : false,
      );
      _messages.value.insert(0, message);
    }
    _helper.ion?.onMessage = _messageProcess;
  }

  void _messageProcess(Message msg) async {
    if (msg.from == _helper.uid) {
      print('Skip self message');
      return;
    }
    var info = msg.data;
    var sender = info['name'];
    var text = info['text'];
    var uid = info['uid'] as String;
    //print('message: sender = ' + sender + ', text = ' + text);
    ChatMessage message = ChatMessage(
      uid,
      text,
      sender,
      formatDate(DateTime.now(), [HH, ':', nn, ':', ss]),
      uid == _helper.uid,
    );

    _messages.value.insert(0, message);
    _messages.update((val) {});
  }

  @override
  void dispose() {
    print('Dispose chat widget!');
    _messages.value.clear();
    super.dispose();
  }

  void _handleSubmit(String text) {
    textEditingController.clear();

    if (text.length == 0 || text == '') {
      return;
    }

    var info = {
      'uid': _helper.uid,
      'name': _helper.name,
      'text': text,
    };

    _helper.ion?.message(_helper.uid, _helper.sid, info);

    var msg = ChatMessage(
      _helper.uid,
      text,
      this._displayName,
      formatDate(DateTime.now(), [HH, ':', nn, ':', ss]),
      true,
    );
    _messages.value.insert(0, msg);
    _messages.update((val) {});
  }
}

class ChatView extends GetView<ChatController> {
  Widget textComposerWidget() {
    return IconTheme(
      data: IconThemeData(color: Colors.blue),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                decoration:
                    InputDecoration.collapsed(hintText: 'Please input message'),
                controller: controller.textEditingController,
                onSubmitted: controller._handleSubmit,
                focusNode: controller.textFocusNode,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => controller
                    ._handleSubmit(controller.textEditingController.text),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: Obx(() => ListView.builder(
                  padding: EdgeInsets.all(8.0),
                  reverse: true,
                  itemBuilder: (_, int index) =>
                      controller._messages.value[index],
                  itemCount: controller._messages.value.length,
                )),
          ),
          Divider(
            height: 1.0,
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: textComposerWidget(),
          )
        ],
      ),
    );
  }
}
