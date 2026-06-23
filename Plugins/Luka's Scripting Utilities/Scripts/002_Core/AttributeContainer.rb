#===============================================================================
#  Luka's Scripting Utilities
#
#  New `AttributeContainer` class for defining quick getter/setter with
#  default values
#===============================================================================
# Container base class for declaring attributes with default values, defining
# accessors (and predicate methods for booleans) on the fly.
class AttributeContainer
  class << self
    # Defines setter and getter methods for a new attribute.
    # @param key [Symbol] attribute name
    # @param default [Object] default value assigned on initialization
    # @return [void]
    def with_attribute(key, default: nil)
      attribute_list[key] = default

      if default.is_a?(TrueClass) || default.is_a?(FalseClass)
        # Creates accessor and predicate methods for boolean attributes
        attr_accessor(key)

        define_method(:"#{key}?") do
          instance_variable_get("@#{key}")
        end
      else
        # Creates accessor methods for non-boolean attributes
        attr_accessor(key)
      end
    end

    # Registered attributes and their default values.
    # @return [Hash{Symbol => Object}] attribute names mapped to defaults
    def attribute_list
      @attribute_list ||= {}
    end

    # Copies the attribute list to inheriting subclasses.
    # @param subclass [Class] class inheriting from this container
    # @return [void]
    def inherited(subclass)
      subclass.instance_variable_set(:@attribute_list, attribute_list.dup)
    end
  end

  # Initializes the container with registered default attribute values.
  # @return [AttributeContainer] new container instance
  def initialize
    self.class.attribute_list.each do |key, value|
      instance_variable_set("@#{key}", value.dup)
    end
  end
end
