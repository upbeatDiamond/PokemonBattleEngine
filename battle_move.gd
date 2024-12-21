class_name PBEMove

var Type : PBEType
var Category : PBEMoveCategory
var Priority : int
##/ <summary>0 PPTier will become 1 PP (unaffected by pp ups)</summary>
var PPTier : int
##/ <summary>0 power will show up as --</summary>
var Power : int
##/ <summary>0 accuracy will show up as --</summary>
var Accuracy : int
var Effect : PBEMoveEffect
var EffectParam : int
var Targets : PBEMoveTarget
var Flags : PBEMoveFlag

#public static class PBEMoveDataExtensions

func HasSecondaryEffects(settings : PBESettings) -> bool:
	return Effect.HasSecondaryEffects(settings);


func IsHPDrainMove() -> bool:
	return Effect.IsHPDrainMove();


func IsHPRestoreMove() -> bool:
	return Effect.IsHPRestoreMove();


func IsMultiHitMove() -> bool:
	return Effect.IsMultiHitMove();


func IsRecoilMove() -> bool:
	return Effect.IsRecoilMove();


func IsSetDamageMove() -> bool:
	return Effect.IsSetDamageMove();


func IsSpreadMove() -> bool:
	return Effect.IsSpreadMove();


func IsWeatherMove() -> bool:
	return Effect.IsWeatherMove();

## <summary>Temporary check to see if a move is usable, can be removed once all moves are added</summary>
func IsMoveUsable() -> bool:
	return Effect.IsMoveUsable();


func _init(type:PBEType, category:PBEMoveCategory, priority:int, ppTier:int, power:int, accuracy:int,
	effect:PBEMoveEffect, effectParam:int, targets:PBEMoveTarget, flags:PBEMoveFlag):
	Type = type; 
	Category = category; 
	Priority = priority; 
	PPTier = ppTier; 
	Power = power; 
	Accuracy = accuracy;
	Effect = effect; 
	EffectParam = effectParam; 
	Targets = targets;
	Flags = flags;


func _to_string() -> String:#String() -> String:
	var sb = str("Type: ", Type)
	str("Category: ", Category)
	str("Priority: ", Priority)
	str("PP: ", max(1, PPTier * PBESettings.DefaultPPMultiplier))
	str("Power: ", ("-" if Power == 0 else str(Power)))
	str("Accuracy: ", ("-" if Accuracy == 0 else str(Accuracy)))
	str("Effect: ", Effect)
	str("Effect Parameter: ", EffectParam)
	str("Targets: ", Targets)
	str("Flags: ", Flags)
	return sb


