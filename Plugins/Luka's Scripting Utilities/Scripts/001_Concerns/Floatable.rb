#===============================================================================
#  Luka's Scripting Utilities
#
#  * Various object extensions
#===============================================================================
# Namespace for Luka's scripting utilities.
module LUTS
  # Mixin concerns for shared object behaviour.
  module Concerns
    # Floatable concern that implents new float value components for smooth
    # calculations.
    module Floatable
      # Returns the float value components for the object
      # @return [FloatValues] float value wrapper for smooth calculations
      def float
        @float ||= FloatValues.new(self)
      end
    end
  end
end
