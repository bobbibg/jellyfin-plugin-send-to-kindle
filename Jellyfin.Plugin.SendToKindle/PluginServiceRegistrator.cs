using Jellyfin.Plugin.SendToKindle.Services;
using MediaBrowser.Controller;
using MediaBrowser.Controller.Plugins;
using Microsoft.Extensions.DependencyInjection;

namespace Jellyfin.Plugin.SendToKindle;

/// <summary>
/// Registers plugin services into Jellyfin's DI container.
/// </summary>
public class PluginServiceRegistrator : IPluginServiceRegistrator
{
    public void RegisterServices(IServiceCollection serviceCollection, IServerApplicationHost applicationHost)
    {
        serviceCollection.AddSingleton<EmailSender>();
        serviceCollection.AddHostedService<ScriptInjector>();
    }
}
