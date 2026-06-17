################################################################################
#                    Mothods Overriden from base Essentials                    #
################################################################################

# Compatibility layer for v20 versions that still use SpriteWrapper
if Essentials::VERSION && Essentials::VERSION.to_f < 20.1
  class SpriteWrapper
    def height
      @sprite.height
    end
    def width
      @sprite.width
    end
  end
end

# Clamp the value of t before doing the math to avoid weird behaviours
alias :anim_getCubicPoint2 :getCubicPoint2
def getCubicPoint2(src, t)
  t = 1 if t > 1
  anim_getCubicPoint2(src, t)
end

# Fix to base PictureEx behaviour: Curve used to not update the coordinated of the sprite
alias :anim_setPictureSprite :setPictureSprite
def setPictureSprite(sprite, picture, iconSprite = false)
  picture.frameUpdates.each do |type|
    if type == Processes::CURVE
      sprite.x = picture.x.round
      sprite.y = picture.y.round
    end
  end
  anim_setPictureSprite(sprite, picture, iconSprite)
end

# This override only changes the third line of the method, removing the to_i:
# this_frame = ((time_now - @timer_start) * 20).to_i -> this_frame = ((time_now - @timer_start) * 20)
# This is to fix the base behaviour, which would otherwise skip over certain animation frames.
# Fully overriding this method is unfortunately the only way of changing this behaviour via plugin, so keep in mind
# that if your project has otherwise changed PictureEx.update this will override those changes.
if Essentials::VERSION && Essentials::VERSION.to_f >= 21
  class PictureEx
    def update
      time_now = System.uptime
      @timer_start = time_now if !@timer_start
      this_frame = ((time_now - @timer_start) * 20)#.to_i   # 20 frames per second
      procEnded = false
      @frameUpdates.clear
      @processes.each_with_index do |process, i|
        # Skip processes that aren't due to start yet
        next if process[1] > this_frame
        # Set initial values if the process has just started
        if !process[3]   # Not started yet
          process[3] = true   # Running
          case process[0]
          when Processes::XY
            process[5] = @x
            process[6] = @y
          when Processes::DELTA_XY
            process[5] = @x
            process[6] = @y
            process[7] += @x
            process[8] += @y
          when Processes::CURVE
            process[5][0] = @x
            process[5][1] = @y
          when Processes::Z
            process[5] = @z
          when Processes::ZOOM
            process[5] = @zoom_x
            process[6] = @zoom_y
          when Processes::ANGLE
            process[5] = @angle
          when Processes::TONE
            process[5] = @tone.clone
          when Processes::COLOR
            process[5] = @color.clone
          when Processes::HUE
            process[5] = @hue
          when Processes::OPACITY
            process[5] = @opacity
          end
        end
        # Update process
        @frameUpdates.push(process[0]) if !@frameUpdates.include?(process[0])
        start_time = @timer_start + (process[1] / 20.0)
        duration = process[2] / 20.0
        case process[0]
        when Processes::XY, Processes::DELTA_XY
          @x = lerp(process[5], process[7], duration, start_time, time_now)
          @y = lerp(process[6], process[8], duration, start_time, time_now)
        when Processes::CURVE
          @x, @y = getCubicPoint2(process[5], (time_now - start_time) / duration)
        when Processes::Z
          @z = lerp(process[5], process[6], duration, start_time, time_now)
        when Processes::ZOOM
          @zoom_x = lerp(process[5], process[7], duration, start_time, time_now)
          @zoom_y = lerp(process[6], process[8], duration, start_time, time_now)
        when Processes::ANGLE
          @angle = lerp(process[5], process[6], duration, start_time, time_now)
        when Processes::TONE
          @tone.red = lerp(process[5].red, process[6].red, duration, start_time, time_now)
          @tone.green = lerp(process[5].green, process[6].green, duration, start_time, time_now)
          @tone.blue = lerp(process[5].blue, process[6].blue, duration, start_time, time_now)
          @tone.gray = lerp(process[5].gray, process[6].gray, duration, start_time, time_now)
        when Processes::COLOR
          @color.red = lerp(process[5].red, process[6].red, duration, start_time, time_now)
          @color.green = lerp(process[5].green, process[6].green, duration, start_time, time_now)
          @color.blue = lerp(process[5].blue, process[6].blue, duration, start_time, time_now)
          @color.alpha = lerp(process[5].alpha, process[6].alpha, duration, start_time, time_now)
        when Processes::HUE
          @hue = lerp(process[5], process[6], duration, start_time, time_now)
        when Processes::OPACITY
          @opacity = lerp(process[5], process[6], duration, start_time, time_now)
        when Processes::VISIBLE
          @visible = process[5]
        when Processes::BLEND_TYPE
          @blend_type = process[5]
        when Processes::SE
          pbSEPlay(process[5], process[6], process[7])
        when Processes::NAME
          @name = process[5]
        when Processes::ORIGIN
          @origin = process[5]
        when Processes::SRC
          @src_rect.x = process[5]
          @src_rect.y = process[6]
        when Processes::SRC_SIZE
          @src_rect.width  = process[5]
          @src_rect.height = process[6]
        when Processes::CROP_BOTTOM
          @cropBottom = process[5]
        end
        # Erase process if its duration has elapsed
        if process[1] + process[2] <= this_frame
          callback(process[4]) if process[4]
          @processes[i] = nil
          procEnded = true
        end
      end
      # Clear out empty spaces in @processes array caused by finished processes
      @processes.compact! if procEnded
      @timer_start = nil if @processes.empty? && @rotate_speed == 0
      # Add the constant rotation speed
      if @rotate_speed != 0
        @frameUpdates.push(Processes::ANGLE) if !@frameUpdates.include?(Processes::ANGLE)
        @auto_angle = @rotate_speed * (time_now - @timer_start)
        while @auto_angle < 0
          @auto_angle += 360
        end
        @auto_angle %= 360
        @angle += @rotate_speed
        while @angle < 0
          @angle += 360
        end
        @angle %= 360
      end
    end
  end
