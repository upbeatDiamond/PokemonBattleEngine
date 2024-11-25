﻿using Kermalis.PokemonBattleEngine.Data;
using System;
using System.IO;

namespace Kermalis.PokemonBattleEngine.Battle;

public static class PBEBattleUtils
{
	public static PBETurnTarget GetSpreadMoveTargets(PBEBattlePokemon pkmn, PBEMoveTarget targets)
	{
		switch (pkmn.Battle.BattleFormat)
		{
			case PBEBattleFormat.Single:
			{
				switch (targets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return PBETurnTarget.AllyCenter | PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoes:
					case PBEMoveTarget.AllFoesSurrounding:
					case PBEMoveTarget.AllSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllTeam:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return PBETurnTarget.AllyCenter;
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new ArgumentOutOfRangeException(nameof(targets));
				}
			}
			case PBEBattleFormat.Double:
			{
				switch (targets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyLeft | PBETurnTarget.AllyRight | PBETurnTarget.FoeLeft | PBETurnTarget.FoeRight;
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
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
							throw new ArgumentException(nameof(pkmn.FieldPosition));
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
							throw new ArgumentException(nameof(pkmn.FieldPosition));
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
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new ArgumentOutOfRangeException(nameof(targets));
				}
			}
			case PBEBattleFormat.Triple:
			{
				switch (targets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyLeft | PBETurnTarget.AllyCenter | PBETurnTarget.AllyRight | PBETurnTarget.FoeLeft | PBETurnTarget.FoeCenter | PBETurnTarget.FoeRight;
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
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
							throw new ArgumentException(nameof(pkmn.FieldPosition));
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
							throw new ArgumentException(nameof(pkmn.FieldPosition));
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
							throw new ArgumentException(nameof(pkmn.FieldPosition));
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
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new ArgumentOutOfRangeException(nameof(targets));
				}
			}
			case PBEBattleFormat.Rotation:
			{
				switch (targets)
				{
					case PBEMoveTarget.All:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyCenter | PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllFoes:
					case PBEMoveTarget.AllFoesSurrounding:
					case PBEMoveTarget.AllSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.FoeCenter;
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.AllTeam:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return PBETurnTarget.AllyCenter;
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new ArgumentOutOfRangeException(nameof(targets));
				}
			}
			default: throw new InvalidDataException(nameof(pkmn.Battle.BattleFormat));
		}
	}
	public static PBETurnTarget[] GetPossibleTargets(PBEBattlePokemon pkmn, PBEMoveTarget targets)
	{
		switch (pkmn.Battle.BattleFormat)
		{
			case PBEBattleFormat.Single:
			{
				switch (targets)
				{
					case PBEMoveTarget.SingleFoeSurrounding:
					case PBEMoveTarget.SingleNotSelf:
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return new PBETurnTarget[] { PBETurnTarget.FoeCenter };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.Self:
					case PBEMoveTarget.SelfOrAllySurrounding:
					case PBEMoveTarget.SingleAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyCenter };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new ArgumentOutOfRangeException(nameof(targets));
				}
			}
			case PBEBattleFormat.Double:
			{
				switch (targets)
				{
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.Self:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyRight };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SelfOrAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft, PBETurnTarget.AllyRight };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyRight };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleFoeSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.FoeLeft, PBETurnTarget.FoeRight };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleNotSelf:
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyRight, PBETurnTarget.FoeLeft, PBETurnTarget.FoeRight };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft, PBETurnTarget.FoeLeft, PBETurnTarget.FoeRight };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new ArgumentOutOfRangeException(nameof(targets));
				}
			}
			case PBEBattleFormat.Triple:
			{
				switch (targets)
				{
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.Self:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyCenter };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyRight };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SelfOrAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft, PBETurnTarget.AllyCenter };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft, PBETurnTarget.AllyCenter, PBETurnTarget.AllyRight };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyCenter, PBETurnTarget.AllyRight };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyCenter };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft, PBETurnTarget.AllyRight };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleFoeSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return new PBETurnTarget[] { PBETurnTarget.FoeCenter, PBETurnTarget.FoeRight };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return new PBETurnTarget[] { PBETurnTarget.FoeLeft, PBETurnTarget.FoeCenter, PBETurnTarget.FoeRight };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.FoeLeft, PBETurnTarget.FoeCenter };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleNotSelf:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyCenter, PBETurnTarget.AllyRight, PBETurnTarget.FoeLeft, PBETurnTarget.FoeCenter, PBETurnTarget.FoeRight };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft, PBETurnTarget.AllyRight, PBETurnTarget.FoeLeft, PBETurnTarget.FoeCenter, PBETurnTarget.FoeRight };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft, PBETurnTarget.AllyCenter, PBETurnTarget.FoeLeft, PBETurnTarget.FoeCenter, PBETurnTarget.FoeRight };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyCenter, PBETurnTarget.FoeCenter, PBETurnTarget.FoeRight };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Center)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyLeft, PBETurnTarget.AllyRight, PBETurnTarget.FoeLeft, PBETurnTarget.FoeCenter, PBETurnTarget.FoeRight };
						}
						else if (pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyCenter, PBETurnTarget.FoeLeft, PBETurnTarget.FoeCenter };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new ArgumentOutOfRangeException(nameof(targets));
				}
			}
			case PBEBattleFormat.Rotation:
			{
				switch (targets)
				{
					case PBEMoveTarget.SingleFoeSurrounding:
					case PBEMoveTarget.SingleNotSelf:
					case PBEMoveTarget.SingleSurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.FoeCenter };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					case PBEMoveTarget.RandomFoeSurrounding:
					case PBEMoveTarget.Self:
					case PBEMoveTarget.SelfOrAllySurrounding:
					case PBEMoveTarget.SingleAllySurrounding:
					{
						if (pkmn.FieldPosition == PBEFieldPosition.Left || pkmn.FieldPosition == PBEFieldPosition.Center || pkmn.FieldPosition == PBEFieldPosition.Right)
						{
							return new PBETurnTarget[] { PBETurnTarget.AllyCenter };
						}
						else
						{
							throw new ArgumentException(nameof(pkmn.FieldPosition));
						}
					}
					default: throw new ArgumentOutOfRangeException(nameof(targets));
				}
			}
			default: throw new InvalidDataException(nameof(pkmn.Battle.BattleFormat));
		}
	}

	internal static void VerifyPosition(PBEBattleFormat format, PBEFieldPosition pos)
	{
		if (pos != PBEFieldPosition.None && pos < PBEFieldPosition.MAX)
		{
			switch (format)
			{
				case PBEBattleFormat.Single:
				{
					switch (pos)
					{
						case PBEFieldPosition.Center: return;
					}
					break;
				}
				case PBEBattleFormat.Double:
				{
					switch (pos)
					{
						case PBEFieldPosition.Left:
						case PBEFieldPosition.Right: return;
					}
					break;
				}
				case PBEBattleFormat.Triple:
				case PBEBattleFormat.Rotation:
				{
					return;
				}
			}
		}
		throw new ArgumentOutOfRangeException(nameof(pos));
	}

	public static int GetFieldPositionIndex(this PBETrainer trainer, PBEFieldPosition position)
	{
		if (!trainer.OwnsSpot(position))
		{
			throw new ArgumentOutOfRangeException(nameof(position));
		}
		PBEBattleFormat battleFormat = trainer.Battle.BattleFormat;
		int index = trainer.Team.Trainers.IndexOf(trainer);
		switch (battleFormat)
		{
			case PBEBattleFormat.Single:
			{
				switch (position)
				{
					case PBEFieldPosition.Center: return 0;
				}
				break;
			}
			case PBEBattleFormat.Double:
			{
				switch (position)
				{
					case PBEFieldPosition.Left: return 0;
					case PBEFieldPosition.Right: return index == 1 ? 0 : 1;
				}
				break;
			}
			case PBEBattleFormat.Triple:
			{
				switch (position)
				{
					case PBEFieldPosition.Left: return 0;
					case PBEFieldPosition.Center: return index == 1 ? 0 : 1;
					case PBEFieldPosition.Right: return index == 2 ? 0 : 2;
				}
				break;
			}
			case PBEBattleFormat.Rotation:
			{
				switch (position)
				{
					case PBEFieldPosition.Center: return 0;
					case PBEFieldPosition.Left: return 1;
					case PBEFieldPosition.Right: return 2;
				}
				break;
			}
		}
		throw new Exception();
	}
	public static bool OwnsSpot(this PBETrainer trainer, PBEFieldPosition pos)
	{
		return GetTrainer(trainer.Team, pos) == trainer;
	}
	public static PBETrainer GetTrainer(this PBETeam team, PBEFieldPosition pos)
	{
		PBEBattleFormat format = team.Battle.BattleFormat;
		VerifyPosition(format, pos);
		int i = 0;
		if (team.Trainers.Count != 1)
		{
			switch (format)
			{
				case PBEBattleFormat.Double: i = pos == PBEFieldPosition.Left ? 0 : 1; break;
				case PBEBattleFormat.Triple: i = pos == PBEFieldPosition.Left ? 0 : pos == PBEFieldPosition.Center ? 1 : 2; break;
			}
		}
		return team.Trainers[i];
	}
}
