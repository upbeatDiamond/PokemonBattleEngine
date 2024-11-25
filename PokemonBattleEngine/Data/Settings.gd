﻿using Kermalis.EndianBinaryIO;
using Kermalis.PokemonBattleEngine.Battle;
using System;
using System.ComponentModel;
using System.IO;

namespace Kermalis.PokemonBattleEngine.Data;

#pragma warning disable CS0618 // Type or member is obsolete
/// <summary>The various engine settings.</summary>
public sealed class PBESettings : INotifyPropertyChanged
{
	private void OnPropertyChanged(string property)
	{
		PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(property));
	}
	/// <summary>Fires whenever a property changes.</summary>
	public event PropertyChangedEventHandler? PropertyChanged;

	private bool _isReadOnly;
	/// <summary>Gets a value that indicates whether this <see cref="PBESettings"/> object is read-only.</summary>
	public bool IsReadOnly
	{
		get => _isReadOnly;
		private set
		{
			if (_isReadOnly != value)
			{
				_isReadOnly = value;
				OnPropertyChanged(nameof(IsReadOnly));
			}
		}
	}

	/// <summary>The default settings used in official games.</summary>
	public static PBESettings DefaultSettings { get; }

	static PBESettings()
	{
		DefaultSettings = new PBESettings();
		DefaultSettings.MakeReadOnly();
	}

	#region Properties

	/// <summary>The default value of <see cref="MaxLevel"/>.</summary>
	public const byte DefaultMaxLevel = 100;
	private byte _maxLevel = DefaultMaxLevel;
	/// <summary>The maximum level a Pokémon can be. Not used in stat/damage calculation.</summary>
	public byte MaxLevel
	{
		get => _maxLevel;
		set
		{
			ShouldNotBeReadOnly();
			if (_maxLevel != value)
			{
				if (value < _minLevel)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(MaxLevel)} must be at least {nameof(MinLevel)} ({_minLevel}).");
				}
				_maxLevel = value;
				OnPropertyChanged(nameof(MaxLevel));
			}
		}
	}
	/// <summary>The default value of <see cref="MinLevel"/>.</summary>
	public const byte DefaultMinLevel = 1;
	private byte _minLevel = DefaultMinLevel;
	/// <summary>The minimum level a Pokémon can be.</summary>
	public byte MinLevel
	{
		get => _minLevel;
		set
		{
			ShouldNotBeReadOnly();
			if (_minLevel != value)
			{
				if (value < 1 || value > _maxLevel)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(MinLevel)} must be at least 1 and cannot exceed {nameof(MaxLevel)} ({_maxLevel}).");
				}
				_minLevel = value;
				OnPropertyChanged(nameof(MinLevel));
			}
		}
	}
	/// <summary>The default value of <see cref="MaxPartySize"/>.</summary>
	public const byte DefaultMaxPartySize = 6;
	private byte _maxPartySize = DefaultMaxPartySize;
	/// <summary>The maximum amount of Pokémon each trainer can bring into a battle.</summary>
	public byte MaxPartySize
	{
		get => _maxPartySize;
		set
		{
			ShouldNotBeReadOnly();
			if (_maxPartySize != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(MaxPartySize)} must be at least 1.");
				}
				_maxPartySize = value;
				OnPropertyChanged(nameof(MaxPartySize));
			}
		}
	}
	/// <summary>The default value of <see cref="MaxPokemonNameLength"/>.</summary>
	public const byte DefaultMaxPokemonNameLength = 10;
	private byte _maxPokemonNameLength = DefaultMaxPokemonNameLength;
	/// <summary>The maximum amount of characters a Pokémon nickname can have.</summary>
	public byte MaxPokemonNameLength
	{
		get => _maxPokemonNameLength;
		set
		{
			ShouldNotBeReadOnly();
			if (_maxPokemonNameLength != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(MaxPokemonNameLength)} must be at least 1.");
				}
				_maxPokemonNameLength = value;
				OnPropertyChanged(nameof(MaxPokemonNameLength));
			}
		}
	}
	/// <summary>The default value of <see cref="MaxTrainerNameLength"/>. This value is different in non-English games.</summary>
	public const byte DefaultMaxTrainerNameLength = 7;
	private byte _maxTrainerNameLength = DefaultMaxTrainerNameLength;
	/// <summary>The maximum amount of characters a trainer's name can have.</summary>
	[Obsolete("Currently not used anywhere.")]
	public byte MaxTrainerNameLength
	{
		get => _maxTrainerNameLength;
		set
		{
			ShouldNotBeReadOnly();
			if (_maxTrainerNameLength != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(MaxTrainerNameLength)} must be at least 1.");
				}
				_maxTrainerNameLength = value;
				OnPropertyChanged(nameof(MaxTrainerNameLength));
			}
		}
	}
	/// <summary>The default value of <see cref="MaxTotalEVs"/>.</summary>
	public const ushort DefaultMaxTotalEVs = 510;
	private ushort _maxTotalEVs = DefaultMaxTotalEVs;
	/// <summary>The maximum sum of a Pokémon's EVs.</summary>
	public ushort MaxTotalEVs
	{
		get => _maxTotalEVs;
		set
		{
			const int max = byte.MaxValue * 6;
			ShouldNotBeReadOnly();
			if (_maxTotalEVs != value)
			{
				if (value > max)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(MaxTotalEVs)} must not exceed {max}.");
				}
				_maxTotalEVs = value;
				OnPropertyChanged(nameof(MaxTotalEVs));
			}
		}
	}
	/// <summary>The default value of <see cref="MaxIVs"/>.</summary>
	public const byte DefaultMaxIVs = 31;
	private byte _maxIVs = DefaultMaxIVs;
	/// <summary>The maximum amount of IVs Pokémon can have in each stat. Raising this will not affect <see cref="PBEMoveEffect.HiddenPower"/>.</summary>
	public byte MaxIVs
	{
		get => _maxIVs;
		set
		{
			ShouldNotBeReadOnly();
			if (_maxIVs != value)
			{
				_maxIVs = value;
				OnPropertyChanged(nameof(MaxIVs));
			}
		}
	}
	/// <summary>The default value of <see cref="NatureStatBoost"/>.</summary>
	public const float DefaultNatureStatBoost = 0.1f;
	private float _natureStatBoost = DefaultNatureStatBoost;
	/// <summary>The amount of influence a Pokémon's <see cref="PBENature"/> has on its stats.</summary>
	public float NatureStatBoost
	{
		get => _natureStatBoost;
		set
		{
			ShouldNotBeReadOnly();
			if (_natureStatBoost != value)
			{
				if (value < 0)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(NatureStatBoost)} must be at least 0.");
				}
				_natureStatBoost = value;
				OnPropertyChanged(nameof(NatureStatBoost));
			}
		}
	}
	/// <summary>The default value of <see cref="MaxStatChange"/>.</summary>
	public const sbyte DefaultMaxStatChange = 6;
	private sbyte _maxStatChange = DefaultMaxStatChange;
	/// <summary>The maximum change a stat can have in the negative and positive direction.</summary>
	public sbyte MaxStatChange
	{
		get => _maxStatChange;
		set
		{
			ShouldNotBeReadOnly();
			if (_maxStatChange != value)
			{
				_maxStatChange = value;
				OnPropertyChanged(nameof(MaxStatChange));
			}
		}
	}
	/// <summary>The default value of <see cref="NumMoves"/>.</summary>
	public const byte DefaultNumMoves = 4;
	private byte _numMoves = DefaultNumMoves;
	/// <summary>The maximum amount of moves a specific Pokémon can remember at once.</summary>
	public byte NumMoves
	{
		get => _numMoves;
		set
		{
			ShouldNotBeReadOnly();
			if (_numMoves != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(NumMoves)} must be at least 1.");
				}
				_numMoves = value;
				OnPropertyChanged(nameof(NumMoves));
			}
		}
	}
	/// <summary>The default value of <see cref="PPMultiplier"/>.</summary>
	public const byte DefaultPPMultiplier = 5;
	private byte _ppMultiplier = DefaultPPMultiplier;
	/// <summary>This affects the base PP of each move and the boost PP-Ups give. The formulas that determine PP are at <see cref="PBEBattleMoveset.GetNonTransformPP(PBESettings, PBEMove, byte)"/> and <see cref="PBEBattleMoveset.GetTransformPP(PBESettings, PBEMove)"/>.</summary>
	public byte PPMultiplier
	{
		get => _ppMultiplier;
		set
		{
			ShouldNotBeReadOnly();
			if (_ppMultiplier != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(PPMultiplier)} must be at least 1.");
				}
				_ppMultiplier = value;
				OnPropertyChanged(nameof(PPMultiplier));
			}
		}
	}
	/// <summary>The default value of <see cref="MaxPPUps"/>.</summary>
	public const byte DefaultMaxPPUps = 3;
	private byte _maxPPUps = DefaultMaxPPUps;
	/// <summary>The maximum amount of PP-Ups that can be used on each of a Pokémon's moves.</summary>
	public byte MaxPPUps
	{
		get => _maxPPUps;
		set
		{
			ShouldNotBeReadOnly();
			if (_maxPPUps != value)
			{
				_maxPPUps = value;
				OnPropertyChanged(nameof(MaxPPUps));
			}
		}
	}
	/// <summary>The default value of <see cref="CritMultiplier"/>.</summary>
	public const float DefaultCritMultiplier = 2.0f;
	private float _critMultiplier = DefaultCritMultiplier;
	/// <summary>The damage boost awarded by critical hits.</summary>
	public float CritMultiplier
	{
		get => _critMultiplier;
		set
		{
			ShouldNotBeReadOnly();
			if (_critMultiplier != value)
			{
				_critMultiplier = value;
				OnPropertyChanged(nameof(CritMultiplier));
			}
		}
	}
	/// <summary>The default value of <see cref="ConfusionMaxTurns"/>.</summary>
	public const byte DefaultConfusionMaxTurns = 4;
	private byte _confusionMaxTurns = DefaultConfusionMaxTurns;
	/// <summary>The maximum amount of turns a Pokémon can be <see cref="PBEStatus2.Confused"/>.</summary>
	public byte ConfusionMaxTurns
	{
		get => _confusionMaxTurns;
		set
		{
			ShouldNotBeReadOnly();
			if (_confusionMaxTurns != value)
			{
				if (value < _confusionMinTurns)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(ConfusionMaxTurns)} must be at least {nameof(ConfusionMinTurns)} ({_confusionMinTurns}).");
				}
				_confusionMaxTurns = value;
				OnPropertyChanged(nameof(ConfusionMaxTurns));
			}
		}
	}
	/// <summary>The default value of <see cref="ConfusionMinTurns"/>.</summary>
	public const byte DefaultConfusionMinTurns = 1;
	private byte _confusionMinTurns = DefaultConfusionMinTurns;
	/// <summary>The minimum amount of turns a Pokémon can be <see cref="PBEStatus2.Confused"/>.</summary>
	public byte ConfusionMinTurns
	{
		get => _confusionMinTurns;
		set
		{
			ShouldNotBeReadOnly();
			if (_confusionMinTurns != value)
			{
				if (value > _confusionMaxTurns)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(ConfusionMinTurns)} cannot exceed {nameof(ConfusionMaxTurns)} ({_confusionMaxTurns}).");
				}
				_confusionMinTurns = value;
				OnPropertyChanged(nameof(ConfusionMinTurns));
			}
		}
	}
	/// <summary>The default value of <see cref="SleepMaxTurns"/>.</summary>
	public const byte DefaultSleepMaxTurns = 3;
	private byte _sleepMaxTurns = DefaultSleepMaxTurns;
	/// <summary>The maximum amount of turns a Pokémon can be <see cref="PBEStatus1.Asleep"/>. <see cref="PBEMoveEffect.Rest"/> will always sleep for <see cref="SleepMaxTurns"/> turns.</summary>
	public byte SleepMaxTurns
	{
		get => _sleepMaxTurns;
		set
		{
			ShouldNotBeReadOnly();
			if (_sleepMaxTurns != value)
			{
				if (value < _sleepMinTurns)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(SleepMaxTurns)} must be at least {nameof(SleepMinTurns)} ({_sleepMinTurns}).");
				}
				_sleepMaxTurns = value;
				OnPropertyChanged(nameof(SleepMaxTurns));
			}
		}
	}
	/// <summary>The default value of <see cref="SleepMinTurns"/>.</summary>
	public const byte DefaultSleepMinTurns = 1;
	private byte _sleepMinTurns = DefaultSleepMinTurns;
	/// <summary>The minimum amount of turns a Pokémon can be <see cref="PBEStatus1.Asleep"/>. <see cref="PBEMoveEffect.Rest"/> will ignore this value and always sleep for <see cref="SleepMaxTurns"/> turns.</summary>
	public byte SleepMinTurns
	{
		get => _sleepMinTurns;
		set
		{
			ShouldNotBeReadOnly();
			if (_sleepMinTurns != value)
			{
				if (value > _sleepMaxTurns)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(SleepMinTurns)} cannot exceed {nameof(SleepMaxTurns)} ({_sleepMaxTurns}).");
				}
				_sleepMinTurns = value;
				OnPropertyChanged(nameof(SleepMinTurns));
			}
		}
	}
	/// <summary>The default value of <see cref="BurnDamageDenominator"/>.</summary>
	public const byte DefaultBurnDamageDenominator = 8;
	private byte _burnDamageDenominator = DefaultBurnDamageDenominator;
	/// <summary>A Pokémon with <see cref="PBEStatus1.Burned"/> loses (1/this) of its HP at the end of every turn.</summary>
	public byte BurnDamageDenominator
	{
		get => _burnDamageDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_burnDamageDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(BurnDamageDenominator)} must be at least 1.");
				}
				_burnDamageDenominator = value;
				OnPropertyChanged(nameof(BurnDamageDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="PoisonDamageDenominator"/>.</summary>
	public const byte DefaultPoisonDamageDenominator = 8;
	private byte _poisonDamageDenominator = DefaultPoisonDamageDenominator;
	/// <summary>A Pokémon with <see cref="PBEStatus1.Poisoned"/> loses (1/this) of its HP at the end of every turn.</summary>
	public byte PoisonDamageDenominator
	{
		get => _poisonDamageDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_poisonDamageDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(PoisonDamageDenominator)} must be at least 1.");
				}
				_poisonDamageDenominator = value;
				OnPropertyChanged(nameof(PoisonDamageDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="ToxicDamageDenominator"/>.</summary>
	public const byte DefaultToxicDamageDenominator = 16;
	private byte _toxicDamageDenominator = DefaultToxicDamageDenominator;
	/// <summary>A Pokémon with <see cref="PBEStatus1.BadlyPoisoned"/> loses (<see cref="PBEBattlePokemon.Status1Counter"/>/this) of its HP at the end of every turn.</summary>
	public byte ToxicDamageDenominator
	{
		get => _toxicDamageDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_toxicDamageDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(ToxicDamageDenominator)} must be at least 1.");
				}
				_toxicDamageDenominator = value;
				OnPropertyChanged(nameof(ToxicDamageDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="LeechSeedDenominator"/>.</summary>
	public const byte DefaultLeechSeedDenominator = 8;
	private byte _leechSeedDenominator = DefaultLeechSeedDenominator;
	/// <summary>A Pokémon with <see cref="PBEStatus2.LeechSeed"/> loses (1/this) of its HP at the end of every turn and the Pokémon at <see cref="PBEBattlePokemon.SeededPosition"/> on <see cref="PBEBattlePokemon.SeededTeam"/> restores the lost HP.</summary>
	public byte LeechSeedDenominator
	{
		get => _leechSeedDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_leechSeedDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(LeechSeedDenominator)} must be at least 1.");
				}
				_leechSeedDenominator = value;
				OnPropertyChanged(nameof(LeechSeedDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="CurseDenominator"/>.</summary>
	public const byte DefaultCurseDenominator = 4;
	private byte _curseDenominator = DefaultCurseDenominator;
	/// <summary>A Pokémon with <see cref="PBEStatus2.Cursed"/> loses (1/this) of its HP at the end of every turn.</summary>
	public byte CurseDenominator
	{
		get => _curseDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_curseDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(CurseDenominator)} must be at least 1.");
				}
				_curseDenominator = value;
				OnPropertyChanged(nameof(CurseDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="LeftoversHealDenominator"/>.</summary>
	public const byte DefaultLeftoversHealDenominator = 16;
	private byte _leftoversHealDenominator = DefaultLeftoversHealDenominator;
	/// <summary>A Pokémon holding a <see cref="PBEItem.Leftovers"/> restores (1/this) of its HP at the end of every turn.</summary>
	public byte LeftoversHealDenominator
	{
		get => _leftoversHealDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_leftoversHealDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(LeftoversHealDenominator)} must be at least 1.");
				}
				_leftoversHealDenominator = value;
				OnPropertyChanged(nameof(LeftoversHealDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="BlackSludgeDamageDenominator"/>.</summary>
	public const byte DefaultBlackSludgeDamageDenominator = 8;
	private byte _blackSludgeDamageDenominator = DefaultBlackSludgeDamageDenominator;
	/// <summary>A Pokémon holding a <see cref="PBEItem.BlackSludge"/> without <see cref="PBEType.Poison"/> loses (1/this) of its HP at the end of every turn.</summary>
	public byte BlackSludgeDamageDenominator
	{
		get => _blackSludgeDamageDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_blackSludgeDamageDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(BlackSludgeDamageDenominator)} must be at least 1.");
				}
				_blackSludgeDamageDenominator = value;
				OnPropertyChanged(nameof(BlackSludgeDamageDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="BlackSludgeHealDenominator"/>.</summary>
	public const byte DefaultBlackSludgeHealDenominator = 16;
	private byte _blackSludgeHealDenominator = DefaultBlackSludgeHealDenominator;
	/// <summary>A Pokémon holding a <see cref="PBEItem.BlackSludge"/> with <see cref="PBEType.Poison"/> restores (1/this) of its HP at the end of every turn.</summary>
	public byte BlackSludgeHealDenominator
	{
		get => _blackSludgeHealDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_blackSludgeHealDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(BlackSludgeHealDenominator)} must be at least 1.");
				}
				_blackSludgeHealDenominator = value;
				OnPropertyChanged(nameof(BlackSludgeHealDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="ReflectTurns"/>.</summary>
	public const byte DefaultReflectTurns = 5;
	private byte _reflectTurns = DefaultReflectTurns;
	/// <summary>The amount of turns <see cref="PBEMoveEffect.Reflect"/> lasts.</summary>
	public byte ReflectTurns
	{
		get => _reflectTurns;
		set
		{
			ShouldNotBeReadOnly();
			if (_reflectTurns != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(ReflectTurns)} must be at least 1.");
				}
				_reflectTurns = value;
				OnPropertyChanged(nameof(ReflectTurns));
			}
		}
	}
	/// <summary>The default value of <see cref="LightScreenTurns"/>.</summary>
	public const byte DefaultLightScreenTurns = 5;
	private byte _lightScreenTurns = DefaultLightScreenTurns;
	/// <summary>The amount of turns <see cref="PBEMoveEffect.LightScreen"/> lasts.</summary>
	public byte LightScreenTurns
	{
		get => _lightScreenTurns;
		set
		{
			ShouldNotBeReadOnly();
			if (_lightScreenTurns != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(LightScreenTurns)} must be at least 1.");
				}
				_lightScreenTurns = value;
				OnPropertyChanged(nameof(LightScreenTurns));
			}
		}
	}
	/// <summary>The default value of <see cref="LightClayTurnExtension"/>.</summary>
	public const byte DefaultLightClayTurnExtension = 3;
	private byte _lightClayTurnExtension = DefaultLightClayTurnExtension;
	/// <summary>The amount of turns added to <see cref="ReflectTurns"/> and <see cref="LightScreenTurns"/> when the user is holding a <see cref="PBEItem.LightClay"/>.</summary>
	public byte LightClayTurnExtension
	{
		get => _lightClayTurnExtension;
		set
		{
			ShouldNotBeReadOnly();
			if (_lightClayTurnExtension != value)
			{
				_lightClayTurnExtension = value;
				OnPropertyChanged(nameof(LightClayTurnExtension));
			}
		}
	}
	/// <summary>The default value of <see cref="HailTurns"/>.</summary>
	public const byte DefaultHailTurns = 5;
	private byte _hailTurns = DefaultHailTurns;
	/// <summary>The amount of turns <see cref="PBEWeather.Hailstorm"/> lasts. For infinite turns, set <see cref="IcyRockTurnExtension"/> to 0 first, then this to 0.</summary>
	public byte HailTurns
	{
		get => _hailTurns;
		set
		{
			ShouldNotBeReadOnly();
			if (_hailTurns != value)
			{
				if (value == 0 && _icyRockTurnExtension != 0)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"For infinite turns, set {nameof(IcyRockTurnExtension)} to 0 first, then {nameof(HailTurns)} to 0.");
				}
				_hailTurns = value;
				OnPropertyChanged(nameof(HailTurns));
			}
		}
	}
	/// <summary>The default value of <see cref="HailDamageDenominator"/>.</summary>
	public const byte DefaultHailDamageDenominator = 16;
	private byte _hailDamageDenominator = DefaultHailDamageDenominator;
	/// <summary>A Pokémon in <see cref="PBEWeather.Hailstorm"/> loses (1/this) of its HP at the end of every turn.</summary>
	public byte HailDamageDenominator
	{
		get => _hailDamageDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_hailDamageDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(HailDamageDenominator)} must be at least 1.");
				}
				_hailDamageDenominator = value;
				OnPropertyChanged(nameof(HailDamageDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="IcyRockTurnExtension"/>.</summary>
	public const byte DefaultIcyRockTurnExtension = 3;
	private byte _icyRockTurnExtension = DefaultIcyRockTurnExtension;
	/// <summary>The amount of turns added to <see cref="HailTurns"/> when the user is holding a <see cref="PBEItem.IcyRock"/>. If <see cref="HailTurns"/> is 0 (infinite turns), this must also be 0.</summary>
	public byte IcyRockTurnExtension
	{
		get => _icyRockTurnExtension;
		set
		{
			ShouldNotBeReadOnly();
			if (_icyRockTurnExtension != value)
			{
				if (value != 0 && _hailTurns == 0)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"If {nameof(HailTurns)} is 0 (infinite turns), {nameof(IcyRockTurnExtension)} must also be 0.");
				}
				_icyRockTurnExtension = value;
				OnPropertyChanged(nameof(IcyRockTurnExtension));
			}
		}
	}
	/// <summary>The default value of <see cref="IceBodyHealDenominator"/>.</summary>
	public const byte DefaultIceBodyHealDenominator = 16;
	private byte _iceBodyHealDenominator = DefaultIceBodyHealDenominator;
	/// <summary>A Pokémon with <see cref="PBEAbility.IceBody"/> in <see cref="PBEWeather.Hailstorm"/> restores (1/this) of its HP at the end of every turn.</summary>
	public byte IceBodyHealDenominator
	{
		get => _iceBodyHealDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_iceBodyHealDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(IceBodyHealDenominator)} must be at least 1.");
				}
				_iceBodyHealDenominator = value;
				OnPropertyChanged(nameof(IceBodyHealDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="RainTurns"/>.</summary>
	public const byte DefaultRainTurns = 5;
	private byte _rainTurns = DefaultRainTurns;
	/// <summary>The amount of turns <see cref="PBEWeather.Rain"/> lasts. For infinite turns, set <see cref="DampRockTurnExtension"/> to 0 first, then this to 0.</summary>
	public byte RainTurns
	{
		get => _rainTurns;
		set
		{
			ShouldNotBeReadOnly();
			if (_rainTurns != value)
			{
				if (value == 0 && _dampRockTurnExtension != 0)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"For infinite turns, set {nameof(DampRockTurnExtension)} to 0 first, then {nameof(RainTurns)} to 0.");
				}
				_rainTurns = value;
				OnPropertyChanged(nameof(RainTurns));
			}
		}
	}
	/// <summary>The default value of <see cref="DampRockTurnExtension"/>.</summary>
	public const byte DefaultDampRockTurnExtension = 3;
	private byte _dampRockTurnExtension = DefaultDampRockTurnExtension;
	/// <summary>The amount of turns added to <see cref="RainTurns"/> when the user is holding a <see cref="PBEItem.DampRock"/>. If <see cref="RainTurns"/> is 0 (infinite turns), this must also be 0.</summary>
	public byte DampRockTurnExtension
	{
		get => _dampRockTurnExtension;
		set
		{
			ShouldNotBeReadOnly();
			if (_dampRockTurnExtension != value)
			{
				if (value != 0 && _rainTurns == 0)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"If {nameof(RainTurns)} is 0 (infinite turns), {nameof(DampRockTurnExtension)} must also be 0.");
				}
				_dampRockTurnExtension = value;
				OnPropertyChanged(nameof(DampRockTurnExtension));
			}
		}
	}
	/// <summary>The default value of <see cref="SandstormTurns"/>.</summary>
	public const byte DefaultSandstormTurns = 5;
	private byte _sandstormTurns = DefaultSandstormTurns;
	/// <summary>The amount of turns <see cref="PBEWeather.Sandstorm"/> lasts. For infinite turns, set <see cref="SmoothRockTurnExtension"/> to 0 first, then this to 0.</summary>
	public byte SandstormTurns
	{
		get => _sandstormTurns;
		set
		{
			ShouldNotBeReadOnly();
			if (_sandstormTurns != value)
			{
				if (value == 0 && _smoothRockTurnExtension != 0)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"For infinite turns, set {nameof(SmoothRockTurnExtension)} to 0 first, then {nameof(SandstormTurns)} to 0.");
				}
				_sandstormTurns = value;
				OnPropertyChanged(nameof(SandstormTurns));
			}
		}
	}
	/// <summary>The default value of <see cref="SandstormDamageDenominator"/>.</summary>
	public const byte DefaultSandstormDamageDenominator = 16;
	private byte _sandstormDamageDenominator = DefaultSandstormDamageDenominator;
	/// <summary>A Pokémon in <see cref="PBEWeather.Sandstorm"/> loses (1/this) of its HP at the end of every turn.</summary>
	public byte SandstormDamageDenominator
	{
		get => _sandstormDamageDenominator;
		set
		{
			ShouldNotBeReadOnly();
			if (_sandstormDamageDenominator != value)
			{
				if (value < 1)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(SandstormDamageDenominator)} must be at least 1.");
				}
				_sandstormDamageDenominator = value;
				OnPropertyChanged(nameof(SandstormDamageDenominator));
			}
		}
	}
	/// <summary>The default value of <see cref="SmoothRockTurnExtension"/>.</summary>
	public const byte DefaultSmoothRockTurnExtension = 3;
	private byte _smoothRockTurnExtension = DefaultSmoothRockTurnExtension;
	/// <summary>The amount of turns added to <see cref="SandstormTurns"/> when the user is holding a <see cref="PBEItem.SmoothRock"/>. If <see cref="SandstormTurns"/> is 0 (infinite turns), this must also be 0.</summary>
	public byte SmoothRockTurnExtension
	{
		get => _smoothRockTurnExtension;
		set
		{
			ShouldNotBeReadOnly();
			if (_smoothRockTurnExtension != value)
			{
				if (value != 0 && _sandstormTurns == 0)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"If {nameof(SandstormTurns)} is 0 (infinite turns), {nameof(SmoothRockTurnExtension)} must also be 0.");
				}
				_smoothRockTurnExtension = value;
				OnPropertyChanged(nameof(SmoothRockTurnExtension));
			}
		}
	}
	/// <summary>The default value of <see cref="SunTurns"/>.</summary>
	public const byte DefaultSunTurns = 5;
	private byte _sunTurns = DefaultSunTurns;
	/// <summary>The amount of turns <see cref="PBEWeather.HarshSunlight"/> lasts. For infinite turns, set <see cref="HeatRockTurnExtension"/> to 0 first, then this to 0.</summary>
	public byte SunTurns
	{
		get => _sunTurns;
		set
		{
			ShouldNotBeReadOnly();
			if (_sunTurns != value)
			{
				if (value == 0 && _heatRockTurnExtension != 0)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"For infinite turns, set {nameof(HeatRockTurnExtension)} to 0 first, then {nameof(SunTurns)} to 0.");
				}
				_sunTurns = value;
				OnPropertyChanged(nameof(SunTurns));
			}
		}
	}
	/// <summary>The default value of <see cref="HeatRockTurnExtension"/>.</summary>
	public const byte DefaultHeatRockTurnExtension = 3;
	private byte _heatRockTurnExtension = DefaultHeatRockTurnExtension;
	/// <summary>The amount of turns added to <see cref="SunTurns"/> when the user is holding a <see cref="PBEItem.HeatRock"/>. If <see cref="SunTurns"/> is 0 (infinite turns), this must also be 0.</summary>
	public byte HeatRockTurnExtension
	{
		get => _heatRockTurnExtension;
		set
		{
			ShouldNotBeReadOnly();
			if (_heatRockTurnExtension != value)
			{
				if (value != 0 && _sunTurns == 0)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"If {nameof(SunTurns)} is 0 (infinite turns), {nameof(HeatRockTurnExtension)} must also be 0.");
				}
				_heatRockTurnExtension = value;
				OnPropertyChanged(nameof(HeatRockTurnExtension));
			}
		}
	}
	/// <summary>The default value of <see cref="HiddenPowerMax"/>.</summary>
	public const byte DefaultHiddenPowerMax = 70;
	private byte _hiddenPowerMax = DefaultHiddenPowerMax;
	/// <summary>The maximum base power of <see cref="PBEMoveEffect.HiddenPower"/>.</summary>
	public byte HiddenPowerMax
	{
		get => _hiddenPowerMax;
		set
		{
			ShouldNotBeReadOnly();
			if (_hiddenPowerMax != value)
			{
				if (value < _hiddenPowerMin)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(HiddenPowerMax)} must be at least {nameof(HiddenPowerMin)} ({_hiddenPowerMin}).");
				}
				_hiddenPowerMax = value;
				OnPropertyChanged(nameof(HiddenPowerMax));
			}
		}
	}
	/// <summary>The default value of <see cref="HiddenPowerMin"/>.</summary>
	public const byte DefaultHiddenPowerMin = 30;
	private byte _hiddenPowerMin = DefaultHiddenPowerMin;
	/// <summary>The minimum base power of <see cref="PBEMoveEffect.HiddenPower"/>.</summary>
	public byte HiddenPowerMin
	{
		get => _hiddenPowerMin;
		set
		{
			ShouldNotBeReadOnly();
			if (_hiddenPowerMin != value)
			{
				if (value == 0 || value > _hiddenPowerMax)
				{
					throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(HiddenPowerMin)} must be at least 1 and cannot exceed {nameof(HiddenPowerMax)} ({_hiddenPowerMax}).");
				}
				_hiddenPowerMin = value;
				OnPropertyChanged(nameof(HiddenPowerMin));
			}
		}
	}
	/// <summary>The default value of <see cref="BugFix"/>.</summary>
	public const bool DefaultBugFix = false;
	private bool _bugFix = DefaultBugFix;
	/// <summary>Whether bugfixes should be applied or not.</summary>
	public bool BugFix
	{
		get => _bugFix;
		set
		{
			ShouldNotBeReadOnly();
			if (_bugFix != value)
			{
				_bugFix = value;
				OnPropertyChanged(nameof(BugFix));
			}
		}
	}

	#endregion

	/// <summary>Creates a new <see cref="PBESettings"/> object where every setting is pre-set to the values used in official games.</summary>
	public PBESettings() { }
	/// <summary>Creates a new <see cref="PBESettings"/> object with the specified code <see cref="string"/>.</summary>
	/// <param name="code">The code <see cref="string"/> to use.</param>
	public PBESettings(string code)
	{
		using (var ms = new MemoryStream(Convert.FromBase64String(code)))
		{
			FromBytes(new EndianBinaryReader(ms));
		}
	}
	/// <summary>Creates a new <see cref="PBESettings"/> object which copies the settings from the specified <see cref="PBESettings"/> object. <see cref="IsReadOnly"/> and <see cref="PropertyChanged"/> are not copied.</summary>
	/// <param name="other">The <see cref="PBESettings"/> object to copy settings from.</param>
	public PBESettings(PBESettings other)
	{
		other.ShouldBeReadOnly(nameof(other));

		MaxLevel = other._maxLevel;
		MinLevel = other._minLevel;
		MaxPartySize = other._maxPartySize;
		MaxPokemonNameLength = other._maxPokemonNameLength;
		MaxTrainerNameLength = other._maxTrainerNameLength;
		MaxTotalEVs = other._maxTotalEVs;
		MaxIVs = other._maxIVs;
		NatureStatBoost = other._natureStatBoost;
		MaxStatChange = other._maxStatChange;
		NumMoves = other._numMoves;
		PPMultiplier = other._ppMultiplier;
		MaxPPUps = other._maxPPUps;
		CritMultiplier = other._critMultiplier;
		ConfusionMaxTurns = other._confusionMaxTurns;
		ConfusionMinTurns = other._confusionMinTurns;
		SleepMaxTurns = other._sleepMaxTurns;
		SleepMinTurns = other._sleepMinTurns;
		BurnDamageDenominator = other._burnDamageDenominator;
		PoisonDamageDenominator = other._poisonDamageDenominator;
		ToxicDamageDenominator = other._toxicDamageDenominator;
		LeechSeedDenominator = other._leechSeedDenominator;
		CurseDenominator = other._curseDenominator;
		LeftoversHealDenominator = other._leftoversHealDenominator;
		BlackSludgeDamageDenominator = other._blackSludgeDamageDenominator;
		BlackSludgeHealDenominator = other._blackSludgeHealDenominator;
		ReflectTurns = other._reflectTurns;
		LightScreenTurns = other._lightScreenTurns;
		LightClayTurnExtension = other._lightClayTurnExtension;
		HailTurns = other._hailTurns;
		HailDamageDenominator = other._hailDamageDenominator;
		IcyRockTurnExtension = other._icyRockTurnExtension;
		IceBodyHealDenominator = other._iceBodyHealDenominator;
		RainTurns = other._rainTurns;
		DampRockTurnExtension = other._dampRockTurnExtension;
		SandstormTurns = other._sandstormTurns;
		SandstormDamageDenominator = other._sandstormDamageDenominator;
		SmoothRockTurnExtension = other._smoothRockTurnExtension;
		SunTurns = other._sunTurns;
		HeatRockTurnExtension = other._heatRockTurnExtension;
		HiddenPowerMax = other._hiddenPowerMax;
		HiddenPowerMin = other._hiddenPowerMin;
		BugFix = other._bugFix;
	}
	public PBESettings(EndianBinaryReader r)
	{
		FromBytes(r);
	}

	private void ShouldNotBeReadOnly()
	{
		if (_isReadOnly)
		{
			throw new InvalidOperationException($"This {nameof(PBESettings)} is marked as read-only.");
		}
	}
	public void ShouldBeReadOnly(string nameOf)
	{
		if (!_isReadOnly)
		{
			throw new ArgumentException("Settings must be read-only.", nameOf);
		}
	}
	/// <summary>Marks this <see cref="PBESettings"/> object as read-only and clears <see cref="PropertyChanged"/>.</summary>
	public void MakeReadOnly()
	{
		if (!_isReadOnly)
		{
			IsReadOnly = true;
			OnPropertyChanged(nameof(IsReadOnly));
			PropertyChanged = null;
		}
	}

	public override int GetHashCode()
	{
		var hash = new HashCode();
		hash.Add(_maxLevel);
		hash.Add(_minLevel);
		hash.Add(_maxPartySize);
		hash.Add(_maxPokemonNameLength);
		hash.Add(_maxTrainerNameLength);
		hash.Add(_maxTotalEVs);
		hash.Add(_maxIVs);
		hash.Add(_natureStatBoost);
		hash.Add(_maxStatChange);
		hash.Add(_numMoves);
		hash.Add(_ppMultiplier);
		hash.Add(_maxPPUps);
		hash.Add(_critMultiplier);
		hash.Add(_confusionMaxTurns);
		hash.Add(_confusionMinTurns);
		hash.Add(_sleepMaxTurns);
		hash.Add(_sleepMinTurns);
		hash.Add(_burnDamageDenominator);
		hash.Add(_poisonDamageDenominator);
		hash.Add(_toxicDamageDenominator);
		hash.Add(_leechSeedDenominator);
		hash.Add(_curseDenominator);
		hash.Add(_leftoversHealDenominator);
		hash.Add(_blackSludgeDamageDenominator);
		hash.Add(_blackSludgeHealDenominator);
		hash.Add(_reflectTurns);
		hash.Add(_lightScreenTurns);
		hash.Add(_lightClayTurnExtension);
		hash.Add(_hailTurns);
		hash.Add(_hailDamageDenominator);
		hash.Add(_icyRockTurnExtension);
		hash.Add(_iceBodyHealDenominator);
		hash.Add(_rainTurns);
		hash.Add(_dampRockTurnExtension);
		hash.Add(_sandstormTurns);
		hash.Add(_sandstormDamageDenominator);
		hash.Add(_smoothRockTurnExtension);
		hash.Add(_sunTurns);
		hash.Add(_heatRockTurnExtension);
		hash.Add(_hiddenPowerMax);
		hash.Add(_hiddenPowerMin);
		hash.Add(_bugFix);
		return hash.ToHashCode();
	}

	/// <summary>Returns a value indicating whether a code <see cref="string"/> or another <see cref="PBESettings"/> object represents the same settings as this <see cref="PBESettings"/> object.</summary>
	/// <param name="obj">The code <see cref="string"/> or the <see cref="PBESettings"/> object to check for equality.</param>
	public override bool Equals(object? obj)
	{
		if (obj is null)
		{
			return false;
		}
		if (ReferenceEquals(obj, this))
		{
			return true;
		}
		if (obj is string str)
		{
			PBESettings ps;
			try
			{
				ps = new PBESettings(str);
			}
			catch
			{
				return false;
			}
			return ps.Equals(this);
		}
		if (obj is PBESettings other)
		{
			return other._maxLevel.Equals(_maxLevel)
				&& other._minLevel.Equals(_minLevel)
				&& other._maxPartySize.Equals(_maxPartySize)
				&& other._maxPokemonNameLength.Equals(_maxPokemonNameLength)
				&& other._maxTrainerNameLength.Equals(_maxTrainerNameLength)
				&& other._maxTotalEVs.Equals(_maxTotalEVs)
				&& other._maxIVs.Equals(_maxIVs)
				&& other._natureStatBoost.Equals(_natureStatBoost)
				&& other._maxStatChange.Equals(_maxStatChange)
				&& other._numMoves.Equals(_numMoves)
				&& other._ppMultiplier.Equals(_ppMultiplier)
				&& other._maxPPUps.Equals(_maxPPUps)
				&& other._critMultiplier.Equals(_critMultiplier)
				&& other._confusionMaxTurns.Equals(_confusionMaxTurns)
				&& other._confusionMinTurns.Equals(_confusionMinTurns)
				&& other._sleepMaxTurns.Equals(_sleepMaxTurns)
				&& other._sleepMinTurns.Equals(_sleepMinTurns)
				&& other._burnDamageDenominator.Equals(_burnDamageDenominator)
				&& other._poisonDamageDenominator.Equals(_poisonDamageDenominator)
				&& other._toxicDamageDenominator.Equals(_toxicDamageDenominator)
				&& other._leechSeedDenominator.Equals(_leechSeedDenominator)
				&& other._curseDenominator.Equals(_curseDenominator)
				&& other._leftoversHealDenominator.Equals(_leftoversHealDenominator)
				&& other._blackSludgeDamageDenominator.Equals(_blackSludgeDamageDenominator)
				&& other._blackSludgeHealDenominator.Equals(_blackSludgeHealDenominator)
				&& other._reflectTurns.Equals(_reflectTurns)
				&& other._lightScreenTurns.Equals(_lightScreenTurns)
				&& other._lightClayTurnExtension.Equals(_lightClayTurnExtension)
				&& other._hailTurns.Equals(_hailTurns)
				&& other._hailDamageDenominator.Equals(_hailDamageDenominator)
				&& other._icyRockTurnExtension.Equals(_icyRockTurnExtension)
				&& other._iceBodyHealDenominator.Equals(_iceBodyHealDenominator)
				&& other._rainTurns.Equals(_rainTurns)
				&& other._dampRockTurnExtension.Equals(_dampRockTurnExtension)
				&& other._sandstormTurns.Equals(_sandstormTurns)
				&& other._sandstormDamageDenominator.Equals(_sandstormDamageDenominator)
				&& other._smoothRockTurnExtension.Equals(_smoothRockTurnExtension)
				&& other._sunTurns.Equals(_sunTurns)
				&& other._heatRockTurnExtension.Equals(_heatRockTurnExtension)
				&& other._hiddenPowerMax.Equals(_hiddenPowerMax)
				&& other._hiddenPowerMin.Equals(_hiddenPowerMin)
				&& other._bugFix.Equals(_bugFix);
		}
		return false;
	}

	private enum PBESettingID : ushort
	{
		MaxLevel,
		MinLevel,
		MaxPartySize,
		MaxPokemonNameLength,
		MaxTrainerNameLength,
		MaxTotalEVs,
		MaxIVs,
		NatureStatBoost,
		MaxStatChange,
		NumMoves,
		PPMultiplier,
		MaxPPUps,
		CritMultiplier,
		ConfusionMaxTurns,
		ConfusionMinTurns,
		SleepMaxTurns,
		SleepMinTurns,
		BurnDamageDenominator,
		PoisonDamageDenominator,
		ToxicDamageDenominator,
		LeechSeedDenominator,
		CurseDenominator,
		LeftoversHealDenominator,
		BlackSludgeDamageDenominator,
		BlackSludgeHealDenominator,
		ReflectTurns,
		LightScreenTurns,
		LightClayTurnExtension,
		HailTurns,
		HailDamageDenominator,
		IcyRockTurnExtension,
		IceBodyHealDenominator,
		RainTurns,
		DampRockTurnExtension,
		SandstormTurns,
		SandstormDamageDenominator,
		SmoothRockTurnExtension,
		SunTurns,
		HeatRockTurnExtension,
		HiddenPowerMax,
		HiddenPowerMin,
		BugFix
	}

	/// <summary>Converts this <see cref="PBESettings"/> object into a unique code <see cref="string"/>.</summary>
	public override string ToString()
	{
		return Convert.ToBase64String(ToBytes());
	}

	public byte[] ToBytes()
	{
		byte[] data;
		ushort numChanged = 0;
		using (var ms = new MemoryStream())
		{
			var w = new EndianBinaryWriter(ms);

			if (_maxLevel != DefaultMaxLevel)
			{
				w.WriteEnum(PBESettingID.MaxLevel);
				w.WriteByte(_maxLevel);
				numChanged++;
			}
			if (_minLevel != DefaultMinLevel)
			{
				w.WriteEnum(PBESettingID.MinLevel);
				w.WriteByte(_minLevel);
				numChanged++;
			}
			if (_maxPartySize != DefaultMaxPartySize)
			{
				w.WriteEnum(PBESettingID.MaxPartySize);
				w.WriteByte(_maxPartySize);
				numChanged++;
			}
			if (_maxPokemonNameLength != DefaultMaxPokemonNameLength)
			{
				w.WriteEnum(PBESettingID.MaxPokemonNameLength);
				w.WriteByte(_maxPokemonNameLength);
				numChanged++;
			}
			if (_maxTrainerNameLength != DefaultMaxTrainerNameLength)
			{
				w.WriteEnum(PBESettingID.MaxTrainerNameLength);
				w.WriteByte(_maxTrainerNameLength);
				numChanged++;
			}
			if (_maxTotalEVs != DefaultMaxTotalEVs)
			{
				w.WriteEnum(PBESettingID.MaxTotalEVs);
				w.WriteUInt16(_maxTotalEVs);
				numChanged++;
			}
			if (_maxIVs != DefaultMaxIVs)
			{
				w.WriteEnum(PBESettingID.MaxIVs);
				w.WriteByte(_maxIVs);
				numChanged++;
			}
			if (_natureStatBoost != DefaultNatureStatBoost)
			{
				w.WriteEnum(PBESettingID.NatureStatBoost);
				w.WriteSingle(_natureStatBoost);
				numChanged++;
			}
			if (_maxStatChange != DefaultMaxStatChange)
			{
				w.WriteEnum(PBESettingID.MaxStatChange);
				w.WriteSByte(_maxStatChange);
				numChanged++;
			}
			if (_numMoves != DefaultNumMoves)
			{
				w.WriteEnum(PBESettingID.NumMoves);
				w.WriteByte(_numMoves);
				numChanged++;
			}
			if (_ppMultiplier != DefaultPPMultiplier)
			{
				w.WriteEnum(PBESettingID.PPMultiplier);
				w.WriteByte(_ppMultiplier);
				numChanged++;
			}
			if (_maxPPUps != DefaultMaxPPUps)
			{
				w.WriteEnum(PBESettingID.MaxPPUps);
				w.WriteByte(_maxPPUps);
				numChanged++;
			}
			if (_critMultiplier != DefaultCritMultiplier)
			{
				w.WriteEnum(PBESettingID.CritMultiplier);
				w.WriteSingle(_critMultiplier);
				numChanged++;
			}
			if (_confusionMaxTurns != DefaultConfusionMaxTurns)
			{
				w.WriteEnum(PBESettingID.ConfusionMaxTurns);
				w.WriteByte(_confusionMaxTurns);
				numChanged++;
			}
			if (_confusionMinTurns != DefaultConfusionMinTurns)
			{
				w.WriteEnum(PBESettingID.ConfusionMinTurns);
				w.WriteByte(_confusionMinTurns);
				numChanged++;
			}
			if (_sleepMaxTurns != DefaultSleepMaxTurns)
			{
				w.WriteEnum(PBESettingID.SleepMaxTurns);
				w.WriteByte(_sleepMaxTurns);
				numChanged++;
			}
			if (_sleepMinTurns != DefaultSleepMinTurns)
			{
				w.WriteEnum(PBESettingID.SleepMinTurns);
				w.WriteByte(_sleepMinTurns);
				numChanged++;
			}
			if (_burnDamageDenominator != DefaultBurnDamageDenominator)
			{
				w.WriteEnum(PBESettingID.BurnDamageDenominator);
				w.WriteByte(_burnDamageDenominator);
				numChanged++;
			}
			if (_poisonDamageDenominator != DefaultPoisonDamageDenominator)
			{
				w.WriteEnum(PBESettingID.PoisonDamageDenominator);
				w.WriteByte(_poisonDamageDenominator);
				numChanged++;
			}
			if (_toxicDamageDenominator != DefaultToxicDamageDenominator)
			{
				w.WriteEnum(PBESettingID.ToxicDamageDenominator);
				w.WriteByte(_toxicDamageDenominator);
				numChanged++;
			}
			if (_leechSeedDenominator != DefaultLeechSeedDenominator)
			{
				w.WriteEnum(PBESettingID.LeechSeedDenominator);
				w.WriteByte(_leechSeedDenominator);
				numChanged++;
			}
			if (_curseDenominator != DefaultCurseDenominator)
			{
				w.WriteEnum(PBESettingID.CurseDenominator);
				w.WriteByte(_curseDenominator);
				numChanged++;
			}
			if (_leftoversHealDenominator != DefaultLeftoversHealDenominator)
			{
				w.WriteEnum(PBESettingID.LeftoversHealDenominator);
				w.WriteByte(_leftoversHealDenominator);
				numChanged++;
			}
			if (_blackSludgeDamageDenominator != DefaultBlackSludgeDamageDenominator)
			{
				w.WriteEnum(PBESettingID.BlackSludgeDamageDenominator);
				w.WriteByte(_blackSludgeDamageDenominator);
				numChanged++;
			}
			if (_blackSludgeHealDenominator != DefaultBlackSludgeHealDenominator)
			{
				w.WriteEnum(PBESettingID.BlackSludgeHealDenominator);
				w.WriteByte(_blackSludgeHealDenominator);
				numChanged++;
			}
			if (_reflectTurns != DefaultReflectTurns)
			{
				w.WriteEnum(PBESettingID.ReflectTurns);
				w.WriteByte(_reflectTurns);
				numChanged++;
			}
			if (_lightScreenTurns != DefaultLightScreenTurns)
			{
				w.WriteEnum(PBESettingID.LightScreenTurns);
				w.WriteByte(_lightScreenTurns);
				numChanged++;
			}
			if (_lightClayTurnExtension != DefaultLightClayTurnExtension)
			{
				w.WriteEnum(PBESettingID.LightClayTurnExtension);
				w.WriteByte(_lightClayTurnExtension);
				numChanged++;
			}
			if (_hailTurns != DefaultHailTurns)
			{
				w.WriteEnum(PBESettingID.HailTurns);
				w.WriteByte(_hailTurns);
				numChanged++;
			}
			if (_hailDamageDenominator != DefaultHailDamageDenominator)
			{
				w.WriteEnum(PBESettingID.HailDamageDenominator);
				w.WriteByte(_hailDamageDenominator);
				numChanged++;
			}
			if (_icyRockTurnExtension != DefaultIcyRockTurnExtension)
			{
				w.WriteEnum(PBESettingID.IcyRockTurnExtension);
				w.WriteByte(_icyRockTurnExtension);
				numChanged++;
			}
			if (_iceBodyHealDenominator != DefaultIceBodyHealDenominator)
			{
				w.WriteEnum(PBESettingID.IceBodyHealDenominator);
				w.WriteByte(_iceBodyHealDenominator);
				numChanged++;
			}
			if (_rainTurns != DefaultRainTurns)
			{
				w.WriteEnum(PBESettingID.RainTurns);
				w.WriteByte(_rainTurns);
				numChanged++;
			}
			if (_dampRockTurnExtension != DefaultDampRockTurnExtension)
			{
				w.WriteEnum(PBESettingID.DampRockTurnExtension);
				w.WriteByte(_dampRockTurnExtension);
				numChanged++;
			}
			if (_sandstormTurns != DefaultSandstormTurns)
			{
				w.WriteEnum(PBESettingID.SandstormTurns);
				w.WriteByte(_sandstormTurns);
				numChanged++;
			}
			if (_sandstormDamageDenominator != DefaultSandstormDamageDenominator)
			{
				w.WriteEnum(PBESettingID.SandstormDamageDenominator);
				w.WriteByte(_sandstormDamageDenominator);
				numChanged++;
			}
			if (_smoothRockTurnExtension != DefaultSmoothRockTurnExtension)
			{
				w.WriteEnum(PBESettingID.SmoothRockTurnExtension);
				w.WriteByte(_smoothRockTurnExtension);
				numChanged++;
			}
			if (_sunTurns != DefaultSunTurns)
			{
				w.WriteEnum(PBESettingID.SunTurns);
				w.WriteByte(_sunTurns);
				numChanged++;
			}
			if (_heatRockTurnExtension != DefaultHeatRockTurnExtension)
			{
				w.WriteEnum(PBESettingID.HeatRockTurnExtension);
				w.WriteByte(_heatRockTurnExtension);
				numChanged++;
			}
			if (_hiddenPowerMax != DefaultHiddenPowerMax)
			{
				w.WriteEnum(PBESettingID.HiddenPowerMax);
				w.WriteByte(_hiddenPowerMax);
				numChanged++;
			}
			if (_hiddenPowerMin != DefaultHiddenPowerMin)
			{
				w.WriteEnum(PBESettingID.HiddenPowerMin);
				w.WriteByte(_hiddenPowerMin);
				numChanged++;
			}
			if (_bugFix != DefaultBugFix)
			{
				w.WriteEnum(PBESettingID.BugFix);
				w.WriteBoolean(_bugFix);
				numChanged++;
			}
			data = ms.ToArray();
		}
		byte[] ret = new byte[data.Length + 2];
		EndianBinaryPrimitives.WriteInt16(ret.AsSpan(0, 2), (short)numChanged, Endianness.LittleEndian);
		Array.Copy(data, 0, ret, 2, data.Length);
		return ret;
	}
	private void FromBytes(EndianBinaryReader r)
	{
		ushort numChanged = r.ReadUInt16();
		for (ushort i = 0; i < numChanged; i++)
		{
			switch (r.ReadEnum<PBESettingID>())
			{
				case PBESettingID.MaxLevel: MaxLevel = r.ReadByte(); break;
				case PBESettingID.MinLevel: MinLevel = r.ReadByte(); break;
				case PBESettingID.MaxPartySize: MaxPartySize = r.ReadByte(); break;
				case PBESettingID.MaxPokemonNameLength: MaxPokemonNameLength = r.ReadByte(); break;
				case PBESettingID.MaxTrainerNameLength: MaxTrainerNameLength = r.ReadByte(); break;
				case PBESettingID.MaxTotalEVs: MaxTotalEVs = r.ReadUInt16(); break;
				case PBESettingID.MaxIVs: MaxIVs = r.ReadByte(); break;
				case PBESettingID.NatureStatBoost: NatureStatBoost = r.ReadSingle(); break;
				case PBESettingID.MaxStatChange: MaxStatChange = r.ReadSByte(); break;
				case PBESettingID.NumMoves: NumMoves = r.ReadByte(); break;
				case PBESettingID.PPMultiplier: PPMultiplier = r.ReadByte(); break;
				case PBESettingID.MaxPPUps: MaxPPUps = r.ReadByte(); break;
				case PBESettingID.CritMultiplier: CritMultiplier = r.ReadSingle(); break;
				case PBESettingID.ConfusionMaxTurns: ConfusionMaxTurns = r.ReadByte(); break;
				case PBESettingID.ConfusionMinTurns: ConfusionMinTurns = r.ReadByte(); break;
				case PBESettingID.SleepMaxTurns: SleepMaxTurns = r.ReadByte(); break;
				case PBESettingID.SleepMinTurns: SleepMinTurns = r.ReadByte(); break;
				case PBESettingID.BurnDamageDenominator: BurnDamageDenominator = r.ReadByte(); break;
				case PBESettingID.PoisonDamageDenominator: PoisonDamageDenominator = r.ReadByte(); break;
				case PBESettingID.ToxicDamageDenominator: ToxicDamageDenominator = r.ReadByte(); break;
				case PBESettingID.LeechSeedDenominator: LeechSeedDenominator = r.ReadByte(); break;
				case PBESettingID.CurseDenominator: CurseDenominator = r.ReadByte(); break;
				case PBESettingID.LeftoversHealDenominator: LeftoversHealDenominator = r.ReadByte(); break;
				case PBESettingID.BlackSludgeDamageDenominator: BlackSludgeDamageDenominator = r.ReadByte(); break;
				case PBESettingID.BlackSludgeHealDenominator: BlackSludgeHealDenominator = r.ReadByte(); break;
				case PBESettingID.ReflectTurns: ReflectTurns = r.ReadByte(); break;
				case PBESettingID.LightScreenTurns: LightScreenTurns = r.ReadByte(); break;
				case PBESettingID.LightClayTurnExtension: LightClayTurnExtension = r.ReadByte(); break;
				case PBESettingID.HailTurns: HailTurns = r.ReadByte(); break;
				case PBESettingID.HailDamageDenominator: HailDamageDenominator = r.ReadByte(); break;
				case PBESettingID.IcyRockTurnExtension: IcyRockTurnExtension = r.ReadByte(); break;
				case PBESettingID.IceBodyHealDenominator: IceBodyHealDenominator = r.ReadByte(); break;
				case PBESettingID.RainTurns: RainTurns = r.ReadByte(); break;
				case PBESettingID.DampRockTurnExtension: DampRockTurnExtension = r.ReadByte(); break;
				case PBESettingID.SandstormTurns: SandstormTurns = r.ReadByte(); break;
				case PBESettingID.SandstormDamageDenominator: SandstormDamageDenominator = r.ReadByte(); break;
				case PBESettingID.SmoothRockTurnExtension: SmoothRockTurnExtension = r.ReadByte(); break;
				case PBESettingID.SunTurns: SunTurns = r.ReadByte(); break;
				case PBESettingID.HeatRockTurnExtension: HeatRockTurnExtension = r.ReadByte(); break;
				case PBESettingID.HiddenPowerMax: HiddenPowerMax = r.ReadByte(); break;
				case PBESettingID.HiddenPowerMin: HiddenPowerMin = r.ReadByte(); break;
				case PBESettingID.BugFix: BugFix = r.ReadBoolean(); break;
				default: throw new InvalidDataException();
			}
		}
	}
}
#pragma warning restore CS0618 // Type or member is obsolete

