class PBETeams: #: IReadOnlyList<PBETeam>
	var _team0 : PBETeam
	var _team1 : PBETeam 
	
	var Count := 2
	
	func _init(battle:PBEBattle, ti0:IReadOnlyList_PBETrainerInfo, ti1:IReadOnlyList_PBETrainerInfo):
		var allTrainers = [];


## <summary>Represents a team in a specific <see cref="PBEBattle"/>.</summary>
class PBETeam:
	## <summary>The battle this team and its party belongs to.</summary>
	var Battle : PBEBattle
	var OpposingTeam : PBETeam
	var Trainers # ReadOnlyCollection<PBETrainer> 
	var Id : int
	var IsWild : bool #=> Battle.BattleType == PBEBattleType.Wild && Id == 1;

	var CombinedName : String
	var CombinedParty  #public IEnumerable<PBEBattlePokemon>  => Trainers.SelectMany(t => t.Party);
	var ActiveBattlers  #public List<PBEBattlePokemon>  => Battle.ActiveBattlers.FindAll(p => p.Team == this);
	var NumConsciousPkmn : int #=> Trainers.Sum(t => t.NumConsciousPkmn);
	var NumPkmnOnField : int #=> Trainers.Sum(t => t.NumPkmnOnField);

	var NumTimesTriedToFlee : int
	var TeamStatus : PBEEnums.PBETeamStatus
	var LightScreenCount : int
	var LuckyChantCount : int
	var ReflectCount : int
	var SafeguardCount : int
	var SpikeCount : int
	var TailwindCount : int
	var ToxicSpikeCount : int
	var MonFaintedLastTurn : bool
	var MonFaintedThisTurn : bool

	# Trainer battle
	func _init(battle:PBEBattle, id:int, ti:IReadOnlyList_PBETrainerInfo, allTrainers:List_PBETrainer):
		var count : int = ti.Count;
		if (!VerifyTrainerCount(battle.BattleFormat, count)):
			print("lolxd")#throw new ArgumentException($"Illegal trainer count (Format: {battle.BattleFormat}, Team: {id}, Count: {count}");
		for t in ti:
			if (!t.IsOkayForSettings(battle.Settings)):
				print("lolxd")#throw new ArgumentOutOfRangeException(nameof(ti), "Team settings do not comply with battle settings.");
		Battle = battle;
		Id = id;
		var trainers = PBETrainer.new()#[ti.Count];
		for i in range(0, ti.Count, 1):
			trainers[i] = PBETrainer.new(this, ti[i], allTrainers);
		#Trainers = new ReadOnlyCollection<PBETrainer>(trainers);
		CombinedName = GetCombinedName();
		OpposingTeam = null; # OpposingTeam is set in PBETeams after both are created

	static func VerifyWildCount(format:PBEBattleFormat , count:int ) -> bool:
		match (format):
			PBEBattleFormat.Single: 
				return count == 1;
			PBEBattleFormat.Double: 
				return count >= 1 && count <= 2;
			PBEBattleFormat.Rotation, PBEBattleFormat.Triple: 
				return count >= 1 && count <= 3;
			_: print("lolxd")#throw new ArgumentOutOfRangeException(nameof(format));
	
	
	static func VerifyTrainerCount(format:PBEBattleFormat, count:int ) -> bool:
		match (format):
			PBEBattleFormat.Single, PBEBattleFormat.Rotation: 
				return count == 1;
			PBEBattleFormat.Double: 
				return count == 1 || count == 2;
			PBEBattleFormat.Triple: 
				return count == 1 || count == 3;
			_: print("lolxd")#throw new ArgumentOutOfRangeException(nameof(format));
	
	
	func GetCombinedName() -> String:
		var names : Array[String] = []; names.resize(Trainers.Count)# new string[Trainers.Count];
		for i in range(0, names.Length, 1):
			names[i] = Trainers[i].Name;
		return names.Andify();
	
	
	func IsSpotOccupied(pos:PBEFieldPosition) -> bool:
		for p in ActiveBattlers:
			if (p.FieldPosition == pos):
				return true;
		return false;
	
	
	func TryGetPokemon(pos:PBEFieldPosition, pkmn:PBEBattlePokemon) -> bool:
		for p in ActiveBattlers:
			if (p.FieldPosition == pos):
				pkmn = p;
				return true;
		pkmn = null;
		return false;
	
	
	func TryAddPokemonToCollection(pos:PBEFieldPosition, list) -> void :
		if (TryGetPokemon(pos, pkmn)):
			list.Add(pkmn);


	func _to_string() -> String:
		var sb := ""
		sb = str(sb, "Team ", id, ":\n")
		sb = str(sb, "TeamStatus:  ", TeamStatus, "\n")
		#sb.AppendLine($"NumPkmn: {Party.Length}");
		sb = str(sb, "NumConsciousPkmn: ", NumConsciousPkmn, "\n")
		sb = str(sb, "NumPkmnOnField: ", NumPkmnOnField, "\n")
		return sb
