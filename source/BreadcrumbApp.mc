import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Timer;
import Toybox.Position;
import Toybox.Graphics;

var globalExceptionCounter as Number = 0;
var sourceMustBeNativeColorFormatCounter as Number = 0;

enum /* Protocol */ {
    // PROTOCOL_ROUTE_DATA = 0, - removed in favour of PROTOCOL_ROUTE_DATA2, users must update companion app
    // PROTOCOL_MAP_TILE = 1, - removed watch has pulled tiles from phone rather than phone pushing for a while
    PROTOCOL_REQUEST_LOCATION_LOAD = 2,
    PROTOCOL_RETURN_TO_USER = 3,
    PROTOCOL_REQUEST_SETTINGS = 4,
    PROTOCOL_SAVE_SETTINGS = 5,
    PROTOCOL_COMPANION_APP_TILE_SERVER_CHANGED = 6, // generally because a new url has been selected on the companion app
    PROTOCOL_ROUTE_DATA2 = 7, // an optimised form of PROTOCOL_ROUTE_DATA, so we do not trip the watchdog
    PROTOCOL_CACHE_CURRENT_AREA = 8,
}

enum /* ProtocolSend */ {
    PROTOCOL_SEND_OPEN_APP = 0,
    PROTOCOL_SEND_SETTINGS = 1,
}

class CommStatus extends Communications.ConnectionListener {
    function initialize() {
        Communications.ConnectionListener.initialize();
    }
    function onComplete() {
        logT("App start message sent");
    }

    function onError() {
        logT("App start message fail");
    }
}

class SettingsSent extends Communications.ConnectionListener {
    function initialize() {
        Communications.ConnectionListener.initialize();
    }
    function onComplete() {
        logT("Settings sent");
    }

    function onError() {
        logT("Settings send failed");
    }
}

(:glance)
class MyGlanceView extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var height = dc.getHeight();

        // 1. Clear background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.clear();

        // 2. Draw App Title (Breadcrumb)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            0,
            height * 0.3,
            Graphics.FONT_GLANCE,
            "GLANCE BREADCRUMB",
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // 3. Draw Sub-Instruction (Tap to open)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            0,
            height * 0.7,
            Graphics.FONT_GLANCE,
            "Tap to open",
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }
}

var _breadcrumbContext as BreadcrumbContext? = null;
var _view as BreadcrumbView? = null; // set in getInitialView so we do not get Circular dependency detected during initialization between '$' and '$.BreadcrumbDataFieldView'.
var timer as Timer.Timer? = null;

