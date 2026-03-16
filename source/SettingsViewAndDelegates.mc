import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Application;

typedef Renderable as interface {
    function rerender() as Void;
};

(:settingsView)
function startPicker(
    picker as
        SettingsFloatPicker or
            SettingsNumberPicker or
            SettingsColourPickerTransparency or
            TextEditorPicker
) as Void {
    WatchUi.pushView(
        new $.NumberPickerView(picker),
        new $.NumberPickerDelegate(picker),
        WatchUi.SLIDE_IMMEDIATE
    );
}

function safeSetSubLabel(
    menu as WatchUi.Menu2,
    id as Object,
    value as String or ResourceId
) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    item.setSubLabel(value);
}

(:settingsView)
function safeSetLabel(menu as WatchUi.Menu2, id as Object, value as String or ResourceId) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    item.setLabel(value);
}

(:settingsView)
function safeSetToggle(menu as WatchUi.Menu2, id as Object, value as Boolean) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    if (item instanceof WatchUi.ToggleMenuItem) {
        item.setEnabled(value);
    }
}

// https://forums.garmin.com/developer/connect-iq/f/discussion/379406/vertically-center-icon-in-iconmenuitem-using-menu2#pifragment-1298=4
const iconMenuWidthPercent = 0.6;

(:settingsView)
class ColourIcon extends WatchUi.Drawable {
    var colour as Number;

    function initialize(colour as Number) {
        Drawable.initialize({});
        self.colour = colour;
    }

    function draw(dc as Graphics.Dc) {
        var iconWidthHeight;

        // Calculate Width Height of Icon based on drawing area
        if (dc.getHeight() > dc.getWidth()) {
            iconWidthHeight = iconMenuWidthPercent * dc.getHeight();
        } else {
            iconWidthHeight = iconMenuWidthPercent * dc.getWidth();
        }

        dc.setColor(colour, colour);
        dc.fillCircle(dc.getWidth() / 2, dc.getHeight() / 2, iconWidthHeight / 2f);
    }
}

(:settingsView)
function safeSetIcon(menu as WatchUi.Menu2, id as Object, value as WatchUi.Drawable) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    // support was added for icons on menuitems in API Level 3.4.0 but IconMenuItem had it from API 3.0.0
    // MenuItem and IconMenuItem, they both support icons
    if (item has :setIcon) {
        item.setIcon(value);
    }
}

// https://forums.garmin.com/developer/connect-iq/f/discussion/304179/programmatically-set-the-state-of-togglemenuitem
(:settingsView)
class SettingsMain extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.settingsTitle });
        addItem(
            new WatchUi.MenuItem(Rez.Strings.generalSettingsTitle, null, :settingsMainGeneral, {})
        );
        addItem(new WatchUi.MenuItem(Rez.Strings.trackSettingsTitle, null, :settingsMainTrack, {}));
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.dataFieldSettingsTitle,
                null,
                :settingsMainDataField,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.zoomAtPaceTitle, null, :settingsMainZoomAtPace, {})
        );
        addItem(new WatchUi.MenuItem(Rez.Strings.routesTitle, null, :settingsMainRoutes, {}));
        addItem(new WatchUi.MenuItem(Rez.Strings.mapsettingsTitle, null, :settingsMainMap, {}));
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.offTrackAlertsGroupTitle,
                null,
                :settingsMainAlerts,
                {}
            )
        );
        addItem(new WatchUi.MenuItem(Rez.Strings.coloursTitle, null, :settingsMainColours, {}));
        addItem(new WatchUi.MenuItem(Rez.Strings.debugSettingsTitle, null, :settingsMainDebug, {}));
        addItem(
            new WatchUi.MenuItem(Rez.Strings.clearStorage, null, :settingsMainClearStorage, {})
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.returnToUserTitle, null, :settingsMainReturnToUser, {})
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.resetDefaults, null, :settingsMainResetDefaults, {})
        );
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
    }
}

(:noSettingsView)
class SettingsMain extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.settingsTitle });
        addItem(new WatchUi.MenuItem(Rez.Strings.attribution, null, :settingsMapAttribution, {}));
        addItem(
            new WatchUi.MenuItem(Rez.Strings.returnToUserTitle, null, :settingsMainReturnToUser, {})
        );
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
    }
}

function getDataTypeString(type as Number) as ResourceId or String {
    switch (type) {
        case DATA_TYPE_NONE:
            return Rez.Strings.dataTypeNone;
        case DATA_TYPE_SCALE:
            return Rez.Strings.dataTypeScale;
        case DATA_TYPE_ALTITUDE:
            return Rez.Strings.dataTypeAltitude;
        case DATA_TYPE_AVERAGE_HEART_RATE:
            return Rez.Strings.dataTypeAvgHR;
        case DATA_TYPE_AVERAGE_SPEED:
            return Rez.Strings.dataTypeAvgSpeed;
        case DATA_TYPE_CURRENT_HEART_RATE:
            return Rez.Strings.dataTypeCurHR;
        case DATA_TYPE_CURRENT_SPEED:
            return Rez.Strings.dataTypeCurSpeed;
        case DATA_TYPE_ELAPSED_DISTANCE:
            return Rez.Strings.dataTypeDistance;
        case DATA_TYPE_ELAPSED_TIME:
            return Rez.Strings.dataTypeTime;
        case DATA_TYPE_TOTAL_ASCENT:
            return Rez.Strings.dataTypeAscent;
        case DATA_TYPE_TOTAL_DESCENT:
            return Rez.Strings.dataTypeDescent;
        case DATA_TYPE_AVERAGE_PACE:
            return Rez.Strings.dataTypeAvgPace;
        case DATA_TYPE_CURRENT_PACE:
            return Rez.Strings.dataTypeCurPace;
        case DATA_TYPE_WALL_CLOCK:
            return Rez.Strings.dataTypeWallClock;
        case DATA_TYPE_CURRENT_LAP_TIME:
            return Rez.Strings.dataTypeCurLapTime;
        case DATA_TYPE_CURRENT_LAP_PACE:
            return Rez.Strings.dataTypeCurLapPace;
        case DATA_TYPE_LAST_LAP_TIME:
            return Rez.Strings.dataTypeLastLapTime;
        case DATA_TYPE_LAST_LAP_PACE:
            return Rez.Strings.dataTypeLastLapPace;
        case DATA_TYPE_GRADE:
            return Rez.Strings.dataTypeGrade;
        case DATA_TYPE_HEADING:
            return Rez.Strings.dataTypeHeading;
        case DATA_TYPE_GPS_ACCURACY:
            return Rez.Strings.dataTypeGPSAccuracy;
        case DATA_TYPE_CURRENT_LAP_DISTANCE:
            return Rez.Strings.dataTypeCurLapDist;
        default:
            return "";
    }
}

(:settingsView)
function getZoomAtPaceModeString(mode as Number) as ResourceId or String {
    switch (mode) {
        case ZOOM_AT_PACE_MODE_PACE:
            return Rez.Strings.zoomAtPaceModePace;
        case ZOOM_AT_PACE_MODE_STOPPED:
            return Rez.Strings.zoomAtPaceModeStopped;
        case ZOOM_AT_PACE_MODE_NEVER_ZOOM:
            return Rez.Strings.zoomAtPaceModeNever;
        case ZOOM_AT_PACE_MODE_ALWAYS_ZOOM:
            return Rez.Strings.zoomAtPaceModeAlways;
        case ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK:
            return Rez.Strings.zoomAtPaceModeRoutesWithoutTrack;
        default:
            return "";
    }
}

(:settingsView)
class SettingsZoomAtPace extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.zoomAtPaceTitle });
        addItem(
            new WatchUi.MenuItem(Rez.Strings.zoomAtPaceModeTitle, null, :settingsZoomAtPaceMode, {})
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.metersAroundUser,
                null,
                :settingsZoomAtPaceUserMeters,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.zoomAtPaceSpeedMPS, null, :settingsZoomAtPaceMPS, {})
        );
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetSubLabel(
            me,
            :settingsZoomAtPaceMode,
            getZoomAtPaceModeString(settings.zoomAtPaceMode)
        );
        safeSetSubLabel(
            me,
            :settingsZoomAtPaceUserMeters,
            settings.metersAroundUser.toString() + "m"
        );
        safeSetSubLabel(
            me,
            :settingsZoomAtPaceMPS,
            settings.zoomAtPaceSpeedMPS.format("%.2f") + "m/s"
        );
    }
}

(:settingsView)
function getModeString(mode as Number) as ResourceId or String {
    switch (mode) {
        case MODE_NORMAL:
            return Rez.Strings.trackRouteMode;
        case MODE_ELEVATION:
            return Rez.Strings.elevationMode;
        case MODE_MAP_MOVE:
            return Rez.Strings.mapMove;
        case MODE_DEBUG:
            return Rez.Strings.debug;
        case MODE_MAP_MOVE_ZOOM:
            return Rez.Strings.mapMoveZoom;
        case MODE_MAP_MOVE_UP_DOWN:
            return Rez.Strings.mapMoveUD;
        case MODE_MAP_MOVE_LEFT_RIGHT:
            return Rez.Strings.mapMoveLR;
    }

    if (mode >= DATA_PAGE_BASE_ID) {
        return "(" + mode + ") Data Page " + (mode - DATA_PAGE_BASE_ID);
    }

    return "";
}

(:settingsView)
function getUiModeString(mode as Number) as ResourceId or String {
    switch (mode) {
        case UI_MODE_SHOW_ALL:
            return Rez.Strings.uiModeShowAll;
        case UI_MODE_HIDDEN:
            return Rez.Strings.uiModeHidden;
        case UI_MODE_NONE:
            return Rez.Strings.uiModeNone;
        case UI_MODE_SHOW_TOUCH_ONLY:
            return Rez.Strings.uiModeShowTouchOnly;
        case UI_MODE_SHOW_BUTTONS_ONLY:
            return Rez.Strings.uiModeShowButtonsOnly;
        default:
            return "";
    }
}

(:settingsView)
function getElevationModeString(mode as Number) as ResourceId or String {
    switch (mode) {
        case ELEVATION_MODE_STACKED:
            return Rez.Strings.elevationModeStacked;
        case ELEVATION_MODE_ORDERED_ROUTES:
            return Rez.Strings.elevationModeOrderedRoutes;
        default:
            return "";
    }
}

(:settingsView)
function getRenderModeString(mode as Number) as ResourceId or String {
    switch (mode) {
        case RENDER_MODE_BUFFERED_ROTATING:
            return Rez.Strings.renderModeBufferedRotating;
        case RENDER_MODE_UNBUFFERED_ROTATING:
            return Rez.Strings.renderModeUnbufferedRotating;
        case RENDER_MODE_BUFFERED_NO_ROTATION:
            return Rez.Strings.renderModeBufferedNoRotating;
        case RENDER_MODE_UNBUFFERED_NO_ROTATION:
            return Rez.Strings.renderModeNoBufferedNoRotating;
        default:
            return "";
    }
}

