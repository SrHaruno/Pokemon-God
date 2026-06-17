#===============================================================================
# STARTER CHOICE PLUGIN - USER GUIDE
#===============================================================================
#
# This plugin allows players to choose 1-3 starter Pokémon with a beautiful UI.
# Supports shiny chance (1/500), gender selection, and custom titles.
#
# -----------------------
# HOW TO USE
# -----------------------
#
# CONTROLS:
#   - LEFT/RIGHT Arrow Keys  : Navigate between Pokémon
#   - A / D Keys            : Also navigate (alternative to arrows)
#   - S / Action Key        : Toggle gender (♂ / ♀)
#   - USE / C / Enter Key   : Select the Pokémon
#   - BACK / X / Esc Key    : Cancel (if enabled)
#
# -----------------------
# METHODS
# -----------------------
#
# 1. pbChooseStarter(starters, level, allow_cancel, title, can_save)
#    - Most flexible method. Use an array of 1-3 Pokémon.
#
#    Examples:
#      pbChooseStarter([:BULBASAUR])                    # 1 Pokémon
#      pbChooseStarter([:PIKACHU, :EEVEE])               # 2 Pokémon
#      pbChooseStarter([:CHARMANDER, :SQUIRTLE, :BULBASAUR], 5, true)
#      pbChooseStarter([:PIKACHU], 10, false, "Choose your partner!")
#      pbChooseStarter([:PIKACHU], 10, true, false)      # do not save shiny/gender
#
# 2. pbStarterChoice(starter1, starter2, starter3, level, allow_cancel, title, can_save)
#    - Specify exactly 3 Pokémon (use nil for empty slots).
#
#    Examples:
#      pbStarterChoice(:CHARMANDER, :SQUIRTLE, :BULBASAUR)
#      pbStarterChoice(:PIKACHU, :EEVEE, nil, 5, true, "Pick a Pokemon!")
#      pbStarterChoice(:CHARMANDER, nil, nil, 5, false, "Your starter!")
#      pbStarterChoice(:PIP, :POP, :PUP, 5, true, false)
#
# 3. pbDefaultStarters(allow_cancel, title, can_save)
#    - Quick preset with :GROWLITHE, :HOUNDOUR, :POOCHYENA at level 5.
#
#    Examples:
#      pbDefaultStarters()
#      pbDefaultStarters(false)
#      pbDefaultStarters(true, "Choose your dog!")
#      pbDefaultStarters(true, false)
#
# 4. pbRandomStarters(count, level, allow_cancel, title, can_save)
#    - Pick 1-3 completely random Pokémon from all available species.
#    - Uses RANDOM_STARTER_BLACKLIST to exclude species.
#    - When can_save is true, saved random species are restored after cancel.
#
#    Examples:
#      pbRandomStarters(3)
#      pbRandomStarters(2, 5, true, "Pick your random partner")
#      pbRandomStarters(1, 10, true, false)
#
# 5. pbRandomStartersFromPool(pool, count, level, allow_cancel, title, can_save)
#    - Pick 1-3 random Pokémon from a defined pool of species.
#
#    Examples:
#      pbRandomStartersFromPool([:BULBASAUR, :SQUIRTLE, :CHARMANDER], 2)
#      pbRandomStartersFromPool([:PIKACHU, :EEVEE, :JIGGLYPUFF], 3, 5, true, "Choose one")
#
# -----------------------
# PARAMETERS EXPLAINED
# -----------------------
#
#   starters     : Array of Pokémon species symbols [:PIKACHU, :EEVEE]
#   level        : Level of the Pokémon (default: 5)
#   allow_cancel : Can player press BACK to cancel? (default: true)
#   title        : Custom text shown at top (default: "Choose Your Starter!")
#   can_save     : Save shiny/gender on cancel? (default: true)
#
# -----------------------
# FEATURES
# -----------------------
#
#   - Shiny Pokémon have 1/500 chance and show a ★ in name
#   - Gender can be toggled with [A] key (Male/Female)
#   - Legendary Pokémon can be genderless
#   - Pokémon cries play when selected
#   - Visual selection effects (glow, zoom, bobbing animation)
#
# -----------------------
# OUTCOME (VARIABLE)
# -----------------------
#
# You can optionally store which starter was chosen into a game variable.
# This lets you use Conditional Branches in events later.
#
# How it works:
#   - Left starter  = 1
#   - Middle starter = 2
#   - Right starter  = 3
#   - Cancel (if allowed) = 0
#
# Set STARTER_CHOICE_OUTCOME_VARIABLE to the variable ID you want to write to.
# Set it to 0 to disable writing.
#
#===============================================================================

