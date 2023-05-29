import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System;
class GarminEUCDelegate extends WatchUi.BehaviorDelegate {
  var eucBleDelegate = null;
  var queue = null;
  var menu = null;
  var mainView = null;
  var activityView = null;
  function initialize(main_view, current_eucBleDelegate, q) {
    eucBleDelegate = current_eucBleDelegate;
    queue = q;
    BehaviorDelegate.initialize();
    mainView = main_view;
    activityView = new ActivityRecordView();
  }

  function onMenu() as Boolean {
    var menu = new Rez.Menus.MainMenu();
    WatchUi.pushView(
      menu,
      new GarminEUCMenu2Delegate(menu, eucBleDelegate, queue, mainView, self),
      WatchUi.SLIDE_UP
    );
    return true;
  }

  function onNextPage() as Boolean {
    WatchUi.pushView(
      activityView,
      new ActivityRecordDelegate(activityView),
      WatchUi.SLIDE_UP
    ); // Switch to activity view
    return true;
  }
}
