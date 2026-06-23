#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `Sprite` class
#===============================================================================
class ::Sprite
  # Allows sprite components to be animated easily
  include LUTS::Concerns::Animatable
  # Allows sprite components to use float values for smooth calculations
  include LUTS::Concerns::Floatable
  # Adds DSL for shader usage
  include LUTS::Concerns::Shaderable

  # Checks if sprite is currently visible within viewport bounds.
  # @return [Boolean] true if sprite is within viewport, false otherwise
  def in_viewport?
    return false unless viewport

    !(apparent_x + apparent_width  < viewport.x - 64 ||
      apparent_y + apparent_height < viewport.x - 64 ||
      apparent_x > viewport.x + viewport.width + 64 ||
      apparent_y > viewport.x + viewport.width + 64)
  end

  # Returns the apparent horizontal position accounting for origin and zoom.
  # @return [Numeric] adjusted x position
  def apparent_x
    x - ox * zoom_x
  end

  # Returns the apparent vertical position accounting for origin and zoom.
  # @return [Numeric] adjusted y position
  def apparent_y
    y - oy * zoom_y
  end

  # Returns the apparent width accounting for zoom level.
  # @return [Numeric] adjusted width
  def apparent_width
    src_rect.width * zoom_x
  end

  # Returns the apparent height accounting for zoom level.
  # @return [Numeric] adjusted height
  def apparent_height
    src_rect.height * zoom_y
  end
end
