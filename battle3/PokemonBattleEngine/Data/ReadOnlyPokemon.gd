﻿using Kermalis.EndianBinaryIO;

namespace Kermalis.PokemonBattleEngine.Data;

public sealed class PBEReadOnlyPokemon : IPBEPokemon
{
	public bool PBEIgnore => false;
	public PBESpecies Species { get; }
	public PBEForm Form { get; }
	public PBEGender Gender { get; }
	public string Nickname { get; }
	public bool Shiny { get; }
	public byte Level { get; }
	public uint EXP { get; }
	public bool Pokerus { get; }
	public PBEItem Item { get; }
	public byte Friendship { get; }
	public PBEAbility Ability { get; }
	public PBENature Nature { get; }
	public PBEItem CaughtBall { get; }
	public IPBEStatCollection EffortValues { get; }
	public IPBEReadOnlyStatCollection IndividualValues { get; }
	public IPBEMoveset Moveset { get; }

	internal PBEReadOnlyPokemon(EndianBinaryReader r)
	{
		Species = r.ReadEnum<PBESpecies>();
		Form = r.ReadEnum<PBEForm>();
		Nickname = r.ReadString_NullTerminated();
		Level = r.ReadByte();
		EXP = r.ReadUInt32();
		Friendship = r.ReadByte();
		Shiny = r.ReadBoolean();
		Pokerus = r.ReadBoolean();
		Ability = r.ReadEnum<PBEAbility>();
		Nature = r.ReadEnum<PBENature>();
		CaughtBall = r.ReadEnum<PBEItem>();
		Gender = r.ReadEnum<PBEGender>();
		Item = r.ReadEnum<PBEItem>();
		EffortValues = new PBEStatCollection(r);
		IndividualValues = new PBEReadOnlyStatCollection(r);
		Moveset = new PBEReadOnlyMoveset(r);
	}
}
