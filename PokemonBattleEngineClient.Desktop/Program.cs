using Avalonia;
using Avalonia.Logging.Serilog;
using Avalonia.ReactiveUI;
using Kermalis.PokemonBattleEngineClient.Infrastructure;
using System;

namespace Kermalis.PokemonBattleEngineClient.Desktop
{
    internal class Program
    {
        [STAThread]
        private static void Main()
        {
            Utils.ForwardCreateDatabaseConnection(string.Empty);
            BuildAvaloniaApp().Start<MainWindow>();
        }
        /// <summary>
        /// This method is needed for IDE previewer infrastructure
        /// </summary>
        public static AppBuilder BuildAvaloniaApp()
        {
            return AppBuilder.Configure<App>()
                           .UsePlatformDetect()
                           .UseReactiveUI()
                           .LogToDebug();
        }
    }
}
