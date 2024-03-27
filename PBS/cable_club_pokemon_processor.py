import argparse
from collections import defaultdict
import configparser
import os.path
import re
"""
[BULBASAUR]
internal_number = 1
forms = 0
gender_rate=FemaleOneEighth
abilities=OVERGROW,CHLOROPHYLL
moves = TACKLE,GROWL,LEECHSEED, etc...
"""


class EvolutionGraph:
    def __init__(self):
        self._graph = defaultdict(set)
        self._base_mons = set()
    
    def add_evolution(self,prevo,evo):
        self._graph[prevo].add((evo,False))
        self._graph[evo].add((prevo,True))
        self._base_mons.add(prevo)
        if any(e[1] for e in self._graph[prevo]):
            self._base_mons.discard(prevo)
    
    def get_directly_connected_mons(self,base):
        return {e[0] for e in self._graph[base] if not e[1]}
        
    def flatten_families(self,mode):
        families = {}
        if mode == 'shared':
            for base in self._base_mons:
                families[base] = self.depth_first_search(base)
        elif mode == 'propagate':
            for base in self._base_mons:
                families[base] = self.get_directly_connected_mons(base)
            for base in (self._graph.keys()-self._base_mons):
                families[base] = self.get_directly_connected_mons(base)
        families.pop('',None)
        return families
    
    def depth_first_search(self,base):
        seen = set()
        def loop(b):
            if b and b not in seen:
                seen.add(b)
                yield b
                for mon in self._graph[b]:
                    if mon[0] and not mon[1]:
                        yield from loop(mon[0])
        return loop(base)

def organize_evo_families(input_files,forms_files):
    evos=EvolutionGraph()
    pokemon_pbs_ = configparser.ConfigParser()
    pokemon_pbs_.read(input_files,encoding='utf-8-sig')
    for section in pokemon_pbs_.sections():
        species = pokemon_pbs_[section]
        internal_name = section
        if 'InternalName' in species:
            internal_name = species['InternalName']
        if "Evolutions" in species and species['Evolutions']:
            evo_data = species["Evolutions"].split(",")
            for imon in evo_data[0::3]:
                evos.add_evolution(internal_name,imon)
    if forms_files:
        pokemon_pbs_ = configparser.ConfigParser()
        pokemon_pbs_.read(forms_files,encoding='utf-8-sig')
        for section in pokemon_pbs_.sections():
            fspecies = pokemon_pbs_[section]
            skey = section.replace(',', '-').replace(' ', '-')
            internal_name, _, _ = skey.partition('-')
            if "Evolutions" in fspecies and fspecies['Evolutions']:
                evo_data = fspecies["Evolutions"].split(",")
                for imon in evo_data[0::3]:
                    evos.add_evolution(internal_name,imon)
    return evos

