import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(NFCPage());
}

class NFCPage extends StatefulWidget {
  static String routeName = './nfc_page';
  @override
  State<StatefulWidget> createState() => NFCPageState();
}

class NFCPageState extends State<NFCPage> {
  ValueNotifier<dynamic> result = ValueNotifier(null);

  initState() {
    super.initState();
    // ignore: avoid_print
    print("initState Called");
    debugPrint("initState Called");

    _tagRead();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('NFC Reader')),
        body: SafeArea(
          child: FutureBuilder<bool>(
            future: NfcManager.instance.isAvailable(),
            builder: (context, ss) => ss.data != true
                ? Center(child: Text('NfcManager.isAvailable(): ${ss.data}'))
                : Flex(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    direction: Axis.vertical,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Container(
                          margin: EdgeInsets.all(4),
                          constraints: BoxConstraints.expand(),
                          decoration: BoxDecoration(border: Border.all()),
                          child: SingleChildScrollView(
                            child: ValueListenableBuilder<dynamic>(
                              valueListenable: result,
                              builder: (context, value, _) =>
                                  Text('${value ?? ''}'),
                            ),
                          ),
                        ),
                      ),
                      Image.asset('assets/images/contactless.png'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _tagRead() {
    print("_tagRead()");
    NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            print(tag.data);

            if (tag.data["ndef"]["cachedMessage"] != null) {
              var tagValue = String.fromCharCodes(tag.data["ndef"]
                      ["cachedMessage"]["records"][0]["payload"])
                  .substring(3);
              result.value = tagValue;
              print(tagValue);

              if (tagValue == 'chatPDP') {
                final fire = FirebaseFirestore.instance;
                final currentUser = FirebaseAuth.instance.currentUser;

                fire
                    .collection("users")
                    .doc(currentUser!.uid)
                    .update({'attended': true});
              }

              NfcManager.instance.stopSession();
            }
          } catch (e) {
            print("------");
            print(e);
          }
        });
  }
}
