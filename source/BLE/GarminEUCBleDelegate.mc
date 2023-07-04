using Toybox.System as Sys;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as Ui;
import Toybox.Lang;

class eucBLEDelegate extends Ble.BleDelegate {
  var profileManager = null;
  var device = null;
  var strA = "";
  var strB = "";
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
    var head = new [20]b;
    // I should be buffering the frames tranmitted by the wheels rather than identifying that way because it probably wouldn't work with custom firmwares

    if (value.size() == 20) {
      head = value;

      if (head[11].toNumber() == 0 && head[12].toNumber() == 28) {
        //Frame B
        strB =
          head[11].toString() +
          "," +
          head[12].toString() +
          "," +
          head[13].toString();
        eucData.totalDistance =
          value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
            :offset => 6,
            :endianness => Lang.ENDIAN_BIG,
          }) / 1000; // in km
        settings = value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 10,
          :endianness => Lang.ENDIAN_BIG,
        });

        //Sys.println("byte 10 :"+settings);

        eucData.pedalMode = (settings >> 13) & 0x03;
        eucData.speedAlertMode = (settings >> 10) & 0x03;
        eucData.rollAngleMode = (settings >> 7) & 0x03;
        //System.println("read angle mode: "+(settings>>7)&0x03);
        //eucData.speedUnitMode  = value[10]&0x1;
        eucData.ledMode = value[17].toNumber(); // 12 in euc dashboard by freestyl3r
        //eucData.lightMode=value[19]&0x03; unable to get light mode from wheel
        //System.println("light mode (frameA ):"+eucData.lightMode);
      } else {
        //Frame A
        strA =
          head[4].toString() +
          "," +
          head[5].toString() +
          "," +
          head[6].toString();
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
            .abs() / 100;
        eucData.tripDistance =
          value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
            :offset => 6,
            :endianness => Lang.ENDIAN_BIG,
          }) / 1000; //in km
        eucData.Phcurrent =
          value
            .decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
              :offset => 10,
              :endianness => Lang.ENDIAN_BIG,
            })
            .abs() / 100;
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
     if(value.size()==8){
            // tail frame A and head of frame B nothing here         
        }
    */
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


    Blkfri : Garmin splits in 2 the array because it supports 20 bytes length max. As a result Frame is troncated at byte 19

    Frame B : one of size 20 ranging from 20 to 15 (reading sequence as a loop) -> head 
    Frame B :one of size 8 ranging from 16 to 23 (so there is a redundancy from 20 to 23) -> tail

    The only way to properly determine frame is to rely on "unknown" bytes that do not change on Frame B to guess the frame type -> 00 1C 20 (7 8 9) & 00 07 (14 15) . On my tesla V2 index 9 is not always 20, it's also 1F sometimes so finaly not using index 9 (=13 because of Garmin shift) for checking

    As byte arrays are shifted it means idx 11->13 and 18->19

    check tramB :  00 1C  & 00 07 (14 15)


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
