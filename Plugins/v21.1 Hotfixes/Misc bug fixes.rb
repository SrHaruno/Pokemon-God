#===============================================================================
# "v21.1 Hotfixes" plugin
# This file contains fixes for bugs in Essentials v21.1.
# These bug fixes are also in the master branch of the GitHub version of
# Essentials:
# https://github.com/Maruno17/pokemon-essentials
#===============================================================================

Essentials::ERROR_TEXT += "[v21.1 Hotfixes 1.0.3]\r\n"

#===============================================================================
# Fixed Pokédex not showing male/female options for species with gender
# differences, and showing them for species without.
#===============================================================================
class PokemonPokedexInfo_Scene
  def pbGetAvailableForms
    ret = []
    multiple_forms = false
    gender_differences = (GameData::Species.front_sprite_filename(@species, 0) != GameData::Species.front_sprite_filename(@species, 0, 1))
    # Find all genders/forms of @species that have been seen
    GameData::Species.each do |sp|
      next if sp.species != @species
      next if sp.form != 0 && (!sp.real_form_name || sp.real_form_name.empty?)
      next if sp.pokedex_form != sp.form
      multiple_forms = true if sp.form > 0
      if sp.single_gendered?
        real_gender = (sp.gender_ratio == :AlwaysFemale) ? 1 : 0
        next if !$player.pokedex.seen_form?(@species, real_gender, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
        real_gender = 2 if sp.gender_ratio == :Genderless
        ret.push([sp.form_name, real_gender, sp.form])
      elsif sp.form == 0 && !gender_differences
        2.times do |real_gndr|
          next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
          ret.push([sp.form_name || _INTL("One Form"), 0, sp.form])
          break
        end
      else   # Both male and female
        2.times do |real_gndr|
          next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
          ret.push([sp.form_name, real_gndr, sp.form])
          break if sp.form_name && !sp.form_name.empty?   # Only show 1 entry for each non-0 form
        end
      end
    end
    # Sort all entries
    ret.sort! { |a, b| (a[2] == b[2]) ? a[1] <=> b[1] : a[2] <=> b[2] }
    # Create form names for entries if they don't already exist
    ret.each do |entry|
      if entry[0]   # Alternate forms, and form 0 if no gender differences
        entry[0] = "" if !multiple_forms && !gender_differences
      else   # Necessarily applies only to form 0
        case entry[1]
        when 0 then entry[0] = _INTL("Male")
        when 1 then entry[0] = _INTL("Female")
        else
          entry[0] = (multiple_forms) ? _INTL("One Form") : _INTL("Genderless")
        end
      end
      entry[1] = 0 if entry[1] == 2   # Genderless entries are treated as male
    end
    return ret
  end
end

#===============================================================================
# Fixed class PngAnimatedBitmap animating slowly.
#===============================================================================
class PngAnimatedBitmap
  def initialize(dir, filename, hue = 0)
    @frames       = []
    @currentFrame = 0
    @timer_start  = System.uptime
    panorama = RPG::Cache.load_bitmap(dir, filename, hue)
    if filename[/^\[(\d+)(?:,(\d+))?\]/]   # Starts with 1 or 2 numbers in brackets
      # File has a frame count
      numFrames = $1.to_i
      duration  = $2.to_i   # In 1/20ths of a second
      duration  = 5 if duration == 0
      raise "Invalid frame count in #{filename}" if numFrames <= 0
      raise "Invalid frame duration in #{filename}" if duration <= 0
      if panorama.width % numFrames != 0
        raise "Bitmap's width (#{panorama.width}) is not divisible by frame count: #{filename}"
      end
      @frame_duration = duration / 20.0
      subWidth = panorama.width / numFrames
      numFrames.times do |i|
        subBitmap = Bitmap.new(subWidth, panorama.height)
        subBitmap.blt(0, 0, panorama, Rect.new(subWidth * i, 0, subWidth, panorama.height))
        @frames.push(subBitmap)
      end
      panorama.dispose
    else
      @frames = [panorama]
    end
  end

  def totalFrames
    return (@frame_duration * @frames.length * 20).to_i
  end
end

#===============================================================================
# Fixed being unable to replace a NamedEvent.
#===============================================================================
class NamedEvent
  def add(key, proc)
    @callbacks[key] = proc
  end
end

#===============================================================================
# Fixed crash when a phone contact tries to call you while you're on a map with
# no map metadata.
#===============================================================================
class Phone
  module Call
    module_function

    def can_make?
      return false if $game_map.metadata&.has_flag?("NoPhoneSignal")
      return true
    end
  end
end

#===============================================================================
# Fixed being able to fly from the Town Map even if the CAN_FLY_FROM_TOWN_MAP
# Setting is false.
#===============================================================================
class PokemonRegionMap_Scene
  def pbMapScene
    x_offset = 0
    y_offset = 0
    new_x    = 0
    new_y    = 0
    timer_start = System.uptime
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if x_offset != 0 || y_offset != 0
        if x_offset != 0
          @sprites["cursor"].x = lerp(new_x - x_offset, new_x, 0.1, timer_start, System.uptime)
          x_offset = 0 if @sprites["cursor"].x == new_x
        end
        if y_offset != 0
          @sprites["cursor"].y = lerp(new_y - y_offset, new_y, 0.1, timer_start, System.uptime)
          y_offset = 0 if @sprites["cursor"].y == new_y
        end
        next if x_offset != 0 || y_offset != 0
      end
      ox = 0
      oy = 0
      case Input.dir8
      when 1, 2, 3
        oy = 1 if @map_y < BOTTOM
      when 7, 8, 9
        oy = -1 if @map_y > TOP
      end
      case Input.dir8
      when 1, 4, 7
        ox = -1 if @map_x > LEFT
      when 3, 6, 9
        ox = 1 if @map_x < RIGHT
      end
      if ox != 0 || oy != 0
        @map_x += ox
        @map_y += oy
        x_offset = ox * SQUARE_WIDTH
        y_offset = oy * SQUARE_HEIGHT
        new_x = @sprites["cursor"].x + x_offset
        new_y = @sprites["cursor"].y + y_offset
        timer_start = System.uptime
      end
      @sprites["mapbottom"].maplocation = pbGetMapLocation(@map_x, @map_y)
      @sprites["mapbottom"].mapdetails  = pbGetMapDetails(@map_x, @map_y)
      if Input.trigger?(Input::BACK)
        if @editor && @changed
          pbSaveMapData if pbConfirmMessage(_INTL("Save changes?")) { pbUpdate }
          break if pbConfirmMessage(_INTL("Exit from the map?")) { pbUpdate }
        else
          break
        end
      elsif Input.trigger?(Input::USE) && @mode == 1   # Choosing an area to fly to
        healspot = pbGetHealingSpot(@map_x, @map_y)
        if healspot && ($PokemonGlobal.visitedMaps[healspot[0]] ||
           ($DEBUG && Input.press?(Input::CTRL)))
          return healspot if @fly_map
          name = pbGetMapNameFromId(healspot[0])
          return healspot if pbConfirmMessage(_INTL("Would you like to use Fly to go to {1}?", name)) { pbUpdate }
        end
      elsif Input.trigger?(Input::USE) && @editor   # Intentionally after other USE input check
        pbChangeMapLocation(@map_x, @map_y)
      elsif Input.trigger?(Input::ACTION) && Settings::CAN_FLY_FROM_TOWN_MAP &&
            !@wallmap && !@fly_map && pbCanFly?
        pbPlayDecisionSE
        @mode = (@mode == 1) ? 0 : 1
        refresh_fly_screen
      end
    end
    pbPlayCloseMenuSE
    return nil
  end
end

#===============================================================================
# Made some unhelpful error messages when compiling more helpful.
#===============================================================================
module Compiler
  module_function
  def cast_csv_value(value, schema, enumer = nil)
    case schema.downcase
    when "i"   # Integer
      if !value || !value[/^\-?\d+$/]
        raise _INTL("Field '{1}' is not an integer.", value) + "\n" + FileLineData.linereport
      end
      return value.to_i
    when "u"   # Positive integer or zero
      if !value || !value[/^\d+$/]
        raise _INTL("Field '{1}' is not a positive integer or 0.", value) + "\n" + FileLineData.linereport
      end
      return value.to_i
    when "v"   # Positive integer
      if !value || !value[/^\d+$/]
        raise _INTL("Field '{1}' is not a positive integer.", value) + "\n" + FileLineData.linereport
      end
      if value.to_i == 0
        raise _INTL("Field '{1}' must be greater than 0.", value) + "\n" + FileLineData.linereport
      end
      return value.to_i
    when "x"   # Hexadecimal number
      if !value || !value[/^[A-F0-9]+$/i]
        raise _INTL("Field '{1}' is not a hexadecimal number.", value) + "\n" + FileLineData.linereport
      end
      return value.hex
    when "f"   # Floating point number
      if !value || !value[/^\-?^\d*\.?\d*$/]
        raise _INTL("Field '{1}' is not a number.", value) + "\n" + FileLineData.linereport
      end
      return value.to_f
    when "b"   # Boolean
      return true if value && value[/^(?:1|TRUE|YES|Y)$/i]
      return false if value && value[/^(?:0|FALSE|NO|N)$/i]
      raise _INTL("Field '{1}' is not a Boolean value (true, false, 1, 0).", value) + "\n" + FileLineData.linereport
    when "n"   # Name
      if !value || !value[/^(?![0-9])\w+$/]
        raise _INTL("Field '{1}' must contain only letters, digits, and\nunderscores and can't begin with a number.", value) + "\n" + FileLineData.linereport
      end
    when "s"   # String
    when "q"   # Unformatted text
    when "m"   # Symbol
      if !value || !value[/^(?![0-9])\w+$/]
        raise _INTL("Field '{1}' must contain only letters, digits, and\nunderscores and can't begin with a number.", value) + "\n" + FileLineData.linereport
      end
      return value.to_sym
    when "e"   # Enumerable
      return checkEnumField(value, enumer)
    when "y"   # Enumerable or integer
      return value.to_i if value && value[/^\-?\d+$/]
      return checkEnumField(value, enumer)
    end
    return value
  end
end

#===============================================================================
# Language files are now loaded properly even if the game is encrypted.
# Fixed trying to load non-existent language files not reverting the messages to
# the default messages if other language files are already loaded.
#===============================================================================
class Translation
  def load_message_files(filename)
    @core_messages = nil
    @game_messages = nil
    begin
      core_filename = sprintf("Data/messages_%s_core.dat", filename)
      if FileTest.exist?(core_filename)
        @core_messages = load_data(core_filename)
        @core_messages = nil if !@core_messages.is_a?(Array)
      end
      game_filename = sprintf("Data/messages_%s_game.dat", filename)
      if FileTest.exist?(game_filename)
        @game_messages = load_data(game_filename)
        @game_messages = nil if !@game_messages.is_a?(Array)
      end
    rescue
      @core_messages = nil
      @game_messages = nil
    end
  end
end

#===============================================================================
# Fixed standing on an event preventing you from interacting with an event
# you're facing.
#===============================================================================
class Game_Player < Game_Character
  def pbCheckEventTriggerFromDistance(triggers)
    events = pbTriggeredTrainerEvents(triggers)
    events.concat(pbTriggeredCounterEvents(triggers))
    return false if events.length == 0
    ret = false
    events.each do |event|
      event.start
      ret = true if event.starting
    end
    return ret
  end

  def check_event_trigger_here(triggers)
    result = false
    # If event is running
    return result if $game_system.map_interpreter.running?
    # All event loops
    $game_map.events.each_value do |event|
      # If event coordinates and triggers are consistent
      next if !event.at_coordinate?(@x, @y)
      next if !triggers.include?(event.trigger)
      # If starting determinant is same position event (other than jumping)
      next if event.jumping? || !event.over_trigger?
      event.start
      result = true if event.starting
    end
    return result
  end

  def check_event_trigger_there(triggers)
    result = false
    # If event is running
    return result if $game_system.map_interpreter.running?
    # Calculate front event coordinates
    new_x = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    new_y = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    return false if !$game_map.valid?(new_x, new_y)
    # All event loops
    $game_map.events.each_value do |event|
      next if !triggers.include?(event.trigger)
      # If event coordinates and triggers are consistent
      next if !event.at_coordinate?(new_x, new_y)
      # If starting determinant is front event (other than jumping)
      next if event.jumping? || event.over_trigger?
      event.start
      result = true if event.starting
    end
    # If fitting event is not found
    if result == false && $game_map.counter?(new_x, new_y)
      # Calculate coordinates of 1 tile further away
      new_x += (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
      new_y += (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
      return false if !$game_map.valid?(new_x, new_y)
      # All event loops
      $game_map.events.each_value do |event|
        next if !triggers.include?(event.trigger)
        # If event coordinates and triggers are consistent
        next if !event.at_coordinate?(new_x, new_y)
        # If starting determinant is front event (other than jumping)
        next if event.jumping? || event.over_trigger?
        event.start
        result = true if event.starting
      end
    end
    return result
  end

  def check_event_trigger_touch(dir)
    result = false
    return result if $game_system.map_interpreter.running?
    # All event loops
    x_offset = (dir == 4) ? -1 : (dir == 6) ? 1 : 0
    y_offset = (dir == 8) ? -1 : (dir == 2) ? 1 : 0
    $game_map.events.each_value do |event|
      next if ![1, 2].include?(event.trigger)   # Player touch, event touch
      # If event coordinates and triggers are consistent
      next if !event.at_coordinate?(@x + x_offset, @y + y_offset)
      if event.name[/(?:sight|trainer)\((\d+)\)/i]
        distance = $~[1].to_i
        next if !pbEventCanReachPlayer?(event, self, distance)
      elsif event.name[/counter\((\d+)\)/i]
        distance = $~[1].to_i
        next if !pbEventFacesPlayer?(event, self, distance)
      end
      # If starting determinant is front event (other than jumping)
      next if event.jumping? || event.over_trigger?
      event.start
      result = true if event.starting
    end
    return result
  end
end