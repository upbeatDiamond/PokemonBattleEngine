### Ideally, this would hold the global/static functions

#
class PBEBattle1: ## Merge Battle into this.
	
	#var amtUsed := 0

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
#public sealed partial class PBEBattle
	
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
	
	
	private void Hit_DoCrit(List<PBEAttackVictim> victims)
		foreach (PBEAttackVictim victim in victims)
			if (victim.Crit)
			{
				BroadcastMoveCrit(victim.Pkmn);
	
	
	private void Hit_DoMoveResult(PBEBattlePokemon user, List<PBEAttackVictim> victims):
		foreach (PBEAttackVictim victim in victims)
			PBEResult result = victim.Result;
			if (result != PBEResult.Success):
				BroadcastMoveResult(user, victim.Pkmn, result);
	
	
	private void Hit_FaintCheck(List<PBEAttackVictim> victims):
		foreach (PBEAttackVictim victim in victims)
			FaintCheck(victim.Pkmn);

	private void BasicHit(PBEBattlePokemon user, PBEBattlePokemon[] targets, IPBEMoveData mData,
			Func<PBEBattlePokemon, PBEResult>? failFunc = null,
			Action<PBEBattlePokemon>? beforeDoingDamage = null,
			Action<PBEBattlePokemon, ushort>? beforePostHit = null,
			Action<PBEBattlePokemon>? afterPostHit = null,
			Func<int, int?>? recoilFunc = null):
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
		if (victims.Count == 0):
			return;
		float basePower = CalculateBasePower(user, targets, mData, moveType); # Gem activates here
		float initDamageMultiplier = victims.Count > 1 ? 0.75f : 1;
		int totalDamageDealt = 0;
		
		
		func CalcDamage(PBEAttackVictim victim):
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
		
		
		func DoSub(List<PBEAttackVictim> subs):
			for (PBEAttackVictim victim in subs):
				CalcDamage(victim);
				PBEBattlePokemon target = victim.Pkmn;
				PBEResult result = victim.Result;
				if (result != PBEResult.Success):
					BroadcastMoveResult(user, target, result);
				if (victim.Crit):
					BroadcastMoveCrit(target);
				if (target.SubstituteHP == 0):
					BroadcastStatus2(target, user, PBEStatus2.Substitute, PBEStatusAction.Ended);
		
		
		func DoNormal(List<PBEAttackVictim> normals):
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

#public sealed partial class PBEBattle
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


#public sealed partial class PBEBattle
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
		match (battleStatusAction)
		{
			PBEBattleStatusAction.Added: BattleStatus |= battleStatus; break;
			PBEBattleStatusAction.Cleared:
			PBEBattleStatusAction.Ended: BattleStatus &= ~battleStatus; break;
			_: throw new ArgumentOutOfRangeException(nameof(battleStatusAction));
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
		match (itemAction)
		{
			PBEItemAction.Consumed:
			{
				itemHolder.Item = PBEItem.None;
				itemHolder.KnownItem = PBEItem.None;
				break;
			}
			_:
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
		match (statusAction)
		{
			PBEStatusAction.Added:
			PBEStatusAction.Announced:
			PBEStatusAction.CausedImmobility:
			PBEStatusAction.Damage: status2Receiver.Status2 |= status2; status2Receiver.KnownStatus2 |= status2; break;
			PBEStatusAction.Cleared:
			PBEStatusAction.Ended: status2Receiver.Status2 &= ~status2; status2Receiver.KnownStatus2 &= ~status2; break;
			_: throw new ArgumentOutOfRangeException(nameof(statusAction));
		}
		Broadcast(new PBEStatus2Packet(status2Receiver, pokemon2, status2, statusAction));
	}
	private void BroadcastTeamStatus(PBETeam team, PBETeamStatus teamStatus, PBETeamStatusAction teamStatusAction)
	{
		match (teamStatusAction)
		{
			PBETeamStatusAction.Added: team.TeamStatus |= teamStatus; break;
			PBETeamStatusAction.Cleared:
			PBETeamStatusAction.Ended: team.TeamStatus &= ~teamStatus; break;
			_: throw new ArgumentOutOfRangeException(nameof(teamStatusAction));
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

		match (packet)
		{
			PBEAbilityPacket ap:
			{
				PBEBattlePokemon abilityOwner = ap.AbilityOwnerTrainer.GetPokemon(ap.AbilityOwner);
				PBEBattlePokemon pokemon2 = ap.AbilityOwnerTrainer.GetPokemon(ap.Pokemon2);
				bool abilityOwnerCaps = true,
							pokemon2Caps = true;
				string message;
				match (ap.Ability)
				{
					PBEAbility.AirLock:
					PBEAbility.CloudNine:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Weather: message = "{0}'s {2} causes the effects of weather to disappear!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.Anticipation:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Announced: message = "{0}'s {2} made it shudder!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.BadDreams:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Damage: message = "{1} is tormented by {0}'s {2}!"; abilityOwnerCaps = false; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.BigPecks:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Stats: message = $"{{0}}'s {PBEDataProvider.Instance.GetStatName(PBEStat.Defense).English} was not lowered!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.ClearBody:
					PBEAbility.WhiteSmoke:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Stats: message = "{0}'s {2} prevents stat reduction!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.ColorChange:
					PBEAbility.FlowerGift:
					PBEAbility.Forecast:
					PBEAbility.Imposter:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.ChangedAppearance: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.CuteCharm:
					PBEAbility.EffectSpore:
					PBEAbility.FlameBody:
					PBEAbility.Healer:
					PBEAbility.PoisonPoint:
					PBEAbility.ShedSkin:
					PBEAbility.Static:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.ChangedStatus: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.Download:
					PBEAbility.Intimidate:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Stats: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.Drizzle:
					PBEAbility.Drought:
					PBEAbility.SandStream:
					PBEAbility.SnowWarning:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Weather: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.HyperCutter:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Stats: message = $"{{0}}'s {PBEDataProvider.Instance.GetStatName(PBEStat.Attack).English} was not lowered!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.IceBody:
					PBEAbility.PoisonHeal:
					PBEAbility.RainDish:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.RestoredHP: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.Illusion:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.ChangedAppearance: goto bottom;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
					}
					PBEAbility.Immunity:
					PBEAbility.Insomnia:
					PBEAbility.Limber:
					PBEAbility.MagmaArmor:
					PBEAbility.Oblivious:
					PBEAbility.OwnTempo:
					PBEAbility.VitalSpirit:
					PBEAbility.WaterVeil:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.ChangedStatus:
							PBEAbilityAction.PreventedStatus: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.IronBarbs:
					PBEAbility.Justified:
					PBEAbility.Levitate:
					PBEAbility.Mummy:
					PBEAbility.Rattled:
					PBEAbility.RoughSkin:
					PBEAbility.SolarPower:
					PBEAbility.Sturdy:
					PBEAbility.WeakArmor:
					PBEAbility.WonderGuard:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Damage: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.KeenEye:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Stats: message = $"{{0}}'s {PBEDataProvider.Instance.GetStatName(PBEStat.Accuracy).English} was not lowered!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.LeafGuard:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.PreventedStatus: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.LiquidOoze:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Damage: message = "{1} sucked up the liquid ooze!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.MoldBreaker:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Announced: message = "{0} breaks the mold!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.Moody:
					PBEAbility.SpeedBoost:
					PBEAbility.Steadfast:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Stats: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.RunAway:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Announced: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.SlowStart:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Announced: message = "{0} can't get it going!"; break;
							PBEAbilityAction.SlowStart_Ended: message = "{0} finally got its act together!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.Teravolt:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Announced: message = "{0} is radiating a bursting aura!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					PBEAbility.Turboblaze:
					{
						match (ap.AbilityAction)
						{
							PBEAbilityAction.Announced: message = "{0} is radiating a blazing aura!"; break;
							_: throw new InvalidDataException(nameof(ap.AbilityAction));
						}
						break;
					}
					_: throw new InvalidDataException(nameof(ap.Ability));
				}
				return string.Format(message, GetPkmnName(abilityOwner, abilityOwnerCaps), GetPkmnName(pokemon2, pokemon2Caps), PBEDataProvider.Instance.GetAbilityName(ap.Ability).English);
			}
			PBEAbilityReplacedPacket arp:
			{
				PBEBattlePokemon abilityOwner = arp.AbilityOwnerTrainer.GetPokemon(arp.AbilityOwner);
				string message;
				match (arp.NewAbility)
				{
					PBEAbility.None: message = "{0}'s {1} was suppressed!"; break;
					_: message = "{0}'s {1} was changed to {2}!"; break;
				}
				return string.Format(message,
					GetPkmnName(abilityOwner, true),
					arp.OldAbility is null ? "Ability" : PBEDataProvider.Instance.GetAbilityName(arp.OldAbility.Value).English,
					PBEDataProvider.Instance.GetAbilityName(arp.NewAbility).English);
			}
			PBEBattleStatusPacket bsp:
			{
				string message;
				match (bsp.BattleStatus)
				{
					PBEBattleStatus.TrickRoom:
					{
						match (bsp.BattleStatusAction)
						{
							PBEBattleStatusAction.Added: message = "The dimensions were twisted!"; break;
							PBEBattleStatusAction.Cleared:
							PBEBattleStatusAction.Ended: message = "The twisted dimensions returned to normal!"; break;
							_: throw new InvalidDataException(nameof(bsp.BattleStatusAction));
						}
						break;
					}
					_: throw new InvalidDataException(nameof(bsp.BattleStatus));
				}
				return message;
			}
			PBECapturePacket cp:
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
			PBEFleeFailedPacket ffp:
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
			PBEHazePacket _:
			{
				return "All stat changes were eliminated!";
			}
			PBEItemPacket ip:
			{
				PBEBattlePokemon itemHolder = ip.ItemHolderTrainer.GetPokemon(ip.ItemHolder);
				PBEBattlePokemon pokemon2 = ip.Pokemon2Trainer.GetPokemon(ip.Pokemon2);
				bool itemHolderCaps = true,
							pokemon2Caps = false;
				string message;
				match (ip.Item)
				{
					PBEItem.AguavBerry:
					PBEItem.BerryJuice:
					PBEItem.FigyBerry:
					PBEItem.IapapaBerry:
					PBEItem.MagoBerry:
					PBEItem.OranBerry:
					PBEItem.SitrusBerry:
					PBEItem.WikiBerry:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Consumed: message = "{0} restored its health using its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.ApicotBerry:
					PBEItem.GanlonBerry:
					PBEItem.LiechiBerry:
					PBEItem.PetayaBerry:
					PBEItem.SalacBerry:
					PBEItem.StarfBerry:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Consumed: message = "{0} used its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.BugGem:
					PBEItem.DarkGem:
					PBEItem.DragonGem:
					PBEItem.ElectricGem:
					PBEItem.FightingGem:
					PBEItem.FireGem:
					PBEItem.FlyingGem:
					PBEItem.GhostGem:
					PBEItem.GrassGem:
					PBEItem.GroundGem:
					PBEItem.IceGem:
					PBEItem.NormalGem:
					PBEItem.PoisonGem:
					PBEItem.PsychicGem:
					PBEItem.RockGem:
					PBEItem.SteelGem:
					PBEItem.WaterGem:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Consumed: message = "The {2} strengthened {0}'s power!"; itemHolderCaps = false; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.BlackSludge:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Damage: message = "{0} is hurt by its {2}!"; break;
							PBEItemAction.RestoredHP: message = "{0} restored a little HP using its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.DestinyKnot:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Announced: message = "{0}'s {2} activated!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.FlameOrb:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Announced: message = "{0} was burned by its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.FocusBand:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Damage: message = "{0} hung on using its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.FocusSash:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Consumed: message = "{0} hung on using its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.Leftovers:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.RestoredHP: message = "{0} restored a little HP using its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.LifeOrb:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Damage: message = "{0} is hurt by its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.PowerHerb:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Consumed: message = "{0} became fully charged due to its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.RockyHelmet:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Damage: message = "{1} was hurt by the {2}!"; pokemon2Caps = true; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.SmokeBall:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Announced: message = "{0} used its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					PBEItem.ToxicOrb:
					{
						match (ip.ItemAction)
						{
							PBEItemAction.Announced: message = "{0} was badly poisoned by its {2}!"; break;
							_: throw new InvalidDataException(nameof(ip.ItemAction));
						}
						break;
					}
					_: throw new InvalidDataException(nameof(ip.Item));
				}
				return string.Format(message, GetPkmnName(itemHolder, itemHolderCaps), GetPkmnName(pokemon2, pokemon2Caps), PBEDataProvider.Instance.GetItemName(ip.Item).English);
			}
			PBEItemTurnPacket itp:
			{
				PBEBattlePokemon itemUser = itp.ItemUserTrainer.GetPokemon(itp.ItemUser);
				string itemEnglish = PBEDataProvider.Instance.GetItemName(itp.Item).English;
				match (itp.ItemAction)
				{
					PBEItemTurnAction.Attempt:
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
					PBEItemTurnAction.NoEffect:
					{
						if (PBEDataUtils.AllBalls.Contains(itp.Item))
						{
							return "The trainer blocked the ball! Don't be a thief!";
						}
						return string.Format("The {0} had no effect.", itemEnglish);
					}
					PBEItemTurnAction.Success:
					{
						#string message;
						match (itp.Item)
						{
							# No "success" items yet
							_: throw new InvalidDataException(nameof(itp.Item));
						}
						#return string.Format(message, GetPkmnName(itemUser, true), itemEnglish);
					}
					_: throw new InvalidDataException(nameof(itp.ItemAction));
				}
			}
			PBEMoveCritPacket mcp:
			{
				PBEBattlePokemon victim = mcp.VictimTrainer.GetPokemon(mcp.Victim);
				return string.Format("A critical hit on {0}!", GetPkmnName(victim, false));
			}
			PBEMovePPChangedPacket mpcp:
			{
				PBEBattlePokemon moveUser = mpcp.MoveUserTrainer.GetPokemon(mpcp.MoveUser);
				return string.Format("{0}'s {1} {3} {2} PP!",
					GetPkmnName(moveUser, true),
					PBEDataProvider.Instance.GetMoveName(mpcp.Move).English,
					Math.Abs(mpcp.AmountReduced),
					mpcp.AmountReduced >= 0 ? "lost" : "gained");
			}
			PBEMoveResultPacket mrp:
			{
				PBEBattlePokemon moveUser = mrp.MoveUserTrainer.GetPokemon(mrp.MoveUser);
				PBEBattlePokemon pokemon2 = mrp.Pokemon2Trainer.GetPokemon(mrp.Pokemon2);
				bool pokemon2Caps = true;
				string message;
				match (mrp.Result)
				{
					PBEResult.Ineffective_Ability: message = "{1} is protected by its Ability!"; break;
					PBEResult.Ineffective_Gender: message = "It doesn't affect {1}..."; pokemon2Caps = false; break;
					PBEResult.Ineffective_Level: message = "{1} is protected by its level!"; break;
					PBEResult.Ineffective_MagnetRise: message = $"{{1}} is protected by {PBEDataProvider.Instance.GetMoveName(PBEMove.MagnetRise).English}!"; break;
					PBEResult.Ineffective_Safeguard: message = $"{{1}} is protected by {PBEDataProvider.Instance.GetMoveName(PBEMove.Safeguard).English}!"; break;
					PBEResult.Ineffective_Stat:
					PBEResult.Ineffective_Status:
					PBEResult.InvalidConditions: message = "But it failed!"; break;
					PBEResult.Ineffective_Substitute: message = $"{{1}} is protected by {PBEDataProvider.Instance.GetMoveName(PBEMove.Substitute).English}!"; break;
					PBEResult.Ineffective_Type: message = "{1} is protected by its Type!"; break;
					PBEResult.Missed: message = "{0}'s attack missed {1}!"; pokemon2Caps = false; break;
					PBEResult.NoTarget: message = "But there was no target..."; break;
					PBEResult.NotVeryEffective_Type: message = "It's not very effective on {1}..."; pokemon2Caps = false; break;
					PBEResult.SuperEffective_Type: message = "It's super effective on {1}!"; pokemon2Caps = false; break;
					_: throw new InvalidDataException(nameof(mrp.Result));
				}
				return string.Format(message, GetPkmnName(moveUser, true), GetPkmnName(pokemon2, pokemon2Caps));
			}
			PBEMoveUsedPacket mup:
			{
				PBEBattlePokemon moveUser = mup.MoveUserTrainer.GetPokemon(mup.MoveUser);
				return string.Format("{0} used {1}!", GetPkmnName(moveUser, true), PBEDataProvider.Instance.GetMoveName(mup.Move).English);
			}
			PBEPkmnFaintedPacket pfp:
			{
				PBEBattlePokemon pokemon = pfp.PokemonTrainer.GetPokemon(pfp.Pokemon);
				return string.Format("{0} fainted!", GetPkmnName(pokemon, true));
			}
			PBEPkmnEXPEarnedPacket peep:
			{
				PBEBattlePokemon pokemon = peep.PokemonTrainer.GetPokemon(peep.Pokemon);
				return string.Format("{0} earned {1} EXP point(s)!", GetPkmnName(pokemon, true), peep.Earned);
			}
			PBEPkmnFaintedPacket_Hidden pfph:
			{
				PBEBattlePokemon pokemon = pfph.PokemonTrainer.GetPokemon(pfph.OldPosition);
				return string.Format("{0} fainted!", GetPkmnName(pokemon, true));
			}
			IPBEPkmnFormChangedPacket pfcp:
			{
				PBEBattlePokemon pokemon = pfcp.PokemonTrainer.GetPokemon(pfcp.Pokemon);
				return string.Format("{0}'s new form is {1}!", GetPkmnName(pokemon, true), PBEDataProvider.Instance.GetFormName(pokemon.Species, pfcp.NewForm).English);
			}
			PBEPkmnHPChangedPacket phcp:
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
			PBEPkmnHPChangedPacket_Hidden phcph:
			{
				PBEBattlePokemon pokemon = phcph.PokemonTrainer.GetPokemon(phcph.Pokemon);
				float percentageChange = phcph.NewHPPercentage - phcph.OldHPPercentage;
				float absPercentageChange = Math.Abs(percentageChange);
				return DoHiddenHP(pokemon, percentageChange, absPercentageChange);
			}
			PBEPkmnLevelChangedPacket plcp:
			{
				PBEBattlePokemon pokemon = plcp.PokemonTrainer.GetPokemon(plcp.Pokemon);
				return string.Format("{0} grew to level {1}!", GetPkmnName(pokemon, true), plcp.NewLevel);
			}
			PBEPkmnStatChangedPacket pscp:
			{
				PBEBattlePokemon pokemon = pscp.PokemonTrainer.GetPokemon(pscp.Pokemon);
				string statName, message;
				match (pscp.Stat)
				{
					PBEStat.Accuracy: statName = "Accuracy"; break;
					PBEStat.Attack: statName = "Attack"; break;
					PBEStat.Defense: statName = "Defense"; break;
					PBEStat.Evasion: statName = "Evasion"; break;
					PBEStat.SpAttack: statName = "Special Attack"; break;
					PBEStat.SpDefense: statName = "Special Defense"; break;
					PBEStat.Speed: statName = "Speed"; break;
					_: throw new InvalidDataException(nameof(pscp.Stat));
				}
				int change = pscp.NewValue - pscp.OldValue;
				match (change)
				{
					-2: message = "harshly fell"; break;
					-1: message = "fell"; break;
					+1: message = "rose"; break;
					+2: message = "rose sharply"; break;
					_:
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
			IPBEPkmnSwitchInPacket psip:
			{
				if (!psip.Forced)
				{
					return string.Format("{1} sent out {0}!", psip.SwitchIns.Select(s => s.Nickname).ToArray().Andify(), GetTrainerName(psip.Trainer));
				}
				goto bottom;
			}
			PBEPkmnSwitchOutPacket psop:
			{
				if (!psop.Forced)
				{
					PBEBattlePokemon pokemon = psop.PokemonTrainer.GetPokemon(psop.Pokemon);
					return string.Format("{1} withdrew {0}!", pokemon.KnownNickname, GetTrainerName(psop.PokemonTrainer));
				}
				goto bottom;
			}
			PBEPkmnSwitchOutPacket_Hidden psoph:
			{
				if (!psoph.Forced)
				{
					PBEBattlePokemon pokemon = psoph.PokemonTrainer.GetPokemon(psoph.OldPosition);
					return string.Format("{1} withdrew {0}!", pokemon.KnownNickname, GetTrainerName(psoph.PokemonTrainer));
				}
				goto bottom;
			}
			PBEPsychUpPacket pup:
			{
				PBEBattlePokemon user = pup.UserTrainer.GetPokemon(pup.User);
				PBEBattlePokemon target = pup.TargetTrainer.GetPokemon(pup.Target);
				return string.Format("{0} copied {1}'s stat changes!", GetPkmnName(user, true), GetPkmnName(target, false));
			}
			PBEReflectTypePacket rtp:
			{
				PBEBattlePokemon user = rtp.UserTrainer.GetPokemon(rtp.User);
				PBEBattlePokemon target = rtp.TargetTrainer.GetPokemon(rtp.Target);
				string type1Str = PBEDataProvider.Instance.GetTypeName(rtp.Type1).English;
				return string.Format("{0} copied {1}'s {2}",
					GetPkmnName(user, true),
					GetPkmnName(target, false),
					rtp.Type2 == PBEType.None ? $"{type1Str} type!" : $"{type1Str} and {PBEDataProvider.Instance.GetTypeName(rtp.Type2).English} types!");
			}
			PBEReflectTypePacket_Hidden rtph:
			{
				PBEBattlePokemon user = rtph.UserTrainer.GetPokemon(rtph.User);
				PBEBattlePokemon target = rtph.TargetTrainer.GetPokemon(rtph.Target);
				return string.Format("{0} copied {1}'s types!", GetPkmnName(user, true), GetPkmnName(target, false));
			}
			PBESpecialMessagePacket smp: # TODO: Clean
			{
				string message;
				match (smp.Message)
				{
					PBESpecialMessage.DraggedOut: message = string.Format("{0} was dragged out!", GetPkmnName(((PBETrainer)smp.Params[0]).GetPokemon((PBEFieldPosition)smp.Params[1]), true)); break;
					PBESpecialMessage.Endure: message = string.Format("{0} endured the hit!", GetPkmnName(((PBETrainer)smp.Params[0]).GetPokemon((PBEFieldPosition)smp.Params[1]), true)); break;
					PBESpecialMessage.HPDrained: message = string.Format("{0} had its energy drained!", GetPkmnName(((PBETrainer)smp.Params[0]).GetPokemon((PBEFieldPosition)smp.Params[1]), true)); break;
					PBESpecialMessage.Magnitude: message = string.Format("Magnitude {0}!", (byte)smp.Params[0]); break;
					PBESpecialMessage.MultiHit: message = string.Format("Hit {0} time(s)!", (byte)smp.Params[0]); break;
					PBESpecialMessage.NothingHappened: message = "But nothing happened!"; break;
					PBESpecialMessage.OneHitKnockout: message = "It's a one-hit KO!"; break;
					PBESpecialMessage.PainSplit: message = "The battlers shared their pain!"; break;
					PBESpecialMessage.PayDay: message = "Coins were scattered everywhere!"; break;
					PBESpecialMessage.Recoil: message = string.Format("{0} is damaged by recoil!", GetPkmnName(((PBETrainer)smp.Params[0]).GetPokemon((PBEFieldPosition)smp.Params[1]), true)); break;
					PBESpecialMessage.Struggle: message = string.Format("{0} has no moves left!", GetPkmnName(((PBETrainer)smp.Params[0]).GetPokemon((PBEFieldPosition)smp.Params[1]), true)); break;
					_: throw new InvalidDataException(nameof(smp.Message));
				}
				return message;
			}
			PBEStatus1Packet s1p:
			{
				PBEBattlePokemon status1Receiver = s1p.Status1ReceiverTrainer.GetPokemon(s1p.Status1Receiver);
				string message;
				match (s1p.Status1)
				{
					PBEStatus1.Asleep:
					{
						match (s1p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} fell asleep!"; break;
							PBEStatusAction.CausedImmobility: message = "{0} is fast asleep."; break;
							PBEStatusAction.Cleared:
							PBEStatusAction.Ended: message = "{0} woke up!"; break;
							_: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					PBEStatus1.BadlyPoisoned:
					{
						match (s1p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} was badly poisoned!"; break;
							PBEStatusAction.Cleared: message = "{0} was cured of its poisoning."; break;
							PBEStatusAction.Damage: message = "{0} was hurt by poison!"; break;
							_: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					PBEStatus1.Burned:
					{
						match (s1p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} was burned!"; break;
							PBEStatusAction.Cleared: message = "{0}'s burn was healed."; break;
							PBEStatusAction.Damage: message = "{0} was hurt by its burn!"; break;
							_: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					PBEStatus1.Frozen:
					{
						match (s1p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} was frozen solid!"; break;
							PBEStatusAction.CausedImmobility: message = "{0} is frozen solid!"; break;
							PBEStatusAction.Cleared:
							PBEStatusAction.Ended: message = "{0} thawed out!"; break;
							_: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					PBEStatus1.Paralyzed:
					{
						match (s1p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} is paralyzed! It may be unable to move!"; break;
							PBEStatusAction.CausedImmobility: message = "{0} is paralyzed! It can't move!"; break;
							PBEStatusAction.Cleared: message = "{0} was cured of paralysis."; break;
							_: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					PBEStatus1.Poisoned:
					{
						match (s1p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} was poisoned!"; break;
							PBEStatusAction.Cleared: message = "{0} was cured of its poisoning."; break;
							PBEStatusAction.Damage: message = "{0} was hurt by poison!"; break;
							_: throw new InvalidDataException(nameof(s1p.StatusAction));
						}
						break;
					}
					_: throw new InvalidDataException(nameof(s1p.Status1));
				}
				return string.Format(message, GetPkmnName(status1Receiver, true));
			}
			PBEStatus2Packet s2p:
			{
				PBEBattlePokemon status2Receiver = s2p.Status2ReceiverTrainer.GetPokemon(s2p.Status2Receiver);
				PBEBattlePokemon pokemon2 = s2p.Pokemon2Trainer.GetPokemon(s2p.Pokemon2);
				string message;
				bool status2ReceiverCaps = true,
							pokemon2Caps = false;
				match (s2p.Status2)
				{
					PBEStatus2.Airborne:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} flew up high!"; break;
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Confused:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} became confused!"; break;
							PBEStatusAction.Announced: message = "{0} is confused!"; break;
							PBEStatusAction.Cleared:
							PBEStatusAction.Ended: message = "{0} snapped out of its confusion."; break;
							PBEStatusAction.Damage: message = "It hurt itself in its confusion!"; break;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Cursed:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{1} cut its own HP and laid a curse on {0}!"; status2ReceiverCaps = false; pokemon2Caps = true; break;
							PBEStatusAction.Damage: message = "{0} is afflicted by the curse!"; break;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Disguised:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Ended: message = "{0}'s illusion wore off!"; break;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Flinching:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.CausedImmobility: message = "{0} flinched and couldn't move!"; break;
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Identified:
					PBEStatus2.MiracleEye:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} was identified!"; break;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.HelpingHand:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{1} is ready to help {0}!"; status2ReceiverCaps = false; pokemon2Caps = true; break;
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Infatuated:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} fell in love with {1}!"; break;
							PBEStatusAction.Announced: message = "{0} is in love with {1}!"; break;
							PBEStatusAction.CausedImmobility: message = "{0} is immobilized by love!"; break;
							PBEStatusAction.Cleared:
							PBEStatusAction.Ended: message = "{0} got over its infatuation."; break;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.LeechSeed:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} was seeded!"; break;
							PBEStatusAction.Damage: message = "{0}'s health is sapped by Leech Seed!"; break;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.LockOn:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} took aim at {1}!"; break;
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.MagnetRise:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} levitated with electromagnetism!"; break;
							PBEStatusAction.Ended: message = "{0}'s electromagnetism wore off!"; break;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Nightmare:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} began having a nightmare!"; break;
							PBEStatusAction.Damage: message = "{0} is locked in a nightmare!"; break;
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.PowerTrick:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} switched its Attack and Defense!"; break;
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Protected:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added:
							PBEStatusAction.Damage: message = "{0} protected itself!"; break;
							PBEStatusAction.Cleared: message = "{1} broke through {0}'s protection!"; status2ReceiverCaps = false; pokemon2Caps = true; break;
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Pumped:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} is getting pumped!"; break;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Roost:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added:
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
					}
					PBEStatus2.ShadowForce:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} vanished instantly!"; break;
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Substitute:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} put in a substitute!"; break;
							PBEStatusAction.Damage: message = "The substitute took damage for {0}!"; status2ReceiverCaps = false; break;
							PBEStatusAction.Ended: message = "{0}'s substitute faded!"; break;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Transformed:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} transformed into {1}!"; break;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Underground:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} burrowed its way under the ground!"; break;
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					PBEStatus2.Underwater:
					{
						match (s2p.StatusAction)
						{
							PBEStatusAction.Added: message = "{0} hid underwater!"; break;
							PBEStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(s2p.StatusAction));
						}
						break;
					}
					_: throw new InvalidDataException(nameof(s2p.Status2));
				}
				return string.Format(message, GetPkmnName(status2Receiver, status2ReceiverCaps), GetPkmnName(pokemon2, pokemon2Caps));
			}
			PBETeamStatusPacket tsp:
			{
				string message;
				bool teamCaps = true;
				match (tsp.TeamStatus)
				{
					PBETeamStatus.LightScreen:
					{
						match (tsp.TeamStatusAction)
						{
							PBETeamStatusAction.Added: message = "Light Screen raised {0} team's Special Defense!"; teamCaps = false; break;
							PBETeamStatusAction.Cleared:
							PBETeamStatusAction.Ended: message = "{0} team's Light Screen wore off!"; break;
							_: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					PBETeamStatus.LuckyChant:
					{
						match (tsp.TeamStatusAction)
						{
							PBETeamStatusAction.Added: message = "The Lucky Chant shielded {0} team from critical hits!"; teamCaps = false; break;
							PBETeamStatusAction.Ended: message = "{0} team's Lucky Chant wore off!"; break;
							_: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					PBETeamStatus.QuickGuard:
					{
						match (tsp.TeamStatusAction)
						{
							PBETeamStatusAction.Added: message = "Quick Guard protected {0} team!"; teamCaps = false; break;
							PBETeamStatusAction.Cleared: message = "{0} team's Quick Guard was destroyed!"; break;
							PBETeamStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					PBETeamStatus.Reflect:
					{
						match (tsp.TeamStatusAction)
						{
							PBETeamStatusAction.Added: message = "Reflect raised {0} team's Defense!"; teamCaps = false; break;
							PBETeamStatusAction.Cleared:
							PBETeamStatusAction.Ended: message = "{0} team's Reflect wore off!"; break;
							_: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					PBETeamStatus.Safeguard:
					{
						match (tsp.TeamStatusAction)
						{
							PBETeamStatusAction.Added: message = "{0} team became cloaked in a mystical veil!"; break;
							PBETeamStatusAction.Ended: message = "{0} team is no longer protected by Safeguard!"; break;
							_: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					PBETeamStatus.Spikes:
					{
						match (tsp.TeamStatusAction)
						{
							PBETeamStatusAction.Added: message = "Spikes were scattered all around the feet of {0} team!"; teamCaps = false; break;
							#PBETeamStatusAction.Cleared: message = "The spikes disappeared from around {0} team's feet!"; teamCaps = false; break;
							_: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					PBETeamStatus.StealthRock:
					{
						match (tsp.TeamStatusAction)
						{
							PBETeamStatusAction.Added: message = "Pointed stones float in the air around {0} team!"; teamCaps = false; break;
							#PBETeamStatusAction.Cleared: message = "The pointed stones disappeared from around {0} team!"; teamCaps = false; break;
							_: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					PBETeamStatus.Tailwind:
					{
						match (tsp.TeamStatusAction)
						{
							PBETeamStatusAction.Added: message = "The tailwind blew from behind {0} team!"; teamCaps = false; break;
							PBETeamStatusAction.Ended: message = "{0} team's tailwind petered out!"; break;
							_: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					PBETeamStatus.ToxicSpikes:
					{
						match (tsp.TeamStatusAction)
						{
							PBETeamStatusAction.Added: message = "Poison spikes were scattered all around {0} team's feet!"; break;
							PBETeamStatusAction.Cleared: message = "The poison spikes disappeared from around {0} team's feet!"; break;
							_: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					PBETeamStatus.WideGuard:
					{
						match (tsp.TeamStatusAction)
						{
							PBETeamStatusAction.Added: message = "Wide Guard protected {0} team!"; break;
							PBETeamStatusAction.Cleared: message = "{0} team's Wide Guard was destroyed!"; break;
							PBETeamStatusAction.Ended: goto bottom;
							_: throw new InvalidDataException(nameof(tsp.TeamStatusAction));
						}
						break;
					}
					_: throw new InvalidDataException(nameof(tsp.TeamStatus));
				}
				return string.Format(message, GetTeamName(tsp.Team, teamCaps));
			}
			PBETeamStatusDamagePacket tsdp:
			{
				PBEBattlePokemon damageVictim = tsdp.DamageVictimTrainer.GetPokemon(tsdp.DamageVictim);
				string message;
				bool damageVictimCaps = false;
				match (tsdp.TeamStatus)
				{
					PBETeamStatus.QuickGuard: message = "Quick Guard protected {0}!"; break;
					PBETeamStatus.Spikes: message = "{0} is hurt by the spikes!"; damageVictimCaps = true; break;
					PBETeamStatus.StealthRock: message = "Pointed stones dug into {0}!"; break;
					PBETeamStatus.WideGuard: message = "Wide Guard protected {0}!"; break;
					_: throw new InvalidDataException(nameof(tsdp.TeamStatus));
				}
				return string.Format(message, GetPkmnName(damageVictim, damageVictimCaps));
			}
			PBETypeChangedPacket tcp:
			{
				PBEBattlePokemon pokemon = tcp.PokemonTrainer.GetPokemon(tcp.Pokemon);
				string type1Str = PBEDataProvider.Instance.GetTypeName(tcp.Type1).English;
				return string.Format("{0} transformed into the {1}",
					GetPkmnName(pokemon, true),
					tcp.Type2 == PBEType.None ? $"{type1Str} type!" : $"{type1Str} and {PBEDataProvider.Instance.GetTypeName(tcp.Type2).English} types!");
			}
			PBEWeatherPacket wp:
			{
				match (wp.Weather)
				{
					PBEWeather.Hailstorm:
					{
						match (wp.WeatherAction)
						{
							PBEWeatherAction.Added: return "It started to hail!";
							PBEWeatherAction.Ended: return "The hail stopped.";
							_: throw new InvalidDataException(nameof(wp.WeatherAction));
						}
					}
					PBEWeather.HarshSunlight:
					{
						match (wp.WeatherAction)
						{
							PBEWeatherAction.Added: return "The sunlight turned harsh!";
							PBEWeatherAction.Ended: return "The sunlight faded.";
							_: throw new InvalidDataException(nameof(wp.WeatherAction));
						}
					}
					PBEWeather.Rain:
					{
						match (wp.WeatherAction)
						{
							PBEWeatherAction.Added: return "It started to rain!";
							PBEWeatherAction.Ended: return "The rain stopped.";
							_: throw new InvalidDataException(nameof(wp.WeatherAction));
						}
					}
					PBEWeather.Sandstorm:
					{
						match (wp.WeatherAction)
						{
							PBEWeatherAction.Added: return "A sandstorm kicked up!";
							PBEWeatherAction.Ended: return "The sandstorm subsided.";
							_: throw new InvalidDataException(nameof(wp.WeatherAction));
						}
					}
					_: throw new InvalidDataException(nameof(wp.Weather));
				}
			}
			PBEWeatherDamagePacket wdp:
			{
				PBEBattlePokemon damageVictim = wdp.DamageVictimTrainer.GetPokemon(wdp.DamageVictim);
				string message;
				match (wdp.Weather)
				{
					PBEWeather.Hailstorm: message = "{0} is buffeted by the hail!"; break;
					PBEWeather.Sandstorm: message = "{0} is buffeted by the sandstorm!"; break;
					_: throw new InvalidDataException(nameof(wdp.Weather));
				}
				return string.Format(message, GetPkmnName(damageVictim, true));
			}
			IPBEWildPkmnAppearedPacket wpap:
			{
				return string.Format("{0}{1} appeared!", wpap.Pokemon.Count == 1 ? "A wild " : "Oh! A wild ", wpap.Pokemon.Select(s => s.Nickname).ToArray().Andify());
			}
			PBEActionsRequestPacket arp:
			{
				return string.Format("{0} must submit actions for {1} Pokémon.", GetTrainerName(arp.Trainer), arp.Pokemon.Count);
			}
			IPBEAutoCenterPacket _:
			{
				return "The battlers shifted to the center!";
			}
			PBEBattleResultPacket brp:
			{
				bool team0Caps = true;
				bool team1Caps = false;
				string message;
				match (brp.BattleResult)
				{
					PBEBattleResult.Team0Forfeit: message = "{0} forfeited."; break;
					PBEBattleResult.Team0Win: message = "{0} defeated {1}!"; break;
					PBEBattleResult.Team1Forfeit: message = "{1} forfeited."; team1Caps = true; break;
					PBEBattleResult.Team1Win: message = "{1} defeated {0}!"; team0Caps = false; team1Caps = true; break;
					PBEBattleResult.WildCapture: goto bottom;
					PBEBattleResult.WildEscape: message = "{0} got away!"; break;
					PBEBattleResult.WildFlee: message = "{1} got away!"; team1Caps = true; break;
					_: throw new InvalidDataException(nameof(brp.BattleResult));
				}
				return string.Format(message, GetRawCombinedName(battle.Teams[0], team0Caps), GetRawCombinedName(battle.Teams[1], team1Caps));
			}
			PBESwitchInRequestPacket sirp:
			{
				return string.Format("{0} must send in {1} Pokémon.", GetTrainerName(sirp.Trainer), sirp.Amount);
			}
			PBETurnBeganPacket tbp:
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

#public sealed partial class PBEBattle
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
		match (battleFormat)
		{
			PBEBattleFormat.Single:
			PBEBattleFormat.Rotation:
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
			PBEBattleFormat.Double:
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
			PBEBattleFormat.Triple:
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
			_: throw new ArgumentOutOfRangeException(nameof(battleFormat));
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
		match (pkmn.Battle.BattleFormat)
		{
			PBEBattleFormat.Single:
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
			PBEBattleFormat.Double:
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
			PBEBattleFormat.Triple:
			PBEBattleFormat.Rotation:
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
			_: throw new InvalidDataException(nameof(pkmn.Battle.BattleFormat));
		}
	}

	private static void FindFoeLeftTarget(PBEBattlePokemon user, bool canHitFarCorners, List<PBEBattlePokemon> targets)
	{
		PBETeam ot = user.Team.OpposingTeam;
		if (!ot.TryGetPokemon(PBEFieldPosition.Left, out PBEBattlePokemon? pkmn))
		{
			# Left not found; fallback to its teammate
			match (user.Battle.BattleFormat)
			{
				PBEBattleFormat.Double:
				{
					if (!ot.TryGetPokemon(PBEFieldPosition.Right, out pkmn))
					{
						return; # Nobody left and nobody right; fail
					}
					break;
				}
				PBEBattleFormat.Triple:
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
				_: throw new InvalidOperationException();
			}
		}
		targets.Add(pkmn);
	}
	private static void FindFoeCenterTarget(PBEBattlePokemon user, bool canHitFarCorners, PBERandom rand, List<PBEBattlePokemon> targets)
	{
		PBETeam ot = user.Team.OpposingTeam;
		if (!ot.TryGetPokemon(PBEFieldPosition.Center, out PBEBattlePokemon? pkmn))
		{
			match (user.Battle.BattleFormat)
			{
				PBEBattleFormat.Single:
				PBEBattleFormat.Rotation: return;
				_: throw new InvalidOperationException();
				PBEBattleFormat.Triple:
				{
					# Center not found; fallback to its teammate
					match (user.FieldPosition)
					{
						PBEFieldPosition.Left:
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
						PBEFieldPosition.Center:
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
						PBEFieldPosition.Right:
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
						_: throw new InvalidDataException();
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
			match (user.Battle.BattleFormat)
			{
				PBEBattleFormat.Double:
				{
					if (!ot.TryGetPokemon(PBEFieldPosition.Left, out pkmn))
					{
						return; # Nobody right and nobody left; fail
					}
					break;
				}
				PBEBattleFormat.Triple:
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
				_: throw new InvalidOperationException();
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
		match (pkmn.Battle.BattleFormat)
		{
			PBEBattleFormat.Single:
			{
				match (possibleTargets)
				{
					PBEMoveTarget.All:
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
					PBEMoveTarget.AllFoes:
					PBEMoveTarget.AllFoesSurrounding:
					PBEMoveTarget.AllSurrounding:
					PBEMoveTarget.SingleFoeSurrounding:
					PBEMoveTarget.SingleNotSelf:
					PBEMoveTarget.SingleSurrounding:
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
					PBEMoveTarget.AllTeam:
					PBEMoveTarget.RandomFoeSurrounding:
					PBEMoveTarget.Self:
					PBEMoveTarget.SelfOrAllySurrounding:
					PBEMoveTarget.SingleAllySurrounding:
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
					_: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			PBEBattleFormat.Double:
			{
				match (possibleTargets)
				{
					PBEMoveTarget.All:
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
					PBEMoveTarget.AllFoes:
					PBEMoveTarget.AllFoesSurrounding:
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
					PBEMoveTarget.AllTeam:
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
					PBEMoveTarget.AllSurrounding:
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
					PBEMoveTarget.RandomFoeSurrounding:
					PBEMoveTarget.Self:
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
					PBEMoveTarget.SelfOrAllySurrounding:
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
					PBEMoveTarget.SingleAllySurrounding:
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
					PBEMoveTarget.SingleFoeSurrounding:
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
					PBEMoveTarget.SingleNotSelf:
					PBEMoveTarget.SingleSurrounding:
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
					_: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			PBEBattleFormat.Triple:
			{
				match (possibleTargets)
				{
					PBEMoveTarget.All:
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
					PBEMoveTarget.AllFoes:
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
					PBEMoveTarget.AllFoesSurrounding:
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
					PBEMoveTarget.AllSurrounding:
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
					PBEMoveTarget.AllTeam:
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
					PBEMoveTarget.RandomFoeSurrounding:
					PBEMoveTarget.Self:
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
					PBEMoveTarget.SelfOrAllySurrounding:
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
					PBEMoveTarget.SingleAllySurrounding:
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
					PBEMoveTarget.SingleFoeSurrounding:
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
					PBEMoveTarget.SingleNotSelf:
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
					PBEMoveTarget.SingleSurrounding:
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
					_: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			PBEBattleFormat.Rotation:
			{
				match (possibleTargets)
				{
					PBEMoveTarget.All:
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
					PBEMoveTarget.AllFoes:
					PBEMoveTarget.AllFoesSurrounding:
					PBEMoveTarget.AllSurrounding:
					PBEMoveTarget.SingleFoeSurrounding:
					PBEMoveTarget.SingleNotSelf:
					PBEMoveTarget.SingleSurrounding:
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
					PBEMoveTarget.AllTeam:
					PBEMoveTarget.RandomFoeSurrounding:
					PBEMoveTarget.Self:
					PBEMoveTarget.SelfOrAllySurrounding:
					PBEMoveTarget.SingleAllySurrounding:
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
					_: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			_: throw new InvalidDataException(nameof(pkmn.Battle.BattleFormat));
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
		match (pkmn.Battle.BattleFormat)
		{
			PBEBattleFormat.Single:
			{
				match (possibleTargets)
				{
					PBEMoveTarget.All:
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
					PBEMoveTarget.AllFoes:
					PBEMoveTarget.AllFoesSurrounding:
					PBEMoveTarget.AllSurrounding:
					PBEMoveTarget.RandomFoeSurrounding:
					PBEMoveTarget.SingleFoeSurrounding:
					PBEMoveTarget.SingleNotSelf:
					PBEMoveTarget.SingleSurrounding:
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
					PBEMoveTarget.AllTeam:
					PBEMoveTarget.Self:
					PBEMoveTarget.SelfOrAllySurrounding:
					PBEMoveTarget.SingleAllySurrounding: # Helping Hand cannot be called by Metronome anyway
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
					_: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			PBEBattleFormat.Double:
			{
				match (possibleTargets)
				{
					PBEMoveTarget.All:
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
					PBEMoveTarget.AllFoes:
					PBEMoveTarget.AllFoesSurrounding:
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
					PBEMoveTarget.AllTeam:
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
					PBEMoveTarget.AllSurrounding:
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
					PBEMoveTarget.Self:
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
					PBEMoveTarget.SelfOrAllySurrounding:
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
					PBEMoveTarget.SingleAllySurrounding: # Helping Hand cannot be called by Metronome anyway
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
					PBEMoveTarget.RandomFoeSurrounding:
					PBEMoveTarget.SingleFoeSurrounding:
					PBEMoveTarget.SingleNotSelf:
					PBEMoveTarget.SingleSurrounding:
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
					_: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			PBEBattleFormat.Triple:
			{
				match (possibleTargets)
				{
					PBEMoveTarget.All:
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
					PBEMoveTarget.AllFoes:
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
					PBEMoveTarget.AllFoesSurrounding:
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
					PBEMoveTarget.AllSurrounding:
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
					PBEMoveTarget.AllTeam:
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
					PBEMoveTarget.Self:
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
					PBEMoveTarget.SelfOrAllySurrounding:
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
					PBEMoveTarget.SingleAllySurrounding: # Helping Hand cannot be called by Metronome anyway
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
					PBEMoveTarget.RandomFoeSurrounding:
					PBEMoveTarget.SingleFoeSurrounding:
					PBEMoveTarget.SingleSurrounding:
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
					PBEMoveTarget.SingleNotSelf:
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
					_: throw new InvalidDataException(nameof(possibleTargets));
				}
			}
			PBEBattleFormat.Rotation:
			{
				match (possibleTargets)
				{
					PBEMoveTarget.All:
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
					PBEMoveTarget.AllFoes:
					PBEMoveTarget.AllFoesSurrounding:
					PBEMoveTarget.AllSurrounding:
					PBEMoveTarget.RandomFoeSurrounding:
					PBEMoveTarget.SingleFoeSurrounding:
					PBEMoveTarget.SingleNotSelf:
					PBEMoveTarget.SingleSurrounding:
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
					PBEMoveTarget.AllTeam:
					PBEMoveTarget.Self:
					PBEMoveTarget.SelfOrAllySurrounding:
					PBEMoveTarget.SingleAllySurrounding: # Helping Hand cannot be called by Metronome anyway
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyCenter;
						}
						else
						{
							throw new InvalidDataException(nameof(pkmn.FieldPosition));
					_: throw new InvalidDataException(nameof(possibleTargets));
			_: throw new InvalidDataException(nameof(pkmn.Battle.BattleFormat));



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