(:settingsView)
class SettingsGeneral extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.generalSettingsTitle });
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.modeDisplayOrderTitle,
                null,
                :settingsGeneralModeDisplayOrder,
                {}
            )
        );
        addItem(new WatchUi.MenuItem(Rez.Strings.modeTitle, null, :settingsGeneralMode, {}));
        addItem(
            new WatchUi.MenuItem(Rez.Strings.uiModeTitle, null, :settingsGeneralModeUiMode, {})
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.elevationModeTitle,
                null,
                :settingsGeneralModeElevationMode,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.recalculateIntervalSTitle,
                null,
                :settingsGeneralRecalculateIntervalS,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.renderModeTitle, null, :settingsGeneralRenderMode, {})
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.centerUserOffsetYTitle,
                null,
                :settingsGeneralCenterUserOffsetY,
                {}
            )
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.displayLatLongTitle,
                null,
                :settingsGeneralDisplayLatLong,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.useStartForStopTitle,
                null,
                :settingsGeneralUseStartForStop,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.mapMoveScreenSizeTitle,
                null,
                :settingsGeneralMapMoveScreenSize,
                {}
            )
        );
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;

        safeSetSubLabel(
            me,
            :settingsGeneralModeDisplayOrder,
            Settings.encodeCSV(settings.modeDisplayOrder)
        );
        safeSetSubLabel(me, :settingsGeneralMode, getModeString(settings.mode));
        safeSetSubLabel(me, :settingsGeneralModeUiMode, getUiModeString(settings.uiMode));
        safeSetSubLabel(
            me,
            :settingsGeneralModeElevationMode,
            getElevationModeString(settings.elevationMode)
        );
        safeSetSubLabel(
            me,
            :settingsGeneralRecalculateIntervalS,
            settings.recalculateIntervalS.toString()
        );
        safeSetSubLabel(me, :settingsGeneralRenderMode, getRenderModeString(settings.renderMode));
        safeSetSubLabel(
            me,
            :settingsGeneralCenterUserOffsetY,
            settings.centerUserOffsetY.format("%.2f")
        );
        safeSetToggle(me, :settingsGeneralDisplayLatLong, settings.displayLatLong);
        safeSetToggle(me, :settingsGeneralUseStartForStop, settings.useStartForStop);
        safeSetSubLabel(
            me,
            :settingsGeneralMapMoveScreenSize,
            settings.mapMoveScreenSize.format("%.2f")
        );
    }
}

(:settingsView)
function getTrackPointReductionMethodString(mode as Number) as ResourceId or String {
    switch (mode) {
        case TRACK_POINT_REDUCTION_METHOD_DOWNSAMPLE:
            return Rez.Strings.trackPointReductionMethodDownsample;
        case TRACK_POINT_REDUCTION_METHOD_REUMANN_WITKAM:
            return Rez.Strings.trackPointReductionMethodReumannWitkam;
        default:
            return "";
    }
}

(:settingsView)
class SettingsTrack extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.trackSettingsTitle });
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.maxTrackPointsTitle,
                null,
                :settingsTrackMaxTrackPoints,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.trackStyleTitle, null, :settingsTrackTrackStyle, {})
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.trackWidthTitle, null, :settingsTrackTrackWidth, {})
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.minTrackPointDistanceMTitle,
                null,
                :settingsTrackMinTrackPointDistanceM,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.trackPointReductionMethodTitle,
                null,
                :settingTrackTrackPointReductionMethod,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.useTrackAsHeadingSpeedMPSTitle,
                null,
                :settingsTrackUseTrackAsHeadingSpeedMPS,
                {}
            )
        );
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetSubLabel(me, :settingsTrackMaxTrackPoints, settings.maxTrackPoints.toString());
        safeSetSubLabel(me, :settingsTrackTrackStyle, getTrackStyleString(settings.trackStyle));
        safeSetSubLabel(me, :settingsTrackTrackWidth, settings.trackWidth.toString() + "px");
        safeSetSubLabel(
            me,
            :settingsTrackMinTrackPointDistanceM,
            settings.minTrackPointDistanceM.toString()
        );
        safeSetSubLabel(
            me,
            :settingTrackTrackPointReductionMethod,
            getTrackPointReductionMethodString(settings.trackPointReductionMethod)
        );
        safeSetSubLabel(
            me,
            :settingsTrackUseTrackAsHeadingSpeedMPS,
            settings.useTrackAsHeadingSpeedMPS.format("%.2f") + "m/s"
        );
    }
}

(:settingsView)
class SettingsDataFieldPageList extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Data Pages" });
        rerender();
    }

    function rerender() as Void {
        while (self.deleteItem(0) != null) {
            // Keep deleting the first item until nothing is left
        }

        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var pageCounts = settings.dataFieldPageCounts;

        // Add items for existing pages
        for (var i = 0; i < pageCounts.size(); i++) {
            addItem(new WatchUi.MenuItem("Page " + i, "Fields: " + pageCounts[i], i, {}));
        }
        // Add a button to add a new page
        addItem(new WatchUi.MenuItem("Add Page", null, :addPage, {}));
    }
}

const DATAFIELD_MAX_FIELD_SIZE = 4;

(:settingsView)
class VisualDataFieldPageEditorView extends WatchUi.View {
    var pageIndex as Number;
    var selectedIndex as Number = 0;
    var fieldTypes as Array<Number>;
    var renderer as BreadcrumbRenderer;
    var settings as Settings;

    function initialize(pageIndex as Number, breadcrumbContext as BreadcrumbContext) {
        View.initialize();
        me.pageIndex = pageIndex;
        // Clone the current field types into our temporary buffer
        settings = breadcrumbContext.settings;
        fieldTypes = settings.getTypesForPage(pageIndex);
        renderer = breadcrumbContext.breadcrumbRenderer;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        renderer.renderDataFieldPageFields(dc, fieldTypes, selectedIndex);
    }

    // Method to update the field type from the delegate
    function updateSelectedField(newType as Number) as Void {
        fieldTypes[selectedIndex] = newType;
        WatchUi.requestUpdate();
    }

    function setSelectedIndex(i as Number) as Void {
        selectedIndex = i;
        WatchUi.requestUpdate();
    }

    function rerender() as Void {
        WatchUi.requestUpdate();
    }
}

(:settingsView)
class VisualDataFieldPageEditorDelegate extends WatchUi.BehaviorDelegate {
    private var view as VisualDataFieldPageEditorView;
    var pageView as SettingsDataFieldPageEditor;
    var listView as SettingsDataFieldPageList;

    function initialize(
        view as VisualDataFieldPageEditorView,
        pageView as SettingsDataFieldPageEditor,
        listView as SettingsDataFieldPageList
    ) {
        BehaviorDelegate.initialize();
        me.view = view;
        me.pageView = pageView;
        me.listView = listView;
    }

    function onNextPage() as Boolean {
        var idx = view.selectedIndex;
        var count = view.fieldTypes.size();
        view.setSelectedIndex((idx + 1) % count);
        return true;
    }

    function onPreviousPage() {
        var idx = view.selectedIndex;
        var count = view.fieldTypes.size();
        view.setSelectedIndex(idx == 0 ? count - 1 : idx - 1);
        return true;
    }

    function onTap(clickEvent) {
        var xy = clickEvent.getCoordinates();
        var count = view.fieldTypes.size();

        // Logical check: which field did they tap?
        for (var i = 0; i < count; i++) {
            System.println("checking: " + i);
            if (isInsideField(xy[0], xy[1], i, count)) {
                System.println("found: " + i);
                view.setSelectedIndex(i);
                openTypePicker();
                return true;
            }
        }
        return true;
    }

    (:settingsView)
    function isInsideField(
        tx as Number,
        ty as Number,
        index as Number,
        count as Number
    ) as Boolean {
        var w = System.getDeviceSettings().screenWidth;
        var h = System.getDeviceSettings().screenHeight;

        if (count == 1) {
            return true; // Single field occupies the whole screen
        } else if (count == 2) {
            // Top half vs Bottom half
            if (index == 0) {
                return ty < h / 2.0f;
            }
            if (index == 1) {
                return ty >= h / 2.0f;
            }
        } else if (count == 3) {
            // Vertical thirds
            var third = h / 3.0f;
            if (index == 0) {
                return ty < third;
            }
            if (index == 1) {
                return ty >= third && ty < 2.0f * third;
            }
            if (index == 2) {
                return ty >= 2.0f * third;
            }
        } else if (count == 4) {
            var third = h / 3.0f;
            if (index == 0) {
                // Top row
                return ty < third;
            } else if (index == 3) {
                // Bottom row
                return ty >= 2.0f * third;
            } else {
                // Middle row (Split vertically)
                if (ty >= third && ty < 2.0f * third) {
                    if (index == 1) {
                        return tx < w / 2.0f;
                    } // Middle Left
                    if (index == 2) {
                        return tx >= w / 2.0f;
                    } // Middle Right
                }
            }
        }

        return false;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        logT("got key event: " + key);

        if (key == WatchUi.KEY_ENTER) {
            openTypePicker();
            return true;
        }

        return false;
    }

    // for touch devices this is touching a section on the screen (we want to handle the onTap instead)
    // for non touch its the 'confirm' button
    // function onSelect() as Boolean {
    // }

