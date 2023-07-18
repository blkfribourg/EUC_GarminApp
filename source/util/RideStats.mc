import Toybox.Lang;
import Toybox.System;
module rideStats {
  var minimalMovingSpeed = 3.0; // 3 kmh
  var distanceSinceStartup;
  var startupDistance as Float?;
  var movingmsec = 0.0;
  var statTimer = 20;

  function avgSpeed() {
    if (eucData.speed > minimalMovingSpeed) {
      if (startupDistance == null) {
        startupDistance = eucData.tripDistance;
      }
      movingmsec = movingmsec + 100;
      eucData.avgMovingSpeed =
        (eucData.tripDistance - startupDistance) / (movingmsec / 3600000.0);
    }
  }

  function topSpeed() {
    if (eucData.speed > eucData.topSpeed) {
      eucData.topSpeed = eucData.speed;
    }
  }
}
