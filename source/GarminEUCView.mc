import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Math;
using Toybox.System;
class GarminEUCView extends WatchUi.View {
    private var cDrawables = {};
    private var timer;
  

    function initialize() {
        View.initialize();

        timer = new Timer.Timer();

    }

function onLayout(dc as Dc) as Void {
  setLayout(Rez.Layouts.HomeLayout(dc));
        
        // Label drawables
        cDrawables[:TimeDate] = View.findDrawableById("TimeDate");
        cDrawables[:SpeedNumber] = View.findDrawableById("SpeedNumber");
        cDrawables[:BatteryNumber] = View.findDrawableById("BatteryNumber");
        cDrawables[:TemperatureNumber] = View.findDrawableById("TemperatureNumber");
        cDrawables[:BottomSubtitle] = View.findDrawableById("BottomSubtitle");
        // And arc drawables
        cDrawables[:SpeedArc] = View.findDrawableById("SpeedDial");
        cDrawables[:BatteryArc] = View.findDrawableById("BatteryArc");
        cDrawables[:TemperatureArc] = View.findDrawableById("TemperatureArc");

    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        var CurrentTime = System.getClockTime(); 
        cDrawables[:TimeDate].setText(
            CurrentTime.hour.format("%d") +
            ":" +
            CurrentTime.min.format("%02d")
        );

         cDrawables[:TimeDate].setColor(Graphics.COLOR_WHITE);
          timer.start(method(:onTimerUpdate), 100, true);    
    }

    // Update the view
    function onUpdate(dc) {
    	
        // Update label drawables
        cDrawables[:TimeDate].setText( // Update time
            System.getClockTime().hour.format("%d") +
            ":" +
            System.getClockTime().min.format("%02d")
        );
        var batteryPercentage=eucData.getBatteryPercentage();
        cDrawables[:BatteryNumber].setText(valueRound(batteryPercentage,"%.1f")+"%");
        cDrawables[:TemperatureNumber].setText(valueRound(eucData.temperature,"%.1f").toString()+"°C");

       /* TO Implement later
            switch (AppStorage.getSetting("BottomSubtitleData")) {
                case 0: cDrawables[:BottomSubtitle].setText(WheelData.wheelModel); break;
                case 1: cDrawables[:BottomSubtitle].setText(Lang.format("$1$% / $2$%", [WheelData.pwm, WheelData.maxPwm])); break;
                case 2: cDrawables[:BottomSubtitle].setText(Lang.format("$1$ / $2$", [WheelData.averageSpeed, WheelData.topSpeed])); break;
                case 3: cDrawables[:BottomSubtitle].setText(WheelData.rideTime); break;
                case 4: cDrawables[:BottomSubtitle].setText(WheelData.rideDistance.toString()); break;
            }
        */
        cDrawables[:SpeedNumber].setText(valueRound(eucData.speed,"%.1f").toString());
        
        //cDrawables[:SpeedArc].setValues(WheelData.currentSpeed.toFloat(), WheelData.speedLimit);
        cDrawables[:SpeedArc].setValues(eucData.getCalculatedtPWM().toFloat(), 100);
        cDrawables[:BatteryArc].setValues(batteryPercentage, 100);
        cDrawables[:TemperatureArc].setValues(eucData.temperature, eucData.maxTemperature);

      
            cDrawables[:TimeDate].setColor(Graphics.COLOR_WHITE);
            cDrawables[:SpeedNumber].setColor(Graphics.COLOR_WHITE);
            cDrawables[:BatteryNumber].setColor(Graphics.COLOR_WHITE);
            cDrawables[:TemperatureNumber].setColor(Graphics.COLOR_WHITE);
            cDrawables[:BottomSubtitle].setColor(Graphics.COLOR_WHITE);
        

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }
     function valueRound(value,format){
        var rounded;
        rounded=Math.round(value*100)/100;
        return rounded.format(format);
    }




/* old layout

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        cDrawables[:speed_val] = View.findDrawableById("speed_val");
        cDrawables[:voltage_val] = View.findDrawableById("voltage_val");
        cDrawables[:distance_val] = View.findDrawableById("distance_val");
        cDrawables[:current_val] = View.findDrawableById("current_val");
        cDrawables[:temperature_val] = View.findDrawableById("temperature_val");
        cDrawables[:totalDistance_val] = View.findDrawableById("totalDistance_val");
        cDrawables[:pedalMode_val] = View.findDrawableById("pedalMode_val");
        cDrawables[:speedAlert_val] = View.findDrawableById("speedAlert_val");
        cDrawables[:ledMode_val] = View.findDrawableById("ledMode_val");
        //prompt = View.findDrawableById("prompt");
    }

*/
















/*


    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        timer.start(method(:onTimerUpdate), 100, true);    
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        updateReadings();
       
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }
*/
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }
    
// Timer callback
    function onTimerUpdate(){
		//System.println("onUpdate");
		//eucData.speed=eucData.speed+1;
        WatchUi.requestUpdate();

	}

    // Timer callback
    function onTimerStop(){
		//System.println("onTimerStop");
		if (timer != null){
			timer.stop();
		}
	}
}
