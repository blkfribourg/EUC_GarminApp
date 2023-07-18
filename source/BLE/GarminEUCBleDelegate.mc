using Toybox.System as Sys;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as Ui;
import Toybox.Lang;

class eucBLEDelegate extends Ble.BleDelegate {
  var profileManager = null;
  var device = null;
  var settings = 0x0000;
  var service = null;
  var char = null;
  var queue;

  function initialize(pm, q) {
    //Sys.println("initializeBle");
    BleDelegate.initialize();
    profileManager = pm;
    char = profileManager.EUC_CHAR;
    queue = q;
    Ble.setScanState(Ble.SCAN_STATE_SCANNING);
  }

  function onConnectedStateChanged(device, state) {
    //		view.deviceStatus=state;
    if (state == Ble.CONNECTION_STATE_CONNECTED) {
      service = device.getService(profileManager.EUC_SERVICE);
      char =
        service != null
          ? service.getCharacteristic(profileManager.EUC_CHAR)
          : null;
      if (service != null && char != null) {
        var cccd = char.getDescriptor(Ble.cccdUuid());
        cccd.requestWrite([0x01, 0x00]b);
      } else {
        Ble.unpairDevice(device);
      }
    } else {
      Ble.unpairDevice(device);
      Ble.setScanState(Ble.SCAN_STATE_SCANNING);
    }
  }
  //! @param scanResults An iterator of new scan results
  function onScanResults(scanResults as Ble.Iterator) {
    for (
      var result = scanResults.next();
      result != null;
      result = scanResults.next()
    ) {
      if (result instanceof Ble.ScanResult) {
        if (
          contains(result.getServiceUuids(), profileManager.EUC_SERVICE, result)
        ) {
          Ble.setScanState(Ble.SCAN_STATE_OFF);
          device = Ble.pairDevice(result);
        }
      }
    }
  }

  function onDescriptorWrite(desc, status) {}

  function onCharacteristicWrite(desc, status) {}

  function onCharacteristicChanged(char, value) {
    frameBuffer(value);
  }

  function sendCmd(cmd) {
    //Sys.println("enter sending command " + cmd);

    if (service != null && char != null) {
      var enc_cmd = string_to_byte_array(cmd as String);
      //Sys.println("sending command " +enc_cmd.toString());
      char.requestWrite(enc_cmd, { :writeType => Ble.WRITE_TYPE_DEFAULT });
      //  Sys.println("command sent !");
    }
  }

  private function contains(iter, obj, sr) {
    for (var uuid = iter.next(); uuid != null; uuid = iter.next()) {
      if (uuid.equals(obj)) {
        return true;
      }
    }
    return false;
  }
  /*
    hidden function string_to_byte_array(plain_text) {
    var options = {
		:fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
        :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
        :encoding => StringUtil.CHAR_ENCODING_UTF8
    };
    
    //System.println(Lang.format("Converting '$1$' to ByteArray", [ plain_text ]));
    var result = StringUtil.convertEncodedString(plain_text, options);
    //System.println(Lang.format("           '$1$'..", [ result ]));
    
    return result;
}
*/

  function getChar() {
    return char;
  }

  function getPMService() {
    return profileManager.EUC_SERVICE;
  }

  function frameBuffer(transmittedFrame) {
    for (var i = 0; i < transmittedFrame.size(); i++) {
      if (checkChar(transmittedFrame[i]) == true) {
        // process frame and guess type
        if (frame[18].toNumber() == 0) {
          // Frame A
          //System.println("Frame A detected");
          processFrameA(frame);
        } else if (frame[18].toNumber() == 4) {
          // Frame B
          //System.println("Frame B detected");
          processFrameB(frame);
        }
      }
    }
  }

  // adapted from wheellog
  var oldc;
  var frame as ByteArray?;
  var state = "unknown";
  function checkChar(c) {
    if (state.equals("collecting")) {
      frame.add(c);
      oldc = c;

      var size = frame.size();

      if (
        (size == 20 && c.toNumber() != 24) ||
        (size > 20 && size <= 24 && c.toNumber() != 90)
      ) {
        state = "unknown";
        return false;
      }

      if (size == 24) {
        state = "done";
        return true;
      }
    } else {
      if (oldc != null && oldc.toNumber() == 85 && c.toNumber() == 170) {
        // beguining of a frame
        frame = new [0]b;
        frame.add(85);
        frame.add(170);
        state = "collecting";
      }
      oldc = c;
    }
    return false;
  }

