﻿using Kermalis.PokemonBattleEngine.Battle;
using Kermalis.PokemonBattleEngine.Data;
using System.Linq;
using Xunit;
using Xunit.Abstractions;

namespace Kermalis.PokemonBattleEngineTests;

[Collection("Utils")]
public class BehaviorTests
{
	public BehaviorTests(TestUtils _, ITestOutputHelper output)
	{
		TestUtils.SetOutputHelper(output);
	}

	[Fact]
	public void Wild_Pkmn_Positions_Set_Before_Begin()
	{
		#region Setup
		PBEDataProvider.GlobalRandom.Seed = 0;
		PBESettings settings = PBESettings.DefaultSettings;

		var p0 = new TestPokemonCollection(1);
		p0[0] = new TestPokemon(settings, PBESpecies.Magikarp, 0, 100, PBEMove.Splash);

		var p1 = new TestPokemonCollection(1);
		p1[0] = new TestPokemon(settings, PBESpecies.Darkrai, 0, 100, PBEMove.Splash)
		{
			CaughtBall = PBEItem.None
		};

		var battle = PBEBattle.CreateWildBattle(PBEBattleFormat.Single, settings, new PBETrainerInfo(p0, "Trainer 0", false), new PBEWildInfo(p1));

		PBETrainer t1 = battle.Trainers[1];
		PBEBattlePokemon darkrai = t1.Party[0];
		#endregion

		#region Check
		Assert.True(darkrai.FieldPosition == PBEFieldPosition.Center
			&& battle.ActiveBattlers.Single() == darkrai);
		#endregion
	}

	[Fact]
	public void Fainted_Pkmn_Not_Sent_Out_Single()
	{
		#region Setup
		PBEDataProvider.GlobalRandom.Seed = 0;
		PBESettings settings = PBESettings.DefaultSettings;

		var p0 = new TestPartyPokemonCollection(2);
		p0[0] = new TestPartyPokemon(settings, PBESpecies.Magikarp, 0, 100, PBEMove.Splash)
		{
			HP = 0
		};
		p0[1] = new TestPartyPokemon(settings, PBESpecies.Absol, 0, 100, PBEMove.Splash);

		var p1 = new TestPokemonCollection(1);
		p1[0] = new TestPokemon(settings, PBESpecies.Darkrai, 0, 100, PBEMove.Splash);

		var battle = PBEBattle.CreateTrainerBattle(PBEBattleFormat.Single, settings, new PBETrainerInfo(p0, "Trainer 0", false), new PBETrainerInfo(p1, "Trainer 1", false));

		PBETrainer t0 = battle.Trainers[0];
		PBEBattlePokemon magikarp = t0.Party[0];
		PBEBattlePokemon absol = t0.Party[1];

		battle.Begin();
		#endregion

		#region Check
		Assert.True(magikarp.FieldPosition == PBEFieldPosition.None
			&& absol.FieldPosition == PBEFieldPosition.Center);
		#endregion
	}

	[Fact]
	public void Fainted_Pkmn_Not_Sent_Out_Double()
	{
		#region Setup
		PBEDataProvider.GlobalRandom.Seed = 0;
		PBESettings settings = PBESettings.DefaultSettings;

		var p0 = new TestPartyPokemonCollection(3);
		p0[0] = new TestPartyPokemon(settings, PBESpecies.Magikarp, 0, 100, PBEMove.Splash);
		p0[1] = new TestPartyPokemon(settings, PBESpecies.Absol, 0, 100, PBEMove.Splash)
		{
			HP = 0
		};
		p0[2] = new TestPartyPokemon(settings, PBESpecies.Feebas, 0, 100, PBEMove.Splash);

		var p1 = new TestPokemonCollection(1);
		p1[0] = new TestPokemon(settings, PBESpecies.Darkrai, 0, 100, PBEMove.Splash);

		var battle = PBEBattle.CreateTrainerBattle(PBEBattleFormat.Double, settings, new PBETrainerInfo(p0, "Trainer 0", false), new PBETrainerInfo(p1, "Trainer 1", false));

		PBETrainer t0 = battle.Trainers[0];
		PBEBattlePokemon magikarp = t0.Party[0];
		PBEBattlePokemon absol = t0.Party[1];
		PBEBattlePokemon feebas = t0.Party[2];

		battle.Begin();
		#endregion

		#region Check
		Assert.True(magikarp.FieldPosition == PBEFieldPosition.Left
			&& absol.FieldPosition == PBEFieldPosition.None
			&& feebas.FieldPosition == PBEFieldPosition.Right);
		#endregion
	}

