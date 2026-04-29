using System;
using System.IO;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Jellyfin.Plugin.SendToKindle.Services;
using MediaBrowser.Controller.Library;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Jellyfin.Plugin.SendToKindle.Api;

/// <summary>
/// API endpoints for the Send to Kindle plugin.
/// Each action declares its own [Authorize] / [AllowAnonymous] explicitly. Earlier versions
/// applied [Authorize(Policy = "DefaultAuthorization")] at the class level, but that policy
/// name is not reliably registered for plugin controllers in Jellyfin 10.11+, causing every
/// request to throw "AuthorizationPolicy named 'DefaultAuthorization' was not found".
/// </summary>
[ApiController]
[Route("SendToKindle")]
public class SendToKindleController : ControllerBase
{
    private readonly EmailSender _emailSender;
    private readonly ILibraryManager _libraryManager;
    private readonly ILogger<SendToKindleController> _logger;

    public SendToKindleController(
        EmailSender emailSender,
        ILibraryManager libraryManager,
        ILogger<SendToKindleController> logger)
    {
        _emailSender = emailSender;
        _libraryManager = libraryManager;
        _logger = logger;
    }

    public class UserConfigDto
    {
        public string KindleEmail { get; set; } = string.Empty;
    }

    /// <summary>
    /// Resolves the calling user's Guid from Jellyfin's internal "Jellyfin-UserId" claim.
    /// Mirrors what Jellyfin.Api.Helpers.ClaimHelpers does — re-implemented here so the
    /// plugin doesn't have to reference the non-redistributable Jellyfin.Api assembly.
    /// </summary>
    private Guid GetCurrentUserId()
    {
        var value = User.FindFirst("Jellyfin-UserId")?.Value
                    ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return string.IsNullOrEmpty(value) ? Guid.Empty : Guid.Parse(value);
    }

    /// <summary>
    /// Send a book item to the calling user's configured Kindle address.
    /// </summary>
    [HttpPost("Send/{itemId}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult> Send([FromRoute] Guid itemId, CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var kindleAddress = Plugin.Instance!.Configuration.GetKindleEmail(userId);

        if (string.IsNullOrWhiteSpace(kindleAddress))
        {
            return BadRequest("Set your Kindle email address first (User menu → Send to Kindle).");
        }

        var item = _libraryManager.GetItemById(itemId);
        if (item == null)
        {
            return NotFound("Item not found.");
        }

        if (string.IsNullOrEmpty(item.Path) || !System.IO.File.Exists(item.Path))
        {
            return NotFound("Item has no file on disk.");
        }

        try
        {
            await _emailSender.SendBookAsync(kindleAddress, item.Path, item.Name, cancellationToken).ConfigureAwait(false);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Send to Kindle rejected: {Reason}", ex.Message);
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Send to Kindle failed for item {ItemId}", itemId);
            return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
        }
    }

    /// <summary>
    /// Get the calling user's Kindle email address.
    /// </summary>
    [HttpGet("UserConfig")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public ActionResult<UserConfigDto> GetUserConfig()
    {
        var userId = GetCurrentUserId();
        var email = Plugin.Instance!.Configuration.GetKindleEmail(userId);
        return Ok(new UserConfigDto { KindleEmail = email ?? string.Empty });
    }

    /// <summary>
    /// Set the calling user's Kindle email address.
    /// </summary>
    [HttpPost("UserConfig")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public ActionResult SetUserConfig([FromBody] UserConfigDto dto)
    {
        if (dto == null || string.IsNullOrWhiteSpace(dto.KindleEmail))
        {
            return BadRequest("KindleEmail is required.");
        }

        var trimmed = dto.KindleEmail.Trim();
        if (!trimmed.EndsWith("@kindle.com", StringComparison.OrdinalIgnoreCase)
            && !trimmed.EndsWith("@free.kindle.com", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest("Address must end in @kindle.com or @free.kindle.com.");
        }

        var userId = GetCurrentUserId();
        var plugin = Plugin.Instance!;
        plugin.Configuration.SetKindleEmail(userId, trimmed);
        plugin.SaveConfiguration();
        return NoContent();
    }

    /// <summary>
    /// Send a tiny test message to the calling admin's Kindle address. Admin-only.
    /// </summary>
    [HttpPost("Test")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult> SendTest(CancellationToken cancellationToken)
    {
        // Admin-only: replaces the previous [Authorize(Policy = "RequiresElevation")]
        // because that policy isn't reliably registered for plugins in JF 10.11+.
        var isAdmin = string.Equals(
            User.FindFirst("Jellyfin-IsAdministrator")?.Value,
            "true",
            StringComparison.OrdinalIgnoreCase);
        if (!isAdmin)
        {
            return Forbid();
        }

        var userId = GetCurrentUserId();
        var kindleAddress = Plugin.Instance!.Configuration.GetKindleEmail(userId);

        if (string.IsNullOrWhiteSpace(kindleAddress))
        {
            return BadRequest("Set your Kindle email first under User menu → Send to Kindle.");
        }

        // Build a tiny in-memory text file Amazon will accept.
        var tempPath = Path.Combine(Path.GetTempPath(), $"send-to-kindle-test-{Guid.NewGuid():N}.txt");
        await System.IO.File.WriteAllTextAsync(
            tempPath,
            "Send-to-Kindle plugin test. If you see this on your Kindle, SMTP is working.",
            cancellationToken).ConfigureAwait(false);

        try
        {
            await _emailSender.SendBookAsync(kindleAddress, tempPath, "Send-to-Kindle test", cancellationToken).ConfigureAwait(false);
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Test send failed");
            return BadRequest(ex.Message);
        }
        finally
        {
            try { System.IO.File.Delete(tempPath); } catch { /* best effort */ }
        }
    }

    /// <summary>
    /// Returns the JS that the script injector points the index.html &lt;script&gt; tag at.
    /// Public so the browser can fetch it without auth — content is the same for everyone.
    /// </summary>
    [HttpGet("Script")]
    [AllowAnonymous]
    [Produces("application/javascript")]
    public ActionResult GetScript()
    {
        var assembly = typeof(Plugin).Assembly;
        var resourceName = $"{typeof(Plugin).Namespace}.Web.sendToKindleButton.js";
        var stream = assembly.GetManifestResourceStream(resourceName);
        if (stream == null)
        {
            return NotFound();
        }

        return File(stream, "application/javascript");
    }
}
