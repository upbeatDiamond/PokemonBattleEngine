extends PBEMoveEffect


func CalculateBasePower(user:PBEBattlePokemon , targets:Array[PBEBattlePokemon], mData:IPBEMoveData, moveType:PBEType) -> float:
	var basePower : float
	
	var filtered = targets.filter(func(t): return mData.Power * t.HP / t.MaxHP)#.Average()
	var sum
	for f in filtered:
		sum += f
	var avg = sum / min( 1, filtered.size() ) ## Avoid divide by zero
	
	basePower = max(1, avg);