    function openTypePicker() as Void {
        var currentType = view.fieldTypes[view.selectedIndex];
        WatchUi.pushView(
            new $.EnumMenu("Select Data", method(:getDataTypeStringL), currentType, DATA_TYPE_MAX),
            new $.EnumDelegate(method(:onTypeSelected), view),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getDataTypeStringL(value as Number) as ResourceId or String {
        return getDataTypeString(value);
    }

    function onTypeSelected(newType as Number) as Void {
        view.updateSelectedField(newType);
    }

    function onBack() as Boolean {
        // This is where you save the "Buffer" back to global settings
        view.settings.setPageFields(view.pageIndex, view.fieldTypes);
        pageView.rerender();
        listView.rerender();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

(:settingsView)
class VisualDataFieldPageLayoutView extends WatchUi.View {
    var pageIndex as Number;
    var fieldTypes as Array<Number>;
    var renderer as BreadcrumbRenderer;
    var settings as Settings;
    var activeCount as Number; // Track how many are actually visible

    function initialize(pageIndex as Number, breadcrumbContext as BreadcrumbContext) {
        View.initialize();
        me.pageIndex = pageIndex;
        settings = breadcrumbContext.settings;
        renderer = breadcrumbContext.breadcrumbRenderer;

        // Get existing fields
        var existing = settings.getTypesForPage(pageIndex);
        activeCount = existing.size();

        // Pad to DATAFIELD_MAX_FIELD_SIZE (4)
        fieldTypes = new [DATAFIELD_MAX_FIELD_SIZE] as Array<Number>;
        for (var i = 0; i < DATAFIELD_MAX_FIELD_SIZE; i++) {
            if (i < activeCount) {
                fieldTypes[i] = existing[i];
            } else {
                fieldTypes[i] = DATA_TYPE_NONE;
            }
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // 1. Render Preview
        var currentTypes = fieldTypes.slice(0, activeCount);
        renderer.renderDataFieldPageFields(dc, currentTypes, null);

        // 2. Draw Scroll Gauge on the Left
        var w = dc.getWidth();
        var h = dc.getHeight();
        var r = w / 2 - 5; // Slightly inside the edge
        var penWidth = 4;
        dc.setPenWidth(penWidth);

        // Total span of the arc (e.g., 60 degrees total, centered at 180)
        var totalSpan = 60;
        var startAngle = 180 + totalSpan / 2; // 210°
        var endAngle = 180 - totalSpan / 2; // 150°

        // Draw Background (Grey Arc)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(w / 2, h / 2, r, Graphics.ARC_CLOCKWISE, startAngle, endAngle);

        // Draw Indicator (Blue Arc)
        // We split the totalSpan into 4 segments
        var segmentSize = totalSpan / DATAFIELD_MAX_FIELD_SIZE;
        // Calculate position: activeCount 1 is top, 4 is bottom
        var indicatorStart =
            startAngle - (DATAFIELD_MAX_FIELD_SIZE - activeCount) * segmentSize;
        var indicatorEnd = indicatorStart - segmentSize;

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(w / 2, h / 2, r, Graphics.ARC_CLOCKWISE, indicatorStart, indicatorEnd);
    }

    function updateLayout(newCount as Number) as Void {
        activeCount = newCount;
        WatchUi.requestUpdate();
    }
}

(:settingsView)
class VisualDataFieldPageLayoutDelegate extends WatchUi.BehaviorDelegate {
    private var view as VisualDataFieldPageLayoutView;
    var pageView as SettingsDataFieldPageEditor;
    var listView as SettingsDataFieldPageList;

    function initialize(
        view as VisualDataFieldPageLayoutView,
        pageView as SettingsDataFieldPageEditor,
        listView as SettingsDataFieldPageList
    ) {
        BehaviorDelegate.initialize();
        me.view = view;
        me.pageView = pageView;
        me.listView = listView;
    }

    function onNextPage() as Boolean {
        var currentCount = view.activeCount;
        var nextCount = currentCount + 1;

        if (nextCount > DATAFIELD_MAX_FIELD_SIZE) {
            nextCount = DATAFIELD_MAX_FIELD_SIZE;
        }

        view.updateLayout(nextCount);
        return true;
    }

    function onPreviousPage() as Boolean {
        var currentCount = view.activeCount;
        var nextCount = currentCount - 1;

        if (nextCount < 1) {
            nextCount = 1;
        }

        view.updateLayout(nextCount);
        return true;
    }

    function onSelect() as Boolean {
        return onBack(); // Save and exit
    }

    function onBack() as Boolean {
        var finalFields = view.fieldTypes.slice(0, view.activeCount);
        view.settings.setPageFields(view.pageIndex, finalFields);
        pageView.rerender();
        listView.rerender();

        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

(:settingsView)
class SettingsDataFieldPageEditor extends WatchUi.Menu2 {
    var pageIndex as Number;

    function initialize(index as Number) {
        Menu2.initialize({ :title => "Page " + index });
        pageIndex = index;
        rerender();
    }

    function rerender() as Void {
        while (self.deleteItem(0) != null) {
            // Keep deleting the first item until nothing is left
        }

        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;

        // Fetch the types corresponding to this page from the global array
        // (You'll need a helper to calculate the offset in the flattened dataFieldPageTypes array)
        var types = settings.getTypesForPage(pageIndex);

        addItem(new WatchUi.MenuItem("Layout", null, :layout, {}));
        addItem(new WatchUi.MenuItem("Edit", null, :edit, {}));
        for (var i = 0; i < types.size(); i++) {
            addItem(new WatchUi.MenuItem("Field " + i, getDataTypeString(types[i]), i, {}));
        }
        if (types.size() < DATAFIELD_MAX_FIELD_SIZE) {
            addItem(new WatchUi.MenuItem("Add Field", null, :addField, {}));
        }
        addItem(new WatchUi.MenuItem("Delete Page", null, :deletePage, {}));
    }
}

(:settingsView)
class SettingsDataFieldPageListDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsDataFieldPageList;

    function initialize(view as SettingsDataFieldPageList) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;

        if (id == :addPage) {
            settings.addNewPage();
            view.rerender(); // make sure the menu updates, we just added a page to it
        } else {
            // Push the editor for the selected page index
            var pageIndex = id as Number;
            var pageView = new $.SettingsDataFieldPageEditor(pageIndex);
            WatchUi.pushView(
                pageView,
                new $.SettingsDataFieldPageEditorDelegate(pageIndex, pageView, view),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

(:settingsView)
class SettingsDataFieldPageEditorDelegate extends WatchUi.Menu2InputDelegate {
    var pageIndex as Number;
    var fieldIndex as Number;
    var view as SettingsDataFieldPageEditor;
    var listView as SettingsDataFieldPageList;

    function initialize(
        pageIndex as Number,
        view as SettingsDataFieldPageEditor,
        listView as SettingsDataFieldPageList
    ) {
        WatchUi.Menu2InputDelegate.initialize();
        me.pageIndex = pageIndex;
        fieldIndex = 0;
        me.view = view;
        me.listView = listView;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;

        var id = item.getId();
        if (id == :addField) {
            settings.addNewField(pageIndex);
            listView.rerender();
            view.rerender();
        } else if (id == :layout) {
            var layoutView = new VisualDataFieldPageLayoutView(pageIndex, _breadcrumbContextLocal);
            WatchUi.pushView(
                layoutView,
                new VisualDataFieldPageLayoutDelegate(layoutView, view, listView),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (id == :edit) {
            var editView = new VisualDataFieldPageEditorView(pageIndex, _breadcrumbContextLocal);
            WatchUi.pushView(
                editView,
                new VisualDataFieldPageEditorDelegate(editView, view, listView),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (id == :deletePage) {
            var dialog = new WatchUi.Confirmation("Delete page?");
            WatchUi.pushView(
                dialog,
                new SettingsDataFieldPageRemoveDelegate(pageIndex, listView),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else {
            fieldIndex = id as Number;

            // Push a sub-menu to choose between Edit or Remove
            var fieldActions = new FieldAction(pageIndex, fieldIndex);
            WatchUi.pushView(
                fieldActions,
                new FieldActionDelegate(pageIndex, fieldIndex, view, listView, fieldActions),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

(:settingsView)
class FieldAction extends WatchUi.Menu2 {
    var pageIndex as Number;
    var fieldIndex as Number;

    function initialize(pageIndex as Number, fieldIndex as Number) {
        Menu2.initialize({ :title => "Page " + pageIndex + " Field " + fieldIndex });
        me.pageIndex = pageIndex;
        me.fieldIndex = fieldIndex;
        addItem(new WatchUi.MenuItem("Type", null, :edit, {}));
        addItem(new WatchUi.MenuItem("Remove Field", null, :remove, {}));
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var types = settings.getTypesForPage(pageIndex);
        safeSetSubLabel(me, :edit, getDataTypeString(types[fieldIndex]));
    }
}

(:settingsView)
class FieldActionDelegate extends WatchUi.Menu2InputDelegate {
    var pageIndex as Number;
    var fieldIndex as Number;
    var view as SettingsDataFieldPageEditor;
    var listView as SettingsDataFieldPageList;
    var fieldActions as FieldAction;

    function initialize(
        pIdx as Number,
        fIdx as Number,
        v as SettingsDataFieldPageEditor,
        listView as SettingsDataFieldPageList,
        fieldActions as FieldAction
    ) {
        WatchUi.Menu2InputDelegate.initialize();
        pageIndex = pIdx;
        fieldIndex = fIdx;
        view = v;
        me.listView = listView;
        me.fieldActions = fieldActions;
    }

    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getDataTypeStringL(value as Number) as ResourceId or String {
        return getDataTypeString(value);
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :edit) {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal == null) {
                breadcrumbContextWasNull();
                return;
            }
            var settings = _breadcrumbContextLocal.settings;
            WatchUi.pushView(
                new $.EnumMenu(
                    "Select Data",
                    method(:getDataTypeStringL),
                    settings.getFieldType(pageIndex, fieldIndex),
                    DATA_TYPE_MAX
                ),
                new $.EnumDelegate(method(:setDataFieldPageType), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (id == :remove) {
            var dialog = new WatchUi.Confirmation("Remove field?");
            WatchUi.pushView(
                dialog,
                new FieldRemoveDelegate(pageIndex, fieldIndex, view, listView),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }

    public function setDataFieldPageType(newType as Number) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        settings.setPageFieldType(pageIndex, fieldIndex, newType);
        fieldActions.rerender();
    }
}

(:settingsView)
class FieldRemoveDelegate extends WatchUi.ConfirmationDelegate {
    var pageIndex as Number;
    var fieldIndex as Number;
    var view as SettingsDataFieldPageEditor;
    var listView as SettingsDataFieldPageList;

    function initialize(
        pIdx as Number,
        fIdx as Number,
        v as SettingsDataFieldPageEditor,
        listView as SettingsDataFieldPageList
    ) {
        WatchUi.ConfirmationDelegate.initialize();
        pageIndex = pIdx;
        fieldIndex = fIdx;
        view = v;
        me.listView = listView;
    }

    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal == null) {
                breadcrumbContextWasNull();
                return false;
            }
            var settings = _breadcrumbContextLocal.settings;
            settings.removeField(pageIndex, fieldIndex);
            listView.rerender();
            view.rerender();
            // Pop the action menu and the confirmation dialog
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        return true;
    }
}

(:settingsView)
class SettingsDataFieldPageRemoveDelegate extends WatchUi.ConfirmationDelegate {
    private var pageIndex as Number;
    private var view as SettingsDataFieldPageList;

    function initialize(pageIndex as Number, view as SettingsDataFieldPageList) {
        WatchUi.ConfirmationDelegate.initialize();
        me.pageIndex = pageIndex;
        me.view = view;
    }

    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal == null) {
                breadcrumbContextWasNull();
                return false;
            }
            var settings = _breadcrumbContextLocal.settings;
            settings.removePage(pageIndex);
            view.rerender(); // make sure the menu updates, we just removed a page from it
            // Pop the editor view now that the data is gone
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }

        return true; // we always handle it
    }
}

(:settingsView)
class SettingsDataField extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.dataFieldSettingsTitle });
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.topDataTypeTitle,
                null,
                :settingsDataFieldTopDataType,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.bottomDataTypeTitle,
                null,
                :settingsDataFieldBottomDataType,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.dataFieldTextSizeTitle,
                null,
                :settingsDataFieldTextSize,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.autoLapDistanceMTitle,
                null,
                :settingsDataFieldAutoLapDistanceM,
                {}
            )
        );
        addItem(new WatchUi.MenuItem("Data Pages", null, :settingsDataFieldPages, {}));
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetSubLabel(me, :settingsDataFieldTopDataType, getDataTypeString(settings.topDataType));
        safeSetSubLabel(
            me,
            :settingsDataFieldTextSize,
            getFontSizeString(settings.dataFieldTextSize)
        );
        safeSetSubLabel(
            me,
            :settingsDataFieldAutoLapDistanceM,
            settings.autoLapDistanceM <= 0 ? "N/A" : settings.autoLapDistanceM.toString() + "m"
        );
        safeSetSubLabel(
            me,
            :settingsDataFieldBottomDataType,
            getDataTypeString(settings.bottomDataType)
        );
    }
}

(:settingsView)
function getPackingFormatString(mode as Number) as ResourceId or String {
    switch (mode) {
        case Communications.PACKING_FORMAT_DEFAULT:
            return Rez.Strings.packingFormatDefault;
        case Communications.PACKING_FORMAT_YUV:
            return Rez.Strings.packingFormatYUV;
        case Communications.PACKING_FORMAT_PNG:
            return Rez.Strings.packingFormatPNG;
        case Communications.PACKING_FORMAT_JPG:
            return Rez.Strings.packingFormatJPG;
        default:
            return "";
    }
}

(:settingsView)
class SettingsMap extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.mapsettingsTitle });
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.mapEnabledTitle,
                null,
                :settingsMapEnabled,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.tileServerSettingsTitle,
                null,
                :settingsMapTileServerSettings,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.mapStorageSettingsTitle,
                null,
                :settingsMapStorageSettings,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.tileCacheSizeTitle,
                null,
                :settingsMapTileCacheSize,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.tileCachePaddingTitle,
                null,
                :settingsMapTileCachePadding,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.maxPendingWebRequests,
                null,
                :settingsMapMaxPendingWebRequests,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.disableMapsFailureCountTitleShort,
                null,
                :settingsMapDisableMapsFailureCount,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.httpErrorTileTTLSTitle,
                null,
                :settingsMapHttpErrorTileTTLS,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.errorTileTTLSTitle,
                null,
                :settingsMapErrorTileTTLS,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.fixedLatitude, null, :settingsMapFixedLatitude, {})
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.fixedLongitude, null, :settingsMapFixedLongitude, {})
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.scaleRestrictedToTileLayersTitle,
                null,
                :settingsMapScaleRestrictedToTileLayers,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.packingFormatTitle,
                null,
                :settingsMapPackingFormat,
                {}
            )
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.useDrawBitmapTitle,
                null,
                :settingsMapUseDrawBitmap,
                false,
                {}
            )
        );
        addItem(new WatchUi.MenuItem(Rez.Strings.attribution, null, :settingsMapAttribution, {}));
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetToggle(me, :settingsMapEnabled, true);

        safeSetSubLabel(me, :settingsMapTileCacheSize, settings.tileCacheSize.toString());
        safeSetSubLabel(me, :settingsMapTileCachePadding, settings.tileCachePadding.toString());
        safeSetSubLabel(
            me,
            :settingsMapMaxPendingWebRequests,
            settings.maxPendingWebRequests.toString()
        );
        safeSetSubLabel(
            me,
            :settingsMapDisableMapsFailureCount,
            settings.disableMapsFailureCount.toString()
        );
        var fixedLatitude = settings.fixedLatitude;
        var latString = fixedLatitude == null ? "Disabled" : fixedLatitude.format("%.5f");
        safeSetSubLabel(me, :settingsMapFixedLatitude, latString);
        var fixedLongitude = settings.fixedLongitude;
        var longString = fixedLongitude == null ? "Disabled" : fixedLongitude.format("%.5f");
        safeSetSubLabel(me, :settingsMapFixedLongitude, longString);
        safeSetToggle(
            me,
            :settingsMapScaleRestrictedToTileLayers,
            settings.scaleRestrictedToTileLayers()
        );
        safeSetSubLabel(me, :settingsMapHttpErrorTileTTLS, settings.httpErrorTileTTLS.toString());
        safeSetSubLabel(me, :settingsMapErrorTileTTLS, settings.errorTileTTLS.toString());
        safeSetToggle(me, :settingsMapUseDrawBitmap, settings.useDrawBitmap);
        safeSetSubLabel(
            me,
            :settingsMapPackingFormat,
            getPackingFormatString(settings.packingFormat)
        );
    }
}

(:settingsView)
function getMapChoiceString(mapChoice as Number) as ResourceId {
    switch (mapChoice) {
        case 0:
            return Rez.Strings.custom;
        case 1:
            return Rez.Strings.companionApp;
        case 2:
            return Rez.Strings.openTopoMap;
        case 3:
            return Rez.Strings.esriWorldImagery;
        case 4:
            return Rez.Strings.esriWorldStreetMap;
        case 5:
            return Rez.Strings.esriWorldTopoMap;
        case 6:
            return Rez.Strings.esriWorldTransportation;
        case 7:
            return Rez.Strings.esriWorldDarkGrayBase;
        case 8:
            return Rez.Strings.esriWorldHillshade;
        case 9:
            return Rez.Strings.esriWorldHillshadeDark;
        case 10:
            return Rez.Strings.esriWorldLightGrayBase;
        case 11:
            return Rez.Strings.esriUSATopoMaps;
        case 12:
            return Rez.Strings.esriWorldOceanBase;
        case 13:
            return Rez.Strings.esriWorldShadedRelief;
        case 14:
            return Rez.Strings.esriNatGeoWorldMap;
        case 15:
            return Rez.Strings.esriWorldNavigationCharts;
        case 16:
            return Rez.Strings.esriWorldPhysicalMap;
        case 17:
            return Rez.Strings.openStreetMapcyclosm;
        case 18:
            return Rez.Strings.stadiaAlidadeSmooth;
        case 19:
            return Rez.Strings.stadiaAlidadeSmoothDark;
        case 20:
            return Rez.Strings.stadiaOutdoors;
        case 21:
            return Rez.Strings.stadiaStamenToner;
        case 22:
            return Rez.Strings.stadiaStamenTonerLite;
        case 23:
            return Rez.Strings.stadiaStamenTerrain;
        case 24:
            return Rez.Strings.stadiaStamenWatercolor;
        case 25:
            return Rez.Strings.stadiaOSMBright;
        case 26:
            return Rez.Strings.cartoVoyager;
        case 27:
            return Rez.Strings.cartoDarkMatter;
        case 28:
            return Rez.Strings.cartoDarkLightAll;
        case 29:
            return Rez.Strings.mapyBasic;
        case 30:
            return Rez.Strings.mapyOutdoor;
        case 31:
            return Rez.Strings.mapyWinter;
        case 32:
            return Rez.Strings.mapyAerial;
        default:
            return Rez.Strings.custom;
    }
}

(:settingsView)
class SettingsTileServer extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.tileServerSettingsTitle });
        addItem(new WatchUi.MenuItem(Rez.Strings.mapChoice, null, :settingsMapChoice, {}));
        addItem(new WatchUi.MenuItem(Rez.Strings.tileUrlTitle, null, :settingsTileUrl, {}));
        addItem(new WatchUi.MenuItem(Rez.Strings.authTokenTitle, null, :settingsAuthToken, {}));
        addItem(new WatchUi.MenuItem(Rez.Strings.layerTileSize, null, :settingsMapTileSize, {}));
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.scaledTileSizeTitle,
                null,
                :settingsMapScaledTileSize,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.tileLayerMaxTitle, null, :settingsMapTileLayerMax, {})
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.tileLayerMinTitle, null, :settingsMapTileLayerMin, {})
        );
        addItem(
            new WatchUi.MenuItem(Rez.Strings.fullTileSizeTitle, null, :settingsMapFullTileSize, {})
        );
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;

        safeSetSubLabel(me, :settingsMapChoice, getMapChoiceString(settings.mapChoice));
        safeSetSubLabel(me, :settingsTileUrl, settings.tileUrl);
        safeSetSubLabel(me, :settingsAuthToken, settings.authToken);
        safeSetSubLabel(me, :settingsMapTileSize, settings.tileSize.toString());
        safeSetSubLabel(me, :settingsMapFullTileSize, settings.fullTileSize.toString());
        safeSetSubLabel(me, :settingsMapScaledTileSize, settings.scaledTileSize.toString());
        safeSetSubLabel(me, :settingsMapTileLayerMax, settings.tileLayerMax.toString());
        safeSetSubLabel(me, :settingsMapTileLayerMin, settings.tileLayerMin.toString());
    }
}

