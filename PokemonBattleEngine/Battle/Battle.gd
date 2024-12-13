### Ideally, this would hold the global/static functions

#
class PBEBattle1: ## Merge Battle into this.
	
	var amtUsed := 0

	static func AreActionsValid(trainer:PBETrainer, actions: Array[PBETurnAction], invalidReason:String) -> bool:
		if (trainer.Battle._battleState != PBEBattleState.WaitingForActions):
			pass #throw new InvalidOperationException($"{nameof(BattleState)} must be {PBEBattleState.WaitingForActions} to validate actions.");
		if (trainer.ActionsRequired.Count == 0):
			invalidReason = "Actions were already submitted";
			return false;
		if (actions.size() != trainer.ActionsRequired.size()):
			invalidReason = str("Invalid amount of actions submitted; required amount is ", trainer.ActionsRequired.Count)
			return false;

		var verified : Array[PBEBattlePokemon] = []; verified.resize(trainer.ActionsRequired.size()); #new List<PBEBattlePokemon>(trainer.ActionsRequired.Count);
		var standBy : Array[PBEBattlePokemon] = []; standBy.resize(trainer.ActionsRequired.size()); # = new List<PBEBattlePokemon>(trainer.ActionsRequired.Count);
		var item : Dictionary = {}; #s = new Dictionary<PBEItem, int>(trainer.ActionsRequired.Count);
		for action in actions: #PBETurnAction
			if (!trainer.TryGetPokemon(action.PokemonId, pkmn)):
				invalidReason = str("Invalid Pokémon ID (", action.PokemonId, ")")
				return false;
			if (!trainer.ActionsRequired.Contains(pkmn)):
				invalidReason = str("Pokémon ", action.PokemonId , " not looking for actions")
				return false;
			if (verified.Contains(pkmn)):
				invalidReason = str("Pokémon ", action.PokemonId, " was multiple actions")
				return false;
			match (action.Decision):
				PBETurnDecision.Fight:
					if (pkmn.GetUsableMoves().find(action.FightMove) == -1):
						invalidReason = str(action.FightMove, " is not usable by Pokémon ", action.PokemonId)
						return false;
					if (action.FightMove == pkmn.TempLockedMove && action.FightTargets != pkmn.TempLockedTargets):
						invalidReason = str("Pokémon ", action.PokemonId, " must target ", pkmn.TempLockedTargets)
						return false;
					if (!AreTargetsValid(pkmn, action.FightMove, action.FightTargets)):
						invalidReason = str("Invalid move targets for Pokémon ", action.PokemonId, "'s ", action.FightMove)
						return false;
					break;
				PBETurnDecision.Item:
					if (pkmn.TempLockedMove != PBEMove.None):
						invalidReason = str("Pokémon ", action.PokemonId, " must use ", pkmn.TempLockedMove)
						return false;
					if (!trainer.Inventory.TryGetValue(action.UseItem, slot)): # out PBEBattleInventory.PBEBattleInventorySlot? 
						invalidReason = str("Trainer \"" , trainer.Name , "\" does not have any ", action.UseItem) # Handles wild Pokémon
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
					amtUsed += 1;
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


	static func _SelectActionsIfValid_roll(trainer:PBETrainer):
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
		var verified = [] #new List<PBEBattlePokemon>(trainer.SwitchInsRequired);
		for s in switches:
			if (s.Position == PBEFieldPosition.None || s.Position >= PBEFieldPosition.MAX || !trainer.OwnsSpot(s.Position)):
				invalidReason = $"Invalid position ({s.PokemonId})";
				return false;
			if (!trainer.TryGetPokemon(s.PokemonId, pkmn)):
				invalidReason = $"Invalid Pokémon ID ({s.PokemonId})";
				return false;
			if (pkmn.HP == 0):
				invalidReason = $"Pokémon {s.PokemonId} is fainted";
				return false;
			if (pkmn.PBEIgnore):
				invalidReason = $"Pokémon {s.PokemonId} cannot battle";
				return false;
			if (pkmn.FieldPosition != PBEFieldPosition.None):
				invalidReason = $"Pokémon {s.PokemonId} is already on the field";
				return false;
			if (verified.Contains(pkmn)):
				invalidReason = $"Pokémon {s.PokemonId} was asked to be switched in multiple times";
				return false;
			verified.Add(pkmn)
		invalidReason = null;
		return true;


	static func SelectSwitchesIfValid(trainer:PBETrainer, switches:Array[PBESwitchIn], invalidReason:String) -> bool:
		if (!AreSwitchesValid(trainer, switches, invalidReason)):
			return false;
		trainer.SwitchInsRequired = 0;
		for s in switches:
			trainer.SwitchInQueue.Add(trainer.GetPokemon(s.PokemonId), s.Position)
		if (trainer.Battle.Trainers.All(func(t): return t.SwitchInsRequired == 0)):
			trainer.Battle.BattleState = PBEBattleState.ReadyToRunSwitches;
		return true;

	static func IsFleeValid(trainer:PBETrainer, invalidReason:String) -> bool:
		if (trainer.Battle.BattleType != PBEBattleType.Wild):
			pass #throw new InvalidOperationException($"{nameof(BattleType)} must be {PBEBattleType.Wild} to flee.");
		match (trainer.Battle._battleState):
			PBEBattleState.WaitingForActions:
				if (trainer.ActionsRequired.Count == 0):
					invalidReason = "Actions were already submitted";
					return false;
				var pkmn : PBEBattlePokemon = trainer.ActiveBattlersOrdered.First();
				if (pkmn.TempLockedMove != PBEMove.None):
					invalidReason = $"Pokémon {pkmn.Id} must use {pkmn.TempLockedMove}";
					return false;
			PBEBattleState.WaitingForSwitchIns:
				if (trainer.SwitchInsRequired == 0):
					invalidReason = "Switches were already submitted";
					return false;
			_: pass #throw new InvalidOperationException($"{nameof(BattleState)} must be {PBEBattleState.WaitingForActions} or {PBEBattleState.WaitingForSwitchIns} to flee.");
		invalidReason = null;
		return true;


	static func SelectFleeIfValid(trainer:PBETrainer, invalidReason:String) -> bool:
		if (!IsFleeValid(trainer, invalidReason)):
			return false;
		trainer.RequestedFlee = true;
		if (trainer.Battle._battleState == PBEBattleState.WaitingForActions):
			trainer.ActionsRequired.Clear();
			if (trainer.Battle.Trainers.All(func(t): return t.ActionsRequired.Count == 0)):
				trainer.Battle.BattleState = PBEBattleState.ReadyToRunTurn;
		else: # WaitingForSwitches
			trainer.SwitchInsRequired = 0;
			if (trainer.Battle.Trainers.All(func(t): return t.SwitchInsRequired == 0)):
				trainer.Battle.BattleState = PBEBattleState.ReadyToRunSwitches;
		return true;


# This constant looping order that's present in hitting as well as turn ended effects is very weird and unnecessary, but I mimic it for accuracy
# That's why this file exists in favor of the order I had before
public sealed partial class PBEBattle
{
	
	# TODO: TripleKick miss logic
	private void Hit_GetVictims(PBEBattlePokemon user, PBEBattlePokemon[] targets, IPBEMoveData mData, PBEType moveType, out List<PBEAttackVictim> victims,
		Func<PBEBattlePokemon, PBEResult>? failFunc = null)
	{
		victims = new List<PBEAttackVictim>(targets.Length);
		foreach (PBEBattlePokemon target in targets)
		{
			if (!AttackTypeCheck(user, target, moveType, out PBEResult result, out float typeEffectiveness))
			{
				continue;
			}
			# Verified: These fails are after type effectiveness (So SuckerPunch will not affect Ghost types due to Normalize before it fails due to invalid conditions)
			if (failFunc is not null && failFunc.Invoke(target) != PBEResult.Success)
			{
				continue;
			}
			victims.Add(new PBEAttackVictim(target, result, typeEffectiveness));
		}
		if (victims.Count == 0)
		{
			return;
		}
		victims.RemoveAll(t => MissCheck(user, t.Pkmn, mData));
		return;
	}
	# Outs are for hit targets that were not behind substitute
	private static void Hit_HitTargets(PBETeam user, Action<List<PBEAttackVictim>> doSub, Action<List<PBEAttackVictim>> doNormal, List<PBEAttackVictim> victims,
		out List<PBEAttackVictim> allies, out List<PBEAttackVictim> foes)
	{
		List<PBEAttackVictim> subAllies = victims.FindAll(v =>
			{
				PBEBattlePokemon pkmn = v.Pkmn;
				return pkmn.Team == user && pkmn.Status2.HasFlag(PBEStatus2.Substitute);
			});
		allies = victims.FindAll(v =>
		{
			PBEBattlePokemon pkmn = v.Pkmn;
			return pkmn.Team == user && !pkmn.Status2.HasFlag(PBEStatus2.Substitute);
		});
		List<PBEAttackVictim> subFoes = victims.FindAll(v =>
			{
				PBEBattlePokemon pkmn = v.Pkmn;
				return pkmn.Team != user && pkmn.Status2.HasFlag(PBEStatus2.Substitute);
			});
		foes = victims.FindAll(v =>
		{
			PBEBattlePokemon pkmn = v.Pkmn;
			return pkmn.Team != user && !pkmn.Status2.HasFlag(PBEStatus2.Substitute);
		});
		doSub(subAllies);
		doNormal(allies);
		doSub(subFoes);
		doNormal(foes);
	}
	private void Hit_DoCrit(List<PBEAttackVictim> victims)
	{
		foreach (PBEAttackVictim victim in victims)
		{
			if (victim.Crit)
			{
				BroadcastMoveCrit(victim.Pkmn);
			}
		}
	}
	private void Hit_DoMoveResult(PBEBattlePokemon user, List<PBEAttackVictim> victims)
	{
		foreach (PBEAttackVictim victim in victims)
		{
			PBEResult result = victim.Result;
			if (result != PBEResult.Success)
			{
				BroadcastMoveResult(user, victim.Pkmn, result);
			}
		}
	}
	private void Hit_FaintCheck(List<PBEAttackVictim> victims)
	{
		foreach (PBEAttackVictim victim in victims)
		{
			FaintCheck(victim.Pkmn);
		}
	}

	private void BasicHit(PBEBattlePokemon user, PBEBattlePokemon[] targets, IPBEMoveData mData,
		Func<PBEBattlePokemon, PBEResult>? failFunc = null,
		Action<PBEBattlePokemon>? beforeDoingDamage = null,
		Action<PBEBattlePokemon, ushort>? beforePostHit = null,
		Action<PBEBattlePokemon>? afterPostHit = null,
		Func<int, int?>? recoilFunc = null)
	{
		# Targets array is [FoeLeft, FoeCenter, FoeRight, AllyLeft, AllyCenter, AllyRight]
		# User can faint or heal with a berry at LiquidOoze, IronBarbs/RockyHelmet, and also at Recoil/LifeOrb
		# -------------Official order-------------
		# Setup   - [effectiveness/fail checks foes], [effectiveness/fail checks allies], [miss/protection checks foes] [miss/protection checks allies], gem,
		# Allies  - [sub damage allies, sub effectiveness allies, sub crit allies, sub break allies], [hit allies], [effectiveness allies], [crit allies], [posthit allies], [faint allies],
		# Foes    - [sub damage foes, sub effectiveness foes, sub crit foes, sub break foes], [hit foes], [effectiveness foes], [crit foes], [posthit foes], [faint foes],
		# Cleanup - recoil, lifeorb, [colorchange foes], [colorchange allies], [berry allies], [berry foes], [antistatusability allies], [antistatusability foes], exp

		PBEType moveType = user.GetMoveType(mData);
		# DreamEater checks for sleep before gem activates
		# SuckerPunch fails
		Hit_GetVictims(user, targets, mData, moveType, out List<PBEAttackVictim> victims, failFunc: failFunc);
		if (victims.Count == 0)
		{
			return;
		}
		float basePower = CalculateBasePower(user, targets, mData, moveType); # Gem activates here
		float initDamageMultiplier = victims.Count > 1 ? 0.75f : 1;
		int totalDamageDealt = 0;
		void CalcDamage(PBEAttackVictim victim)
		{
			PBEBattlePokemon target = victim.Pkmn;
			PBEResult result = victim.Result;
			float damageMultiplier = initDamageMultiplier * victim.TypeEffectiveness;
			# Brick Break destroys Light Screen and Reflect before doing damage (after gem)
			# Feint destroys protection
			# Pay Day scatters coins
			beforeDoingDamage?.Invoke(target);
			bool crit = CritCheck(user, target, mData);
			damageMultiplier *= CalculateDamageMultiplier(user, target, mData, moveType, result, crit);
			int damage = (int)(damageMultiplier * CalculateDamage(user, target, mData, moveType, basePower, crit));
			victim.Damage = DealDamage(user, target, damage, ignoreSubstitute: false, ignoreSturdy: false);
			totalDamageDealt += victim.Damage;
			victim.Crit = crit;
		}
		void DoSub(List<PBEAttackVictim> subs)
		{
			foreach (PBEAttackVictim victim in subs)
			{
				CalcDamage(victim);
				PBEBattlePokemon target = victim.Pkmn;
				PBEResult result = victim.Result;
				if (result != PBEResult.Success)
				{
					BroadcastMoveResult(user, target, result);
				}
				if (victim.Crit)
				{
					BroadcastMoveCrit(target);
				}
				if (target.SubstituteHP == 0)
				{
					BroadcastStatus2(target, user, PBEStatus2.Substitute, PBEStatusAction.Ended);
				}
			}
		}
		void DoNormal(List<PBEAttackVictim> normals)
		{
			foreach (PBEAttackVictim victim in normals)
			{
				CalcDamage(victim);
			}
			Hit_DoMoveResult(user, normals);
			Hit_DoCrit(normals);
			foreach (PBEAttackVictim victim in normals)
			{
				PBEBattlePokemon target = victim.Pkmn;
				# Stats/statuses are changed before post-hit effects
				# HP-draining moves restore HP
				beforePostHit?.Invoke(target, victim.Damage); # TODO: LiquidOoze fainting/healing
				DoPostHitEffects(user, target, mData, moveType);
				# ShadowForce destroys protection
				# SmellingSalt cures paralysis
				# WakeUpSlap cures sleep
				afterPostHit?.Invoke(target); # Verified: These happen before Recoil/LifeOrb
			}
			Hit_FaintCheck(normals);
		}

		Hit_HitTargets(user.Team, DoSub, DoNormal, victims, out List<PBEAttackVictim> allies, out List<PBEAttackVictim> foes);
		DoPostAttackedEffects(user, allies, foes, true, recoilDamage: recoilFunc?.Invoke(totalDamageDealt), colorChangeType: moveType);
	}
	# None of these moves are multi-target
	private void FixedDamageHit(PBEBattlePokemon user, PBEBattlePokemon[] targets, IPBEMoveData mData, Func<PBEBattlePokemon, int> damageFunc,
		Func<PBEBattlePokemon, PBEResult>? failFunc = null,
		Action? beforePostHit = null)
	{
		PBEType moveType = user.GetMoveType(mData);
		# Endeavor fails if the target's HP is <= the user's HP
		# One hit knockout moves fail if the target's level is > the user's level
		Hit_GetVictims(user, targets, mData, moveType, out List<PBEAttackVictim> victims, failFunc: failFunc);
		if (victims.Count == 0)
		{
			return;
		}
		# BUG: Gems activate for these moves despite base power not being involved
		if (!Settings.BugFix)
		{
			_ = CalculateBasePower(user, targets, mData, moveType);
		}
		void CalcDamage(PBEAttackVictim victim)
		{
			PBEBattlePokemon target = victim.Pkmn;
			# FinalGambit user faints here
			victim.Damage = DealDamage(user, target, damageFunc.Invoke(target));
		}
		void DoSub(List<PBEAttackVictim> subs)
		{
			foreach (PBEAttackVictim victim in subs)
			{
				CalcDamage(victim);
				PBEBattlePokemon target = victim.Pkmn;
				if (target.SubstituteHP == 0)
				{
					BroadcastStatus2(target, user, PBEStatus2.Substitute, PBEStatusAction.Ended);
				}
			}
		}
		void DoNormal(List<PBEAttackVictim> normals)
		{
			foreach (PBEAttackVictim victim in normals)
			{
				CalcDamage(victim);
			}
			foreach (PBEAttackVictim victim in normals)
			{
				PBEBattlePokemon target = victim.Pkmn;
				# "It's a one-hit KO!"
				beforePostHit?.Invoke();
				DoPostHitEffects(user, target, mData, moveType);
			}
			Hit_FaintCheck(normals);
		}

		Hit_HitTargets(user.Team, DoSub, DoNormal, victims, out List<PBEAttackVictim> allies, out List<PBEAttackVictim> foes);
		DoPostAttackedEffects(user, allies, foes, false, colorChangeType: moveType);
	}
	# None of these moves are multi-target
	private void MultiHit(PBEBattlePokemon user, PBEBattlePokemon[] targets, IPBEMoveData mData, byte numHits,
		bool subsequentMissChecks = false,
		Action<PBEBattlePokemon>? beforePostHit = null)
	{
		PBEType moveType = user.GetMoveType(mData);
		Hit_GetVictims(user, targets, mData, moveType, out List<PBEAttackVictim> victims);
		if (victims.Count == 0)
		{
			return;
		}
		float basePower = CalculateBasePower(user, targets, mData, moveType); # Verified: Gem boost applies to all hits
		float initDamageMultiplier = victims.Count > 1 ? 0.75f : 1;
		void CalcDamage(PBEAttackVictim victim)
		{
			PBEBattlePokemon target = victim.Pkmn;
			PBEResult result = victim.Result;
			float damageMultiplier = initDamageMultiplier * victim.TypeEffectiveness;
			bool crit = CritCheck(user, target, mData);
			damageMultiplier *= CalculateDamageMultiplier(user, target, mData, moveType, result, crit);
			int damage = (int)(damageMultiplier * CalculateDamage(user, target, mData, moveType, basePower, crit));
			victim.Damage = DealDamage(user, target, damage, ignoreSubstitute: false, ignoreSturdy: false);
			victim.Crit = crit;
		}
		void DoSub(List<PBEAttackVictim> subs)
		{
			foreach (PBEAttackVictim victim in subs)
			{
				CalcDamage(victim);
				PBEBattlePokemon target = victim.Pkmn;
				if (victim.Crit)
				{
					BroadcastMoveCrit(target);
				}
				if (target.SubstituteHP == 0)
				{
					BroadcastStatus2(target, user, PBEStatus2.Substitute, PBEStatusAction.Ended);
				}
			}
		}
		void DoNormal(List<PBEAttackVictim> normals)
		{
			normals.RemoveAll(v => v.Pkmn.HP == 0); # Remove ones that fainted from previous hits
			foreach (PBEAttackVictim victim in normals)
			{
				CalcDamage(victim);
			}
			Hit_DoCrit(normals);
			foreach (PBEAttackVictim victim in normals)
			{
				PBEBattlePokemon target = victim.Pkmn;
				# Twineedle has a chance to poison on each strike
				beforePostHit?.Invoke(target);
				DoPostHitEffects(user, target, mData, moveType);
			}
		}

		byte hit = 0;
		List<PBEAttackVictim> allies, foes;
		do
		{
			Hit_HitTargets(user.Team, DoSub, DoNormal, victims, out allies, out foes);
			hit++;
		} while (hit < numHits && user.HP > 0 && user.Status1 != PBEStatus1.Asleep && victims.FindIndex(v => v.Pkmn.HP > 0) != -1);
		Hit_DoMoveResult(user, allies);
		Hit_DoMoveResult(user, foes);
		BroadcastMultiHit(hit);
		Hit_FaintCheck(allies);
		Hit_FaintCheck(foes);
		DoPostAttackedEffects(user, allies, foes, true, colorChangeType: moveType);
	}
}

