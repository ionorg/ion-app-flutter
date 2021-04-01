import 'package:flutter/material.dart';
import 'package:date_format/date_format.dart';
import 'package:ion/helper/ion_helper.dart';
import 'package:ion/page/chat_message.dart';
import 'package:flutter_ion/flutter_ion.dart';

class ChatPage extends StatefulWidget {
  IonHelper _helper;
  var _historyMessage = [];
  String _displayName;
  String _room;

  ChatPage(this._helper, this._historyMessage, this._displayName, this._room);

  @override
  State createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  IonHelper? _helper;
  var _historyMessage = [];

  String _displayName = "";
  String _sid = "";

  final TextEditingController textEditingController = TextEditingController();
  List<ChatMessage> _messages = <ChatMessage>[];
  FocusNode textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _helper = widget._helper;
    _historyMessage = widget._historyMessage;
    _displayName = widget._displayName;
    _sid = widget._room;

    if (_helper != null) {
      for (int i = 0; i < _historyMessage.length; i++) {
        var hisMsg = _historyMessage[i];

        ChatMessage message = ChatMessage(
          hisMsg['text'],
          hisMsg['name'],
          formatDate(DateTime.now(), [HH, ':', nn, ':', ss]),
          hisMsg['name'] == _displayName ? true : false,
        );
        _messages.insert(0, message);
      }
      setState(() {
        _messages = _messages;
      });
      _helper?.ion?.onMessage = _messageProcess;
    }
  }

  void _messageProcess(Message msg) async {
    var info = msg.data;
    print('message: ' + msg.data.toString());
    ChatMessage message = ChatMessage(
      info['msg'],
      info['senderName'],
      formatDate(DateTime.now(), [HH, ':', nn, ':', ss]),
      info['senderName'] == _displayName ? true : false,
    );

    _messages.insert(0, message);
    setState(() {
      _messages = _messages;
    });
  }

  @override
  void dispose() {
    print('Dispose chat widget!');

    _messages = <ChatMessage>[];
    super.dispose();
  }

  void _handleSubmit(String text) {
    textEditingController.clear();

    if (text.length == 0 || text == '') {
      return;
    }

    var info = {
      "senderName": _displayName,
      "msg": text,
    };

    _helper?.ion?.message(_helper!.uid, _sid, info);

    var msg = ChatMessage(
      text,
      this._displayName,
      formatDate(DateTime.now(), [HH, ':', nn, ':', ss]),
      true,
    );
    _messages.insert(0, msg);
    setState(() {
      _messages = _messages;
    });
  }

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
                controller: textEditingController,
                onSubmitted: _handleSubmit,
                focusNode: textFocusNode,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _handleSubmit(textEditingController.text),
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
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
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