end

# The number 6 in the moveZoom function is the only thing changed from base essentials
# It now waits one more frame to avoid playing the animation while the sprite is still not fully in position
module Battle::Scene::Animation::BallAnimationMixin
  def battlerAppear(battler, delay, battlerX, battlerY, batSprite, color)
    battler.setVisible(delay, true)
    battler.setOpacity(delay, 255)
    battler.moveXY(delay, 5, battlerX, battlerY)
    battler.moveZoom(delay, 6, 100, [batSprite, :pbPlayIntroAnimation])
    # NOTE: As soon as the battler sprite finishes zooming, and just as it
    #       starts changing its tone to normal, it plays its intro animation.
    color.alpha = 0
    battler.moveColor(delay + 5, 10, color)
  end
end

# This adds animations to PokemonSprites, as well as the name attribute to behave correctly with PictureEx.
# These changes allow you to call pbPlayIntroAnimation to PokemonSprites just as you would with a BattlerSprite.
class PokemonSprite
  attr_reader :offset
  # Sets the sprite's filename.  Alias for setBitmap.
  def name
    @name
  end
  def name=(value)
    @name = value
    @_iconbitmap.dispose if @_iconbitmap
    @_iconbitmap = AnimatedBitmap.new(value)
    self.bitmap = @_iconbitmap.bitmap
  end

  def pbPlayIntroAnimation(pictureEx = nil)
    return if @pokemon.nil?
    # Play Intro animation
    @anim&.dispose
    @anim = nil
    @anim = PokemonIntroAnimation.new([self],@viewport,@pokemon,false)
  end

  alias :anim_update :update unless method_defined?(:anim_update)

  def update
    anim_update
    return if @anim.nil?
    @anim.update
    if @anim.animDone?
      @anim.dispose
      @anim = nil
    end
  end

  alias :anim_setPokemonBitmap :setPokemonBitmap unless method_defined?(:anim_setPokemonBitmap)
  def setPokemonBitmap(pokemon, back = false)
    @anim&.dispose
    @anim = nil
    @pokemon = pokemon
    anim_setPokemonBitmap(pokemon, back)
  end

  alias :anim_setPokemonBitmapSpecies :setPokemonBitmapSpecies unless method_defined?(:anim_setPokemonBitmapSpecies)
  def setPokemonBitmapSpecies(pokemon, species, back = false)
    @anim&.dispose
    @anim = nil
    @pokemon = pokemon
    anim_setPokemonBitmapSpecies(pokemon, species, back)
  end
end

