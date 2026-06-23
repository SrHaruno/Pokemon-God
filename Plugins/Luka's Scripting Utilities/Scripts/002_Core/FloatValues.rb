#===============================================================================
#  Luka's Scripting Utilities
#
#  New class to handle float values for smooth calculations.
#===============================================================================
class FloatValues
  # Stores float values for sprite properties, allowing smooth animations and calculations.
  # @return [Array<Symbol>]
  METHODS = [
    :x, :y, :ox, :oy, :width, :height, :opacity, :angle
  ].freeze

  # A bit of metaprogramming to define setters and getters for above method names
  METHODS.each do |name|
    # Defines the getter function
    attr_reader name

    # Defines the setter function
    define_method(:"#{name}=") do |value|
      instance_variable_set(:"@#{name}", value)
      object.send(:"#{name}=", value) if object.respond_to?(:"#{name}=")
    end
  end

  # Initializes float value storage for an object.
  # @param object [Object] the object whose properties to track as floats
  # @return [void]
  def initialize(object)
    @object = object

    # Initializes beginning values
    METHODS.each do |name|
      instance_variable_set(:"@#{name}", (@object.respond_to?(name) ? @object.send(name) : 0))
    end
  end

  private

  # Returns the object being tracked by this float values instance.
  # @return [Object] the tracked object
  attr_reader :object
end