	[Fact]
	public void Fainted_Pkmn_Not_Sent_Out_Triple()
	{
		#region Setup
		PBEDataProvider.GlobalRandom.Seed = 0;
		PBESettings settings = PBESettings.DefaultSettings;

		var p0 = new TestPartyPokemonCollection(5);
		p0[0] = new TestPartyPokemon(settings, PBESpecies.Magikarp, 0, 100, PBEMove.Splash)
		{
			HP = 0
		};
		p0[1] = new TestPartyPokemon(settings, PBESpecies.Absol, 0, 100, PBEMove.Splash)
		{
			HP = 0
		};
		p0[2] = new TestPartyPokemon(settings, PBESpecies.Feebas, 0, 100, PBEMove.Splash)
		{
			HP = 0
		};
		p0[3] = new TestPartyPokemon(settings, PBESpecies.Happiny, 0, 100, PBEMove.Splash);
		p0[4] = new TestPartyPokemon(settings, PBESpecies.Gastly, 0, 100, PBEMove.Splash);

		var p1 = new TestPokemonCollection(1);
		p1[0] = new TestPokemon(settings, PBESpecies.Darkrai, 0, 100, PBEMove.Splash);

		var battle = PBEBattle.CreateTrainerBattle(PBEBattleFormat.Triple, settings, new PBETrainerInfo(p0, "Trainer 0", false), new PBETrainerInfo(p1, "Trainer 1", false));

		PBETrainer t0 = battle.Trainers[0];
		PBEBattlePokemon magikarp = t0.Party[0];
		PBEBattlePokemon absol = t0.Party[1];
		PBEBattlePokemon feebas = t0.Party[2];
		PBEBattlePokemon happiny = t0.Party[3];
		PBEBattlePokemon gastly = t0.Party[4];

		battle.Begin();
		#endregion

		#region Check
		Assert.True(magikarp.FieldPosition == PBEFieldPosition.None
			&& absol.FieldPosition == PBEFieldPosition.None
			&& feebas.FieldPosition == PBEFieldPosition.None
			&& happiny.FieldPosition == PBEFieldPosition.Left
			&& gastly.FieldPosition == PBEFieldPosition.Center);
		#endregion
	}

	[Fact]
	public void Lose_If_Remaining_Ignored()
	{
		#region Setup
		PBEDataProvider.GlobalRandom.Seed = 0;
		PBESettings settings = PBESettings.DefaultSettings;

		var p0 = new TestPokemonCollection(2);
		p0[0] = new TestPokemon(settings, PBESpecies.Koffing, 0, 100, PBEMove.Selfdestruct);
		p0[1] = new TestPokemon(settings, PBESpecies.Magikarp, 0, 1, PBEMove.Splash)
		{
			PBEIgnore = true
		};

		var p1 = new TestPokemonCollection(1);
		p1[0] = new TestPokemon(settings, PBESpecies.Darkrai, 0, 100, PBEMove.Protect);

		var battle = PBEBattle.CreateTrainerBattle(PBEBattleFormat.Single, settings, new PBETrainerInfo(p0, "Trainer 0", false), new PBETrainerInfo(p1, "Trainer 1", false));
		battle.OnNewEvent += PBEBattle.ConsoleBattleEventHandler;

		PBETrainer t0 = battle.Trainers[0];
		PBETrainer t1 = battle.Trainers[1];
		PBEBattlePokemon koffing = t0.Party[0];
		PBEBattlePokemon magikarp = t0.Party[1];
		PBEBattlePokemon darkrai = t1.Party[0];

		battle.Begin();
		#endregion

		#region Darkrai uses Protect, Koffing uses Selfdestruct and faints
		Assert.True(t0.SelectActionsIfValid(out _, new PBETurnAction(koffing, PBEMove.Selfdestruct, PBETurnTarget.FoeCenter)));
		Assert.True(t1.SelectActionsIfValid(out _, new PBETurnAction(darkrai, PBEMove.Protect, PBETurnTarget.AllyCenter)));

		battle.RunTurn();
		#endregion

		#region Check
		Assert.True(koffing.HP == 0 && magikarp.HP > 0
			&& battle.BattleResult == PBEBattleResult.Team1Win); // Koffing's team loses
		#endregion

		#region Cleanup
		battle.OnNewEvent -= PBEBattle.ConsoleBattleEventHandler;
		#endregion
	}
}
