### Ideally, this would hold the global/static functions

#
class PBEBattle:

	static func AreActionsValid(trainer:PBETrainer, actions: Array[PBETurnAction], invalidReason:String) -> bool:
		if (trainer.Battle._battleState != PBEBattleState.WaitingForActions):
			pass #throw new InvalidOperationException($"{nameof(BattleState)} must be {PBEBattleState.WaitingForActions} to validate actions.");
		if (trainer.ActionsRequired.Count == 0):
			invalidReason = "Actions were already submitted";
			return false;
		if (actions.Count != trainer.ActionsRequired.Count):
			invalidReason = str("Invalid amount of actions submitted; required amount is ", trainer.ActionsRequired.Count)
			return false;

		var verified : Array[PBEBattlePokemon] = []; verified.resize(trainer.ActionsRequired.Count); #new List<PBEBattlePokemon>(trainer.ActionsRequired.Count);
		var standBy : Array[PBEBattlePokemon] = []; standBy.resize(trainer.ActionsRequired.Count); # = new List<PBEBattlePokemon>(trainer.ActionsRequired.Count);
		var item : Dictionary = {}; #s = new Dictionary<PBEItem, int>(trainer.ActionsRequired.Count);
		for action in actions: #PBETurnAction
			if (!trainer.TryGetPokemon(action.PokemonId, pkmn)):
				invalidReason = str("Invalid Pokémon ID (", action.PokemonId, ")")
				return false;
			if (!trainer.ActionsRequired.Contains(pkmn)):
				invalidReason = $"Pokémon {action.PokemonId} not looking for actions";
				return false;
			if (verified.Contains(pkmn)):
				invalidReason = $"Pokémon {action.PokemonId} was multiple actions";
				return false;
			match (action.Decision):
				PBETurnDecision.Fight:
					if (Array.IndexOf(pkmn.GetUsableMoves(), action.FightMove) == -1):
						invalidReason = $"{action.FightMove} is not usable by Pokémon {action.PokemonId}";
						return false;
					if (action.FightMove == pkmn.TempLockedMove && action.FightTargets != pkmn.TempLockedTargets):
						invalidReason = $"Pokémon {action.PokemonId} must target {pkmn.TempLockedTargets}";
						return false;
					if (!AreTargetsValid(pkmn, action.FightMove, action.FightTargets)):
						invalidReason = $"Invalid move targets for Pokémon {action.PokemonId}'s {action.FightMove}";
						return false;
					break;
				PBETurnDecision.Item:
					if (pkmn.TempLockedMove != PBEMove.None):
						invalidReason = $"Pokémon {action.PokemonId} must use {pkmn.TempLockedMove}";
						return false;
					if (!trainer.Inventory.TryGetValue(action.UseItem, slot)): # out PBEBattleInventory.PBEBattleInventorySlot? 
						invalidReason = $"Trainer \"{trainer.Name}\" does not have any {action.UseItem}"; # Handles wild Pokémon
						return false;
					var used : bool = items.TryGetValue(action.UseItem, amtUsed); # out int 
					if (!used):
						amtUsed = 0;
					var newAmt = slot.Quantity - amtUsed;
					if (newAmt <= 0):
						invalidReason = $"Tried to use too many {action.UseItem}";
						return false;
					if (trainer.Battle.BattleType == PBEBattleType.Wild and trainer.Team.OpposingTeam.ActiveBattlers.Count > 1
						and PBEDataUtils.AllBalls.Contains(action.UseItem)):
						invalidReason = $"Cannot throw a ball at multiple wild Pokémon";
						return false;
					amtUsed+=1;
					if (used):
						items[action.UseItem] = amtUsed;
					else:
						items.Add(action.UseItem, amtUsed);
					break;
				PBETurnDecision.SwitchOut:
					if (!pkmn.CanSwitchOut()):
						invalidReason = $"Pokémon {action.PokemonId} cannot switch out";
						return false;
					if (!trainer.TryGetPokemon(action.SwitchPokemonId, switchPkmn)): # out PBEBattlePokemon? 
						invalidReason = $"Invalid switch Pokémon ID ({action.PokemonId})";
						return false;
					if (switchPkmn.HP == 0):
						invalidReason = $"Switch Pokémon {action.PokemonId} is fainted";
						return false;
					if (switchPkmn.PBEIgnore):
						invalidReason = $"Switch Pokémon {action.PokemonId} cannot battle";
						return false;
					if (switchPkmn.FieldPosition != PBEFieldPosition.None):
						invalidReason = $"Switch Pokémon {action.PokemonId} is already on the field";
						return false;
					if (standBy.Contains(switchPkmn)):
						invalidReason = $"Switch Pokémon {action.PokemonId} was asked to be switched in multiple times";
						return false;
					standBy.Add(switchPkmn);
					break;
				_:
					invalidReason = $"Invalid turn decision ({action.Decision})";
					return false;
			verified.Add(pkmn);
		invalidReason = null;
		return true;


	static func SelectActionsIfValid(trainer:PBETrainer, actions:Array[PBETurnAction], invalidReason:String) -> bool:
		if (!AreActionsValid(trainer, actions, invalidReason)):
			return false;
		
		trainer.ActionsRequired.Clear();
		for action in actions:
			var pkmn : PBEBattlePokemon = trainer.GetPokemon(action.PokemonId);
			if (action.Decision == PBETurnDecision.Fight && pkmn.GetMoveTargets(action.FightMove) == PBEMoveTarget.RandomFoeSurrounding):
				match (trainer.Battle.BattleFormat):
					PBEBattleFormat.Single, PBEBattleFormat.Rotation:
						action.FightTargets = PBETurnTarget.FoeCenter;
						break;
					PBEBattleFormat.Double:
						action.FightTargets = PBETurnTarget.FoeLeft if trainer.Battle._rand.RandomBool() else PBETurnTarget.FoeRight;
						break;
					PBEBattleFormat.Triple:
						if (pkmn.FieldPosition == PBEFieldPosition.Left):
							action.FightTargets = PBETurnTarget.FoeCenter if trainer.Battle._rand.RandomBool() else PBETurnTarget.FoeRight;
						elif (pkmn.FieldPosition == PBEFieldPosition.Center):
							action.FightTargets = _SelectActionsIfValid_roll(trainer)
						else:
							action.FightTargets = PBETurnTarget.FoeLeft if trainer.Battle._rand.RandomBool() else PBETurnTarget.FoeCenter;
						break;
					_: pass #throw new InvalidDataException(nameof(trainer.Battle.BattleFormat));
			
			pkmn.TurnAction = action;
		if (trainer.Battle.Trainers.All(func(t): return t.ActionsRequired.Count == 0)):
			trainer.Battle.BattleState = PBEBattleState.ReadyToRunTurn;
		return true;


	func _SelectActionsIfValid_roll(trainer:PBETrainer):
		var oppTeam : PBETeam = trainer.Team.OpposingTeam;
		var r = trainer.Battle._rand.RandomInt(0, 2); # Keep randomly picking until a non-fainted foe is selected
		var targets = []
		
		if (oppTeam.IsSpotOccupied(PBEFieldPosition.Left)):
			targets.append( PBETurnTarget.FoeLeft )
		if (oppTeam.IsSpotOccupied(PBEFieldPosition.Right)):
			targets.append( PBETurnTarget.FoeRight )
		if (oppTeam.IsSpotOccupied(PBEFieldPosition.Center)):
			targets.append( PBETurnTarget.FoeCenter )
		return targets.shuffle()[0]
	

	static func AreSwitchesValid(trainer : PBETrainer, switches : Array[PBESwitchIn], invalidReason : String) -> bool:
		if (trainer.Battle._battleState != PBEBattleState.WaitingForSwitchIns):
			pass #throw new InvalidOperationException($"{nameof(BattleState)} must be {PBEBattleState.WaitingForSwitchIns} to validate switches.");
		if (trainer.SwitchInsRequired == 0):
			invalidReason = "Switches were already submitted";
			return false;
		if (switches.Count != trainer.SwitchInsRequired):
			invalidReason = $"Invalid amount of switches submitted; required amount is {trainer.SwitchInsRequired}";
			return false;
		var verified = new List<PBEBattlePokemon>(trainer.SwitchInsRequired);
		for s in switches:
			if (s.Position == PBEFieldPosition.None || s.Position >= PBEFieldPosition.MAX || !trainer.OwnsSpot(s.Position)):
				invalidReason = $"Invalid position ({s.PokemonId})";
				return false;
			if (!trainer.TryGetPokemon(s.PokemonId, out PBEBattlePokemon? pkmn))
			{
				invalidReason = $"Invalid Pokémon ID ({s.PokemonId})";
				return false;
			}
			if (pkmn.HP == 0)
			{
				invalidReason = $"Pokémon {s.PokemonId} is fainted";
				return false;
			}
			if (pkmn.PBEIgnore)
			{
				invalidReason = $"Pokémon {s.PokemonId} cannot battle";
				return false;
			}
			if (pkmn.FieldPosition != PBEFieldPosition.None)
			{
				invalidReason = $"Pokémon {s.PokemonId} is already on the field";
				return false;
			}
			if (verified.Contains(pkmn))
			{
				invalidReason = $"Pokémon {s.PokemonId} was asked to be switched in multiple times";
				return false;
			}
			verified.Add(pkmn);
		}
		invalidReason = null;
		return true;
	}
	internal static bool SelectSwitchesIfValid(PBETrainer trainer, IReadOnlyCollection<PBESwitchIn> switches, [NotNullWhen(false)] out string? invalidReason)
	{
		if (!AreSwitchesValid(trainer, switches, out invalidReason))
		{
			return false;
		}
		trainer.SwitchInsRequired = 0;
		foreach (PBESwitchIn s in switches)
		{
			trainer.SwitchInQueue.Add((trainer.GetPokemon(s.PokemonId), s.Position));
		}
		if (trainer.Battle.Trainers.All(t => t.SwitchInsRequired == 0))
		{
			trainer.Battle.BattleState = PBEBattleState.ReadyToRunSwitches;
		}
		return true;
	}

	internal static bool IsFleeValid(PBETrainer trainer, [NotNullWhen(false)] out string? invalidReason)
	{
		if (trainer.Battle.BattleType != PBEBattleType.Wild)
		{
			pass #throw new InvalidOperationException($"{nameof(BattleType)} must be {PBEBattleType.Wild} to flee.");
		}
		switch (trainer.Battle._battleState)
		{
			case PBEBattleState.WaitingForActions:
			{
				if (trainer.ActionsRequired.Count == 0)
				{
					invalidReason = "Actions were already submitted";
					return false;
				}
				PBEBattlePokemon pkmn = trainer.ActiveBattlersOrdered.First();
				if (pkmn.TempLockedMove != PBEMove.None)
				{
					invalidReason = $"Pokémon {pkmn.Id} must use {pkmn.TempLockedMove}";
					return false;
				}
				break;
			}
			case PBEBattleState.WaitingForSwitchIns:
			{
				if (trainer.SwitchInsRequired == 0)
				{
					invalidReason = "Switches were already submitted";
					return false;
				}
				break;
			}
			_: pass #throw new InvalidOperationException($"{nameof(BattleState)} must be {PBEBattleState.WaitingForActions} or {PBEBattleState.WaitingForSwitchIns} to flee.");
		invalidReason = null;
		return true;
	
	static func SelectFleeIfValid(PBETrainer trainer, [NotNullWhen(false)] out string? invalidReason) -> bool:
		if (!IsFleeValid(trainer, out invalidReason)):
			return false;
		trainer.RequestedFlee = true;
		if (trainer.Battle._battleState == PBEBattleState.WaitingForActions):
			trainer.ActionsRequired.Clear();
			if (trainer.Battle.Trainers.All(t => t.ActionsRequired.Count == 0)):
				trainer.Battle.BattleState = PBEBattleState.ReadyToRunTurn;
		else: # WaitingForSwitches
			trainer.SwitchInsRequired = 0;
			if (trainer.Battle.Trainers.All(t => t.SwitchInsRequired == 0)):
				trainer.Battle.BattleState = PBEBattleState.ReadyToRunSwitches;
		return true;
