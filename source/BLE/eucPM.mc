using Toybox.BluetoothLowEnergy as Ble;
using Toybox.System as Sys;

class eucPM {
    var EUC_SERVICE = Ble.longToUuid(0x0000FFE000001000L, 0x800000805F9B34FBL); // Begode Tesla V2 :)
	var EUC_CHAR    = Ble.longToUuid(0x0000FFE100001000L, 0x800000805F9B34FBL);    


    private var eucProfileDef = {
        :uuid => EUC_SERVICE,
        :characteristics => [{
            :uuid => EUC_CHAR,
            :descriptors => [Ble.cccdUuid()]
        }]
    };
       

    function registerProfiles() {
		try {      
        	Ble.registerProfile( eucProfileDef );
		} catch(e) {
			System.println("e="+e.getErrorMessage());
		}
    }
}