STARTER_CHOICE_OUTCOME_VARIABLE = 7
# Add species symbols to this array to exclude them from pbRandomStarters.
RANDOM_STARTER_BLACKLIST = []

class StarterChoice_Scene
  attr_reader :index
  
  @@saved_starter_states = {}
  
  COLOR_SELECTED = Color.new(255, 215, 0)
  COLOR_UNSELECTED = Color.new(100, 100, 100)
  COLOR_BG = Color.new(0, 0, 0, 180)
  COLOR_NAME_BG = Color.new(0, 0, 0, 200)
  COLOR_TYPE_BG = Color.new(0, 0, 0, 160)
  
  def pbStartScene(starters, level = 5, allow_cancel = true, title = nil, can_save = true, state_key = nil)
    @starters = starters
    @level = level
    @allow_cancel = allow_cancel
    @can_save = can_save
    @state_key = state_key || generateStateKey(starters, level)
    @index = 0
    @confirmed = false
    @sprites = {}
    @shiny_status = {}
    @gender_status = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"].z = 1
    @sprites["overlay"].bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, COLOR_BG)
    
    addBackgroundPlane(@sprites, "bg", "StarterChoice/bg", @viewport) rescue nil
    @sprites["bg"].z = 0 if @sprites["bg"]
    
    @sprites["title"] = BitmapSprite.new(Graphics.width, 60, @viewport)
    @sprites["title"].z = 20
    @sprites["title"].y = 20
    pbSetSystemFont(@sprites["title"].bitmap)
    title_text = title || _INTL("Choose Your Starter!")
    pbDrawTextPositions(@sprites["title"].bitmap,
      [[title_text, Graphics.width / 2, 10, :center,
        Color.new(255, 255, 255), Color.new(80, 80, 80)]])
    
    @sprites["instructions"] = BitmapSprite.new(Graphics.width, 40, @viewport)
    @sprites["instructions"].z = 20
    @sprites["instructions"].y = Graphics.height - 40
    pbSetSmallFont(@sprites["instructions"].bitmap)
    
    instruction_text = buildInstructionText(@starters.length, @allow_cancel)
    
    pbDrawTextPositions(@sprites["instructions"].bitmap,
      [[instruction_text, Graphics.width / 2, 10, :center, 
        Color.new(200, 200, 200), Color.new(60, 60, 60)]])
    
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].z = 100
    @sprites["messagebox"].viewport = @viewport
    @sprites["messagebox"].visible = false
    @sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"], 2)
    
    @x_positions = calculatePositions(@starters.length)
    @y_position = Graphics.height / 2 - 20
    
    @starters.each_with_index do |species, i|
      createStarterDisplay(species, i)
    end
    
    updateSelection(true)
    
    pbFadeInAndShow(@sprites) { update }
  end
  
  def calculatePositions(count)
    case count
    when 1
      [Graphics.width / 2]
    when 2
      [
        Graphics.width / 3,
        Graphics.width * 2 / 3
      ]
    else
      [
        80,
        Graphics.width / 2,
        Graphics.width - 80
      ]
    end
  end
  
  def buildInstructionText(starter_count, allow_cancel)
    parts = []
    
    if starter_count > 1
      parts << _INTL("◀ ▶ to choose")
    end
    
    parts << _INTL("[A] change gender")
    
    parts << _INTL("[USE] to select")
    
    parts.join("  |  ")
  end
  
  def generateStateKey(starters, level)
    "#{level}:#{starters.map(&:to_s).join(",")}".freeze
  end
  
  def saveCurrentStarterState
    self.class.set_saved_state(@state_key,
      {
        starters: @starters.dup,
        shiny: @shiny_status.dup,
        gender: @gender_status.dup
      }
    )
  end
  
  def self.get_saved_state(key)
    @@saved_starter_states[key]
  end
  
  def self.set_saved_state(key, value)
    @@saved_starter_states[key] = value
  end
  
  def createStarterDisplay(species, index)
    x = @x_positions[index]
    
    temp_pokemon = Pokemon.new(species, @level)
    species_data = GameData::Species.get(species)
    
    saved_state = @can_save ? self.class.get_saved_state(@state_key) : nil
    if saved_state
      temp_pokemon.shiny = saved_state[:shiny][index]
      @shiny_status[index] = temp_pokemon.shiny?
      temp_pokemon.gender = saved_state[:gender][index] unless saved_state[:gender][index].nil?
      @gender_status[index] = temp_pokemon.gender
    else
      if rand(4096) == 0
        temp_pokemon.shiny = true
      end
      
      @shiny_status[index] = temp_pokemon.shiny?
      
      is_legendary = species_data.has_flag?("Legendary") || species_data.has_flag?("Mythical")
      if temp_pokemon.gender == 2 && !is_legendary
        temp_pokemon.gender = rand(2)
      end
      @gender_status[index] = temp_pokemon.gender
    end
    
    @sprites["panel#{index}"] = BitmapSprite.new(140, 190, @viewport)
    @sprites["panel#{index}"].x = x - 70
    @sprites["panel#{index}"].y = @y_position - 85
    @sprites["panel#{index}"].z = 5
    drawSelectionPanel(@sprites["panel#{index}"].bitmap, false)
    
    @sprites["pokemon#{index}"] = PokemonSprite.new(@viewport)
    @sprites["pokemon#{index}"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemon#{index}"].setPokemonBitmap(temp_pokemon)
    @sprites["pokemon#{index}"].x = x
    @sprites["pokemon#{index}"].y = @y_position - 20
    @sprites["pokemon#{index}"].z = 10
    @sprites["pokemon#{index}"].zoom_x = 0.55
    @sprites["pokemon#{index}"].zoom_y = 0.55
    
    @sprites["namebg#{index}"] = BitmapSprite.new(140, 36, @viewport)
    @sprites["namebg#{index}"].x = x - 70
    @sprites["namebg#{index}"].y = @y_position + 70
    @sprites["namebg#{index}"].z = 8
    @sprites["namebg#{index}"].bitmap.fill_rect(0, 0, 140, 36, COLOR_NAME_BG)
    
    @sprites["name#{index}"] = BitmapSprite.new(140, 36, @viewport)
    @sprites["name#{index}"].x = x - 70
    @sprites["name#{index}"].y = @y_position + 70
    @sprites["name#{index}"].z = 11
    pbSetSystemFont(@sprites["name#{index}"].bitmap)
    
    name = species_data.name
    #if temp_pokemon.shiny?
     # name = " #{name}"
    #end
    
    base_color = Color.new(255, 255, 255)
    shadow_color = Color.new(60, 60, 60)
    pbDrawTextPositions(@sprites["name#{index}"].bitmap,
      [[name, 70, 6, :center, base_color, shadow_color]])
    
    @sprites["gender_sprite#{index}"] = BitmapSprite.new(40, 28, @viewport)
    @sprites["gender_sprite#{index}"].x = x - 55
    @sprites["gender_sprite#{index}"].y = @y_position + 102
    @sprites["gender_sprite#{index}"].z = 12
    pbSetSmallFont(@sprites["gender_sprite#{index}"].bitmap)
    
    updateGenderDisplay(index)
    
    @sprites["level#{index}"] = BitmapSprite.new(45, 28, @viewport)
    @sprites["level#{index}"].x = x - 5
    @sprites["level#{index}"].y = @y_position + 102
    @sprites["level#{index}"].z = 11
    pbSetSmallFont(@sprites["level#{index}"].bitmap)
    
    level_text = _INTL("Lv. {1}", @level)
    pbDrawTextPositions(@sprites["level#{index}"].bitmap,
      [[level_text, 22, 4, :center, Color.new(200, 200, 200), Color.new(60, 60, 60)]])
    
    types = species_data.types
    @sprites["types#{index}"] = BitmapSprite.new(140, 48, @viewport)
    @sprites["types#{index}"].x = x - 70
    @sprites["types#{index}"].y = @y_position + 125
    @sprites["types#{index}"].z = 11
    
    drawTypes(@sprites["types#{index}"].bitmap, types)
    
    @sprites["arrow#{index}"] = BitmapSprite.new(40, 40, @viewport)
    @sprites["arrow#{index}"].x = x - 20
    @sprites["arrow#{index}"].y = @y_position - 110
    @sprites["arrow#{index}"].z = 15
    @sprites["arrow#{index}"].visible = (index == 0)
    drawArrow(@sprites["arrow#{index}"].bitmap)
  end
  
  def drawSelectionPanel(bitmap, selected)
    bitmap.clear
    
    bg_color = selected ? Color.new(40, 40, 60) : Color.new(20, 20, 30)
    border_color = selected ? COLOR_SELECTED : COLOR_UNSELECTED
    
    bitmap.fill_rect(4, 4, 132, 182, bg_color)
    
    bitmap.fill_rect(0, 0, 140, 4, border_color)
    bitmap.fill_rect(0, 186, 140, 4, border_color)
    bitmap.fill_rect(0, 0, 4, 190, border_color)
    bitmap.fill_rect(136, 0, 4, 190, border_color)
    
    if selected
      glow_color = Color.new(255, 215, 0, 100)
      bitmap.fill_rect(4, 4, 132, 4, glow_color)
      bitmap.fill_rect(4, 182, 132, 4, glow_color)
      bitmap.fill_rect(4, 4, 4, 182, glow_color)
      bitmap.fill_rect(132, 4, 4, 182, glow_color)
    end
  end
  
  def updateGenderDisplay(index)
    bitmap = @sprites["gender_sprite#{index}"].bitmap
    bitmap.clear
    
    gender = @gender_status[index]
    gender_symbol = (gender == 2) ? "-" : getGenderSymbol(gender)
    gender_color = (gender == 2) ? Color.new(200, 200, 200) : getGenderColor(gender)
    
    pbSetSmallFont(bitmap)
    pbDrawTextPositions(bitmap,
      [[_INTL("{1}", gender_symbol), 20, 4, :center, gender_color, Color.new(0, 0, 0)]])
  end
  
  def drawArrow(bitmap)
    bitmap.clear
    
    color = COLOR_SELECTED
    bitmap.fill_rect(16, 0, 8, 8, color)
    bitmap.fill_rect(12, 4, 16, 4, color)
    bitmap.fill_rect(8, 8, 24, 4, color)
    bitmap.fill_rect(4, 12, 32, 4, color)
  end
  
  def getGenderSymbol(gender)
    case gender
    when 0
      return "♂"
    when 1
      return "♀"
    else
      return ""
    end
  end
  
  def getGenderColor(gender)
    case gender
    when 0
      return Color.new(104, 144, 240)
    when 1
      return Color.new(248, 88, 136)
    else
      return Color.new(200, 200, 200)
    end
  end
  
  def drawTypes(bitmap, types)
    bitmap.clear
    
    pill_width = 46
    spacing = 50
    total_width = types.length * pill_width + (types.length - 1) * (spacing - pill_width)
    start_x = (140 - total_width) / 2 + (pill_width / 2) - 23
    
    types.each_with_index do |type, i|
      type_data = GameData::Type.get(type)
      
      x_pos = start_x + (i * spacing)
      y_pos = 8
      
      type_color = getTypeColor(type)
      
      bitmap.fill_rect(x_pos - 2, y_pos - 2, 46, 24, Color.new(0, 0, 0, 180))
      bitmap.fill_rect(x_pos, y_pos, 42, 20, type_color)
      
      pbSetSmallFont(bitmap)
      type_name = type_data.name[0..2]
      text_color = Color.new(255, 255, 255)
      shadow_color = Color.new(40, 40, 40)
      pbDrawTextPositions(bitmap,
        [[type_name, x_pos + 21, y_pos + 2, :center, text_color, shadow_color]])
    end
  end
  
  def getTypeColor(type)
    type_colors = {
      :NORMAL   => Color.new(168, 168, 120),
      :FIGHTING => Color.new(192, 48, 40),
      :FLYING   => Color.new(168, 144, 240),
      :POISON   => Color.new(160, 64, 160),
      :GROUND   => Color.new(224, 192, 104),
      :ROCK     => Color.new(184, 160, 56),
      :BUG      => Color.new(168, 184, 32),
      :GHOST    => Color.new(112, 88, 152),
      :STEEL    => Color.new(184, 184, 208),
      :FIRE     => Color.new(240, 128, 48),
      :WATER    => Color.new(104, 144, 240),
      :GRASS    => Color.new(120, 200, 80),
      :ELECTRIC => Color.new(248, 208, 48),
      :PSYCHIC  => Color.new(248, 88, 136),
      :ICE      => Color.new(152, 216, 216),
      :DRAGON   => Color.new(112, 56, 248),
      :DARK     => Color.new(112, 88, 72),
      :FAIRY    => Color.new(238, 153, 172)
    }
    
    return type_colors[type] || Color.new(168, 168, 120)
  end
  
  def updateSelection(skip_animation = false)
    @starters.each_with_index do |_, i|
      is_selected = (i == @index)
      
      drawSelectionPanel(@sprites["panel#{i}"].bitmap, is_selected)
      
      @sprites["arrow#{i}"].visible = is_selected
      
      if is_selected
        @sprites["pokemon#{i}"].setOffset(PictureOrigin::CENTER)
        @sprites["pokemon#{i}"].zoom_x = 0.7
        @sprites["pokemon#{i}"].zoom_y = 0.7
        @sprites["pokemon#{i}"].tone = Tone.new(0, 0, 0, 0)
      else
        @sprites["pokemon#{i}"].zoom_x = 0.55
        @sprites["pokemon#{i}"].zoom_y = 0.55
        @sprites["pokemon#{i}"].tone = Tone.new(-30, -30, -30, 0)
      end
    end
    
    unless skip_animation
      species = @starters[@index]
      temp_pokemon = Pokemon.new(species, @level)
      temp_pokemon.play_cry(70)
    end
  end
  
  def pbChooseStarter
    loop do
      Graphics.update
      Input.update
      self.update
      
      old_index = @index
      
      if Input.trigger?(Input::LEFT) || Input.triggerex?(0x41)
        @index -= 1
        @index = @starters.length - 1 if @index < 0
      elsif Input.trigger?(Input::RIGHT) || Input.triggerex?(0x44)
        @index += 1
        @index = 0 if @index >= @starters.length
      elsif Input.trigger?(Input::ACTION) || Input.triggerex?(0x53)
        current_gender = @gender_status[@index]
        species_data = GameData::Species.get(@starters[@index])
        is_legendary = species_data.has_flag?("Legendary") || species_data.has_flag?("Mythical")
        
        if is_legendary && current_gender == 2
          pbPlayBuzzerSE
        else
          new_gender = (current_gender == 0) ? 1 : 0
          @gender_status[@index] = new_gender
          updateGenderDisplay(@index)
          pbPlayCursorSE
        end
      elsif Input.trigger?(Input::USE)
        species_data = GameData::Species.get(@starters[@index])
        pokemon_name = species_data.name
        
        if pbConfirmMessage(_INTL("\\w[itembox]Are you sure you want to choose {1}?", pokemon_name))
          pbPlayDecisionSE
          @confirmed = true
          return @index
        end
        pbPlayCancelSE
      elsif Input.trigger?(Input::BACK)
        if @allow_cancel
          if pbConfirmMessage(_INTL("Are you sure you want to cancel?"))
            saveCurrentStarterState if @can_save
            pbPlayCancelSE
            return -1
          end
        else
          pbPlayBuzzerSE
        end
      end
      
      if @index != old_index
        pbPlayCursorSE
        updateSelection
      end
    end
  end
  
  def pbEndScene
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
  
  def update
    pbUpdateSpriteHash(@sprites)
    
    if @sprites["pokemon#{@index}"]
      time = System.uptime
      offset = Math.sin(time * 4) * 3
      @sprites["pokemon#{@index}"].y = @y_position - 20 + offset
    end
  end
end

class StarterChoice_Screen
  def initialize(scene)
    @scene = scene
  end
  
  def pbStartScreen(starters, level = 5, allow_cancel = true, title = nil, can_save = true, state_key = nil)
    @scene.pbStartScene(starters, level, allow_cancel, title, can_save, state_key)
    index = @scene.pbChooseStarter
    if index >= 0
      shiny_status = @scene.instance_variable_get(:@shiny_status)[index]
      selected_gender = @scene.instance_variable_get(:@gender_status)[index]
    else
      shiny_status = false
      selected_gender = nil
    end
    @scene.pbEndScene
    return [index, shiny_status, selected_gender]
  end
end

def pbChooseStarter(starters, level = 5, allow_cancel = true, title = nil, can_save = true, state_key = nil)
  if title == true || title == false
    can_save = title
    title = nil
  end
  valid_starters = starters[0...3].compact
  if valid_starters.length < 1
    raise ArgumentError, _INTL("At least one starter Pokémon must be specified!")
  end
  
  valid_starters.each do |species|
    if !species || !GameData::Species.exists?(species)
      raise ArgumentError, _INTL("Invalid Pokémon species: {1}", species.to_s)
    end
  end
  
  scene = StarterChoice_Scene.new
  screen = StarterChoice_Screen.new(scene)
  result = screen.pbStartScreen(valid_starters, level, allow_cancel, title, can_save, state_key)
  index = result[0]
  is_shiny = result[1]
  selected_gender = result[2]
  
  if defined?($game_variables) && STARTER_CHOICE_OUTCOME_VARIABLE.to_i > 0
    $game_variables[STARTER_CHOICE_OUTCOME_VARIABLE] = (index >= 0) ? (index + 1) : 0
  end
  
  if index >= 0
    selected_species = valid_starters[index]
    
    pokemon = Pokemon.new(selected_species, level)
    
    pokemon.shiny = true if is_shiny
    
    if selected_gender && selected_gender != 2
      pokemon.gender = selected_gender
    elsif selected_gender == 2
      pokemon.gender = 2
    end
    
    $player.pokedex.set_seen(pokemon.species)
    $player.pokedex.set_owned(pokemon.species)
    
    if $player.party.length >= Settings::MAX_PARTY_SIZE
      $PokemonStorage.pbStore(pokemon)
      pbMessage(_INTL("{1} was transferred to your PC!", pokemon.name))
    else
      $player.party.push(pokemon)
    end
    
    pokemon.play_cry
    
   # if is_shiny
     # pbMessage(_INTL("\\me[Battle capture success]\\w[itembox]{1} obtained \\c[1]{2}\\c[0]!\\nIt has the \\c[1]{3}\\c[0] nature.", $player.name, pokemon.name, pokemon.species_nature) + "\\wtnp[80]")   #(_INTL("You received {1}!", pokemon.name))
    #else
      pbMessage(_INTL("\\me[Battle capture success]\\w[itembox]{1} obtained \\c[1]{2}\\c[0]!\\nIt has the \\c[1]{3}\\c[0] nature.", $player.name, pokemon.name, pokemon.nature.name) + "\\wtnp[80]")   #(_INTL("You received {1}!", pokemon.name))
    #end
    
    if pbConfirmMessage(_INTL("Do you want to give your Pokémon a name?"))
      pokemon.name = pbEnterPokemonName(_INTL("{1}'s name?", pokemon.speciesName),
                                        0, Pokemon::MAX_NAME_SIZE, "", pokemon)
    end
    
    return pokemon
  else
    return nil
  end
end

def pbStarterChoice(starter1, starter2, starter3, level = 5, allow_cancel = true, title = nil, can_save = true)
  if title == true || title == false
    can_save = title
    title = nil
  end
  starters = [starter1, starter2, starter3]
  return pbChooseStarter(starters, level, allow_cancel, title, can_save)
end

def pbDefaultStarters(allow_cancel = false, title = nil, can_save = true)
  if title == true || title == false
    can_save = title
    title = nil
  end
  starters = [:GROWLITHE, :HOUNDOUR, :POOCHYENA]
  return pbChooseStarter(starters, 5, allow_cancel, title, can_save)
end

def random_starter_state_key(count, level, allow_cancel, title, blacklist)
  blacklist_key = blacklist.compact.map(&:to_s).sort.join(",")
  return "pbRandomStarters:#{count}:#{level}:#{allow_cancel}:#{title || ''}:#{blacklist_key}"
end

def random_pool_starter_state_key(pool, count, level, allow_cancel, title)
  pool_key = pool.compact.map(&:to_s).sort.join(",")
  return "pbRandomStartersFromPool:#{pool_key}:#{count}:#{level}:#{allow_cancel}:#{title || ''}"
end

def pbRandomStarters(count = 3, level = 5, allow_cancel = true, title = nil, can_save = true)
  if title == true || title == false
    can_save = title
    title = nil
  end
  count = count.clamp(1, 3)
  key = random_starter_state_key(count, level, allow_cancel, title, RANDOM_STARTER_BLACKLIST)
  if can_save && StarterChoice_Scene.get_saved_state(key)
    starters = StarterChoice_Scene.get_saved_state(key)[:starters]
  else
    starters = random_starter_species(count, RANDOM_STARTER_BLACKLIST)
  end
  return pbChooseStarter(starters, level, allow_cancel, title, can_save, key)
end


def pbRandomStartersFromPool(pool, count = 3, level = 5, allow_cancel = true, title = nil, can_save = true)
  if title == true || title == false
    can_save = title
    title = nil
  end
  raise ArgumentError, _INTL("A species pool must be provided!") if !pool || pool.empty?
  valid_pool = pool.compact.uniq
  raise ArgumentError, _INTL("A species pool must contain at least one Pokémon!") if valid_pool.empty?
  count = count.clamp(1, 3)
  raise ArgumentError, _INTL("Pool must contain at least {1} species.", count) if valid_pool.length < count
  valid_pool.each do |species|
    if !GameData::Species.exists?(species)
      raise ArgumentError, _INTL("Invalid Pokémon species: {1}", species.to_s)
    end
  end
  key = random_pool_starter_state_key(valid_pool, count, level, allow_cancel, title)
  if can_save && StarterChoice_Scene.get_saved_state(key)
    starters = StarterChoice_Scene.get_saved_state(key)[:starters]
  else
    starters = valid_pool.sample(count)
  end
  return pbChooseStarter(starters, level, allow_cancel, title, can_save, key)
end


def random_starter_species(count, blacklist = [])
  species = []
  GameData::Species.each_species { |sp| species << sp.species }
  blacklist = blacklist.compact.map(&:to_sym)
  species.reject! { |sp| blacklist.include?(sp) }
  return species.sample(count)
end
