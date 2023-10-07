#===============================================================================
# € BW Get Key Item v2.3 for v19.x
#
# Original version by KleinStudio
#
# Updated Version for Essentials v18.x by DeepBlue PacificWaves
# Updated Version for Essentials v19.x by Izanagi
#
# The original post can be found in: https://www.deviantart.com/kleinstudio,
# however the original script and graphics are unavailable.
#
# The version I've updated can be found in the Pokemon Essentials BW V3.1.1,
# available in the same gallery.
#===============================================================================
# Instructions:
#
# Extract the file BW Get Key Item into your main project folder. If the script
# doesn't load, delete the PluginScripts file in the Data folder of your main
# project and then run the game again from RMXP.
#
# To call the scene, use the command "pbGetKeyItem(:XXXX,Y)" without quotation,
# where X is the internal name of the item you're gonna give and Y is the quantity
# of items you're gonna give.
#
# Ex: pbGetKeyItem(:BICYCLE,5)
#
# The script will automatically play the animation displaying the icon defined in
# Graphics/Items/Key Items. If you want to display the bigger icon
# ( aka, à la Gen V style), you need to name the icon XXXXXX_key, where X is the
# default naming convention of Pokémon Essentials for icons.
#
# Ex: POTION_key
#
# You can also use "pbGetKeyItem("XXXXXX")", where X is the name of the image file
# of an item that's note defined in PBS Items.
#
# Ex: pbGetKeyItem("itemDexMaleKey")
#
# But this method will not show the "Get Item" message. Note that quotation
# inside the parentheses is necessary in order to the "fake item" to display.
#
#===============================================================================

class GetKeyItemScene

def initialize(item, quantity, plural)
 @item = item
 @quantity = quantity
 @plural = plural
end

def pbStartScene
 @sprites = {}
 @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height) # Updated DEFAULTSCREENHEIGHT
 @viewport.z = 99999
 @finished = false

 @sprites["whitescreen"] = Sprite.new(@viewport)
 @sprites["whitescreen"].color = Color.new(255, 255, 255)
 @sprites["whitescreen"].opacity = 0

 @sprites["bg"] = Sprite.new(@viewport)
 @sprites["bg"].bitmap = RPG::Cache.picture("keyitembg")
 @sprites["bg"].ox = @sprites["bg"].bitmap.width / 2
 @sprites["bg"].oy = @sprites["bg"].bitmap.height / 2
 @sprites["bg"].y = Settings::SCREEN_HEIGHT / 2 # Updated DEFAULTSCREENHEIGHT
 @sprites["bg"].x = Settings::SCREEN_WIDTH / 2  # Updated DEFAULTSCREENWIDTH
 @sprites["bg"].zoom_y = 0
 @sprites["bg"].zoom_x = 0
 @sprites["bg"].opacity = 0

  if !@item.is_a?(String)
     iconname = _INTL("Graphics/Items/Key Items/{1}_key", @item)
    if !pbResolveBitmap(iconname)
     iconname = _INTL("Graphics/Items/{1}", @item)
    end
  else
   iconname = _INTL("Graphics/Items/Key Items/{1}", @item)
   @fakeitem = true
end

 @sprites["item"] = IconSprite.new(Settings::SCREEN_WIDTH / 2, Settings::SCREEN_HEIGHT / 2, @viewport)
 # Updated DEFAULTSCREENHEIGHT and DEFAULTSCREENWIDTH
 @sprites["item"].setBitmap(iconname)
 @sprites["item"].ox = @sprites["item"].bitmap.width / 2
 @sprites["item"].oy = @sprites["item"].bitmap.height / 2
 @sprites["item"].angle = 180
 @sprites["item"].zoom_y = 0
 @sprites["item"].zoom_x = 0
 @sprites["item"].opacity = 0

end


def pbEndScene
  pbDisposeSpriteHash(@sprites)
  @viewport.dispose
end

def shakeItem
   3.times do
   Graphics.update
   @sprites["item"].angle += 2
   end
   3.times do
   Graphics.update
   @sprites["item"].angle -= 2
   end
   3.times do
   Graphics.update
   @sprites["item"].angle -= 2
   end
   3.times do
   Graphics.update
   @sprites["item"].angle += 2
   end
end

def pbUpdate
  10.times do
  Graphics.update
  @sprites["whitescreen"].opacity += 255 / 10
  end
  10.times do
  Graphics.update
  @sprites["whitescreen"].opacity -= 255 / 10
end
  frametome = 0
  18.times do
  frametome += 1
  Graphics.update
  @sprites["item"].angle -= 15 / 2 if @sprites["item"].angle != 0
  @sprites["item"].angle = 0 if @sprites["item"].angle < 0
  pbMEPlay("Key item get") if frametome == 7  # Updated ME to Essentials Default
  @sprites["bg"].zoom_y += 0.1 / 2 if @sprites["bg"].zoom_y < 1.75
  @sprites["bg"].zoom_x += 0.1 / 2 if @sprites["bg"].zoom_x < 1.75
  @sprites["bg"].opacity += 14.16
  @sprites["item"].zoom_y += 0.17 / 2
  @sprites["item"].zoom_x += 0.17 / 2
  @sprites["item"].opacity += 14.16
  end
  12.times do
  Graphics.update
  @sprites["item"].angle -= 15 / 2 if @sprites["item"].angle != 0
  @sprites["item"].angle = 0 if @sprites["item"].angle < 0

  @sprites["bg"].zoom_y += 0.1 / 2 if @sprites["bg"].zoom_y > 1
  @sprites["bg"].zoom_x += 0.1 / 2 if @sprites["bg"].zoom_x > 1
  @sprites["bg"].zoom_x = 1 if @sprites["bg"].zoom_x < 1
  @sprites["bg"].zoom_y = 1 if @sprites["bg"].zoom_y < 1

  @sprites["item"].zoom_y-=0.17/2 if @sprites["item"].zoom_y>1
  @sprites["item"].zoom_x-=0.17/2 if @sprites["item"].zoom_x>1
  @sprites["item"].zoom_x = 1 if @sprites["item"].zoom_x < 1
  @sprites["item"].zoom_y = 1 if @sprites["item"].zoom_y < 1
  end
  @sprites["item"].angle = 0
  @sprites["item"].zoom_y = 1
  @sprites["item"].zoom_x = 1
  @sprites["bg"].zoom_y = 1
  @sprites["bg"].zoom_x = 1
  shakeItem
  pbWait(1)
  18.times do
  Graphics.update
  @sprites["bg"].zoom_y -= 0.15 / 2
  @sprites["bg"].zoom_x += 0.1 / 2
  @sprites["bg"].opacity -= 14.16
  @sprites["item"].zoom_y -= 0.17 / 2
  @sprites["item"].zoom_x -= 0.17 / 2
  @sprites["item"].opacity -= 14.16
  end
  pbReceiveItem(@item, @quantity) if !@fakeitem # Deleted Kernel. and @plural
  # Deleted the loop do code
    end
  end

###################################################

class GetKeyItem

def initialize(scene)
 @scene = scene
end

def pbStartScreen
 @scene.pbStartScene
 @scene.pbUpdate
 @scene.pbEndScene
end

end

def pbGetKeyItem(item, quantity = 1, plural = nil)
  scene = GetKeyItemScene.new(item, quantity, plural)
  screen = GetKeyItem.new(scene)
  screen.pbStartScreen
 end
