using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using MediaBrowser.Common.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Jellyfin.Plugin.SendToKindle.Services;

/// <summary>
/// Patches Jellyfin's web index.html on startup to load our button script.
/// Uses the same approach as IntroSkipper / Skip Intro — there's no first-class plugin
/// API for injecting UI into the player/detail pages, so we modify the served HTML.
///
/// The patch is idempotent: if our script tag is already present we leave the file alone.
/// </summary>
public class ScriptInjector : IHostedService
{
    private const string Marker = "<!-- SendToKindle-Injected -->";
    private const string ScriptTag = Marker + "\n<script src=\"/SendToKindle/Script\" defer></script>\n";

    private readonly IApplicationPaths _appPaths;
    private readonly ILogger<ScriptInjector> _logger;

    public ScriptInjector(IApplicationPaths appPaths, ILogger<ScriptInjector> logger)
    {
        _appPaths = appPaths;
        _logger = logger;
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        try
        {
            var indexPath = Path.Combine(_appPaths.WebPath, "index.html");
            if (!File.Exists(indexPath))
            {
                _logger.LogWarning("index.html not found at {Path}; cannot inject Send-to-Kindle script", indexPath);
                return Task.CompletedTask;
            }

            var html = File.ReadAllText(indexPath);
            if (html.Contains(Marker, StringComparison.Ordinal))
            {
                _logger.LogInformation("Send-to-Kindle script already injected.");
                return Task.CompletedTask;
            }

            var bodyClose = html.LastIndexOf("</body>", StringComparison.OrdinalIgnoreCase);
            if (bodyClose < 0)
            {
                _logger.LogWarning("Could not find </body> in index.html; skipping script injection.");
                return Task.CompletedTask;
            }

            var patched = html.Insert(bodyClose, ScriptTag);
            File.WriteAllText(indexPath, patched);
            _logger.LogInformation("Injected Send-to-Kindle script into {Path}", indexPath);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to inject Send-to-Kindle script");
        }

        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
