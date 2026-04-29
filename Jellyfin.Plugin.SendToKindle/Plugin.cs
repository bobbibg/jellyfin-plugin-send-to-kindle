using System;
using System.Collections.Generic;
using Jellyfin.Plugin.SendToKindle.Configuration;
using MediaBrowser.Common.Configuration;
using MediaBrowser.Common.Plugins;
using MediaBrowser.Model.Plugins;
using MediaBrowser.Model.Serialization;

namespace Jellyfin.Plugin.SendToKindle;

/// <summary>
/// The plugin entry point. Holds configuration and exposes the admin + per-user config pages.
/// </summary>
public class Plugin : BasePlugin<PluginConfiguration>, IHasWebPages
{
    public Plugin(IApplicationPaths applicationPaths, IXmlSerializer xmlSerializer)
        : base(applicationPaths, xmlSerializer)
    {
        Instance = this;
    }

    public static Plugin? Instance { get; private set; }

    public override string Name => "Send to Kindle";

    public override Guid Id => Guid.Parse("b9a4d8c1-3f7e-4a2b-8c5d-1e6f9a0b2c3d");

    public override string Description =>
        "Send books from your Jellyfin library to your Kindle via email. " +
        "Admins configure the SMTP server (e.g. GMX). Each user sets their own @kindle.com address.";

    public IEnumerable<PluginPageInfo> GetPages()
    {
        return new[]
        {
            new PluginPageInfo
            {
                Name = "SendToKindle",
                EmbeddedResourcePath = $"{GetType().Namespace}.Configuration.configPage.html",
                MenuSection = "server",
                DisplayName = "Send to Kindle"
            },
            new PluginPageInfo
            {
                Name = "SendToKindleUser",
                EmbeddedResourcePath = $"{GetType().Namespace}.Configuration.userConfigPage.html",
                MenuSection = "user",
                DisplayName = "Send to Kindle"
            }
        };
    }
}