# Same as PokemonSprite, name and setBitmap are needed to work seamlessly with PictureEx.
class Battle::Scene::BattlerSprite
  attr_reader :offset

  def name
    @name
  end
  def name=(value)
    setBitmap(value)
  end

  def setBitmap(file,hue=0)
    self.bitmap = nil
    @name=file
    return if file==nil
    if file!=""
      @_iconbitmap=AnimatedBitmap.new(file,hue)
      # for compatibility
      self.bitmap=@_iconbitmap ? @_iconbitmap.bitmap : nil
    else
      @_iconbitmap=nil
    end
  end

  alias :anim_pbPlayIntroAnimation :pbPlayIntroAnimation unless method_defined?(:anim_pbPlayIntroAnimation)
  def pbPlayIntroAnimation(pictureEx = nil)
    anim_pbPlayIntroAnimation(pictureEx)

    # Play Intro animation
    if PokemonIntroAnimationSettings::ENABLED_IN_BATTLE && PokemonIntroAnimationSettings::DEFAULT_BEHAVIOUR != nil
      @battleAnimations.push(PokemonIntroAnimation.new([self],@viewport,@pkmn,@index%2 == 0))
    end
  end

  # Lines 4 and 5 of this method have beeh commented out.
  # This is to avoid overriding the second frame's bitmap during update.
  if Essentials::VERSION && Essentials::VERSION.to_f >= 21
    def update
      return if !@_iconBitmap
      @updating = true
      # Update bitmap
      # @_iconBitmap.update
      # self.bitmap = @_iconBitmap.bitmap
      # Pokémon sprite bobbing while Pokémon is selected
      @spriteYExtra = 0
      if @selected == 1 && COMMAND_BOBBING_DURATION    # When choosing commands for this Pokémon
        bob_delta = System.uptime % COMMAND_BOBBING_DURATION   # 0-COMMAND_BOBBING_DURATION
        bob_frame = (4 * bob_delta / COMMAND_BOBBING_DURATION).floor
        case bob_frame
        when 1 then @spriteYExtra = 2
        when 3 then @spriteYExtra = -2
        end
      end
      self.x       = self.x
      self.y       = self.y
      self.visible = @spriteVisible
      # Pokémon sprite blinking when targeted
      if @selected == 2 && @spriteVisible && TARGET_BLINKING_DURATION
        blink_delta = System.uptime % TARGET_BLINKING_DURATION   # 0-TARGET_BLINKING_DURATION
        blink_frame = (3 * blink_delta / TARGET_BLINKING_DURATION).floor
        self.visible = (blink_frame != 0)
      end
      @updating = false
    end
  else
    def update(frameCounter = 0)
      return if !@_iconBitmap
      @updating = true
      # Update bitmap
      # @_iconBitmap.update
      # self.bitmap = @_iconBitmap.bitmap
      # Pokémon sprite bobbing while Pokémon is selected
      @spriteYExtra = 0
      if @selected == 1    # When choosing commands for this Pokémon
        case (frameCounter / QUARTER_ANIM_PERIOD).floor
        when 1 then @spriteYExtra = 2
        when 3 then @spriteYExtra = -2
        end
      end
      self.x       = self.x
      self.y       = self.y
      self.visible = @spriteVisible
      # Pokémon sprite blinking when targeted
      if @selected == 2 && @spriteVisible
        case (frameCounter / SIXTH_ANIM_PERIOD).floor
        when 2, 5 then self.visible = false
        else           self.visible = true
        end
      end
      @updating = false
    end
  end
end


module GameData
  class Species
    def self.sprite_name_from_pokemon(pkmn, back = false, anim = false)
      if back
        return self.check_graphic_file("Graphics/Pokemon/", pkmn.species, pkmn.form, pkmn.gender, false, pkmn.shadowPokemon?, "Back" + (pkmn.shiny? ? " shiny" : "") + (anim ? "/Frame2" : ""))
      else
        return self.check_graphic_file("Graphics/Pokemon/", pkmn.species, pkmn.form, pkmn.gender, false, pkmn.shadowPokemon?, "Front" + (pkmn.shiny? ? " shiny" : "") + (anim ? "/Frame2" : ""))
      end
    end

    # ALL THE STUFF BELOW THIS IS UNUSED, LEAVING IT IN CASE IT WILL BE USEFUL

    # def self.check_anim_sprite(pkmn, back = false, species = nil)
    #   species = pkmn.species if !species
    #   species = GameData::Species.get(species).species
    #   return (back) ? self.back_anim_sprite_filename(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
    #                 : self.front_anim_sprite_filename(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
    # end

    # def self.ow_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
    #   ret = self.check_graphic_file("Graphics/Characters/", species, form, gender, shiny, shadow, "PkmnOw")
    #   ret = "Graphics/Characters/PkmnOw/000" if nil_or_empty?(ret)
    #   return ret
    # end

    # def self.front_anim_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
    #   return self.check_graphic_file("Graphics/Pokemon/", species, form, gender, shiny, shadow, "Front/Anim")
    # end
    #
    # def self.back_anim_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
    #   return self.check_graphic_file("Graphics/Pokemon/", species, form, gender, shiny, shadow, "Back/Anim")
    # end
    #
    # def self.front_anim_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false)
    #   filename = self.front_anim_sprite_filename(species, form, gender, shiny, shadow)
    #   return (filename) ? AnimatedBitmap.new(filename) : dummy_bitmap(false)
    # end
    #
    # def self.back_anim_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false)
    #   filename = self.back_anim_sprite_filename(species, form, gender, shiny, shadow)
    #   return (filename) ? AnimatedBitmap.new(filename) : dummy_bitmap(true)
    # end
    #
    # def self.anim_sprite_bitmap_from_pokemon(pkmn, back = false, species = nil)
    #   species = pkmn.species if !species
    #   species = GameData::Species.get(species).species   # Just to be sure it's a symbol
    #   return self.egg_sprite_bitmap(species, pkmn.form) if pkmn.egg?
    #   if back
    #     ret = self.back_anim_sprite_bitmap(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
    #   else
    #     ret = self.front_anim_sprite_bitmap(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
    #   end
    #   # alter_bitmap_function = MultipleForms.getFunction(species, "alterBitmap")
    #   # if ret && alter_bitmap_function
    #   #   new_ret = ret.copy
    #   #   ret.dispose
    #   #   new_ret.each { |bitmap| alter_bitmap_function.call(pkmn, bitmap) }
    #   #   ret = new_ret
    #   # end
    #   return ret
    # end

    # def self.dummy_bitmap(back)
    #   return (back) ? AnimatedBitmap.new("Graphics/Pokemon/_back") : AnimatedBitmap.new("Graphics/Pokemon/_front")
    # end
  end
end