// to get devices and their memory limits
// cd <homedir>/AppData/Roaming/Garmin/ConnectIQ/Devices/
// cat ./**/compiler.json | grep -E '"type": "datafield"|displayName' -B 1
// we currently need 128.5Kb of memory
// for supported image formats of devices
// cat ./**/compiler.json | grep -E 'imageFormats|displayName' -A 5
// looks like if it does not have a key for "imageFormats" the device only supports native formats and "Source must be native color format" if trying to use anything else.
(:glance)
class BreadcrumbApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    (:typecheck(disableGlanceCheck))
    function setupGlobals() as Void {
        if ($._breadcrumbContext != null) {
            return;
        }

        $._breadcrumbContext = new BreadcrumbContext();
        ($._breadcrumbContext as BreadcrumbContext).setup();
        $._view = new BreadcrumbView($._breadcrumbContext as BreadcrumbContext);
        onStartActual();
    }

    (:typecheck(disableGlanceCheck))
    function timerCallback() as Void {
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null) {
            if ($._view != null) {
                $._view.compute(activityInfo);
            }
        }
        // request update every time we update the activity, similar to what data fields do
        WatchUi.requestUpdate();
    }

    (:typecheck(disableGlanceCheck))
    function onPosition(info as Position.Info) as Void {
        // position pulled from timerCallback with Activity.getActivityInfo()
        // but we have to turn it on, otherwise the activity will not always do it for us
    }

    (:typecheck(disableGlanceCheck))
    function onSettingsChanged() as Void {
        try {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal != null) {
                _breadcrumbContextLocal.settings.onSettingsChanged();
            }
        } catch (e) {
            logE("failed onSettingsChange: " + e.getErrorMessage());
            ++$.globalExceptionCounter;
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        if (state != null && state has :launchedFromGlance && state.launchedFromGlance) {
            // see https://forums.garmin.com/developer/connect-iq/f/discussion/401977/glances-and-widgets-user-input
            // and https://pastebin.com/ZZLcz2XC
            return; // nothing special to do when launched from a glance
        }
    }

    (:typecheck(disableGlanceCheck))
    function onStartActual() as Void {
        // simulator seems to crash if we put this in onstart (though real device seems fine?)
        // so adding it when we get the initial view
        System.println("onStartActual");
        if (Communications has :registerForPhoneAppMessages) {
            logT("registering for phone messages");
            Communications.registerForPhoneAppMessages(method(:onPhone));
        }

        if (timer == null) {
            // just make sure it get set
            timer = new Timer.Timer();
            timer.start(method(:timerCallback), 1000, true);
        }

        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    // onStop() is called when your application is exiting
    (:typecheck(disableGlanceCheck))
    function onStop(state as Dictionary?) as Void {
        System.println("onStop");
        // https://forums.garmin.com/developer/connect-iq/f/discussion/872/battery-drain-when-connectiq-app-is-not-running/2006348
        // https://forums.garmin.com/developer/connect-iq/i/bug-reports/bug-battery-drain-after-app-exit-caused-by-activityrecording-api
        var timerLocal = timer;
        if (timerLocal != null) {
            timerLocal.stop();
        }
        timer = null;
        timerLocal = null;

        // suggested by Brian https://forums.garmin.com/developer/connect-iq/f/discussion/872/battery-drain-when-connectiq-app-is-not-running/1661071
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null); //not in the api but good to do if using GPS
        Sensor.unregisterSensorDataListener(); // if using a data listener, unregister
        Sensor.setEnabledSensors([]); // this is in the CIQ api
        Sensor.enableSensorEvents(null); // this is NOT in the CIQ api and is a Garmin bug.
    }

    // Return the initial view of your application here
    (:typecheck(disableGlanceCheck))
    function getInitialView() as [Views] or [Views, InputDelegates] {
        setupGlobals();
        // the initial view is called again when the settings close (sometimes)
        // we also catch this in the 'onUpdate' function in the main view
        if ($._view != null) {
            $._view.allowTaskComputes = true;
        }
        // to open settings to test the simulator has it in an obvious place
        // Settings -> Trigger App Settings (right down the bottom - almost off the screen)
        // then to go back you need to Settings -> Time Out App Settings
        return [
            $._view as BreadcrumbView,
            new BreadcrumbDelegate($._breadcrumbContext as BreadcrumbContext),
        ];
    }

    function getGlanceView() as [WatchUi.GlanceView] or
        [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or
        Null {
        return [new MyGlanceView()];
    }

    (:typecheck(disableGlanceCheck))
    function myGetSettingsView() as [Views, InputDelegates] {
        if ($._view != null) {
            $._view.allowTaskComputes = false;
        }
        if ($._breadcrumbContext != null) {
            $._breadcrumbContext.tileCache.clearValuesWithoutStorage(); // try and use the least amount of memory whilst settings is open
        }
        var settings = new $.SettingsMain();
        return [settings, new $.SettingsMainDelegate(settings)];
    }

    (:typecheck(disableGlanceCheck))
    function onPhone(msg as Communications.PhoneAppMessage) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        try {
            var data = msg.data as Array?;
            if (data == null || !(data instanceof Array) || data.size() < 1) {
                logE("Bad message: " + data);
                mustUpdate();
                return;
            }

            var type = data[0] as Number;
            var rawData = data.slice(1, null);

            if (type == PROTOCOL_ROUTE_DATA2) {
                logT("Parsing route data 2");
                // protocol:
                //  name
                //  [x, y, z]...  // latitude <float> and longitude <float> in rectangular coordinates, altitude <float> - pre calculated by the app
                //  [x, y, angle, index] // direction data - pre calculated all floats
                if (rawData.size() < 2) {
                    logT("Failed to parse route 2 data, bad length: " + rawData.size());
                    mustUpdate();
                    return;
                }

                var name = rawData[0] as String;
                var routeData = rawData[1] as Array<Float>;
                var directions = [] as Array<Number>; // back compat empty array
                if (rawData.size() > 2) {
                    directions = rawData[2] as Array<Number>;
                }
                if (routeData.size() % ARRAY_POINT_SIZE == 0) {
                    var route = _breadcrumbContextLocal.newRoute(name);
                    if (route == null) {
                        logE("Failed to add route");
                        mustUpdate();
                        return;
                    }
                    var routeWrote = route.handleRouteV2(
                        routeData,
                        directions,
                        _breadcrumbContextLocal.cachedValues
                    );
                    logT("Parsing route data 2 complete, wrote to storage: " + routeWrote);
                    if (!routeWrote) {
                        _breadcrumbContextLocal.clearRoute(route.storageIndex);
                    }
                    return;
                }

                logE(
                    "Failed to parse route2 data, bad length: " +
                        rawData.size() +
                        " remainder: " +
                        (rawData.size() % 3)
                );
                mustUpdate();
                return;
            } else if (type == PROTOCOL_REQUEST_LOCATION_LOAD) {
                // logT("parsing req location: " + rawData);
                if (rawData.size() < 2) {
                    logE("Failed to parse request load tile, bad length: " + rawData.size());
                    return;
                }

                var lat = rawData[0] as Float;
                var long = rawData[1] as Float;
                _breadcrumbContextLocal.settings.setFixedPosition(lat, long, true);

                if (rawData.size() >= 3) {
                    // also sets the scale, since user has provided how many meters they want to see
                    // note this ignores the 'restrict to tile layers' functionality
                    var scale = _breadcrumbContextLocal.cachedValues.calcScaleForScreenMeters(
                        rawData[2] as Float
                    );
                    _breadcrumbContextLocal.cachedValues.setScale(scale);
                }
                return;
            } else if (type == PROTOCOL_RETURN_TO_USER) {
                logT("got return to user req: " + rawData);
                _breadcrumbContextLocal.cachedValues.returnToUser();
                return;
            } else if (type == PROTOCOL_REQUEST_SETTINGS) {
                logT("got send settings req: " + rawData);
                var settings = _breadcrumbContextLocal.settings.asDict();
                // logT("sending settings"+ settings);
                _breadcrumbContextLocal.webRequestHandler.transmit(
                    [PROTOCOL_SEND_SETTINGS, settings],
                    {},
                    new SettingsSent()
                );
                return;
            } else if (type == PROTOCOL_SAVE_SETTINGS) {
                logT("got save settings req: " + rawData);
                if (rawData.size() < 1) {
                    logE("Failed to parse save settings request, bad length: " + rawData.size());
                    return;
                }
                _breadcrumbContextLocal.settings.saveSettings(
                    rawData[0] as Dictionary<String, PropertyValueType>
                );
                _breadcrumbContextLocal.settings.onSettingsChanged(); // reload anything that has changed
                return;
            } else if (type == PROTOCOL_COMPANION_APP_TILE_SERVER_CHANGED) {
                // use to just be PROTOCOL_DROP_TILE_CACHE
                logT("got tile cache changed req: " + rawData);
                // they could be using a custom tile server that points to the companion app and has a custom max/min tile layer, we need to clear the cache in this case but not update the tile server settings
                if (!_breadcrumbContextLocal.settings.tileUrl.equals(COMPANION_APP_TILE_URL)) {
                    logT("not using the companion app tile server");
                    return;
                }
                // this is not perfect, some web requests could be about to complete and add a tile to the cache
                // maybe we should go into a backoff period? or just allow manual purge from phone app for if something goes wrong
                // currently tiles have no expiry
                _breadcrumbContextLocal.tileCache._storageTileCache.clearValues();
                _breadcrumbContextLocal.settings.clearTileCache();
                _breadcrumbContextLocal.settings.clearPendingWebRequests();

                if (rawData.size() >= 2) {
                    // also sets the max/min tile layers
                    _breadcrumbContextLocal.settings.companionChangedToMaxMin(
                        rawData[0] as Number,
                        rawData[1] as Number
                    );
                }

                if (rawData.size() >= 4) {
                    _breadcrumbContextLocal.tileCache.updatePalette(
                        rawData[2] as Number?,
                        rawData[3] as Array?
                    );
                }

                return;
            } else if (type == PROTOCOL_CACHE_CURRENT_AREA) {
                // use to just be PROTOCOL_DROP_TILE_CACHE
                logT("got tile cache current area req: " + rawData);

                _breadcrumbContextLocal.cachedValues.startCacheCurrentMapArea();

                return;
            }

            logE("Unknown message type: " + type);
            mustUpdate();
        } catch (e) {
            logE("failed onPhone: " + e.getErrorMessage());
            mustUpdate();
            ++$.globalExceptionCounter;
        }
    }
}

function getApp() as BreadcrumbApp {
    return Application.getApp() as BreadcrumbApp;
}
