import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Application;
using Toybox.Math;

class HomeView extends WatchUi.View {

    private var cDrawables = {};
	
    function initialize() {
        View.initialize();
        
    }

    // Load your resources here
    function onLayout(dc) {
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

       /*
        if (!WheelData.isAppConnected) {
            WheelData.setIsAppConnected(false);
        }

        AppStorage.runtimeDb["comm_dataSource"] = "home";
        */
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
        cDrawables[:BatteryNumber].setText(valueRound(batteryPercentage)+"%");
        cDrawables[:TemperatureNumber].setText(valueRound(eucData.temperature).toString()+"°C");

       /* TO Implement later
            switch (AppStorage.getSetting("BottomSubtitleData")) {
                case 0: cDrawables[:BottomSubtitle].setText(WheelData.wheelModel); break;
                case 1: cDrawables[:BottomSubtitle].setText(Lang.format("$1$% / $2$%", [WheelData.pwm, WheelData.maxPwm])); break;
                case 2: cDrawables[:BottomSubtitle].setText(Lang.format("$1$ / $2$", [WheelData.averageSpeed, WheelData.topSpeed])); break;
                case 3: cDrawables[:BottomSubtitle].setText(WheelData.rideTime); break;
                case 4: cDrawables[:BottomSubtitle].setText(WheelData.rideDistance.toString()); break;
            }
        */
        cDrawables[:SpeedNumber].setText(valueRound(eucData.speed).toString());
        
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
     function valueRound(value){
        var rounded;
        rounded=Math.round(value*100)/100;
        return rounded.format("%.2f");
    }


    function onHide() {

    }	
}