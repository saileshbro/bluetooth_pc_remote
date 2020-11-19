import 'dart:async';
import 'package:bluetooth_pc_remote/ui/widgets/bluetooth_device_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class PairedDevicesView extends StatefulWidget {
  final bool checkAvailability;

  const PairedDevicesView({this.checkAvailability = false});

  @override
  _PairedDevicesView createState() => _PairedDevicesView();
}

enum DeviceAvailability {
  no,
  maybe,
  yes,
}

class DeviceWithAvailability extends BluetoothDevice {
  BluetoothDevice device;
  DeviceAvailability availability;
  int rssi;

  DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}

class _PairedDevicesView extends State<PairedDevicesView> {
  List<DeviceWithAvailability> devices = List<DeviceWithAvailability>();

  StreamSubscription<BluetoothDiscoveryResult> _discoveryStreamSubscription;
  bool _isDiscovering;

  _PairedDevicesView();

  @override
  void initState() {
    super.initState();

    _isDiscovering = widget.checkAvailability;

    if (_isDiscovering) {
      _startDiscovery();
    }

    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        devices = bondedDevices
            .map((device) => DeviceWithAvailability(
                device,
                widget.checkAvailability
                    ? DeviceAvailability.maybe
                    : DeviceAvailability.yes))
            .toList();
      });
    });
  }

  void _restartDiscovery() {
    setState(() {
      _isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    Permission.locationAlways.status.then((value) {
      print(value);
      if (value.isUndetermined || value.isDenied) {
        Permission.locationAlways.request().then((value) {
          if (value.isGranted) {
            _discoveryStreamSubscription =
                FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
              print(r);
              setState(() {
                Iterator i = devices.iterator;
                while (i.moveNext()) {
                  var _device = i.current;
                  if (_device.device == r.device) {
                    _device.availability = DeviceAvailability.yes;
                    _device.rssi = r.rssi;
                  }
                }
              });
            });
          } else {
            _discoveryStreamSubscription =
                FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
              print(r);
              setState(() {
                Iterator i = devices.iterator;
                while (i.moveNext()) {
                  var _device = i.current;
                  if (_device.device == r.device) {
                    _device.availability = DeviceAvailability.yes;
                    _device.rssi = r.rssi;
                  }
                }
              });
            });
          }
        });
      }
    });

    _discoveryStreamSubscription?.onDone(() {
      print("finished");
      setState(() {
        _isDiscovering = false;
      });
    });
  }

  @override
  void dispose() {
    _discoveryStreamSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<BluetoothDeviceEntry> list = devices
        .map((_device) => BluetoothDeviceEntry(
              device: _device.device,
              rssi: _device.rssi,
              enabled: _device.availability == DeviceAvailability.yes,
              onTap: () {
                Navigator.of(context).pop(_device.device);
              },
            ))
        .toList();
    return Scaffold(
        appBar: AppBar(
          title: Text('Select device'),
          actions: <Widget>[
            (_isDiscovering
                ? FittedBox(
                    child: Container(
                        margin: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white))))
                : IconButton(
                    icon: Icon(Icons.replay), onPressed: _restartDiscovery))
          ],
        ),
        body: ListView(children: list));
  }
}
