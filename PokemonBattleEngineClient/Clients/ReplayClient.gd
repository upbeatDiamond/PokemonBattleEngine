﻿using Kermalis.PokemonBattleEngine.Battle;
using Kermalis.PokemonBattleEngine.Packets;
using Kermalis.PokemonBattleEngineClient.Views;

namespace Kermalis.PokemonBattleEngineClient.Clients;

internal sealed class ReplayClient : NonLocalClient
{
	public override PBEBattle Battle { get; }
	public override PBETrainer? Trainer => null;
	public override BattleView BattleView { get; }
	public override bool HideNonOwned => false;

	public ReplayClient(string path, string name)
	: base(name)
	{
		Battle = PBEBattle.LoadReplay(path, new PBEPacketProcessor());
		BattleView = new BattleView(this);
		ShowAllPokemon();
		StartPacketThread();
	}

	protected override bool ProcessPacket(IPBEPacket packet)
	{
		switch (packet)
		{
			case PBEMovePPChangedPacket mpcp:
			{
				PBEBattlePokemon moveUser = mpcp.MoveUserTrainer.GetPokemon(mpcp.MoveUser);
				moveUser.Moves[mpcp.Move]!.PP -= mpcp.AmountReduced;
				break;
			}
			case PBEActionsRequestPacket _:
			case PBESwitchInRequestPacket _: return true;
		}
		return base.ProcessPacket(packet);
	}
}
