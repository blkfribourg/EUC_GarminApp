import Toybox.ActivityRecording;
using Toybox.FitContributor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Timer;

class ActivityRecordDelegate extends WatchUi.BehaviorDelegate {
  private var _view as ActivityRecordView;

  //! Constructor
  //! @param view The app view
  public function initialize(view as ActivityRecordView) {
    BehaviorDelegate.initialize();
    _view = view;
  }

  //! On menu event, start/stop recording
  //! @return true if handled, false otherwise
  public function onMenu() as Boolean {
    return true;
  }

  function onKey(keyEvent) {
    if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
      if (Toybox has :ActivityRecording) {
        if (!_view.isSessionRecording()) {
          _view.startRecording();
        } else {
          _view.stopRecording();
        }
      }
    }

    return true;
  }

  function onPreviousPage() {
    // WatchUi.switchToView(main_view, main_delegate, WatchUi.SLIDE_UP); // Switch to
    WatchUi.popView(WatchUi.SLIDE_UP);
    return true;
  }
}

class ActivityRecordView extends WatchUi.View {
  private var accuracy = [
    "not available",
    "last know GPS fix",
    "Poor GPS fix",
    "Usable GPS fix",
    "Good GPS fix",
  ];
  private var accuracy_msg = "";
  private var running = false;
  private var fitTimer;
  private var _session as Session?;

  //! Constructor
  public function initialize() {
    View.initialize();
    if (fitTimer == null) {
      fitTimer = new Timer.Timer();
    }
  }

  //! Stop the recording if necessary
  public function stopRecording() as Void {
    running = false;
    var session = _session;
    if (
      Toybox has :ActivityRecording &&
      isSessionRecording() &&
      session != null
    ) {
      session.stop();
      session.save();
      _session = null;
      WatchUi.requestUpdate();
    }
    if (fitTimer != null) {
      fitTimer.stop();
    }
  }

  //! Start recording a session
  public function startRecording() as Void {
    running = true;
    _session = ActivityRecording.createSession({
      :name => "EUC riding",
      :sport => ActivityRecording.SPORT_GENERIC,
    });
    _session.start();
    setupField(_session);
    resetVariables();
    if (fitTimer != null) {
      fitTimer.start(method(:updateFitData), 1000, true);
    }
    WatchUi.requestUpdate();
  }

  //! Load your resources here
  //! @param dc Device context
  public function onLayout(dc as Dc) as Void {}

  //! Called when this View is removed from the screen. Save the
  //! state of this View here. This includes freeing resources from
  //! memory.
  public function onHide() as Void {
    if (running == false) {
      //System.println("Stopping sensors");
      Position.enableLocationEvents(
        Position.LOCATION_DISABLE,
        method(:onPosition)
      );
    }
  }

