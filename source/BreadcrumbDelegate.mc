import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

// see BreadcrumbDataFieldView if touch stops working
class BreadcrumbDelegate extends WatchUi.BehaviorDelegate {
    var _breadcrumbContext as BreadcrumbContext;
    private var _dragStartX as Number? = null;
    private var _dragStartY as Number? = null;

    function initialize(breadcrumbContext as BreadcrumbContext) {
        BehaviorDelegate.initialize();
        _breadcrumbContext = breadcrumbContext;
    }

    // onDrag is called when the user drags their finger across the screen
    // Handle map panning when the user drags their finger across the screen.
    function onDrag(dragEvent as WatchUi.DragEvent) as Lang.Boolean {
        // System.println("onDrag: " + dragEvent.getType());
        // Only handle drag events if we are in map move mode.
        // we also allow it on the normal track page, since we can handle drag events in apps unlike on datafields.
        // perhaps on touchscreen devices this should be the only way to move?
        // it can be a bit finicky though, some users might still prefer the tapping interface (so ill leave both)
        if (
            _breadcrumbContext.settings.mode != MODE_MAP_MOVE &&
            _breadcrumbContext.settings.mode != MODE_NORMAL &&
            _breadcrumbContext.settings.mode != MODE_MAP_MOVE_ZOOM &&
            _breadcrumbContext.settings.mode != MODE_MAP_MOVE_UP_DOWN &&
            _breadcrumbContext.settings.mode != MODE_MAP_MOVE_LEFT_RIGHT
        ) {
            return false;
        }

        var eventType = dragEvent.getType();
        var coords = dragEvent.getCoordinates();

        if (eventType == WatchUi.DRAG_TYPE_START) {
            // The user has started dragging. Record the initial coordinates.
            _dragStartX = coords[0];
            _dragStartY = coords[1];
        } else if (eventType == WatchUi.DRAG_TYPE_CONTINUE) {
            // The user is continuing a drag.
            // Safety check to ensure we have a starting point.
            var _dragStartXLocal = _dragStartX;
            var _dragStartYLocal = _dragStartY;
            if (_dragStartXLocal == null || _dragStartYLocal == null) {
                // some invalid state
                return true;
            }

            var cachedValues = _breadcrumbContext.cachedValues;

            // Calculate the distance dragged in pixels since the last event.
            var dx = (coords[0] as Number) - _dragStartXLocal;
            var dy = (coords[1] as Number) - _dragStartYLocal;

            // Update the stored coordinates to be the current point for the next continue event.
            _dragStartX = coords[0];
            _dragStartY = coords[1];

            var currentScale = cachedValues.currentScale;
            // Avoid division by zero if scale is not set.
            if (currentScale == 0.0f) {
                return true;
            }

            // Convert the pixel movement to meters using the current scale.
            var xMoveUnrotatedMeters = -dx / currentScale;
            var yMoveUnrotatedMeters = dy / currentScale;

            // Calculate the rotated movement to account for map orientation.
            var xMoveRotatedMeters =
                xMoveUnrotatedMeters * cachedValues.rotateCos +
                yMoveUnrotatedMeters * cachedValues.rotateSin;
            var yMoveRotatedMeters =
                -(xMoveUnrotatedMeters * cachedValues.rotateSin) +
                yMoveUnrotatedMeters * cachedValues.rotateCos;

            // Apply the calculated movement to the map's fixed position.
            cachedValues.moveLatLong(
                xMoveUnrotatedMeters,
                yMoveUnrotatedMeters,
                xMoveRotatedMeters,
                yMoveRotatedMeters
            );
        } else if (eventType == WatchUi.DRAG_TYPE_STOP) {
            // The user has stopped dragging. Reset the state variables.
            _dragStartX = null;
            _dragStartY = null;
        }

        return true;
    }

    function onFlick(flickEvent as WatchUi.FlickEvent) as Lang.Boolean {
        // var direction = flickEvent.getDirection();
        // System.println("Flick event deg: " + direction);

        return false; // let it propagate
    }

    function onSwipe(swipeEvent) {
        // prevent exit when we flick instead of drag
        // System.println("onSwipe: " + swipeEvent.getDirection());
        return true; // this has to be true to prevent the default onback handler (that quits the app)
    }

    // see BreadcrumbDataFieldView if touch stops working
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        if (onTapInner(evt)) {
            try {
                if (Attention has :vibrate) {
                    // quick little buzz to let them know the screen tap has been acknowledged (haptic feedback)
                    // might need to make this a setting to disable it?
                    var vibeData = [new Attention.VibeProfile(50, 100)];
                    // this is not documented that it throws, but got bit by the backlight, so protecting it too in order to always show our alerts
                    Attention.vibrate(vibeData);
                }
            } catch (e) {
                logE("failed to vibrate: " + e.getErrorMessage());
            }
            return true;
        }

