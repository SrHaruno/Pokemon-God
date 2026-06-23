#===============================================================================
#  Luka's Scripting Utilities
#
#  * Various object extensions
#===============================================================================
module LUTS
  # Concern mixins for extended object functionality.
  module Concerns
    # Allows objects to accept a block during initialization, providing a convenient alternative to `.tap`.
    module BlockConstructor
      alias with_block_constructor_initialize initialize

      # Initializes the object and optionally calls a provided block with the new instance.
      # @param args [Array] arguments to pass to the original initialize method
      # @param block [Proc] optional block to call with the new instance
      # @return [void]
      def initialize(*args, &block)
        with_block_constructor_initialize(*args)

        block.call(self) if block_given?
      end
    end
  end
end