(:settingsView)
class SettingsMapStorage extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.mapStorageSettingsTitle });
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.cacheTilesInStorageTitle,
                null,
                :settingsMapStorageCacheTilesInStorage,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.storageMapTilesOnlyTitle,
                null,
                :settingsMapStorageStorageMapTilesOnly,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.storageTileCacheSizeTitle,
                null,
                :settingsMapStorageStorageTileCacheSize,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.storageTileCachePageCountTitle,
                null,
                :settingsMapStorageStorageTileCachePageCount,
                {}
            )
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.storageSeedBoundingBoxTitle,
                null,
                :settingsMapStorageStorageSeedBoundingBox,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.storageSeedRouteDistanceMTitle,
                null,
                :settingsMapStorageStorageSeedRouteDistanceM,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.cacheCurrentArea,
                null,
                :settingsMapStorageCacheCurrentArea,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.cancelCacheDownload,
                null,
                :settingsMapStorageCancelCacheDownload,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.clearCachedTiles,
                null,
                :settingsMapStorageClearCachedTiles,
                {}
            )
        );
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var cachedValues = _breadcrumbContextLocal.cachedValues;
        safeSetToggle(me, :settingsMapStorageCacheTilesInStorage, settings.cacheTilesInStorage);
        safeSetToggle(me, :settingsMapStorageStorageMapTilesOnly, settings.storageMapTilesOnly);
        safeSetSubLabel(
            me,
            :settingsMapStorageStorageTileCacheSize,
            settings.storageTileCacheSize.toString()
        );
        safeSetSubLabel(
            me,
            :settingsMapStorageStorageTileCachePageCount,
            settings.storageTileCachePageCount.toString()
        );
        safeSetToggle(
            me,
            :settingsMapStorageStorageSeedBoundingBox,
            settings.storageSeedBoundingBox
        );
        safeSetSubLabel(
            me,
            :settingsMapStorageStorageSeedRouteDistanceM,
            settings.storageSeedRouteDistanceM.format("%.2f")
        );
        var cacheSize =
            "" +
            _breadcrumbContextLocal.tileCache._storageTileCache._totalTileCount +
            "/" +
            settings.storageTileCacheSize;
        safeSetSubLabel(me, :settingsMapStorageCacheCurrentArea, cacheSize);
        safeSetSubLabel(
            me,
            :settingsMapStorageCancelCacheDownload,
            cachedValues.seeding() ? "Seeding" : ""
        );
    }
}

function alertsCommonMenu(menu as WatchUi.Menu2) as Void {
    menu.addItem(
        new WatchUi.MenuItem(
            Rez.Strings.offTrackAlertsDistanceMTitle,
            null,
            :settingsAlertsOffTrackDistanceM,
            {}
        )
    );
    menu.addItem(
        new WatchUi.MenuItem(
            Rez.Strings.offTrackCheckIntervalSTitle,
            null,
            :settingsAlertsOffTrackCheckIntervalS,
            {}
        )
    );
    menu.addItem(
        new WatchUi.ToggleMenuItem(
            Rez.Strings.drawLineToClosestPointTitle,
            null,
            :settingsAlertsDrawLineToClosestPoint,
            false,
            {}
        )
    );
    menu.addItem(
        new WatchUi.ToggleMenuItem(
            Rez.Strings.drawCheveronsTitle,
            null,
            :settingsAlertsDrawCheverons,
            false,
            {}
        )
    );
    menu.addItem(
        new WatchUi.ToggleMenuItem(
            Rez.Strings.offTrackWrongDirectionTitle,
            null,
            :settingsAlertsOffTrackWrongDirection,
            false,
            {}
        )
    );
    menu.addItem(
        new WatchUi.ToggleMenuItem(
            Rez.Strings.enableOffTrackAlertsTitle,
            null,
            :settingsAlertsEnabled,
            false,
            {}
        )
    );
    menu.addItem(
        new WatchUi.MenuItem(
            Rez.Strings.turnAlertTimeSTitle,
            null,
            :settingsAlertsTurnAlertTimeS,
            {}
        )
    );
    menu.addItem(
        new WatchUi.MenuItem(
            Rez.Strings.minTurnAlertDistanceMTitle,
            null,
            :settingsAlertsMinTurnAlertDistanceM,
            {}
        )
    );
    menu.addItem(
        new WatchUi.MenuItem(Rez.Strings.alertTypeTitle, null, :settingsAlertsAlertType, {})
    );
}

(:settingsView)
class SettingsMapDisabled extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.mapsettingsTitle });
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.mapEnabledTitle,
                null,
                :settingsMapEnabled,
                false,
                {}
            )
        );
        rerender();
    }

    function rerender() as Void {
        safeSetToggle(me, :settingsMapEnabled, false);
    }
}

(:settingsView)
class SettingsAlerts extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.offTrackAlertsGroupTitle });
        alertsCommonMenu(self);
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        alertsCommon(me, settings);
        safeSetSubLabel(
            me,
            :settingsAlertsOffTrackAlertsMaxReportIntervalS,
            settings.offTrackAlertsMaxReportIntervalS.toString()
        );
    }
}

(:settingsView)
function getAlertTypeString(mode as Number) as ResourceId or String {
    switch (mode) {
        case ALERT_TYPE_TOAST:
            return Rez.Strings.alertTypeToast;
        case ALERT_TYPE_IMAGE:
            return Rez.Strings.alertTypeImage;
        default:
            return "";
    }
}

