## <summary>Represents a specific Pokémon battle.</summary>
class_name PBEBattle

signal state_changed(battle:PBEBattle)
var _battleState : PBEBattleState;
var BattleState : PBEBattleState :
	get: return _battleState
	set(value):
		if (value != _battleState):
			_battleState = value;
			state_changed.emit(this);
var TurnNumber : int
var BattleResult : PBEBattleResult

var _rand : RandomNumberGenerator
var IsLocallyHosted : bool 
var BattleType : PBEBattleEnums.PBEBattleType 
var BattleTerrain : PBEBattleEnums.PBEBattleTerrain 
var BattleFormat : PBEBattleFormat 
var Settings : PBESettings 
var Teams : PBETeams 
var Trainers : PBETrainers 
var ActiveBattlers := [] # List<PBEBattlePokemon>  ... { get; } = new(6);
var _turnOrder = [] # readonly List<PBEBattlePokemon>

var Weather : PBEWeather 
var WeatherCounter : byte 
var BattleStatus : PBEBattleStatus 
var TrickRoomCount : int

var Events := [] #{ get; } = new();

# Trainer battle
func _init(battle_type:BattleType, battleFormat:PBEBattleFormat, settings:PBESettings, ti0:Array[PBETrainerInfo], ti1:Array[PBETrainerInfo],
	battleTerrain:PBEBattleTerrain, weather:PBEWeather, randomSeed:int):
	if (battleFormat >= PBEBattleFormat.MAX):
		push_error("ArgumentOutOfRangeException", nameof(battleFormat))
	if (battleTerrain >= PBEBattleTerrain.MAX):
		push_error("ArgumentOutOfRangeException", nameof(battleTerrain))
	if (weather >= PBEWeather.MAX):
		push_error("ArgumentOutOfRangeException", nameof(weather))

	settings.ShouldBeReadOnly(nameof(settings));
	_rand = RandomNumberGenerator.new()
	_rand.seed = randomSeed if randomSeed != null else PBEDataProvider.GlobalRandom.RandomInt()
	IsLocallyHosted = true;
	BattleType = battle_type#PBEBattleType.Trainer;
	BattleTerrain = battleTerrain;
	BattleFormat = battleFormat;
	Settings = settings;
	Weather = weather;
	Teams = PBETeams.new(self, ti0, ti1, trainers);
	Trainers = trainers;
	_turnOrder = [] #new List<PBEBattlePokemon>(6);
	_QueueUpPokemon();

## Remote battle
#func _init_from_packet(packet:PBEBattlePacket) -> PBEBattle:
	#var battle = PBEBattle.new( packet.BattleType, packet.BattleFormat, packet.Settings, ?, 
			#?, packet.BattleTerrain, packet.Weather )
	#battle.IsLocallyHosted = false;
#
	#battle.Teams = new PBETeams(this, packet, out PBETrainers trainers);
	#battle.Trainers = trainers;
	## These two will never be used in a non-local battle
	#battle._rand = null!;
	#battle._turnOrder = null!;


#func static PBEBattle CreateTrainerBattle(PBEBattleFormat battleFormat, PBESettings settings, PBETrainerInfo ti0, PBETrainerInfo ti1,
	#PBEBattleTerrain battleTerrain = PBEBattleTerrain.Plain, PBEWeather weather = PBEWeather.None, int? randomSeed = null)
#{
	#return new PBEBattle(battleFormat, settings, new[] { ti0 }, new[] { ti1 }, battleTerrain, weather, randomSeed);
#}
#func static PBEBattle CreateTrainerBattle(PBEBattleFormat battleFormat, PBESettings settings, IReadOnlyList<PBETrainerInfo> ti0, IReadOnlyList<PBETrainerInfo> ti1,
	#PBEBattleTerrain battleTerrain = PBEBattleTerrain.Plain, PBEWeather weather = PBEWeather.None, int? randomSeed = null)
#{
	#return new PBEBattle(battleFormat, settings, ti0, ti1, battleTerrain, weather, randomSeed);
#}
#func static PBEBattle CreateWildBattle(PBEBattleFormat battleFormat, PBESettings settings, PBETrainerInfo ti0, PBEWildInfo wi,
	#PBEBattleTerrain battleTerrain = PBEBattleTerrain.Plain, PBEWeather weather = PBEWeather.None, int? randomSeed = null)
#{
	#return new PBEBattle(battleFormat, settings, new[] { ti0 }, wi, battleTerrain, weather, randomSeed);
