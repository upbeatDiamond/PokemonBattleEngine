﻿using Kermalis.PokemonBattleEngine.Battle;
using Kermalis.PokemonBattleEngine.Data;
using Xunit;
using Xunit.Abstractions;

namespace Kermalis.PokemonBattleEngineTests.Abilities;

[Collection("Utils")]
public class NaturalCureTests
{
	public NaturalCureTests(TestUtils _, ITestOutputHelper output)
	{
		TestUtils.SetOutputHelper(output);
	}

	[Fact]
	public void NaturalCure_Works_On_Battle_Ending()
	{
		#region Setup
		PBEDataProvider.GlobalRandom.Seed = 0;
		PBESettings settings = PBESettings.DefaultSettings;

		var p0 = new TestPokemonCollection(1);
		p0[0] = new TestPokemon(settings, PBESpecies.Happiny, 0, 1, PBEMove.Splash);

		var p1 = new TestPokemonCollection(1);
		p1[0] = new TestPokemon(settings, PBESpecies.Shaymin, PBEForm.Shaymin, 100, PBEMove.Splash, PBEMove.QuickAttack)
		{
			Ability = PBEAbility.NaturalCure,
			Item = PBEItem.FlameOrb
		};

		var battle = PBEBattle.CreateTrainerBattle(PBEBattleFormat.Single, settings, new PBETrainerInfo(p0, "Trainer 0", false), new PBETrainerInfo(p1, "Trainer 1", false));
		battle.OnNewEvent += PBEBattle.ConsoleBattleEventHandler;

		PBETrainer t0 = battle.Trainers[0];
		PBETrainer t1 = battle.Trainers[1];
		PBEBattlePokemon happiny = t0.Party[0];
		PBEBattlePokemon shaymin = t1.Party[0];

		battle.Begin();
		#endregion

		#region Burn Shaymin
		Assert.True(t0.SelectActionsIfValid(out _, new PBETurnAction(happiny, PBEMove.Splash, PBETurnTarget.AllyCenter)));
		Assert.True(t1.SelectActionsIfValid(out _, new PBETurnAction(shaymin, PBEMove.Splash, PBETurnTarget.AllyCenter)));

		battle.RunTurn();

		Assert.True(shaymin.Status1 == PBEStatus1.Burned);
		#endregion

		#region End battle and check
		Assert.True(t0.SelectActionsIfValid(out _, new PBETurnAction(happiny, PBEMove.Splash, PBETurnTarget.AllyCenter)));
		Assert.True(t1.SelectActionsIfValid(out _, new PBETurnAction(shaymin, PBEMove.QuickAttack, PBETurnTarget.FoeCenter)));

		battle.RunTurn();

		Assert.True(battle.BattleResult == PBEBattleResult.Team1Win
			&& battle.BattleState == PBEBattleState.Ended
			&& shaymin.Status1 == PBEStatus1.None);
		#endregion

		#region Cleanup
		battle.OnNewEvent -= PBEBattle.ConsoleBattleEventHandler;
		#endregion
	}
}
