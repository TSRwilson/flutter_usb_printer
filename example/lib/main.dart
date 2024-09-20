import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> devices = [];                                
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  bool connected = false;
  int? connectedVendorId;
  int? connectedProductId;

  @override
  initState() {
    super.initState();
    _getDevicelist();
  }

  // Fetch the list of USB devices
  _getDevicelist() async {
    List<Map<String, dynamic>> results = [];
    results = await FlutterUsbPrinter.getUSBDeviceList();

    print(" length: ${results.length}");
    setState(() {
      devices = results;
    });
  }

  // Connect to a specific USB device
  _connect(int vendorId, int productId) async {
    bool? returned = false;
    try {
      returned = await flutterUsbPrinter.connect(vendorId, productId);
    } on PlatformException {
      print('Failed to connect to USB device.');
    }
    if (returned!) {
      setState(() {
        connected = true;
        connectedVendorId = vendorId;
        connectedProductId = productId;
      });
    }
  }

  // Close the connection to the specific USB device
  _closeConnection() async {
    if (connectedVendorId != null && connectedProductId != null) {
      try {
        await flutterUsbPrinter.close(connectedVendorId!, connectedProductId!);
        setState(() {
          //connected = false;
          connectedVendorId = null;
          connectedProductId = null;
        });
        print('Connection closed');
      } on PlatformException {
        print('Failed to close the connection.');
      }
    }
  }

  // Print data to the connected USB printer
  _print() async {
    try {
      var data = Uint8List.fromList(
          utf8.encode(" Hello world Testing ESC POS printer..."));
      await flutterUsbPrinter.write(data);
    } on PlatformException {
      print('Failed to print.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('USB PRINTER'),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.refresh), onPressed: _getDevicelist),
            connected == true
                ? IconButton(
                    icon: Icon(Icons.print),
                    onPressed: _print,
                  )
                : Container(),
            connected == true
                ? IconButton(
                    icon: Icon(Icons.close),
                    onPressed: _closeConnection,
                  )
                : Container(),
          ],
        ),
        body: devices.length > 0
            ? ListView(
                scrollDirection: Axis.vertical,
                children: _buildList(devices),
              )
            : Center(child: Text('No USB devices found')),
      ),
    );
  }

  List<Widget> _buildList(List<Map<String, dynamic>> devices) {
    return devices
        .map((device) => ListTile(
              onTap: () {
                _connect(int.parse(device['vendorId']),
                    int.parse(device['productId']));
              },
              leading: Icon(Icons.usb),
              title: Text(device['manufacturer'] + " " + device['productName']),
              subtitle: Text(device['vendorId'] + " " + device['productId']),
            ))
        .toList();
  }
}