(:settingsView)
function alertsCommon(menu as WatchUi.Menu2, settings as Settings) as Void {
    safeSetSubLabel(
        menu,
        :settingsAlertsOffTrackDistanceM,
        settings.offTrackAlertsDistanceM.toString()
    );
    safeSetSubLabel(
        menu,
        :settingsAlertsOffTrackCheckIntervalS,
        settings.offTrackCheckIntervalS.toString()
    );
    safeSetToggle(menu, :settingsAlertsDrawLineToClosestPoint, settings.drawLineToClosestPoint);
    safeSetToggle(menu, :settingsAlertsDrawCheverons, settings.drawCheverons);
    safeSetToggle(menu, :settingsAlertsOffTrackWrongDirection, settings.offTrackWrongDirection);
    safeSetToggle(menu, :settingsAlertsEnabled, settings.enableOffTrackAlerts);
    safeSetSubLabel(menu, :settingsAlertsTurnAlertTimeS, settings.turnAlertTimeS.toString());
    safeSetSubLabel(
        menu,
        :settingsAlertsMinTurnAlertDistanceM,
        settings.minTurnAlertDistanceM.toString()
    );
    safeSetSubLabel(menu, :settingsAlertsAlertType, getAlertTypeString(settings.alertType));
}

(:settingsView)
class SettingsAlertsDisabled extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.offTrackAlertsGroupTitle });
        alertsCommonMenu(self);
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        alertsCommon(me, settings);
    }
}

(:settingsView)
class SettingsColours extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.coloursTitle });
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.trackColourTitle,
                null,
                :settingsColoursTrackColour,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.trackColour2Title,
                null,
                :settingsColoursTrackColour2,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.defaultRouteColourTitle,
                null,
                :settingsColoursDefaultRouteColour,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.elevationColourTitle,
                null,
                :settingsColoursElevationColour,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.userColour,
                null,
                :settingsColoursUserColour,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.normalModeColour,
                null,
                :settingsColoursNormalModeColour,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.uiColour,
                null,
                :settingsColoursUiColour,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.dataFieldPageColour,
                null,
                :settingsColoursDataFieldPageColour,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.dataFieldPageColour2,
                null,
                :settingsColoursDataFieldPageColour2,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.debugColour,
                null,
                :settingsColoursDebugColour,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetIcon(me, :settingsColoursTrackColour, new ColourIcon(settings.trackColour));
        safeSetIcon(me, :settingsColoursTrackColour2, new ColourIcon(settings.trackColour2));
        safeSetIcon(
            me,
            :settingsColoursDefaultRouteColour,
            new ColourIcon(settings.defaultRouteColour)
        );
        safeSetIcon(me, :settingsColoursUserColour, new ColourIcon(settings.userColour));
        safeSetIcon(me, :settingsColoursElevationColour, new ColourIcon(settings.elevationColour));
        safeSetIcon(
            me,
            :settingsColoursNormalModeColour,
            new ColourIcon(settings.normalModeColour)
        );
        safeSetIcon(me, :settingsColoursUiColour, new ColourIcon(settings.uiColour));
        safeSetIcon(
            me,
            :settingsColoursDataFieldPageColour,
            new ColourIcon(settings.dataFieldPageColour)
        );
        safeSetIcon(
            me,
            :settingsColoursDataFieldPageColour2,
            new ColourIcon(settings.dataFieldPageColour2)
        );
        safeSetIcon(me, :settingsColoursDebugColour, new ColourIcon(settings.debugColour));
    }
}

(:settingsView)
class SettingsDebug extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.debugSettingsTitle });
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.drawLineToClosestTrackTitle,
                null,
                :settingsDebugDrawLineToClosestTrack,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.showTileBordersTitle,
                null,
                :settingsDebugShowTileBorders,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.showErrorTileMessagesTitle,
                null,
                :settingsDebugShowErrorTileMessages,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.tileErrorColourTitle,
                null,
                :settingsDebugTileErrorColour,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.drawHitBoxesTitle,
                null,
                :settingsDebugDrawHitBoxes,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.showDirectionPointsTitle,
                null,
                :settingsDebugShowDirectionPoints,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.MenuItem(
                Rez.Strings.showDirectionPointTextUnderIndexTitle,
                null,
                :settingsDebugShowDirectionPointTextUnderIndex,
                {}
            )
        );
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetIcon(me, :settingsDebugTileErrorColour, new ColourIcon(settings.tileErrorColour));
        safeSetToggle(me, :settingsDebugDrawLineToClosestTrack, settings.drawLineToClosestTrack);
        safeSetToggle(me, :settingsDebugShowTileBorders, settings.showTileBorders);
        safeSetToggle(me, :settingsDebugShowErrorTileMessages, settings.showErrorTileMessages);
        safeSetToggle(me, :settingsDebugDrawHitBoxes, settings.drawHitBoxes);
        safeSetToggle(me, :settingsDebugShowDirectionPoints, settings.showDirectionPoints);
        safeSetSubLabel(
            me,
            :settingsDebugShowDirectionPointTextUnderIndex,
            settings.showDirectionPointTextUnderIndex.toString()
        );
    }
}

(:settingsView)
class SettingsRoute extends WatchUi.Menu2 {
    var settings as Settings;
    var routeId as Number;
    var parent as SettingsRoutes;
    function initialize(settings as Settings, routeId as Number, parent as SettingsRoutes) {
        Menu2.initialize({ :title => Rez.Strings.routesTitle });
        addItem(new WatchUi.MenuItem(Rez.Strings.routeName, null, :settingsRouteName, {}));
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.routeEnabled,
                null,
                :settingsRouteEnabled,
                false,
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.routeColourTitle,
                null,
                :settingsRouteColour,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.IconMenuItem(
                Rez.Strings.routeColour2Title,
                null,
                :settingsRouteColour2,
                new ColourIcon(Graphics.COLOR_BLACK),
                {}
            )
        );
        addItem(
            new WatchUi.ToggleMenuItem(
                Rez.Strings.routeReversed,
                null,
                :settingsRouteReversed,
                false,
                {}
            )
        );
        addItem(new WatchUi.MenuItem(Rez.Strings.routeStyleTitle, null, :settingsRouteStyle, {}));
        addItem(new WatchUi.MenuItem(Rez.Strings.routeWidthTitle, null, :settingsRouteWidth, {}));
        addItem(new WatchUi.MenuItem(Rez.Strings.routeDelete, null, :settingsRouteDelete, {}));
        self.settings = settings;
        self.routeId = routeId;
        self.parent = parent;
        rerender();
    }

    function rerender() as Void {
        var name = settings.routeName(routeId);
        setTitle(name);
        safeSetSubLabel(me, :settingsRouteName, name);
        safeSetToggle(me, :settingsRouteEnabled, settings.routeEnabled(routeId));
        safeSetIcon(me, :settingsRouteColour, new ColourIcon(settings.routeColour(routeId)));
        safeSetIcon(me, :settingsRouteColour2, new ColourIcon(settings.routeColour2(routeId)));
        safeSetSubLabel(me, :settingsRouteStyle, getTrackStyleString(settings.routeStyle(routeId)));
        safeSetSubLabel(me, :settingsRouteWidth, settings.routeWidth(routeId).toString() + "px");
        safeSetToggle(me, :settingsRouteReversed, settings.routeReversed(routeId));
        parent.rerender();
    }

    function setName(value as String) as Void {
        settings.setRouteName(routeId, value);
    }

    function setEnabled(value as Boolean) as Void {
        settings.setRouteEnabled(routeId, value);
    }

    function setReversed(value as Boolean) as Void {
        settings.setRouteReversed(routeId, value);
    }

    function routeEnabled() as Boolean {
        return settings.routeEnabled(routeId);
    }

    function routeReversed() as Boolean {
        return settings.routeReversed(routeId);
    }

    function routeColour() as Number {
        return settings.routeColour(routeId);
    }

    function routeColour2() as Number {
        return settings.routeColour2(routeId);
    }

    function setColour(value as Number) as Void {
        settings.setRouteColour(routeId, value);
    }

    function setColour2(value as Number) as Void {
        settings.setRouteColour2(routeId, value);
    }

    function setStyle(value as Number) as Void {
        settings.setRouteStyle(routeId, value);
    }

    function setWidth(value as Number) as Void {
        settings.setRouteWidth(routeId, value);
    }
}

(:settingsView)
class SettingsRoutes extends WatchUi.Menu2 {
    var settings as Settings;
    function initialize(settings as Settings) {
        WatchUi.Menu2.initialize({
            :title => Rez.Strings.routesTitle,
        });
        me.settings = settings;
        setup();
        rerender();
    }

    function setup() as Void {
        addItem(
            new ToggleMenuItem(
                Rez.Strings.routesEnabled,
                "", // sublabel
                :settingsRoutesEnabled,
                settings.routesEnabled,
                {}
            )
        );
        if (!settings.routesEnabled) {
            return;
        }

        addItem(
            new ToggleMenuItem(
                Rez.Strings.displayRouteNamesTitle,
                "", // sublabel
                :settingsDisplayRouteNames,
                settings.displayRouteNames,
                {}
            )
        );

        addItem(
            new MenuItem(
                Rez.Strings.routeMax,
                settings.routeMax().toString(),
                :settingsDisplayRouteMax,
                {}
            )
        );

        addItem(
            new MenuItem(
                Rez.Strings.clearRoutes,
                "", // sublabel
                :settingsRoutesClearAll,
                {}
            )
        );

        // don't use route max, sometimes it gets out of sync, we want to pull in all the routes so we can remove them
        for (var i = 0; i < settings.routes.size(); ++i) {
            var routeId = settings.routes[i]["routeId"] as Number;
            var routeName = settings.routeName(routeId);
            var enabledStr = settings.routeEnabled(routeId) ? "Enabled" : "Disabled";
            var reversedStr = settings.routeReversed(routeId) ? "Reversed" : "Forward";
            addItem(
                // do not be tempted to switch this to a menuitem (IconMenuItem is supported since API 3.0.0, MenuItem only supports icons from API 3.4.0)
                new IconMenuItem(
                    routeName.equals("") ? "<unlabeled>" : routeName,
                    enabledStr + " " + reversedStr,
                    routeId,
                    new ColourIcon(settings.routeColour(routeId)),
                    {
                        // only get left or right, no center :(
                        :alignment => MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT,
                    }
                )
            );
        }
    }

    function rerender() as Void {
        safeSetToggle(me, :settingsRoutesEnabled, settings.routesEnabled);
        safeSetToggle(me, :settingsDisplayRouteNames, settings.displayRouteNames);
        safeSetSubLabel(me, :settingsDisplayRouteMax, settings.routeMax().toString());
        for (var i = 0; i < settings.routes.size(); ++i) {
            var routeId = settings.routes[i]["routeId"] as Number;
            var routeName = settings.routeName(routeId);
            safeSetLabel(me, routeId, routeName.equals("") ? "<unlabeled>" : routeName);
            safeSetIcon(me, routeId, new ColourIcon(settings.routeColour(routeId)));
            safeSetSubLabel(me, routeId, settings.routeEnabled(routeId) ? "Enabled" : "Disabled");
        }
    }
}