#}
#func static PBEBattle CreateWildBattle(PBEBattleFormat battleFormat, PBESettings settings, IReadOnlyList<PBETrainerInfo> ti0, PBEWildInfo wi,
	#PBEBattleTerrain battleTerrain = PBEBattleTerrain.Plain, PBEWeather weather = PBEWeather.None, int? randomSeed = null)
#{
	#return new PBEBattle(battleFormat, settings, ti0, wi, battleTerrain, weather, randomSeed);
#}
#func static PBEBattle CreateRemoteBattle(PBEBattlePacket packet)
#{
	#return new PBEBattle(packet);
#}

func QueueUp(team : PBETeam, pos : PBEFieldPosition, trainer : PBETrainer, index : int ) -> int:
	trainer = _queue_up_correct_trainer(pos, trainer)
	var party : Array[PBEBattlePokemon] = trainer.Party;
	return _queue_up_tryget(trainer, index, party)


func _queue_up_correct_trainer(pos : PBEFieldPosition, trainer : PBETrainer) -> PBETrainer:
	# See which trainer owns this spot
	var pos_trainer : PBETrainer = team.GetTrainer(pos);
	# If it's not the previous trainer, we start at their first PKMN
	if (trainer != pos_trainer):
		index = 0;
		trainer = pos_trainer;


func _queue_up_tryget(trainer, index, party) -> int:
	# If the check index is valid, try to send out a non-fainted non-ignore PKMN
	if (index < party.size()):
		var mon : PBEBattlePokemon = party[index]
		# If we should ignore this PKMN, try to get the one in the next index
		if (!mon.CanBattle):
			index += 1
			return _queue_up_tryget(trainer, index, party)
		# Valid PKMN, send it out
		mon.Trainer.SwitchInQueue.Add(mon, pos)
		# Wild PKMN should be out already
		if (team.IsWild):
			mon.FieldPosition = pos;
			ActiveBattlers.Add(mon);
		# Next slot to check
		index += 1
	return index


func _QueueUpPokemon():
	match (BattleFormat):
		PBEBattleFormat.Single:
			for team in Teams:
				var t : PBETrainer = null;
				var i = 0
				QueueUp(team, PBEBattleEnums.PBEFieldPosition.Center, t, i);
		
		PBEBattleFormat.Double:
			
			for team in Teams:
				var t : PBETrainer = null;
				var i = 0
				i = QueueUp(team, PBEFieldPosition.Left, t, i);
				i = QueueUp(team, PBEFieldPosition.Right, t, i);
		
		PBEBattleFormat.Triple:
			for team in Teams:
				var t : PBETrainer = null;
				var i = 0
				i = QueueUp(team, PBEFieldPosition.Left, t, i);
				i = QueueUp(team, PBEFieldPosition.Center, t, i);
				i = QueueUp(team, PBEFieldPosition.Right, t, i);
		
		PBEBattleFormat.Rotation:
			for team in Teams:
				var t : PBETrainer = null;
				var i = 0
				i = QueueUp(team, PBEFieldPosition.Center, t, i);
				i = QueueUp(team, PBEFieldPosition.Left, t, i);
				i = QueueUp(team, PBEFieldPosition.Right, t, i);
		_: 
			push_error("ArgumentOutOfRangeException", nameof(BattleFormat) )
		
	BattleState = PBEBattleState.ReadyToBegin;


func CheckLocal():
	if (!IsLocallyHosted):
		push_error("InvalidOperationException: This battle is not locally hosted")


## <summary>Begins the battle.</summary>
## <exception cref="InvalidOperationException">Thrown when <see cref="BattleState"/> is not <see cref="PBEBattleState.ReadyToBegin"/>.</exception>
func Begin():
	CheckLocal();
	if (_battleState != PBEBattleState.ReadyToBegin):
		push_error("InvalidOperationException ",nameof(BattleState)," must be ",PBEBattleState.ReadyToBegin," to begin the battle.");
	
	BattleState = PBEBattleState.Processing;
	BroadcastBattle(); # The first packet sent is PBEBattlePacket which replays rely on
					   # Wild Pokémon appearing
	if (BattleType == PBEBattleType.Wild):
		var team : PBETeam = Teams[1];
		var trainer : PBETrainer = team.Trainers[0];
		var count : int = trainer.SwitchInQueue.Count;
		var appearances : Array[PBEPkmnAppearedInfo] = []
		
		for i in range (0, count, 1):
			appearances[i] = PBEPkmnAppearedInfo.new(trainer.SwitchInQueue[i].Pkmn);
		
		trainer.SwitchInQueue.Clear();
		BroadcastWildPkmnAppeared(appearances);
	
	SwitchesOrActions();

