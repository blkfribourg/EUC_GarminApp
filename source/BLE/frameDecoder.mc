import Toybox.Lang;
using Toybox.BluetoothLowEnergy as Ble;

module frameDecoder {
  function init() {
    if (eucData.wheelBrand.equals("0")) {
      return new GwDecoder();
    }
    if (eucData.wheelBrand.equals("1")) {
      return new VeteranDecoder();
    }
    if (eucData.wheelBrand.equals("2")) {
      return new KingsongDecoder();
    } else {
      return null;
    }
  }
}
class GwDecoder {
  var settings = 0x0000;
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
    if (state.equals("collecting") && frame != null) {
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
    eucData.useMiles = settings & 0x01;
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
}

class VeteranDecoder {
  function frameBuffer(transmittedFrame) {
    for (var i = 0; i < transmittedFrame.size(); i++) {
      if (checkChar(transmittedFrame[i]) == true) {
        processFrame(frame);
      }
    }
  }

  // adapted from wheellog
  var old1 = 0;
  var old2 = 0;
  var len = 0;

  var frame as ByteArray?;
  var state = "unknown";
  function checkChar(c) {
    if (state.equals("collecting") && frame != null) {
      var size = frame.size();

      if (
        ((size == 22 || size == 30) && c.toNumber() != 0) ||
        (size == 23 && (c & 0xfe).toNumber != 0) ||
        (size == 31 && (c & 0xfc).toNumber() != 0)
      ) {
        state = "done";
        reset();
        return false;
      }
      frame.add(c);
      if (size == len + 3) {
        state = "done";
        reset();
        return true;
      }
      // break;
    }
    if (state.equals("lensearch")) {
      frame.add(c);
      len = c & 0xff;
      state = "collecting";
      old2 = old1;
      old1 = c;
      //break;
    } else {
      if (c.toNumber() == 92 && old1.toNumber() == 90 && old2 == 220) {
        frame = new [0]b;
        frame.add(92);
        frame.add(90);
        frame.add(220);
        state = "lensearch";
      } else if (c.toNumber() == 90 && old1 == 220) {
        old2 = old1;
      } else {
        old2 = 0;
      }
      old1 = c;
    }
    return false;
  }
  function reset() {
    old1 = 0;
    old2 = 0;
    state = "unknown";
  }

  function processFrame(value) {
    eucData.voltage = value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
      :offset => 4,
      :endianness => Lang.ENDIAN_BIG,
    });
    eucData.speed =
      value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 6,
        :endianness => Lang.ENDIAN_BIG,
      }) * 10;
    eucData.tripDistance = value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
      :offset => 8,
      :endianness => Lang.ENDIAN_BIG,
    });
    eucData.totalDistance = value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
      :offset => 12,
      :endianness => Lang.ENDIAN_BIG,
    });
    eucData.Phcurrent =
      value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 16,
        :endianness => Lang.ENDIAN_BIG,
      }) * 10;
    eucData.temperature = value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
      :offset => 18,
      :endianness => Lang.ENDIAN_BIG,
    });
    // implement chargeMode/speedAlert/speedTiltback later
    eucData.version = value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
      :offset => 28,
      :endianness => Lang.ENDIAN_BIG,
    });
  }
}

class KingsongDecoder {
  var char;
  function setChar(_char) {
    char = _char;
  }

  function requestName(char) {
    var data = getEmptyRequest();
    data[16] = 155;
    char.requestWrite(data, { :writeType => Ble.WRITE_TYPE_DEFAULT });
  }
  function requestSerial(char) {
    var data = getEmptyRequest();
    data[16] = 99;
    char.requestWrite(data, { :writeType => Ble.WRITE_TYPE_DEFAULT });
  }
  function getEmptyRequest() {
    return [
      0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0x5a, 0x5a,
    ]b;
  }

