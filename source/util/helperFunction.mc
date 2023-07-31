import Toybox.Lang;
using Toybox.StringUtil;
using Toybox.Math;

// convert string to byte, used when sending string command via BLE
function string_to_byte_array(plain_text) {
  var options = {
    :fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
    :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
    :encoding => StringUtil.CHAR_ENCODING_UTF8,
  };
  var result = StringUtil.convertEncodedString(plain_text, options);
  return result;
}

//Just a round function with formating
function valueRound(value, format) {
  var rounded;
  rounded = Math.round(value * 100) / 100;
  return rounded.format(format);
}

//Returns the EUC settings class from the selected EUC brand
function getEUCSettingsDict() {
  if (eucData.wheelBrand == 0) {
    return new gotwayConfig();
  }
  if (eucData.wheelBrand == 1) {
    return null;
  }
  if (eucData.wheelBrand == 2) {
    return null;
  } else {
    return null;
  }
}

// Generate Main Settings Menu
import Toybox.WatchUi;
function createSettingsMenu(settingsLabels, title) {
  var menu = new WatchUi.Menu2({ :title => title });

  if (settingsLabels != null) {
    for (var i = 0; i < settingsLabels.size(); i++) {
      menu.addItem(new MenuItem(settingsLabels[i], "", settingsLabels[i], {}));
    }
    return menu;
  }
  return null;
}