## <summary>Runs a turn.</summary>
## <exception cref="InvalidOperationException">Thrown when <see cref="BattleState"/> is not <see cref="PBEBattleState.ReadyToRunTurn"/>.</exception>
func RunTurn():
	CheckLocal()
	if (_battleState != PBEBattleState.ReadyToRunTurn):
		pass#throw new InvalidOperationException($"{nameof(BattleState)} must be {PBEBattleState.ReadyToRunTurn} to run a turn.");
	BattleState = PBEBattleState.Processing;
	FleeCheck();
	if EndCheck():
		return;
	DetermineTurnOrder();
	RunActionsInOrder();
	TurnEnded();


func RunSwitches():
	CheckLocal();
	if (_battleState != PBEBattleState.ReadyToRunSwitches):
		pass#throw new InvalidOperationException($"{nameof(BattleState)} must be {PBEBattleState.ReadyToRunSwitches} to run switches.");
	BattleState = PBEBattleState.Processing;
	FleeCheck();
	if (EndCheck()):
		return;
	SwitchesOrActions();

## <summary>Sets <see cref="BattleState"/> to <see cref="PBEBattleState.Ended"/> and clears <see cref="OnNewEvent"/> and <see cref="OnStateChanged"/>. Does not touch <see cref="BattleResult"/>.</summary>
func SetEnded():
	if (_battleState != PBEBattleState.Ended):
		BattleState = PBEBattleState.Ended;
		OnNewEvent = null;
		OnStateChanged = null;


func EndCheck() -> bool:
	if (BattleResult != null):
		BroadcastBattleResult(BattleResult.Value);
		for pkmn in ActiveBattlers:
			pkmn.ApplyNaturalCure(); # Natural Cure happens at the end of the battle. Pokémon should be copied when BattleState is set to "Ended", not upon battle result.
		SetEnded();
		return true;
	return false;


