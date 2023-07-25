import Toybox.Attention;
import Toybox.Lang;
using Toybox.System;

module EUCAlarms {
  var alarmDelay = 0;
  var alarmType = "none";
  function alarmHandler(intensity, duration) {
    Attention.vibrate([new Attention.VibeProfile(intensity, duration)]);
  }

  function speedAlarmCheck() {
    //PWN alarm
    if (Attention has :vibrate && eucData.alarmThreshold_PWN != 0) {
      if (
        eucData.calculatedPWM > eucData.alarmThreshold_PWN &&
        eucData.calculatedPWM < eucData.alarmThreshold_PWN + 5 &&
        alarmDelay <= 0
      ) {
        EUCAlarms.alarmHandler(100, 300);
        alarmDelay = 1000 / eucData.updateDelay;
        alarmType = "PWM";
      }
      if (
        eucData.calculatedPWM > eucData.alarmThreshold_PWN + 5 &&
        alarmDelay <= 0
      ) {
        EUCAlarms.alarmHandler(100, 100);
        alarmDelay = 200 / eucData.updateDelay;
        alarmType = "PWM";
      }
      if (eucData.calculatedPWM < eucData.alarmThreshold_PWN) {
        alarmDelay = 0;
        alarmType = "none";
      } else {
        alarmDelay--;
      }
    }
    //Speed alarm
    if (Attention has :vibrate && eucData.alarmThreshold_speed != 0) {
      if (
        eucData.correctedSpeed > eucData.alarmThreshold_speed &&
        alarmDelay <= 0 &&
        alarmType != "PWM"
      ) {
        // PWM alarm have priority over speed alarm
        EUCAlarms.alarmHandler(100, 300);
        alarmDelay = 1000 / eucData.updateDelay;
        alarmType = "speed";
      }
      if (eucData.correctedSpeed < eucData.alarmThreshold_speed) {
        alarmDelay = 0;
        alarmType = "none";
      } else {
        alarmDelay--;
      }
    }
  }
}
