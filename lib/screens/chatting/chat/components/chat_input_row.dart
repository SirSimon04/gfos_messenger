import 'dart:io';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dispuatio/constants.dart';
import 'package:flutter_dispuatio/models/chat_model.dart';
import 'package:flutter_dispuatio/models/message_model.dart';
import 'package:flutter_dispuatio/screens/chatting/chat/screens/image_send/image_send_screen.dart';
import 'package:flutter_dispuatio/services/chat_service/chat_fcm_service.dart';
import 'package:flutter_dispuatio/services/chat_service/chat_firebase_service.dart';
import 'package:flutter_dispuatio/services/user_services/GeneralUserService.dart';
import 'package:flutter_dispuatio/services/user_services/user_firebase_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SendMessage extends Notification {
  SendMessage();
}

class ChatInputRow extends StatefulWidget {
  final ChatModel chat;
  final ScrollController scrollController;
  final MessageModel answerMessage;
  ChatInputRow({
    required this.chat,
    required this.scrollController,
    required this.answerMessage,
  });

  @override
  _ChatInputRowState createState() => _ChatInputRowState(chat);
}

class _ChatInputRowState extends State<ChatInputRow> {
  ChatModel chat;
  _ChatInputRowState(this.chat);

  final textController = TextEditingController();

  Widget sendIconButton = Container();

  FirebaseAuth _auth = FirebaseAuth.instance;

  final picker = ImagePicker();

  Future getImageFromCam() async {
    File imageFile = File(await ImagePicker()
        .getImage(source: ImageSource.camera)
        .then((pickedFile) => pickedFile!.path));

    Navigator.of(context)
        .push(
          CupertinoPageRoute(
            builder: (context) => ImageSendScreen(image: imageFile, chat: chat),
          ),
        )
        .then((value) => Navigator.pop(context));
  }

  Future getImageFromGallery() async {
    File imageFile = File(await ImagePicker()
        .getImage(source: ImageSource.gallery)
        .then((pickedFile) => pickedFile!.path));

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ImageSendScreen(image: imageFile, chat: chat),
      ),
    );
  }

  Future<Null> getWrittenText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      setState(() {
        textController.text = (prefs.getString(chat.uid))!;
      });
    } catch (e) {}
  }

  Future<Null> setWrittenText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(chat.uid, textController.text);
  }

  @override
  void initState() {
    super.initState();
    getWrittenText();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    setWrittenText();
    textController.dispose();
    super.dispose();
  }

  int _lineCount = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _lineCount > 1 ? 90 : 70,
      color: Theme.of(context).bottomAppBarColor,
      child: Column(
        children: [
          SizedBox(
            height: kDefaultPadding / 2,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: kDefaultPadding / 2,
              ),
              IconButton(
                icon: Icon(
                  FontAwesomeIcons.plus,
                ),
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onPressed: () {
                  if (Platform.isIOS) {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) => CupertinoActionSheet(),
                    );
                  } else {
                    showAdaptiveActionSheet(
                      context: context,
                      actions: [
                        BottomSheetAction(
                          title: Text(
                            "Fotomediathek",
                            textAlign: TextAlign.center,
                          ),
                          onPressed: getImageFromGallery,
                          trailing: Icon(FontAwesomeIcons.solidImages),
                        ),
                        BottomSheetAction(
                            title: Text(
                              "Foto aufnehmen",
                              textAlign: TextAlign.center,
                            ),
                            onPressed: getImageFromCam,
                            trailing: Icon(FontAwesomeIcons.camera)),
                      ],
                      cancelAction: CancelAction(
                        title: const Text('Schließen'),
                      ),
                    );
                  }
                },
              ),
              SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.multiline,
                  cursorColor: Theme.of(context).primaryColor,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(kCircularBorderRadius),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 3,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(kCircularBorderRadius),
                    ),
                    filled: true,
                    isDense: true,
                    contentPadding: EdgeInsets.all(14),
                  ),
                  minLines: _lineCount > 1 ? 2 : 1,
                  maxLines: 2,
                  controller: textController,
                  onChanged: (String text) {
                    // print(('\n'.allMatches(text).length + 1).toString());
                    print("zeilen " +
                        ((textController.text.length /
                                    (MediaQuery.of(context).size.width *
                                        0.055)) //TODO: test this on other devices
                                .round())
                            .toString());

                    setState(() {
                      _lineCount = (textController.text.length /
                              (MediaQuery.of(context).size.width * 0.055))
                          .round();
                      checkUserInput();
                    });
                  },
                ),
              ),
              SizedBox(
                width: kDefaultPadding / 2,
              ),
              // SizedBox(
              //   height: 24,
              //   width: 24,
              //   child: FocusedMenuHolder(
              //     menuItems: getRightContextMenuActions(
              //       normalPressed: () {
              //         setState(() {
              //           _rightContextButton = Icon(FontAwesomeIcons.ellipsisH);
              //         });
              //       },
              //       importantPressed: () {
              //         setState(() {
              //           _rightContextButton =
              //               Icon(FontAwesomeIcons.exclamation);
              //         });
              //       },
              //       plannedPressed: () {
              //         setState(() {
              //           _rightContextButton =
              //               Icon(FontAwesomeIcons.solidCalendar);
              //         });
              //       },
              //     ),
              //     onPressed: () {},
              //     openWithTap: true,
              //     animateMenuItems: false,
              //     bottomOffsetHeight: 10.0,
              //     menuOffset: 10.0,
              //     child: _rightContextButton,
              //   ),
              // ),
              SizedBox(
                width: kDefaultPadding / 2,
              ),
              sendIconButton,
            ],
          ),
          SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
      ),
    );
  }

  checkUserInput() {
    print("checkUserInput");
    if (textController.text.trim().length != 0) {
      UserFirebaseService.setWritingTrue(chat.uid);
      sendIconButton = Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: IconButton(
              icon: Icon(
                FontAwesomeIcons.solidPaperPlane,
              ),
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              padding: EdgeInsets.all(0),
              onPressed: () async {
                await ChatFirebaseService.sendMessage(
                  ansMsg: widget.answerMessage,
                  text: textController.text,
                  chatUid: widget.chat.uid,
                  usersUid: widget.chat.isGroup
                      ? widget.chat.members
                      : GeneralUserService.getUidsFromMembers(widget.chat),
                  memberCount: widget.chat.members.length,
                );

                await ChatFirebaseService.updateChatAfterSend(
                    chatUid: widget.chat.uid,
                    text: textController.text,
                    memberCount: widget.chat.members.length);

                await UserFirebaseService.setWritingFalse(chat.uid);

                SendMessage().dispatch(context); //Notify parent msg got send

                String msgText =
                    textController.text; //save msgText for sending the FCM-Msg

                setState(() {
                  // Reset textfield and scroll to bottom
                  textController.clear();
                  _lineCount = 0;
                  checkUserInput();
                  widget.scrollController.animateTo(
                    widget.scrollController.position.maxScrollExtent,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.fastOutSlowIn,
                  );
                });

                ChatFcmService.sendMsgPrivate(
                  chatUid: widget.chat.uid,
                  name: _auth.currentUser?.displayName ?? "",
                  msgText: msgText,
                );
              },
            ),
          ),
          SizedBox(
            width: kDefaultPadding / 2,
          ),
        ],
      );
    } else {
      UserFirebaseService.setWritingFalse(chat.uid);
      sendIconButton = Container();
    }
  }
}