func SwitchesOrActions():
	# Checking SwitchInQueue count since SwitchInsRequired is set to 0 after submitting switches
	var trainersWithSwitchIns : Array[PBETrainer] #= Trainers.Where(t => t.SwitchInQueue.Count > 0).ToArray();
	if (trainersWithSwitchIns.Length > 0):
		var list : Array[PBEBattlePokemon];
		for trainer in trainersWithSwitchIns:
			var count : int = trainer.SwitchInQueue.Count;
			var switches : Array[PBEPkmnAppearedInfo] #[count];
			switches.resize(count)
			
			for i in range(0, count, 1):
				#(PBEBattlePokemon pkmn, PBEFieldPosition pos) = trainer.SwitchInQueue[i];
				## ^ This involves multiple return, and I can't find the function it calls?
				pkmn.FieldPosition = pos;
				switches[i] = CreateSwitchInInfo(pkmn);
				PBETrainer.SwitchTwoPokemon(pkmn, pos); # Swap after Illusion
				ActiveBattlers.Add(pkmn); # Add before broadcast
				list.Add(pkmn);
			BroadcastPkmnSwitchIn(trainer, switches);
		DoSwitchInEffects(list);
	
	for trainer in Trainers:
		var available : int = trainer.NumConsciousPkmn - trainer.NumPkmnOnField;
		trainer.SwitchInsRequired = 0;
		trainer.SwitchInQueue.Clear();
		if (available > 0):
			match (BattleFormat):
				PBEBattleFormat.Single:
					if (!trainer.IsSpotOccupied(PBEFieldPosition.Center)):
						trainer.SwitchInsRequired = 1;
				PBEBattleFormat.Double:
					if (trainer.OwnsSpot(PBEFieldPosition.Left) && !trainer.IsSpotOccupied(PBEFieldPosition.Left)):
						available -= 1
						trainer.SwitchInsRequired += 1
					if (available > 0 && trainer.OwnsSpot(PBEFieldPosition.Right) && !trainer.IsSpotOccupied(PBEFieldPosition.Right)):
						trainer.SwitchInsRequired += 1
				PBEBattleFormat.Rotation, \
				PBEBattleFormat.Triple:
					if (trainer.OwnsSpot(PBEFieldPosition.Left) && !trainer.IsSpotOccupied(PBEFieldPosition.Left)):
						available -= 1
						trainer.SwitchInsRequired += 1
					if (available > 0 && trainer.OwnsSpot(PBEFieldPosition.Center) && !trainer.IsSpotOccupied(PBEFieldPosition.Center)):
						available -= 1
						trainer.SwitchInsRequired += 1
					if (available > 0 && trainer.OwnsSpot(PBEFieldPosition.Right) && !trainer.IsSpotOccupied(PBEFieldPosition.Right)):
						trainer.SwitchInsRequired += 1
				_: 
					pass#throw new ArgumentOutOfRangeException(nameof(BattleFormat));

	#trainersWithSwitchIns = Trainers.Where(t => t.SwitchInsRequired > 0).ToArray();
	if (trainersWithSwitchIns.Length > 0):
		BattleState = PBEBattleState.WaitingForSwitchIns;
		for trainer in trainersWithSwitchIns:
			BroadcastSwitchInRequest(trainer);
	else:
		if EndCheck():
			return;

		for pkmn in ActiveBattlers:
			pkmn.HasUsedMoveThisTurn = false;
			pkmn.TurnAction = null;
			pkmn.SpeedBoost_AbleToSpeedBoostThisTurn = pkmn.Ability == PBEAbility.SpeedBoost;

			if (pkmn.Status2.HasFlag(PBEStatus2.Flinching)):
				BroadcastStatus2(pkmn, pkmn, PBEStatus2.Flinching, PBEStatusAction.Ended);
			if (pkmn.Status2.HasFlag(PBEStatus2.HelpingHand)):
				BroadcastStatus2(pkmn, pkmn, PBEStatus2.HelpingHand, PBEStatusAction.Ended);
			if (pkmn.Status2.HasFlag(PBEStatus2.LockOn)):
				if (--pkmn.LockOnTurns == 0):
					pkmn.LockOnPokemon = null;
					BroadcastStatus2(pkmn, pkmn, PBEStatus2.LockOn, PBEStatusAction.Ended);
			if (pkmn.Protection_Used):
				pkmn.Protection_Counter += 1
				pkmn.Protection_Used = false;
				if (pkmn.Status2.HasFlag(PBEStatus2.Protected)):
					BroadcastStatus2(pkmn, pkmn, PBEStatus2.Protected, PBEStatusAction.Ended);
			else:
				pkmn.Protection_Counter = 0;
			if (pkmn.Status2.HasFlag(PBEStatus2.Roost)):
				pkmn.EndRoost();
				BroadcastStatus2(pkmn, pkmn, PBEStatus2.Roost, PBEStatusAction.Ended);
		for team in Teams:
			if (team.TeamStatus.HasFlag(PBETeamStatus.QuickGuard)):
				BroadcastTeamStatus(team, PBETeamStatus.QuickGuard, PBETeamStatusAction.Ended);
			if (team.TeamStatus.HasFlag(PBETeamStatus.WideGuard)):
				BroadcastTeamStatus(team, PBETeamStatus.WideGuard, PBETeamStatusAction.Ended);
		for trainer in Trainers:
			trainer.ActionsRequired.Clear();
			trainer.ActionsRequired.AddRange(trainer.ActiveBattlersOrdered);

		# #318 - We check pkmn on the field instead of conscious pkmn because of multi-battles
		# It still works if there's only one trainer on the team since we check for available switch-ins above
		if (BattleFormat == PBEBattleFormat.Triple): #&& Teams.All(t => t.NumPkmnOnField == 1))
			var pkmn0 = ActiveBattlers[0]
			var pkmn1 = ActiveBattlers[1]
			if ((pkmn0.FieldPosition == PBEFieldPosition.Left && pkmn1.FieldPosition == PBEFieldPosition.Left) || (pkmn0.FieldPosition == PBEFieldPosition.Right && pkmn1.FieldPosition == PBEFieldPosition.Right)):
				var pkmn0OldPos = pkmn0.FieldPosition
				var pkmn1OldPos = pkmn1.FieldPosition;
				pkmn0.FieldPosition = PBEFieldPosition.Center;
				pkmn1.FieldPosition = PBEFieldPosition.Center;
				BroadcastAutoCenter(pkmn0, pkmn0OldPos, pkmn1, pkmn1OldPos);
		
		TurnNumber += 1
		BroadcastTurnBegan();
		for team in Teams:
			var old : bool = team.MonFaintedThisTurn; # Fire events in a specific order
			team.MonFaintedThisTurn = false;
			team.MonFaintedLastTurn = old;
		BattleState = PBEBattleState.WaitingForActions;
		#foreach (PBETrainer trainer in Trainers.Where(t => t.NumConsciousPkmn > 0))
			#BroadcastActionsRequest(trainer);