  function processFrameB(value) {
    eucData.totalDistance =
      value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
        :offset => 2,
        :endianness => Lang.ENDIAN_BIG,
      }) / 1000.0; // in km
    settings = value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
      :offset => 6,
      :endianness => Lang.ENDIAN_BIG,
    });

    //Sys.println("byte 10 :"+settings);

    eucData.pedalMode = (settings >> 13) & 0x03;
    eucData.speedAlertMode = (settings >> 10) & 0x03;
    eucData.rollAngleMode = (settings >> 7) & 0x03;
    //System.println("read angle mode: "+(settings>>7)&0x03);
    //eucData.speedUnitMode  = value[10]&0x1;
    eucData.ledMode = value[13].toNumber(); // 12 in euc dashboard by freestyl3r
    //eucData.lightMode=value[19]&0x03; unable to get light mode from wheel
    //System.println("light mode (frameA ):"+eucData.lightMode);
  }
  function processFrameA(value) {
    eucData.speed =
      (value
        .decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 4,
          :endianness => Lang.ENDIAN_BIG,
        })
        .abs() *
        3.6) /
      100;
    eucData.voltage =
      value
        .decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 2,
          :endianness => Lang.ENDIAN_BIG,
        })
        .abs() / 100.0;
    eucData.tripDistance =
      value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
        :offset => 6,
        :endianness => Lang.ENDIAN_BIG,
      }) / 1000.0; //in km
    eucData.Phcurrent =
      value
        .decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 10,
          :endianness => Lang.ENDIAN_BIG,
        })
        .abs() / 100.0;
    eucData.temperature =
      value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 12,
        :endianness => Lang.ENDIAN_BIG,
      }) /
        340 +
      36.53;
    //eucData.volume=(value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, { :offset => 16 ,:endianness => Lang.ENDIAN_BIG}));
    //eucData.PWM=value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, { :offset => 14 ,:endianness => Lang.ENDIAN_BIG})*10;
    //System.println("PWM data "+ eucData.PWM);
  }
}

/*
    Gotway/Begode reverse-engineered protocol
    Gotway uses byte stream from a serial port via Serial-to-BLE adapter.
    There are two types of frames, A and B. Normally they alternate.
    Most numeric values are encoded as Big Endian (BE) 16 or 32 bit integers.
    The protocol has no checksums.
    Since the BLE adapter has no serial flow control and has limited input buffer,
    data come in variable-size chunks with arbitrary delays between chunks. Some
    bytes may even be lost in case of BLE transmit buffer overflow.



         0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 | 16 17 18 19 20 21 22 23
        -----------------------------------------------------------------------
     A: 55 AA 19 F0 00 00 00 00 00 00 01 2C FD CA 00 01 | FF F8 00 18 5A 5A 5A 5A 
     B: 55 AA 00 0A 4A 12 48 00 1C 20 00 2A 00 03 00 07 | 00 08 04 18 5A 5A 5A 5A
     A: 55 AA 19 F0 00 00 00 00 00 00 00 F0 FD D2 00 01 | FF F8 00 18 5A 5A 5A 5A
     B: 55 AA 00 0A 4A 12 48 00 1C 20 00 2A 00 03 00 07 | 00 08 04 18 5A 5A 5A 5A
        ....
    Frame A:
        Bytes 0-1:   frame header, 55 AA
        Bytes 2-3:   BE voltage, fixed point, 1/100th (assumes 67.2 battery, rescale for other voltages)
        Bytes 4-5:   BE speed, fixed point, 3.6 * value / 100 km/h
        Bytes 6-9:   BE distance, 32bit fixed point, meters
        Bytes 10-11: BE current, signed fixed point, 1/100th amperes
        Bytes 12-13: BE temperature, (value / 340 + 36.53) / 100, Celsius degrees (MPU6050 native data)
        Bytes 14-17: unknown
        Byte  18:    frame type, 00 for frame A
        Byte  19:    18 frame footer
        Bytes 20-23: frame footer, 5A 5A 5A 5A
    Frame B:
        Bytes 0-1:   frame header, 55 AA
        Bytes 2-5:   BE total distance, 32bit fixed point, meters
        Byte  6:     pedals mode (high nibble), speed alarms (low nibble)
        Bytes 7-12:  unknown
        Byte  13:    LED mode
        Bytes 14-17: unknown
        Byte  18:    frame type, 04 for frame B
        Byte  19:    18 frame footer
        Bytes 20-23: frame footer, 5A 5A 5A 5A
    Unknown bytes may carry out other data, but currently not used by the parser.
*/