public sealed partial class PBEBattle
{
	## <summary>Gets the influence a stat change has on a stat.</summary>
	## <param name="change">The stat change.</param>
	## <param name="forMissing">True if the stat is <see cref="PBEStat.Accuracy"/> or <see cref="PBEStat.Evasion"/>.</param>
	public static float GetStatChangeModifier(sbyte change, bool forMissing)
	{
		float baseVal = forMissing ? 3 : 2;
		float numerator = Math.Max(baseVal, baseVal + change);
		float denominator = Math.Max(baseVal, baseVal - change);
		return numerator / denominator;
	}

	# Verified: Sturdy and Substitute only activate on damaging attacks (so draining HP or liquid ooze etc can bypass sturdy)
	private ushort DealDamage(PBEBattlePokemon culprit, PBEBattlePokemon victim, int hp, bool ignoreSubstitute = true, bool ignoreSturdy = true)
	{
		if (hp < 1)
		{
			hp = 1;
		}
		if (!ignoreSubstitute && victim.Status2.HasFlag(PBEStatus2.Substitute))
		{
			ushort oldSubHP = victim.SubstituteHP;
			victim.SubstituteHP = (ushort)Math.Max(0, victim.SubstituteHP - hp);
			ushort damageAmt = (ushort)(oldSubHP - victim.SubstituteHP);
			BroadcastStatus2(victim, culprit, PBEStatus2.Substitute, PBEStatusAction.Damage);
			return damageAmt;
		}
		ushort oldHP = victim.HP;
		float oldPercentage = victim.HPPercentage;
		victim.HP = (ushort)Math.Max(0, victim.HP - hp);
		bool sturdyHappened = false, focusBandHappened = false, focusSashHappened = false;
		if (!ignoreSturdy && victim.HP == 0)
		{
			# TODO: Endure
			if (oldHP == victim.MaxHP && victim.Ability == PBEAbility.Sturdy && !culprit.HasCancellingAbility())
			{
				sturdyHappened = true;
				victim.HP = 1;
			}
			else if (victim.Item == PBEItem.FocusBand && _rand.RandomBool(10, 100))
			{
				focusBandHappened = true;
				victim.HP = 1;
			}
			else if (oldHP == victim.MaxHP && victim.Item == PBEItem.FocusSash)
			{
				focusSashHappened = true;
				victim.HP = 1;
			}
		}
		victim.UpdateHPPercentage();
		BroadcastPkmnHPChanged(victim, oldHP, oldPercentage);
		if (sturdyHappened)
		{
			BroadcastAbility(victim, culprit, PBEAbility.Sturdy, PBEAbilityAction.Damage);
			BroadcastEndure(victim);
		}
		else if (focusBandHappened)
		{
			BroadcastItem(victim, culprit, PBEItem.FocusBand, PBEItemAction.Damage);
		}
		else if (focusSashHappened)
		{
			BroadcastItem(victim, culprit, PBEItem.FocusSash, PBEItemAction.Consumed);
		}
		return (ushort)(oldHP - victim.HP);
	}
	## <summary>Restores HP to <paramref name="pkmn"/> and broadcasts the HP changing if it changes.</summary>
	## <param name="pkmn">The Pokémon receiving the HP.</param>
	## <param name="hp">The amount of HP <paramref name="pkmn"/> will try to gain.</param>
	## <returns>The amount of HP restored.</returns>
	private ushort HealDamage(PBEBattlePokemon pkmn, int hp)
	{
		if (hp < 1)
		{
			hp = 1;
		}
		ushort oldHP = pkmn.HP;
		float oldPercentage = pkmn.HPPercentage;
		pkmn.HP = (ushort)Math.Min(pkmn.MaxHP, pkmn.HP + hp); # Always try to heal at least 1 HP
		ushort healAmt = (ushort)(pkmn.HP - oldHP);
		if (healAmt > 0)
		{
			pkmn.UpdateHPPercentage();
			BroadcastPkmnHPChanged(pkmn, oldHP, oldPercentage);
		}
		return healAmt;
	}