        return false;
    }
    function onTapInner(evt as WatchUi.ClickEvent) as Boolean {
        var _viewLocal = $._view;
        if (_viewLocal != null && _viewLocal.imageAlert != null) {
            // any touch cancels the alert
            _viewLocal.imageAlert = null;
            return true;
        }
        // logT("got tap (x,y): (" + evt.getCoordinates()[0] + "," +
        //                evt.getCoordinates()[1] + ")");

        var coords = evt.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        var renderer = _breadcrumbContext.breadcrumbRenderer;
        var settings = _breadcrumbContext.settings;
        var cachedValues = _breadcrumbContext.cachedValues;

        var hitboxSize = renderer.hitboxSize;
        var halfHitboxSize = hitboxSize / 2.0f;

        if (settings.uiMode == UI_MODE_NONE) {
            return false;
        }

        if (cachedValues.seeding()) {
            // we are displaying the tile seed screen, only allow cancel
            if (y < hitboxSize) {
                // top of screen
                cachedValues.cancelCacheCurrentMapArea();
                return true;
            }
            return false;
        }

        if (renderer.handleStartCacheRoute(x, y)) {
            return true;
        }

        if (renderer.handleStartMapEnable(x, y)) {
            return true;
        }

        if (renderer.handleStartMapDisable(x, y)) {
            return true;
        }

        if (renderer.handleClearRoute(x, y)) {
            // returns true if it handles touches on top left
            // also blocks input if we are in the menu
            return true;
        }

        // perhaps put this into new class to handle touch events, and have a
        // renderer for that ui would allow us to switch out ui and handle touched
        // differently also will alow setting the scren height
        if (inHitbox(x, y, renderer.modeSelectX, renderer.modeSelectY, halfHitboxSize)) {
            // top right
            settings.nextMode();
            return true;
        }

        if (settings.mode == MODE_DEBUG || settings.mode == MODE_ELEVATION) {
            return false;
        }

        var xHalfPhysical = cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = cachedValues.yHalfPhysical; // local lookup faster

        if (inHitbox(x, y, renderer.returnToUserX, renderer.returnToUserY, halfHitboxSize)) {
            // return to users location
            // bottom left
            // reset scale to user tracking mode (we auto set it when enterring move mode so we do not get weird zooms when we are panning)
            // there is a chance the user already had a custom scale set (by pressing the +/- zoom  buttons on the track page)
            // but we will just clear it when they click 'go back to user', and it will now be whatever is in the 'zoom at pace' settings
            return renderer.returnToUser();
        }

        if (settings.mode == MODE_MAP_MOVE_ZOOM) {
            if (y < yHalfPhysical) {
                // anywhere top half of screen other than the mode button checked above
                renderer.incScale();
                return true;
            }

            renderer.decScale();
            return true;
        }

        if (settings.mode == MODE_MAP_MOVE_UP_DOWN) {
            if (y < yHalfPhysical) {
                // anywhere top half of screen other than the mode button checked above
                cachedValues.moveFixedPositionUp();
                return true;
            }

            cachedValues.moveFixedPositionDown();
            return true;
        }

        if (settings.mode == MODE_MAP_MOVE_LEFT_RIGHT) {
            if (x < xHalfPhysical) {
                // anywhere left half of screen other than the mode button checked above
                cachedValues.moveFixedPositionLeft();
                return true;
            }

            cachedValues.moveFixedPositionRight();
            return true;
        }

        if (inHitbox(x, y, renderer.clearRouteX, renderer.clearRouteY, halfHitboxSize)) {
            // bottom left
            if (settings.mode == MODE_MAP_MOVE) {
                renderer.decScale();
                return true;
            }
        }

        if (inHitbox(x, y, renderer.mapEnabledX, renderer.mapEnabledY, halfHitboxSize)) {
            // bottom right (or top right with useStartForStop enabled)
            if (settings.mode == MODE_MAP_MOVE) {
                renderer.incScale();
                return true;
            }
        }

        if (y < hitboxSize) {
            // top of screen
            if (settings.mode == MODE_MAP_MOVE) {
                cachedValues.moveFixedPositionUp();
                return true;
            } else if (settings.mode == MODE_NORMAL) {
                renderer.incScale();
                return true;
            }
        } else if (y > cachedValues.physicalScreenHeight - hitboxSize) {
            // bottom of screen
            if (settings.mode == MODE_MAP_MOVE) {
                cachedValues.moveFixedPositionDown();
                return true;
            } else if (settings.mode == MODE_NORMAL) {
                renderer.decScale();
                return true;
            }
        } else if (x > cachedValues.physicalScreenWidth - hitboxSize) {
            // right of screen
            if (settings.mode == MODE_MAP_MOVE) {
                cachedValues.moveFixedPositionRight();
                return true;
            }
            // handled by handleStartCacheRoute
            // cachedValues.startCacheCurrentMapArea();
            return false;
        } else if (x < hitboxSize) {
            // left of screen
            if (settings.mode == MODE_MAP_MOVE) {
                cachedValues.moveFixedPositionLeft();
                return true;
            } else if (settings.mode == MODE_NORMAL) {
                settings.nextZoomAtPaceMode();
                return true;
            }
        }

        return false;
    }

    public function onMenu() as Boolean {
        var settingsView = getApp().myGetSettingsView();
        WatchUi.pushView(settingsView[0], settingsView[1], WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    // public function onSelect() as Boolean {
    // onselect never seems to work on venu2s, but KEY_ENTER works on all products
    // }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        logT("got key event: " + key);

        var cachedValues = _breadcrumbContext.cachedValues;

        if (cachedValues.seeding()) {
            if (key == WatchUi.KEY_ESC) {
                cachedValues.cancelCacheCurrentMapArea();
                return true;
            }

            return false;
        }

        var settings = _breadcrumbContext.settings;
        var renderer = _breadcrumbContext.breadcrumbRenderer;

        if (
            (key == WatchUi.KEY_ENTER && !_breadcrumbContext.settings.useStartForStop) ||
            (key == WatchUi.KEY_ESC && _breadcrumbContext.settings.useStartForStop)
        ) {
            _breadcrumbContext.settings.nextMode();
            return true;
        } else if (
            (key == WatchUi.KEY_ESC && !_breadcrumbContext.settings.useStartForStop) ||
            (key == WatchUi.KEY_ENTER && _breadcrumbContext.settings.useStartForStop)
        ) {
            var confirmationView = new WatchUi.Confirmation("Exit?");
            var delegate = new DiscardConfirmationDelegate(_breadcrumbContext);

            // Push the confirmation view to the user.
            WatchUi.pushView(confirmationView, delegate, WatchUi.SLIDE_IMMEDIATE);

            return true;
        } else if (key == WatchUi.KEY_UP_LEFT || key == WatchUi.KEY_UP) {
            if (settings.mode == MODE_MAP_MOVE_ZOOM) {
                renderer.incScale();
            } else if (settings.mode == MODE_MAP_MOVE_UP_DOWN) {
                cachedValues.moveFixedPositionUp();
            } else if (settings.mode == MODE_MAP_MOVE_LEFT_RIGHT) {
                cachedValues.moveFixedPositionLeft();
            } else if (settings.mode == MODE_NORMAL) {
                settings.nextZoomAtPaceMode();
            }
        } else if (key == WatchUi.KEY_DOWN_LEFT || key == WatchUi.KEY_DOWN) {
            if (settings.mode == MODE_MAP_MOVE_ZOOM) {
                renderer.decScale();
            } else if (settings.mode == MODE_MAP_MOVE_UP_DOWN) {
                cachedValues.moveFixedPositionDown();
            } else if (settings.mode == MODE_MAP_MOVE_LEFT_RIGHT) {
                cachedValues.moveFixedPositionRight();
            } else if (settings.mode == MODE_ELEVATION) {
                /* todo launch clear route confirmation, and render button hint */
            } else if (settings.mode == MODE_NORMAL || settings.mode == MODE_MAP_MOVE) {
                renderer.returnToUser();
            }
        }

        return false;
    }

    // function onPreviousPage() as Boolean {
    //     System.println("onPreviousPage");
    //     drag events are handled for map panning, key events are handled in onKey
    //     because on touchscreens onPreviousPage and all the flick/drags are called when the user flicks the screen
    //     return false; // let it propagate
    // }

    //function onNextPage() as Boolean {
    //     System.println("onNextPage");
    //     drag events are handled for map panning, key events are handled in onKey
    //     because on touchscreens onPreviousPage and all the flick/drags are called when the user flicks the screen
    //     return false; // let it propagate
    //}

    // public function onBack() as Boolean {
    // touchscreens swipe right to call onback, prevent this, as we only want it to happen on key press
    // the swipe could be from a map pan drag and get misinterpreted as an onback
    // System.println("onBack");
    // return false; // let it propagate to the onKey handler
    //}
}

// A delegate to handle the response from a confirmation dialog.
class DiscardConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    var _breadcrumbContext as BreadcrumbContext;

    function initialize(context as BreadcrumbContext) {
        ConfirmationDelegate.initialize();
        _breadcrumbContext = context;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            System.exit();
        }
        return true;
    }
}
