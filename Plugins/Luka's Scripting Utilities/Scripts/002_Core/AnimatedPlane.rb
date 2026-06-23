#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `AnimatedPlane` class
#===============================================================================
# Core extensions for the `AnimatedPlane` class, adding animation tracking
# coordinates.
class AnimatedPlane < Plane
  # @return [Numeric] tracked x coordinate used by animations
  attr_accessor :end_x
  # @return [Numeric] tracked y coordinate used by animations
  attr_accessor :end_y
end
