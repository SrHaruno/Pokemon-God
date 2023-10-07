class GenderSelectorScene

def pbStartScene
@sprites = {}
@viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
@viewport.z = 99999
@select = -1
@finished = false

#===================================================
# Create bars
#===================================================

@sprites["bg"] = Sprite.new(@viewport)
@sprites["bg"].bitmap = RPG::Cache.picture("introbg")

@sprites["gendergirl"] = Sprite.new(@viewport)
@sprites["gendergirl"].bitmap = RPG::Cache.picture("genderselect")
@sprites["gendergirl"].y = Graphics.height / 2
@sprites["gendergirl"].x = Graphics.width
@sprites["genderboy"] = Sprite.new(@viewport)
@sprites["genderboy"].bitmap = RPG::Cache.picture("genderselect")
@sprites["genderboy"].y = Graphics.height / 2
@barwidth = @sprites["gendergirl"].bitmap.width
@barheight = @sprites["gendergirl"].bitmap.height / 2
@sprites["gendergirl"].src_rect.set(0, 0, @barwidth, @barheight)
@sprites["genderboy"].src_rect.set(0, @barheight, @barwidth, @barheight)
@sprites["gendergirl"].oy = @barheight / 2
@sprites["genderboy"].oy = @barheight / 2
@sprites["gendergirl"].ox = @barwidth / 2 - @barwidth / 6
@sprites["genderboy"].ox = @barwidth / 2 + @barwidth / 6


#===================================================
# Create trainer sprites
#===================================================
  @sprites["girl"] = Sprite.new(@viewport)
  @sprites["girl"].bitmap = Bitmap.new(TRAINERFEMALE)
  @sprites["girl"].zoom_x = 2.0; @sprites["girl"].zoom_y = 2.0
  @totalframeg = @sprites["girl"].bitmap.width/@sprites["girl"].bitmap.height
  @totalframeg = 1 if @totalframeg < 1
  realwidthg = @sprites["girl"].bitmap.width / @totalframeg
  @sprites["girl"].src_rect.set((@totalframeg - 1) * realwidthg, 0,
  realwidthg,@sprites["girl"].bitmap.height)
  @sprites["girl"].oy = @sprites["girl"].bitmap.height / 2
  @sprites["girl"].ox = realwidthg / 2
  @sprites["girl"].x = 412
  @sprites["girl"].y = Graphics.height / 2

  @sprites["boy"] = Sprite.new(@viewport)
  @sprites["boy"].bitmap = Bitmap.new(TRAINERMALE)
  @sprites["boy"].zoom_x = 2.0; @sprites["boy"].zoom_y = 2.0
  @totalframeb = @sprites["boy"].bitmap.width/@sprites["boy"].bitmap.height
  @totalframeb = 1 if @totalframeb < 1
  realwidthb = @sprites["boy"].bitmap.width / @totalframeb
  @sprites["boy"].src_rect.set((@totalframeb - 1) * realwidthb, 0,
  realwidthb,@sprites["boy"].bitmap.height)
  @sprites["boy"].oy = @sprites["boy"].bitmap.height / 2
  @sprites["boy"].ox = realwidthb / 2
  @sprites["boy"].x = 100
  @sprites["boy"].y = Graphics.height / 2

  @BOYX = @sprites["boy"].x
  @GENDERBOYX = @sprites["genderboy"].x

  @GIRLX=@sprites["girl"].x
  @GENDERGIRLX=@sprites["gendergirl"].x

  @sprites["msgwindow"] = pbCreateMessageWindow(@viewport)

  @sprites["bg"].opacity = 0
  @sprites["genderboy"].opacity = 0
  @sprites["boy"].opacity = 0
  @sprites["gendergirl"].opacity = 0
  @sprites["girl"].opacity = 0

end


def pbEndScene
  pbDisposeSpriteHash(@sprites)
  @viewport.dispose
end

def pbHide
10.times do
Graphics.update
@sprites["bg"].opacity -= 25.5
@sprites["genderboy"].opacity -= 25.5
@sprites["boy"].opacity -= 25.5
@sprites["gendergirl"].opacity -= 25.5
@sprites["girl"].opacity -= 25.5
end
end

def pbShow
10.times do
Graphics.update
@sprites["bg"].opacity += 25.5
@sprites["genderboy"].opacity += 25.5
@sprites["boy"].opacity += 25.5
@sprites["gendergirl"].opacity += 25.5
@sprites["girl"].opacity += 25.5
end
end

def selectBoy
frame = 0
6.times do
Graphics.update
frame += 1
@sprites["genderboy"].tone.set(0, 0, 0, 0)
@sprites["boy"].tone.set(0, 0, 0, 0)

@sprites["genderboy"].x += 12
@sprites["boy"].x += 12

if @select == -1
@sprites["gendergirl"].x += 6
@sprites["girl"].x += 6
else
@sprites["gendergirl"].x += 12
@sprites["girl"].x += 12
end

@sprites["boy"].zoom_x += 0.0005 * 2 if @sprites["boy"].zoom_x != 2.0
@sprites["boy"].zoom_y += 0.0005 * 2 if @sprites["boy"].zoom_y != 2.0
@sprites["genderboy"].zoom_x += 0.015 * 2 if @sprites["genderboy"].zoom_x != 1.0
@sprites["genderboy"].zoom_y += 0.015 * 2 if @sprites["genderboy"].zoom_y != 1.0

