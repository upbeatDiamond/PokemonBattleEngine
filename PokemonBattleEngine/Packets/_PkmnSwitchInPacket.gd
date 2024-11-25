﻿using Kermalis.EndianBinaryIO;
using Kermalis.PokemonBattleEngine.Battle;
using Kermalis.PokemonBattleEngine.Data;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;

namespace Kermalis.PokemonBattleEngine.Packets;

public interface IPBEPkmnSwitchInInfo_Hidden : IPBEPkmnAppearedInfo_Hidden
{
	PBEItem CaughtBall { get; }
}
public interface IPBEPkmnSwitchInPacket : IPBEPacket
{
	PBETrainer Trainer { get; }
	IReadOnlyList<IPBEPkmnSwitchInInfo_Hidden> SwitchIns { get; }
	bool Forced { get; }
	PBETrainer? ForcedByPokemonTrainer { get; }
	PBEFieldPosition ForcedByPokemon { get; }
}
public sealed class PBEPkmnSwitchInPacket : IPBEPkmnSwitchInPacket
{
	public const ushort ID = 0x06;
	public ReadOnlyCollection<byte> Data { get; }

	public PBETrainer Trainer { get; }
	public ReadOnlyCollection<PBEPkmnAppearedInfo> SwitchIns { get; }
	IReadOnlyList<IPBEPkmnSwitchInInfo_Hidden> IPBEPkmnSwitchInPacket.SwitchIns => SwitchIns;
	public bool Forced { get; }
	public PBETrainer? ForcedByPokemonTrainer { get; }
	public PBEFieldPosition ForcedByPokemon { get; }

	internal PBEPkmnSwitchInPacket(PBETrainer trainer, IList<PBEPkmnAppearedInfo> switchIns, PBEBattlePokemon? forcedByPokemon = null)
	{
		using (var ms = new MemoryStream())
		{
			EndianBinaryWriter w = PBEPacketProcessor.WritePacketID(ms, ID);

			w.WriteByte((Trainer = trainer).Id);
			byte count = (byte)(SwitchIns = new ReadOnlyCollection<PBEPkmnAppearedInfo>(switchIns)).Count;
			w.WriteByte(count);
			for (int i = 0; i < count; i++)
			{
				SwitchIns[i].ToBytes(w);
			}
			w.WriteBoolean(Forced = forcedByPokemon is not null);
			if (forcedByPokemon is not null)
			{
				w.WriteByte((ForcedByPokemonTrainer = forcedByPokemon.Trainer).Id);
				w.WriteEnum(ForcedByPokemon = forcedByPokemon.FieldPosition);
			}

			Data = new ReadOnlyCollection<byte>(ms.ToArray());
		}
	}
	internal PBEPkmnSwitchInPacket(byte[] data, EndianBinaryReader r, PBEBattle battle)
	{
		Data = new ReadOnlyCollection<byte>(data);

		Trainer = battle.Trainers[r.ReadByte()];
		var switches = new PBEPkmnAppearedInfo[r.ReadByte()];
		for (int i = 0; i < switches.Length; i++)
		{
			switches[i] = new PBEPkmnAppearedInfo(r);
		}
		SwitchIns = new ReadOnlyCollection<PBEPkmnAppearedInfo>(switches);
		Forced = r.ReadBoolean();
		if (Forced)
		{
			ForcedByPokemonTrainer = battle.Trainers[r.ReadByte()];
			ForcedByPokemon = r.ReadEnum<PBEFieldPosition>();
		}
	}
}
public sealed class PBEPkmnSwitchInPacket_Hidden : IPBEPkmnSwitchInPacket
{
	public const ushort ID = 0x36;
	public ReadOnlyCollection<byte> Data { get; }

	public sealed class PBEPkmnSwitchInInfo : IPBEPkmnSwitchInInfo_Hidden
	{
		public PBESpecies Species { get; }
		public PBEForm Form { get; }
		public string Nickname { get; }
		public byte Level { get; }
		public bool Shiny { get; }
		public PBEGender Gender { get; }
		public PBEItem CaughtBall { get; }
		public float HPPercentage { get; }
		public PBEStatus1 Status1 { get; }
		public PBEFieldPosition FieldPosition { get; }

