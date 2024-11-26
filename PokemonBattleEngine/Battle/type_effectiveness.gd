class_name PBETypeEffectiveness

#region Static Collections
## <summary>The type effectiveness table. The first key is the attacking type and the second key is the defending type.</summary>
var _table : Dictionary = {
			PBEEnums.PBEType.None: { 
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 1.0,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 1.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 1.0,
				PBEEnums.PBEType.Steel: 1.0,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Bug: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 2.0,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 0.5,
				PBEEnums.PBEType.Fire: 0.5,
				PBEEnums.PBEType.Flying: 0.5,
				PBEEnums.PBEType.Ghost: 0.5,
				PBEEnums.PBEType.Grass: 2.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 0.5,
				PBEEnums.PBEType.Psychic: 2.0,
				PBEEnums.PBEType.Rock: 1.0,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Dark: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 0.5,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 0.5,
				PBEEnums.PBEType.Fire: 1.0,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 2.0,
				PBEEnums.PBEType.Grass: 1.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 2.0,
				PBEEnums.PBEType.Rock: 1.0,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Dragon: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 2.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 1.0,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 1.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 1.0,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Electric: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 0.5,
				PBEEnums.PBEType.Electric: 0.5,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 1.0,
				PBEEnums.PBEType.Flying: 2.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 0.5,
				PBEEnums.PBEType.Ground: 0.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 1.0,
				PBEEnums.PBEType.Steel: 1.0,
				PBEEnums.PBEType.Water: 2.0,
		},
			PBEEnums.PBEType.Fighting: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 0.5,
				PBEEnums.PBEType.Dark: 2.0,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 1.0,
				PBEEnums.PBEType.Flying: 0.5,
				PBEEnums.PBEType.Ghost: 0.0,
				PBEEnums.PBEType.Grass: 1.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 2.0,
				PBEEnums.PBEType.Normal: 2.0,
				PBEEnums.PBEType.Poison: 0.5,
				PBEEnums.PBEType.Psychic: 0.5,
				PBEEnums.PBEType.Rock: 2.0,
				PBEEnums.PBEType.Steel: 2.0,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Fire: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 2.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 0.5,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 0.5,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 2.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 2.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 0.5,
				PBEEnums.PBEType.Steel: 2.0,
				PBEEnums.PBEType.Water: 0.5,
		},
			PBEEnums.PBEType.Flying: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 2.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 0.5,
				PBEEnums.PBEType.Fighting: 2.0,
				PBEEnums.PBEType.Fire: 1.0,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 2.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 0.5,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Ghost: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 0.5,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 1.0,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 2.0,
				PBEEnums.PBEType.Grass: 1.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 0.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 2.0,
				PBEEnums.PBEType.Rock: 1.0,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Grass: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 0.5,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 0.5,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 0.5,
				PBEEnums.PBEType.Flying: 0.5,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 0.5,
				PBEEnums.PBEType.Ground: 2.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 0.5,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 2.0,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 2.0,
		},
			PBEEnums.PBEType.Ground: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 0.5,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 2.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 2.0,
				PBEEnums.PBEType.Flying: 0.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 0.5,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 2.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 2.0,
				PBEEnums.PBEType.Steel: 2.0,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Ice: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 2.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 0.5,
				PBEEnums.PBEType.Flying: 2.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 2.0,
				PBEEnums.PBEType.Ground: 2.0,
				PBEEnums.PBEType.Ice: 0.5,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 1.0,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 0.5,
		},
			PBEEnums.PBEType.Normal: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 1.0,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 0.0,
				PBEEnums.PBEType.Grass: 1.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 0.5,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Poison: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 1.0,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 0.5,
				PBEEnums.PBEType.Grass: 2.0,
				PBEEnums.PBEType.Ground: 0.5,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 0.5,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 0.5,
				PBEEnums.PBEType.Steel: 0.0,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Psychic: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 0.0,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 2.0,
				PBEEnums.PBEType.Fire: 1.0,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 1.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 2.0,
				PBEEnums.PBEType.Psychic: 0.5,
				PBEEnums.PBEType.Rock: 1.0,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Rock: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 2.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 0.5,
				PBEEnums.PBEType.Fire: 2.0,
				PBEEnums.PBEType.Flying: 2.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 1.0,
				PBEEnums.PBEType.Ground: 0.5,
				PBEEnums.PBEType.Ice: 2.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 1.0,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 1.0,
		},
			PBEEnums.PBEType.Steel: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 1.0,
				PBEEnums.PBEType.Electric: 0.5,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 0.5,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 1.0,
				PBEEnums.PBEType.Ground: 1.0,
				PBEEnums.PBEType.Ice: 2.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 2.0,
				PBEEnums.PBEType.Steel: 0.5,
				PBEEnums.PBEType.Water: 0.5,
		},
			PBEEnums.PBEType.Water: {
				PBEEnums.PBEType.None: 1.0,
				PBEEnums.PBEType.Bug: 1.0,
				PBEEnums.PBEType.Dark: 1.0,
				PBEEnums.PBEType.Dragon: 0.5,
				PBEEnums.PBEType.Electric: 1.0,
				PBEEnums.PBEType.Fighting: 1.0,
				PBEEnums.PBEType.Fire: 2.0,
				PBEEnums.PBEType.Flying: 1.0,
				PBEEnums.PBEType.Ghost: 1.0,
				PBEEnums.PBEType.Grass: 0.5,
				PBEEnums.PBEType.Ground: 2.0,
				PBEEnums.PBEType.Ice: 1.0,
				PBEEnums.PBEType.Normal: 1.0,
				PBEEnums.PBEType.Poison: 1.0,
				PBEEnums.PBEType.Psychic: 1.0,
				PBEEnums.PBEType.Rock: 2.0,
				PBEEnums.PBEType.Steel: 1.0,
				PBEEnums.PBEType.Water: 0.5,
		}
}
#endregion

