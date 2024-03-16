module CableClub
  HOST = "127.0.0.1"
  PORT = 9999
  
  ONLINE_TRAINER_TYPE_LIST = [
    [:POKEMONTRAINER_Blair,:POKEMONTRAINER_Whitlea],
    [:PSYCHIC_M,:PSYCHIC_F],
    [:BLACKBELT,:CRUSHGIRL],
    [:ACETRAINER_M,:ACETRAINER_F]
  ]
  ENABLE_RECORD_MIXER = false
  
  # If true, Sketch fails when used.
  # If false, Sketch is undone after battle
  DISABLE_SKETCH_ONLINE = true
end