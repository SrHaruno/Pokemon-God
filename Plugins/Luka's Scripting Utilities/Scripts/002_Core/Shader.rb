#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `Shader` class
#===============================================================================
# Core extensions for the mkxp-z `Shader` class, loading GLSL files by key and
# applying configurable uniform properties.
class Shader
  # Custom error class for shader components
  class ShaderError < StandardError
  end

  # Preserve original mkxp-z constructor and disposal
  alias initialize_mkxp_shaders initialize unless method_defined?(:initialize_mkxp_shaders)
  alias dispose_mkxp_shaders dispose if method_defined?(:dispose) && !method_defined?(:dispose_mkxp_shaders)

  # @return [Symbol] shader file identifier
  attr_reader :key

  # Class constructor. Loads the GLSL shader file and applies given properties.
  # @param key [Symbol] shader file identifier
  # @param properties [Hash] uniform properties to set on the shader
  # @return [Shader] new shader instance
  def initialize(key, properties = {})
    @key        = key
    @disposed   = false
    @properties = properties
    validate

    initialize_mkxp_shaders(path)
    set_properties
  end

  # Disposes active shader
  # @return [void]
  def dispose
    return if disposed?

    dispose_mkxp_shaders
    @disposed = true
  end

  # Checks if the shader has been disposed.
  # @return [Boolean] whether the shader is disposed
  def disposed?
    @disposed
  end

  private

  # @return [Hash] uniform properties passed to the constructor
  attr_reader :properties

  # Full path to the GLSL shader file.
  # @return [String] shader file path
  def path
    @path ||= "Data/Shaders/#{key}.glsl"
  end

  # Validate file path. Raises if the shader file does not exist.
  # @return [void]
  def validate
    return if FileTest.exist?(path)

    raise ShaderError, "No such file exists: `#{path}`."
  end

  # Sets optional properties as shader uniforms based on their value arity.
  # @return [void]
  def set_properties
    properties.each do |key, value|
      values = Array(value)

      case values.count
      when 1
        if values.first.is_a?(Bitmap)
          set_bitmap(key.to_s, values.first)
        elsif values.first.is_a?(String)
          set_bitmap(key.to_s, Bitmap.new(values.first))
        else
          set_float(key.to_s, values.first.to_f)
        end
      when 2 then set_vec2(key.to_s, *values)
      when 3 then set_vec3(key.to_s, *values)
      when 4 then set_vec4(key.to_s, *values)
      end
    end
  end
end