(:settingsView)
class SettingsMainDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMain;
    function initialize(view as SettingsMain) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsMainGeneral) {
            var view = new $.SettingsGeneral();
            WatchUi.pushView(view, new $.SettingsGeneralDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainTrack) {
            var view = new $.SettingsTrack();
            WatchUi.pushView(view, new $.SettingsTrackDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainDataField) {
            var view = new $.SettingsDataField();
            WatchUi.pushView(view, new $.SettingsDataFieldDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainZoomAtPace) {
            var view = new $.SettingsZoomAtPace();
            WatchUi.pushView(view, new $.SettingsZoomAtPaceDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainRoutes) {
            var view = new $.SettingsRoutes(settings);
            WatchUi.pushView(
                view,
                new $.SettingsRoutesDelegate(view, settings),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainMap) {
            if (settings.mapEnabled) {
                var view = new SettingsMap();
                WatchUi.pushView(view, new $.SettingsMapDelegate(view), WatchUi.SLIDE_IMMEDIATE);
                return;
            }
            var disabledView = new SettingsMapDisabled();
            WatchUi.pushView(
                disabledView,
                new $.SettingsMapDisabledDelegate(disabledView),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainAlerts) {
            if (settings.offTrackWrongDirection || settings.enableOffTrackAlerts) {
                var view = new SettingsAlerts();
                WatchUi.pushView(view, new $.SettingsAlertsDelegate(view), WatchUi.SLIDE_IMMEDIATE);
                return;
            }
            var disabledView = new SettingsAlertsDisabled();
            WatchUi.pushView(
                disabledView,
                new $.SettingsAlertsDisabledDelegate(disabledView),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainColours) {
            var view = new SettingsColours();
            WatchUi.pushView(view, new $.SettingsColoursDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainDebug) {
            var view = new SettingsDebug();
            WatchUi.pushView(view, new $.SettingsDebugDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainClearStorage) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.clearStorage) as String
            );
            WatchUi.pushView(dialog, new ClearStorageDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainReturnToUser) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.returnToUserTitle) as String
            );
            WatchUi.pushView(dialog, new ReturnToUserDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainResetDefaults) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.resetDefaults) as String
            );
            WatchUi.pushView(dialog, new ResetSettingsDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

(:noSettingsView)
class SettingsMainDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMain;
    function initialize(view as SettingsMain) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        if (itemId == :settingsMainMapAttribution) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsMapAttribution(),
                new $.SettingsMapAttributionDelegate(),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainReturnToUser) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.returnToUserTitle) as String
            );
            WatchUi.pushView(dialog, new ReturnToUserDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

(:settingsView)
class ResetSettingsDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return false;
        }
        if (response == WatchUi.CONFIRM_YES) {
            _breadcrumbContextLocal.settings.resetDefaultsFromMenu();
        }

        return true; // we always handle it
    }
}

class ReturnToUserDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal == null) {
                breadcrumbContextWasNull();
                return false;
            }
            _breadcrumbContextLocal.cachedValues.returnToUser();
        }

        return true; // we always handle it
    }
}

(:settingsView)
class ClearStorageDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return false;
        }
        if (response == WatchUi.CONFIRM_YES) {
            Application.Storage.clearValues(); // purge the storage, but we have to clean up all our classes that load from storage too
            _breadcrumbContextLocal.tileCache._storageTileCache.reset(); // reload our tile storage class
            _breadcrumbContextLocal.tileCache.clearValues(); // also clear the tile cache, it case it pulled from our storage
            _breadcrumbContextLocal.clearRoutes(); // also clear the routes to mimic storage being removed
            _breadcrumbContextLocal.settings.storageCleared();
        }

        return true; // we always handle it
    }
}

(:settingsView)
class ClearCachedTilesDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return false;
        }
        if (response == WatchUi.CONFIRM_YES) {
            _breadcrumbContextLocal.tileCache._storageTileCache.clearValues();
            _breadcrumbContextLocal.tileCache.clearValues(); // also clear the tile cache, in case it pulled from our storage

            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop confirmation
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop map storage view
            var view = new $.SettingsMapStorage();
            WatchUi.pushView(view, new $.SettingsMapStorageDelegate(view), WatchUi.SLIDE_IMMEDIATE); // replace with new updated map storage view
            WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the confirmation to pop
        }

        return true; // we always handle it
    }
}

(:settingsView)
class StartCachedTilesDelegate extends WatchUi.ConfirmationDelegate {
    var view as SettingsMapStorage;
    function initialize(view as SettingsMapStorage) {
        WatchUi.ConfirmationDelegate.initialize();
        me.view = view;
    }
    function onResponse(response as Confirm) as Boolean {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return false;
        }
        if (response == WatchUi.CONFIRM_YES) {
            _breadcrumbContextLocal.cachedValues.startCacheCurrentMapArea();
            view.rerender();
        }

        return true; // we always handle it
    }
}

(:settingsView)
class DeleteRouteDelegate extends WatchUi.ConfirmationDelegate {
    var routeId as Number;
    var settings as Settings;
    function initialize(_routeId as Number, _settings as Settings) {
        WatchUi.ConfirmationDelegate.initialize();
        routeId = _routeId;
        settings = _settings;
    }
    function onResponse(response as Confirm) as Boolean {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return false;
        }

        if (response == WatchUi.CONFIRM_YES) {
            _breadcrumbContextLocal.clearRoute(routeId);

            // WARNING: this is a massive hack, probably dependant on platform
            // just poping the vew and replacing does not work, because the confirmation is still active whilst we are in this function
            // so we need to pop the confirmation too
            // but the confirmation is also about to call WatchUi.popView()
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop confirmation
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop route view
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop routes view
            var view = new $.SettingsRoutes(settings);
            WatchUi.pushView(
                view,
                new $.SettingsRoutesDelegate(view, settings),
                WatchUi.SLIDE_IMMEDIATE
            ); // replace with new updated routes view
            WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the confirmation to pop
        }

        return true; // we always handle it
    }
}

class SettingsMapAttributionDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        WatchUi.Menu2InputDelegate.initialize();
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId() as Object;
        switch (itemId) {
            case :settingsMapAttributionOpenTopoMap:
                Communications.openWebPage("https://opentopomap.org/about", {}, {});
                break;
            case :settingsMapAttributionGoogle:
                Communications.openWebPage("https://cloud.google.com/maps-platform/terms", {}, {});
                break;
            case :settingsMapAttributionEsri:
                Communications.openWebPage("https://www.esri.com", {}, {});
                break;
            case :settingsMapAttributionOpenStreetmap:
                Communications.openWebPage("https://openstreetmap.org/copyright", {}, {});
                break;
            case :settingsMapAttributionStadia:
                Communications.openWebPage("https://stadiamaps.com/", {}, {});
                break;
            case :settingsMapAttributionOpenMapTiles:
                Communications.openWebPage("https://openmaptiles.org/", {}, {});
                break;
            case :settingsMapAttributionCarto:
                Communications.openWebPage("https://carto.com/attributions/", {}, {});
                break;
            case :settingsMapAttributionMapy:
                Communications.openWebPage("https://mapy.com/", {}, {});
                break;
        }

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView)
class SettingsZoomAtPaceDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsZoomAtPace;
    function initialize(view as SettingsZoomAtPace) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getZoomAtPaceModeStringL(value as Number) as ResourceId or String {
        return getZoomAtPaceModeString(value);
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsZoomAtPaceMode) {
            WatchUi.pushView(
                new EnumMenu(
                    Rez.Strings.zoomAtPaceModeTitle,
                    method(:getZoomAtPaceModeStringL),
                    settings.zoomAtPaceMode,
                    ZOOM_AT_PACE_MODE_MAX
                ),
                new $.EnumDelegate(settings.method(:setZoomAtPaceMode), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsZoomAtPaceUserMeters) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMetersAroundUser),
                    settings.metersAroundUser,
                    view
                )
            );
        } else if (itemId == :settingsZoomAtPaceMPS) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setZoomAtPaceSpeedMPS),
                    settings.zoomAtPaceSpeedMPS,
                    view
                )
            );
        }
    }
}

(:settingsView)
class SettingsGeneralDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsGeneral;
    function initialize(view as SettingsGeneral) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getModeStringL(value as Number) as ResourceId or String {
        return getModeString(value);
    }

    public function getUiModeStringL(value as Number) as ResourceId or String {
        return getUiModeString(value);
    }

    public function getElevationModeStringL(value as Number) as ResourceId or String {
        return getElevationModeString(value);
    }

    public function getRenderModeStringL(value as Number) as ResourceId or String {
        return getRenderModeString(value);
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();

        if (itemId == :settingsGeneralModeDisplayOrder) {
            startPicker(
                new TextEditorPicker(
                    settings.method(:setModeDisplayOrder),
                    Settings.encodeCSV(settings.modeDisplayOrder),
                    view
                )
            );
        } else if (itemId == :settingsGeneralMode) {
            var enumView = new EnumMenu(
                Rez.Strings.modeTitle,
                method(:getModeStringL),
                settings.mode,
                MODE_MAX
            );

            // Add items to the end of the list, maybe we should make this generic?
            for (var i = 0; i < settings.dataFieldPageCounts.size(); i++) {
                var modeId = DATA_PAGE_BASE_ID + i;
                var isSelected = modeId == settings.mode;
                enumView.addItem(
                    new MenuItem(getModeStringL(modeId), isSelected ? "Selected" : "", modeId, {})
                );
            }
            WatchUi.pushView(
                enumView,
                new $.EnumDelegate(settings.method(:setMode), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsGeneralModeUiMode) {
            WatchUi.pushView(
                new EnumMenu(
                    Rez.Strings.uiModeTitle,
                    method(:getUiModeStringL),
                    settings.uiMode,
                    UI_MODE_MAX
                ),
                new $.EnumDelegate(settings.method(:setUiMode), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsGeneralModeElevationMode) {
            WatchUi.pushView(
                new EnumMenu(
                    Rez.Strings.elevationModeTitle,
                    method(:getElevationModeStringL),
                    settings.elevationMode,
                    ELEVATION_MODE_MAX
                ),
                new $.EnumDelegate(settings.method(:setElevationMode), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsGeneralRecalculateIntervalS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setRecalculateIntervalS),
                    settings.recalculateIntervalS,
                    view
                )
            );
        } else if (itemId == :settingsGeneralRenderMode) {
            WatchUi.pushView(
                new EnumMenu(
                    Rez.Strings.renderModeTitle,
                    method(:getRenderModeStringL),
                    settings.renderMode,
                    RENDER_MODE_MAX
                ),
                new $.EnumDelegate(settings.method(:setRenderMode), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsGeneralCenterUserOffsetY) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setCenterUserOffsetY),
                    settings.centerUserOffsetY,
                    view
                )
            );
        } else if (itemId == :settingsGeneralDisplayLatLong) {
            settings.toggleDisplayLatLong();
            view.rerender();
        } else if (itemId == :settingsGeneralUseStartForStop) {
            settings.toggleUseStartForStop();
            view.rerender();
        } else if (itemId == :settingsGeneralMapMoveScreenSize) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setMapMoveScreenSize),
                    settings.mapMoveScreenSize,
                    view
                )
            );
        }
    }
}

(:settingsView)
class SettingsTrackDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsTrack;
    function initialize(view as SettingsTrack) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getTrackStyleStringL(value as Number) as ResourceId or String {
        return getTrackStyleString(value);
    }

    public function getTrackPointReductionMethodStringL(value as Number) as ResourceId or String {
        return getTrackPointReductionMethodString(value);
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();

        if (itemId == :settingsTrackMaxTrackPoints) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMaxTrackPoints),
                    settings.maxTrackPoints,
                    view
                )
            );
        } else if (itemId == :settingsTrackTrackStyle) {
            // Push the style picker
            var menu = new EnumMenu(
                Rez.Strings.trackStyleTitle,
                method(:getTrackStyleStringL),
                settings.trackStyle,
                TRACK_STYLE_MAX
            );
            var delegate = new $.EnumDelegate(settings.method(:setTrackStyle), view);
            WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsTrackTrackWidth) {
            startPicker(
                new SettingsNumberPicker(settings.method(:setTrackWidth), settings.trackWidth, view)
            );
        } else if (itemId == :settingsTrackMinTrackPointDistanceM) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMinTrackPointDistanceM),
                    settings.minTrackPointDistanceM,
                    view
                )
            );
        } else if (itemId == :settingTrackTrackPointReductionMethod) {
            WatchUi.pushView(
                new EnumMenu(
                    Rez.Strings.trackPointReductionMethodTitle,
                    method(:getTrackPointReductionMethodStringL),
                    settings.trackPointReductionMethod,
                    TRACK_POINT_REDUCTION_METHOD_MAX
                ),
                new $.EnumDelegate(settings.method(:setTrackPointReductionMethod), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsTrackUseTrackAsHeadingSpeedMPS) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setUseTrackAsHeadingSpeedMPS),
                    settings.useTrackAsHeadingSpeedMPS,
                    view
                )
            );
        }
    }
}

