extends PBEMoveEffect

## Used for supplementary base power; after item boost is applied
func CalculateBasePowerBoost(user:PBEBattlePokemon , targets:Array[PBEBattlePokemon], mData:IPBEMoveData, moveType:PBEType) -> float:
	var basePower : float
	if (Array.FindIndex(targets, t => t.Status1 == PBEStatus1.Asleep) != -1):
		basePower *= 2.0
	return basePower;
