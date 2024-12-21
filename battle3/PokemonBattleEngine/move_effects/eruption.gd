extends PBEMoveEffect

func CalculateBasePower(user:PBEBattlePokemon , targets:Array[PBEBattlePokemon], mData:IPBEMoveData, moveType:PBEType) -> float:
	var basePower : float
	return max(1, mData.Power * user.HP / user.MaxHP);
