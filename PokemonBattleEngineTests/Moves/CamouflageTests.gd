﻿using Kermalis.PokemonBattleEngine.Battle;
using Kermalis.PokemonBattleEngine.Data;
using Xunit;
using Xunit.Abstractions;

namespace Kermalis.PokemonBattleEngineTests.Moves;

[Collection("Utils")]
public class CamouflageTests
{
	public CamouflageTests(TestUtils _, ITestOutputHelper output)
	{
		TestUtils.SetOutputHelper(output);
	}

	[Theory]
	[InlineData(PBEBattleTerrain.Cave, PBEType.Rock, PBESpecies.Kecleon)]
	[InlineData(PBEBattleTerrain.Cave, PBEType.Rock, PBESpecies.Starmie)]
	[InlineData(PBEBattleTerrain.Grass, PBEType.Grass, PBESpecies.Kecleon)]
	[InlineData(PBEBattleTerrain.Grass, PBEType.Grass, PBESpecies.Starmie)]
	[InlineData(PBEBattleTerrain.Plain, PBEType.Normal, PBESpecies.Kecleon)]
	[InlineData(PBEBattleTerrain.Plain, PBEType.Normal, PBESpecies.Starmie)]
	[InlineData(PBEBattleTerrain.Puddle, PBEType.Ground, PBESpecies.Kecleon)]
	[InlineData(PBEBattleTerrain.Puddle, PBEType.Ground, PBESpecies.Starmie)]
	[InlineData(PBEBattleTerrain.Sand, PBEType.Ground, PBESpecies.Kecleon)]
	[InlineData(PBEBattleTerrain.Sand, PBEType.Ground, PBESpecies.Starmie)]
	[InlineData(PBEBattleTerrain.Snow, PBEType.Ice, PBESpecies.Kecleon)]
	[InlineData(PBEBattleTerrain.Snow, PBEType.Ice, PBESpecies.Starmie)]
	[InlineData(PBEBattleTerrain.Water, PBEType.Water, PBESpecies.Kecleon)]
	[InlineData(PBEBattleTerrain.Water, PBEType.Water, PBESpecies.Starmie)]
	public void Camouflage_Works(PBEBattleTerrain battleTerrain, PBEType expectedType, PBESpecies species)
	{
		#region Setup
		PBEDataProvider.GlobalRandom.Seed = 0;
		PBESettings settings = PBESettings.DefaultSettings;

		var p0 = new TestPokemonCollection(1);
		p0[0] = new TestPokemon(settings, species, 0, 100, PBEMove.Camouflage);

		var p1 = new TestPokemonCollection(1);
		p1[0] = new TestPokemon(settings, PBESpecies.Magikarp, 0, 100, PBEMove.Splash);

		var battle = PBEBattle.CreateTrainerBattle(PBEBattleFormat.Single, settings, new PBETrainerInfo(p0, "Trainer 0", false), new PBETrainerInfo(p1, "Trainer 1", false),
				battleTerrain: battleTerrain);
		battle.OnNewEvent += PBEBattle.ConsoleBattleEventHandler;

		PBETrainer t0 = battle.Trainers[0];
		PBETrainer t1 = battle.Trainers[1];
		PBEBattlePokemon camouflager = t0.Party[0];
		PBEBattlePokemon magikarp = t1.Party[0];

		battle.Begin();
		#endregion

		#region Use Camouflage and check
		Assert.True(t0.SelectActionsIfValid(out _, new PBETurnAction(camouflager, PBEMove.Camouflage, PBETurnTarget.AllyCenter)));
		Assert.True(t1.SelectActionsIfValid(out _, new PBETurnAction(magikarp, PBEMove.Splash, PBETurnTarget.AllyCenter)));

		battle.RunTurn();

		Assert.True(camouflager.Type1 == expectedType && camouflager.Type2 == PBEType.None);
		#endregion

		#region Cleanup
		battle.OnNewEvent -= PBEBattle.ConsoleBattleEventHandler;
		#endregion
	}

	[Fact]
	public void Camouflage_Fails()
	{
		#region Setup
		PBEDataProvider.GlobalRandom.Seed = 0;
		PBESettings settings = PBESettings.DefaultSettings;

		var p0 = new TestPokemonCollection(1);
		p0[0] = new TestPokemon(settings, PBESpecies.Staryu, 0, 100, PBEMove.Camouflage);

		var p1 = new TestPokemonCollection(1);
		p1[0] = new TestPokemon(settings, PBESpecies.Magikarp, 0, 100, PBEMove.Splash);

		var battle = PBEBattle.CreateTrainerBattle(PBEBattleFormat.Single, settings, new PBETrainerInfo(p0, "Trainer 0", false), new PBETrainerInfo(p1, "Trainer 1", false),
				battleTerrain: PBEBattleTerrain.Water);
		battle.OnNewEvent += PBEBattle.ConsoleBattleEventHandler;

		PBETrainer t0 = battle.Trainers[0];
		PBETrainer t1 = battle.Trainers[1];
		PBEBattlePokemon staryu = t0.Party[0];
		PBEBattlePokemon magikarp = t1.Party[0];

		battle.Begin();
		#endregion

		#region Use Camouflage and check
		Assert.True(t0.SelectActionsIfValid(out _, new PBETurnAction(staryu, PBEMove.Camouflage, PBETurnTarget.AllyCenter)));
		Assert.True(t1.SelectActionsIfValid(out _, new PBETurnAction(magikarp, PBEMove.Splash, PBETurnTarget.AllyCenter)));

		battle.RunTurn();

		Assert.True(battle.VerifyMoveResultHappened(staryu, staryu, PBEResult.InvalidConditions));
		#endregion

		#region Cleanup
		battle.OnNewEvent -= PBEBattle.ConsoleBattleEventHandler;
		#endregion
	}
}