  function processFrame(value, char) {
    if (eucData.KSName == null) {
      requestName(char);
    } else if (eucData.KSSerial == null) {
      requestSerial(char);
    }

    if (value.size() >= 20) {
      var a1 = value[0] & 255;
      var a2 = value[1] & 255;
      if (a1 != 170 || a2 != 85) {
        return false;
      }
      if ((value[16] & 255) == 0xa9) {
        // Live data
        var voltage = value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 2,
          :endianness => Lang.ENDIAN_BIG,
        });
        eucData.voltage = voltage; //wd.setVoltage(voltage);

        eucData.speed = value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 4,
          :endianness => Lang.ENDIAN_BIG,
        });

        if (
          eucData.model.equals("KS-18L") &&
          eucData.KS18L_scale_toggle == true
        ) {
          eucData.totalDistance =
            0.83 *
            value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
              :offset => 6,
              :endianness => Lang.ENDIAN_BIG,
            });
        } else {
          eucData.totalDistance = value.decodeNumber(
            Lang.NUMBER_FORMAT_UINT32,
            {
              :offset => 6,
              :endianness => Lang.ENDIAN_BIG,
            }
          );
        }
        eucData.totalDistance = value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
          :offset => 12,
          :endianness => Lang.ENDIAN_BIG,
        });
        eucData.current = (value[10] & 0xff) + (value[11] << 8);
        eucData.temperature = value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 12,
          :endianness => Lang.ENDIAN_BIG,
        });

        if ((value[15] & 255) == 224) {
          var mMode = value[14]; // don't know what it is
        }
        return true;
      } else if ((value[16] & 255) == 0xb9) {
        // Distance/Time/Fan Data
        eucData.tripDistance = value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
          :offset => 2,
          :endianness => Lang.ENDIAN_BIG,
        });
        eucData.fanStatus = value[12];
        eucData.chargingStatus = value[13];
        eucData.temperature2 = value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 14,
          :endianness => Lang.ENDIAN_BIG,
        });
      } else if ((value[16] & 255) == 187) {
        // Name and Type data
        var end = 0;
        var i = 0;
        while (i < 14 && value[i + 2] != 0) {
          end++;
          i++;
        }
        var name = value.toString().substring(2, end);
        var model = "";
        var ss = splitstr(name, "-");
        for (i = 0; i < ss.size() - 1; i++) {
          if (i != 0) {
            model = model + "-";
          }
          model = model + ss[i];
        }
        System.println("name:" + name);
        System.println("model:" + model);
      } else if ((value[16] & 255) == 0xf5) {
        //cpu load
        eucData.cpuLoad = value[14];
        eucData.output = value[15] * 100;
        return false;
      } else if ((value[16] & 255) == 0xf6) {
        //speed limit (PWM?)
        eucData.speedLimit =
          value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
            :offset => 2,
            :endianness => Lang.ENDIAN_BIG,
          }) / 100.0;
        return false;
      } else if ((value[16] & 255) == 0xa4 || (value[16] & 255) == 0xb5) {
        //max speed and alerts
        eucData.KSMaxSpeed = value[10] & 255;

        eucData.KSAlarm3Speed = value[8] & 255;
        eucData.KSAlarm2Speed = value[6] & 255;
        eucData.KSAlarm1Speed = value[4] & 255;

        // after received 0xa4 send same repeat data[2] =0x01 data[16] = 0x98
        if ((value[16] & 255) == 164) {
          value[16] = 0x98;
          char.requestWrite(value, { :writeType => Ble.WRITE_TYPE_DEFAULT });
        }
        return true;
      } else if ((value[16] & 255) == 0xf1 || (value[16] & 255) == 0xf2) {
        // F1 - 1st BMS, F2 - 2nd BMS. F3 and F4 are also present but empty
      } else if ((value[16] & 255) == 0xe1 || (value[16] & 255) == 0xe2) {
        // e1 - 1st BMS, e2 - 2nd BMS.
      } else if ((value[16] & 255) == 0xe5 || (value[16] & 255) == 0xe6) {
        // e5 - 1st BMS, e6 - 2nd BMS.
      }
    }
    return false;
  }
}
