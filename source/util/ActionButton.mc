module ActionButton {
  var eucDict = getEUCSettingsDict();
  var lightToggleIndex = 0;
  function triggerAction(bleDelegate) {
    if (bleDelegate != null) {
      if (eucData.actionButton == 0) {
        //do nothing
      }
      if (eucData.actionButton == 1) {
        bleDelegate.sendCmd(eucDict.dictLightsMode.values()[lightToggleIndex]);
        lightToggleIndex = lightToggleIndex + 1;
        if (lightToggleIndex > 2) {
          lightToggleIndex = 0;
        }
      }
    }
  }
}
