#===============================================================================
#  Luka's Scripting Utilities
#
#  Adds easy to use mouse functionality for your Essentials code
#===============================================================================
# Adds easy to use mouse input functionality (clicks, holds, scrolling and
#   dragging) along with mixins for sprites, viewports and rects.
module Mouse
  # Time in seconds within which a press counts as a click
  # @return [Numeric]
  CLICK_TIMEOUT = 0.5

  # Mouse button input map
  # @return [Hash{Symbol => Integer}]
  INPUTS = {
    left: Input::MOUSELEFT,
    right: Input::MOUSERIGHT,
    middle: Input::MOUSEMIDDLE
  }.freeze

  # Module-level mouse input functions
  class << self
    # Checks whether the mouse cursor is inside the game window.
    # @return [Boolean] mouse is in game window
    def active?
      Input.mouse_in_window?
    end

    # Shows mouse cursor in game window
    # @return [void]
    def show
      Graphics.show_cursor = true
    end

    # Hides mouse cursor in game window
    # @return [void]
    def hide
      Graphics.show_cursor = false
    end

    # Checks whether the mouse button was clicked (pressed and released
    #   within the click timeout).
    # @param button [Symbol] mouse button to check
    # @return [Boolean] mouse button clicked
    def click?(button = :left)
      return false if @drag
      return @hold = 0 || true if !press?(button) && @hold&.between?(1, CLICK_TIMEOUT * Graphics.frame_rate)

      @hold ||= 0
      if press?(button)
        @hold += 1
      else
        @hold = 0
      end

      false
    end

    # Checks whether the mouse button is currently pressed.
    # @param button [Symbol] mouse button to check
    # @return [Boolean] mouse button pressed
    def press?(button = :left)
      Input.press?(INPUTS[button])
    end

    # Checks whether the mouse button was just released.
    # @param button [Symbol] mouse button to check
    # @return [Boolean] mouse button released
    def release?(button = :left)
      Input.release?(INPUTS[button])
    end

    # Checks whether the mouse button input is repeating.
    # @param button [Symbol] mouse button to check
    # @return [Boolean] mouse button repeated
    def repeat?(button = :left)
      Input.repeat?(INPUTS[button])
    end

    # Checks whether the mouse button is held longer than the click timeout.
    # @param button [Symbol] mouse button to check
    # @return [Boolean] mouse button held
    def hold?(button)
      press?(button) && Input.time?(INPUTS[button]) > CLICK_TIMEOUT * 1_000_000
    end

    # Checks whether the mouse wheel scrolled up, optionally only within a rect.
    # @param rect [Rect] optional area the mouse must be over
    # @return [Boolean] mouse scroll up
    def scroll_up?(rect = nil)
      return false if rect && !over?(rect)

      Input.scroll_v.positive?
    end

    # Checks whether the mouse wheel scrolled down, optionally only within a rect.
    # @param rect [Rect] optional area the mouse must be over
    # @return [Boolean] mouse scroll down
    def scroll_down?(rect = nil)
      return false if rect && !over?(rect)

      Input.scroll_v.negative?
    end

    # Checks whether the mouse cursor is over the given object.
    # @param object [Object] object responding to `mouse_params`
    # @return [Boolean] mouse is over supported object
    def over?(object)
      return false unless object.respond_to?(:mouse_params)

      ox, oy, ow, oh = object.mouse_params

      Input.mouse_x.between?(ox, ox + ow) && Input.mouse_y.between?(oy, oy + oh)
    end

    # Checks whether the mouse cursor is within the specified area.
    # @param arx [Integer] X coordinate
    # @param ary [Integer] Y coordinate
    # @param arw [Integer] width
    # @param arh [Integer] height
    # @return [Boolean] mouse is in specified area
    def over_area?(arx, ary, arw, arh)
      Rect.new(arx, ary, arw, arh).over?
    end

    # Creates rectangle from mouse drag selection
    # @param button [Symbol] mouse button to track
    # @return [Rect] current selection rectangle (empty when not dragging)
    def create_rect(button = :left)
      if press?(button)
        @rect_x ||= x
        @rect_y ||= y

        rx = x < @rect_x ? x : @rect_x
        ry = y < @rect_y ? y : @rect_y
        rw = x < @rect_x ? @rect_x - x : x - @rect_x
        rh = y < @rect_y ? @rect_y - y : y - @rect_y

        return Rect.new(rx, ry, rw, rh)
      end

      @rect_x = nil
      @rect_y = nil
      Rect.new(0, 0, 0, 0)
    end

    # Checks whether the object is currently being dragged with the mouse.
    # @param object [Object] object responding to `mouse_params`
    # @param button [Symbol] mouse button to track
    # @return [Boolean] object is being dragged with mouse
    def dragging?(object, button = :left)
      unless (over?(object) || @drag.eql?(object)) && press?(button)
        @drag = nil    unless press?(button)
        @object_ox = 0 unless press?(button)
        @object_oy = 0 unless press?(button)
        return false
      end

      @drag = [Input.mouse_x, Input.mouse_y] if @drag.nil?
      if @drag.is_a?(Array) && !(@drag[0].eql?(Input.mouse_x) && @drag[1].eql?(Input.mouse_y))
        @drag = object
        @object_ox = Input.mouse_x - object.x
        @object_oy = Input.mouse_y - object.y
      end

      true
    end

    # Method to drag object using mouse
    # @param object [Object] object being dragged
    # @param button [Symbol] mouse button to track
    # @param rect [Rect] creates a maximum dragging area
    # @param lock [Symbol] drag lock direction
    # @return [Boolean] object is being dragged
    def drag_object(object, button = :left, rect = nil, lock = nil)
      return false unless dragging?(object, button) && @drag.eql?(object)

      object.x = Input.mouse_x - (@object_ox || 0) unless lock.eql?(:vertical)
      object.y = Input.mouse_y - (@object_oy || 0) unless lock.eql?(:horizontal)
      return true unless rect.is_a?(Rect)

      rx, ry, rw, rh = rect.mouse_params
      _ox, _oy, ow, oh = object.mouse_params
      object.x = rx if object.x < rx && !lock.eql?(:vertical)
      object.y = ry if object.y < ry && !lock.eql?(:horizontal)
      object.x = rx + rw - ow if object.x > rx + rw - ow && !lock.eql?(:vertical)
      object.y = ry + rh - oh if object.y > ry + rh - oh && !lock.eql?(:horizontal)

      true
    end

    # Method to drag object only on the X axis
    # @param object [Object] object being dragged
    # @param button [Symbol] mouse button to track
    # @param rect [Rect] creates a maximum dragging area
    # @return [Boolean] object is being dragged
    def drag_object_x(object, button = :left, rect = nil)
      drag_object(object, button, rect, :horizontal)
    end

    # Method to drag object only on the Y axis
    # @param object [Object] object being dragged
    # @param button [Symbol] mouse button to track
    # @param rect [Rect] creates a maximum dragging area
    # @return [Boolean] object is being dragged
    def drag_object_y(object, button = :left, rect = nil)
      drag_object(object, button, rect, :vertical)
    end
  end

  # Sprite class extensions
  module Sprite
    # Calculates the sprite's on-screen mouse interaction area.
    # @param pure [Boolean] only actual values (non-transformative)
    # @return [Array<Integer>] x, y, width and height values
    def mouse_params(pure: false)
      return [x, y, width, height] if pure

      sox = x - ox + (viewport ? viewport.rect.x : 0)
      soy = y - oy + (viewport ? viewport.rect.y : 0)
      sow = bitmap ? bitmap.width * zoom_x : 0
      soh = bitmap ? bitmap.height * zoom_y : 0

      if src_rect
        sow = src_rect.width * zoom_x unless src_rect.width.eql?(sow)
        soh = src_rect.height * zoom_y unless src_rect.height.eql?(soh)
      end

      [sox, soy, sow, soh]
    end

    # Checks whether the mouse is over a non-transparent pixel of the sprite.
    # @return [Boolean] if alpha of pixel is greater than 0
    def over_pixel?
      return false unless over? && bitmap

      ox, oy = mouse_params

      bitmap.get_pixel(x - ox, y - oy).alpha.positive?
    end
  end

  # Viewport class extensions
  module Viewport
    # Calculates the viewport's on-screen mouse interaction area.
    # @return [Array<Integer>] x, y, width and height values
    def mouse_params
      [rect.x, rect.y, rect.width, rect.height]
    end
  end

  # Rect class extensions
  module Rect
    # Calculates the rect's on-screen mouse interaction area.
    # @return [Array<Integer>] x, y, width and height values
    def mouse_params
      [x, y, width, height]
    end
  end

  # Shared extensions
  module Extensions
    # Checks whether the object was clicked with the mouse.
    # @return [Boolean] mouse clicked over object
    def click?
      over? && Mouse.click?
    end

    # Checks whether the mouse is pressed over the object.
    # @return [Boolean] mouse pressed over object
    def press?
      over? && Mouse.press?
    end

    # Checks whether the mouse cursor is over the object.
    # @return [Boolean] mouse is over object
    def over?
      Mouse.over?(self)
    end

    # Drags object
    # @param rect [Rect] creates a maximum dragging area
    # @return [Boolean] object is being dragged
    def mouse_drag(rect = nil)
      Mouse.drag_object(self, :left, rect)
    end

    # Drags object on X axis
    # @param rect [Rect] creates a maximum dragging area
    # @return [Boolean] object is being dragged
    def mouse_drag_x(rect = nil)
      Mouse.drag_object_x(self, :left, rect)
    end

    # Drags object on Y axis
    # @param rect [Rect] creates a maximum dragging area
    # @return [Boolean] object is being dragged
    def mouse_drag_y(rect = nil)
      Mouse.drag_object_y(self, :left, rect)
    end

    # Checks whether this object's area overlaps the target's area.
    # @param target [Object] object responding to `mouse_params`
    # @return [Boolean] areas overlap
    def overlap?(target)
      obj_x, obj_y, obj_w, obj_h = mouse_params
      tar_x, tar_y, tar_w, tar_h = target.mouse_params

      !(obj_x + obj_w < tar_x || obj_y + obj_h < tar_y || obj_x > tar_x + tar_w || obj_y > tar_y + tar_h)
    end

    # Checks whether the mouse was released while this object overlaps the target.
    # @param target [Object] object responding to `mouse_params`
    # @return [Boolean] mouse released over target
    def released_in?(target)
      overlap?(target) && Mouse.release?
    end

    # Checks whether the mouse was released while this object is inside the rect.
    # @param target [Rect] area to check against
    # @return [Boolean] mouse released inside rect
    def released_in_rect?(target)
      x.between?(target.x, target.x + target.width) && y.between?(target.y, target.y + target.height) && Mouse.release?
    end
  end
end

#-------------------------------------------------------------------------------
# Add mouse functionality to various classes
#-------------------------------------------------------------------------------
# FloatSprite extension to add mouse functionality.
class ::FloatSprite
  include Mouse::Extensions
  include Mouse::Sprite
end

# Sprite extension to add mouse functionality.
class Sprite
  include Mouse::Extensions
  include Mouse::Sprite
end

# Rect extension to add mouse functionality.
class ::Rect
  include Mouse::Extensions
  include Mouse::Rect
end

# Viewport extension to add mouse functionality.
class ::Viewport
  include Mouse::Extensions
  include Mouse::Viewport
end
