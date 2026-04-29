using System;
using System.Linq;
using MediaBrowser.Model.Plugins;

namespace Jellyfin.Plugin.SendToKindle.Configuration;

/// <summary>
/// Plugin configuration. SMTP credentials are admin-only. Per-user Kindle addresses
/// live in UserKindleAddresses keyed by Jellyfin user GUID (as a hex string).
/// </summary>
public class PluginConfiguration : BasePluginConfiguration
{
    public PluginConfiguration()
    {
        SmtpHost = "mail.gmx.com";
        SmtpPort = 587;
        SmtpUsername = string.Empty;
        SmtpPassword = string.Empty;
        FromAddress = string.Empty;
        UseStartTls = true;
        MaxAttachmentMegabytes = 50;
        UserKindleAddresses = Array.Empty<UserKindleEntry>();
    }

    public string SmtpHost { get; set; }

    public int SmtpPort { get; set; }

    public string SmtpUsername { get; set; }

    public string SmtpPassword { get; set; }

    /// <summary>
    /// The "From" email address. MUST be in your Amazon approved-senders list,
    /// otherwise Amazon will silently drop the message.
    /// </summary>
    public string FromAddress { get; set; }

    public bool UseStartTls { get; set; }

    public int MaxAttachmentMegabytes { get; set; }

    /// <summary>
    /// Per-user Kindle addresses. Stored as an array (not a Dictionary) because
    /// Jellyfin's default XmlSerializer cannot round-trip generic dictionaries.
    /// </summary>
    public UserKindleEntry[] UserKindleAddresses { get; set; }

    /// <summary>
    /// Look up a user's address by GUID. Returns null if unset.
    /// </summary>
    public string? GetKindleEmail(Guid userId)
    {
        var key = userId.ToString("N");
        return UserKindleAddresses?
            .FirstOrDefault(e => string.Equals(e.UserId, key, StringComparison.OrdinalIgnoreCase))
            ?.KindleEmail;
    }

    /// <summary>
    /// Set a user's address (idempotent — replaces any existing entry).
    /// </summary>
    public void SetKindleEmail(Guid userId, string kindleEmail)
    {
        var key = userId.ToString("N");
        var keep = (UserKindleAddresses ?? Array.Empty<UserKindleEntry>())
            .Where(e => !string.Equals(e.UserId, key, StringComparison.OrdinalIgnoreCase))
            .ToList();
        keep.Add(new UserKindleEntry { UserId = key, KindleEmail = kindleEmail });
        UserKindleAddresses = keep.ToArray();
    }
}

/// <summary>
/// One row in the per-user Kindle address map.
/// </summary>
public class UserKindleEntry
{
    public string UserId { get; set; } = string.Empty;
    public string KindleEmail { get; set; } = string.Empty;
}