	private float CalculateBasePower(PBEBattlePokemon user, PBEBattlePokemon[] targets, IPBEMoveData mData, PBEType moveType)
	{
		float basePower;

		#region Get move's base power
		switch (mData.Effect)
		{
			case PBEMoveEffect.CrushGrip:
			{
				basePower = Math.Max(1, targets.Select(t => (float)mData.Power * t.HP / t.MaxHP).Average());
				break;
			}
			case PBEMoveEffect.Eruption:
			{
				basePower = Math.Max(1, mData.Power * user.HP / user.MaxHP);
				break;
			}
			case PBEMoveEffect.Flail:
			{
				int val = 48 * user.HP / user.MaxHP;
				if (val < 2)
				{
					basePower = 200;
				}
				else if (val < 4)
				{
					basePower = 150;
				}
				else if (val < 8)
				{
					basePower = 100;
				}
				else if (val < 16)
				{
					basePower = 80;
				}
				else if (val < 32)
				{
					basePower = 40;
				}
				else
				{
					basePower = 20;
				}
				break;
			}
			case PBEMoveEffect.Frustration:
			{
				basePower = Math.Max(1, (byte.MaxValue - user.Friendship) / 2.5f);
				break;
			}
			case PBEMoveEffect.GrassKnot:
			{
				basePower = targets.Select(t =>
				{
					if (t.Weight >= 200.0f)
					{
						return 120f;
					}
					else if (t.Weight >= 100.0f)
					{
						return 100f;
					}
					else if (t.Weight >= 50.0f)
					{
						return 80f;
					}
					else if (t.Weight >= 25.0f)
					{
						return 60f;
					}
					else if (t.Weight >= 10.0f)
					{
						return 40f;
					}
					return 20f;
				}).Average();
				break;
			}
			case PBEMoveEffect.HeatCrash:
			{
				basePower = targets.Select(t =>
				{
					float relative = user.Weight / t.Weight;
					if (relative < 2)
					{
						return 40f;
					}
					else if (relative < 3)
					{
						return 60f;
					}
					else if (relative < 4)
					{
						return 80f;
					}
					else if (relative < 5)
					{
						return 100f;
					}
					return 120f;
				}).Average();
				break;
			}
			case PBEMoveEffect.HiddenPower:
			{
				basePower = user.IndividualValues!.GetHiddenPowerBasePower(Settings);
				break;
			}
			case PBEMoveEffect.Magnitude:
			{
				int val = _rand.RandomInt(0, 99);
				byte magnitude;
				if (val < 5) # Magnitude 4 - 5%
				{
					magnitude = 4;
					basePower = 10;
				}
				else if (val < 15) # Magnitude 5 - 10%
				{
					magnitude = 5;
					basePower = 30;
				}
				else if (val < 35) # Magnitude 6 - 20%
				{
					magnitude = 6;
					basePower = 50;
				}
				else if (val < 65) # Magnitude 7 - 30%
				{
					magnitude = 7;
					basePower = 70;
				}
				else if (val < 85) # Magnitude 8 - 20%
				{
					magnitude = 8;
					basePower = 90;
				}
				else if (val < 95) # Magnitude 9 - 10%
				{
					magnitude = 9;
					basePower = 110;
				}
				else # Magnitude 10 - 5%
				{
					magnitude = 10;
					basePower = 150;
				}
				BroadcastMagnitude(magnitude);
				break;
			}
			case PBEMoveEffect.Punishment:
			{
				basePower = Math.Max(1, Math.Min(200, targets.Select(t => mData.Power + (20f * t.GetPositiveStatTotal())).Average()));
				break;
			}
			case PBEMoveEffect.Return:
			{
				basePower = Math.Max(1, user.Friendship / 2.5f);
				break;
			}
			case PBEMoveEffect.StoredPower:
			{
				basePower = mData.Power + (20 * user.GetPositiveStatTotal());
				break;
			}
			default:
			{
				basePower = Math.Max(1, (int)mData.Power);
				break;
			}
		}
		#endregion

		# Technician goes before any other power boosts
		if (user.Ability == PBEAbility.Technician && basePower <= 60)
		{
			basePower *= 1.5f;
		}

		#region Item-specific power boosts
		switch (moveType)
		{
			case PBEType.Bug:
			{
				switch (user.Item)
				{
					case PBEItem.InsectPlate:
					case PBEItem.SilverPowder:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.BugGem:
					{
						BroadcastItem(user, user, PBEItem.BugGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Dark:
			{
				switch (user.Item)
				{
					case PBEItem.BlackGlasses:
					case PBEItem.DreadPlate:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.DarkGem:
					{
						BroadcastItem(user, user, PBEItem.DarkGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Dragon:
			{
				switch (user.Item)
				{
					case PBEItem.AdamantOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Dialga)
						{
							basePower *= 1.2f;
						}
						break;
					}
					case PBEItem.DracoPlate:
					case PBEItem.DragonFang:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.GriseousOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Giratina && user.RevertForm == PBEForm.Giratina_Origin)
						{
							basePower *= 1.2f;
						}
						break;
					}
					case PBEItem.LustrousOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Palkia)
						{
							basePower *= 1.2f;
						}
						break;
					}
					case PBEItem.DragonGem:
					{
						BroadcastItem(user, user, PBEItem.DragonGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Electric:
			{
				switch (user.Item)
				{
					case PBEItem.Magnet:
					case PBEItem.ZapPlate:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.ElectricGem:
					{
						BroadcastItem(user, user, PBEItem.ElectricGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Fighting:
			{
				switch (user.Item)
				{
					case PBEItem.BlackBelt:
					case PBEItem.FistPlate:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.FightingGem:
					{
						BroadcastItem(user, user, PBEItem.FightingGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Fire:
			{
				switch (user.Item)
				{
					case PBEItem.Charcoal:
					case PBEItem.FlamePlate:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.FireGem:
					{
						BroadcastItem(user, user, PBEItem.FireGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Flying:
			{
				switch (user.Item)
				{
					case PBEItem.SharpBeak:
					case PBEItem.SkyPlate:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.FlyingGem:
					{
						BroadcastItem(user, user, PBEItem.FlyingGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Ghost:
			{
				switch (user.Item)
				{
					case PBEItem.GriseousOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Giratina && user.RevertForm == PBEForm.Giratina_Origin)
						{
							basePower *= 1.2f;
						}
						break;
					}
					case PBEItem.SpellTag:
					case PBEItem.SpookyPlate:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.GhostGem:
					{
						BroadcastItem(user, user, PBEItem.GhostGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Grass:
			{
				switch (user.Item)
				{
					case PBEItem.MeadowPlate:
					case PBEItem.MiracleSeed:
					case PBEItem.RoseIncense:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.GrassGem:
					{
						BroadcastItem(user, user, PBEItem.GrassGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Ground:
			{
				switch (user.Item)
				{
					case PBEItem.EarthPlate:
					case PBEItem.SoftSand:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.GroundGem:
					{
						BroadcastItem(user, user, PBEItem.GroundGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Ice:
			{
				switch (user.Item)
				{
					case PBEItem.IciclePlate:
					case PBEItem.NeverMeltIce:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.IceGem:
					{
						BroadcastItem(user, user, PBEItem.IceGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.None:
			{
				break;
			}
			case PBEType.Normal:
			{
				switch (user.Item)
				{
					case PBEItem.SilkScarf:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.NormalGem:
					{
						BroadcastItem(user, user, PBEItem.NormalGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Poison:
			{
				switch (user.Item)
				{
					case PBEItem.PoisonBarb:
					case PBEItem.ToxicPlate:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.PoisonGem:
					{
						BroadcastItem(user, user, PBEItem.PoisonGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Psychic:
			{
				switch (user.Item)
				{
					case PBEItem.MindPlate:
					case PBEItem.OddIncense:
					case PBEItem.TwistedSpoon:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.PsychicGem:
					{
						BroadcastItem(user, user, PBEItem.PsychicGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Rock:
			{
				switch (user.Item)
				{
					case PBEItem.HardStone:
					case PBEItem.RockIncense:
					case PBEItem.StonePlate:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.RockGem:
					{
						BroadcastItem(user, user, PBEItem.RockGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Steel:
			{
				switch (user.Item)
				{
					case PBEItem.AdamantOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Dialga)
						{
							basePower *= 1.2f;
						}
						break;
					}
					case PBEItem.IronPlate:
					case PBEItem.MetalCoat:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.SteelGem:
					{
						BroadcastItem(user, user, PBEItem.SteelGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			case PBEType.Water:
			{
				switch (user.Item)
				{
					case PBEItem.LustrousOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Palkia)
						{
							basePower *= 1.2f;
						}
						break;
					}
					case PBEItem.MysticWater:
					case PBEItem.SeaIncense:
					case PBEItem.SplashPlate:
					case PBEItem.WaveIncense:
					{
						basePower *= 1.2f;
						break;
					}
					case PBEItem.WaterGem:
					{
						BroadcastItem(user, user, PBEItem.WaterGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			default: throw new ArgumentOutOfRangeException(nameof(moveType));
		}
		#endregion

		#region Move-specific power boosts
		switch (mData.Effect)
		{
			case PBEMoveEffect.Acrobatics:
			{
				if (user.Item == PBEItem.None)
				{
					basePower *= 2.0f;
				}
				break;
			}
			case PBEMoveEffect.Brine:
			{
				if (Array.FindIndex(targets, t => t.HP <= t.HP / 2) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			case PBEMoveEffect.Facade:
			{
				if (user.Status1 == PBEStatus1.Burned || user.Status1 == PBEStatus1.Paralyzed || user.Status1 == PBEStatus1.Poisoned || user.Status1 == PBEStatus1.BadlyPoisoned)
				{
					basePower *= 2.0f;
				}
				break;
			}
			case PBEMoveEffect.Hex:
			{
				if (Array.FindIndex(targets, t => t.Status1 != PBEStatus1.None) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			case PBEMoveEffect.Payback:
			{
				if (Array.FindIndex(targets, t => t.HasUsedMoveThisTurn) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			case PBEMoveEffect.Retaliate:
			{
				if (user.Team.MonFaintedLastTurn)
				{
					basePower *= 2.0f;
				}
				break;
			}
			case PBEMoveEffect.SmellingSalt:
			{
				if (Array.FindIndex(targets, t => t.Status1 == PBEStatus1.Paralyzed) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			case PBEMoveEffect.Venoshock:
			{
				if (Array.FindIndex(targets, t => t.Status1 == PBEStatus1.Poisoned || t.Status1 == PBEStatus1.BadlyPoisoned) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			case PBEMoveEffect.WakeUpSlap:
			{
				if (Array.FindIndex(targets, t => t.Status1 == PBEStatus1.Asleep) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			case PBEMoveEffect.WeatherBall:
			{
				if (ShouldDoWeatherEffects() && Weather != PBEWeather.None)
				{
					basePower *= 2.0f;
				}
				break;
			}
		}
		#endregion

		#region Weather-specific power boosts
		if (ShouldDoWeatherEffects())
		{
			switch (Weather)
			{
				case PBEWeather.HarshSunlight:
				{
					if (moveType == PBEType.Fire)
					{
						basePower *= 1.5f;
					}
					else if (moveType == PBEType.Water)
					{
						basePower *= 0.5f;
					}
					break;
				}
				case PBEWeather.Rain:
				{
					if (moveType == PBEType.Water)
					{
						basePower *= 1.5f;
					}
					else if (moveType == PBEType.Fire)
					{
						basePower *= 0.5f;
					}
					break;
				}
				case PBEWeather.Sandstorm:
				{
					if (user.Ability == PBEAbility.SandForce && (moveType == PBEType.Rock || moveType == PBEType.Ground || moveType == PBEType.Steel))
					{
						basePower *= 1.3f;
					}
					break;
				}
			}
		}
		#endregion

		#region Other power boosts
		if (user.Status2.HasFlag(PBEStatus2.HelpingHand))
		{
			basePower *= 1.5f;
		}
		if (user.Ability == PBEAbility.FlareBoost && mData.Category == PBEMoveCategory.Special && user.Status1 == PBEStatus1.Burned)
		{
			basePower *= 1.5f;
		}
		if (user.Ability == PBEAbility.ToxicBoost && mData.Category == PBEMoveCategory.Physical && (user.Status1 == PBEStatus1.Poisoned || user.Status1 == PBEStatus1.BadlyPoisoned))
		{
			basePower *= 1.5f;
		}
		if (user.Item == PBEItem.LifeOrb)
		{
			basePower *= 1.3f;
		}
		if (user.Ability == PBEAbility.IronFist && mData.Flags.HasFlag(PBEMoveFlag.AffectedByIronFist))
		{
			basePower *= 1.2f;
		}
		if (user.Ability == PBEAbility.Reckless && mData.Flags.HasFlag(PBEMoveFlag.AffectedByReckless))
		{
			basePower *= 1.2f;
		}
		if (user.Item == PBEItem.MuscleBand && mData.Category == PBEMoveCategory.Physical)
		{
			basePower *= 1.1f;
		}
		if (user.Item == PBEItem.WiseGlasses && mData.Category == PBEMoveCategory.Special)
		{
			basePower *= 1.1f;
		}
		#endregion

		return basePower;
	}
	private float CalculateDamageMultiplier(PBEBattlePokemon user, PBEBattlePokemon target, IPBEMoveData mData, PBEType moveType, PBEResult moveResult, bool criticalHit)
	{
		float damageMultiplier = 1;
		if (target.Status2.HasFlag(PBEStatus2.Airborne) && mData.Flags.HasFlag(PBEMoveFlag.DoubleDamageAirborne))
		{
			damageMultiplier *= 2.0f;
		}
		if (target.Minimize_Used && mData.Flags.HasFlag(PBEMoveFlag.DoubleDamageMinimized))
		{
			damageMultiplier *= 2.0f;
		}
		if (target.Status2.HasFlag(PBEStatus2.Underground) && mData.Flags.HasFlag(PBEMoveFlag.DoubleDamageUnderground))
		{
			damageMultiplier *= 2.0f;
		}
		if (target.Status2.HasFlag(PBEStatus2.Underwater) && mData.Flags.HasFlag(PBEMoveFlag.DoubleDamageUnderwater))
		{
			damageMultiplier *= 2.0f;
		}

		if (criticalHit)
		{
			damageMultiplier *= Settings.CritMultiplier;
			if (user.Ability == PBEAbility.Sniper)
			{
				damageMultiplier *= 1.5f;
			}
		}
		else if (user.Ability != PBEAbility.Infiltrator)
		{
			if ((target.Team.TeamStatus.HasFlag(PBETeamStatus.Reflect) && mData.Category == PBEMoveCategory.Physical)
				|| (target.Team.TeamStatus.HasFlag(PBETeamStatus.LightScreen) && mData.Category == PBEMoveCategory.Special))
			{
				if (target.Team.NumPkmnOnField == 1)
				{
					damageMultiplier *= 0.5f;
				}
				else
				{
					damageMultiplier *= 0.66f;
				}
			}
		}

		switch (moveResult)
		{
			case PBEResult.NotVeryEffective_Type:
			{
				if (user.Ability == PBEAbility.TintedLens)
				{
					damageMultiplier *= 2.0f;
				}
				break;
			}
			case PBEResult.SuperEffective_Type:
			{
				if ((target.Ability == PBEAbility.Filter || target.Ability == PBEAbility.SolidRock) && !user.HasCancellingAbility())
				{
					damageMultiplier *= 0.75f;
				}
				if (user.Item == PBEItem.ExpertBelt)
				{
					damageMultiplier *= 1.2f;
				}
				break;
			}
		}
		if (user.ReceivesSTAB(moveType))
		{
			if (user.Ability == PBEAbility.Adaptability)
			{
				damageMultiplier *= 2.0f;
			}
			else
			{
				damageMultiplier *= 1.5f;
			}
		}
		if (mData.Category == PBEMoveCategory.Physical && user.Status1 == PBEStatus1.Burned && user.Ability != PBEAbility.Guts)
		{
			damageMultiplier *= 0.5f;
		}
		if (moveType == PBEType.Fire && target.Ability == PBEAbility.Heatproof && !user.HasCancellingAbility())
		{
			damageMultiplier *= 0.5f;
		}

		return damageMultiplier;
	}

	private float CalculateAttack(PBEBattlePokemon user, PBEBattlePokemon target, PBEType moveType, float initialAttack)
	{
		float attack = initialAttack;

		if (user.Ability == PBEAbility.HugePower || user.Ability == PBEAbility.PurePower)
		{
			attack *= 2.0f;
		}
		if (user.Item == PBEItem.ThickClub && (user.OriginalSpecies == PBESpecies.Cubone || user.OriginalSpecies == PBESpecies.Marowak))
		{
			attack *= 2.0f;
		}
		if (user.Item == PBEItem.LightBall && user.OriginalSpecies == PBESpecies.Pikachu)
		{
			attack *= 2.0f;
		}
		if (moveType == PBEType.Bug && user.Ability == PBEAbility.Swarm && user.HP <= user.MaxHP / 3)
		{
			attack *= 1.5f;
		}
		if (moveType == PBEType.Fire && user.Ability == PBEAbility.Blaze && user.HP <= user.MaxHP / 3)
		{
			attack *= 1.5f;
		}
		if (moveType == PBEType.Grass && user.Ability == PBEAbility.Overgrow && user.HP <= user.MaxHP / 3)
		{
			attack *= 1.5f;
		}
		if (moveType == PBEType.Water && user.Ability == PBEAbility.Torrent && user.HP <= user.MaxHP / 3)
		{
			attack *= 1.5f;
		}
		if (user.Ability == PBEAbility.Hustle)
		{
			attack *= 1.5f;
		}
		if (user.Ability == PBEAbility.Guts && user.Status1 != PBEStatus1.None)
		{
			attack *= 1.5f;
		}
		if (user.Item == PBEItem.ChoiceBand)
		{
			attack *= 1.5f;
		}
		if (!user.HasCancellingAbility() && ShouldDoWeatherEffects() && Weather == PBEWeather.HarshSunlight && user.Team.ActiveBattlers.FindIndex(p => p.Ability == PBEAbility.FlowerGift) != -1)
		{
			attack *= 1.5f;
		}
		if ((moveType == PBEType.Fire || moveType == PBEType.Ice) && target.Ability == PBEAbility.ThickFat && !user.HasCancellingAbility())
		{
			attack *= 0.5f;
		}
		if (user.Ability == PBEAbility.Defeatist && user.HP <= user.MaxHP / 2)
		{
			attack *= 0.5f;
		}
		if (user.Ability == PBEAbility.SlowStart && user.SlowStart_HinderTurnsLeft > 0)
		{
			attack *= 0.5f;
		}

		return attack;
	}
	private static float CalculateDefense(PBEBattlePokemon user, PBEBattlePokemon target, float initialDefense)
	{
		float defense = initialDefense;

		if (target.Item == PBEItem.MetalPowder && target.OriginalSpecies == PBESpecies.Ditto && !target.Status2.HasFlag(PBEStatus2.Transformed))
		{
			defense *= 2.0f;
		}
		if (target.Ability == PBEAbility.MarvelScale && target.Status1 != PBEStatus1.None && !user.HasCancellingAbility())
		{
			defense *= 1.5f;
		}
		if (target.Item == PBEItem.Eviolite && PBEDataProvider.Instance.HasEvolutions(target.OriginalSpecies, target.RevertForm))
		{
			defense *= 1.5f;
		}

		return defense;
	}
	private float CalculateSpAttack(PBEBattlePokemon user, PBEBattlePokemon target, PBEType moveType, float initialSpAttack)
	{
		float spAttack = initialSpAttack;

		if (user.Item == PBEItem.DeepSeaTooth && user.OriginalSpecies == PBESpecies.Clamperl)
		{
			spAttack *= 2.0f;
		}
		if (user.Item == PBEItem.LightBall && user.OriginalSpecies == PBESpecies.Pikachu)
		{
			spAttack *= 2.0f;
		}
		if (moveType == PBEType.Bug && user.Ability == PBEAbility.Swarm && user.HP <= user.MaxHP / 3)
		{
			spAttack *= 1.5f;
		}
		if (moveType == PBEType.Fire && user.Ability == PBEAbility.Blaze && user.HP <= user.MaxHP / 3)
		{
			spAttack *= 1.5f;
		}
		if (moveType == PBEType.Grass && user.Ability == PBEAbility.Overgrow && user.HP <= user.MaxHP / 3)
		{
			spAttack *= 1.5f;
		}
		if (moveType == PBEType.Water && user.Ability == PBEAbility.Torrent && user.HP <= user.MaxHP / 3)
		{
			spAttack *= 1.5f;
		}
		if (ShouldDoWeatherEffects() && Weather == PBEWeather.HarshSunlight && user.Ability == PBEAbility.SolarPower)
		{
			spAttack *= 1.5f;
		}
		if (user.Item == PBEItem.SoulDew && (user.OriginalSpecies == PBESpecies.Latias || user.OriginalSpecies == PBESpecies.Latios))
		{
			spAttack *= 1.5f;
		}
		if (user.Item == PBEItem.ChoiceSpecs)
		{
			spAttack *= 1.5f;
		}
		if ((user.Ability == PBEAbility.Minus || user.Ability == PBEAbility.Plus) && user.Team.ActiveBattlers.FindIndex(p => p != user && (p.Ability == PBEAbility.Minus || p.Ability == PBEAbility.Plus)) != -1)
		{
			spAttack *= 1.5f;
		}
		if ((moveType == PBEType.Fire || moveType == PBEType.Ice) && target.Ability == PBEAbility.ThickFat && !user.HasCancellingAbility())
		{
			spAttack *= 0.5f;
		}
		if (user.Ability == PBEAbility.Defeatist && user.HP <= user.MaxHP / 2)
		{
			spAttack *= 0.5f;
		}

		return spAttack;
	}
	private float CalculateSpDefense(PBEBattlePokemon user, PBEBattlePokemon target, float initialSpDefense)
	{
		float spDefense = initialSpDefense;

		if (target.Item == PBEItem.DeepSeaScale && target.OriginalSpecies == PBESpecies.Clamperl)
		{
			spDefense *= 2.0f;
		}
		if (target.Item == PBEItem.SoulDew && (target.OriginalSpecies == PBESpecies.Latias || target.OriginalSpecies == PBESpecies.Latios))
		{
			spDefense *= 1.5f;
		}
		if (target.Item == PBEItem.Eviolite && PBEDataProvider.Instance.HasEvolutions(target.OriginalSpecies, target.RevertForm))
		{
			spDefense *= 1.5f;
		}
		if (ShouldDoWeatherEffects())
		{
			if (Weather == PBEWeather.Sandstorm && target.HasType(PBEType.Rock))
			{
				spDefense *= 1.5f;
			}
			if (!user.HasCancellingAbility() && Weather == PBEWeather.HarshSunlight && target.Team.ActiveBattlers.FindIndex(p => p.Ability == PBEAbility.FlowerGift) != -1)
			{
				spDefense *= 1.5f;
			}
		}

		return spDefense;
	}

	private int CalculateDamage(PBEBattlePokemon user, float a, float d, float basePower)
	{
		float damage;
		damage = (2 * user.Level / 5) + 2;
		damage = damage * a * basePower / d;
		damage /= 50;
		damage += 2;
		return (int)(damage * ((100f - _rand.RandomInt(0, 15)) / 100));
	}
	private int CalculateConfusionDamage(PBEBattlePokemon pkmn)
	{
		# Verified: Unaware has no effect on confusion damage
		float m = GetStatChangeModifier(pkmn.AttackChange, false);
		float a = CalculateAttack(pkmn, pkmn, PBEType.None, pkmn.Attack * m);
		m = GetStatChangeModifier(pkmn.DefenseChange, false);
		float d = CalculateDefense(pkmn, pkmn, pkmn.Defense * m);
		return CalculateDamage(pkmn, a, d, 40);
	}
	private int CalculateDamage(PBEBattlePokemon user, PBEBattlePokemon target, IPBEMoveData mData, PBEType moveType, float basePower, bool criticalHit)
	{
		PBEBattlePokemon aPkmn;
		PBEMoveCategory aCat = mData.Category, dCat;
		switch (mData.Effect)
		{
			case PBEMoveEffect.FoulPlay:
			{
				aPkmn = target;
				dCat = aCat;
				break;
			}
			case PBEMoveEffect.Psyshock:
			{
				aPkmn = user;
				dCat = PBEMoveCategory.Physical;
				break;
			}
			default:
			{
				aPkmn = user;
				dCat = aCat;
				break;
			}
		}

		bool ignoreA = user != target && target.Ability == PBEAbility.Unaware && !user.HasCancellingAbility();
		bool ignoreD = user != target && (mData.Effect == PBEMoveEffect.ChipAway || user.Ability == PBEAbility.Unaware);
		float a, d;
		if (aCat == PBEMoveCategory.Physical)
		{
			float m = ignoreA ? 1 : GetStatChangeModifier(criticalHit ? Math.Max((sbyte)0, aPkmn.AttackChange) : aPkmn.AttackChange, false);
			a = CalculateAttack(user, target, moveType, aPkmn.Attack * m);
		}
		else
		{
			float m = ignoreA ? 1 : GetStatChangeModifier(criticalHit ? Math.Max((sbyte)0, aPkmn.SpAttackChange) : aPkmn.SpAttackChange, false);
			a = CalculateSpAttack(user, target, moveType, aPkmn.SpAttack * m);
		}
		if (dCat == PBEMoveCategory.Physical)
		{
			float m = ignoreD ? 1 : GetStatChangeModifier(criticalHit ? Math.Min((sbyte)0, target.DefenseChange) : target.DefenseChange, false);
			d = CalculateDefense(user, target, target.Defense * m);
		}
		else
		{
			float m = ignoreD ? 1 : GetStatChangeModifier(criticalHit ? Math.Min((sbyte)0, target.SpDefenseChange) : target.SpDefenseChange, false);
			d = CalculateSpDefense(user, target, target.SpDefense * m);
		}

		return CalculateDamage(user, a, d, basePower);
	}
}

public sealed partial class PBEBattle
{
	public delegate void BattleEvent(PBEBattle battle, IPBEPacket packet);
	public event BattleEvent? OnNewEvent;

	private void Broadcast(IPBEPacket packet)
	{
		Events.Add(packet);
		OnNewEvent?.Invoke(this, packet);
	}

	private void BroadcastAbility(PBEBattlePokemon abilityOwner, PBEBattlePokemon pokemon2, PBEAbility ability, PBEAbilityAction abilityAction)
	{
		abilityOwner.Ability = ability;
		abilityOwner.KnownAbility = ability;
		Broadcast(new PBEAbilityPacket(abilityOwner, pokemon2, ability, abilityAction));
	}
	private void BroadcastAbilityReplaced(PBEBattlePokemon abilityOwner, PBEAbility newAbility)
	{
		PBEAbility? oldAbility = newAbility == PBEAbility.None ? null : abilityOwner.Ability; # Gastro Acid does not reveal previous ability
		abilityOwner.Ability = newAbility;
		abilityOwner.KnownAbility = newAbility;
		Broadcast(new PBEAbilityReplacedPacket(abilityOwner, oldAbility, newAbility));
	}
	private void BroadcastBattleStatus(PBEBattleStatus battleStatus, PBEBattleStatusAction battleStatusAction)
	{
		switch (battleStatusAction)
		{
			case PBEBattleStatusAction.Added: BattleStatus |= battleStatus; break;
			case PBEBattleStatusAction.Cleared:
			case PBEBattleStatusAction.Ended: BattleStatus &= ~battleStatus; break;
			default: throw new ArgumentOutOfRangeException(nameof(battleStatusAction));
		}
		Broadcast(new PBEBattleStatusPacket(battleStatus, battleStatusAction));
	}
	private void BroadcastCapture(PBEBattlePokemon pokemon, PBEItem ball, byte numShakes, bool success, bool critical)
	{
		Broadcast(new PBECapturePacket(pokemon, ball, numShakes, success, critical));
	}
	private void BroadcastFleeFailed(PBEBattlePokemon pokemon)
	{
		Broadcast(new PBEFleeFailedPacket(pokemon));
	}
	private void BroadcastHaze()
	{
		Broadcast(new PBEHazePacket());
	}
	private void BroadcastIllusion(PBEBattlePokemon pokemon)
	{
		Broadcast(new PBEIllusionPacket(pokemon));
	}
	private void BroadcastItem(PBEBattlePokemon itemHolder, PBEBattlePokemon pokemon2, PBEItem item, PBEItemAction itemAction)
	{
		switch (itemAction)
		{
			case PBEItemAction.Consumed:
			{
				itemHolder.Item = PBEItem.None;
				itemHolder.KnownItem = PBEItem.None;
				break;
			}
			default:
			{
				itemHolder.Item = item;
				itemHolder.KnownItem = item;
				break;
			}
		}
		Broadcast(new PBEItemPacket(itemHolder, pokemon2, item, itemAction));
	}
	private void BroadcastItemTurn(PBEBattlePokemon itemUser, PBEItem item, PBEItemTurnAction itemAction)
	{
		Broadcast(new PBEItemTurnPacket(itemUser, item, itemAction));
	}
	private void BroadcastMoveCrit(PBEBattlePokemon victim)
	{
		Broadcast(new PBEMoveCritPacket(victim));
	}
	private void BroadcastMoveLock_ChoiceItem(PBEBattlePokemon moveUser, PBEMove lockedMove)
	{
		moveUser.ChoiceLockedMove = lockedMove;
		Broadcast(new PBEMoveLockPacket(moveUser, PBEMoveLockType.ChoiceItem, lockedMove));
	}
	private void BroadcastMoveLock_Temporary(PBEBattlePokemon moveUser, PBEMove lockedMove, PBETurnTarget lockedTargets)
	{
		moveUser.TempLockedMove = lockedMove;
		moveUser.TempLockedTargets = lockedTargets;
		Broadcast(new PBEMoveLockPacket(moveUser, PBEMoveLockType.Temporary, lockedMove, lockedTargets));
	}
	private void BroadcastMovePPChanged(PBEBattlePokemon moveUser, PBEMove move, int amountReduced)
	{
		Broadcast(new PBEMovePPChangedPacket(moveUser, move, amountReduced));
	}
	private void BroadcastMoveResult(PBEBattlePokemon moveUser, PBEBattlePokemon pokemon2, PBEResult result)
	{
		Broadcast(new PBEMoveResultPacket(moveUser, pokemon2, result));
	}
	private void BroadcastMoveUsed(PBEBattlePokemon moveUser, PBEMove move)
	{
		bool owned;
		if (!_calledFromOtherMove && moveUser.Moves.Contains(move))
		{
			# Check if this move is known first. If you check for PBEMove.MAX then you will get multiple results
			if (!moveUser.KnownMoves.Contains(move))
			{
				moveUser.KnownMoves[PBEMove.MAX]!.Move = move;
			}
			owned = true;
		}
		else
		{
			owned = false;
		}
		Broadcast(new PBEMoveUsedPacket(moveUser, move, owned));
	}
	private void BroadcastPkmnEXPChanged(PBEBattlePokemon pokemon, uint oldEXP)
	{
		Broadcast(new PBEPkmnEXPChangedPacket(pokemon, oldEXP));
	}
	private void BroadcastPkmnEXPEarned(PBEBattlePokemon pokemon, uint earned)
	{
		Broadcast(new PBEPkmnEXPEarnedPacket(pokemon, earned));
	}
	private void BroadcastPkmnFainted(PBEBattlePokemon pokemon, PBEFieldPosition oldPosition)
	{
		Broadcast(new PBEPkmnFaintedPacket(pokemon, oldPosition));
	}
	private void BroadcastPkmnFormChanged(PBEBattlePokemon pokemon, PBEForm newForm, PBEAbility newAbility, PBEAbility newKnownAbility, bool isRevertForm)
	{
		pokemon.Ability = newAbility;
		pokemon.KnownAbility = newKnownAbility;
		pokemon.Form = newForm;
		pokemon.KnownForm = newForm;
		if (isRevertForm)
		{
			pokemon.RevertForm = newForm;
			pokemon.RevertAbility = newAbility;
		}
		# This calcs all stats and then adds/removes HP based on the new MaxHP. So if the new MaxHP was 5 more than old, the mon would gain 5 HP.
		# This is the same logic a level-up and evolution would use when HP changes.
		pokemon.SetStats(true, false);
		IPBEPokemonData pData = PBEDataProvider.Instance.GetPokemonData(pokemon.Species, newForm);
		PBEType type1 = pData.Type1;
		pokemon.Type1 = type1;
		pokemon.KnownType1 = type1;
		PBEType type2 = pData.Type2;
		pokemon.Type2 = type2;
		pokemon.KnownType2 = type2;
		float weight = pData.Weight; # TODO: Is weight updated here? Bulbapedia claims in Autotomize's page that it is not
		pokemon.Weight = weight;
		pokemon.KnownWeight = weight;
		Broadcast(new PBEPkmnFormChangedPacket(pokemon, isRevertForm));
		# BUG: PBEStatus2.PowerTrick is not cleared when changing form (meaning it can still be baton passed)
		if (Settings.BugFix && pokemon.Status2.HasFlag(PBEStatus2.PowerTrick))
		{
			BroadcastStatus2(pokemon, pokemon, PBEStatus2.PowerTrick, PBEStatusAction.Ended);
		}
	}
	private void BroadcastPkmnHPChanged(PBEBattlePokemon pokemon, ushort oldHP, float oldHPPercentage)
	{
		Broadcast(new PBEPkmnHPChangedPacket(pokemon, oldHP, oldHPPercentage));
	}
	private void BroadcastPkmnLevelChanged(PBEBattlePokemon pokemon)
	{
		Broadcast(new PBEPkmnLevelChangedPacket(pokemon));
	}
	private void BroadcastPkmnStatChanged(PBEBattlePokemon pokemon, PBEStat stat, sbyte oldValue, sbyte newValue)
	{
		Broadcast(new PBEPkmnStatChangedPacket(pokemon, stat, oldValue, newValue));
	}
	private void BroadcastPkmnSwitchIn(PBETrainer trainer, PBEPkmnAppearedInfo[] switchIns, PBEBattlePokemon? forcedByPokemon = null)
	{
		Broadcast(new PBEPkmnSwitchInPacket(trainer, switchIns, forcedByPokemon));
	}
	private void BroadcastPkmnSwitchOut(PBEBattlePokemon pokemon, PBEFieldPosition oldPosition, PBEBattlePokemon? forcedByPokemon = null)
	{
		Broadcast(new PBEPkmnSwitchOutPacket(pokemon, oldPosition, forcedByPokemon));
	}
	private void BroadcastPsychUp(PBEBattlePokemon user, PBEBattlePokemon target)
	{
		user.AttackChange = target.AttackChange;
		user.DefenseChange = target.DefenseChange;
		user.SpAttackChange = target.SpAttackChange;
		user.SpDefenseChange = target.SpDefenseChange;
		user.SpeedChange = target.SpeedChange;
		user.AccuracyChange = target.AccuracyChange;
		user.EvasionChange = target.EvasionChange;
		Broadcast(new PBEPsychUpPacket(user, target));
	}
	private void BroadcastReflectType(PBEBattlePokemon user, PBEBattlePokemon target)
	{
		user.Type1 = user.KnownType1 = target.KnownType1 = target.Type1;
		user.Type2 = user.KnownType2 = target.KnownType2 = target.Type2;
		Broadcast(new PBEReflectTypePacket(user, target));
	}

	private void BroadcastDraggedOut(PBEBattlePokemon pokemon)
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.DraggedOut, pokemon));
	}
	private void BroadcastEndure(PBEBattlePokemon pokemon)
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.Endure, pokemon));
	}
	private void BroadcastHPDrained(PBEBattlePokemon pokemon)
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.HPDrained, pokemon));
	}
	private void BroadcastMagnitude(byte magnitude)
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.Magnitude, magnitude));
	}
	private void BroadcastMultiHit(byte numHits)
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.MultiHit, numHits));
	}
	private void BroadcastNothingHappened()
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.NothingHappened));
	}
	private void BroadcastOneHitKnockout()
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.OneHitKnockout));
	}
	private void BroadcastPainSplit(PBEBattlePokemon user, PBEBattlePokemon target)
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.PainSplit, user, target));
	}
	private void BroadcastPayDay()
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.PayDay));
	}
	private void BroadcastRecoil(PBEBattlePokemon pokemon)
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.Recoil, pokemon));
	}
	private void BroadcastStruggle(PBEBattlePokemon pokemon)
	{
		Broadcast(new PBESpecialMessagePacket(PBESpecialMessage.Struggle, pokemon));
	}

	private void BroadcastStatus1(PBEBattlePokemon status1Receiver, PBEBattlePokemon pokemon2, PBEStatus1 status1, PBEStatusAction statusAction)
	{
		Broadcast(new PBEStatus1Packet(status1Receiver, pokemon2, status1, statusAction));
	}
	private void BroadcastStatus2(PBEBattlePokemon status2Receiver, PBEBattlePokemon pokemon2, PBEStatus2 status2, PBEStatusAction statusAction)
	{
		switch (statusAction)
		{
			case PBEStatusAction.Added:
			case PBEStatusAction.Announced:
			case PBEStatusAction.CausedImmobility:
			case PBEStatusAction.Damage: status2Receiver.Status2 |= status2; status2Receiver.KnownStatus2 |= status2; break;
			case PBEStatusAction.Cleared:
			case PBEStatusAction.Ended: status2Receiver.Status2 &= ~status2; status2Receiver.KnownStatus2 &= ~status2; break;
			default: throw new ArgumentOutOfRangeException(nameof(statusAction));
		}
		Broadcast(new PBEStatus2Packet(status2Receiver, pokemon2, status2, statusAction));
	}
	private void BroadcastTeamStatus(PBETeam team, PBETeamStatus teamStatus, PBETeamStatusAction teamStatusAction)
	{
		switch (teamStatusAction)
		{
			case PBETeamStatusAction.Added: team.TeamStatus |= teamStatus; break;
			case PBETeamStatusAction.Cleared:
			case PBETeamStatusAction.Ended: team.TeamStatus &= ~teamStatus; break;
			default: throw new ArgumentOutOfRangeException(nameof(teamStatusAction));
		}
		Broadcast(new PBETeamStatusPacket(team, teamStatus, teamStatusAction));
	}
	private void BroadcastTeamStatusDamage(PBETeam team, PBETeamStatus teamStatus, PBEBattlePokemon damageVictim)
	{
		team.TeamStatus |= teamStatus;
		Broadcast(new PBETeamStatusDamagePacket(team, teamStatus, damageVictim));
	}
	private void BroadcastTransform(PBEBattlePokemon user, PBEBattlePokemon target)
	{
		Broadcast(new PBETransformPacket(user, target));
	}
	private void BroadcastTypeChanged(PBEBattlePokemon pokemon, PBEType type1, PBEType type2)
	{
		pokemon.Type1 = type1;
		pokemon.KnownType1 = type1;
		pokemon.Type2 = type2;
		pokemon.KnownType2 = type2;
		Broadcast(new PBETypeChangedPacket(pokemon, type1, type2));
	}
	private void BroadcastWeather(PBEWeather weather, PBEWeatherAction weatherAction)
	{
		Broadcast(new PBEWeatherPacket(weather, weatherAction));
	}
	private void BroadcastWeatherDamage(PBEWeather weather, PBEBattlePokemon damageVictim)
	{
		Broadcast(new PBEWeatherDamagePacket(weather, damageVictim));
	}
	private void BroadcastWildPkmnAppeared(PBEPkmnAppearedInfo[] appearances)
	{
		Broadcast(new PBEWildPkmnAppearedPacket(appearances));
	}
	private void BroadcastActionsRequest(PBETrainer trainer)
	{
		Broadcast(new PBEActionsRequestPacket(trainer));
	}
	private void BroadcastAutoCenter(PBEBattlePokemon pokemon0, PBEFieldPosition pokemon0OldPosition, PBEBattlePokemon pokemon1, PBEFieldPosition pokemon1OldPosition)
	{
		Broadcast(new PBEAutoCenterPacket(pokemon0, pokemon0OldPosition, pokemon1, pokemon1OldPosition));
	}
	private void BroadcastBattle()
	{
		Broadcast(new PBEBattlePacket(this));
	}
	private void BroadcastBattleResult(PBEBattleResult r)
	{
		Broadcast(new PBEBattleResultPacket(r));
	}
	private void BroadcastSwitchInRequest(PBETrainer trainer)
	{
		Broadcast(new PBESwitchInRequestPacket(trainer));
	}
	private void BroadcastTurnBegan()
	{
		Broadcast(new PBETurnBeganPacket(TurnNumber));
	}

	public static string? GetDefaultMessage(PBEBattle battle, IPBEPacket packet, bool showRawHP = false, PBETrainer? userTrainer = null,
		Func<PBEBattlePokemon, bool, string>? pkmnNameFunc = null, Func<PBETrainer, string>? trainerNameFunc = null, Func<PBETeam, bool, string>? teamNameFunc = null)
	{
		# This is not used by switching in or out or wild Pokémon appearing; those always use the known nickname
		string GetPkmnName(PBEBattlePokemon pkmn, bool firstLetterCapitalized)
		{
			if (pkmnNameFunc is not null)
			{
				return pkmnNameFunc(pkmn, firstLetterCapitalized);
			}
			if (pkmn.IsWild)
			{
				string wildPrefix = firstLetterCapitalized ? "The wild " : "the wild ";
				return wildPrefix + pkmn.KnownNickname;
			}
			# Replay/spectator always see prefix, but if you're battling a multi-battle, your Pokémon should still have no prefix
			if (userTrainer is null || (pkmn.Trainer != userTrainer && pkmn.Team.Trainers.Count > 1))
			{
				return $"{GetTrainerName(pkmn.Trainer)}'s {pkmn.KnownNickname}";
			}
			string ownerPrefix = string.Empty;
			string foePrefix = firstLetterCapitalized ? "The foe's " : "the foe's ";
			string prefix = pkmn.Trainer == userTrainer ? ownerPrefix : foePrefix;
			return prefix + pkmn.KnownNickname;
		}
		string GetTrainerName(PBETrainer trainer)
		{
			if (trainerNameFunc is not null)
			{
				return trainerNameFunc(trainer);
			}
			return trainer.Name;
		}
		string GetRawCombinedName(PBETeam team, bool firstLetterCapitalized)
		{
			if (team.IsWild)
			{
				string prefix = firstLetterCapitalized ? "The" : "the";
				return prefix + " wild Pokémon";
			}
			return team.CombinedName;
		}
		# This is not used by PBEBattleResultPacket; those use GetRawCombinedName()
		string GetTeamName(PBETeam team, bool firstLetterCapitalized)
		{
			if (teamNameFunc is not null)
			{
				return teamNameFunc(team, firstLetterCapitalized);
			}
			if (userTrainer is null)
			{
				return $"{GetRawCombinedName(team, firstLetterCapitalized)}'s";
			}
			string ownerPrefix = firstLetterCapitalized ? "Your" : "your";
			string foePrefix = firstLetterCapitalized ? "The opposing" : "the opposing";
			return team == userTrainer.Team ? ownerPrefix : foePrefix;
		}
		string DoHiddenHP(PBEBattlePokemon pokemon, float percentageChange, float absPercentageChange)
		{
			return string.Format("{0} {1} {2:P2} of its HP!", GetPkmnName(pokemon, true), percentageChange <= 0 ? "lost" : "restored", absPercentageChange);
		}

		switch (packet)
		{
			case PBEAbilityPacket ap:
			{
				PBEBattlePokemon abilityOwner = ap.AbilityOwnerTrainer.GetPokemon(ap.AbilityOwner);
				PBEBattlePokemon pokemon2 = ap.AbilityOwnerTrainer.GetPokemon(ap.Pokemon2);
				bool abilityOwnerCaps = true,
							pokemon2Caps = true;
				string message;
				switch (ap.Ability)
				{
					case PBEAbility.AirLock:
					case PBEAbility.CloudNine:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Weather: message = "{0}'s {2} causes the effects of weather to disappear!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.Anticipation:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Announced: message = "{0}'s {2} made it shudder!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.BadDreams:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Damage: message = "{1} is tormented by {0}'s {2}!"; abilityOwnerCaps = false; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.BigPecks:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Stats: message = $"{{0}}'s {PBEDataProvider.Instance.GetStatName(PBEStat.Defense).English} was not lowered!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.ClearBody:
					case PBEAbility.WhiteSmoke:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Stats: message = "{0}'s {2} prevents stat reduction!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.ColorChange:
					case PBEAbility.FlowerGift:
					case PBEAbility.Forecast:
					case PBEAbility.Imposter:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.ChangedAppearance: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.CuteCharm:
					case PBEAbility.EffectSpore:
					case PBEAbility.FlameBody:
					case PBEAbility.Healer:
					case PBEAbility.PoisonPoint:
					case PBEAbility.ShedSkin:
					case PBEAbility.Static:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.ChangedStatus: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.Download:
					case PBEAbility.Intimidate:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Stats: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.Drizzle:
					case PBEAbility.Drought:
					case PBEAbility.SandStream:
					case PBEAbility.SnowWarning:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Weather: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.HyperCutter:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Stats: message = $"{{0}}'s {PBEDataProvider.Instance.GetStatName(PBEStat.Attack).English} was not lowered!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.IceBody:
					case PBEAbility.PoisonHeal:
					case PBEAbility.RainDish:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.RestoredHP: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.Illusion:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.ChangedAppearance: goto bottom;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
					}
					case PBEAbility.Immunity:
					case PBEAbility.Insomnia:
					case PBEAbility.Limber:
					case PBEAbility.MagmaArmor:
					case PBEAbility.Oblivious:
					case PBEAbility.OwnTempo:
					case PBEAbility.VitalSpirit:
					case PBEAbility.WaterVeil:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.ChangedStatus:
							case PBEAbilityAction.PreventedStatus: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.IronBarbs:
					case PBEAbility.Justified:
					case PBEAbility.Levitate:
					case PBEAbility.Mummy:
					case PBEAbility.Rattled:
					case PBEAbility.RoughSkin:
					case PBEAbility.SolarPower:
					case PBEAbility.Sturdy:
					case PBEAbility.WeakArmor:
					case PBEAbility.WonderGuard:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Damage: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.KeenEye:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Stats: message = $"{{0}}'s {PBEDataProvider.Instance.GetStatName(PBEStat.Accuracy).English} was not lowered!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.LeafGuard:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.PreventedStatus: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.LiquidOoze:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Damage: message = "{1} sucked up the liquid ooze!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.MoldBreaker:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Announced: message = "{0} breaks the mold!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.Moody:
					case PBEAbility.SpeedBoost:
					case PBEAbility.Steadfast:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Stats: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.RunAway:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Announced: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.SlowStart:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Announced: message = "{0} can't get it going!"; break;
							case PBEAbilityAction.SlowStart_Ended: message = "{0} finally got its act together!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.Teravolt:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Announced: message = "{0} is radiating a bursting aura!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					case PBEAbility.Turboblaze:
					{
						switch (ap.AbilityAction)
						{
							case PBEAbilityAction.Announced: message = "{0} is radiating a blazing aura!"; break;
							default: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					default: throw new InvalidDataException(nameof(ap.Ability));
				}
				return string.Format(message, GetPkmnName(abilityOwner, abilityOwnerCaps), GetPkmnName(pokemon2, pokemon2Caps), PBEDataProvider.Instance.GetAbilityName(ap.Ability).English);
			}
			case PBEAbilityReplacedPacket arp:
			{
				PBEBattlePokemon abilityOwner = arp.AbilityOwnerTrainer.GetPokemon(arp.AbilityOwner);
				string message;
				switch (arp.NewAbility)
				{
					case PBEAbility.None: message = "{0}'s {1} was suppressed!"; break;
					default: message = "{0}'s {1} was changed to {2}!"; break;
				}
				return string.Format(message,
					GetPkmnName(abilityOwner, true),
					arp.OldAbility is null ? "Ability" : PBEDataProvider.Instance.GetAbilityName(arp.OldAbility.Value).English,
					PBEDataProvider.Instance.GetAbilityName(arp.NewAbility).English);
			}
			case PBEBattleStatusPacket bsp:
			{
				string message;
				switch (bsp.BattleStatus)
				{
					case PBEBattleStatus.TrickRoom:
					{
						switch (bsp.BattleStatusAction)
						{
							case PBEBattleStatusAction.Added: message = "The dimensions were twisted!"; break;
							case PBEBattleStatusAction.Cleared:
							case PBEBattleStatusAction.Ended: message = "The twisted dimensions returned to normal!"; break;
							default: throw new InvalidDataException(nameof(bsp.BattleStatusAction));
						}
						break;
					}
					default: throw new InvalidDataException(nameof(bsp.BattleStatus));
				}
				return message;
			}
			case PBECapturePacket cp:
			{
				PBEBattlePokemon pokemon = cp.PokemonTrainer.GetPokemon(cp.Pokemon);
				string ballEnglish = PBEDataProvider.Instance.GetItemName(cp.Ball).English;
				if (cp.Success)
				{
					return string.Format("Gotcha! {0} was caught with the {1} after {2} shake{3}!", pokemon.Nickname, ballEnglish, cp.NumShakes, cp.NumShakes == 1 ? string.Empty : "s");
				}
				if (cp.NumShakes == 0)
				{
					return "The Pokémon broke free without shaking!";
				}
				return string.Format("The Pokémon broke free after {0} shake{1}!", cp.NumShakes, cp.NumShakes == 1 ? string.Empty : "s");
			}
			case PBEFleeFailedPacket ffp:
			{
				string name;
				if (ffp.Pokemon == PBEFieldPosition.None)
				{
					name = GetTrainerName(ffp.PokemonTrainer);
				}
				else
				{
					PBEBattlePokemon pokemon = ffp.PokemonTrainer.GetPokemon(ffp.Pokemon);
					name = GetPkmnName(pokemon, true);
				}
				return string.Format("{0} could not get away!", name);
			}
			case PBEHazePacket _:
			{
				return "All stat changes were eliminated!";
			}
			case PBEItemPacket ip:
			{
				PBEBattlePokemon itemHolder = ip.ItemHolderTrainer.GetPokemon(ip.ItemHolder);
				PBEBattlePokemon pokemon2 = ip.Pokemon2Trainer.GetPokemon(ip.Pokemon2);
				bool itemHolderCaps = true,
							pokemon2Caps = false;
				string message;
				switch (ip.Item)
				{
					case PBEItem.AguavBerry:
					case PBEItem.BerryJuice:
					case PBEItem.FigyBerry:
					case PBEItem.IapapaBerry:
					case PBEItem.MagoBerry:
					case PBEItem.OranBerry:
					case PBEItem.SitrusBerry:
					case PBEItem.WikiBerry:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Consumed: message = "{0} restored its health using its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.ApicotBerry:
					case PBEItem.GanlonBerry:
					case PBEItem.LiechiBerry:
					case PBEItem.PetayaBerry:
					case PBEItem.SalacBerry:
					case PBEItem.StarfBerry:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Consumed: message = "{0} used its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.BugGem:
					case PBEItem.DarkGem:
					case PBEItem.DragonGem:
					case PBEItem.ElectricGem:
					case PBEItem.FightingGem:
					case PBEItem.FireGem:
					case PBEItem.FlyingGem:
					case PBEItem.GhostGem:
					case PBEItem.GrassGem:
					case PBEItem.GroundGem:
					case PBEItem.IceGem:
					case PBEItem.NormalGem:
					case PBEItem.PoisonGem:
					case PBEItem.PsychicGem:
					case PBEItem.RockGem:
					case PBEItem.SteelGem:
					case PBEItem.WaterGem:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Consumed: message = "The {2} strengthened {0}'s power!"; itemHolderCaps = false; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.BlackSludge:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Damage: message = "{0} is hurt by its {2}!"; break;
							case PBEItemAction.RestoredHP: message = "{0} restored a little HP using its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.DestinyKnot:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Announced: message = "{0}'s {2} activated!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.FlameOrb:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Announced: message = "{0} was burned by its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.FocusBand:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Damage: message = "{0} hung on using its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.FocusSash:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Consumed: message = "{0} hung on using its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.Leftovers:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.RestoredHP: message = "{0} restored a little HP using its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.LifeOrb:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Damage: message = "{0} is hurt by its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.PowerHerb:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Consumed: message = "{0} became fully charged due to its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.RockyHelmet:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Damage: message = "{1} was hurt by the {2}!"; pokemon2Caps = true; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.SmokeBall:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Announced: message = "{0} used its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					case PBEItem.ToxicOrb:
					{
						switch (ip.ItemAction)
						{
							case PBEItemAction.Announced: message = "{0} was badly poisoned by its {2}!"; break;
							default: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					default: throw new InvalidDataException(nameof(ip.Item));
				}
				return string.Format(message, GetPkmnName(itemHolder, itemHolderCaps), GetPkmnName(pokemon2, pokemon2Caps), PBEDataProvider.Instance.GetItemName(ip.Item).English);
			}
			case PBEItemTurnPacket itp:
			{
				PBEBattlePokemon itemUser = itp.ItemUserTrainer.GetPokemon(itp.ItemUser);
				string itemEnglish = PBEDataProvider.Instance.GetItemName(itp.Item).English;
				switch (itp.ItemAction)
				{
					case PBEItemTurnAction.Attempt:
					{
						string word;
						if (PBEDataUtils.AllBalls.Contains(itp.Item))
						{
							word = "threw";
						}
						else
						{
							word = "used";
						}
						return string.Format("{0} {1} the {2}.", GetTrainerName(itemUser.Trainer), word, itemEnglish);
					}
					case PBEItemTurnAction.NoEffect:
					{
						if (PBEDataUtils.AllBalls.Contains(itp.Item))
						{
							return "The trainer blocked the ball! Don't be a thief!";
						}
						return string.Format("The {0} had no effect.", itemEnglish);
					}
					case PBEItemTurnAction.Success:
					{
						#string message;
						switch (itp.Item)
						{
							# No "success" items yet
							default: throw new InvalidDataException(nameof(itp.Item));
						}
						#return string.Format(message, GetPkmnName(itemUser, true), itemEnglish);
					}
					default: throw new InvalidDataException(nameof(itp.ItemAction));
				}
			}
			case PBEMoveCritPacket mcp:
			{
				PBEBattlePokemon victim = mcp.VictimTrainer.GetPokemon(mcp.Victim);
				return string.Format("A critical hit on {0}!", GetPkmnName(victim, false));
			}
			case PBEMovePPChangedPacket mpcp:
			{
				PBEBattlePokemon moveUser = mpcp.MoveUserTrainer.GetPokemon(mpcp.MoveUser);
				return string.Format("{0}'s {1} {3} {2} PP!",
					GetPkmnName(moveUser, true),
					PBEDataProvider.Instance.GetMoveName(mpcp.Move).English,
					Math.Abs(mpcp.AmountReduced),
					mpcp.AmountReduced >= 0 ? "lost" : "gained");
			}
			case PBEMoveResultPacket mrp:
			{
				PBEBattlePokemon moveUser = mrp.MoveUserTrainer.GetPokemon(mrp.MoveUser);
				PBEBattlePokemon pokemon2 = mrp.Pokemon2Trainer.GetPokemon(mrp.Pokemon2);
				bool pokemon2Caps = true;
				string message;
				switch (mrp.Result)
				{
					case PBEResult.Ineffective_Ability: message = "{1} is protected by its Ability!"; break;
					case PBEResult.Ineffective_Gender: message = "It doesn't affect {1}..."; pokemon2Caps = false; break;
					case PBEResult.Ineffective_Level: message = "{1} is protected by its level!"; break;
					case PBEResult.Ineffective_MagnetRise: message = $"{{1}} is protected by {PBEDataProvider.Instance.GetMoveName(PBEMove.MagnetRise).English}!"; break;
					case PBEResult.Ineffective_Safeguard: message = $"{{1}} is protected by {PBEDataProvider.Instance.GetMoveName(PBEMove.Safeguard).English}!"; break;
					case PBEResult.Ineffective_Stat:
					case PBEResult.Ineffective_Status:
					case PBEResult.InvalidConditions: message = "But it failed!"; break;
					case PBEResult.Ineffective_Substitute: message = $"{{1}} is protected by {PBEDataProvider.Instance.GetMoveName(PBEMove.Substitute).English}!"; break;
					case PBEResult.Ineffective_Type: message = "{1} is protected by its Type!"; break;
					case PBEResult.Missed: message = "{0}'s attack missed {1}!"; pokemon2Caps = false; break;
					case PBEResult.NoTarget: message = "But there was no target..."; break;
					case PBEResult.NotVeryEffective_Type: message = "It's not very effective on {1}..."; pokemon2Caps = false; break;
					case PBEResult.SuperEffective_Type: message = "It's super effective on {1}!"; pokemon2Caps = false; break;
					default: throw new InvalidDataException(nameof(mrp.Result));
				}
				return string.Format(message, GetPkmnName(moveUser, true), GetPkmnName(pokemon2, pokemon2Caps));
			}
			case PBEMoveUsedPacket mup:
			{
				PBEBattlePokemon moveUser = mup.MoveUserTrainer.GetPokemon(mup.MoveUser);
				return string.Format("{0} used {1}!", GetPkmnName(moveUser, true), PBEDataProvider.Instance.GetMoveName(mup.Move).English);
			}
			case PBEPkmnFaintedPacket pfp:
			{
				PBEBattlePokemon pokemon = pfp.PokemonTrainer.GetPokemon(pfp.Pokemon);
				return string.Format("{0} fainted!", GetPkmnName(pokemon, true));
			}
			case PBEPkmnEXPEarnedPacket peep:
			{
				PBEBattlePokemon pokemon = peep.PokemonTrainer.GetPokemon(peep.Pokemon);
				return string.Format("{0} earned {1} EXP point(s)!", GetPkmnName(pokemon, true), peep.Earned);
			}
			case PBEPkmnFaintedPacket_Hidden pfph:
			{
				PBEBattlePokemon pokemon = pfph.PokemonTrainer.GetPokemon(pfph.OldPosition);
				return string.Format("{0} fainted!", GetPkmnName(pokemon, true));
			}
			case IPBEPkmnFormChangedPacket pfcp:
			{
				PBEBattlePokemon pokemon = pfcp.PokemonTrainer.GetPokemon(pfcp.Pokemon);
				return string.Format("{0}'s new form is {1}!", GetPkmnName(pokemon, true), PBEDataProvider.Instance.GetFormName(pokemon.Species, pfcp.NewForm).English);
			}
			case PBEPkmnHPChangedPacket phcp:
			{
				PBEBattlePokemon pokemon = phcp.PokemonTrainer.GetPokemon(phcp.Pokemon);
				float percentageChange = phcp.NewHPPercentage - phcp.OldHPPercentage;
				float absPercentageChange = Math.Abs(percentageChange);
				if (showRawHP || userTrainer == pokemon.Trainer) # Owner should see raw values
				{
					int change = phcp.NewHP - phcp.OldHP;
					int absChange = Math.Abs(change);
					return string.Format("{0} {1} {2} ({3:P2}) HP!", GetPkmnName(pokemon, true), change <= 0 ? "lost" : "restored", absChange, absPercentageChange);
				}
				return DoHiddenHP(pokemon, percentageChange, absPercentageChange);
			}
			case PBEPkmnHPChangedPacket_Hidden phcph:
			{
				PBEBattlePokemon pokemon = phcph.PokemonTrainer.GetPokemon(phcph.Pokemon);
				float percentageChange = phcph.NewHPPercentage - phcph.OldHPPercentage;
				float absPercentageChange = Math.Abs(percentageChange);
				return DoHiddenHP(pokemon, percentageChange, absPercentageChange);
			}
			case PBEPkmnLevelChangedPacket plcp:
			{
				PBEBattlePokemon pokemon = plcp.PokemonTrainer.GetPokemon(plcp.Pokemon);
				return string.Format("{0} grew to level {1}!", GetPkmnName(pokemon, true), plcp.NewLevel);
			}
			case PBEPkmnStatChangedPacket pscp:
			{
				PBEBattlePokemon pokemon = pscp.PokemonTrainer.GetPokemon(pscp.Pokemon);
				string statName, message;
				switch (pscp.Stat)
				{
					case PBEStat.Accuracy: statName = "Accuracy"; break;
					case PBEStat.Attack: statName = "Attack"; break;
					case PBEStat.Defense: statName = "Defense"; break;
					case PBEStat.Evasion: statName = "Evasion"; break;
					case PBEStat.SpAttack: statName = "Special Attack"; break;
					case PBEStat.SpDefense: statName = "Special Defense"; break;
					case PBEStat.Speed: statName = "Speed"; break;
					default: throw new InvalidDataException(nameof(pscp.Stat));
				}
				int change = pscp.NewValue - pscp.OldValue;
				switch (change)
				{
					case -2: message = "harshly fell"; break;
					case -1: message = "fell"; break;
					case +1: message = "rose"; break;
					case +2: message = "rose sharply"; break;
					default:
					{
						if (change == 0 && pscp.NewValue == -battle.Settings.MaxStatChange)
						{
							message = "won't go lower";
						}
						else if (change == 0 && pscp.NewValue == battle.Settings.MaxStatChange)
						{
							message = "won't go higher";
						}
						else if (change <= -3)
						{
							message = "severely fell";
						}
						else if (change >= +3)
						{
							message = "rose drastically";
						}
						else
						{
							throw new Exception();
						}
						break;
					}
				}
				return string.Format("{0}'s {1} {2}!", GetPkmnName(pokemon, true), statName, message);
			}
			case IPBEPkmnSwitchInPacket psip:
			{
				if (!psip.Forced)
				{
					return string.Format("{1} sent out {0}!", psip.SwitchIns.Select(s => s.Nickname).ToArray().Andify(), GetTrainerName(psip.Trainer));
				}
				goto bottom;
			}
			case PBEPkmnSwitchOutPacket psop:
			{
				if (!psop.Forced)
				{
					PBEBattlePokemon pokemon = psop.PokemonTrainer.GetPokemon(psop.Pokemon);
					return string.Format("{1} withdrew {0}!", pokemon.KnownNickname, GetTrainerName(psop.PokemonTrainer));
				}
				goto bottom;
			}
			case PBEPkmnSwitchOutPacket_Hidden psoph:
			{
				if (!psoph.Forced)
				{
					PBEBattlePokemon pokemon = psoph.PokemonTrainer.GetPokemon(psoph.OldPosition);
					return string.Format("{1} withdrew {0}!", pokemon.KnownNickname, GetTrainerName(psoph.PokemonTrainer));
				}
				goto bottom;
			}
			case PBEPsychUpPacket pup:
			{
				PBEBattlePokemon user = pup.UserTrainer.GetPokemon(pup.User);
				PBEBattlePokemon target = pup.TargetTrainer.GetPokemon(pup.Target);
				return string.Format("{0} copied {1}'s stat changes!", GetPkmnName(user, true), GetPkmnName(target, false));
			}
			case PBEReflectTypePacket rtp:
			{
				PBEBattlePokemon user = rtp.UserTrainer.GetPokemon(rtp.User);
				PBEBattlePokemon target = rtp.TargetTrainer.GetPokemon(rtp.Target);
				string type1Str = PBEDataProvider.Instance.GetTypeName(rtp.Type1).English;
				return string.Format("{0} copied {1}'s {2}",
					GetPkmnName(user, true),
					GetPkmnName(target, false),
					rtp.Type2 == PBEType.None ? $"{type1Str} type!" : $"{type1Str} and {PBEDataProvider.Instance.GetTypeName(rtp.Type2).English} types!");
			}
			case PBEReflectTypePacket_Hidden rtph:
			{
				PBEBattlePokemon user = rtph.UserTrainer.GetPokemon(rtph.User);
				PBEBattlePokemon target = rtph.TargetTrainer.GetPokemon(rtph.Target);
				return string.Format("{0} copied {1}'s types!", GetPkmnName(user, true), GetPkmnName(target, false));
			}
			case PBESpecialMessagePacket smp: # TODO: Clean
			{
				string message;
				switch (smp.Message)
				{
					case PBESpecialMessage.DraggedOut: message = string.Format("{0} was dragged out!", GetPkmnName(((PBETrainer)smp.Params[0]).GetPokemon((PBEFieldPosition)smp.Params[1]), true)); break;
					case PBESpecialMessage.Endure: message = string.Format("{0} endured the hit!", GetPkmnName(((PBETrainer)smp.Params[0]).GetPokemon((PBEFieldPosition)smp.Params[1]), true)); break;
					case PBESpecialMessage.HPDrained: message = string.Format("{0} had its energy drained!", GetPkmnName(((PBETrainer)smp.Params[0]).GetPokemon((PBEFieldPosition)smp.Params[1]), true)); break;
					case PBESpecialMessage.Magnitude: message = string.Format("Magnitude {0}!", (byte)smp.Params[0]); break;
					case PBESpecialMessage.MultiHit: message = string.Format("Hit {0} time(s)!", (byte)smp.Params[0]); break;
					case PBESpecialMessage.NothingHappened: message = "But nothing happened!"; break;
					case PBESpecialMessage.OneHitKnockout: message = "It's a one-hit KO!"; break;
					case PBESpecialMessage.PainSplit: message = "The battlers shared their pain!"; break;
					case PBESpecialMessage.PayDay: message = "Coins were scattered everywhere!"; break;
					case PBESpecialMessage.Recoil: message = string.Format("{0} is damaged by recoil!", GetPkmnName(((PBETrainer)smp.Params[0]).GetPokemon((PBEFieldPosition)smp.Params[1]), true)); break;
					case PBESpecialMessage.Struggle: message = string.Format("{0} has no moves left!", GetPkmnName(((PBETrainer)smp.Params[0]).GetPokemon((PBEFieldPosition)smp.Params[1]), true)); break;
					default: throw new InvalidDataException(nameof(smp.Message));
				}
				return message;
			}
			case PBEStatus1Packet s1p:
			{
				PBEBattlePokemon status1Receiver = s1p.Status1ReceiverTrainer.GetPokemon(s1p.Status1Receiver);
				string message;
				switch (s1p.Status1)
				{
					case PBEStatus1.Asleep:
					{
						switch (s1p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} fell asleep!"; break;
							case PBEStatusAction.CausedImmobility: message = "{0} is fast asleep."; break;
							case PBEStatusAction.Cleared:
							case PBEStatusAction.Ended: message = "{0} woke up!"; break;
							default: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					case PBEStatus1.BadlyPoisoned:
					{
						switch (s1p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} was badly poisoned!"; break;
							case PBEStatusAction.Cleared: message = "{0} was cured of its poisoning."; break;
							case PBEStatusAction.Damage: message = "{0} was hurt by poison!"; break;
							default: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					case PBEStatus1.Burned:
					{
						switch (s1p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} was burned!"; break;
							case PBEStatusAction.Cleared: message = "{0}'s burn was healed."; break;
							case PBEStatusAction.Damage: message = "{0} was hurt by its burn!"; break;
							default: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					case PBEStatus1.Frozen:
					{
						switch (s1p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} was frozen solid!"; break;
							case PBEStatusAction.CausedImmobility: message = "{0} is frozen solid!"; break;
							case PBEStatusAction.Cleared:
							case PBEStatusAction.Ended: message = "{0} thawed out!"; break;
							default: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					case PBEStatus1.Paralyzed:
					{
						switch (s1p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} is paralyzed! It may be unable to move!"; break;
							case PBEStatusAction.CausedImmobility: message = "{0} is paralyzed! It can't move!"; break;
							case PBEStatusAction.Cleared: message = "{0} was cured of paralysis."; break;
							default: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					case PBEStatus1.Poisoned:
					{
						switch (s1p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} was poisoned!"; break;
							case PBEStatusAction.Cleared: message = "{0} was cured of its poisoning."; break;
							case PBEStatusAction.Damage: message = "{0} was hurt by poison!"; break;
							default: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					default: throw new InvalidDataException(nameof(s1p.Status1));
				}
				return string.Format(message, GetPkmnName(status1Receiver, true));
			}
			case PBEStatus2Packet s2p:
			{
				PBEBattlePokemon status2Receiver = s2p.Status2ReceiverTrainer.GetPokemon(s2p.Status2Receiver);
				PBEBattlePokemon pokemon2 = s2p.Pokemon2Trainer.GetPokemon(s2p.Pokemon2);
				string message;
				bool status2ReceiverCaps = true,
							pokemon2Caps = false;
				switch (s2p.Status2)
				{
					case PBEStatus2.Airborne:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} flew up high!"; break;
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Confused:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} became confused!"; break;
							case PBEStatusAction.Announced: message = "{0} is confused!"; break;
							case PBEStatusAction.Cleared:
							case PBEStatusAction.Ended: message = "{0} snapped out of its confusion."; break;
							case PBEStatusAction.Damage: message = "It hurt itself in its confusion!"; break;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Cursed:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{1} cut its own HP and laid a curse on {0}!"; status2ReceiverCaps = false; pokemon2Caps = true; break;
							case PBEStatusAction.Damage: message = "{0} is afflicted by the curse!"; break;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Disguised:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Ended: message = "{0}'s illusion wore off!"; break;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Flinching:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.CausedImmobility: message = "{0} flinched and couldn't move!"; break;
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Identified:
					case PBEStatus2.MiracleEye:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} was identified!"; break;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.HelpingHand:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{1} is ready to help {0}!"; status2ReceiverCaps = false; pokemon2Caps = true; break;
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Infatuated:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} fell in love with {1}!"; break;
							case PBEStatusAction.Announced: message = "{0} is in love with {1}!"; break;
							case PBEStatusAction.CausedImmobility: message = "{0} is immobilized by love!"; break;
							case PBEStatusAction.Cleared:
							case PBEStatusAction.Ended: message = "{0} got over its infatuation."; break;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.LeechSeed:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} was seeded!"; break;
							case PBEStatusAction.Damage: message = "{0}'s health is sapped by Leech Seed!"; break;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.LockOn:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} took aim at {1}!"; break;
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.MagnetRise:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} levitated with electromagnetism!"; break;
							case PBEStatusAction.Ended: message = "{0}'s electromagnetism wore off!"; break;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Nightmare:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} began having a nightmare!"; break;
							case PBEStatusAction.Damage: message = "{0} is locked in a nightmare!"; break;
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.PowerTrick:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} switched its Attack and Defense!"; break;
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Protected:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added:
							case PBEStatusAction.Damage: message = "{0} protected itself!"; break;
							case PBEStatusAction.Cleared: message = "{1} broke through {0}'s protection!"; status2ReceiverCaps = false; pokemon2Caps = true; break;
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Pumped:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} is getting pumped!"; break;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Roost:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added:
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
					}
					case PBEStatus2.ShadowForce:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} vanished instantly!"; break;
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Substitute:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} put in a substitute!"; break;
							case PBEStatusAction.Damage: message = "The substitute took damage for {0}!"; status2ReceiverCaps = false; break;
							case PBEStatusAction.Ended: message = "{0}'s substitute faded!"; break;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Transformed:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} transformed into {1}!"; break;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Underground:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} burrowed its way under the ground!"; break;
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					case PBEStatus2.Underwater:
					{
						switch (s2p.StatusAction)
						{
							case PBEStatusAction.Added: message = "{0} hid underwater!"; break;
							case PBEStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					default: throw new InvalidDataException(nameof(s2p.Status2));
				}
				return string.Format(message, GetPkmnName(status2Receiver, status2ReceiverCaps), GetPkmnName(pokemon2, pokemon2Caps));
			}
			case PBETeamStatusPacket tsp:
			{
				string message;
				bool teamCaps = true;
				switch (tsp.TeamStatus)
				{
					case PBETeamStatus.LightScreen:
					{
						switch (tsp.TeamStatusAction)
						{
							case PBETeamStatusAction.Added: message = "Light Screen raised {0} team's Special Defense!"; teamCaps = false; break;
							case PBETeamStatusAction.Cleared:
							case PBETeamStatusAction.Ended: message = "{0} team's Light Screen wore off!"; break;
							default: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					case PBETeamStatus.LuckyChant:
					{
						switch (tsp.TeamStatusAction)
						{
							case PBETeamStatusAction.Added: message = "The Lucky Chant shielded {0} team from critical hits!"; teamCaps = false; break;
							case PBETeamStatusAction.Ended: message = "{0} team's Lucky Chant wore off!"; break;
							default: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					case PBETeamStatus.QuickGuard:
					{
						switch (tsp.TeamStatusAction)
						{
							case PBETeamStatusAction.Added: message = "Quick Guard protected {0} team!"; teamCaps = false; break;
							case PBETeamStatusAction.Cleared: message = "{0} team's Quick Guard was destroyed!"; break;
							case PBETeamStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					case PBETeamStatus.Reflect:
					{
						switch (tsp.TeamStatusAction)
						{
							case PBETeamStatusAction.Added: message = "Reflect raised {0} team's Defense!"; teamCaps = false; break;
							case PBETeamStatusAction.Cleared:
							case PBETeamStatusAction.Ended: message = "{0} team's Reflect wore off!"; break;
							default: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					case PBETeamStatus.Safeguard:
					{
						switch (tsp.TeamStatusAction)
						{
							case PBETeamStatusAction.Added: message = "{0} team became cloaked in a mystical veil!"; break;
							case PBETeamStatusAction.Ended: message = "{0} team is no longer protected by Safeguard!"; break;
							default: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					case PBETeamStatus.Spikes:
					{
						switch (tsp.TeamStatusAction)
						{
							case PBETeamStatusAction.Added: message = "Spikes were scattered all around the feet of {0} team!"; teamCaps = false; break;
							#case PBETeamStatusAction.Cleared: message = "The spikes disappeared from around {0} team's feet!"; teamCaps = false; break;
							default: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					case PBETeamStatus.StealthRock:
					{
						switch (tsp.TeamStatusAction)
						{
							case PBETeamStatusAction.Added: message = "Pointed stones float in the air around {0} team!"; teamCaps = false; break;
							#case PBETeamStatusAction.Cleared: message = "The pointed stones disappeared from around {0} team!"; teamCaps = false; break;
							default: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					case PBETeamStatus.Tailwind:
					{
						switch (tsp.TeamStatusAction)
						{
							case PBETeamStatusAction.Added: message = "The tailwind blew from behind {0} team!"; teamCaps = false; break;
							case PBETeamStatusAction.Ended: message = "{0} team's tailwind petered out!"; break;
							default: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					case PBETeamStatus.ToxicSpikes:
					{
						switch (tsp.TeamStatusAction)
						{
							case PBETeamStatusAction.Added: message = "Poison spikes were scattered all around {0} team's feet!"; break;
							case PBETeamStatusAction.Cleared: message = "The poison spikes disappeared from around {0} team's feet!"; break;
							default: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					case PBETeamStatus.WideGuard:
					{
						switch (tsp.TeamStatusAction)
						{
							case PBETeamStatusAction.Added: message = "Wide Guard protected {0} team!"; break;
							case PBETeamStatusAction.Cleared: message = "{0} team's Wide Guard was destroyed!"; break;
							case PBETeamStatusAction.Ended: goto bottom;
							default: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					default: throw new InvalidDataException(nameof(tsp.TeamStatus));
				}
				return string.Format(message, GetTeamName(tsp.Team, teamCaps));
			}
			case PBETeamStatusDamagePacket tsdp:
			{
				PBEBattlePokemon damageVictim = tsdp.DamageVictimTrainer.GetPokemon(tsdp.DamageVictim);
				string message;
				bool damageVictimCaps = false;
				switch (tsdp.TeamStatus)
				{
					case PBETeamStatus.QuickGuard: message = "Quick Guard protected {0}!"; break;
					case PBETeamStatus.Spikes: message = "{0} is hurt by the spikes!"; damageVictimCaps = true; break;
					case PBETeamStatus.StealthRock: message = "Pointed stones dug into {0}!"; break;
					case PBETeamStatus.WideGuard: message = "Wide Guard protected {0}!"; break;
					default: throw new InvalidDataException(nameof(tsdp.TeamStatus));
				}
				return string.Format(message, GetPkmnName(damageVictim, damageVictimCaps));
			}
			case PBETypeChangedPacket tcp:
			{
				PBEBattlePokemon pokemon = tcp.PokemonTrainer.GetPokemon(tcp.Pokemon);
				string type1Str = PBEDataProvider.Instance.GetTypeName(tcp.Type1).English;
				return string.Format("{0} transformed into the {1}",
					GetPkmnName(pokemon, true),
					tcp.Type2 == PBEType.None ? $"{type1Str} type!" : $"{type1Str} and {PBEDataProvider.Instance.GetTypeName(tcp.Type2).English} types!");
			}
			case PBEWeatherPacket wp:
			{
				switch (wp.Weather)
				{
					case PBEWeather.Hailstorm:
					{
						switch (wp.WeatherAction)
						{
							case PBEWeatherAction.Added: return "It started to hail!";
							case PBEWeatherAction.Ended: return "The hail stopped.";
							default: throw new InvalidDataException(nameof(wp.WeatherAction));
						}
					}
					case PBEWeather.HarshSunlight:
					{
						switch (wp.WeatherAction)
						{
							case PBEWeatherAction.Added: return "The sunlight turned harsh!";
							case PBEWeatherAction.Ended: return "The sunlight faded.";
							default: throw new InvalidDataException(nameof(wp.WeatherAction));
						}
					}
					case PBEWeather.Rain:
					{
						switch (wp.WeatherAction)
						{
							case PBEWeatherAction.Added: return "It started to rain!";
							case PBEWeatherAction.Ended: return "The rain stopped.";
							default: throw new InvalidDataException(nameof(wp.WeatherAction));
						}
					}
					case PBEWeather.Sandstorm:
					{
						switch (wp.WeatherAction)
						{
							case PBEWeatherAction.Added: return "A sandstorm kicked up!";
							case PBEWeatherAction.Ended: return "The sandstorm subsided.";
							default: throw new InvalidDataException(nameof(wp.WeatherAction));
						}
					}
					default: throw new InvalidDataException(nameof(wp.Weather));
				}
			}
			case PBEWeatherDamagePacket wdp:
			{
				PBEBattlePokemon damageVictim = wdp.DamageVictimTrainer.GetPokemon(wdp.DamageVictim);
				string message;
				switch (wdp.Weather)
				{
					case PBEWeather.Hailstorm: message = "{0} is buffeted by the hail!"; break;
					case PBEWeather.Sandstorm: message = "{0} is buffeted by the sandstorm!"; break;
					default: throw new InvalidDataException(nameof(wdp.Weather));
				}
				return string.Format(message, GetPkmnName(damageVictim, true));
			}
			case IPBEWildPkmnAppearedPacket wpap:
			{
				return string.Format("{0}{1} appeared!", wpap.Pokemon.Count == 1 ? "A wild " : "Oh! A wild ", wpap.Pokemon.Select(s => s.Nickname).ToArray().Andify());
			}
			case PBEActionsRequestPacket arp:
			{
				return string.Format("{0} must submit actions for {1} Pokémon.", GetTrainerName(arp.Trainer), arp.Pokemon.Count);
			}
			case IPBEAutoCenterPacket _:
			{
				return "The battlers shifted to the center!";
			}
			case PBEBattleResultPacket brp:
			{
				bool team0Caps = true;
				bool team1Caps = false;
				string message;
				switch (brp.BattleResult)
				{
					case PBEBattleResult.Team0Forfeit: message = "{0} forfeited."; break;
					case PBEBattleResult.Team0Win: message = "{0} defeated {1}!"; break;
					case PBEBattleResult.Team1Forfeit: message = "{1} forfeited."; team1Caps = true; break;
					case PBEBattleResult.Team1Win: message = "{1} defeated {0}!"; team0Caps = false; team1Caps = true; break;
					case PBEBattleResult.WildCapture: goto bottom;
					case PBEBattleResult.WildEscape: message = "{0} got away!"; break;
					case PBEBattleResult.WildFlee: message = "{1} got away!"; team1Caps = true; break;
					default: throw new InvalidDataException(nameof(brp.BattleResult));
				}
				return string.Format(message, GetRawCombinedName(battle.Teams[0], team0Caps), GetRawCombinedName(battle.Teams[1], team1Caps));
			}
			case PBESwitchInRequestPacket sirp:
			{
				return string.Format("{0} must send in {1} Pokémon.", GetTrainerName(sirp.Trainer), sirp.Amount);
			}
			case PBETurnBeganPacket tbp:
			{
				return string.Format("Turn {0} is starting.", tbp.TurnNumber);
			}
		}
	bottom:
		return null;
	}

	## <summary>Writes battle events to <see cref="Console.Out"/> in English.</summary>
	## <param name="battle">The battle that <paramref name="packet"/> belongs to.</param>
	## <param name="packet">The battle event packet.</param>
	## <exception cref="ArgumentNullException">Thrown when <paramref name="battle"/> or <paramref name="packet"/> are null.</exception>
	public static void ConsoleBattleEventHandler(PBEBattle battle, IPBEPacket packet)
	{
		string? message = GetDefaultMessage(battle, packet, showRawHP: true);
		if (string.IsNullOrEmpty(message))
		{
			return;
		}
		Console.WriteLine(message);
	}
}

public sealed partial class PBEBattle
{
	private const ushort CUR_REPLAY_VERSION = 0;

	public string GetDefaultReplayFileName()
	{
		# "2020-12-30 23-59-59 - Team 1 vs Team 2.pbereplay"
		return PBEUtils.ToSafeFileName(new string(string.Format("{0:yyyy-MM-dd HH-mm-ss} - {1} vs {2}", DateTime.Now, Teams[0].CombinedName, Teams[1].CombinedName).Take(200).ToArray())) + ".pbereplay";
	}
	private void CheckCanSaveReplay()
	{
		if (!IsLocallyHosted)
		{
			throw new InvalidOperationException("Can only save replays of locally hosted battles");
		}
		if (_battleState != PBEBattleState.Ended)
		{
			throw new InvalidOperationException($"{nameof(BattleState)} must be {PBEBattleState.Ended} to save a replay.");
		}
	}

	public void SaveReplay()
	{
		CheckCanSaveReplay();
		SaveReplay(GetDefaultReplayFileName());
	}
	public void SaveReplayToFolder(string path)
	{
		CheckCanSaveReplay();
		SaveReplay(Path.Combine(path, GetDefaultReplayFileName()));
	}
	public void SaveReplay(string path)
	{
		CheckCanSaveReplay();

		using (var ms = new MemoryStream())
		{
			var w = new EndianBinaryWriter(ms);
			w.WriteUInt16(CUR_REPLAY_VERSION);
			w.WriteInt32(_rand.Seed);

			int numEvents = Events.Count;
			w.WriteInt32(numEvents);
			for (int i = 0; i < numEvents; i++)
			{
				byte[] data = Events[i].Data.ToArray();
				w.WriteUInt16((ushort)data.Length);
				w.WriteBytes(data);
			}

			ms.Position = 0;
			w.WriteBytes(MD5.HashData(ms));

			File.WriteAllBytes(path, ms.ToArray());
		}
	}

	public static PBEBattle LoadReplay(string path, PBEPacketProcessor packetProcessor)
	{
		byte[] fileBytes = File.ReadAllBytes(path);
		using (var s = new MemoryStream(fileBytes))
		{
			var r = new EndianBinaryReader(s);

			byte[] hash;
			hash = MD5.HashData(fileBytes.AsSpan(0, fileBytes.Length - 16));
			for (int i = 0; i < 16; i++)
			{
				if (hash[i] != fileBytes[fileBytes.Length - 16 + i])
				{
					throw new InvalidDataException();
				}
			}
			ushort version = r.ReadUInt16(); # Unused for now
			int seed = r.ReadInt32(); # Unused for now
			PBEBattle b = null!; # The first packet should be a PBEBattlePacket
			int numEvents = r.ReadInt32();
			if (numEvents < 1)
			{
				throw new InvalidDataException();
			}
			for (int i = 0; i < numEvents; i++)
			{
				byte[] data = new byte[r.ReadUInt16()];
				r.ReadBytes(data);
				IPBEPacket packet = packetProcessor.CreatePacket(data, b);
				if (packet is PBEBattlePacket bp)
				{
					if (i != 0)
					{
						throw new InvalidDataException();
					}
					b = new PBEBattle(bp);
				}
				else
				{
					if (i == 0)
					{
						throw new InvalidDataException();
					}
					if (packet is PBEWildPkmnAppearedPacket wpap)
					{
						PBETrainer wildTrainer = b.Teams[1].Trainers[0];
						foreach (PBEPkmnAppearedInfo info in wpap.Pokemon)
						{
							PBEBattlePokemon pkmn = wildTrainer.GetPokemon(info.Pokemon);
							# Process disguise and position now
							pkmn.FieldPosition = info.FieldPosition;
							if (info.IsDisguised)
							{
								pkmn.Status2 |= PBEStatus2.Disguised;
								pkmn.KnownCaughtBall = info.CaughtBall;
								pkmn.KnownGender = info.Gender;
								pkmn.KnownNickname = info.Nickname;
								pkmn.KnownShiny = info.Shiny;
								pkmn.KnownSpecies = info.Species;
								pkmn.KnownForm = info.Form;
								IPBEPokemonData pData = PBEDataProvider.Instance.GetPokemonData(info);
								pkmn.KnownType1 = pData.Type1;
								pkmn.KnownType2 = pData.Type2;
							}
							b.ActiveBattlers.Add(pkmn);
						}
					}
					b.Events.Add(packet);
				}
			}
			b.BattleState = PBEBattleState.Ended;
			return b;
		}
	}
}

public sealed partial class PBEBattle
{
	## <summary>Gets the position across from the inputted position for a specific battle format.</summary>
	## <param name="battleFormat">The battle format.</param>
	## <param name="position">The position.</param>
	## <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="battleFormat"/> is invalid or <paramref name="position"/> is invalid for <paramref name="battleFormat"/>.</exception>
	public static PBEFieldPosition GetPositionAcross(PBEBattleFormat battleFormat, PBEFieldPosition position)
	{
		switch (battleFormat)
		{
			case PBEBattleFormat.Single:
			case PBEBattleFormat.Rotation:
			{
				if (position == PBEFieldPosition.Center)
				{
					return PBEFieldPosition.Center;
				}
				else
				{
					throw new ArgumentOutOfRangeException(nameof(position));
				}
			}
			case PBEBattleFormat.Double:
			{
				if (position == PBEFieldPosition.Left)
				{
					return PBEFieldPosition.Right;
				}
				else if (position == PBEFieldPosition.Right)
				{
					return PBEFieldPosition.Left;
				}
				else
				{
					throw new ArgumentOutOfRangeException(nameof(position));
				}
			}
			case PBEBattleFormat.Triple:
			{
				if (position == PBEFieldPosition.Left)
				{
					return PBEFieldPosition.Right;
				}
				else if (position == PBEFieldPosition.Center)
				{
					return PBEFieldPosition.Center;
				}
				else if (position == PBEFieldPosition.Right)
				{
					return PBEFieldPosition.Left;
				}
				else
				{
					throw new ArgumentOutOfRangeException(nameof(position));
				}
			}
			default: throw new ArgumentOutOfRangeException(nameof(battleFormat));
		}
	}

	## <summary>Gets the Pokémon surrounding <paramref name="pkmn"/>.</summary>
	## <param name="pkmn">The Pokémon to check.</param>
	## <param name="includeAllies">True if allies should be included, False otherwise.</param>
	## <param name="includeFoes">True if foes should be included, False otherwise.</param>
	## <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="pkmn"/>'s <see cref="PBEBattle"/>'s <see cref="BattleFormat"/> is invalid or <paramref name="pkmn"/>'s <see cref="PBEBattlePokemon.FieldPosition"/> is invalid for <paramref name="pkmn"/>'s <see cref="PBEBattle"/>'s <see cref="BattleFormat"/>.</exception>
	public static IReadOnlyList<PBEBattlePokemon> GetRuntimeSurrounding(PBEBattlePokemon pkmn, bool includeAllies, bool includeFoes)
	{
		if (!includeAllies && !includeFoes)
		{
			throw new ArgumentException($"\"{nameof(includeAllies)}\" and \"{nameof(includeFoes)}\" were false.");
		}
		List<PBEBattlePokemon> allies = pkmn.Team.ActiveBattlers.FindAll(p => p != pkmn);
		List<PBEBattlePokemon> foes = pkmn.Team.OpposingTeam.ActiveBattlers;
		switch (pkmn.Battle.BattleFormat)
		{
			case PBEBattleFormat.Single:
			{
				if (pkmn.FieldPosition == PBEFieldPosition.Center)
				{
					if (includeFoes)
					{
						return foes.FindAll(p => p.FieldPosition == PBEFieldPosition.Center);
					}
					return Array.Empty<PBEBattlePokemon>();
				}
				else
				{
					throw new InvalidDataException(nameof(pkmn.FieldPosition));
				}
			}
			case PBEBattleFormat.Double:
			{
				if (pkmn.FieldPosition == PBEFieldPosition.Left)
				{
					List<PBEBattlePokemon> ret = null!;
					if (includeAllies)
					{
						ret = allies.FindAll(p => p.FieldPosition == PBEFieldPosition.Right);
						if (!includeFoes)
						{
							return ret;
						}
					}
					if (includeFoes)
					{
						List<PBEBattlePokemon> f = foes.FindAll(p => p.FieldPosition == PBEFieldPosition.Left || p.FieldPosition == PBEFieldPosition.Right);
						if (!includeAllies)
						{
							return f;
						}
						ret.AddRange(f);
						return ret;
					}
					return Array.Empty<PBEBattlePokemon>();
				}
				else if (pkmn.FieldPosition == PBEFieldPosition.Right)
				{
					List<PBEBattlePokemon> ret = null!;
					if (includeAllies)
					{
						ret = allies.FindAll(p => p.FieldPosition == PBEFieldPosition.Left);
						if (!includeFoes)
						{
							return ret;
						}
					}
					if (includeFoes)
					{
						List<PBEBattlePokemon> f = foes.FindAll(p => p.FieldPosition == PBEFieldPosition.Left || p.FieldPosition == PBEFieldPosition.Right);
						if (!includeAllies)
						{
							return f;
						}
						ret.AddRange(f);
						return ret;
					}
					return Array.Empty<PBEBattlePokemon>();
				}
				else
				{
					throw new InvalidDataException(nameof(pkmn.FieldPosition));
				}
			}
			case PBEBattleFormat.Triple:
			case PBEBattleFormat.Rotation:
			{
				if (pkmn.FieldPosition == PBEFieldPosition.Left)
				{
					List<PBEBattlePokemon> ret = null!;
					if (includeAllies)
					{
						ret = allies.FindAll(p => p.FieldPosition == PBEFieldPosition.Center);
						if (!includeFoes)
						{
							return ret;
						}
					}
					if (includeFoes)
					{
						List<PBEBattlePokemon> f = foes.FindAll(p => p.FieldPosition == PBEFieldPosition.Center || p.FieldPosition == PBEFieldPosition.Right);
						if (!includeAllies)
						{
							return f;
						}
						ret.AddRange(f);
						return ret;
					}
					return Array.Empty<PBEBattlePokemon>();
				}
				else if (pkmn.FieldPosition == PBEFieldPosition.Center)
				{
					List<PBEBattlePokemon> ret = null!;
					if (includeAllies)
					{
						ret = allies.FindAll(p => p.FieldPosition == PBEFieldPosition.Left || p.FieldPosition == PBEFieldPosition.Right);
						if (!includeFoes)
						{
							return ret;
						}
					}
					if (includeFoes)
					{
						List<PBEBattlePokemon> f = foes.FindAll(p => p.FieldPosition == PBEFieldPosition.Left || p.FieldPosition == PBEFieldPosition.Center || p.FieldPosition == PBEFieldPosition.Right);
						if (!includeAllies)
						{
							return f;
						}
						ret.AddRange(f);
						return ret;
					}
					return Array.Empty<PBEBattlePokemon>();
				}
				else if (pkmn.FieldPosition == PBEFieldPosition.Right)
				{
					List<PBEBattlePokemon> ret = null!;
					if (includeAllies)
					{
						ret = allies.FindAll(p => p.FieldPosition == PBEFieldPosition.Center);
						if (!includeFoes)
						{
							return ret;
						}
					}
					if (includeFoes)
					{
						List<PBEBattlePokemon> f = foes.FindAll(p => p.FieldPosition == PBEFieldPosition.Center || p.FieldPosition == PBEFieldPosition.Left);
						if (!includeAllies)
						{
							return f;
						}
						ret.AddRange(f);
						return ret;
					}
					return Array.Empty<PBEBattlePokemon>();
				}
				else
				{
					throw new InvalidDataException(nameof(pkmn.FieldPosition));
				}
			}
			default: throw new InvalidDataException(nameof(pkmn.Battle.BattleFormat));
		}
	}

	private static void FindFoeLeftTarget(PBEBattlePokemon user, bool canHitFarCorners, List<PBEBattlePokemon> targets)
	{
		PBETeam ot = user.Team.OpposingTeam;
		if (!ot.TryGetPokemon(PBEFieldPosition.Left, out PBEBattlePokemon? pkmn))
		{
			# Left not found; fallback to its teammate
			switch (user.Battle.BattleFormat)
			{
				case PBEBattleFormat.Double:
				{
					if (!ot.TryGetPokemon(PBEFieldPosition.Right, out pkmn))
					{
						return; # Nobody left and nobody right; fail
					}
					break;
				}
				case PBEBattleFormat.Triple:
				{
					if (!ot.TryGetPokemon(PBEFieldPosition.Center, out pkmn))
					{
						if (user.FieldPosition != PBEFieldPosition.Right || canHitFarCorners)
						{
							# Center fainted as well but the user can reach far right
							if (!ot.TryGetPokemon(PBEFieldPosition.Right, out pkmn))
							{
								return; # Nobody left, center, or right; fail
							}
						}
						else
						{
							return; # Nobody left and nobody center; fail since we can't reach the right
						}
					}
					break;
				}
				default: throw new InvalidOperationException();
			}
		}
		targets.Add(pkmn);
	}
	private static void FindFoeCenterTarget(PBEBattlePokemon user, bool canHitFarCorners, PBERandom rand, List<PBEBattlePokemon> targets)
	{
		PBETeam ot = user.Team.OpposingTeam;
		if (!ot.TryGetPokemon(PBEFieldPosition.Center, out PBEBattlePokemon? pkmn))
		{
			switch (user.Battle.BattleFormat)
			{
				case PBEBattleFormat.Single:
				case PBEBattleFormat.Rotation: return;
				default: throw new InvalidOperationException();
				case PBEBattleFormat.Triple:
				{
					# Center not found; fallback to its teammate
					switch (user.FieldPosition)
					{
						case PBEFieldPosition.Left:
						{
							if (!ot.TryGetPokemon(PBEFieldPosition.Right, out pkmn))
							{
								if (canHitFarCorners)
								{
									if (!ot.TryGetPokemon(PBEFieldPosition.Left, out pkmn))
									{
										return; # Nobody center, right, or left; fail
									}
								}
								else
								{
									return; # Nobody center and nobody right; fail since we can't reach the left
								}
							}
							break;
						}
						case PBEFieldPosition.Center:
						{
							if (!ot.TryGetPokemon(PBEFieldPosition.Left, out PBEBattlePokemon? left))
							{
								if (!ot.TryGetPokemon(PBEFieldPosition.Right, out PBEBattlePokemon? right))
								{
									return; # Nobody left or right; fail
								}
								pkmn = right; # Nobody left; pick right
							}
							else
							{
								if (!ot.TryGetPokemon(PBEFieldPosition.Right, out PBEBattlePokemon? right))
								{
									pkmn = left; # Nobody right; pick left
								}
								else
								{
									pkmn = rand.RandomBool() ? left : right; # Left and right present; randomly select left or right
								}
							}
							break;
						}
						case PBEFieldPosition.Right:
						{
							if (!ot.TryGetPokemon(PBEFieldPosition.Left, out pkmn))
							{
								if (canHitFarCorners)
								{
									if (!ot.TryGetPokemon(PBEFieldPosition.Right, out pkmn))
									{
										return; # Nobody center, left, or right; fail
									}
								}
								else
								{
									return; # Nobody center and nobody left; fail since we can't reach the right
								}
							}
							break;
						}
						default: throw new InvalidDataException();
					}
					break;
				}
			}
		}
		targets.Add(pkmn);
	}
	private static void FindFoeRightTarget(PBEBattlePokemon user, bool canHitFarCorners, List<PBEBattlePokemon> targets)
	{
		PBETeam ot = user.Team.OpposingTeam;
		if (!ot.TryGetPokemon(PBEFieldPosition.Right, out PBEBattlePokemon? pkmn))
		{
			# Right not found; fallback to its teammate
			switch (user.Battle.BattleFormat)
			{
				case PBEBattleFormat.Double:
				{
					if (!ot.TryGetPokemon(PBEFieldPosition.Left, out pkmn))
					{
						return; # Nobody right and nobody left; fail
					}
					break;
				}
				case PBEBattleFormat.Triple:
				{
					if (!ot.TryGetPokemon(PBEFieldPosition.Center, out pkmn))
					{
						if (user.FieldPosition != PBEFieldPosition.Left || canHitFarCorners)
						{
							# Center fainted as well but the user can reach far left
							if (!ot.TryGetPokemon(PBEFieldPosition.Left, out pkmn))
							{
								return; # Nobody right, center, or left; fail
							}
						}
						else
						{
							return; # Nobody right and nobody center; fail since we can't reach the left
						}
					}
					break;
				}
				default: throw new InvalidOperationException();
			}
		}
		targets.Add(pkmn);
	}
	## <summary>Gets all Pokémon that will be hit.</summary>
	## <param name="user">The Pokémon that will act.</param>
	## <param name="requestedTargets">The targets the Pokémon wishes to hit.</param>
	## <param name="canHitFarCorners">Whether the move can hit far Pokémon in a triple battle.</param>
	## <param name="rand">The random to use.</param>
	private static PBEBattlePokemon[] GetRuntimeTargets(PBEBattlePokemon user, PBETurnTarget requestedTargets, bool canHitFarCorners, PBERandom rand)
	{
		var targets = new List<PBEBattlePokemon>();
		# Foes first, then allies (since initial attack effects run that way)
		if (requestedTargets.HasFlag(PBETurnTarget.FoeLeft))
		{
			FindFoeLeftTarget(user, canHitFarCorners, targets);
		}
		if (requestedTargets.HasFlag(PBETurnTarget.FoeCenter))
		{
			FindFoeCenterTarget(user, canHitFarCorners, rand, targets);
		}
		if (requestedTargets.HasFlag(PBETurnTarget.FoeRight))
		{
			FindFoeRightTarget(user, canHitFarCorners, targets);
		}
		PBETeam t = user.Team;
		if (requestedTargets.HasFlag(PBETurnTarget.AllyLeft))
		{
			t.TryAddPokemonToCollection(PBEFieldPosition.Left, targets);
		}
		if (requestedTargets.HasFlag(PBETurnTarget.AllyCenter))
		{
			t.TryAddPokemonToCollection(PBEFieldPosition.Center, targets);
		}
		if (requestedTargets.HasFlag(PBETurnTarget.AllyRight))
		{
			t.TryAddPokemonToCollection(PBEFieldPosition.Right, targets);
		}
		return targets.Distinct().ToArray(); # Remove duplicate targets
	}

	## <summary>Determines whether chosen targets are valid for a given move.</summary>
	## <param name="pkmn">The Pokémon that will act.</param>
	## <param name="move">The move the Pokémon wishes to use.</param>
	## <param name="targets">The targets bitfield to validate.</param>
	## <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="targets"/>, <paramref name="move"/>, <paramref name="pkmn"/>'s <see cref="PBEBattlePokemon.FieldPosition"/>, or <paramref name="pkmn"/>'s <see cref="PBEBattle"/>'s <see cref="BattleFormat"/> is invalid.</exception>
	public static bool AreTargetsValid(PBEBattlePokemon pkmn, PBEMove move, PBETurnTarget targets)
	{
		if (move == PBEMove.None || move >= PBEMove.MAX)
		{
			throw new ArgumentOutOfRangeException(nameof(move));
		}
		IPBEMoveData mData = PBEDataProvider.Instance.GetMoveData(move);
		if (!mData.IsMoveUsable())
		{
			throw new ArgumentOutOfRangeException(nameof(move));
		}
		return AreTargetsValid(pkmn, mData, targets);
	}
	public static bool AreTargetsValid(PBEBattlePokemon pkmn, IPBEMoveData mData, PBETurnTarget targets)
	{
		PBEMoveTarget possibleTargets = pkmn.GetMoveTargets(mData);
		switch (pkmn.Battle.BattleFormat)
		{
			case PBEBattleFormat.Single:
			{
				switch (possibleTargets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == (PBETurnTarget.AllyCenter | PBETurnTarget.FoeCenter);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoes:
					case PBEMoveTarget.AllFoesSurrounding:
					case PBEMoveTarget.AllSurrounding:
					case PBEMoveTarget.SingleFoeSurrounding:
					case PBEMoveTarget.SingleNotSelf:
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllTeam:
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.Self:
					case PBEMoveTarget.SelfOrAllySurrounding:
					case PBEMoveTarget.SingleAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == PBETurnTarget.AllyCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			case PBEBattleFormat.Double:
			{
				switch (possibleTargets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == (PBETurnTarget.AllyLeft | PBETurnTarget.AllyRight | PBETurnTarget.FoeLeft | PBETurnTarget.FoeRight);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoes:
					case PBEMoveTarget.AllFoesSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == (PBETurnTarget.FoeLeft | PBETurnTarget.FoeRight);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllTeam:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == (PBETurnTarget.AllyLeft | PBETurnTarget.AllyRight);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == (PBETurnTarget.AllyRight | PBETurnTarget.FoeLeft | PBETurnTarget.FoeRight);
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == (PBETurnTarget.AllyLeft | PBETurnTarget.FoeLeft | PBETurnTarget.FoeRight);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.Self:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == PBETurnTarget.AllyLeft;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.AllyRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SelfOrAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.AllyLeft || targets == PBETurnTarget.AllyRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == PBETurnTarget.AllyRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.AllyLeft;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleFoeSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.FoeLeft || targets == PBETurnTarget.FoeRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleNotSelf:
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == PBETurnTarget.AllyRight || targets == PBETurnTarget.FoeLeft || targets == PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.AllyLeft || targets == PBETurnTarget.FoeLeft || targets == PBETurnTarget.FoeRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			case PBEBattleFormat.Triple:
			{
				switch (possibleTargets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == (PBETurnTarget.AllyLeft | PBETurnTarget.AllyCenter | PBETurnTarget.AllyRight | PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoes:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == (PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoesSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == (PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight);
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == (PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight);
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == (PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == (PBETurnTarget.AllyCenter | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight);
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == (PBETurnTarget.AllyLeft | PBETurnTarget.AllyRight | PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight);
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == (PBETurnTarget.AllyCenter | PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllTeam:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == (PBETurnTarget.AllyLeft | PBETurnTarget.AllyCenter | PBETurnTarget.AllyRight);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.Self:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == PBETurnTarget.AllyLeft;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == PBETurnTarget.AllyCenter;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.AllyRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SelfOrAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == PBETurnTarget.AllyLeft || targets == PBETurnTarget.AllyCenter;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == PBETurnTarget.AllyLeft || targets == PBETurnTarget.AllyCenter || targets == PBETurnTarget.AllyRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.AllyCenter || targets == PBETurnTarget.AllyRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.AllyCenter;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == PBETurnTarget.AllyLeft || targets == PBETurnTarget.AllyRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleFoeSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == PBETurnTarget.FoeCenter || targets == PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == PBETurnTarget.FoeLeft || targets == PBETurnTarget.FoeCenter || targets == PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.FoeLeft || targets == PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleNotSelf:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == PBETurnTarget.AllyCenter || targets == PBETurnTarget.AllyRight || targets == PBETurnTarget.FoeLeft || targets == PBETurnTarget.FoeCenter || targets == PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == PBETurnTarget.AllyLeft || targets == PBETurnTarget.AllyRight || targets == PBETurnTarget.FoeLeft || targets == PBETurnTarget.FoeCenter || targets == PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.AllyLeft || targets == PBETurnTarget.AllyCenter || targets == PBETurnTarget.FoeLeft || targets == PBETurnTarget.FoeCenter || targets == PBETurnTarget.FoeRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return targets == PBETurnTarget.AllyCenter || targets == PBETurnTarget.FoeCenter || targets == PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return targets == PBETurnTarget.AllyLeft || targets == PBETurnTarget.AllyRight || targets == PBETurnTarget.FoeLeft || targets == PBETurnTarget.FoeCenter || targets == PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.AllyCenter || targets == PBETurnTarget.FoeLeft || targets == PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			case PBEBattleFormat.Rotation:
			{
				switch (possibleTargets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == (PBETurnTarget.AllyCenter | PBETurnTarget.FoeCenter);
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoes:
					case PBEMoveTarget.AllFoesSurrounding:
					case PBEMoveTarget.AllSurrounding:
					case PBEMoveTarget.SingleFoeSurrounding:
					case PBEMoveTarget.SingleNotSelf:
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllTeam:
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.Self:
					case PBEMoveTarget.SelfOrAllySurrounding:
					case PBEMoveTarget.SingleAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return targets == PBETurnTarget.AllyCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			default: throw new InvalidDataException(nameof(pkmn.Battle.BattleFormat));
		}
	}

	## <summary>Gets a random target a move can hit when called by <see cref="PBEMoveEffect.Metronome"/>.</summary>
	## <param name="pkmn">The Pokémon using <paramref name="calledMove"/>.</param>
	## <param name="calledMove">The move being called.</param>
	## <param name="rand">The random to use.</param>
	## <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="calledMove"/>, <paramref name="pkmn"/>'s <see cref="PBEBattlePokemon.FieldPosition"/>, or <paramref name="pkmn"/>'s <see cref="PBEBattle"/>'s <see cref="BattleFormat"/> is invalid.</exception>
	public static PBETurnTarget GetRandomTargetForMetronome(PBEBattlePokemon pkmn, PBEMove calledMove, PBERandom rand)
	{
		if (calledMove == PBEMove.None || calledMove >= PBEMove.MAX || !PBEDataUtils.IsMoveUsable(calledMove))
		{
			throw new ArgumentOutOfRangeException(nameof(calledMove));
		}
		IPBEMoveData mData = PBEDataProvider.Instance.GetMoveData(calledMove);
		if (!mData.IsMoveUsable())
		{
			throw new ArgumentOutOfRangeException(nameof(calledMove));
		}
		PBEMoveTarget possibleTargets = pkmn.GetMoveTargets(mData);
		switch (pkmn.Battle.BattleFormat)
		{
			case PBEBattleFormat.Single:
			{
				switch (possibleTargets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return PBETurnTarget.AllyCenter | PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoes:
					case PBEMoveTarget.AllFoesSurrounding:
					case PBEMoveTarget.AllSurrounding:
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.SingleFoeSurrounding:
					case PBEMoveTarget.SingleNotSelf:
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllTeam:
					case PBEMoveTarget.Self:
					case PBEMoveTarget.SelfOrAllySurrounding:
					case PBEMoveTarget.SingleAllySurrounding: # Helping Hand cannot be called by Metronome anyway
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return PBETurnTarget.AllyCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			case PBEBattleFormat.Double:
			{
				switch (possibleTargets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyLeft | PBETurnTarget.AllyRight | PBETurnTarget.FoeLeft | PBETurnTarget.FoeRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoes:
					case PBEMoveTarget.AllFoesSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.FoeLeft | PBETurnTarget.FoeRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllTeam:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyLeft | PBETurnTarget.AllyRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return PBETurnTarget.AllyRight | PBETurnTarget.FoeLeft | PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyLeft | PBETurnTarget.FoeLeft | PBETurnTarget.FoeRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.Self:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return PBETurnTarget.AllyLeft;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SelfOrAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							if (rand.RandomBool())
							{
								return PBETurnTarget.AllyLeft;
							}
							else
							{
								return PBETurnTarget.AllyRight;
							}
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleAllySurrounding: # Helping Hand cannot be called by Metronome anyway
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return PBETurnTarget.AllyRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyLeft;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.SingleFoeSurrounding:
					case PBEMoveTarget.SingleNotSelf:
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							if (rand.RandomBool())
							{
								return PBETurnTarget.FoeLeft;
							}
							else
							{
								return PBETurnTarget.FoeRight;
							}
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			case PBEBattleFormat.Triple:
			{
				switch (possibleTargets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyLeft | PBETurnTarget.AllyCenter | PBETurnTarget.AllyRight | PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoes:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoesSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return PBETurnTarget.AllyCenter | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return PBETurnTarget.AllyLeft | PBETurnTarget.AllyRight | PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyCenter | PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllTeam:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyLeft | PBETurnTarget.AllyCenter | PBETurnTarget.AllyRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.Self:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return PBETurnTarget.AllyLeft;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return PBETurnTarget.AllyCenter;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyRight;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SelfOrAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							if (rand.RandomBool())
							{
								return PBETurnTarget.AllyLeft;
							}
							else
							{
								return PBETurnTarget.AllyCenter;
							}
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							int val = rand.RandomInt(0, 2);
							if (val == 0)
							{
								return PBETurnTarget.AllyLeft;
							}
							else if (val == 1)
							{
								return PBETurnTarget.AllyCenter;
							}
							else
							{
								return PBETurnTarget.AllyRight;
							}
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							if (rand.RandomBool())
							{
								return PBETurnTarget.AllyCenter;
							}
							else
							{
								return PBETurnTarget.AllyRight;
							}
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleAllySurrounding: # Helping Hand cannot be called by Metronome anyway
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return PBETurnTarget.AllyCenter;
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							if (rand.RandomBool())
							{
								return PBETurnTarget.AllyLeft;
							}
							else
							{
								return PBETurnTarget.AllyRight;
							}
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.SingleFoeSurrounding:
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							if (rand.RandomBool())
							{
								return PBETurnTarget.FoeCenter;
							}
							else
							{
								return PBETurnTarget.FoeRight;
							}
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							int val = rand.RandomInt(0, 2);
							if (val == 0)
							{
								return PBETurnTarget.FoeLeft;
							}
							else if (val == 1)
							{
								return PBETurnTarget.FoeCenter;
							}
							else
							{
								return PBETurnTarget.FoeRight;
							}
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							if (rand.RandomBool())
							{
								return PBETurnTarget.FoeLeft;
							}
							else
							{
								return PBETurnTarget.FoeCenter;
							}
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleNotSelf:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							int val = rand.RandomInt(0, 2);
							if (val == 0)
							{
								return PBETurnTarget.FoeLeft;
							}
							else if (val == 1)
							{
								return PBETurnTarget.FoeCenter;
							}
							else
							{
								return PBETurnTarget.FoeRight;
							}
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			case PBEBattleFormat.Rotation:
			{
				switch (possibleTargets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyCenter | PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoes:
					case PBEMoveTarget.AllFoesSurrounding:
					case PBEMoveTarget.AllSurrounding:
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.SingleFoeSurrounding:
					case PBEMoveTarget.SingleNotSelf:
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllTeam:
					case PBEMoveTarget.Self:
					case PBEMoveTarget.SelfOrAllySurrounding:
					case PBEMoveTarget.SingleAllySurrounding: # Helping Hand cannot be called by Metronome anyway
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			default: throw new InvalidDataException(nameof(pkmn.Battle.BattleFormat));
		}
	}
}



class PBEAttackVictim:
	var Pkmn : PBEBattlePokemon
	var Result : PBEResult 
	var TypeEffectiveness : float 
	var Crit : bool
	var Damage : int #ushort 
	
	func _init(pkmn:PBEBattlePokemon , result:PBEResult , typeEffectiveness:float ):
		Pkmn = pkmn
		Result = result
		TypeEffectiveness = typeEffectiveness