static func IsAffectedByAttack(user:PBEBattlePokemon, target:PBEBattlePokemon, moveType:PBEEnums.PBEType, damageMultiplier:float, useKnownInfo:=false) -> PBEEnums.PBEResult:
	if (moveType >= PBEEnums.PBEType.MAX):
		pass #throw new ArgumentOutOfRangeException(nameof(moveType));
	
	var result : PBEEnums.PBEResult
	
	if (moveType == PBEEnums.PBEType.Ground):
		result = target.IsGrounded(user, useKnownInfo)
		if (result != PBEEnums.PBEResult.Success):
			damageMultiplier = 0;
			return result
	
	var ignoreGhost : bool = user.Ability == PBEAbility.Scrappy || target.Status2.HasFlag(PBEStatus2.Identified)
	var ignoreDark : bool = target.Status2.HasFlag(PBEStatus2.MiracleEye)
	damageMultiplier = GetEffectiveness(moveType, target.types, useKnownInfo, ignoreGhost, ignoreDark)
	if (damageMultiplier <= 0): # (-infinity, 0]
		damageMultiplier = 0;
		return PBEResult.Ineffective_Type;
	
	elif (damageMultiplier < 1): # (0, 1)
		result = PBEResult.NotVeryEffective_Type;
	
	elif (damageMultiplier == 1): # [1, 1]
		result = PBEResult.Success;
	
	else: # (1, infinity)
		return PBEResult.SuperEffective_Type;
	
	var kAbility : PBEAbility = useKnownInfo if target.KnownAbility else target.Ability
	if (kAbility == PBEAbility.WonderGuard && !user.HasCancellingAbility()):
		damageMultiplier = 0;
		result = PBEResult.Ineffective_Ability;
	
	return result;

