class_name PBETurnAction

var PokemonId : int#byte
var Decision : PBEEnums.PBETurnDecision
var FightMove : PBEEnums.PBEMove
var FightTargets : PBEEnums.PBETurnTarget #{ get; internal set; } # Internal set because of PBEMoveTarget.RandomFoeSurrounding (TODO: Shouldn't this happen at runtime?)
var UseItem : PBEEnums.PBEItem
var SwitchPokemonId : int#byte
#
#internal PBETurnAction(EndianBinaryReader r)
#{
	#PokemonId = r.ReadByte();
	#Decision = r.ReadEnum<PBETurnDecision>();
	#switch (Decision)
	#{
		#case PBETurnDecision.Fight:
		#{
			#FightMove = r.ReadEnum<PBEMove>();
			#FightTargets = r.ReadEnum<PBETurnTarget>();
			#break;
		#}
		#case PBETurnDecision.Item:
		#{
			#UseItem = r.ReadEnum<PBEItem>();
			#break;
		#}
		#case PBETurnDecision.SwitchOut:
		#{
			#SwitchPokemonId = r.ReadByte();
			#break;
		#}
		#case PBETurnDecision.WildFlee: break;
		#default: throw new InvalidDataException(nameof(Decision));
	#}
#}

static func Fight(pokemon, fightMove : PBEEnums.PBEMove, fightTargets : PBEEnums.PBETurnTarget) -> PBETurnAction:
	var action = PBETurnAction.new()
	if pokemon is PBEBattlePokemon:
		pokemon = pokemon.Id
	
	action.PokemonId = pokemon;
	action.DecisionId = PBEEnums.PBETurnDecision.Fight;
	action.FightMove = fightMove;
	action.FightTargets = fightTargets;
	return action


## Fight
#public PBETurnAction()
	#: this(pokemon.Id, fightMove, fightTargets) { }
#public PBETurnAction(byte pokemonId, PBEMove fightMove, PBETurnTarget fightTargets)
#{
	#PokemonId = pokemonId;
	#Decision = PBETurnDecision.Fight;
	#FightMove = fightMove;
	#FightTargets = fightTargets;
#}

static func Item(pokemon, item : PBEEnums.PBEItem) -> PBETurnAction:
	var action = PBETurnAction.new()
	if pokemon is PBEBattlePokemon:
		pokemon = pokemon.Id
	
	action.PokemonId = pokemon;
	action.DecisionId = PBEEnums.PBETurnDecision.Item;
	action.UseItem = item;
	return action

# Item
#public PBETurnAction(PBEBattlePokemon pokemon, PBEItem item)
	#: this(pokemon.Id, item) { }
#public PBETurnAction(byte pokemonId, PBEItem item)
#{
	#PokemonId = pokemonId;
	#Decision = PBETurnDecision.Item;
	#UseItem = item;
#}

static func Switch(pokemon, switchPokemon) -> PBETurnAction:
	var action = PBETurnAction.new()
	if pokemon is PBEBattlePokemon:
		pokemon = pokemon.Id
	if switchPokemon is PBEBattlePokemon:
		switchPokemon = switchPokemon.Id
	
	action.PokemonId = pokemon;
	action.Decision = PBEEnums.PBETurnDecision.SwitchOut;
	action.SwitchPokemonId = switchPokemon;
	return action
#
## Switch
#public PBETurnAction(PBEBattlePokemon pokemon, PBEBattlePokemon switchPokemon)
	#: this(pokemon.Id, switchPokemon.Id) { }
#public PBETurnAction(byte pokemonId, byte switchPokemonId)
#{
	#PokemonId = pokemonId;
	#Decision = PBETurnDecision.SwitchOut;
	#SwitchPokemonId = switchPokemonId;
#}

static func Flee(pokemon) -> PBETurnAction:
	var action = PBETurnAction.new()
	if pokemon is PBEBattlePokemon:
		pokemon = pokemon.Id
	
	PokemonId = pokemonId;
	Decision = PBETurnDecision.WildFlee;
	return action
#
## Internal wild flee
#internal PBETurnAction(PBEBattlePokemon pokemon)
	#: this(pokemon.Id) { }
#internal PBETurnAction(byte pokemonId)
#{
	#PokemonId = pokemonId;
	#Decision = PBETurnDecision.WildFlee;
#}
#
#internal void ToBytes(EndianBinaryWriter w)
#{
	#w.WriteByte(PokemonId);
	#w.WriteEnum(Decision);
	#switch (Decision)
	#{
		#case PBETurnDecision.Fight:
		#{
			#w.WriteEnum(FightMove);
			#w.WriteEnum(FightTargets);
			#break;
		#}
		#case PBETurnDecision.Item:
		#{
			#w.WriteEnum(UseItem);
			#break;
		#}
		#case PBETurnDecision.SwitchOut:
		#{
			#w.WriteByte(SwitchPokemonId);
			#break;
		#}
		#case PBETurnDecision.WildFlee: break;
		#default: throw new InvalidDataException(nameof(Decision));
	#}
#}
#}

class PBESwitchIn:
	var PokemonId : int
	var Position : PBEEnums.PBEFieldPosition 
	
	func _init(pokemon, position:PBEEnums.PBEFieldPosition ):
		if pokemon is PBEBattlePokemon:
			pokemon = pokemon.Id
			
		PokemonId = pokemon;
		Position = position;