def generate_server_pokemon_PBS(mode,input_files,output_file,forms_files,tm_file):
    output_parser = configparser.ConfigParser(default_section=None)
    evo_fams = None
    if mode == 'propagate' or mode == 'shared':
      evo_fams=organize_evo_families(input_files,forms_files)
    pokemon_pbs_ = configparser.ConfigParser()
    pokemon_pbs_.read(input_files,encoding='utf-8-sig')
    for section in pokemon_pbs_.sections():
        species = pokemon_pbs_[section]
        internal_name = section
        internal_num = None
        if 'InternalName' in species:
            internal_name = species['InternalName']
            internal_num = section
        output_parser.add_section(internal_name)
        if internal_num:
            output_parser.set(internal_name,'internal_number',internal_num)
        output_parser.set(internal_name,'forms','0')
        if 'GenderRate' in species:
            output_parser.set(internal_name,'gender_ratio',species['GenderRate'])
        else:
            output_parser.set(internal_name,'gender_ratio',species['GenderRatio'])
        ability_names = []
        if 'Abilities ' in species:
            ability_names |= species['Abilities'].split(',')
        if 'HiddenAbility' in species:
            ability_names.extend(species['HiddenAbility'].split(','))
        elif 'HiddenAbilities' in species:
            ability_names.extend(species['HiddenAbilities'].split(','))
        abilities = {a for a in ability_names if a}
        output_parser.set(internal_name,'abilities',",".join(abilities))
        moves = set()
        if 'Moves' in species:
            moves |= {m for m in species['Moves'].split(',')[1::2] if m}
        if 'EggMoves' in species:
            moves |= {m for m in species['EggMoves'].split(',') if m}
        if 'TutorMoves' in species:
            moves |= {m for m in species['TutorMoves'].split(',') if m}
        output_parser.set(internal_name,'moves',",".join(moves))
    if forms_files:
        pokemon_pbs_ = configparser.ConfigParser()
        pokemon_pbs_.read(forms_files,encoding='utf-8-sig')
        for section in pokemon_pbs_.sections():
            fspecies = pokemon_pbs_[section]
            skey = section.replace(',', '-').replace(' ', '-')
            internal_name, _, f_num = skey.partition('-')
            form_nums = output_parser[internal_name]['forms'].split(',')
            form_nums.append(f_num)
            output_parser.set(internal_name,'forms',','.join(form_nums))
            ability_names = []
            if 'Abilities ' in fspecies:
                ability_names |= fspecies['Abilities'].split(',')
            if 'HiddenAbility' in fspecies:
                ability_names.extend(fspecies['HiddenAbility'].split(','))
            elif 'HiddenAbilities' in fspecies:
                ability_names.extend(fspecies['HiddenAbilities'].split(','))
            abilities = {a for a in ability_names if a}
            abilities.update(output_parser[internal_name]['abilities'].split(','))
            output_parser.set(internal_name,'abilities',",".join(abilities))
            moves = set()
            if 'Moves' in fspecies:
                moves |= {m for m in fspecies['Moves'].split(',')[1::2] if m}
            if 'EggMoves' in fspecies:
                moves |= {m for m in fspecies['EggMoves'].split(',') if m}
            if 'TutorMoves' in fspecies:
                moves |= {m for m in fspecies['TutorMoves'].split(',') if m}
            moves.update(output_parser[internal_name]['moves'].split(','))
            output_parser.set(internal_name,'moves',",".join(moves))
    if tm_file:
        with open(tm_file, 'r',encoding='utf-8-sig') as tm_pbs:
            move = None
            for line in tm_pbs:
                line = line.strip()
                match = re.match(r'\[([A-Z]+)\]', line)
                if line.startswith('#'):
                    continue
                elif match:
                    move = match.group(1)
                else:
                    for name in line.split(','):
                        if name:
                            # TODO: Cheating here to get it to run
                            internal_name=name.partition('_')[0]
                            moves = set(output_parser[internal_name]['moves'].split(','))
                            moves.add(move)
                            output_parser.set(internal_name,'moves',",".join(moves))
                            
    if evo_fams:
        for base,family in evo_fams.flatten_families(mode).items():
            fam = set(family)
            if mode == 'propagate':
                fam.discard(base)
                moves = set(output_parser[base]['moves'].split(','))
            if mode == 'shared':
                moves=set(output_parser[base]['moves'].split(','))
                for mon in fam:
                    moves.update(output_parser[mon]['moves'].split(','))
            output_parser.set(base,'moves',",".join(moves))
            for mon in fam:
                t_moves = set(output_parser[mon]['moves'].split(','))
                t_moves.update(moves)
                output_parser.set(mon,'moves',",".join(t_moves))
    with open(output_file, 'w') as configfile:
        output_parser.write(configfile)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='A preprocessor that converts game PBS files into a format acceptable for Cable Club\'s Server.')
    parser.add_argument('--mode', choices=['simple','propagate','shared'],default='simple',help='The method used in processing the PBS file. simple is a direct conversion, propagate copies movesets down an evolution chain, shared gives the same moveset to all members of an evolutionary family.')
    parser.add_argument('-o','--output_file', default='server_pokemon.txt',help='The output name of the file. Cable Club expects a pokemon_server.txt file.')
    parser.add_argument('-pf','--forms_files',nargs='+', help='If provided, will combine the data from the forms files into the base form data.')
    parser.add_argument('-tm','--tm_file',nargs=1, help='If provided, will combine the moves data with the main pokemon.txt PBS file')
    parser.add_argument('input_files',nargs='+',help='The pokemon.txt files to convert.')
    args = parser.parse_args()
    generate_server_pokemon_PBS(args.mode,args.input_files,args.output_file,args.forms_files,args.tm_file)
    
    