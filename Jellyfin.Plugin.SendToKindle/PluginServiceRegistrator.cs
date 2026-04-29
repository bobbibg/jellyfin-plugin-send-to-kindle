using Jellyfin.Plugin.SendToKindle.Services;
using MediaBrowser.Common.Plugins;
using MediaBrowser.Controller;
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
