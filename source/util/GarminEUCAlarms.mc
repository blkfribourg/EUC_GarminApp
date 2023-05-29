import Toybox.Attention;
import Toybox.Lang;
using Toybox.System;




module EUCAlarms {
    function alarmHandler(alarmType) {
       
            Attention.vibrate(alarmsArray[alarmType]);
        
    }

    var alarmsArray = [
       [ new Attention.VibeProfile(100, 100), new Attention.VibeProfile(0, 300), new Attention.VibeProfile(100, 100) ], //  PWM >80 & <85 %
       [ new Attention.VibeProfile(100, 200), new Attention.VibeProfile(0, 100), new Attention.VibeProfile(100, 200) ]  //  PWM >85 %
    ];


function speedAlarmCheck(current_PWM){
    System.println("checking for alarm :"+current_PWM );
    if (Attention has :vibrate) {
        if (current_PWM > 80 && current_PWM < 85) {
            EUCAlarms.alarmHandler(0);
    }
    if (current_PWM > 85) {
       EUCAlarms.alarmHandler(1);
    }


}
}






 

}