@sprites["gendergirl"].zoom_x -= 0.015
@sprites["gendergirl"].zoom_y -= 0.015
@sprites["girl"].zoom_x -= 0.0005 * 2
@sprites["girl"].zoom_y -= 0.0005 * 2

if frame == 4
@sprites["gendergirl"].tone.set(-20, -20, -20, 100)
@sprites["girl"].tone.set(-60, -60, -60, 100)
end
end
@select = 0
end

def selectGirl
frame = 0
6.times do
Graphics.update
frame += 1
@sprites["gendergirl"].tone.set(0, 0, 0, 0)
@sprites["girl"].tone.set(0, 0, 0, 0)
@sprites["gendergirl"].x -= 12
@sprites["girl"].x -= 12

if @select == -1
@sprites["genderboy"].x -= 6
@sprites["boy"].x -= 6
else
@sprites["genderboy"].x -= 12
@sprites["boy"].x -= 12
end

@sprites["girl"].zoom_x += 0.0005 * 2 if @sprites["girl"].zoom_x != 2.0
@sprites["girl"].zoom_y += 0.0005 * 2 if @sprites["girl"].zoom_y != 2.0
@sprites["gendergirl"].zoom_x += 0.015 * 2 if @sprites["gendergirl"].zoom_x != 1.0
@sprites["gendergirl"].zoom_y += 0.015 * 2 if @sprites["gendergirl"].zoom_y != 1.0

@sprites["genderboy"].zoom_x -= 0.015
@sprites["genderboy"].zoom_y -= 0.015
@sprites["boy"].zoom_x -= 0.0005 * 2
@sprites["boy"].zoom_y -= 0.0005 * 2

if frame == 4
@sprites["genderboy"].tone.set(-20, -20, -20, 100)
@sprites["boy"].tone.set(-60, -60, -60, 100)
end
end
@select = 1
end

def selection

if @select == 0 # Boy is selected
actualboyx = @sprites["boy"].x
22.times do # Animation
Graphics.update
@sprites["gendergirl"].x += 16
@sprites["girl"].x += 12
@sprites["genderboy"].x += 16
@sprites["genderboy"].zoom_y -= 0.008
@sprites["boy"].x += 12 if @sprites["boy"].x != Graphics.width / 2
@sprites["boy"].x = Graphics.width / 2 if @sprites["boy"].x > Graphics.width / 2

end

if !pbConfirmMessage(_INTL("You're a boy, right?"))
22.times do
Graphics.update
@sprites["gendergirl"].x -= 16
@sprites["girl"].x -= 12
@sprites["genderboy"].x -= 16
@sprites["genderboy"].zoom_y += 0.008
@sprites["boy"].x -= 12 if @sprites["boy"].x != actualboyx
@sprites["boy"].x = actualboyx if @sprites["boy"].x < actualboyx
@sprites["msgwindow"].visible = true
end
else
  pbChangePlayer(1)
  @sprites["msgwindow"].visible = false
  pbMessage("I'd like to know your name.\nPlease tell me.")
  selectName
end


else # Girl is selected
actualgirlx=@sprites["girl"].x
22.times do # Animation
Graphics.update
@sprites["genderboy"].x -= 16
@sprites["boy"].x -= 12
@sprites["gendergirl"].x -= 16
@sprites["gendergirl"].zoom_y -= 0.008
@sprites["girl"].x -= 12 if @sprites["girl"].x != Graphics.width / 2
@sprites["girl"].x = Graphics.width / 2 if @sprites["girl"].x < Graphics.width / 2
end

if !pbConfirmMessage(_INTL("You're a girl, right?"))
22.times do
Graphics.update
@sprites["genderboy"].x += 16
@sprites["boy"].x += 12
@sprites["gendergirl"].x += 16
@sprites["gendergirl"].zoom_y += 0.008
@sprites["girl"].x += 12 if @sprites["girl"].x != actualgirlx
@sprites["girl"].x = actualgirlx if @sprites["girl"].x > actualgirlx
@sprites["msgwindow"].visible = true
end
else
pbChangePlayer(2)
@sprites["msgwindow"].visible = false
pbMessage("I'd like to know your name.\nPlease tell me.")
selectName
    end

  end
end

def selectName
if WRITETRAINERNAME
  pbHide
  pbTrainerName
  if !pbConfirmMessage(_INTL("Your name is {1}?", $player.name))
    selectName
  else
    @finished = true
  end
else
  @finished = true
end
end

def pbUpdate
  pbShow
  pbMessageDisplay(@sprites["msgwindow"],
      _INTL("Are you a boy?\nOr a girl?"))
  selectBoy
loop do
  Graphics.update
  Input.update

  if Input.trigger?(Input::LEFT)
    selectBoy if @select != 0
  elsif Input.trigger?(Input::RIGHT)
    selectGirl if @select != 1
  end

  if Input.trigger?(Input::C)
    selection
  end

  break if @finished
  end
end

end
###################################################

class GenderSelector

def initialize(scene)
@scene = scene
end

def pbStartScreen
@scene.pbStartScene
@scene.pbUpdate
@scene.pbEndScene
end

end

def pbGenderSelector
  scene = GenderSelectorScene.new
  screen = GenderSelector.new(scene)
  screen.pbStartScreen
end
