import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:holding_gesture/holding_gesture.dart';
import 'package:sensors/sensors.dart';
import 'dart:convert';

class AllControlsView extends StatefulWidget {
  final BluetoothDevice server;

  const AllControlsView({this.server});

  @override
  _AllControlsViewState createState() => _AllControlsViewState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _AllControlsViewState extends State<AllControlsView>
    with SingleTickerProviderStateMixin {
  StreamSubscription<Uint8List> _streamSubscription;
  List<_Message> messages = List<_Message>();
  String _messageBuffer = '';
  TextEditingController presentatioonTextEditingController;
  TextEditingController terminalTextEditingController;
  AnimationController spinController;
  bool isConnecting = true;

  bool isConnected = false;
  bool doubleTapped = false;
  bool _condition = true;
  double dx = 0.0;
  double dy = 0.0;

  bool isGyroOn = false;

  bool _onHold = false;
  @override
  void initState() {
    presentatioonTextEditingController = TextEditingController();
    terminalTextEditingController = TextEditingController();
    spinController = AnimationController(
      vsync: this,
      lowerBound: 0,
      duration: Duration(seconds: 10),
      upperBound: 2,
    );
    super.initState();
    spinController.repeat();

    accelerometerEvents.listen((event) {
      if (isGyroOn) {
        _sendMessage('*#*Offset(${event.x * -1}, ${event.y * -1})*@*');
      }
    });
    if (widget.server.isConnected) {
      isConnected = true;
      isConnecting = false;
    }

    connectToBluetooth();
  }

  BluetoothConnection _bluetoothConnection;
  connectToBluetooth() async {
    if (!isConnected) {
      _bluetoothConnection =
          await BluetoothConnection.toAddress(widget.server.address);

      isConnecting = false;
      this._bluetoothConnection = _bluetoothConnection;

      _streamSubscription = _bluetoothConnection.input.listen(_onDataReceived);
      setState(() {
        isConnected = true;
      });

      _streamSubscription.onDone(() {
        print('we got disconnected by remote!');
        _streamSubscription = null;
        setState(() {
          isConnected = false;
        });
      });
    }
  }

  @override
  void dispose() {
    spinController?.dispose();
    _streamSubscription?.cancel();
    presentatioonTextEditingController?.dispose();
    terminalTextEditingController?.dispose();
    if (isConnected) {
      print('we are disconnecting locally!');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(text: "PowerPoint"),
              Tab(text: "VLC"),
              Tab(text: "Terminal"),
            ],
          ),
          title: (isConnecting
              ? Text('Connecting')
              : isConnected
                  ? Text('Connected')
                  : Text('Disconnected')),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => close(),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: isConnected ? null : () => connectToBluetooth(),
            ),
          ],
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildPresentationControl(context),
            _buildVLC(context),
            _buildTerminal(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminal(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 11,
                child: TextField(
                  controller: terminalTextEditingController,
                  maxLines: 20,
                  cursorColor: Color(0xffFF3399),
                  autofocus: true,
                  cursorWidth: 9,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    _sendStringToType(value.trim());
                    _sendMessage("*#*ENTER*@*");
                    terminalTextEditingController.clear();
                  },
                  cursorHeight: 24,
                  decoration: InputDecoration(
                    hintText: (isConnecting
                        ? 'Wait until connected...'
                        : isConnected
                            ? 'Send terminal Commands'
                            : 'BT got disconnected'),
                    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                    fillColor: Theme.of(context).dialogBackgroundColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  enabled: isConnected,
                ),
              ),
              Flexible(
                flex: 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (dragUpdate) => scroll(dragUpdate),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 8.0),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          HoldDetector(
                            onHold: () => scroll(DragUpdateDetails(
                                delta: Offset(0.0, -1.0),
                                globalPosition: null)),
                            holdTimeout: Duration(milliseconds: 200),
                            enableHapticFeedback: true,
                            child: IconButton(
                              onPressed: () => scroll(DragUpdateDetails(
                                  delta: Offset(0.0, -1.0),
                                  globalPosition: null)),
                              icon: Icon(
                                Icons.arrow_drop_up,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          HoldDetector(
                            onHold: () => scroll(DragUpdateDetails(
                                delta: Offset(0.0, 1.0), globalPosition: null)),
                            holdTimeout: Duration(milliseconds: 200),
                            enableHapticFeedback: true,
                            child: IconButton(
                              onPressed: () => scroll(DragUpdateDetails(
                                  delta: Offset(0.0, 1.0),
                                  globalPosition: null)),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
          Spacer(),
          Container(
            width: double.maxFinite,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 12,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FlatButton(
                    child: Text("New Window"),
                    onPressed: isConnected ? openNewWindow : null,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FlatButton(
                    child: Text("New Tab"),
                    onPressed: isConnected ? openNewTab : null,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FlatButton(
                    child: Text("Clear Terminal"),
                    onPressed: isConnected ? clearTerminal : null,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FlatButton(
                    child: Text("Kill Process"),
                    onPressed: isConnected ? cancelTerminalProcess : null,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FlatButton(
                    child: Text("Close Tab"),
                    onPressed: isConnected ? closeTab : null,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVLC(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: spinController,
            builder: (context, child) => Transform.rotate(
              angle: pi * spinController.value,
              child: child,
            ),
            child: Image.asset('assets/logos/vlc.png',
                width: MediaQuery.of(context).size.width * 0.75),
          ),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.arrow_up, size: 42),
                  onPressed: isConnected ? arrowUp : null,
                  tooltip: 'Volume Up',
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(CupertinoIcons.viewfinder),
                          onPressed: isConnected ? toggleFullScreen : null,
                          tooltip: 'Toggle FullScreen',
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(MaterialCommunityIcons.turtle),
                          onPressed: isConnected ? decreaseSpeed : null,
                          tooltip: 'Decrease Speed',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(CupertinoIcons.arrow_left, size: 42),
                          onPressed: isConnected ? arrowLeft : null,
                          tooltip: 'Seek 10s Back',
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(CupertinoIcons.arrow_down, size: 42),
                          onPressed: isConnected ? arrowDown : null,
                          tooltip: 'Volume Down',
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon:
                              const Icon(CupertinoIcons.arrow_right, size: 42),
                          onPressed: isConnected ? arrowRight : null,
                          tooltip: 'Seek 10s forward',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.closed_caption_outlined),
                          onPressed: isConnected ? toggleSubtitle : null,
                          tooltip: 'Subtitles',
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(MaterialCommunityIcons.rabbit),
                          onPressed: isConnected ? increaseSpeed : null,
                          tooltip: 'Increase Speed',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 22),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.backward_end_alt),
                  onPressed: isConnected ? previousVideo : null,
                  tooltip: 'Previous Media in Playlist',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.play),
                  onPressed: isConnected ? playVideo : null,
                  tooltip: 'Play',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.stop),
                  onPressed: isConnected ? stopVideo : null,
                  tooltip: 'Stop',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.forward_end_alt),
                  onPressed: isConnected ? nextVideo : null,
                  tooltip: 'Next Media in Playlist',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.speaker_slash),
                  onPressed: isConnected ? mute : null,
                  tooltip: 'Mute',
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Padding _buildPresentationControl(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(
              'Gyro',
              style: Theme.of(context).textTheme.headline6,
            ),
            trailing: CupertinoSwitch(
              value: isGyroOn,
              onChanged: (isOn) => accelerometerControl(isOn),
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.maxFinite,
            child: Row(
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (dragUpdate) => zoom(dragUpdate),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 8.0),
                    child: Container(
                      height: MediaQuery.of(context).size.height - 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          HoldDetector(
                            onHold: () => zoom(DragUpdateDetails(
                                delta: Offset(0.0, -1.0),
                                globalPosition: null)),
                            holdTimeout: Duration(milliseconds: 200),
                            enableHapticFeedback: true,
                            child: IconButton(
                              onPressed: () => zoom(DragUpdateDetails(
                                  delta: Offset(0.0, -1.0),
                                  globalPosition: null)),
                              icon: Icon(
                                CupertinoIcons.zoom_in,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          HoldDetector(
                            onHold: () => zoom(DragUpdateDetails(
                                delta: Offset(0.0, 1.0), globalPosition: null)),
                            holdTimeout: Duration(milliseconds: 200),
                            enableHapticFeedback: true,
                            child: IconButton(
                              onPressed: () => zoom(DragUpdateDetails(
                                  delta: Offset(0.0, 1.0),
                                  globalPosition: null)),
                              icon: Icon(
                                CupertinoIcons.zoom_out,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
                isGyroOn
                    ? Expanded(
                        child: HoldDetector(
                          onHold: () => setState(() {
                            _onHold = true;
                          }),
                          onCancel: () => setState(() {
                            _onHold = false;
                          }),
                          onTap: () => leftClickMouse(),
                          holdTimeout: Duration(milliseconds: 200),
                          enableHapticFeedback: true,
                          child: TouchArea(
                            dx: dx,
                            dy: dy,
                          ),
                        ),
                      )
                    : Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => leftClickMouse(),
                          onDoubleTap: () => {
                            doubleTapped = true,
                            print('Double Tapped'),
                          },
                          onScaleUpdate: _condition
                              ? (dragUpdate) => onScale(dragUpdate)
                              : null,
                          onScaleEnd: (scaleEndDetails) => onScaleEnd(),
                          child: TouchArea(
                            dx: dx,
                            dy: dy,
                          ),
                        ),
                      ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (dragUpdate) => scroll(dragUpdate),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 8.0),
                    child: Container(
                      height: MediaQuery.of(context).size.height - 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          HoldDetector(
                            onHold: () => scroll(DragUpdateDetails(
                                delta: Offset(0.0, -1.0),
                                globalPosition: null)),
                            holdTimeout: Duration(milliseconds: 200),
                            enableHapticFeedback: true,
                            child: IconButton(
                              onPressed: () => scroll(DragUpdateDetails(
                                  delta: Offset(0.0, -1.0),
                                  globalPosition: null)),
                              icon: Icon(
                                Icons.arrow_drop_up,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          HoldDetector(
                            onHold: () => scroll(DragUpdateDetails(
                                delta: Offset(0.0, 1.0), globalPosition: null)),
                            holdTimeout: Duration(milliseconds: 200),
                            enableHapticFeedback: true,
                            child: IconButton(
                              onPressed: () => scroll(DragUpdateDetails(
                                  delta: Offset(0.0, 1.0),
                                  globalPosition: null)),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          trailing: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
                icon: const Icon(CupertinoIcons.square_arrow_right),
                onPressed: isConnected
                    ? () => _sendStringToType(
                        presentatioonTextEditingController.text)
                    : null),
          ),
          title: TextField(
            controller: presentatioonTextEditingController,
            decoration: InputDecoration(
              hintText: (isConnecting
                  ? 'Wait until connected...'
                  : isConnected
                      ? 'Type on PC...'
                      : 'BT got disconnected'),
              hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
              fillColor: Theme.of(context).dialogBackgroundColor,
              filled: true,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            enabled: isConnected,
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Container(
          height: kBottomNavigationBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.device_desktop),
                  onPressed: isConnected ? present : null,
                  tooltip: 'Present from beginning',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.device_laptop),
                  onPressed: isConnected ? presentCurrent : null,
                  tooltip: 'Present from current slide',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: isConnected ? arrowLeft : null,
                  tooltip: 'Next slide',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: isConnected ? arrowRight : null,
                  tooltip: 'Previous slide',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: isConnected ? exit : null,
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        )
      ]),
    );
  }

  void close() {
    if (isConnected) {
      _streamSubscription = null;

      setState(() {
        isConnected = false;
      });

      print('we are disconnecting locally!');
    }
  }

  void present() {
    _sendMessage("*#*F5*@*");
  }

  void exit() {
    _sendMessage("*#*esc*@*");
  }

  void presentCurrent() {
    _sendMessage("*#*SHIFT+F5*@*");
  }

  void _onDataReceived(Uint8List data) {
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(_Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index)));
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) {
    if (text != null) {
      text = text.trim();
      if (text.length > 0) {
        presentatioonTextEditingController.clear();
        _bluetoothConnection.output.add(ascii.encode(text + "\r\n"));
      }
    }
  }

  directionChanged(double degrees, double distance) {
    print(degrees.toString() + " " + distance.toString());
    _sendMessage(
        "*#*JOYSTICK" + degrees.toString() + " " + distance.toString() + "*@*");
  }

  bool _leftClick = false;
  bool _dragEnabled = false;
  leftClickMouse() {
    print("Left Click");
    _sendMessage("*#*LC*@*");
  }

  onPan(DragUpdateDetails dragUpdate) {
    print("Cordinates:${dragUpdate.delta}");
  }

  scroll(DragUpdateDetails dragUpdate) {
    _sendMessage("*#*SCROLL${dragUpdate.delta.dy.toString()}*@*");
    print(dragUpdate);
  }

  zoom(DragUpdateDetails dragUpdate) {
    _sendMessage("*#*ZOOM${dragUpdate.delta.dy.toString()}*@*");
    print(dragUpdate);
  }

  onScale(ScaleUpdateDetails dragUpdate) {
    print(dragUpdate);
    setState(() => _condition = false);
    if (dragUpdate.scale != 1) {
      if (prevScale == 0) {
        prevScale = dragUpdate.scale;
        setState(() => _condition = true);
        return;
      }
      print("${dragUpdate.scale - prevScale}");
      _sendMessage("*#*ZOOM${dragUpdate.scale - prevScale}*@*");
      prevScale = dragUpdate.scale;
      setState(() => _condition = true);
      return;
    }
    if (prevFocalPoint == null) {
      prevFocalPoint = dragUpdate.focalPoint;
      setState(() => _condition = true);
      return;
    }

    double halfWidth = (MediaQuery.of(context).size.width) / 2;
    double halfHeight = (MediaQuery.of(context).size.height) / 2;
    setState(() => {
          dx = (dragUpdate.focalPoint.dx - halfWidth) / halfWidth,
          dy = (dragUpdate.focalPoint.dy - halfHeight) / halfHeight,
        });

    _dragEnabled = _leftClick;
    _sendMessage(
        "*#*${(_leftClick ? 'DRAG' : '') + (dragUpdate.focalPoint - prevFocalPoint).toString()}*@*");
    prevFocalPoint = dragUpdate.focalPoint;
    setState(() => _condition = true);
  }

  onScaleEnd() {
    _sendMessage(_dragEnabled ? "*#*DRAGENDED*@*" : null);
    _dragEnabled = false;
    _leftClick = false;
    prevFocalPoint = null;
    doubleTapped = false;
    prevScale = 0;
    setState(() {
      dx = 0;
      dy = 0;
    });
  }

  Offset prevFocalPoint;
  double prevScale;

  _sendStringToType(String text) {
    _sendMessage("*#*TYPE$text*@*");
  }

  void accelerometerControl(bool isOn) {
    setState(() {
      this.isGyroOn = isOn;
    });
  }

  void playVideo() {
    _sendMessage("*#*SPACE*@*");
  }

  void previousVideo() {
    _sendMessage("*#*SINGLEKEY+P*@*");
  }

  void nextVideo() {
    _sendMessage("*#*SINGLEKEY+N*@*");
  }

  void stopVideo() {
    _sendMessage("*#*SINGLEKEY+S*@*");
  }

  void toggleFullScreen() {
    _sendMessage("*#*SINGLEKEY+F*@*");
  }

  void arrowUp() {
    _sendMessage("*#*UP*@*");
  }

  void arrowRight() {
    _sendMessage("*#*RIGHT*@*");
  }

  void arrowDown() {
    _sendMessage("*#*DOWN*@*");
  }

  void arrowLeft() {
    _sendMessage("*#*LEFT*@*");
  }

  void mute() {
    _sendMessage("*#*SINGLEKEY+M*@*");
  }

  void toggleSubtitle() {
    _sendMessage("*#*SINGLEKEY+V*@*");
  }

  void decreaseSpeed() {
    _sendMessage("*#*SINGLEKEY+[*@*");
  }

  void increaseSpeed() {
    _sendMessage("*#*SINGLEKEY+]*@*");
  }

  openNewWindow() {
    _sendMessage("*#*CTRL+ALT+T*@*");
  }

  openNewTab() {
    _sendMessage("*#*CTRL+SHIFT+T*@*");
  }

  clearTerminal() {
    _sendMessage("*#*CTRL+L*@*");
  }

  cancelTerminalProcess() {
    _sendMessage("*#*CTRL+C*@*");
  }

  closeTab() {
    _sendStringToType("exit");
    _sendMessage("*#*ENTER*@*");
  }
}

class TouchArea extends StatelessWidget {
  TouchArea({this.dx, this.dy});
  final double dx, dy;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: MediaQuery.of(context).size.width * (4 / 6) - 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: RadialGradient(
            center: Alignment.center,
            colors: [
              Color(0xff676767),
              Color(0xff676772),
            ],
          ),
        ),
      ),
    );
  }
}
