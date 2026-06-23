#===============================================================================
#  Luka's Scripting Utilities
#
#  * Various object extensions
#===============================================================================
module LUTS
  # Provides a convenient interface for defining and playing sprite animations from arrays.
  # Requires the including class to have `sprites`, `viewport`, and `update` methods.
  # Animation arrays use format: [duration, {sprite_key: {attribute: value}}].
  # @note Must be included in a class with required sprite management methods
  module QuickAnimatable
    # Plays all animations in the quick animation array sequentially.
    # @return [void]
    def play_quick_animation
      return unless validate_animation_class

      quick_animation_array.each do |value|
        duration, anim = value
        Graphics.animate(duration) do
          anim.each do |key, args|
            (key.eql?(:viewport) ? viewport : sprites[key]).animate(**args)
          end

          update
        end
      end
    end

    private

    # Returns the array of animations to play.
    # @return [Array<[Integer, Hash]>] animation frames with sprite attribute updates
    # @raise [NotImplementedError] if not implemented in including class
    def quick_animation_array
      raise NotImplementedError
    end

    # Validates that the including class has all required methods for animation.
    # @return [Boolean] true if all required methods are present
    def validate_animation_class
      [:sprites, :viewport, :update].each do |func|
        unless respond_to?(func, true)
          LUTS::ErrorMessages::MissingFunctionError.new(self.class.name, func).raise
          return false
        end
      end

      true
    end
  end
end