func GetActingOrder(pokemon, ignoreItemsThatActivate:bool): #  IEnumerable<PBEBattlePokemon> 
	var evaluated = [] #new List<(PBEBattlePokemon Pokemon, float Speed)>(); # TODO: Full Incense, Lagging Tail, Stall, Quick Claw
	for pkmn in pokemon:
		
		var speed : float = pkmn.Speed * GetStatChangeModifier(pkmn.SpeedChange, false);

		match (pkmn.Item):
			PBEItem.ChoiceScarf:
				speed *= 1.5
			PBEItem.MachoBrace, \
			PBEItem.PowerAnklet, \
			PBEItem.PowerBand, \
			PBEItem.PowerBelt, \
			PBEItem.PowerBracer, \
			PBEItem.PowerLens, \
			PBEItem.PowerWeight:
				speed *= 0.5
			PBEItem.QuickPowder:
				if (pkmn.OriginalSpecies == PBESpecies.Ditto && !pkmn.Status2.HasFlag(PBEStatus2.Transformed)):
					speed *= 2.0
		if (ShouldDoWeatherEffects()):
			if (Weather == PBEWeather.HarshSunlight && pkmn.Ability == PBEAbility.Chlorophyll):
				speed *= 2.0
			elif (Weather == PBEWeather.Rain && pkmn.Ability == PBEAbility.SwiftSwim):
				speed *= 2.0
			elif (Weather == PBEWeather.Sandstorm && pkmn.Ability == PBEAbility.SandRush):
				speed *= 2.0
		match (pkmn.Ability):
			PBEAbility.QuickFeet:
				if (pkmn.Status1 != PBEStatus1.None):
					speed *= 1.5
			PBEAbility.SlowStart:
				if (pkmn.SlowStart_HinderTurnsLeft > 0):
					speed *= 0.5
		
		if (pkmn.Ability != PBEAbility.QuickFeet && pkmn.Status1 == PBEStatus1.Paralyzed):
			speed *= 0.25
		if (pkmn.Team.TeamStatus.HasFlag(PBETeamStatus.Tailwind)):
			speed *= 2.0
		#(PBEBattlePokemon Pokemon, float Speed) tup = (pkmn, speed)
		if (evaluated.Count == 0):
			evaluated.Add( [pkmn, speed] )
		else:
			#int pkmnTiedWith = evaluated.FindIndex(t => t.Speed == speed)
			var pkmnTiedWith = evaluated.filter(func(tuple): return tuple[1]).find(speed)
			if (pkmnTiedWith != -1): # Speed tie - randomly go before or after the Pokémon it tied with
				if (_rand.randi_range(0,1) == 1):
					if (pkmnTiedWith == evaluated.Count - 1):
						evaluated.Add( [pkmn, speed] )
					else:
						evaluated.Insert(pkmnTiedWith + 1, [pkmn, speed])
				else:
					evaluated.Insert(pkmnTiedWith, [pkmn, speed])
			else:
				var pkmnToGoBefore : int #= evaluated.FindIndex(t => BattleStatus.HasFlag(PBEBattleStatus.TrickRoom) ? t.Speed > speed : t.Speed < speed);
				if (pkmnToGoBefore == -1):
					evaluated.Add([pkmn, speed])
				else:
					evaluated.Insert(pkmnToGoBefore, tup)
	return evaluated.filter(func(tuple): return tuple[0])


func GetMovePrio(p:PBEBattlePokemon) -> int:
	var mData : IPBEMoveData = PBEDataProvider.Instance.GetMoveData(p.TurnAction.FightMove);
	var priority : int = mData.Priority;
	if (p.Ability == PBEAbility.Prankster && mData.Category == PBEMoveCategory.Status):
		priority += 1
	return priority;