(:settingsView)
class SettingsDataFieldDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsDataField;
    function initialize(view as SettingsDataField) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getDataTypeStringL(value as Number) as ResourceId or String {
        return getDataTypeString(value);
    }
    public function getFontSizeStringL(value as Number) as ResourceId or String {
        return getFontSizeString(value);
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();

        if (itemId == :settingsDataFieldTopDataType) {
            WatchUi.pushView(
                new EnumMenu(
                    "Data Type",
                    method(:getDataTypeStringL),
                    settings.topDataType,
                    DATA_TYPE_MAX
                ),
                new $.EnumDelegate(settings.method(:setTopDataType), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsDataFieldBottomDataType) {
            WatchUi.pushView(
                new EnumMenu(
                    "Data Type",
                    method(:getDataTypeStringL),
                    settings.bottomDataType,
                    DATA_TYPE_MAX
                ),
                new $.EnumDelegate(settings.method(:setBottomDataType), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsDataFieldTextSize) {
            WatchUi.pushView(
                new EnumMenu(
                    "Font Size",
                    method(:getFontSizeStringL),
                    settings.dataFieldTextSize,
                    5
                ),
                new $.EnumDelegate(settings.method(:setDataFieldTextSize), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsDataFieldAutoLapDistanceM) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setAutoLapDistanceM),
                    settings.autoLapDistanceM,
                    view
                )
            );
        } else if (itemId == :settingsDataFieldPages) {
            var view = new $.SettingsDataFieldPageList();
            WatchUi.pushView(
                view,
                new $.SettingsDataFieldPageListDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

(:settingsView)
class SettingsRoutesDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsRoutes;
    var settings as Settings;
    function initialize(view as SettingsRoutes, settings as Settings) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
        me.settings = settings;
    }

    function setRouteMax(value as Number) as Void {
        settings.setRouteMax(value);
        // reload our ui, so any route changes are cleared
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // remove the number picker view
        reloadView();
        WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the number picker to remove
    }

    function reloadView() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var view = new $.SettingsRoutes(settings);
        WatchUi.pushView(
            view,
            new $.SettingsRoutesDelegate(view, settings),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        if (itemId == :settingsRoutesEnabled) {
            settings.toggleRoutesEnabled();
            reloadView();
        } else if (itemId == :settingsDisplayRouteNames) {
            settings.toggleDisplayRouteNames();
            view.rerender();
        } else if (itemId == :settingsDisplayRouteMax) {
            startPicker(new SettingsNumberPicker(method(:setRouteMax), settings.routeMax(), view));
        } else if (itemId == :settingsRoutesClearAll) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.clearRoutes1) as String
            );
            WatchUi.pushView(dialog, new ClearRoutesDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }

        // itemId should now be the route storageIndex = routeId
        if (itemId instanceof Number) {
            var thisView = new $.SettingsRoute(settings, itemId, view);
            WatchUi.pushView(
                thisView,
                new $.SettingsRouteDelegate(thisView, settings),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

(:settingsView)
class SettingsRouteDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsRoute;
    var settings as Settings;
    function initialize(view as SettingsRoute, settings as Settings) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
        me.settings = settings;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        if (itemId == :settingsRouteName) {
            startPicker(
                new TextEditorPicker(view.method(:setName), settings.routeName(view.routeId), view)
            );
        } else if (itemId == :settingsRouteEnabled) {
            if (view.routeEnabled()) {
                view.setEnabled(false);
            } else {
                view.setEnabled(true);
            }
            view.rerender();
        } else if (itemId == :settingsRouteReversed) {
            if (view.routeReversed()) {
                view.setReversed(false);
            } else {
                view.setReversed(true);
            }
            view.rerender();
        } else if (itemId == :settingsRouteColour) {
            startPicker(
                new SettingsColourPickerTransparency(
                    view.method(:setColour),
                    view.routeColour(),
                    view,
                    false
                )
            );
        } else if (itemId == :settingsRouteColour2) {
            startPicker(
                new SettingsColourPickerTransparency(
                    view.method(:setColour2),
                    view.routeColour2(),
                    view,
                    true
                )
            );
        } else if (itemId == :settingsRouteDelete) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.routeDelete) as String
            );
            WatchUi.pushView(
                dialog,
                new DeleteRouteDelegate(view.routeId, settings),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsRouteStyle) {
            var menu = new EnumMenu(
                Rez.Strings.trackStyleTitle,
                method(:getTrackStyleStringL),
                view.settings.routeStyle(view.routeId),
                TRACK_STYLE_MAX
            );
            var delegate = new $.EnumDelegate(view.method(:setStyle), view);
            WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsRouteWidth) {
            startPicker(
                new SettingsNumberPicker(
                    view.method(:setWidth),
                    view.settings.routeWidth(view.routeId),
                    view
                )
            );
        }
    }

    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getTrackStyleStringL(value as Number) as ResourceId or String {
        return getTrackStyleString(value);
    }
}

(:settingsView)
class SettingsMapDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMap;
    function initialize(view as SettingsMap) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsMapEnabled) {
            settings.setMapEnabled(false);
            var view = new SettingsMapDisabled();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(
                view,
                new $.SettingsMapDisabledDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMapTileCacheSize) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setTileCacheSize),
                    settings.tileCacheSize,
                    view
                )
            );
        } else if (itemId == :settingsMapTileCachePadding) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setTileCachePadding),
                    settings.tileCachePadding,
                    view
                )
            );
        } else if (itemId == :settingsMapMaxPendingWebRequests) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMaxPendingWebRequests),
                    settings.maxPendingWebRequests,
                    view
                )
            );
        } else if (itemId == :settingsMapDisableMapsFailureCount) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setDisableMapsFailureCount),
                    settings.disableMapsFailureCount,
                    view
                )
            );
        } else if (itemId == :settingsMapHttpErrorTileTTLS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setHttpErrorTileTTLS),
                    settings.httpErrorTileTTLS,
                    view
                )
            );
        } else if (itemId == :settingsMapErrorTileTTLS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setErrorTileTTLS),
                    settings.errorTileTTLS,
                    view
                )
            );
        } else if (itemId == :settingsMapFixedLatitude) {
            var fixedLatitude = settings.fixedLatitude;
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setFixedLatitude),
                    fixedLatitude != null ? fixedLatitude : 0f,
                    view
                )
            );
        } else if (itemId == :settingsMapFixedLongitude) {
            var fixedLongitude = settings.fixedLongitude;
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setFixedLongitude),
                    fixedLongitude != null ? fixedLongitude : 0f,
                    view
                )
            );
        } else if (itemId == :settingsMapScaleRestrictedToTileLayers) {
            settings.toggleScaleRestrictedToTileLayers();
            view.rerender();
        } else if (itemId == :settingsMapAttribution) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsMapAttribution(),
                new $.SettingsMapAttributionDelegate(),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMapUseDrawBitmap) {
            settings.toggleUseDrawBitmap();
            view.rerender();
        } else if (itemId == :settingsMapPackingFormat) {
            WatchUi.pushView(
                new EnumMenu(
                    Rez.Strings.packingFormatTitle,
                    method(:getPackingFormatStringL),
                    settings.packingFormat,
                    4
                ),
                new $.EnumDelegate(settings.method(:setPackingFormat), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMapStorageSettings) {
            var view = new SettingsMapStorage();
            WatchUi.pushView(view, new $.SettingsMapStorageDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMapTileServerSettings) {
            var view = new SettingsTileServer();
            WatchUi.pushView(view, new $.SettingsTileServerDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getPackingFormatStringL(value as Number) as ResourceId or String {
        return getPackingFormatString(value);
    }
}

(:settingsView)
class SettingsTileServerDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsTileServer;
    function initialize(view as SettingsTileServer) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getMapChoiceStringL(value as Number) as ResourceId or String {
        return getMapChoiceString(value);
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsMapChoice) {
            WatchUi.pushView(
                new EnumMenu(
                    Rez.Strings.mapChoice,
                    method(:getMapChoiceStringL),
                    settings.mapChoice,
                    33
                ),
                new $.EnumDelegate(settings.method(:setMapChoice), view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsTileUrl) {
            startPicker(new TextEditorPicker(settings.method(:setTileUrl), settings.tileUrl, view));
        } else if (itemId == :settingsAuthToken) {
            startPicker(
                new TextEditorPicker(settings.method(:setAuthToken), settings.authToken, view)
            );
        } else if (itemId == :settingsMapTileSize) {
            startPicker(
                new SettingsNumberPicker(settings.method(:setTileSize), settings.tileSize, view)
            );
        } else if (itemId == :settingsMapFullTileSize) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setFullTileSize),
                    settings.fullTileSize,
                    view
                )
            );
        } else if (itemId == :settingsMapScaledTileSize) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setScaledTileSize),
                    settings.scaledTileSize,
                    view
                )
            );
        } else if (itemId == :settingsMapTileLayerMax) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setTileLayerMax),
                    settings.tileLayerMax,
                    view
                )
            );
        } else if (itemId == :settingsMapTileLayerMin) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setTileLayerMin),
                    settings.tileLayerMin,
                    view
                )
            );
        }
    }
}

