import Toybox.Attention;
import Toybox.Lang;
using Toybox.System;

module EUCAlarms {
  var alarmDelay = 0;
  function alarmHandler(intensity, duration) {
    Attention.vibrate([new Attention.VibeProfile(intensity, duration)]);
  }

  function speedAlarmCheck(current_PWM) {
    if (Attention has :vibrate) {
      if (current_PWM > 80 && current_PWM < 85 && alarmDelay <= 0) {
        EUCAlarms.alarmHandler(100, 300);
        alarmDelay = 10;
      }
      if (current_PWM > 85 && alarmDelay <= 0) {
        EUCAlarms.alarmHandler(100, 100);
        alarmDelay = 2;
      }
      if (current_PWM < 80) {
        alarmDelay = 0;
      } else {
        alarmDelay--;
      }
    }
  }
}