## <summary>Checks if <see cref="PBEMoveEffect.ThunderWave"/>'s type affects the target, taking into account <see cref="PBEAbility.Normalize"/>.</summary>
static func ThunderWaveTypeCheck(user:PBEBattlePokemon, target:PBEBattlePokemon, move:PBEEnums.PBEMove, useKnownInfo:=false) -> PBEEnums.PBEResult:
	var moveType : PBEType = user.GetMoveType(move);
	var d : float = GetEffectiveness(moveType, target, useKnownInfo);
	if (d <= 0):
		return PBEResult.Ineffective_Type;
	return PBEResult.Success;


static func GetEffectiveness(attackingType:PBEEnums.PBEType, defendingTypes:Array[PBEEnums.PBEType], ignoreGhost:=false, ignoreDark:=false) -> float:
	var d :float = 1.0
	
	for dType in defendingTypes:
		if dType is PBEType:
			d *= _get_effectiveness_one_on_one(attackingType, dType, ignoreGhost, ignoreDark)
	
	return d;


static func _get_effectiveness_one_on_one(attack_type: PBEEnums.PBEType, defend_type: PBEEnums.PBEType) -> float:
	if (attackingType >= PBEEnums.PBEType.MAX):
		pass #throw new ArgumentOutOfRangeException(nameof(attackingType));
	if (defendingType >= PBEEnums.PBEType.MAX):
		pass #throw new ArgumentOutOfRangeException(nameof(defendingType));
	
	var d :float = _table[attackingType][defendingType];
	if (d <= 0 && ((ignoreGhost && defendingType == PBEType.Ghost) || (ignoreDark && defendingType == PBEType.Dark))):
		return 1;
	return d;


#
#func static float GetEffectiveness(PBEType attackingType, PBEType defendingType1, PBEType defendingType2, bool ignoreGhost = false, bool ignoreDark = false):
	#float d = GetEffectiveness(attackingType, defendingType1, ignoreGhost: ignoreGhost, ignoreDark: ignoreDark);
	#d *= GetEffectiveness(attackingType, defendingType2, ignoreGhost: ignoreGhost, ignoreDark: ignoreDark);
	#return d;
#
#
#func static float GetEffectiveness(PBEType attackingType, IPBEPokemonTypes defendingTypes, bool ignoreGhost = false, bool ignoreDark = false):
	#return GetEffectiveness(attackingType, defendingTypes.Type1, defendingTypes.Type2, ignoreGhost: ignoreGhost, ignoreDark: ignoreDark);
#
#
#func static float GetEffectiveness_Known(PBEType attackingType, IPBEPokemonKnownTypes defendingTypes, bool ignoreGhost = false, bool ignoreDark = false):
	#return GetEffectiveness(attackingType, defendingTypes.KnownType1, defendingTypes.KnownType2, ignoreGhost: ignoreGhost, ignoreDark: ignoreDark);
#
#
#func static float GetEffectiveness<T>(PBEType attackingType, T defendingTypes, useKnownInfo:bool, ignoreGhost := false, ignoreDark := false):
	##where T : IPBEPokemonTypes, IPBEPokemonKnownTypes
	#return GetEffectiveness(attackingType, useKnownInfo ? defendingTypes.KnownType1 : defendingTypes.Type1, useKnownInfo ? defendingTypes.KnownType2 : defendingTypes.Type2, ignoreGhost: ignoreGhost, ignoreDark: ignoreDark);


static func GetStealthRockMultiplier(type1:PBEEnums.PBEType, type2:PBEEnums.PBEType ) -> float:
	if (type1 >= PBEType.MAX):
		pass #throw new ArgumentOutOfRangeException(nameof(type1));
	if (type2 >= PBEType.MAX):
		pass #throw new ArgumentOutOfRangeException(nameof(type2));
	
	var d :float = 0.125
	d *= _table[PBEType.Rock][type1];
	d *= _table[PBEType.Rock][type2];
	return d;