(:settingsView)
class SettingsMapStorageDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMapStorage;
    function initialize(view as SettingsMapStorage) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsMapStorageCacheTilesInStorage) {
            settings.toggleCacheTilesInStorage();
            view.rerender();
        } else if (itemId == :settingsMapStorageStorageMapTilesOnly) {
            settings.toggleStorageMapTilesOnly();
            view.rerender();
        } else if (itemId == :settingsMapStorageStorageSeedBoundingBox) {
            settings.toggleStorageSeedBoundingBox();
            view.rerender();
        } else if (itemId == :settingsMapStorageStorageTileCacheSize) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setStorageTileCacheSize),
                    settings.storageTileCacheSize,
                    view
                )
            );
        } else if (itemId == :settingsMapStorageStorageTileCachePageCount) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setStorageTileCachePageCount),
                    settings.storageTileCachePageCount,
                    view
                )
            );
        } else if (itemId == :settingsMapStorageStorageSeedRouteDistanceM) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setStorageSeedRouteDistanceM),
                    settings.storageSeedRouteDistanceM,
                    view
                )
            );
        } else if (itemId == :settingsMapStorageCacheCurrentArea) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.startTileCache1) as String
            );
            WatchUi.pushView(dialog, new StartCachedTilesDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMapStorageCancelCacheDownload) {
            _breadcrumbContextLocal.cachedValues.cancelCacheCurrentMapArea();
            view.rerender();
        } else if (itemId == :settingsMapStorageClearCachedTiles) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.clearCachedTiles) as String
            );
            WatchUi.pushView(dialog, new ClearCachedTilesDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

(:settingsView)
class SettingsMapDisabledDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMapDisabled;
    function initialize(view as SettingsMapDisabled) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsMapEnabled) {
            settings.setMapEnabled(true);
            var view = new SettingsMap();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(view, new $.SettingsMapDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

(:settingsView)
function checkAlertViewDisplay(
    oldView as SettingsAlerts or SettingsAlertsDisabled,
    settings as Settings
) as Void {
    if (
        oldView instanceof SettingsAlerts &&
        !settings.offTrackWrongDirection &&
        !settings.enableOffTrackAlerts
    ) {
        var view = new SettingsAlertsDisabled();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(view, new $.SettingsAlertsDisabledDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    } else if (
        oldView instanceof SettingsAlertsDisabled &&
        (settings.offTrackWrongDirection || settings.enableOffTrackAlerts)
    ) {
        var view = new SettingsAlerts();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(view, new $.SettingsAlertsDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    } else {
        oldView.rerender();
    }
}

(:settingsView)
function onSelectAlertCommon(
    itemId as Object?,
    settings as Settings,
    view as SettingsAlerts or SettingsAlertsDisabled
) as Void {
    if (itemId == :settingsAlertsDrawLineToClosestPoint) {
        settings.toggleDrawLineToClosestPoint();
        view.rerender();
    } else if (itemId == :settingsAlertsEnabled) {
        settings.toggleEnableOffTrackAlerts();
        checkAlertViewDisplay(view, settings);
    } else if (itemId == :settingsAlertsOffTrackWrongDirection) {
        settings.toggleOffTrackWrongDirection();
        checkAlertViewDisplay(view, settings);
    } else if (itemId == :settingsAlertsDrawCheverons) {
        settings.toggleDrawCheverons();
        view.rerender();
    } else if (itemId == :settingsAlertsOffTrackDistanceM) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setOffTrackAlertsDistanceM),
                settings.offTrackAlertsDistanceM,
                view
            )
        );
    } else if (itemId == :settingsAlertsTurnAlertTimeS) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setTurnAlertTimeS),
                settings.turnAlertTimeS,
                view
            )
        );
    } else if (itemId == :settingsAlertsMinTurnAlertDistanceM) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setMinTurnAlertDistanceM),
                settings.minTurnAlertDistanceM,
                view
            )
        );
    } else if (itemId == :settingsAlertsOffTrackCheckIntervalS) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setOffTrackCheckIntervalS),
                settings.offTrackCheckIntervalS,
                view
            )
        );
    } else if (itemId == :settingsAlertsAlertType) {
        WatchUi.pushView(
            new EnumMenu(
                Rez.Strings.alertTypeTitle,
                (new GetAlertTypeStringLProxy()).method(:getAlertTypeStringL),
                settings.alertType,
                ALERT_TYPE_MAX
            ),
            new $.EnumDelegate(settings.method(:setAlertType), view),
            WatchUi.SLIDE_IMMEDIATE
        );
    }
}

class GetAlertTypeStringLProxy {
    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getAlertTypeStringL(value as Number) as ResourceId or String {
        return getAlertTypeString(value);
    }
}

(:settingsView)
class SettingsAlertsDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsAlerts;
    function initialize(view as SettingsAlerts) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();

        if (itemId == :settingsAlertsOffTrackAlertsMaxReportIntervalS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setOffTrackAlertsMaxReportIntervalS),
                    settings.offTrackAlertsMaxReportIntervalS,
                    view
                )
            );
            return;
        }

        onSelectAlertCommon(itemId, settings, view);
    }
}

(:settingsView)
class SettingsAlertsDisabledDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsAlertsDisabled;
    function initialize(view as SettingsAlertsDisabled) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        onSelectAlertCommon(itemId, settings, view);
    }
}

(:settingsView)
class DummyView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }
}

(:settingsView)
class ClearRoutesDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return false;
        }
        var settings = _breadcrumbContextLocal.settings;

        if (response == WatchUi.CONFIRM_YES) {
            _breadcrumbContextLocal.clearRoutes();

            // WARNING: this is a massive hack, probably dependant on platform
            // just poping the vew and replacing does not work, because the confirmation is still active whilst we are in this function
            // so we need to pop the confirmation too
            // but the confirmation is also about to call WatchUi.popView()
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop confirmation
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop routes view
            var view = new $.SettingsRoutes(settings);
            WatchUi.pushView(
                view,
                new $.SettingsRoutesDelegate(view, settings),
                WatchUi.SLIDE_IMMEDIATE
            ); // replace with new updated routes view
            WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the confirmation to pop
        }

        return true; // we always handle it
    }
}

(:settingsView)
class SettingsColoursDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsColours;
    function initialize(view as SettingsColours) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsColoursTrackColour) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setTrackColour),
                    settings.trackColour,
                    view,
                    false
                )
            );
        } else if (itemId == :settingsColoursTrackColour2) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setTrackColour2),
                    settings.trackColour2,
                    view,
                    true
                )
            );
        } else if (itemId == :settingsColoursDefaultRouteColour) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setDefaultRouteColour),
                    settings.defaultRouteColour,
                    view,
                    false
                )
            );
        } else if (itemId == :settingsColoursElevationColour) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setElevationColour),
                    settings.elevationColour,
                    view,
                    false
                )
            );
        } else if (itemId == :settingsColoursUserColour) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setUserColour),
                    settings.userColour,
                    view,
                    false
                )
            );
        } else if (itemId == :settingsColoursNormalModeColour) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setNormalModeColour),
                    settings.normalModeColour,
                    view,
                    false
                )
            );
        } else if (itemId == :settingsColoursUiColour) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setUiColour),
                    settings.uiColour,
                    view,
                    false
                )
            );
        } else if (itemId == :settingsColoursDataFieldPageColour) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setDataFieldPageColour),
                    settings.dataFieldPageColour,
                    view,
                    false
                )
            );
        } else if (itemId == :settingsColoursDataFieldPageColour2) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setDataFieldPageColour2),
                    settings.dataFieldPageColour2,
                    view,
                    false
                )
            );
        } else if (itemId == :settingsColoursDebugColour) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setDebugColour),
                    settings.debugColour,
                    view,
                    false
                )
            );
        }
    }
}

(:settingsView)
class SettingsDebugDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsDebug;
    function initialize(view as SettingsDebug) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsDebugTileErrorColour) {
            startPicker(
                new SettingsColourPickerTransparency(
                    settings.method(:setTileErrorColour),
                    settings.tileErrorColour,
                    view,
                    false
                )
            );
        } else if (itemId == :settingsDebugDrawLineToClosestTrack) {
            settings.toggleDrawLineToClosestTrack();
            view.rerender();
        } else if (itemId == :settingsDebugShowTileBorders) {
            settings.toggleShowTileBorders();
            view.rerender();
        } else if (itemId == :settingsDebugShowErrorTileMessages) {
            settings.toggleShowErrorTileMessages();
            view.rerender();
        } else if (itemId == :settingsDebugDrawHitBoxes) {
            settings.toggleDrawHitBoxes();
            view.rerender();
        } else if (itemId == :settingsDebugShowDirectionPoints) {
            settings.toggleShowDirectionPoints();
            view.rerender();
        } else if (itemId == :settingsDebugShowDirectionPointTextUnderIndex) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setShowDirectionPointTextUnderIndex),
                    settings.showDirectionPointTextUnderIndex,
                    view
                )
            );
        }
    }
}

(:settingsView)
function getFontSizeString(font as Number) as ResourceId or String {
    switch (font) {
        case Graphics.FONT_XTINY:
            return Rez.Strings.fontXTiny;
        case Graphics.FONT_TINY:
            return Rez.Strings.fontTiny;
        case Graphics.FONT_SMALL:
            return Rez.Strings.fontSmall;
        case Graphics.FONT_MEDIUM:
            return Rez.Strings.fontMedium;
        case Graphics.FONT_LARGE:
            return Rez.Strings.fontLarge;
        // numbers cannot be used because we add letters too, and the numbers fonts only renders numbers
        // case Graphics.FONT_NUMBER_MILD: return Rez.Strings.fontNumMild;
        // case Graphics.FONT_NUMBER_MEDIUM: return Rez.Strings.fontNumMedium;
        // case Graphics.FONT_NUMBER_HOT: return Rez.Strings.fontNumHot;
        // case Graphics.FONT_NUMBER_THAI_HOT: return Rez.Strings.fontNumThaiHot;
        // <!-- System Fonts seem to be almost the same, so save the space for the strings and code-->
        // case Graphics.FONT_SYSTEM_XTINY: return Rez.Strings.fontSysXTiny;
        // case Graphics.FONT_SYSTEM_TINY: return Rez.Strings.fontSysTiny;
        // case Graphics.FONT_SYSTEM_SMALL: return Rez.Strings.fontSysSmall;
        // case Graphics.FONT_SYSTEM_MEDIUM: return Rez.Strings.fontSysMedium;
        // case Graphics.FONT_SYSTEM_LARGE: return Rez.Strings.fontSysLarge;
        default:
            return "";
    }
}

(:settingsView)
function getTrackStyleString(style as Number) as ResourceId {
    switch (style) {
        case TRACK_STYLE_LINE:
            return Rez.Strings.trackStyleLine;
        case TRACK_STYLE_DASHED:
            return Rez.Strings.trackStyleDashed;
        case TRACK_STYLE_POINTS:
            return Rez.Strings.trackStylePoints;
        case TRACK_STYLE_POINTS_INTERPOLATED:
            return Rez.Strings.trackStylePointsInterp;
        case TRACK_STYLE_BOXES:
            return Rez.Strings.trackStyleBoxes;
        case TRACK_STYLE_BOXES_INTERPOLATED:
            return Rez.Strings.trackStyleBoxesInterp;
        case TRACK_STYLE_FILLED_SQUARE:
            return Rez.Strings.trackStyleFilledSquare;
        case TRACK_STYLE_FILLED_SQUARE_INTERPOLATED:
            return Rez.Strings.trackStyleFilledSquareInterp;
        case TRACK_STYLE_POINTS_OUTLINE:
            return Rez.Strings.trackStylePointsOutline;
        case TRACK_STYLE_POINTS_OUTLINE_INTERPOLATED:
            return Rez.Strings.trackStylePointsOutlineInterp;
        // --- Texture Styles ---
        case TRACK_STYLE_CHECKERBOARD:
            return Rez.Strings.trackStyleChecker;
        case TRACK_STYLE_HAZARD:
            return Rez.Strings.trackStyleHazard;
        case TRACK_STYLE_DOT_MATRIX:
            return Rez.Strings.trackStyleMatrix;
        case TRACK_STYLE_POLKA_DOT:
            return Rez.Strings.trackStylePolka;
        case TRACK_STYLE_DIAMOND:
            return Rez.Strings.trackStyleDiamond;
        default:
            return Rez.Strings.trackStyleLine;
    }
}

class EnumMenu extends WatchUi.Menu2 {
    function initialize(
        title as String or ResourceId,
        callback as (Method(value as Number) as ResourceId or String),
        current as Number,
        max as Number
    ) {
        Menu2.initialize({ :title => title });
        for (var i = 0; i < max; i++) {
            var label = callback.invoke(i);
            if (label.equals("")) {
                continue;
            }
            var isSelected = i == current;
            addItem(new MenuItem(label, isSelected ? "Selected" : "", i, {}));
        }
    }
}

(:settingsView)
class EnumDelegate extends WatchUi.Menu2InputDelegate {
    private var callback as (Method(value as Number) as Void);
    private var parent as Renderable;

    function initialize(callback as (Method(value as Number) as Void), parent as Renderable) {
        Menu2InputDelegate.initialize();
        self.callback = callback;
        self.parent = parent;
    }

    function onSelect(item as MenuItem) as Void {
        callback.invoke(item.getId() as Number);
        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
