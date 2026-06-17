#-------------------------------------------------------------------------------
# Battle Intro Animations
# v0.1
# By PikachuMazzinga
#-------------------------------------------------------------------------------
# This is very WIP and made to work with sticks and stones during Eevee Expo
# Game Jam 10 time constrains, if you're looking copy for in your game, either
# wait for the full release or contact me in private on the forum or on discord. 
#-------------------------------------------------------------------------------

class PokemonIntroAnimation < Battle::Scene::Animation

  def fixN(pos)
    return @back ? pos.abs : pos
  end

  def initialize(sprites,viewport,pkmn,back = false)
    @pkmn = pkmn
    # @_iconBitmap = _iconBitmap
    @back = back

    @nameFrame1 = GameData::Species.sprite_name_from_pokemon(pkmn, back, false)
    @nameFrame2 = GameData::Species.sprite_name_from_pokemon(pkmn, back, true)
    @nameFrame2 = @nameFrame1 if @nameFrame2 == nil
    
    @animData = PokemonIntroAnimationSettings::ANIMATION_DATA[@pkmn.species] || PokemonIntroAnimationSettings::DEFAULT_BEHAVIOUR

    @animType = @animData[@back ? 2 : 0]
    @animFreq = @animData[@back ? 3 : 1]

    @animType = @animData[0] if @animType == nil && PokemonIntroAnimationSettings::DEFAULT_FRONT_BEHAVIOUR_ON_BACK
    @animFreq = @animData[1] if @animFreq == nil && PokemonIntroAnimationSettings::DEFAULT_FRONT_BEHAVIOUR_ON_BACK
    
    super(sprites,viewport)
  end

  def createProcesses
    batSprite  = @sprites[0]
    
    case batSprite.offset
    when PictureOrigin::CENTER, PictureOrigin::LEFT, PictureOrigin::RIGHT
      batSprite.y += batSprite.height / 2
    when PictureOrigin::BOTTOM, PictureOrigin::BOTTOM_LEFT, PictureOrigin::BOTTOM_RIGHT
      # do nothing
    when PictureOrigin::TOP, PictureOrigin::TOP_LEFT, PictureOrigin::TOP_RIGHT
      batSprite.y += batSprite.height
    end
    case batSprite.offset
    when PictureOrigin::LEFT, PictureOrigin::TOP_LEFT, PictureOrigin::BOTTOM_LEFT
      batSprite.x += batSprite.width / 2
    when PictureOrigin::CENTER, PictureOrigin::TOP, PictureOrigin::BOTTOM
      # do nothing
    when PictureOrigin::RIGHT, PictureOrigin::TOP_RIGHT, PictureOrigin::BOTTOM_RIGHT
      batSprite.x -= batSprite.width / 2
    end

    batSprite.setOffset(PictureOrigin::BOTTOM) if batSprite.respond_to?(:setOffset)
    battler    = addSprite(batSprite, PictureOrigin::BOTTOM)
    
    @starting_x = starting_x = batSprite.x
    @starting_y = starting_y = batSprite.y 
    
  
    path_A = @nameFrame1
    path_B = @nameFrame2

    totalDuration = 0
    
    # gif frame duration / PictureEx frame duration
    speedUp = (30.0/1000) / (1.0/20)

    # uncomment this to check slower animations
    # speedUp = 1 if $DEBUG && Input.press?(Input::CTRL)
    
    case @animType
    
    when "StretchVertical"
      zoom_values = [100, 102.5, 105, 106, 105, 107.5, 105, 110, 107.5, 110, 110, 105, 110, 107.5, 105, 102.5, 103, 101, 100, 100, 100]
      totalDuration = zoom_values.length
      zoom_values.each_with_index do |v,i|
        battler.setZoomXY(i*speedUp, 100, v)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "StretchHorizontal"
      zoom_values = [100, 102.5, 105, 106, 105, 107.5, 105, 110, 107.5, 110, 110, 105, 110, 107.5, 105, 102.5, 103, 101, 100, 100, 100]
      totalDuration = zoom_values.length
      zoom_values.each_with_index do |v,i|
        battler.setZoomXY(i*speedUp, v + (v-100), 100)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "FlyVertical"
      y_values = [0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 0, 0]
      totalDuration = y_values.length
      maxAngle = 15

      new_y = starting_y - (batSprite.height)/2
      battler.setOrigin(0,PictureOrigin::CENTER)
      battler.setXY(0,starting_x, new_y)

      y_values.each_with_index do |v,i|
        battler.setAngle(i*speedUp, Math.sin(i*(Math::PI*4)/totalDuration)*maxAngle)
        battler.setXY(i*speedUp, starting_x, new_y + fixN(v*2))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "FlyHorizontal"
      x_values = [0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 0, 0]
      totalDuration = x_values.length
      maxAngle = 15

      new_y = starting_y - (batSprite.height)/2
      battler.setOrigin(0,PictureOrigin::CENTER)
      battler.setXY(0,starting_x, new_y)

      x_values.each_with_index do |v,i|
        battler.setAngle(i*speedUp, Math.sin(i*(Math::PI*4)/totalDuration)*maxAngle)
        battler.setXY(i*speedUp, starting_x + (v*2), new_y)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "SlideVertical"
      y_values = [0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x, starting_y + fixN(v*2))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "SlideHorizontal"
      x_values = [0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x + (v*2), starting_y)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "StompSmall"
      y_values = [0, 2, -1, 3, -2, 3, -1, 4, -1, 4, -1, 3, -1, 2, 0, 2, 0, 3, 1, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x, starting_y + fixN(v*2))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "StompBig"
      y_values = [0, 0, 0, 0, 0, 0, 2, -1, 3, -2, 3, -1, 4, -1, 4, -1, 3, -1, 2, 0, 2, 0, 3, 1, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x, starting_y + fixN(v*2))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "StompDouble"
      y_values = [0, 0, 0, 0, 0, 0, 3, -5, 2, 0, -3, 3, -3, 0, 1, -2, 0, 0, 0, 3, -5, 2, 0, -3, 3, -3, 0, 1, -2, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x, starting_y + fixN(v*2))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "ShakeSmall"
      x_values = [0, 0, 0, -2, 1, -3, 2, -3, 2, -3, 2, -3, 2, 1, 0, -1, 1, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x + (v*2), starting_y)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "ShakeBig"
      x_values = [0, 0, 0, -1, 1, -2, 2, -3, 3, -4, 4, -4, 4, -5, 5, -5, 5, -5, 5, -6, 6, -5, 5, -5, 5, -4, 4, -3, 3, -3, 3, -2, 2, -1, 1, 0, 0, 0, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x + (v*2), starting_y)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "HopSmall"
      y_values = [0, 0, 0, 0, 0, 0, 0, 0, -4, -6, -4, 0, -4, -6, -4, 0, -6, -9, -6, 0, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x, starting_y + fixN(v*2))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "HopBig"
      totalDuration = 36
      
      battler.moveCurve( 1*speedUp, 10*speedUp, 
                                starting_x,    starting_y, 
                                starting_x-16,  fixN(starting_y-32), 
                                starting_x-32, starting_y)
      battler.moveCurve(13*speedUp, 10*speedUp, 
                                starting_x-32, starting_y, 
                                starting_x,    fixN(starting_y-32), 
                                starting_x+16,  starting_y)
      battler.moveCurve(25*speedUp, 10*speedUp, 
                                starting_x+16,  starting_y, 
                                starting_x+16,  fixN(starting_y-16), 
                                starting_x,    starting_y)

      battler.moveZoomXY( 8*speedUp, 5*speedUp, 110, 90)
      battler.moveZoomXY(13*speedUp, 5*speedUp, 90, 110)
      battler.moveZoomXY(18*speedUp, 5*speedUp, 100, 100)
      battler.moveZoomXY(23*speedUp, 4*speedUp, 110, 90)
      battler.moveZoomXY(27*speedUp, 4*speedUp, 100, 100)
      for i in 0...totalDuration do
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "HopAround"
      y_values = [0, 0, 0, 0, 0, 0, 0, 0, -4, -6, -4, 0, -4, -6, -4, 0, -6, -9, -6, 0, 0, 0]
      x_values = [0, 0, 0, 0, 0, 0, 0, 0, -4, -6, -8, -8, -4, 0, 4, 8, 6, 4, 2, 0, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x + (x_values[i]*2), starting_y + fixN(v*2))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "RotateBottom"
      totalDuration = 30
      maxAngle = 15
      for i in 0...totalDuration do
        battler.setAngle(i*speedUp, Math.sin(i*(Math::PI*2)/totalDuration)*maxAngle)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "RotateTop" 
      battler.setOrigin(0,PictureOrigin::TOP)
      battler.setXY(0,starting_x, starting_y - batSprite.height)
      totalDuration = 30
      maxAngle = 15
      battler.setOrigin(totalDuration*speedUp,PictureOrigin::BOTTOM)
      battler.setXY(totalDuration*speedUp,starting_x, starting_y)
      for i in 0...totalDuration do
        battler.setAngle(i*speedUp, Math.sin(i*(Math::PI*2)/totalDuration)*maxAngle)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "RotateJump"
      totalDuration = 80
      angle = 15
      slide = 8

      battler.moveCurve( 0*speedUp, 7*speedUp,
                         starting_x,    starting_y,
                         starting_x+slide/2,  fixN(starting_y-48),
                         starting_x+slide, starting_y)
      
      battler.moveCurve( 8*speedUp, 12*speedUp,
                         starting_x+slide,    starting_y,
                         starting_x,  fixN(starting_y-48),
                         starting_x-slide, starting_y)

      battler.moveCurve( 20*speedUp, 12*speedUp,
                         starting_x-slide,    starting_y,
                         starting_x,  fixN(starting_y-48),
                         starting_x+slide, starting_y)

      battler.moveCurve( 32*speedUp, 12*speedUp,
                         starting_x+slide,    starting_y,
                         starting_x,  fixN(starting_y-48),
                         starting_x-slide, starting_y)

      battler.moveCurve( 44*speedUp, 12*speedUp,
                         starting_x-slide,    starting_y,
                         starting_x,  fixN(starting_y-48),
                         starting_x+slide, starting_y)

      battler.moveCurve( 56*speedUp, 12*speedUp,
                         starting_x+slide,    starting_y,
                         starting_x,  fixN(starting_y-48),
                         starting_x-slide, starting_y)

      battler.moveCurve( 68*speedUp, 12*speedUp,
                         starting_x-slide,    starting_y,
                         starting_x-slide/2,  fixN(starting_y-36),
                         starting_x, starting_y)

      battler.moveAngle(      0*speedUp,  7*speedUp, angle)
      battler.moveAngle( ( 8+1)*speedUp, 11*speedUp,-angle)
      battler.moveAngle( (20+1)*speedUp, 11*speedUp,angle)
      battler.moveAngle( (32+1)*speedUp, 11*speedUp,-angle)
      battler.moveAngle( (44+1)*speedUp, 11*speedUp,angle)
      battler.moveAngle( (56+1)*speedUp, 11*speedUp,-angle)
      battler.moveAngle( (68+1)*speedUp, 11*speedUp,0)
      
      for i in 0...totalDuration do
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "Explosion"
      zoom_values = [100, 100, 95, 100, 90, 95, 90, 95, 87.5, 95, 87.5, 95, 87.5, 95, 90, 95, 100, 95, 100, 100, 102.5, 100, 105, 100, 110, 105, 110, 105, 110, 105, 110, 105, 110, 100, 105, 100, 102.5, 100, 100, 100]
      totalDuration = zoom_values.length
      # battler.setOrigin(0,PictureOrigin::CENTER)
      # battler.setOrigin(totalDuration,PictureOrigin::BOTTOM)
      zoom_values.each_with_index do |v,i|
        battler.setZoomXY(i*speedUp, v, v)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "Bounce"
      y_values      = [  0,  0,      0,    0,   0,     0,   0,    0,     0,   0,     -1,   -3,  -4,    -5,  -4,   -3,    -1,   0,     0,    0,   0,     0,   0,    0,     0,   0,   0,   0,   0,   0,   0]
      zoom_x_values = [100, 100, 102.5,  105, 110, 112.5, 110,  105, 102.5, 100,     95, 92.5,  90,  87.5,  90, 92.5,    95, 100, 102.5,  105, 110, 112.5, 110,  105, 102.5, 100, 100, 100, 100, 100, 100]
      zoom_y_values = [100, 100,    95, 92.5,  90,  87.5,  90, 92.5,    95, 100,  102.5,  105, 110, 112.5, 110,  105, 102.5, 100,    95, 92.5,  90,  87.5,  90, 92.5,    95, 100, 100, 100, 100, 100, 100]

      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x, starting_y + fixN(v*2))
        battler.setZoomXY(i*speedUp, zoom_x_values[i], zoom_y_values[i])
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "Boing"
      y_values      = [  0,  0,      0,    0,   0,     0,   0,    0,     0,   0,     -1,   -3,  -4,    -5,  -4,   -3,    -1,   0,     0,    0,   0,     0,   0,    0,     0,   0,   0]
      zoom_x_values = [100, 100, 102.5,  105, 110, 112.5, 110,  105, 102.5, 100,     95, 92.5,  90,  87.5,  90, 92.5,    95, 100, 102.5,  105, 110, 112.5, 110,  105, 102.5, 100, 100]
      zoom_y_values = [100, 100,    95, 92.5,  90,  87.5,  90, 92.5,    95, 100,  102.5,  105, 110, 112.5, 110,  105, 102.5, 100,    95, 92.5,  90,  87.5,  90, 92.5,    95, 100, 100]

      totalDuration = y_values.length*2
      y_values.each_with_index do |v,i|
        battler.moveXY(i*speedUp*2, 2, starting_x, starting_y + fixN(v*2))
        battler.moveZoomXY(i*speedUp*2, 2, zoom_x_values[i], zoom_y_values[i])
        battler.setName(i*speedUp*2, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "Fluid"
      zoom_values = [100, 100, 100, 90, 86, 95, 100, 105, 110, 102, 90, 86, 95, 100, 105, 110, 102, 100, 100, 100, 100, 100]
      totalDuration = zoom_values.length
      
      new_y = starting_y - (batSprite.height)/2
      battler.setOrigin(0,PictureOrigin::CENTER)
      battler.setXY(0,starting_x, new_y)

      zoom_values.each_with_index do |v,i|
        u = i > 3 ? zoom_values[i-3] : 100
        battler.setZoomXY(i*speedUp, (v*2)-100, (u*2)-100)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "ZoomDouble"      
      zoom_values = [100, 100, 100, 100, 100, 100, 95, 90, 88, 86, 88, 90, 92, 95, 100, 102, 105, 107.5, 108, 107.5, 105, 102, 100, 95, 92, 90, 88, 90, 92, 95, 100, 100, 100]
      totalDuration = zoom_values.length
      # battler.setOrigin(0,PictureOrigin::CENTER)
      # battler.setOrigin(totalDuration,PictureOrigin::BOTTOM)
      zoom_values.each_with_index do |v,i|
        battler.setZoomXY(i*speedUp, v, v)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "Glide" # intended for Gligar but unused
      x_values = [0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        k = Math.sin(i*(Math::PI*2)/totalDuration) * 20
        j = Math.cos(i*(Math::PI*2)/totalDuration) * 20
        battler.setXY(i*speedUp, starting_x + j, starting_y + fixN(k))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "BlinkYellow"
      x_values       = [0, 0, 0, -2, 1, -3, 2, -3, 2, -3, 2, -3, 2, 1, 0, -1, 1, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      # x_values     = [ 0, 2, 2, 0, 0, 2, 2, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # real values but lame imo (?)
      color_values   = [ 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x + (v*2), starting_y)
        battler.setColor(i*speedUp, color_values[i] == 0 ? Color.new(0, 0, 0, 0) : Color.new(255, 255, 0, 255))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end

    # Custom / Unused in HGSS
    
    when "GIF" # for Crystal-like animations
      totalDuration = 30 # d=====(￣▽￣*) source : trust me bro
      battler.setName(0, path_B)
      battler.setName(totalDuration, path_A)

    when "BlinkRed" # mainly used for backsprites in DPPT
      x_values       = [0, 0, 0, -2, 1, -3, 2, -3, 2, -3, 2, -3, 2, 1, 0, -1, 1, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      color_values   = [ 0, 0, 0, 0, 0, 32, 32, 80, 80, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 80, 80, 32, 32, 0, 0, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x + (v*2), starting_y)
        battler.setColor(i*speedUp, Color.new(255, 0, 0, color_values[i]))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "BlinkBlue" # mainly used for backsprites in DPPT
      x_values       = [0, 0, 0, -2, 1, -3, 2, -3, 2, -3, 2, -3, 2, 1, 0, -1, 1, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      color_values   = [ 0, 0, 0, 0, 0, 32, 32, 80, 80, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 80, 80, 32, 32, 0, 0, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i*speedUp, starting_x + (v*2), starting_y)
        battler.setColor(i*speedUp, color_values[i] == 0 ? Color.new(0, 0, 0, 0) : Color.new(0, 0, 255, 255))
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "DoAFlip" # just a silly one, define yours next
      x_values = [0, -1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -9, -9, -10, -10, -10, -10, -10, -9, -9, -9, -8, -8, -7, -6, -5, -4, -3, -2, -1, -0, 2, 1, 0, 0, 0, 0]
      totalDuration = x_values.length
      maxAngle = 360

      new_y = starting_y - (batSprite.height)/2
      battler.setOrigin(0,PictureOrigin::CENTER)
      battler.setXY(0,starting_x, new_y)

      x_values.each_with_index do |v,i|
        battler.setAngle(i*speedUp, Math.sin(i*(Math::PI/2)/totalDuration)*maxAngle)
        battler.setXY(i*speedUp, starting_x + (v*4), new_y)
        battler.setName(i*speedUp, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end

    else
      # do nothing?

    end
    
    # reset battler's attributes at the end
    totalDuration *= speedUp
    battler.setAngle(totalDuration, 0)
    battler.setZoomXY(totalDuration, 100, 100)
    battler.setName(totalDuration, path_A)
    battler.setOrigin(totalDuration,PictureOrigin::BOTTOM)
    battler.setXY(totalDuration, starting_x, starting_y)
    battler.setColor(totalDuration,Color.new(0,0,0,0))
  end
  
  def dispose
    reset_sprite
    @tempSprites.each { |s| s&.dispose }
  end
  
  def reset_sprite
    batSprite  = @sprites[0]
    batSprite.x = @starting_x
    batSprite.y = @starting_y
    batSprite.name = @nameFrame1
    batSprite.setOffset(PictureOrigin::BOTTOM) if batSprite.respond_to?(:setOffset)
    batSprite.color = Color.new(0,0,0,0)
    batSprite.zoom_x = batSprite.zoom_y = 1
    batSprite.angle = 0
  end

  # def getAnimSprite(animDuration = 30, i = 0)
  #   @_iconBitmap = getAnimationFrameChar(@animFreq, animDuration, i) == "B" ? @spriteFrame2 : @spriteFrame1
  #   return @_iconBitmap.bitmap
  # end

  def getAnimationFrameChar(animFreq = nil, animDuration = 30, i = 0)
    return "B" if animFreq == nil || animFreq == ""
    return animFreq.chars[((i.to_f/animDuration)*animFreq.length).to_i]
  end

end
