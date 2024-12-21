extends PBEMoveEffect

func CalculateBasePower(user:PBEBattlePokemon , targets:Array[PBEBattlePokemon], mData:IPBEMoveData, moveType:PBEType) -> float:
	var basePower : float
	var val = 48 * user.HP / user.MaxHP;
	if (val < 2):
		basePower = 200;
	elif (val < 4):
		basePower = 150;
	elif (val < 8):
		basePower = 100;
	elif (val < 16):
		basePower = 80;
	elif (val < 32):
		basePower = 40;
	else:
		basePower = 20;
	return basePower;
