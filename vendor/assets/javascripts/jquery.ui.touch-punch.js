/*!
 * jQuery UI Touch Punch 0.2.3
 *
 * Copyright 2011–2014, Dave Furfero
 * Dual licensed under the MIT or GPL Version 2 licenses.
 *
 * Depends:
 * jquery.ui.widget.js
 * jquery.ui.mouse.js
 */
(function ($) {

  // Detect touch support
  $.support.touch = 'ontouchend' in document;

  // Ignore browsers without touch support
  if (!$.support.touch) {
    return;
  }

  var mouseProto = $.ui.mouse.prototype,
    _mouseInit = mouseProto._mouseInit,
    _mouseDestroy = mouseProto._mouseDestroy,
    touchHandled;

  /**
   * Simulate a mouse event based on a corresponding touch event
   * @param {Object} event A touch event
   * @param {String} simulatedType The corresponding mouse event
   */
  function simulateMouseEvent (event, simulatedType) {

    // Ignore multi-touch events
    if (event.originalEvent.touches.length > 1) {
      return;
    }

    event.preventDefault();

    var touch = event.originalEvent.changedTouches[0],
      simulatedEvent = document.createEvent('MouseEvents');

    simulatedEvent.initMouseEvent(
      simulatedType,
      true,
      true,
      window,
      1,
      touch.screenX,
      touch.screenY,
      touch.clientX,
      touch.clientY,
      false,
      false,
      false,
      false,
      0,
      null
    );

    event.target.dispatchEvent(simulatedEvent);
  }

  mouseProto._touchStart = function (event) {

    var self = this;

    if (touchHandled || !self._mouseCapture(event.originalEvent.changedTouches[0])) {
      return;
    }

    touchHandled = true;
    self._touchMoved = false;

    // Skip mousemove on touchstart so jQuery UI sortable delay (long-press) works.
    simulateMouseEvent(event, 'mouseover');
    simulateMouseEvent(event, 'mousedown');
  };

  mouseProto._touchMove = function (event) {

    if (!touchHandled) {
      return;
    }

    this._touchMoved = true;
    simulateMouseEvent(event, 'mousemove');
  };

  mouseProto._touchEnd = function (event) {

    if (!touchHandled) {
      return;
    }

    simulateMouseEvent(event, 'mouseup');
    simulateMouseEvent(event, 'mouseout');

    if (!this._touchMoved) {
      simulateMouseEvent(event, 'click');
    }

    touchHandled = false;
  };

  mouseProto._mouseInit = function () {

    var self = this;

    self.element.bind({
      touchstart: $.proxy(self, '_touchStart'),
      touchmove: $.proxy(self, '_touchMove'),
      touchend: $.proxy(self, '_touchEnd')
    });

    _mouseInit.call(self);
  };

  mouseProto._mouseDestroy = function () {

    var self = this;

    self.element.unbind({
      touchstart: $.proxy(self, '_touchStart'),
      touchmove: $.proxy(self, '_touchMove'),
      touchend: $.proxy(self, '_touchEnd')
    });

    _mouseDestroy.call(self);
  };

})(jQuery);
