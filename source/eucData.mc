using Toybox.System;

module eucData {
  // Calculated PWM variables :
  // PLEASE UPDATE WITH YOU OWN VALUES BEFORE USE !
  var rotationSpeed; // cutoff speed when freespin test performed
  var powerFactor; // 0.9 for better safety
  var rotationVoltage; // voltage when freespin test performed
  var updateDelay;
  var alarmThreshold_PWN;
  var alarmThreshold_speed;
  var actionButton;
  var speedCorrectionFactor; // correct distance aswell ...
  var calculatedPWM = 0.0;
  var deviceName = null;
  var voltage_scaling;
  var speed = 0.0;
  var correctedSpeed = 0.0;
  var voltage = 0;
  var lowestBatteryPercentage = 101;
  var tripDistance = 0.0;
  var Phcurrent = 0;
  var temperature = 0;
  var maxTemperature = 65;
  var totalDistance = 0;
  var PWM = 0;
  var pedalMode = "0";
  var speedAlertMode = "0";
  var rollAngleMode = "0";
  var speedUnitMode = 0;
  var ledMode = "0";
  var avgMovingSpeed = 0.0;
  var topSpeed = 0.0;
  var watchBatteryUsage = 0.0;
  //var volume="1";
  //var lightMode="0";

  // dict for status report

  // no lights & volume "feedback" on tesla v2
  /*
        var dictLightStatus ={
            "On" => "0",
            "Off" => "1",
            "Flashing" => "2"
        };
        */
  var dictPedalStatus = {
    "Hard" => "2",
    "Medium" => "1",
    "Soft" => "0",
  };
  var dictAlarmStatus = {
    "PWM only" => "2",
    "35Kmh + PWM" => "1",
    "30Kmh + PWM" => "0",
  };
  /* No angle status feedback
        var dictCutoffAngleStatus={
            "High" => "2",
            "Medium" => "1",
            "Low" => "0"
        };
*/

  //dict for communication
  var dictLightsMode = {
    "On" => "Q",
    "Off" => "E",
    "Flashing" => "T",
  };
  var dictPedalMode = {
    "Hard" => "h",
    "Medium" => "f",
    "Soft" => "s",
  };
  var dictAlarmMode = {
    "PWM only" => "i",
    "35Kmh + PWM" => "u",
    "30Kmh + PWM" => "o",
  };
  var dictCutoffAngleMode = {
    "High" => "<",
    "Medium" => "=",
    "Low" => ">",
  };

  // dict for communication & status report
  var dictLedMode = {
    "0" => "0",
    "1" => "1",
    "2" => "2",
    "3" => "3",
    "4" => "4",
  };
  var dictVolume = {
    "1" => "1",
    "2" => "2",
    "3" => "3",
    "4" => "4",
    "5" => "5",
    "6" => "6",
    "7" => "7",
    "8" => "8",
    "9" => "9",
  };

  function getBatteryPercentage() {
    var battery = 0;
    // using better battery formula from wheellog :
    if (voltage > 66.8) {
      battery = 100.0;
    } else if (voltage > 54.4) {
      battery = (voltage - 53.8) / 0.13;
    } else if (voltage > 52.9) {
      battery = (voltage - 52.9) / 0.325;
    } else {
      battery = 0.0;
    }
    return battery;
  }
  function setSettings(
    _updateDelay,
    _rotationSpeed,
    _rotationVoltage,
    _powerFactor,
    _voltageFactor,
    _speedCorrectionFactor,
    _actionButton,
    _alarmThreshold_PWN,
    _alarmThreshold_speed
  ) {
    updateDelay = _updateDelay;
    rotationSpeed = _rotationSpeed;
    rotationVoltage = _rotationVoltage;
    powerFactor = _powerFactor;
    voltage_scaling = _voltageFactor;
    speedCorrectionFactor = _speedCorrectionFactor;
    actionButton = _actionButton;
    alarmThreshold_PWN = _alarmThreshold_PWN;
    alarmThreshold_speed = _alarmThreshold_speed;
  }
  function getCalculatedtPWM() {
    if (eucData.voltage != 0) {
      var CalculatedPWM =
        eucData.speed.toFloat() /
        ((rotationSpeed / rotationVoltage) *
          eucData.voltage.toFloat() *
          eucData.voltage_scaling *
          powerFactor);
      return CalculatedPWM * 100;
    } else {
      return 0;
    }
  }
  function getCorrectedSpeed() {
    return speed * speedCorrectionFactor.toFloat();
  }
}