func DetermineTurnOrder() -> void:
	_turnOrder.Clear();
	#const int PursuitPriority = +7;
	const SwitchRotatePriority = +6;
	const WildFleePriority = -7;
	var pkmnUsingItem # : List<PBEBattlePokemon> = ActiveBattlers.FindAll(p => p.TurnAction?.Decision == PBETurnDecision.Item);
	var pkmnSwitchingOut # : List<PBEBattlePokemon> = ActiveBattlers.FindAll(p => p.TurnAction?.Decision == PBETurnDecision.SwitchOut);
	var pkmnFighting # : List<PBEBattlePokemon> = ActiveBattlers.FindAll(p => p.TurnAction?.Decision == PBETurnDecision.Fight);
	var wildFleeing # : List<PBEBattlePokemon> = ActiveBattlers.FindAll(p => p.TurnAction?.Decision == PBETurnDecision.WildFlee);
	# Item use happens first:
	_turnOrder.AddRange(GetActingOrder(pkmnUsingItem, true));
	# Get move/switch/rotate/wildflee priority sorted
	#IOrderedEnumerable<IGrouping<int, PBEBattlePokemon>> prios =
			#pkmnSwitchingOut.Select(p => (p, SwitchRotatePriority))
			#.Concat(pkmnFighting.Select(p => (p, GetMovePrio(p)))) # Get move priority
			#.Concat(wildFleeing.Select(p => (p, WildFleePriority)))
			#.GroupBy(t => t.Item2, t => t.p)
			#.OrderByDescending(t => t.Key);
	#foreach (IGrouping<int, PBEBattlePokemon> bracket in prios)
		#bool ignoreItemsThatActivate = bracket.Key == SwitchRotatePriority || bracket.Key == WildFleePriority;
		#_turnOrder.AddRange(GetActingOrder(bracket, ignoreItemsThatActivate));

func RunActionsInOrder():
	for pkmn in _turnOrder.duplicate(): # Copy the list so a faint or ejection does not cause a collection modified exception
		if (BattleResult != null): # Do not broadcast battle result by calling EndCheck() in here; do it in TurnEnded()
			return;
		elif (ActiveBattlers.Contains(pkmn)):
			match (pkmn.TurnAction.Decision):
				PBETurnDecision.Fight:
					UseMove(pkmn, pkmn.TurnAction.FightMove, pkmn.TurnAction.FightTargets);
				PBETurnDecision.Item:
					UseItem(pkmn, pkmn.TurnAction.UseItem);
				PBETurnDecision.SwitchOut:
					SwitchTwoPokemon(pkmn, pkmn.Trainer.GetPokemon(pkmn.TurnAction.SwitchPokemonId));
				PBETurnDecision.WildFlee:
					WildFleeCheck(pkmn);
				_: 
					pass#throw new ArgumentOutOfRangeException(nameof(pkmn.TurnAction.Decision));


func TurnEnded():
	if EndCheck():
		return;

	# Verified: Effects before LightScreen/LuckyChant/Reflect/Safeguard/TrickRoom
	DoTurnEndedEffects();

	if EndCheck():
		return;

	# Verified: LightScreen/LuckyChant/Reflect/Safeguard/TrickRoom are removed in the order they were added
	for team in Teams: #each (PBETeam 
		if (team.TeamStatus.HasFlag(PBETeamStatus.LightScreen)):
			team.LightScreenCount -= 1
			if (team.LightScreenCount == 0):
				BroadcastTeamStatus(team, PBETeamStatus.LightScreen, PBETeamStatusAction.Ended);
		if (team.TeamStatus.HasFlag(PBETeamStatus.LuckyChant)):
			team.LuckyChantCount -= 1
			if (team.LuckyChantCount == 0):
				BroadcastTeamStatus(team, PBETeamStatus.LuckyChant, PBETeamStatusAction.Ended);
		if (team.TeamStatus.HasFlag(PBETeamStatus.Reflect)):
			team.ReflectCount -= 1
			if (team.ReflectCount == 0):
				BroadcastTeamStatus(team, PBETeamStatus.Reflect, PBETeamStatusAction.Ended);
		if (team.TeamStatus.HasFlag(PBETeamStatus.Safeguard)):
			team.SafeguardCount -= 1
			if (team.SafeguardCount == 0):
				BroadcastTeamStatus(team, PBETeamStatus.Safeguard, PBETeamStatusAction.Ended);
		if (team.TeamStatus.HasFlag(PBETeamStatus.Tailwind)):
			team.TailwindCount -= 1
			if (team.TailwindCount == 0):
				BroadcastTeamStatus(team, PBETeamStatus.Tailwind, PBETeamStatusAction.Ended);

	# Trick Room
	if (BattleStatus.HasFlag(PBEBattleStatus.TrickRoom)):
		TrickRoomCount -= 1
		if (TrickRoomCount == 0):
			BroadcastBattleStatus(PBEBattleStatus.TrickRoom, PBEBattleStatusAction.Ended);

	SwitchesOrActions();