func CalculateBasePower(user:PBEBattlePokemon, targets:Array[PBEBattlePokemon], mData:IPBEMoveData, moveType:PBEType) -> float:
	var basePower : float
	
	#region Get move's base power
	match (mData.Effect):
		PBEMoveEffect.CrushGrip:
			basePower = max(1, targets.filter(func(t): return mData.Power * t.HP / t.MaxHP).Average());
		PBEMoveEffect.Eruption:
			basePower = max(1, mData.Power * user.HP / user.MaxHP);
		PBEMoveEffect.Frustration:
			basePower = max(1, (byte.MaxValue - user.Friendship) / 2.0);
		PBEMoveEffect.GrassKnot:
			basePower = targets.Select(func(t):
				if (t.Weight >= 200.0):
					return 12;
				elif (t.Weight >= 100.0):
					return 10;
				elif (t.Weight >= 50.0):
					return 8;
				elif (t.Weight >= 25.0):
					return 6;
				elif (t.Weight >= 10.0):
					return 4;
				return 2;
			).Average();
		PBEMoveEffect.HeatCrash:
			basePower = targets.Select(func(t):
				var relative = user.Weight / t.Weight;
				if (relative < 2):
					return 4
				elif (relative < 3):
					return 6
				elif (relative < 4):
					return 8;
				elif (relative < 5):
					return 10;
				return 12;
			).Average();
		PBEMoveEffect.HiddenPower:
			basePower = user.IndividualValues.GetHiddenPowerBasePower(Settings);
		PBEMoveEffect.Magnitude:
			var val = randi_range(0, 99);
			var magnitude : int
			if (val < 5): # Magnitude 4 - 5%
				magnitude = 4
				basePower = 10
			elif (val < 15): # Magnitude 5 - 10%
				magnitude = 5
				basePower = 30
			elif (val < 35): # Magnitude 6 - 20%
				magnitude = 6
				basePower = 50
			elif (val < 65): # Magnitude 7 - 30%
				magnitude = 7
				basePower = 70
			elif (val < 85): # Magnitude 8 - 20%
				magnitude = 8
				basePower = 90
			elif (val < 95): # Magnitude 9 - 10%
				magnitude = 9
				basePower = 110
			else: # Magnitude 10 - 5%
				magnitude = 10
				basePower = 150
			BroadcastMagnitude(magnitude);
		PBEMoveEffect.Punishment:
			basePower = max(1, Math.Min(200, targets.Select(func(t): mData.Power + (2 * t.GetPositiveStatTotal())).Average()));
		PBEMoveEffect.Return:
			basePower = max(1, user.Friendship / 2.0);
		PBEMoveEffect.StoredPower:
			basePower = mData.Power + (20 * user.GetPositiveStatTotal());
		_:
			basePower = max(1, floori(mData.Power) );
	#endregion

	# Technician goes before any other power boosts
	if (user.Ability == PBEAbility.Technician && basePower <= 60):
		basePower *= 1.5

	#region Item-specific power boosts
	match (moveType):
		PBEType.Bug:
			match (user.Item):
				PBEItem.InsectPlate, PBEItem.SilverPowder:
					basePower *= 1.2
				PBEItem.BugGem:
					BroadcastItem(user, user, PBEItem.BugGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Dark:
			match (user.Item):
				PBEItem.BlackGlasses, PBEItem.DreadPlate:
					basePower *= 1.2
				PBEItem.DarkGem:
					BroadcastItem(user, user, PBEItem.DarkGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Dragon:
			match (user.Item):
				PBEItem.AdamantOrb:
					if (user.OriginalSpecies == PBESpecies.Dialga):
						basePower *= 1.2
				PBEItem.DracoPlate, \
				PBEItem.DragonFang:
					basePower *= 1.2
				PBEItem.GriseousOrb:
					if (user.OriginalSpecies == PBESpecies.Giratina && user.RevertForm == PBEForm.Giratina_Origin):
						basePower *= 1.2
				PBEItem.LustrousOrb:
					if (user.OriginalSpecies == PBESpecies.Palkia):
						basePower *= 1.2
				PBEItem.DragonGem:
					BroadcastItem(user, user, PBEItem.DragonGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Electric:
			match (user.Item):
				PBEItem.Magnet, \
				PBEItem.ZapPlate:
					basePower *= 1.2
				PBEItem.ElectricGem:
					BroadcastItem(user, user, PBEItem.ElectricGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Fighting:
			match (user.Item):
				PBEItem.BlackBelt, \
				PBEItem.FistPlate:
					basePower *= 1.2
				PBEItem.FightingGem:
					BroadcastItem(user, user, PBEItem.FightingGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Fire:
			match (user.Item):
				PBEItem.Charcoal, \
				PBEItem.FlamePlate:
					basePower *= 1.2
				PBEItem.FireGem:
					BroadcastItem(user, user, PBEItem.FireGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Flying:
			match (user.Item):
				PBEItem.SharpBeak, \
				PBEItem.SkyPlate:
					basePower *= 1.2
				PBEItem.FlyingGem:
					BroadcastItem(user, user, PBEItem.FlyingGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Ghost:
			match (user.Item):
				PBEItem.GriseousOrb:
					if (user.OriginalSpecies == PBESpecies.Giratina && user.RevertForm == PBEForm.Giratina_Origin):
						basePower *= 1.2
				PBEItem.SpellTag, \
				PBEItem.SpookyPlate:
					basePower *= 1.2
				PBEItem.GhostGem:
					BroadcastItem(user, user, PBEItem.GhostGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Grass:
			match (user.Item):
				PBEItem.MeadowPlate, \
				PBEItem.MiracleSeed, \
				PBEItem.RoseIncense:
					basePower *= 1.2
				PBEItem.GrassGem:
					BroadcastItem(user, user, PBEItem.GrassGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Ground:
			match (user.Item):
				PBEItem.EarthPlate, \
				PBEItem.SoftSand:
					basePower *= 1.2
				PBEItem.GroundGem:
					BroadcastItem(user, user, PBEItem.GroundGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Ice:
			match (user.Item):
				PBEItem.IciclePlate, \
				PBEItem.NeverMeltIce:
					basePower *= 1.2
				PBEItem.IceGem:
					BroadcastItem(user, user, PBEItem.IceGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.None:
			pass
		PBEType.Normal:
			match (user.Item):
				PBEItem.SilkScarf:
					basePower *= 1.2
				PBEItem.NormalGem:
					BroadcastItem(user, user, PBEItem.NormalGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Poison:
			match (user.Item):
				PBEItem.PoisonBarb, \
				PBEItem.ToxicPlate:
					basePower *= 1.2
				PBEItem.PoisonGem:
					BroadcastItem(user, user, PBEItem.PoisonGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Psychic:
			match (user.Item):
				PBEItem.MindPlate, \
				PBEItem.OddIncense, \
				PBEItem.TwistedSpoon:
					basePower *= 1.2
				PBEItem.PsychicGem:
					BroadcastItem(user, user, PBEItem.PsychicGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Rock:
			match (user.Item):
				PBEItem.HardStone, \
				PBEItem.RockIncense, \
				PBEItem.StonePlate:
					basePower *= 1.2
				PBEItem.RockGem:
					BroadcastItem(user, user, PBEItem.RockGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Steel:
			match (user.Item):
				PBEItem.AdamantOrb:
					if (user.OriginalSpecies == PBESpecies.Dialga):
						basePower *= 1.2
				PBEItem.IronPlate, \
				PBEItem.MetalCoat:
					basePower *= 1.2
				PBEItem.SteelGem:
					BroadcastItem(user, user, PBEItem.SteelGem, PBEItemAction.Consumed);
					basePower *= 1.5
		PBEType.Water:
			match (user.Item):
				PBEItem.LustrousOrb:
					if (user.OriginalSpecies == PBESpecies.Palkia):
						basePower *= 1.2
				PBEItem.MysticWater, \
				PBEItem.SeaIncense, \
				PBEItem.SplashPlate, \
				PBEItem.WaveIncense:
					basePower *= 1.2
				PBEItem.WaterGem:
					BroadcastItem(user, user, PBEItem.WaterGem, PBEItemAction.Consumed);
					basePower *= 1.5
		_: pass #throw new ArgumentOutOfRangeException(nameof(moveType));
	#endregion

	#region Move-specific power boosts
	match (mData.Effect):
		PBEMoveEffect.Acrobatics:
			if (user.Item == PBEItem.None):
				basePower *= 2.0
		PBEMoveEffect.Facade:
			if (user.Status1 == PBEStatus1.Burned || user.Status1 == PBEStatus1.Paralyzed || user.Status1 == PBEStatus1.Poisoned || user.Status1 == PBEStatus1.BadlyPoisoned):
				basePower *= 2.0
		PBEMoveEffect.Retaliate:
			if (user.Team.MonFaintedLastTurn):
				basePower *= 2.0
		PBEMoveEffect.WeatherBall:
			if (ShouldDoWeatherEffects() && Weather != PBEWeather.None):
				basePower *= 2.0
	#endregion

	#region Weather-specific power boosts
	if (ShouldDoWeatherEffects()):
		match (Weather):
			PBEWeather.HarshSunlight:
				if (moveType == PBEType.Fire):
					basePower *= 1.5
				elif (moveType == PBEType.Water):
					basePower *= 0.5
			PBEWeather.Rain:
				if (moveType == PBEType.Water):
					basePower *= 1.5
				elif (moveType == PBEType.Fire):
					basePower *= 0.5
			PBEWeather.Sandstorm:
				if (user.Ability == PBEAbility.SandForce && (moveType == PBEType.Rock || moveType == PBEType.Ground || moveType == PBEType.Steel)):
					basePower *= 1.3
	#endregion

	#region Other power boosts
	if (user.Status2.HasFlag(PBEStatus2.HelpingHand)):
		basePower *= 1.5
	if (user.Ability == PBEAbility.FlareBoost && mData.Category == PBEMoveCategory.Special && user.Status1 == PBEStatus1.Burned):
		basePower *= 1.5
	if (user.Ability == PBEAbility.ToxicBoost && mData.Category == PBEMoveCategory.Physical && (user.Status1 == PBEStatus1.Poisoned || user.Status1 == PBEStatus1.BadlyPoisoned)):
		basePower *= 1.5
	if (user.Item == PBEItem.LifeOrb):
		basePower *= 1.3
	if (user.Ability == PBEAbility.IronFist && mData.Flags.HasFlag(PBEMoveFlag.AffectedByIronFist)):
		basePower *= 1.2
	if (user.Ability == PBEAbility.Reckless && mData.Flags.HasFlag(PBEMoveFlag.AffectedByReckless)):
		basePower *= 1.2
	if (user.Item == PBEItem.MuscleBand && mData.Category == PBEMoveCategory.Physical):
		basePower *= 1.1
	if (user.Item == PBEItem.WiseGlasses && mData.Category == PBEMoveCategory.Special):
		basePower *= 1.1
	#endregion

	return basePower;


func CalculateDamageMultiplier(user:PBEBattlePokemon, target:PBEBattlePokemon, mData:IPBEMoveData, moveType:PBEType, moveResult:PBEResult, criticalHit:bool) -> float:
	var damageMultiplier : float = 1;
	if (target.Status2.HasFlag(PBEStatus2.Airborne) && mData.Flags.HasFlag(PBEMoveFlag.DoubleDamageAirborne)):
		damageMultiplier *= 2.0
	if (target.Minimize_Used && mData.Flags.HasFlag(PBEMoveFlag.DoubleDamageMinimized)):
		damageMultiplier *= 2.0
	if (target.Status2.HasFlag(PBEStatus2.Underground) && mData.Flags.HasFlag(PBEMoveFlag.DoubleDamageUnderground)):
		damageMultiplier *= 2.0
	if (target.Status2.HasFlag(PBEStatus2.Underwater) && mData.Flags.HasFlag(PBEMoveFlag.DoubleDamageUnderwater)):
		damageMultiplier *= 2.0

	if (criticalHit):
		damageMultiplier *= Settings.CritMultiplier
		if (user.Ability == PBEAbility.Sniper):
			damageMultiplier *= 1.5
	elif (user.Ability != PBEAbility.Infiltrator):
		if ((target.Team.TeamStatus.HasFlag(PBETeamStatus.Reflect) && mData.Category == PBEMoveCategory.Physical) \
			|| (target.Team.TeamStatus.HasFlag(PBETeamStatus.LightScreen) && mData.Category == PBEMoveCategory.Special)):
			if (target.Team.NumPkmnOnField == 1):
				damageMultiplier *= 0.0
			else:
				damageMultiplier *= 0.66

	match (moveResult):
		PBEResult.NotVeryEffective_Type:
			if (user.Ability == PBEAbility.TintedLens):
				damageMultiplier *= 2.0
		PBEResult.SuperEffective_Type:
			if ((target.Ability == PBEAbility.Filter || target.Ability == PBEAbility.SolidRock) && !user.HasCancellingAbility()):
				damageMultiplier *= 0.75;
			if (user.Item == PBEItem.ExpertBelt):
				damageMultiplier *= 1.2
	if (user.ReceivesSTAB(moveType)):
		if (user.Ability == PBEAbility.Adaptability):
			damageMultiplier *= 2.0
		else:
			damageMultiplier *= 1.5
	if (mData.Category == PBEMoveCategory.Physical && user.Status1 == PBEStatus1.Burned && user.Ability != PBEAbility.Guts):
		damageMultiplier *= 0.5
	if (moveType == PBEType.Fire && target.Ability == PBEAbility.Heatproof && !user.HasCancellingAbility()):
		damageMultiplier *= 0.5
	return damageMultiplier


func CalculateAttack(user:PBEBattlePokemon, target:PBEBattlePokemon, moveType:PBEType, initialAttack:float) -> float:
	var attack : float = initialAttack;
	
	if (user.Ability == PBEAbility.HugePower || user.Ability == PBEAbility.PurePower):
		attack *= 2.0
	if (user.Item == PBEItem.ThickClub && (user.OriginalSpecies == PBESpecies.Cubone || user.OriginalSpecies == PBESpecies.Marowak)):
		attack *= 2.0
	if (user.Item == PBEItem.LightBall && user.OriginalSpecies == PBESpecies.Pikachu):
		attack *= 2.0
	if (moveType == PBEType.Bug && user.Ability == PBEAbility.Swarm && user.HP <= user.MaxHP / 3):
		attack *= 1.5
	if (moveType == PBEType.Fire && user.Ability == PBEAbility.Blaze && user.HP <= user.MaxHP / 3):
		attack *= 1.5
	if (moveType == PBEType.Grass && user.Ability == PBEAbility.Overgrow && user.HP <= user.MaxHP / 3):
		attack *= 1.5
	if (moveType == PBEType.Water && user.Ability == PBEAbility.Torrent && user.HP <= user.MaxHP / 3):
		attack *= 1.5
	if (user.Ability == PBEAbility.Hustle):
		attack *= 1.5
	if (user.Ability == PBEAbility.Guts && user.Status1 != PBEStatus1.None):
		attack *= 1.5
	if (user.Item == PBEItem.ChoiceBand):
		attack *= 1.5
	#if (!user.HasCancellingAbility() && ShouldDoWeatherEffects() && Weather == PBEWeather.HarshSunlight && user.Team.ActiveBattlers.FindIndex(p => p.Ability == PBEAbility.FlowerGift) != -1):
		#attack *= 1.5
	if ((moveType == PBEType.Fire || moveType == PBEType.Ice) && target.Ability == PBEAbility.ThickFat && user.HasCancellingAbility()):
		attack *= 0.5
	if (user.Ability == PBEAbility.Defeatist && user.HP <= user.MaxHP / 2):
		attack *= 0.5
	if (user.Ability == PBEAbility.SlowStart && user.SlowStart_HinderTurnsLeft > 0):
		attack *= 0.5
	return attack;


func CalculateDamage(user:PBEBattlePokemon, target:PBEBattlePokemon, mData:IPBEMoveData, moveType:PBEType, basePower:float, criticalHit:bool) -> int:
	var aPkmn : PBEBattlePokemon
	var aCat : PBEMoveCategory = mData.Category
	var dCat : PBEMoveCategory
	
	match (mData.Effect):
		PBEMoveEffect.FoulPlay:
			aPkmn = target
			dCat = aCat
		PBEMoveEffect.Psyshock:
			aPkmn = user
			dCat = PBEMoveCategory.Physical
		_:
			aPkmn = user
			dCat = aCat

	var ignoreA : bool = user != target && target.Ability == PBEAbility.Unaware && !user.HasCancellingAbility();
	var ignoreD : bool  = user != target && (mData.Effect == PBEMoveEffect.ChipAway || user.Ability == PBEAbility.Unaware);
	var a : float
	var d : float
	if (aCat == PBEMoveCategory.Physical):
		var m : float = 1 if ignoreA else GetStatChangeModifier(max(0, aPkmn.AttackChange) if criticalHit else aPkmn.AttackChange, false);
		a = CalculateAttack(user, target, moveType, aPkmn.Attack * m);
	else:
		var m : float = 1 if ignoreA else GetStatChangeModifier(max(0, aPkmn.SpAttackChange) if criticalHit else aPkmn.SpAttackChange, false);
		a = CalculateSpAttack(user, target, moveType, aPkmn.SpAttack * m);
	if (dCat == PBEMoveCategory.Physical):
		var m : float = 1 if ignoreD else GetStatChangeModifier(min(0, target.DefenseChange) if criticalHit else target.DefenseChange, false);
		d = CalculateDefense(user, target, target.Defense * m);
	else:
		var m : float = 1 if ignoreD else GetStatChangeModifier(min(0, target.SpDefenseChange) if criticalHit else target.SpDefenseChange, false);
		d = CalculateSpDefense(user, target, target.SpDefense * m);

	return CalculateDamage(user, a, d, basePower);
