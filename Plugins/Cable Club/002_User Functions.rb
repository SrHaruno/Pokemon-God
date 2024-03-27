# Returns false if an error occurred.
def pbCableClub
  scene = CableClub_Scene.new
  screen = CableClubScreen.new(scene)
  return screen.pbStartScreen
end

def pbChangeOnlineTrainerType
  old_trainer_type = $player.online_trainer_type
  if $player.online_trainer_type==$player.trainer_type
    pbMessage(_INTL("Hmmm...!\\1"))
    pbMessage(_INTL("What is your favorite kind of Trainer?\\nCan you tell me?\\1"))
  else
    trainername=GameData::TrainerType.get($player.online_trainer_type).name
    if ['a','e','i','o','u'].include?(trainername[0,1].downcase)
      msg=_INTL("Hello! You've been mistaken for an {1}, haven't you?\\1",trainername)
    else
      msg=_INTL("Hello! You've been mistaken for a {1}, haven't you?\\1",trainername)
    end
    pbMessage(msg)
    pbMessage(_INTL("But I think you can also pass for a different kind of Trainer.\\1"))
    pbMessage(_INTL("So, how about telling me what kind of Trainer that you like?\\1"))
  end
  commands=[]
  trainer_types=[]
  CableClub::ONLINE_TRAINER_TYPE_LIST.each do |type|
    t=type
    t=type[$player.gender] if type.is_a?(Array)
    commands.push(GameData::TrainerType.get(t).name)
    trainer_types.push(t)
  end
  commands.push(_INTL("Cancel"))
  loop do
    cmd=pbMessage(_INTL("Which kind of Trainer would you like to be?"),commands,-1)
    if cmd>=0 && cmd<commands.length-1
      trainername=commands[cmd]
      if ['a','e','i','o','u'].include?(trainername[0,1].downcase)
        msg=_INTL("An {1} is the kind of Trainer you want to be?",trainername)
      else
        msg=_INTL("A {1} is the kind of Trainer you want to be?",trainername)
      end
      if pbConfirmMessage(msg)
        if ['a','e','i','o','u'].include?(trainername[0,1].downcase)
          msg=_INTL("I see! So an {1} is the kind of Trainer you like.\\1",trainername)
        else
          msg=_INTL("I see! So a {1} is the kind of Trainer you like.\\1",trainername)
        end
        pbMessage(msg)
        pbMessage(_INTL("If that's the case, others may come to see you in the same way.\\1"))
        $player.online_trainer_type=trainer_types[cmd]
        break
      end
    else
      break
    end
  end
  pbMessage(_INTL("OK, then I'll just talk to you later!"))
  if old_trainer_type != $player.online_trainer_type
    EventHandlers.trigger(:cable_club_trainer_type_updated,$player.online_trainer_type)
  end
end

def pbChangeOnlineWinText
  pbMessage(_INTL("When winning a battle, a powerful victory speech is the way to go.\\1"))
  commands = []
  CableClub::ONLINE_WIN_SPEECHES_LIST.each do |text|
    commands.push(_INTL(text))
  end
  commands.push(_INTL("Cancel"))
  loop do
    cmd=pbMessage(_INTL("What kind of speech speaks to you?"),commands,-1)
    if cmd>=0 && cmd<CableClub::ONLINE_WIN_SPEECHES_LIST.length-1
      win_text=commands[cmd]
      if pbConfirmMessage(_INTL("\"{1}\"\\nThis is what you wish to say?",win_text))
        pbMessage(_INTL("\"{1}\"\\nThis is a powerful speech indeed.\\1",win_text))
        $player.online_win_text=cmd
        break
      end
    else
      break
    end
  end
  pbMessage(_INTL("Show your strength with your speech!"))
end

def pbChangeOnlineLoseText
  pbMessage(_INTL("When you lose a battle, you still need to say something...\\1"))
  commands = []
  CableClub::ONLINE_LOSE_SPEECHES_LIST.each do |text|
    commands.push(_INTL(text))
  end
  commands.push(_INTL("Cancel"))
  loop do
    cmd=pbMessage(_INTL("What kind of speech speaks to you?"),commands,-1)
    if cmd>=0 && cmd<CableClub::ONLINE_LOSE_SPEECHES_LIST.length-1
      lose_text=commands[cmd]
      if pbConfirmMessage(_INTL("\"{1}\"\\nThis is what you wish to say?",lose_text))
        pbMessage(_INTL("\"{1}\"\\nYeah... That sounds good...\\1",lose_text))
        $player.online_lose_text=cmd
        break
      end
    else
      break
    end
  end
  pbMessage(_INTL("...Hopefully you don't need to use it."))
end