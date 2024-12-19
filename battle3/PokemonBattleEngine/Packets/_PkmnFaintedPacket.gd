﻿using Kermalis.EndianBinaryIO;
using Kermalis.PokemonBattleEngine.Battle;
using System.Collections.ObjectModel;
using System.IO;

namespace Kermalis.PokemonBattleEngine.Packets;

public interface IPBEPkmnFaintedPacket : IPBEPacket
{
	PBETrainer PokemonTrainer { get; }
	PBEFieldPosition OldPosition { get; }
}
public sealed class PBEPkmnFaintedPacket : IPBEPkmnFaintedPacket
{
	public const ushort ID = 0x0E;
	public ReadOnlyCollection<byte> Data { get; }

	public PBETrainer PokemonTrainer { get; }
	public byte Pokemon { get; }
	public PBEFieldPosition OldPosition { get; }

	internal PBEPkmnFaintedPacket(PBEBattlePokemon pokemon, PBEFieldPosition oldPosition)
	{
		using (var ms = new MemoryStream())
		{
			EndianBinaryWriter w = PBEPacketProcessor.WritePacketID(ms, ID);

			w.WriteByte((PokemonTrainer = pokemon.Trainer).Id);
			w.WriteByte(Pokemon = pokemon.Id);
			w.WriteEnum(OldPosition = oldPosition);

			Data = new ReadOnlyCollection<byte>(ms.ToArray());
		}
	}
	internal PBEPkmnFaintedPacket(byte[] data, EndianBinaryReader r, PBEBattle battle)
	{
		Data = new ReadOnlyCollection<byte>(data);

		PokemonTrainer = battle.Trainers[r.ReadByte()];
		Pokemon = r.ReadByte();
		OldPosition = r.ReadEnum<PBEFieldPosition>();
	}
}
public sealed class PBEPkmnFaintedPacket_Hidden : IPBEPkmnFaintedPacket
{
	public const ushort ID = 0x2F;
	public ReadOnlyCollection<byte> Data { get; }

	public PBETrainer PokemonTrainer { get; }
	public PBEFieldPosition OldPosition { get; }

	public PBEPkmnFaintedPacket_Hidden(PBEPkmnFaintedPacket other)
	{
		using (var ms = new MemoryStream())
		{
			EndianBinaryWriter w = PBEPacketProcessor.WritePacketID(ms, ID);

			w.WriteByte((PokemonTrainer = other.PokemonTrainer).Id);
			w.WriteEnum(OldPosition = other.OldPosition);

			Data = new ReadOnlyCollection<byte>(ms.ToArray());
		}
	}
	internal PBEPkmnFaintedPacket_Hidden(byte[] data, EndianBinaryReader r, PBEBattle battle)
	{
		Data = new ReadOnlyCollection<byte>(data);

		PokemonTrainer = battle.Trainers[r.ReadByte()];
		OldPosition = r.ReadEnum<PBEFieldPosition>();
	}
}
