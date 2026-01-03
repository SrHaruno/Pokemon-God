class GameStats
  def online_link_count;   return @online_link_count   || 0; end
  def online_battles_wins; return @online_battles_wins || 0; end
  def online_battles_lost; return @online_battles_lost || 0; end
  def online_trade_count;  return @online_trade_count  || 0; end
  
  attr_writer :online_link_count
  attr_writer :online_battles_wins, :online_battles_lost
  attr_writer :online_trade_count
end

module CableClub
  ACTIVITY_OPTIONS = {:battle => _INTL("battle"),
                      :trade => _INTL("trade"),
                      :record_mix => _INTL("mix records")}
  def self.pokemon_order(client_id)
    case client_id
    when 0; [0, 1, 2, 3, 4, 5]
    when 1; [1, 0, 3, 2, 5, 4]
    else; raise "Unknown client_id: #{client_id}"
    end
  end

  def self.pokemon_target_order(client_id)
    case client_id
    when 0..1; [1, 0, 3, 2, 5, 4]
    else; raise "Unknown client_id: #{client_id}"
    end
  end

  def self.do_battle(connection, client_id, seed, battle_rules, player_party, partner, partner_party)
    $player.heal_party # Avoids having to transmit damaged state.
    partner_party.each{|pkmn| pkmn.heal} # back to back battles desync without it.
    olditems  = player_party.transform { |p| p.item_id }
    olditems2 = partner_party.transform { |p| p.item_id }
    if !DISABLE_SKETCH_ONLINE
      oldmoves  = player_party.transform { |p| p.moves.dup }
      oldmoves2 = partner_party.transform { |p| p.moves.dup }
    end
    if PluginManager.installed?("Terastal Phenomenon") ||
       PluginManager.installed?("[DBK] Terastallization")
      old_tera = $player.tera_charged?
      $player.tera_charged = true
    end
    scene = BattleCreationHelperMethods.create_battle_scene
    battle = Battle_CableClub.new(connection, client_id, scene, player_party, partner_party, partner, seed)
    battle.items = []
    battle.internalBattle = false
    battle_rules.applyBattleRules(battle)
    trainerbgm = pbGetTrainerBattleBGM(partner)
    EventHandlers.trigger(:on_start_battle)
    # XXX: Configuring Online Battle Rules
    setBattleRule("environment", :None)
    setBattleRule("weather", :None)
    setBattleRule("terrain", :None)
    setBattleRule("backdrop", "indoor1")
    BattleCreationHelperMethods.prepare_battle(battle)
    $game_temp.clear_battle_rules
    battle.time = 0
    exc = nil
    outcome = 0
    pbBattleAnimation(trainerbgm, (battle.singleBattle?) ? 1 : 3, [partner]) {
      pbSceneStandby {
        begin
          outcome = battle.pbStartBattle
        rescue Connection::Disconnected
          scene.pbEndBattle(0)
          exc = $!
        ensure
          if PluginManager.installed?("Terastal Phenomenon") ||
             PluginManager.installed?("[DBK] Terastallization")
            $player.tera_charged = old_tera
          end
          player_party.each_with_index do |pkmn, i|
            pkmn.heal
            pkmn.makeUnmega
            pkmn.makeUnprimal
            pkmn.item = olditems[i]
            if !DISABLE_SKETCH_ONLINE
              pkmn.moves.clear
              oldmoves[i].each_with_index {|move,i| pkmn.moves[i]=move}
            end
            pkmn.unmax if PluginManager.installed?("ZUD Mechanics")
            if PluginManager.installed?("[DBK] Dynamax")
               if pkmn.dynamax?
                 pkmn.makeUndynamaxForm
                 pkmn.makeUndynamax
                 pkmn.calc_stats
               end
            end
            if PluginManager.installed?("Terastal Phenomenon") ||
               PluginManager.installed?("[DBK] Terastallization")
              pkmn.terastallized = false if pkmn&.tera?
            end
          end
          partner_party.each_with_index do |pkmn, i|
            pkmn.heal
            pkmn.makeUnmega
            pkmn.makeUnprimal
            pkmn.item = olditems2[i]
            if !DISABLE_SKETCH_ONLINE
              pkmn.moves.clear
              oldmoves2[i].each_with_index {|move,i| pkmn.moves[i]=move}
            end
            pkmn.unmax if PluginManager.installed?("ZUD Mechanics")
            if PluginManager.installed?("[DBK] Dynamax")
               if pkmn.dynamax?
                 pkmn.makeUndynamaxForm
                 pkmn.makeUndynamax
                 pkmn.calc_stats
               end
            end
            if PluginManager.installed?("Terastal Phenomenon") ||
               PluginManager.installed?("[DBK] Terastallization")
              pkmn.terastallized = false if pkmn&.tera?
            end
          end
        end
      }
    }
    raise exc if exc
    case outcome
    when 1
      $stats.online_battles_wins+=1
    when 2
      $stats.online_battles_lost+=1
    end
  end

  def self.do_trade(index, you, your_pkmn)
    my_pkmn = $player.party[index]
    $player.pokedex.register(your_pkmn)
    $player.pokedex.set_owned(your_pkmn.species)
    pbFadeOutInWithMusic(99999) {
      scene = PokemonTrade_Scene.new
      scene.pbStartScreen(my_pkmn, your_pkmn, $player.name, you.name)
      scene.pbTrade
      scene.pbEndScreen
    }
    $player.party[index] = your_pkmn
    $stats.online_trade_count+=1
  end

  def self.choose_pokemon
    chosen = -1
    pbFadeOutIn(99999) {
      scene = PokemonParty_Scene.new
      screen = PokemonPartyScreen.new(scene, $player.party)
      screen.pbStartScene(_INTL("Choose a Pokémon."), false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    }
    return chosen
  end
  
  def self.choose_team(ruleset)
    team_order = nil
    pbFadeOutIn(99999) {
      scene = PokemonParty_Scene.new
      screen = PokemonPartyScreen.new(scene, $player.party)
      team_order = screen.pbPokemonMultipleEntryScreenOrder(ruleset)
    }
    return team_order
  end
  
  def self.check_pokemon(pkmn)
    pbFadeOutIn(99999) {
      scene = PokemonSummary_Scene.new
      screen = PokemonSummaryScreen.new(scene,true)
      screen.pbStartScreen([pkmn],0)
    }
  end

  def self.write_party(writer)
    writer.int($player.party_count)
    $player.party.each do |pkmn|
      write_pkmn(writer, pkmn)
    end
  end

  def self.write_pkmn(writer, pkmn)
    writer.sym(pkmn.species)
    writer.int(pkmn.level)
    writer.int(pkmn.personalID)
    writer.int(pkmn.owner.id)
    writer.str(pkmn.owner.name)
    writer.int(pkmn.owner.gender)
    writer.int(pkmn.exp)
    writer.int(pkmn.form)
    writer.nil_or(:sym, pkmn.item_id)
    writer.int(pkmn.numMoves)
    pkmn.moves.each do |move|
      writer.sym(move.id)
      writer.int(move.ppup)
      if PluginManager.installed?("PLA Battle Styles")
        writer.nil_or(:bool,move.mastered?)
      end
    end
    writer.int(pkmn.first_moves.length)
    pkmn.first_moves.each do |move|
      writer.sym(move)
    end
    if PluginManager.installed?("PLA Battle Styles")
      writer.int(pkmn.mastered_moves.length)
      pkmn.mastered_moves.each do |move|
        writer.sym(move)
      end
    end
    writer.int(pkmn.gender)
    writer.nil_or(:bool,pkmn.shiny?)
    writer.nil_or(:sym, pkmn.ability_id)
    writer.nil_or(:int, pkmn.ability_index)
    writer.nil_or(:sym, pkmn.nature_id)
    writer.nil_or(:sym, pkmn.nature_for_stats_id)
    GameData::Stat.each_main do |s|
      writer.int(pkmn.iv[s.id])
      writer.nil_or(:bool, pkmn.ivMaxed[s.id])
      writer.int(pkmn.ev[s.id])
    end
    writer.int(pkmn.happiness)
    writer.str(pkmn.name)
    writer.sym(pkmn.poke_ball)
    writer.int(pkmn.steps_to_hatch)
    writer.int(pkmn.pokerus)
    writer.int(pkmn.obtain_method)
    writer.int(pkmn.obtain_map)
    writer.nil_or(:str,pkmn.obtain_text)
    writer.int(pkmn.obtain_level)
    writer.int(pkmn.hatched_map)
    writer.int(pkmn.cool)
    writer.int(pkmn.beauty)
    writer.int(pkmn.cute)
    writer.int(pkmn.smart)
    writer.int(pkmn.tough)
    writer.int(pkmn.sheen)
    writer.int(pkmn.numRibbons)
    pkmn.ribbons.each do |ribbon|
      writer.sym(ribbon)
    end
    if PluginManager.installed?("Essentials Deluxe") ||
       PluginManager.installed?("[MUI] Improved Mementos")
      writer.int(pkmn.scale)
    end
    if PluginManager.installed?("[MUI] Improved Mementos")
      writer.nil_or(:sym,pkmn.memento)
    end
    if PluginManager.installed?("ZUD Mechanics") ||
       PluginManager.installed?("[DBK] Dynamax")
      writer.int(pkmn.dynamax_lvl)
      writer.bool(pkmn.gmax_factor?)
      writer.bool(pkmn.dynamax_able?)
    end
    # already sent PLA Battle Styles data
    if PluginManager.installed?("Terastal Phenomenon") ||
       PluginManager.installed?("[DBK] Terastallization")
      writer.sym(pkmn.tera_type)
    end
    if PluginManager.installed?("Focus Meter System")
      writer.sym(pkmn.focus_id)
    end
    writer.bool(!!pkmn.mail)
    if pkmn.mail
      writer.sym(pkmn.mail.item)
      writer.str(pkmn.mail.message)
      writer.str(pkmn.mail.sender)
      if pkmn.mail.poke1
        #[species,gender,shininess,form,shadowness,is egg]
        writer.sym(pkmn.mail.poke1[0])
        writer.int(pkmn.mail.poke1[1])
        writer.bool(pkmn.mail.poke1[2])
        writer.int(pkmn.mail.poke1[3])
        writer.bool(pkmn.mail.poke1[4])
        writer.bool(pkmn.mail.poke1[5])
      else
        writer.nil_or(:sym,nil)
      end
      if pkmn.mail.poke2
        #[species,gender,shininess,form,shadowness,is egg]
        writer.sym(pkmn.mail.poke2[0])
        writer.int(pkmn.mail.poke2[1])
        writer.bool(pkmn.mail.poke2[2])
        writer.int(pkmn.mail.poke2[3])
        writer.bool(pkmn.mail.poke2[4])
        writer.bool(pkmn.mail.poke2[5])
      else
        writer.nil_or(:sym,nil)
      end
      if pkmn.mail.poke3
        #[species,gender,shininess,form,shadowness,is egg]
        writer.sym(pkmn.mail.poke3[0])
        writer.int(pkmn.mail.poke3[1])
        writer.bool(pkmn.mail.poke3[2])
        writer.int(pkmn.mail.poke3[3])
        writer.bool(pkmn.mail.poke3[4])
        writer.bool(pkmn.mail.poke3[5])
      else
        writer.nil_or(:sym,nil)
      end
    end
    writer.bool(!!pkmn.fused)
    if pkmn.fused
      write_pkmn(writer, pkmn.fused)
    end
  end

  def self.parse_party(record)
    party = []
    record.int.times do
      party << parse_pkmn(record)
    end
    return party
  end

  def self.parse_pkmn(record)
    species = record.sym
    level = record.int
    pkmn = Pokemon.new(species, level, $player)
    pkmn.personalID = record.int
    pkmn.owner.id = record.int
    pkmn.owner.name = record.str
    pkmn.owner.gender = record.int
    pkmn.exp = record.int
    form = record.int
    #pkmn.forced_form = form if MultipleForms.hasFunction?(pkmn.species,"getForm")
    pkmn.form_simple = form
    pkmn.item = record.sym
    pkmn.forget_all_moves
    record.int.times do |i|
      pkmn.moves[i] = Pokemon::Move.new(record.sym)
      pkmn.moves[i].ppup = record.int
      if PluginManager.installed?("PLA Battle Styles")
        pkmn.moves[i].mastered = record.nil_or(:bool)
      end
    end
    pkmn.moves.compact!
    pkmn.clear_first_moves
    record.int.times do |i|
      pkmn.add_first_move(record.sym)
    end
    if PluginManager.installed?("PLA Battle Styles")
      record.int.times do |i|
        pkmn.register_mastered_move(record.sym)
      end
    end
    pkmn.gender = record.int
    pkmn.shiny = record.nil_or(:bool)
    pkmn.ability = record.nil_or(:sym)
    pkmn.ability_index = record.nil_or(:int)
    pkmn.nature = record.sym
    pkmn.nature_for_stats = record.nil_or(:sym)
    GameData::Stat.each_main do |s|
      pkmn.iv[s.id] = record.int
      pkmn.ivMaxed[s.id] = record.nil_or(:bool)
      pkmn.ev[s.id] = record.int
    end
    pkmn.happiness = record.int
    pkmn.name = record.str
    pkmn.poke_ball = record.sym
    pkmn.steps_to_hatch = record.int
    pkmn.pokerus = record.int
    pkmn.obtain_method = record.int
    pkmn.obtain_map = record.int
    pkmn.obtain_text = record.nil_or(:str)
    pkmn.obtain_level = record.int
    pkmn.hatched_map = record.int
    pkmn.cool = record.int
    pkmn.beauty = record.int
    pkmn.cute = record.int
    pkmn.smart = record.int
    pkmn.tough = record.int
    pkmn.sheen = record.int
    record.int.times do |i|
      pkmn.giveRibbon(record.sym)
    end
    if PluginManager.installed?("Essentials Deluxe") || 
       PluginManager.installed?("[MUI] Improved Mementos")
      pkmn.scale = record.int
    end
    if PluginManager.installed?("[MUI] Improved Mementos")
      pkmn.memento = record.nil_or(:sym)
    end
    if PluginManager.installed?("ZUD Mechanics") ||
       PluginManager.installed?("[DBK] Dynamax")
      pkmn.dynamax_lvl = record.int
      pkmn.gmax_factor = record.bool
      pkmn.dynamax_able = record.bool
    end
    # already received PLA Battle Styles data
    if PluginManager.installed?("Terastal Phenomenon") ||
       PluginManager.installed?("[DBK] Terastallization")
      pkmn.tera_type = record.sym
    end
    if PluginManager.installed?("Focus Meter System")
      pkmn.focus_style = record.sym
    end
    if record.bool() # mail
      m_item = record.sym()
      m_msg = record.str()
      m_sender = record.str()
      m_poke1 = []
      if m_species1 = record.nil_or(:sym)
        #[species,gender,shininess,form,shadowness,is egg]
        m_poke1[0] = m_species1
        m_poke1[1] = record.int()
        m_poke1[2] = record.bool()
        m_poke1[3] = record.int()
        m_poke1[4] = record.bool()
        m_poke1[5] = record.bool()
      else
        m_poke1 = nil
      end
      m_poke2 = []
      if m_species2 = record.nil_or(:sym)
        #[species,gender,shininess,form,shadowness,is egg]
        m_poke2[0] = m_species2
        m_poke2[1] = record.int()
        m_poke2[2] = record.bool()
        m_poke2[3] = record.int()
        m_poke2[4] = record.bool()
        m_poke2[5] = record.bool()
      else
        m_poke2 = nil
      end
      m_poke3 = []
      if m_species3 = record.nil_or(:sym)
        #[species,gender,shininess,form,shadowness,is egg]
        m_poke3[0] = m_species3
        m_poke3[1] = record.int()
        m_poke3[2] = record.bool()
        m_poke3[3] = record.int()
        m_poke3[4] = record.bool()
        m_poke3[5] = record.bool()
      else
        m_poke3 = nil
      end
      pkmn.mail = Mail.new(m_item,m_msg,m_sender,m_poke1,m_poke2,m_poke3)
    end
    if record.bool() # fused
      pkmn.fused = parse_pkmn(record)
    end
    pkmn.calc_stats
    return pkmn
  end
  
  def self.parse_battle_rules(record)
    rules = []
    record.int.times do
      rules << parse_battle_rule(record)
    end
    return rules
  end
  
  def self.parse_battle_rule(record)
    name = record.str
    desc = record.str
    rule = PokemonOnlineRules.new
    rule.setTeamPreview(record.int)
    rule.setNumberRange(record.int,record.int)
    # level adjustment
    level_adjustment = record.nil_or(:str)
    if level_adjustment
      level_adjustment_data = level_adjustment.split(";")
      level_adjustmentClass = level_adjustment_data.shift
      level_adjustment_args = process_args_type_hint(*level_adjustment_data)
      if Object.const_defined?(level_adjustmentClass)
        rule.setLevelAdjustment(Kernel.const_get(level_adjustmentClass),*level_adjustment_args)
      end
    end
    # battle rules
    record.int.times do
      clause_data = record.str.split(";")
      clauseClass = clause_data.shift
      clause_args = process_args_type_hint(*clause_data)
      if Object.const_defined?(clauseClass)
        rule.addBattleRule(Kernel.const_get(clauseClass),*clause_args)
      end
    end
    # pokemon rules
    record.int.times do
      clause_data = record.str.split(";")
      clauseClass = clause_data.shift
      clause_args = process_args_type_hint(*clause_data)
      if Object.const_defined?(clauseClass)
        rule.addPokemonRule(Kernel.const_get(clauseClass),*clause_args)
      end
    end
    # subset rules
    record.int.times do
      clause_data = record.str.split(";")
      clauseClass = clause_data.shift
      clause_args = process_args_type_hint(*clause_data)
      if Object.const_defined?(clauseClass)
        rule.addSubsetRule(Kernel.const_get(clauseClass),*clause_args)
      end
    end
    # team rules
    record.int.times do
      clause_data = record.str.split(";")
      clauseClass = clause_data.shift
      clause_args = process_args_type_hint(*clause_data)
      if Object.const_defined?(clauseClass)
        rule.addTeamRule(Kernel.const_get(clauseClass),*clause_args)
      end
    end
    return [name,desc,rule]
  end
  
  def self.write_battle_rule(writer,battle_rule)  
    name,desc,rule = battle_rule
    writer.str(name)
    writer.str(desc)
    writer.int(rule.team_preview)
    writer.int(rule.ruleset.minLength)
    writer.int(rule.ruleset.maxLength)
    if rule.rules_hash[:level_adjust]
      writer.str(rule.rules_hash[:level_adjust].join(";"))
    else
      writer.nil_or(:str,nil)
    end
    writer.int(rule.rules_hash[:battle].length)
    rule.rules_hash[:battle].each do |br|
      writer.str(br.join(";"))
    end
    writer.int(rule.rules_hash[:pokemon].length)
    rule.rules_hash[:pokemon].each do |pr|
      writer.str(pr.join(";"))
    end
    writer.int(rule.rules_hash[:subset].length)
    rule.rules_hash[:subset].each do |sr|
      writer.str(sr.join(";"))
    end
    writer.int(rule.rules_hash[:team].length)
    rule.rules_hash[:team].each do |tr|
      writer.str(tr.join(";"))
    end
  end
  
  def self.get_server_info
    ret = [HOST,PORT]
    if safeExists?("serverinfo.ini")
      File.foreach("serverinfo.ini") do |line|
        case line
        when /^\s*[Hh][Oo][Ss][Tt]\s*=\s*(.+)$/
          ret[0] = $1 if !nil_or_empty?($1)
        when /^\s*[Pp][Oo][Rr][Tt]\s*=\s*(\d{1,5})$/
          if !nil_or_empty?($1)
            port = $1.to_i
            ret[1] = port if port>0 && port<=65535
          end
        end
      end
    end
    return ret
  end
  
    # only handles int, bool, sym, and str
  def self.apply_args_type_hint(*args)
    ret = []
    args.each do |arg|
      case arg
      when Integer; ret.push([:int,arg])
      when TrueClass,FalseClass; ret.push([:bool,arg])
      when String; ret.push([:str,arg])
      when Symbol; ret.push([:sym,arg])
      end
    end
    return ret
  end
  
  # takes a long chain of args, every second element is the original argument
  def self.process_args_type_hint(*args)
    ret = []
    r = nil
    args.each do |arg|
      if r
        case r
        when :int; ret.push(arg.to_i)
        when :bool
          if arg == "true"
            ret.push(true)
          elsif arg == "false"
            ret.push(false)
          else
            raise "expected bool, got #{arg}"
          end
        when :str; ret.push(arg)
        when :sym; ret.push(arg.to_sym)
        end
        r = nil
      else
        r = arg.to_sym
      end
    end
    return ret
  end
end