  //! Restore the state of the app and prepare the view to be shown.
  public function onShow() as Void {
    //System.println("starting sensors");
    Position.enableLocationEvents(
      Position.LOCATION_CONTINUOUS,
      method(:onPosition)
    );
  }
  function onPosition(info as Info) as Void {
    System.println("check gps:" + info.accuracy);
    accuracy_msg = accuracy[info.accuracy];
  }
  //! Update the view
  //! @param dc Device context
  public function onUpdate(dc as Dc) as Void {
    // Set background color
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.drawText(
      dc.getWidth() / 2,
      0,
      Graphics.FONT_XTINY,
      "GPS:\n" + accuracy_msg,
      Graphics.TEXT_JUSTIFY_CENTER
    );

    if (Toybox has :ActivityRecording) {
      // Draw the instructions
      if (!isSessionRecording()) {
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(
          dc.getWidth() / 2,
          dc.getHeight() / 2,
          Graphics.FONT_MEDIUM,
          "Press OK to\nStart Recording",
          Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
      } else {
        var x = dc.getWidth() / 2;
        var y = dc.getFontHeight(Graphics.FONT_XTINY) * 2;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.drawText(
          x,
          y,
          Graphics.FONT_MEDIUM,
          "Recording...",
          Graphics.TEXT_JUSTIFY_CENTER
        );
        y += dc.getFontHeight(Graphics.FONT_MEDIUM);
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(
          x,
          y,
          Graphics.FONT_MEDIUM,
          "Press OK again\nto Stop and Save\nthe Recording",
          Graphics.TEXT_JUSTIFY_CENTER
        );
      }
    } else {
      // tell the user this sample doesn't work
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
      dc.drawText(
        dc.getWidth() / 2,
        dc.getWidth() / 2,
        Graphics.FONT_MEDIUM,
        "This product doesn't\nhave FIT Support",
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }
  }

  //! Get whether a session is currently recording
  //! @return true if there is a session currently recording, false otherwise
  public function isSessionRecording() as Boolean {
    if (_session != null) {
      return _session.isRecording();
    }
    return false;
  }

  // Field ID from resources.
  const SPEED_FIELD_ID = 0;
  const PWM_FIELD_ID = 1;
  const VOLTAGE_FIELD_ID = 2;
  const CURRENT_FIELD_ID = 3;
  const TEMP_FIELD_ID = 4;
  const TRIPDISTANCE_FIELD_ID = 5;
  const MAXSPEED_FIELD_ID = 6;
  const MAXPWM_FIELD_ID = 7;
  const MAXCURRENT_FIELD_ID = 8;
  const MAXPOWER_FIELD_ID = 9;
  const MAXTEMP_FIELD_ID = 10;
  const AVGSPEED_FIELD_ID = 11;
  hidden var mSpeedField;
  hidden var mPWMField;
  hidden var mVoltageField;
  hidden var mCurrentField;
  hidden var mTempField;
  hidden var mTripDistField;
  hidden var mMaxSpeedField;
  hidden var mMaxPWMField;
  hidden var mMaxCurrentField;
  hidden var mMaxPowerField;
  hidden var mMaxTempField;
  hidden var mAvgSpeedField;

  // Initializes the new fields in the activity file
  function setupField(session as Session) {
    mSpeedField = session.createField(
      "current_speed",
      SPEED_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "km/h" }
    );
    mPWMField = session.createField(
      "current_PWM",
      PWM_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "%" }
    );
    mVoltageField = session.createField(
      "current_Voltage",
      VOLTAGE_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "V" }
    );
    mCurrentField = session.createField(
      "current_Current",
      CURRENT_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "A" }
    );
    mTempField = session.createField(
      "current_Temperature",
      TEMP_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "°C" }
    );
    mTripDistField = session.createField(
      "current_TripDistance",
      TRIPDISTANCE_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "km" }
    );
    mMaxSpeedField = session.createField(
      "session_Max_speed",
      MAXSPEED_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "km/h" }
    );
    mMaxPWMField = session.createField(
      "session_Max_PWM",
      MAXPWM_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "%" }
    );
    mMaxCurrentField = session.createField(
      "session_Max_Current",
      MAXCURRENT_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "A" }
    );
    mMaxTempField = session.createField(
      "session_Max_Temperature",
      MAXTEMP_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "°C" }
    );
    mAvgSpeedField = session.createField(
      "session_Avg_Speed",
      AVGSPEED_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "km/h" }
    );
  }
  private var maxSpeed;
  private var maxPWM;
  private var maxCurrent;
  private var maxTemp;
  private var runningsec;
  private var currentPWM;

  function updateFitData() {
    //System.println("compute called");
    currentPWM = eucData.getCalculatedtPWM();
    mSpeedField.setData(eucData.speed);
    mPWMField.setData(currentPWM);
    mVoltageField.setData(eucData.voltage * eucData.voltage_scaling);
    mCurrentField.setData(eucData.current);
    mTempField.setData(eucData.temperature);
    mTripDistField.setData(eucData.tripDistance);

    if (eucData.speed > maxSpeed) {
      maxSpeed = eucData.speed;
      mMaxSpeedField.setData(maxSpeed);
    }
    if (currentPWM > maxPWM) {
      maxPWM = currentPWM;
      mMaxPWMField.setData(maxPWM);
    }
    if (eucData.current > maxCurrent) {
      maxCurrent = eucData.current;
      mMaxCurrentField.setData(maxCurrent);
    }
    if (eucData.temperature > maxTemp) {
      maxTemp = eucData.temperature;
      mMaxTempField.setData(maxTemp);
    }
    if (runningsec > 0) {
      mAvgSpeedField.setData(eucData.tripDistance / (runningsec / 3600));
    }

    runningsec++;
    WatchUi.requestUpdate();
  }

  function resetVariables() {
    maxSpeed = 0.0;
    maxPWM = 0.0;
    maxCurrent = 0.0;
    maxTemp = -255;
    runningsec = 0.0;
  }
}
