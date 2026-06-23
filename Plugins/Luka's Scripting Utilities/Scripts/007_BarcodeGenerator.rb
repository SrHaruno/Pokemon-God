#===============================================================================
#  Luka's Scripting Utilities
#
#  UPC-A barcode generator
#
#  Generates a barcode bitmap following the UPC-A standard.
#    Barcodes allow a maximum of 11 digits, with the 12th digit
#    Always being the final control digit.
#===============================================================================
# Generates UPC-A barcode bitmaps from a numeric value of up to 11 digits,
# appending the standard control digit automatically.
class BarcodeGenerator
  # Custom error raised when the input is not an integer.
  class TypeError < ArgumentError
    # Sets the default error message.
    # @return [BarcodeGenerator::TypeError] new error instance
    def initialize
      super('Wrong input type. Only integer values allowed.')
    end
  end

  # Custom error raised when the input exceeds 11 digits.
  class SizeError < ArgumentError
    # Sets the default error message.
    # @return [BarcodeGenerator::SizeError] new error instance
    def initialize
      super('Wrong input size. Max number of digits allowed is 11.')
    end
  end

  # Encoding for left side of digits
  # @return [Hash{Integer=>Array<Integer>}]
  L_CODE = {
    0	=> [0, 0, 0, 1, 1, 0, 1],
    1	=> [0, 0, 1, 1, 0, 0, 1],
    2	=> [0, 0, 1, 0, 0, 1, 1],
    3	=> [0, 1, 1, 1, 1, 0, 1],
    4	=> [0, 1, 0, 0, 0, 1, 1],
    5	=> [0, 1, 1, 0, 0, 0, 1],
    6	=> [0, 1, 0, 1, 1, 1, 1],
    7	=> [0, 1, 1, 1, 0, 1, 1],
    8	=> [0, 1, 1, 0, 1, 1, 1],
    9	=> [0, 0, 0, 1, 0, 1, 1]
  }.freeze

  # Encoding for right side of digits
  # @return [Hash{Integer=>Array<Integer>}]
  R_CODE = {
    0 => [1, 1, 1, 0, 0, 1, 0],
    1 => [1, 1, 0, 0, 1, 1, 0],
    2 => [1, 1, 0, 1, 1, 0, 0],
    3 => [1, 0, 0, 0, 0, 1, 0],
    4 => [1, 0, 1, 1, 1, 0, 0],
    5 => [1, 0, 0, 1, 1, 1, 0],
    6 => [1, 0, 1, 0, 0, 0, 0],
    7 => [1, 0, 0, 0, 1, 0, 0],
    8 => [1, 0, 0, 1, 0, 0, 0],
    9 => [1, 1, 1, 0, 1, 0, 0]
  }.freeze

  # Left guard for scanner alignment
  # @return [Array<Integer>]
  LEFT_GUARD  = [1, 0, 1].freeze
  # Left guard for scanner alignment
  # @return [Array<Integer>]
  MID_GUARD   = [0, 1, 0, 1, 0].freeze
  # Left guard for scanner alignment
  # @return [Array<Integer>]
  RIGHT_GUARD = [1, 0, 1].freeze

  # Width in pixels for each bar unit
  # @return [Integer]
  UNIT = 4
  # Color for "white" barcode lines
  # @return [Color]
  COLOR_WHITE = Color.white
  # Color for "black" barcode lines
  # @return [Color]
  COLOR_BLACK = Color.black

  # Stores barcode configuration and validates the input number.
  # @param number [Integer] numeric value to encode (max 11 digits)
  # @param height [Integer] bitmap height
  # @param unit [Integer] bar unit width in pixels
  # @param color_white [Color] color for "white" barcode lines
  # @param color_black [Color] color for "black" barcode lines
  # @return [BarcodeGenerator] new generator instance
  def initialize(number, height: 96, unit: UNIT, color_white: COLOR_WHITE, color_black: COLOR_BLACK)
    @number      = number
    @height      = height
    @unit        = unit
    @color_white = color_white
    @color_black = color_black

    validate_input
  end

  # Generates barcode bitmap
  # @return [Bitmap] full UPC-A barcode bitmap
  def generate
    bitmap = Bitmap.new(encoded_digits.size * unit, height)

    encoded_digits.each_with_index do |digit, i|
      bitmap.fill_rect(i * unit, 0, unit, height, digit.zero? ? color_white : color_black)
    end

    bitmap
  end

  # Generates barcode bitmap from a trimmed value of max 5 digits
  # @return [Bitmap] trimmed barcode bitmap
  def generate_trimmed
    bitmap = Bitmap.new(encoded_digits_trimmed.size * unit, height)

    encoded_digits_trimmed.each_with_index do |digit, i|
      bitmap.fill_rect(i * unit, 0, unit, height, digit.zero? ? color_white : color_black)
    end

    bitmap
  end

  private

  # @return [Integer] numeric value being encoded
  attr_reader :number
  # @return [Integer] bitmap height
  attr_reader :height
  # @return [Integer] bar unit width in pixels
  attr_reader :unit
  # @return [Color] color for "white" barcode lines
  attr_reader :color_white
  # @return [Color] color for "black" barcode lines
  attr_reader :color_black

  # Validates the input number type and digit count.
  # @raise [BarcodeGenerator::TypeError] if the input is not an integer
  # @raise [BarcodeGenerator::SizeError] if the input exceeds 11 digits
  # @return [void]
  def validate_input
    raise TypeError.new unless number.is_a?(Integer)
    raise SizeError.new if number.digits.size > 11
  end

  # Full sequence of encoded bar units including guards.
  # @return [Array<Integer>] flattened bar unit values
  def encoded_digits
    @encoded_digits ||= (LEFT_GUARD + left_encoded + MID_GUARD + right_encoded + RIGHT_GUARD).flatten
  end

  # Encoded bar units for the trimmed 5-digit barcode.
  # @return [Array<Integer>] flattened bar unit values
  def encoded_digits_trimmed
    @encoded_digits_trimmed ||= padded_number[6...11].map { |d| R_CODE[d] }.flatten
  end

  # Input number zero-padded to 11 digits.
  # @return [Array<Integer>] individual digits of the padded number
  def padded_number
    @padded_number ||= [0] * (11 - number.digits.size) + number.digits.reverse
  end

  # Left half of the barcode encoded with the L-code table.
  # @return [Array<Integer>] encoded bar unit values
  def left_encoded
    @left_encoded ||= padded_number[0...6].map { |d| L_CODE[d] }
  end

  # Right half of the barcode (including control digit) encoded with the R-code table.
  # @return [Array<Integer>] encoded bar unit values
  def right_encoded
    @right_encoded ||= (padded_number[6...11] + [control_digit]).flatten.map { |d| R_CODE[d] }
  end

  # Calculates the 12th, check digit for barcode
  # @return [Integer] control digit value
  def control_digit
    return @control_digit if @control_digit

    odd   = padded_number.values_at(0, 2, 4, 6, 8, 10).sum * 3
    even  = padded_number.values_at(1, 3, 5, 7, 9).sum
    total = odd + even

    @control_digit = (10 - (total % 10)) % 10
  end
end
