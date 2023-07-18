import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
using Toybox.Timer;
class GarminEUCApp extends Application.AppBase {
  private var view;
  private var delegate;
  private var eucBleDelegate;
  private var queue;
  private var alarmsTimer;
  private var updateDelay = 100;
  private var menu;
  private var menu2Delegate;

  function initialize() {
    AppBase.initialize();
    alarmsTimer = new Timer.Timer();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    alarmsTimer.start(method(:onUpdateTimer), updateDelay, true);
    menu = new Rez.Menus.MainMenu();
    eucData.setSettings(
      AppStorage.getSetting("rotationSpeed_PWM"),
      AppStorage.getSetting("rotationVoltage_PWM"),
      AppStorage.getSetting("powerFactor_PWM"),
      AppStorage.getSetting("voltageCorrectionFactor"),
      AppStorage.getSetting("actionButton")
    );
    rideStats.movingmsec = 0;
  }

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {}

  // Return the initial view of your application here
  function getInitialView() as Array<Views or InputDelegates>? {
    queue = new BleQueue();
    var profileManager = new eucPM();

    if (Toybox has :BluetoothLowEnergy) {
      eucBleDelegate = new eucBLEDelegate(profileManager, queue);
      BluetoothLowEnergy.setDelegate(eucBleDelegate);
      profileManager.registerProfiles();
    }
    view = new GarminEUCView();

    menu2Delegate = new GarminEUCMenu2Delegate(
      menu,
      eucBleDelegate,
      queue,
      view
    );

    delegate = new GarminEUCDelegate(
      view,
      menu,
      menu2Delegate,
      eucBleDelegate,
      queue
    );

    return [view, delegate] as Array<Views or InputDelegates>;
  }
  // Timer callback for various alarms & update UI
  function onUpdateTimer() {
    EUCAlarms.speedAlarmCheck(eucData.getCalculatedtPWM());
    if (menu2Delegate.requestSubLabelsUpdate == true) {
      menu2Delegate.updateSublabels();
    }
    rideStats.avgSpeed();
    rideStats.topSpeed();

    WatchUi.requestUpdate();
  }
}

function getApp() as GarminEUCApp {
  return Application.getApp() as GarminEUCApp;
}
