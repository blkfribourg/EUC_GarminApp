import Toybox.Lang;
import Toybox.System;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;

class GarminEUCMenu2Delegate extends WatchUi.Menu2InputDelegate {
  var eucBleDelegate = null;
  var queue = null;
  var parent_menu = null;
  var menu as CheckboxMenu?;
  var delay = 200;
  var updateDelay = 500;
  var main_view;
  var main_delegate;
  var delayUpdate;

  function initialize(
    current_menu,
    current_eucBleDelegate,
    q,
    m_view,
    m_delegate
  ) {
    parent_menu = current_menu;
    eucBleDelegate = current_eucBleDelegate;
    queue = q;
    Menu2InputDelegate.initialize();
    main_view = m_view;
    main_delegate = m_delegate;
    delayUpdate = new Timer.Timer();
    updateSublabels();
  }
  function onBack() {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
    delayUpdate.stop();
  }
  function onSelect(item) {
    //System.println(item.getId().toString());
    if (item.getId() == :lightsModeMenu) {
      nestedMenu("Lights", eucData.dictLightsMode);
    }

    if (item.getId() == :pedalModeMenu) {
      nestedMenu("Pedal Mode", eucData.dictPedalMode);
    }
    if (item.getId() == :alarmModeMenu) {
      nestedMenu("Speed Alarm", eucData.dictAlarmMode);
    }
    if (item.getId() == :cutoffAngleMenu) {
      nestedMenu("Cutoff Angle", eucData.dictCutoffAngleMode);
    }
    if (item.getId() == :ledModeMenu) {
      nestedMenu("Leds Mode", eucData.dictLedMode);
    }
    if (item.getId() == :volumeMenu) {
      nestedMenu("Beep Volume", eucData.dictVolume);
    }
  }

  function nestedMenu(title, paramsdict) {
    // var menu = new WatchUi.Menu2({:title=>title});
    menu = new WatchUi.CheckboxMenu({ :title => title });
    var delegate;
    var menuKeys = paramsdict.keys();
    var menuVals = paramsdict.values();
    for (var i = 0; i < paramsdict.size(); i++) {
      menu.addItem(
        new CheckboxMenuItem(menuKeys[i], "", menuVals[i], false, {})
      );
    }
    delegate = new GarminEUCsubMenu2Delegate(
      title,
      parent_menu,
      self,
      eucBleDelegate,
      queue
    ); // a WatchUi.Menu2InputDelegate
    WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
    delayUpdate.stop();
    return true;
  }

  function updateSublabels() {
    var menuToUpdate = parent_menu;
    // System.println("call update labels");
    var valuesToUpdate = [
      eucData.dictLedMode.keys()[
        eucData.dictLedMode.values().indexOf(eucData.ledMode.toString())
      ],
      eucData.dictAlarmStatus.keys()[
        eucData.dictAlarmStatus
          .values()
          .indexOf(eucData.speedAlertMode.toString())
      ],
      eucData.dictPedalStatus.keys()[
        eucData.dictPedalStatus.values().indexOf(eucData.pedalMode.toString())
      ],
    ];

    if (menuToUpdate != null) {
      for (var i = 0; i < valuesToUpdate.size(); i++) {
        menuToUpdate.getItem(i + 1).setSubLabel(valuesToUpdate[i].toString()); // i+1 -> skipping first item (lights as no feedback on tesla)
      }
    }
  }
  function uniqueCheck(parentMenuTitle, item) {
    //System.println(parentMenuTitle);
    if (parentMenuTitle.equals("Lights")) {
      uncheckExeptItem(item, eucData.dictLightsMode);
    }

    if (parentMenuTitle.equals("Pedal Mode")) {
      uncheckExeptItem(item, eucData.dictPedalMode);
    }
    if (parentMenuTitle.equals("Speed Alarm")) {
      uncheckExeptItem(item, eucData.dictAlarmMode);
    }
    if (parentMenuTitle.equals("Cutoff Angle")) {
      uncheckExeptItem(item, eucData.dictCutoffAngleMode);
    }
    if (parentMenuTitle.equals("Leds Mode")) {
      uncheckExeptItem(item, eucData.dictLedMode);
    }
    if (parentMenuTitle.equals("Beep Volume")) {
      uncheckExeptItem(item, eucData.dictVolume);
    }
    //System.println(item.getId());
  }
  function uncheckExeptItem(item, paramsdict) {
    for (var i = 0; i < paramsdict.size(); i++) {
      if (item != menu.getItem(i)) {
        var tempItem = menu.getItem(i) as CheckboxMenuItem;
        tempItem.setChecked(false);
      }
    }
  }
  function execute(parentMenuTitle) {
    if (parentMenuTitle.equals("Lights")) {
      findChecked(parentMenuTitle, eucData.dictLightsMode);
    }

    if (parentMenuTitle.equals("Pedal Mode")) {
      findChecked(parentMenuTitle, eucData.dictPedalMode);
    }
    if (parentMenuTitle.equals("Speed Alarm")) {
      findChecked(parentMenuTitle, eucData.dictAlarmMode);
    }
    if (parentMenuTitle.equals("Cutoff Angle")) {
      findChecked(parentMenuTitle, eucData.dictCutoffAngleMode);
    }
    if (parentMenuTitle.equals("Leds Mode")) {
      findChecked(parentMenuTitle, eucData.dictLedMode);
    }
    if (parentMenuTitle.equals("Beep Volume")) {
      findChecked(parentMenuTitle, eucData.dictVolume);
    }
  }

