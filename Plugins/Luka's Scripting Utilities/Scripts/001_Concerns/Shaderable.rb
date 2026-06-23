#===============================================================================
#  Luka's Scripting Utilities
#
#  * Various object extensions
#===============================================================================
module LUTS
  # Concern mixins for extended object functionality.
  module Concerns
    # Shaderable concern that implements new shader functionality for supported objects.
    # Provides methods to add, remove, and retrieve shaders applied to sprites.
    module Shaderable
      # Adds a shader to the sprite's shader array.
      # @param key [Symbol, Shader] shader key symbol or Shader instance
      # @param properties [Hash] optional properties to pass to new shader
      # @return [void]
      def add_shader(key, properties = {})
        shader = key.is_a?(Shader) ? key : Shader.new(key, properties)

        self.shaders = shaders + [shader]
      end

      # Removes shader from sprite by key, index, or instance.
      # @param key [Symbol, Integer, Shader] shader identifier to remove
      # @return [void]
      def remove_shader(key)
        self.shaders = shaders.reject.with_index do |shader, i|
          (key.is_a?(Integer) && i.eql?(key)) ||
            (key.is_a?(Symbol) && shader.key.eql?(key)) ||
            (key.is_a?(Shader) && shader.eql?(key))
        end
      end

      # Retrieves a shader by key or index.
      # @param key [Symbol, Integer] shader key symbol or array index
      # @return [Shader] the shader instance, or nil if not found
      def get_shader(key)
        return shaders[key] if key.is_a?(Integer)

        shaders.find { |shader| shader.key.eql?(key) }
      end

      # Disposes all applied shaders and clears the shader array.
      # @return [void]
      def dispose_shaders
        shaders.each(&:dispose)
        self.shaders = []
      end
    end
  end
end
