import 'package:flutter/material.dart';
import 'package:ion/utils/utils.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/ion_controller.dart';

class SettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}

class SettingsController extends GetxController {
  final _helper = Get.find<IonController>();
  late SharedPreferences prefs;

  var _resolution = ''.obs;
  var _bandwidth = ''.obs;
  var _codec = ''.obs;
  var _displayName = ''.obs;

  @override
  @mustCallSuper
  void onInit() async {
    super.onInit();
    prefs = await _helper.prefs();
    _resolution.value = prefs.getString('resolution') ?? 'vga';
    _bandwidth.value = prefs.getString('bandwidth') ?? '512';
    _displayName.value = prefs.getString('display_name') ?? 'Guest';
    _codec.value = prefs.getString('codec') ?? 'vp8';
  }

  save() {
    prefs.setString('resolution', _resolution.value);
    prefs.setString('bandwidth', _bandwidth.value);
    prefs.setString('display_name', _displayName.value);
    prefs.setString('codec', _codec.value);
    Get.back();
  }
}

class SettingsView extends GetView<SettingsController> {
  var _codecItems = [
    {
      'name': 'H264',
      'value': 'h264',
    },
    {
      'name': 'VP8',
      'value': 'vp8',
    },
    {
      'name': 'VP9',
      'value': 'VP9',
    },
  ];

  var _bandwidthItems = [
    {
      'name': '256kbps',
      'value': '256',
    },
    {
      'name': '512kbps',
      'value': '512',
    },
    {
      'name': '768kbps',
      'value': '768',
    },
    {
      'name': '1Mbps',
      'value': '1024',
    },
  ];

  var _resolutionItems = [
    {
      'name': 'QVGA',
      'value': 'qvga',
    },
    {
      'name': 'VGA',
      'value': 'vga',
    },
    {
      'name': 'HD',
      'value': 'hd',
    },
  ];

  Widget _buildRowFixTitleRadio(List<Map<String, dynamic>> items, var value,
      ValueChanged<String> onValueChanged) {
    return Container(
        width: 320,
        height: 100,
        child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            childAspectRatio: 2.8,
            children: items
                .map((item) => ConstrainedBox(
                      constraints:
                          BoxConstraints.tightFor(width: 120.0, height: 36.0),
                      child: RadioListTile<String>(
                        value: item['value'],
                        title: Text(item['name']),
                        groupValue: value,
                        onChanged: (value) => onValueChanged(value!),
                      ),
                    ))
                .toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
        ),
        body: Align(
            alignment: Alignment(0, 0),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(46.0, 18.0, 48.0, 0),
                          child: Align(
                            child: Text('DisplayName:'),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(48.0, 0.0, 48.0, 0),
                          child: TextField(
                            keyboardType: TextInputType.text,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(10.0),
                              border: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.black12)),
                              hintText: controller._displayName.value,
                            ),
                            onChanged: (value) {
                              controller._displayName.value = value;
                            },
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(46.0, 18.0, 48.0, 0),
                          child: Align(
                            child: Text('Codec:'),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0),
                          child: Obx( () => _buildRowFixTitleRadio(
                              _codecItems, controller._codec.value, (value) {
                            controller._codec.value = value;
                          })),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(46.0, 18.0, 48.0, 0),
                          child: Align(
                            child: Text('Resolution:'),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0),
                          child: Obx(() => _buildRowFixTitleRadio(
                              _resolutionItems, controller._resolution.value,
                              (value) {
                            controller._resolution.value = value;
                          })),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(46.0, 18.0, 48.0, 0),
                          child: Align(
                            child: Text('Bandwidth:'),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0),
                          child: Obx(() => _buildRowFixTitleRadio(
                              _bandwidthItems, controller._bandwidth.value,
                              (value) {
                            controller._bandwidth.value = value;
                          })),
                        ),
                      ],
                    ),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(0.0, 18.0, 0.0, 0.0),
                        child: Container(
                            height: 48.0,
                            width: 160.0,
                            child: InkWell(
                              child: Container(
                                width: 220.0,
                                height: 48.0,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: string2Color('#e13b3f'),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Save',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () => controller.save(),
                            )))
                  ]),
            )));
  }
}
