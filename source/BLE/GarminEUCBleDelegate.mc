using Toybox.System as Sys;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as Ui;
import Toybox.Lang;

class eucBLEDelegate extends Ble.BleDelegate {
  var profileManager = null;
  var device = null;
  var service = null;
  var char = null;
  var queue;
  var paired = false;
  var decoder = null;

  function initialize(pm, q, _decoder) {
    //Sys.println("initializeBle");
    BleDelegate.initialize();
    profileManager = pm;
    char = profileManager.EUC_CHAR;
    queue = q;
    decoder = _decoder;
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
        paired = true;
      } else {
        Ble.unpairDevice(device);
        paired = false;
      }
    } else {
      Ble.unpairDevice(device);
      Ble.setScanState(Ble.SCAN_STATE_SCANNING);
      paired = false;
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
    if (decoder != null) {
      decoder.frameBuffer(value);
    }
  }

  function sendCmd(cmd) {
    //Sys.println("enter sending command " + cmd);

    if (service != null && char != null && cmd != "") {
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