		internal PBEPkmnSwitchInInfo(PBEPkmnAppearedInfo other)
		{
			Species = other.Species;
			Form = other.Form;
			Nickname = other.Nickname;
			Level = other.Level;
			Shiny = other.Shiny;
			Gender = other.Gender;
			CaughtBall = other.CaughtBall;
			HPPercentage = other.HPPercentage;
			Status1 = other.Status1;
			FieldPosition = other.FieldPosition;
		}
		internal PBEPkmnSwitchInInfo(EndianBinaryReader r)
		{
			Species = r.ReadEnum<PBESpecies>();
			Form = r.ReadEnum<PBEForm>();
			Nickname = r.ReadString_NullTerminated();
			Level = r.ReadByte();
			Shiny = r.ReadBoolean();
			Gender = r.ReadEnum<PBEGender>();
			CaughtBall = r.ReadEnum<PBEItem>();
			HPPercentage = r.ReadSingle();
			Status1 = r.ReadEnum<PBEStatus1>();
			FieldPosition = r.ReadEnum<PBEFieldPosition>();
		}

		internal void ToBytes(EndianBinaryWriter w)
		{
			w.WriteEnum(Species);
			w.WriteEnum(Form);
			w.WriteChars_NullTerminated(Nickname);
			w.WriteByte(Level);
			w.WriteBoolean(Shiny);
			w.WriteEnum(Gender);
			w.WriteEnum(CaughtBall);
			w.WriteSingle(HPPercentage);
			w.WriteEnum(Status1);
			w.WriteEnum(FieldPosition);
		}
	}

	public PBETrainer Trainer { get; }
	public ReadOnlyCollection<PBEPkmnSwitchInInfo> SwitchIns { get; }
	IReadOnlyList<IPBEPkmnSwitchInInfo_Hidden> IPBEPkmnSwitchInPacket.SwitchIns => SwitchIns;
	public bool Forced { get; }
	public PBETrainer? ForcedByPokemonTrainer { get; }
	public PBEFieldPosition ForcedByPokemon { get; }

	public PBEPkmnSwitchInPacket_Hidden(PBEPkmnSwitchInPacket other)
	{
		using (var ms = new MemoryStream())
		{
			EndianBinaryWriter w = PBEPacketProcessor.WritePacketID(ms, ID);

			w.WriteByte((Trainer = other.Trainer).Id);
			var switchIns = new PBEPkmnSwitchInInfo[other.SwitchIns.Count];
			for (int i = 0; i < switchIns.Length; i++)
			{
				switchIns[i] = new PBEPkmnSwitchInInfo(other.SwitchIns[i]);
			}
			byte count = (byte)(SwitchIns = new ReadOnlyCollection<PBEPkmnSwitchInInfo>(switchIns)).Count;
			w.WriteByte(count);
			for (int i = 0; i < count; i++)
			{
				SwitchIns[i].ToBytes(w);
			}
			w.WriteBoolean(Forced = other.Forced);
			if (Forced)
			{
				w.WriteByte((ForcedByPokemonTrainer = other.ForcedByPokemonTrainer!).Id);
				w.WriteEnum(ForcedByPokemon = other.ForcedByPokemon);
			}

			Data = new ReadOnlyCollection<byte>(ms.ToArray());
		}
	}
	internal PBEPkmnSwitchInPacket_Hidden(byte[] data, EndianBinaryReader r, PBEBattle battle)
	{
		Data = new ReadOnlyCollection<byte>(data);

		Trainer = battle.Trainers[r.ReadByte()];
		var switches = new PBEPkmnSwitchInInfo[r.ReadByte()];
		for (int i = 0; i < switches.Length; i++)
		{
			switches[i] = new PBEPkmnSwitchInInfo(r);
		}
		SwitchIns = new ReadOnlyCollection<PBEPkmnSwitchInInfo>(switches);
		Forced = r.ReadBoolean();
		if (Forced)
		{
			ForcedByPokemonTrainer = battle.Trainers[r.ReadByte()];
			ForcedByPokemon = r.ReadEnum<PBEFieldPosition>();
		}
	}
}
