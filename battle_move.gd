extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



	private float CalculateBasePower(PBEBattlePokemon user, PBEBattlePokemon[] targets, IPBEMoveData mData, PBEType moveType)
	{
		float basePower;

		#region Get move's base power
		match (mData.Effect)
		{
			PBEMoveEffect.CrushGrip:
			{
				basePower = Math.Max(1, targets.Select(t => (float)mData.Power * t.HP / t.MaxHP).Average());
				break;
			}
			PBEMoveEffect.Eruption:
			{
				basePower = Math.Max(1, mData.Power * user.HP / user.MaxHP);
				break;
			}
			PBEMoveEffect.Flail:
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
			PBEMoveEffect.Frustration:
			{
				basePower = Math.Max(1, (byte.MaxValue - user.Friendship) / 2.5f);
				break;
			}
			PBEMoveEffect.GrassKnot:
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
			PBEMoveEffect.HeatCrash:
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
			PBEMoveEffect.HiddenPower:
			{
				basePower = user.IndividualValues!.GetHiddenPowerBasePower(Settings);
				break;
			}
			PBEMoveEffect.Magnitude:
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
			PBEMoveEffect.Punishment:
			{
				basePower = Math.Max(1, Math.Min(200, targets.Select(t => mData.Power + (20f * t.GetPositiveStatTotal())).Average()));
				break;
			}
			PBEMoveEffect.Return:
			{
				basePower = Math.Max(1, user.Friendship / 2.5f);
				break;
			}
			PBEMoveEffect.StoredPower:
			{
				basePower = mData.Power + (20 * user.GetPositiveStatTotal());
				break;
			}
			_:
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
		match (moveType)
		{
			PBEType.Bug:
			{
				match (user.Item)
				{
					PBEItem.InsectPlate:
					PBEItem.SilverPowder:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.BugGem:
					{
						BroadcastItem(user, user, PBEItem.BugGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Dark:
			{
				match (user.Item)
				{
					PBEItem.BlackGlasses:
					PBEItem.DreadPlate:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.DarkGem:
					{
						BroadcastItem(user, user, PBEItem.DarkGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Dragon:
			{
				match (user.Item)
				{
					PBEItem.AdamantOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Dialga)
						{
							basePower *= 1.2f;
						}
						break;
					}
					PBEItem.DracoPlate:
					PBEItem.DragonFang:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.GriseousOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Giratina && user.RevertForm == PBEForm.Giratina_Origin)
						{
							basePower *= 1.2f;
						}
						break;
					}
					PBEItem.LustrousOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Palkia)
						{
							basePower *= 1.2f;
						}
						break;
					}
					PBEItem.DragonGem:
					{
						BroadcastItem(user, user, PBEItem.DragonGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Electric:
			{
				match (user.Item)
				{
					PBEItem.Magnet:
					PBEItem.ZapPlate:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.ElectricGem:
					{
						BroadcastItem(user, user, PBEItem.ElectricGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Fighting:
			{
				match (user.Item)
				{
					PBEItem.BlackBelt:
					PBEItem.FistPlate:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.FightingGem:
					{
						BroadcastItem(user, user, PBEItem.FightingGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Fire:
			{
				match (user.Item)
				{
					PBEItem.Charcoal:
					PBEItem.FlamePlate:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.FireGem:
					{
						BroadcastItem(user, user, PBEItem.FireGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Flying:
			{
				match (user.Item)
				{
					PBEItem.SharpBeak:
					PBEItem.SkyPlate:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.FlyingGem:
					{
						BroadcastItem(user, user, PBEItem.FlyingGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Ghost:
			{
				match (user.Item)
				{
					PBEItem.GriseousOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Giratina && user.RevertForm == PBEForm.Giratina_Origin)
						{
							basePower *= 1.2f;
						}
						break;
					}
					PBEItem.SpellTag:
					PBEItem.SpookyPlate:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.GhostGem:
					{
						BroadcastItem(user, user, PBEItem.GhostGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Grass:
			{
				match (user.Item)
				{
					PBEItem.MeadowPlate:
					PBEItem.MiracleSeed:
					PBEItem.RoseIncense:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.GrassGem:
					{
						BroadcastItem(user, user, PBEItem.GrassGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Ground:
			{
				match (user.Item)
				{
					PBEItem.EarthPlate:
					PBEItem.SoftSand:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.GroundGem:
					{
						BroadcastItem(user, user, PBEItem.GroundGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Ice:
			{
				match (user.Item)
				{
					PBEItem.IciclePlate:
					PBEItem.NeverMeltIce:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.IceGem:
					{
						BroadcastItem(user, user, PBEItem.IceGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.None:
			{
				break;
			}
			PBEType.Normal:
			{
				match (user.Item)
				{
					PBEItem.SilkScarf:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.NormalGem:
					{
						BroadcastItem(user, user, PBEItem.NormalGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Poison:
			{
				match (user.Item)
				{
					PBEItem.PoisonBarb:
					PBEItem.ToxicPlate:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.PoisonGem:
					{
						BroadcastItem(user, user, PBEItem.PoisonGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Psychic:
			{
				match (user.Item)
				{
					PBEItem.MindPlate:
					PBEItem.OddIncense:
					PBEItem.TwistedSpoon:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.PsychicGem:
					{
						BroadcastItem(user, user, PBEItem.PsychicGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Rock:
			{
				match (user.Item)
				{
					PBEItem.HardStone:
					PBEItem.RockIncense:
					PBEItem.StonePlate:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.RockGem:
					{
						BroadcastItem(user, user, PBEItem.RockGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Steel:
			{
				match (user.Item)
				{
					PBEItem.AdamantOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Dialga)
						{
							basePower *= 1.2f;
						}
						break;
					}
					PBEItem.IronPlate:
					PBEItem.MetalCoat:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.SteelGem:
					{
						BroadcastItem(user, user, PBEItem.SteelGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			PBEType.Water:
			{
				match (user.Item)
				{
					PBEItem.LustrousOrb:
					{
						if (user.OriginalSpecies == PBESpecies.Palkia)
						{
							basePower *= 1.2f;
						}
						break;
					}
					PBEItem.MysticWater:
					PBEItem.SeaIncense:
					PBEItem.SplashPlate:
					PBEItem.WaveIncense:
					{
						basePower *= 1.2f;
						break;
					}
					PBEItem.WaterGem:
					{
						BroadcastItem(user, user, PBEItem.WaterGem, PBEItemAction.Consumed);
						basePower *= 1.5f;
						break;
					}
				}
				break;
			}
			_: throw new ArgumentOutOfRangeException(nameof(moveType));
		}
		#endregion

		#region Move-specific power boosts
		match (mData.Effect)
		{
			PBEMoveEffect.Acrobatics:
			{
				if (user.Item == PBEItem.None)
				{
					basePower *= 2.0f;
				}
				break;
			}
			PBEMoveEffect.Brine:
			{
				if (Array.FindIndex(targets, t => t.HP <= t.HP / 2) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			PBEMoveEffect.Facade:
			{
				if (user.Status1 == PBEStatus1.Burned || user.Status1 == PBEStatus1.Paralyzed || user.Status1 == PBEStatus1.Poisoned || user.Status1 == PBEStatus1.BadlyPoisoned)
				{
					basePower *= 2.0f;
				}
				break;
			}
			PBEMoveEffect.Hex:
			{
				if (Array.FindIndex(targets, t => t.Status1 != PBEStatus1.None) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			PBEMoveEffect.Payback:
			{
				if (Array.FindIndex(targets, t => t.HasUsedMoveThisTurn) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			PBEMoveEffect.Retaliate:
			{
				if (user.Team.MonFaintedLastTurn)
				{
					basePower *= 2.0f;
				}
				break;
			}
			PBEMoveEffect.SmellingSalt:
			{
				if (Array.FindIndex(targets, t => t.Status1 == PBEStatus1.Paralyzed) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			PBEMoveEffect.Venoshock:
			{
				if (Array.FindIndex(targets, t => t.Status1 == PBEStatus1.Poisoned || t.Status1 == PBEStatus1.BadlyPoisoned) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			PBEMoveEffect.WakeUpSlap:
			{
				if (Array.FindIndex(targets, t => t.Status1 == PBEStatus1.Asleep) != -1)
				{
					basePower *= 2.0f;
				}
				break;
			}
			PBEMoveEffect.WeatherBall:
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
			match (Weather)
			{
				PBEWeather.HarshSunlight:
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
				PBEWeather.Rain:
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
				PBEWeather.Sandstorm:
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

		match (moveResult)
		{
			PBEResult.NotVeryEffective_Type:
			{
				if (user.Ability == PBEAbility.TintedLens)
				{
					damageMultiplier *= 2.0f;
				}
				break;
			}
			PBEResult.SuperEffective_Type:
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


	private int CalculateDamage(PBEBattlePokemon user, PBEBattlePokemon target, IPBEMoveData mData, PBEType moveType, float basePower, bool criticalHit)
	{
		PBEBattlePokemon aPkmn;
		PBEMoveCategory aCat = mData.Category, dCat;
		match (mData.Effect)
		{
			PBEMoveEffect.FoulPlay:
			{
				aPkmn = target;
				dCat = aCat;
				break;
			}
			PBEMoveEffect.Psyshock:
			{
				aPkmn = user;
				dCat = PBEMoveCategory.Physical;
				break;
			}
			_:
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
