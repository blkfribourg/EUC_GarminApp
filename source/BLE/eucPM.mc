using Toybox.BluetoothLowEnergy as Ble;
using Toybox.System as Sys;

class eucPM {
  var EUC_SERVICE = Ble.longToUuid(0x0000ffe000001000l, 0x800000805f9b34fbl); // Begode Tesla V2 :)
  var EUC_CHAR = Ble.longToUuid(0x0000ffe100001000l, 0x800000805f9b34fbl);

  private var eucProfileDef = {
    :uuid => EUC_SERVICE,
    :characteristics => [
      {
        :uuid => EUC_CHAR,
        :descriptors => [Ble.cccdUuid()],
      },
    ],
  };

  function registerProfiles() {
    try {
      Ble.registerProfile(eucProfileDef);
    } catch (e) {
      System.println("e=" + e.getErrorMessage());
    }
  }
}
