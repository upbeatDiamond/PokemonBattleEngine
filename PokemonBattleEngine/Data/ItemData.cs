﻿using System.Collections.Generic;

namespace Kermalis.PokemonBattleEngine.Data
{
    public sealed class PItemData
    {
        public byte FlingPower;

        public static Dictionary<PItem, PItemData> Data = new Dictionary<PItem, PItemData>()
        {
            { PItem.BlackBelt, new PItemData { FlingPower = 30 } },
            { PItem.BlackGlasses, new PItemData { FlingPower = 30 } },
            { PItem.BlackSludge, new PItemData { FlingPower = 30 } },
            { PItem.BrightPowder, new PItemData { FlingPower = 10 } },
            { PItem.BurnDrive, new PItemData { FlingPower = 70 } },
            { PItem.Charcoal, new PItemData { FlingPower = 30 } },
            { PItem.ChillDrive, new PItemData { FlingPower = 70 } },
            { PItem.ChoiceBand, new PItemData { FlingPower = 10 } },
            { PItem.ChoiceScarf, new PItemData { FlingPower = 10 } },
            { PItem.ChoiceSpecs, new PItemData { FlingPower = 10 } },
            { PItem.DampRock, new PItemData { FlingPower = 60 } },
            { PItem.DeepSeaScale, new PItemData { FlingPower = 30 } },
            { PItem.DeepSeaTooth, new PItemData { FlingPower = 90 } },
            { PItem.DouseDrive, new PItemData { FlingPower = 70 } },
            { PItem.DracoPlate, new PItemData { FlingPower = 90 } },
            { PItem.DragonFang, new PItemData { FlingPower = 70 } },
            { PItem.DreadPlate, new PItemData { FlingPower = 90 } },
            { PItem.EarthPlate, new PItemData { FlingPower = 90 } },
            { PItem.FistPlate, new PItemData { FlingPower = 90 } },
            { PItem.FlamePlate, new PItemData { FlingPower = 90 } },
            { PItem.GriseousOrb, new PItemData { FlingPower = 60 } },
            { PItem.HardStone, new PItemData { FlingPower = 100 } },
            { PItem.HeatRock, new PItemData { FlingPower = 60 } },
            { PItem.IciclePlate, new PItemData { FlingPower = 90 } },
            { PItem.InsectPlate, new PItemData { FlingPower = 90 } },
            { PItem.IronPlate, new PItemData { FlingPower = 90 } },
            { PItem.LaxIncense, new PItemData { FlingPower = 10 } },
            { PItem.Leftovers, new PItemData { FlingPower = 10 } },
            { PItem.LifeOrb, new PItemData { FlingPower = 30 } },
            { PItem.LightBall, new PItemData { FlingPower = 30 } },
            { PItem.LightClay, new PItemData { FlingPower = 30 } },
            { PItem.Magnet, new PItemData { FlingPower = 30 } },
            { PItem.MeadowPlate, new PItemData { FlingPower = 90 } },
            { PItem.MetalPowder, new PItemData { FlingPower = 10 } },
            { PItem.MindPlate, new PItemData { FlingPower = 90 } },
            { PItem.MiracleSeed, new PItemData { FlingPower = 30 } },
            { PItem.MysticWater, new PItemData { FlingPower = 30 } },
            { PItem.NeverMeltIce, new PItemData { FlingPower = 30 } },
            { PItem.PoisonBarb, new PItemData { FlingPower = 70 } },
            { PItem.PowerHerb, new PItemData { FlingPower = 10 } },
            { PItem.RazorClaw, new PItemData { FlingPower = 80 } },
            { PItem.ScopeLens, new PItemData { FlingPower = 30 } },
            { PItem.SharpBeak, new PItemData { FlingPower = 50 } },
            { PItem.ShockDrive, new PItemData { FlingPower = 70 } },
            { PItem.SilkScarf, new PItemData { FlingPower = 10 } },
            { PItem.SkyPlate, new PItemData { FlingPower = 90 } },
            { PItem.SoulDew, new PItemData { FlingPower = 30 } },
            { PItem.SpellTag, new PItemData { FlingPower = 30 } },
            { PItem.SplashPlate, new PItemData { FlingPower = 90 } },
            { PItem.SpookyPlate, new PItemData { FlingPower = 90 } },
            { PItem.StonePlate, new PItemData { FlingPower = 90 } },
            { PItem.ThickClub, new PItemData { FlingPower = 90 } },
            { PItem.ToxicPlate, new PItemData { FlingPower = 90 } },
            { PItem.TwistedSpoon, new PItemData { FlingPower = 30 } },
            { PItem.WideLens, new PItemData { FlingPower = 10 } },
            { PItem.ZapPlate, new PItemData { FlingPower = 90 } },
        };
    }
}