  function findChecked(parentMenuTitle, paramsdict) {
    for (var i = 0; i < paramsdict.size(); i++) {
      var tempItem = menu.getItem(i) as CheckboxMenuItem;
      if (tempItem.isChecked()) {
        sendCommand(parentMenuTitle, tempItem.getId().toString());
      }
    }
  }
  function sendCommand(fromMenu, cmd) {
    var command = null;
    var enc_cmd = null;

    if (fromMenu.equals("Leds Mode")) {
      command = "W";
      enc_cmd = string_to_byte_array(command as String);

      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
      command = "M";
      enc_cmd = string_to_byte_array(command as String);

      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
      command = cmd;
      enc_cmd = string_to_byte_array(command as String);
      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
    }
    if (fromMenu.equals("Beep Volume")) {
      command = "W";
      enc_cmd = string_to_byte_array(command as String);

      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
      command = "B";
      enc_cmd = string_to_byte_array(command as String);

      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
      command = cmd;
      enc_cmd = string_to_byte_array(command as String);
      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
    } else {
      eucBleDelegate.sendCmd(cmd);
    }
    queue.delayTimer.start(method(:timerCallback), delay, true);
    delayUpdate.start(method(:labelUpdate), updateDelay, true);
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
 //   System.println(Lang.format("           '$1$'..", [ result ]));
    
    return result;
 }
*/
  function timerCallback() {
    queue.run();
  }

  function labelUpdate() {
    updateSublabels();
    WatchUi.requestUpdate();
  }
}

/*
//! Custom menu adapted from garmin sdk samples, I was using an icon to identify currently selected item but not showing on my garmin venu -> switched to checkbox items for menu
class CustomEucMenu extends WatchUi.CustomMenu {
    var title="";
    //! Constructor
    //! @param itemHeight The pixel height of menu items rendered by this menu
    //! @param backgroundColor The color for the menu background
    public function initialize(itemHeight as Number, backgroundColor as ColorValue,titleToShow) {
        CustomMenu.initialize(itemHeight, backgroundColor, {:titleItemHeight=>20});
        title=titleToShow;
    }

    //! Draw the menu title
    //! @param dc Device Context
    public function drawTitle(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        dc.setPenWidth(3);
        dc.drawLine(0, dc.getHeight() - 2, dc.getWidth(), dc.getHeight() - 2);
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_TINY, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}
//! This is the custom item drawable.
//! It draws the label it is initialized with at the center of the region
class CustomItem extends WatchUi.CustomMenuItem {

    private var _label as String;
    private var _textColor as ColorValue;

    //! Constructor
    //! @param id The identifier for this item
    //! @param label Text to display
    //! @param textColor Color of the text
    public function initialize(id as Symbol, label as String, textColor as ColorValue) {
        CustomMenuItem.initialize(id, {});
        _label = label;
        _textColor = textColor;
    }

    //! Draw the item string at the center of the item.
    //! @param dc Device Context
    public function draw(dc as Dc) as Void {
        var check_bitmap=WatchUi.loadResource($.Rez.Drawables.Check);
        var font = Graphics.FONT_SMALL;
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_WHITE);
        dc.clear();

        if (isSelected()) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
            dc.clear();
            dc.drawBitmap(40, (dc.getHeight() / 2)-20, check_bitmap);
        }
        
        dc.setColor(_textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, font, _label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

     
}
*/
