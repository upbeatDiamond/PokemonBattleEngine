﻿using Kermalis.PokemonBattleEngine.Battle;
using Kermalis.PokemonBattleEngine.Data;
using Kermalis.PokemonBattleEngine.Data.Utils;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace Kermalis.PokemonBattleEngine.DefaultData.AI;

public partial class PBEDDAI
{
	private PBETurnAction DecideAction(PBEBattlePokemon user, List<PBETurnAction> actions, List<PBEBattlePokemon> standBy)
	{
		// Gather all options of switching and moves
		PBEMove[] usableMoves = user.GetUsableMoves();
		var possibleActions = new List<(PBETurnAction Action, float Score)>();
		for (int m = 0; m < usableMoves.Length; m++) // Score moves
		{
			PBEMove move = usableMoves[m];
			PBEType moveType = user.GetMoveType(move);
			PBEMoveTarget moveTargets = user.GetMoveTargets(move);
			PBETurnTarget[] possibleTargets = PBEDataUtils.IsSpreadMove(moveTargets)
							? new PBETurnTarget[] { PBEBattleUtils.GetSpreadMoveTargets(user, moveTargets) }
							: PBEBattleUtils.GetPossibleTargets(user, moveTargets);
			foreach (PBETurnTarget possibleTarget in possibleTargets)
			{
				// TODO: RandomFoeSurrounding (probably just account for the specific effects that use this target type)
				// TODO: Don't queue up to do the same thing (two trying to afflict the same target when there are multiple targets)
				var targets = new List<PBEBattlePokemon>();
				if (possibleTarget.HasFlag(PBETurnTarget.AllyLeft))
				{
					Trainer.Team.TryAddPokemonToCollection(PBEFieldPosition.Left, targets);
				}
				if (possibleTarget.HasFlag(PBETurnTarget.AllyCenter))
				{
					Trainer.Team.TryAddPokemonToCollection(PBEFieldPosition.Center, targets);
				}
				if (possibleTarget.HasFlag(PBETurnTarget.AllyRight))
				{
					Trainer.Team.TryAddPokemonToCollection(PBEFieldPosition.Right, targets);
				}
				if (possibleTarget.HasFlag(PBETurnTarget.FoeLeft))
				{
					Trainer.Team.OpposingTeam.TryAddPokemonToCollection(PBEFieldPosition.Left, targets);
				}
				if (possibleTarget.HasFlag(PBETurnTarget.FoeCenter))
				{
					Trainer.Team.OpposingTeam.TryAddPokemonToCollection(PBEFieldPosition.Center, targets);
				}
				if (possibleTarget.HasFlag(PBETurnTarget.FoeRight))
				{
					Trainer.Team.OpposingTeam.TryAddPokemonToCollection(PBEFieldPosition.Right, targets);
				}
				float score = ScoreMove(targets, user, move, moveType, actions);
				possibleActions.Add((new PBETurnAction(user, move, possibleTarget), score));
			}
		}
		if (user.CanSwitchOut())
		{
			PBEBattlePokemon[] availableForSwitch = Trainer.Party.Except(standBy).Where(p => p.FieldPosition == PBEFieldPosition.None && p.CanBattle).ToArray();
			for (int s = 0; s < availableForSwitch.Length; s++) // Score switches
			{
				PBEBattlePokemon switchPkmn = availableForSwitch[s];
				// TODO: Entry hazards
				// TODO: Known moves of active battlers
				// TODO: Type effectiveness
				float score = -10;
				possibleActions.Add((new PBETurnAction(user, switchPkmn), score));
			}
		}

		IOrderedEnumerable<(PBETurnAction Action, float Score)> byScore = possibleActions.OrderByDescending(t => t.Score);
		Debug_LogGeneratedActions(user, byScore);
		float bestScore = byScore.First().Score;
		return PBEDataProvider.GlobalRandom.RandomElement(byScore.Where(t => t.Score == bestScore).ToArray()).Action; // Pick random action of the ones that tied for best score
	}
	private void Debug_LogGeneratedActions(PBEBattlePokemon user, IOrderedEnumerable<(PBETurnAction Action, float Score)> byScore)
	{
		string ToDebugString((PBETurnAction Action, float Score) t)
		{
			string str = "{";
			if (t.Action.Decision == PBETurnDecision.Fight)
			{
				str += string.Format("Fight {0} {1}", t.Action.FightMove, t.Action.FightTargets);
			}
			else
			{
				str += string.Format("Switch {0}", Trainer.GetPokemon(t.Action.SwitchPokemonId).Nickname);
			}
			str += " [" + t.Score + "]}";
			return str;
		}
		Debug.WriteLine("{0}'s possible actions: {1}", user.Nickname, "( " + string.Join(", ", byScore.Select(t => ToDebugString(t))) + " )");
	}
	private float ScoreMove(List<PBEBattlePokemon> targets, PBEBattlePokemon user, PBEMove move, PBEType moveType, List<PBETurnAction> actions)
	{
		if (targets.Count == 0)
		{
			return -100;
		}
		float score = 0;
		IPBEMoveData mData = PBEDataProvider.Instance.GetMoveData(move);
		if (!mData.IsMoveUsable())
		{
			throw new ArgumentOutOfRangeException(nameof(move), $"{move} is not yet implemented in Pokémon Battle Engine.");
		}
		switch (mData.Effect)
		{
			case PBEMoveEffect.Acrobatics:
			case PBEMoveEffect.Bounce:
			case PBEMoveEffect.BrickBreak:
			case PBEMoveEffect.Brine:
			case PBEMoveEffect.ChipAway:
			case PBEMoveEffect.CrushGrip:
			case PBEMoveEffect.Dig:
			case PBEMoveEffect.Dive:
			case PBEMoveEffect.Eruption:
			case PBEMoveEffect.Facade:
			case PBEMoveEffect.Feint:
			case PBEMoveEffect.Flail:
			case PBEMoveEffect.Fly:
			case PBEMoveEffect.FoulPlay:
			case PBEMoveEffect.Frustration:
			case PBEMoveEffect.GrassKnot:
			case PBEMoveEffect.HeatCrash:
			case PBEMoveEffect.Hex:
			case PBEMoveEffect.HiddenPower:
			case PBEMoveEffect.Hit:
			case PBEMoveEffect.Hit__2Times:
			case PBEMoveEffect.Hit__2Times__MaybePoison:
			case PBEMoveEffect.Hit__2To5Times:
			case PBEMoveEffect.Hit__MaybeBurn:
			case PBEMoveEffect.Hit__MaybeBurn__10PercentFlinch:
			case PBEMoveEffect.Hit__MaybeBurnFreezeParalyze:
			case PBEMoveEffect.Hit__MaybeConfuse:
			case PBEMoveEffect.Hit__MaybeFlinch:
			case PBEMoveEffect.Hit__MaybeFreeze:
			case PBEMoveEffect.Hit__MaybeFreeze__10PercentFlinch:
			case PBEMoveEffect.Hit__MaybeLowerTarget_ACC_By1:
			case PBEMoveEffect.Hit__MaybeLowerTarget_ATK_By1:
			case PBEMoveEffect.Hit__MaybeLowerTarget_DEF_By1:
			case PBEMoveEffect.Hit__MaybeLowerTarget_SPATK_By1:
			case PBEMoveEffect.Hit__MaybeLowerTarget_SPDEF_By1:
			case PBEMoveEffect.Hit__MaybeLowerTarget_SPDEF_By2:
			case PBEMoveEffect.Hit__MaybeLowerTarget_SPE_By1:
			case PBEMoveEffect.Hit__MaybeLowerUser_ATK_DEF_By1:
			case PBEMoveEffect.Hit__MaybeLowerUser_DEF_SPDEF_By1:
			case PBEMoveEffect.Hit__MaybeLowerUser_SPATK_By2:
			case PBEMoveEffect.Hit__MaybeLowerUser_SPE_By1:
			case PBEMoveEffect.Hit__MaybeLowerUser_SPE_DEF_SPDEF_By1:
			case PBEMoveEffect.Hit__MaybeParalyze:
			case PBEMoveEffect.Hit__MaybeParalyze__10PercentFlinch:
			case PBEMoveEffect.Hit__MaybePoison:
			case PBEMoveEffect.Hit__MaybeRaiseUser_ATK_By1:
			case PBEMoveEffect.Hit__MaybeRaiseUser_ATK_DEF_SPATK_SPDEF_SPE_By1:
			case PBEMoveEffect.Hit__MaybeRaiseUser_DEF_By1:
			case PBEMoveEffect.Hit__MaybeRaiseUser_SPATK_By1:
			case PBEMoveEffect.Hit__MaybeRaiseUser_SPE_By1:
			case PBEMoveEffect.Hit__MaybeToxic:
			case PBEMoveEffect.HPDrain:
			case PBEMoveEffect.Judgment:
			case PBEMoveEffect.Magnitude:
			case PBEMoveEffect.Payback:
			case PBEMoveEffect.PayDay:
			case PBEMoveEffect.Psyshock:
			case PBEMoveEffect.Punishment:
			case PBEMoveEffect.Recoil:
			case PBEMoveEffect.Recoil__10PercentBurn:
			case PBEMoveEffect.Recoil__10PercentParalyze:
			case PBEMoveEffect.Retaliate:
			case PBEMoveEffect.Return:
			case PBEMoveEffect.SecretPower:
			case PBEMoveEffect.ShadowForce:
			case PBEMoveEffect.SmellingSalt:
			case PBEMoveEffect.StoredPower:
			case PBEMoveEffect.TechnoBlast:
			case PBEMoveEffect.Venoshock:
			case PBEMoveEffect.WakeUpSlap:
			case PBEMoveEffect.WeatherBall:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					// TODO: Favor hitting ally with move if waterabsorb/voltabsorb etc
					// TODO: Liquid ooze
					// TODO: Check items
					// TODO: Stat changes and accuracy (even thunder/guillotine accuracy)
					// TODO: Check base power specifically against hp remaining (include spread move damage reduction)
					PBETypeEffectiveness.IsAffectedByAttack(user, target, moveType, out float damageMultiplier, useKnownInfo: true);
					if (damageMultiplier <= 0) // (-infinity, 0.0] Ineffective
					{
						score += target.Team == Trainer.Team ? 0 : -60;
					}
					else if (damageMultiplier <= 0.25) // (0.0, 0.25] NotVeryEffective
					{
						score += target.Team == Trainer.Team ? -5 : -30;
					}
					else if (damageMultiplier < 1) // (0.25, 1.0) NotVeryEffective
					{
						score += target.Team == Trainer.Team ? -10 : -10;
					}
					else if (damageMultiplier == 1) // [1.0, 1.0] Normal
					{
						score += target.Team == Trainer.Team ? -15 : +10;
					}
					else if (damageMultiplier < 4) // (1.0, 4.0) SuperEffective
					{
						score += target.Team == Trainer.Team ? -20 : +25;
					}
					else // [4.0, infinity) SuperEffective
					{
						score += target.Team == Trainer.Team ? -30 : +40;
					}
					if (user.ReceivesSTAB(moveType) && damageMultiplier > 0)
					{
						score += (user.Ability == PBEAbility.Adaptability ? 7 : 5) * (target.Team == Trainer.Team ? -1 : +1);
					}
				}
				break;
			}
			case PBEMoveEffect.Attract:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					// TODO: Destiny knot
					if (target.IsAttractionPossible(user, useKnownInfo: true) == PBEResult.Success)
					{
						score += target.Team == Trainer.Team ? -20 : +40;
					}
					else
					{
						score += target.Team == Trainer.Team ? 0 : -60;
					}
				}
				break;
			}
			case PBEMoveEffect.Burn:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					// TODO: Heatproof, physical attacker
					if (target.IsBurnPossible(user, useKnownInfo: true) == PBEResult.Success)
					{
						score += target.Team == Trainer.Team ? -20 : +40;
					}
					else
					{
						score += target.Team == Trainer.Team ? 0 : -60;
					}
				}
				break;
			}
			case PBEMoveEffect.ChangeTarget_ACC:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Accuracy, mData.EffectParam, ref score);
				}
				break;
			}
			case PBEMoveEffect.ChangeTarget_ATK:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Attack, mData.EffectParam, ref score);
				}
				break;
			}
			case PBEMoveEffect.ChangeTarget_DEF:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Defense, mData.EffectParam, ref score);
				}
				break;
			}
			case PBEMoveEffect.ChangeTarget_EVA:
			case PBEMoveEffect.Minimize:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Evasion, mData.EffectParam, ref score);
				}
				break;
			}
			case PBEMoveEffect.ChangeTarget_SPATK:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.SpAttack, mData.EffectParam, ref score);
				}
				break;
			}
			case PBEMoveEffect.ChangeTarget_SPDEF:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.SpDefense, mData.EffectParam, ref score);
				}
				break;
			}
			case PBEMoveEffect.ChangeTarget_SPE:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Speed, mData.EffectParam, ref score);
				}
				break;
			}
			case PBEMoveEffect.Confuse:
			case PBEMoveEffect.Flatter:
			case PBEMoveEffect.Swagger:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					// TODO: Only swagger/flatter if the opponent most likely won't use it against you
					if (target.IsConfusionPossible(user, useKnownInfo: true) == PBEResult.Success)
					{
						score += target.Team == Trainer.Team ? -20 : +40;
					}
					else
					{
						score += target.Team == Trainer.Team ? 0 : -60;
					}
				}
				break;
			}
			case PBEMoveEffect.Growth:
			{
				int change = Trainer.Battle.WillLeafGuardActivate() ? +2 : +1;
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Attack, change, ref score);
					ScoreStatChange(user, target, PBEStat.SpAttack, change, ref score);
				}
				break;
			}
			case PBEMoveEffect.LeechSeed:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					if (target.IsLeechSeedPossible(useKnownInfo: true) == PBEResult.Success)
					{
						score += target.Team == Trainer.Team ? -20 : +40;
					}
					else
					{
						score += target.Team == Trainer.Team ? 0 : -60;
					}
				}
				break;
			}
			case PBEMoveEffect.LightScreen:
			{
				score += Trainer.Team.TeamStatus.HasFlag(PBETeamStatus.LightScreen) || IsTeammateUsingEffect(actions, PBEMoveEffect.LightScreen) ? -100 : +40;
				break;
			}
			case PBEMoveEffect.LowerTarget_ATK_DEF_By1:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Attack, -1, ref score);
					ScoreStatChange(user, target, PBEStat.Defense, -1, ref score);
				}
				break;
			}
			case PBEMoveEffect.LowerTarget_DEF_SPDEF_By1_Raise_ATK_SPATK_SPE_By2:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Defense, -1, ref score);
					ScoreStatChange(user, target, PBEStat.SpDefense, -1, ref score);
					ScoreStatChange(user, target, PBEStat.Attack, +2, ref score);
					ScoreStatChange(user, target, PBEStat.SpAttack, +2, ref score);
					ScoreStatChange(user, target, PBEStat.Speed, +2, ref score);
				}
				break;
			}
			case PBEMoveEffect.LuckyChant:
			{
				score += Trainer.Team.TeamStatus.HasFlag(PBETeamStatus.LuckyChant) || IsTeammateUsingEffect(actions, PBEMoveEffect.LuckyChant) ? -100 : +40;
				break;
			}
			case PBEMoveEffect.Moonlight:
			case PBEMoveEffect.Rest:
			case PBEMoveEffect.RestoreTargetHP:
			case PBEMoveEffect.Roost:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					if (target.Team == Trainer.Team)
					{
						score += HPAware(target.HPPercentage, +45, -15);
					}
					else
					{
						score -= 100;
					}
				}
				break;
			}
			case PBEMoveEffect.Nothing:
			case PBEMoveEffect.Teleport:
			{
				score -= 100;
				break;
			}
			case PBEMoveEffect.Paralyze:
			case PBEMoveEffect.ThunderWave:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					bool tw = mData.Effect != PBEMoveEffect.ThunderWave || PBETypeEffectiveness.ThunderWaveTypeCheck(user, target, move, useKnownInfo: true) == PBEResult.Success;
					if (tw && target.IsParalysisPossible(user, useKnownInfo: true) == PBEResult.Success)
					{
						score += target.Team == Trainer.Team ? -20 : +40;
					}
					else
					{
						score += target.Team == Trainer.Team ? 0 : -60;
					}
				}
				break;
			}
			case PBEMoveEffect.Poison:
			case PBEMoveEffect.Toxic:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					// TODO: Poison Heal
					if (target.IsPoisonPossible(user, useKnownInfo: true) == PBEResult.Success)
					{
						score += target.Team == Trainer.Team ? -20 : +40;
					}
					else
					{
						score += target.Team == Trainer.Team ? 0 : -60;
					}
				}
				break;
			}
			case PBEMoveEffect.RaiseTarget_ATK_ACC_By1:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Attack, +1, ref score);
					ScoreStatChange(user, target, PBEStat.Accuracy, +1, ref score);
				}
				break;
			}
			case PBEMoveEffect.RaiseTarget_ATK_DEF_By1:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Attack, +1, ref score);
					ScoreStatChange(user, target, PBEStat.Defense, +1, ref score);
				}
				break;
			}
			case PBEMoveEffect.RaiseTarget_ATK_DEF_ACC_By1:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Attack, +1, ref score);
					ScoreStatChange(user, target, PBEStat.Defense, +1, ref score);
					ScoreStatChange(user, target, PBEStat.Accuracy, +1, ref score);
				}
				break;
			}
			case PBEMoveEffect.RaiseTarget_ATK_SPATK_By1:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Attack, +1, ref score);
					ScoreStatChange(user, target, PBEStat.SpAttack, +1, ref score);
				}
				break;
			}
			case PBEMoveEffect.RaiseTarget_ATK_SPE_By1:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Attack, +1, ref score);
					ScoreStatChange(user, target, PBEStat.Speed, +1, ref score);
				}
				break;
			}
			case PBEMoveEffect.RaiseTarget_DEF_SPDEF_By1:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Defense, +1, ref score);
					ScoreStatChange(user, target, PBEStat.SpDefense, +1, ref score);
				}
				break;
			}
			case PBEMoveEffect.RaiseTarget_SPATK_SPDEF_By1:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.SpAttack, +1, ref score);
					ScoreStatChange(user, target, PBEStat.SpDefense, +1, ref score);
				}
				break;
			}
			case PBEMoveEffect.RaiseTarget_SPATK_SPDEF_SPE_By1:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.SpAttack, +1, ref score);
					ScoreStatChange(user, target, PBEStat.SpDefense, +1, ref score);
					ScoreStatChange(user, target, PBEStat.Speed, +1, ref score);
				}
				break;
			}
			case PBEMoveEffect.RaiseTarget_SPE_By2_ATK_By1:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					ScoreStatChange(user, target, PBEStat.Speed, +2, ref score);
					ScoreStatChange(user, target, PBEStat.Attack, +1, ref score);
				}
				break;
			}
			case PBEMoveEffect.Reflect:
			{
				score += Trainer.Team.TeamStatus.HasFlag(PBETeamStatus.Reflect) || IsTeammateUsingEffect(actions, PBEMoveEffect.Reflect) ? -100 : +40;
				break;
			}
			case PBEMoveEffect.Safeguard:
			{
				score += Trainer.Team.TeamStatus.HasFlag(PBETeamStatus.Safeguard) || IsTeammateUsingEffect(actions, PBEMoveEffect.Safeguard) ? -100 : +40;
				break;
			}
			case PBEMoveEffect.Sleep:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					// TODO: Bad Dreams
					if (target.IsSleepPossible(user, useKnownInfo: true) == PBEResult.Success)
					{
						score += target.Team == Trainer.Team ? -20 : +40;
					}
					else
					{
						score += target.Team == Trainer.Team ? 0 : -60;
					}
				}
				break;
			}
			case PBEMoveEffect.Substitute:
			{
				foreach (PBEBattlePokemon target in targets)
				{
					if (target.IsSubstitutePossible() == PBEResult.Success)
					{
						score += target.Team == Trainer.Team ? HPAware(target.HPPercentage, -30, +50) : -60;
					}
					else
					{
						score += target.Team == Trainer.Team ? 0 : -20;
					}
				}
				break;
			}
			case PBEMoveEffect.BellyDrum:
			case PBEMoveEffect.Camouflage:
			case PBEMoveEffect.ChangeTarget_SPATK__IfAttractionPossible:
			case PBEMoveEffect.Conversion:
			case PBEMoveEffect.Curse:
			case PBEMoveEffect.Endeavor:
			case PBEMoveEffect.Entrainment:
			case PBEMoveEffect.FinalGambit:
			case PBEMoveEffect.FocusEnergy:
			case PBEMoveEffect.Foresight:
			case PBEMoveEffect.GastroAcid:
			case PBEMoveEffect.Hail:
			case PBEMoveEffect.Haze:
			case PBEMoveEffect.HelpingHand:
			case PBEMoveEffect.HPDrain__RequireSleep:
			case PBEMoveEffect.LockOn:
			case PBEMoveEffect.MagnetRise:
			case PBEMoveEffect.Metronome:
			case PBEMoveEffect.MiracleEye:
			case PBEMoveEffect.Nightmare:
			case PBEMoveEffect.OneHitKnockout:
			case PBEMoveEffect.PainSplit:
			case PBEMoveEffect.PowerTrick:
			case PBEMoveEffect.Protect:
			case PBEMoveEffect.PsychUp:
			case PBEMoveEffect.Psywave:
			case PBEMoveEffect.QuickGuard:
			case PBEMoveEffect.RainDance:
			case PBEMoveEffect.ReflectType:
			case PBEMoveEffect.Refresh:
			case PBEMoveEffect.RolePlay:
			case PBEMoveEffect.Sandstorm:
			case PBEMoveEffect.SeismicToss:
			case PBEMoveEffect.Selfdestruct:
			case PBEMoveEffect.SetDamage:
			case PBEMoveEffect.SimpleBeam:
			case PBEMoveEffect.Sketch:
			case PBEMoveEffect.Snore:
			case PBEMoveEffect.Soak:
			case PBEMoveEffect.Spikes:
			case PBEMoveEffect.StealthRock:
			case PBEMoveEffect.SuckerPunch:
			case PBEMoveEffect.SunnyDay:
			case PBEMoveEffect.SuperFang:
			case PBEMoveEffect.Tailwind:
			case PBEMoveEffect.ToxicSpikes:
			case PBEMoveEffect.Transform:
			case PBEMoveEffect.TrickRoom:
			case PBEMoveEffect.Whirlwind:
			case PBEMoveEffect.WideGuard:
			case PBEMoveEffect.WorrySeed:
			{
				// TODO
				break;
			}
			default: throw new InvalidDataException(nameof(IPBEMoveData.Effect));
		}
		return score;
	}
	private static void ScoreStatChange(PBEBattlePokemon user, PBEBattlePokemon target, PBEStat stat, int change, ref float score)
	{
		// TODO: Do we need the stat change? Physical vs special vs status users, and base stats/transform stats/power trick stats
		sbyte original = target.GetStatChange(stat);
		sbyte maxStatChange = user.Battle.Settings.MaxStatChange;
		change = Math.Max(-maxStatChange, Math.Min(maxStatChange, original + change)) - original;
		if (change != 0)
		{
			score += (user.Team == target.Team ? +1 : -1) * change * 10;
			score += HPAware(target.HPPercentage, -20, +10);
		}
	}
	private static bool IsTeammateUsingEffect(List<PBETurnAction> actions, PBEMoveEffect effect)
	{
		return actions.FindIndex(a => a.Decision == PBETurnDecision.Fight && PBEDataProvider.Instance.GetMoveData(a.FightMove).Effect == effect) != -1;
	}
	private static float HPAware(float hpPercentage, float zeroPercentScore, float hundredPercentScore)
	{
		return ((-zeroPercentScore + hundredPercentScore) * hpPercentage) + zeroPercentScore;
	}
}
