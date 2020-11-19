import 'dart:async';
import 'package:bluetooth_pc_remote/ui/views/all_controls_view.dart';
import 'package:bluetooth_pc_remote/ui/views/paired_devices_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeView createState() => _HomeView();
}

class _HomeView extends State<HomeView> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _name = "...";

  @override
  void initState() {
    super.initState();

    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {});

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth PC Remote'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(
                'Bluetooth Status',
                style: Theme.of(context).textTheme.headline6,
              ),
              trailing: CupertinoSwitch(
                value: _bluetoothState.isEnabled,
                onChanged: (bool value) {
                  future() async {
                    if (value)
                      await FlutterBluetoothSerial.instance.requestEnable();
                    else
                      await FlutterBluetoothSerial.instance.requestDisable();
                  }

                  future().then((_) {
                    setState(() {});
                  });
                },
              ),
            ),
          ),
          SizedBox(
            height: 12,
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(
                _bluetoothState.isEnabled
                    ? "Device Name: $_name"
                    : "Bluetooth Turned Off!",
                style: Theme.of(context).textTheme.headline6.copyWith(
                      color: _bluetoothState.isEnabled
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
              ),
            ),
          ),
          SizedBox(
            height: 12,
          ),
          Visibility(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        trailing: Icon(Icons.arrow_forward_ios),
                        title: Text('Connect to paired PC to Control',
                            style: Theme.of(context).textTheme.subtitle1),
                        onTap: _bluetoothState.isEnabled
                            ? () async {
                                final BluetoothDevice selectedDevice =
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) {
                                  return PairedDevicesView(
                                      checkAvailability: false);
                                }));

                                if (selectedDevice != null) {
                                  print('Connect -> selected ' +
                                      selectedDevice.address);
                                  initConnection(context, selectedDevice);
                                } else {
                                  print('Connect -> no device selected');
                                }
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            visible: _bluetoothState.isEnabled,
          ),
        ],
      ),
    );
  }

  void initConnection(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return AllControlsView(server: server);
    }));
  }
}
