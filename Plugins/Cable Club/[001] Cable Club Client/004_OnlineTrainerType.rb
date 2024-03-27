class Player
  attr_writer :online_trainer_type
  def online_trainer_type
    return @online_trainer_type || self.trainer_type
  end
  
  attr_writer :online_win_text
  def online_win_text
    return @online_win_text || 0
  end
  attr_writer :online_lose_text
    def online_lose_text
    return @online_lose_text || 0
  end
end