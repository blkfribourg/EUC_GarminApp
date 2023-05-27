import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GarminEUCApp extends Application.AppBase {
    private var view;
    private var delegate;
    private var eucBleDelegate;
    private var queue;
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        queue=new BleQueue();
        var profileManager = new eucPM();     
        
   		if(Toybox has :BluetoothLowEnergy) {
   			//view.hasBle=true;
			//BluetoothLowEnergy.setDelegate(new eucBLEDelegate(euc,profileManager));
            
            eucBleDelegate= new eucBLEDelegate(profileManager,queue);
            BluetoothLowEnergy.setDelegate(eucBleDelegate);   	
        	profileManager.registerProfiles();
        }       
        view=new GarminEUCView();
        delegate=new GarminEUCDelegate(view,eucBleDelegate,queue);
        return [ view, delegate ] as Array<Views or InputDelegates>;
        //return [ new GarminEUCView(), new GarminEUCDelegate() ] as Array<Views or InputDelegates>;
       
        // for test :
    
    }

}

function getApp() as GarminEUCApp {
    return Application.getApp() as GarminEUCApp;
}