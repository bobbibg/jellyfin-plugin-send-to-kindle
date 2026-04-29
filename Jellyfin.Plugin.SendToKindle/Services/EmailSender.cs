using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Jellyfin.Plugin.SendToKindle.Configuration;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using MimeKit;

namespace Jellyfin.Plugin.SendToKindle.Services;

/// <summary>
/// Sends a book attachment to a Kindle email address via the configured SMTP server.
/// </summary>
public class EmailSender
{
    private readonly ILogger<EmailSender> _logger;

    /// <summary>
    /// Formats Amazon Send-to-Kindle accepts as of 2025. Anything else gets rejected.
    /// EPUB is auto-converted to Amazon's format on their end.
    /// </summary>
    private static readonly HashSet<string> SupportedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".epub", ".pdf", ".mobi", ".azw", ".azw3",
        ".doc", ".docx", ".txt", ".rtf", ".html", ".htm"
    };

    public EmailSender(ILogger<EmailSender> logger)
    {
        _logger = logger;
    }

    public async Task SendBookAsync(string toAddress, string filePath, string bookTitle, CancellationToken cancellationToken)
    {
        var config = Plugin.Instance?.Configuration
            ?? throw new InvalidOperationException("Plugin not initialised");

        if (string.IsNullOrWhiteSpace(config.SmtpHost))
        {
            throw new InvalidOperationException("SMTP host is not configured. Ask your admin to set it in the Send to Kindle plugin config.");
        }

        if (string.IsNullOrWhiteSpace(config.FromAddress))
        {
            throw new InvalidOperationException("From address is not configured. Ask your admin to set it in the Send to Kindle plugin config.");
        }

        if (string.IsNullOrWhiteSpace(toAddress))
        {
            throw new InvalidOperationException("No Kindle email address set for this user.");
        }

        if (!File.Exists(filePath))
        {
            throw new FileNotFoundException("Book file not found on disk.", filePath);
        }

        var ext = Path.GetExtension(filePath);
        if (!SupportedExtensions.Contains(ext))
        {
            throw new InvalidOperationException(
                $"File format '{ext}' is not accepted by Amazon Send-to-Kindle. " +
                $"Supported: {string.Join(", ", SupportedExtensions)}.");
        }

        var fileInfo = new FileInfo(filePath);
        var maxBytes = (long)Math.Max(1, config.MaxAttachmentMegabytes) * 1024L * 1024L;
        if (fileInfo.Length > maxBytes)
        {
            throw new InvalidOperationException(
                $"File is {fileInfo.Length / (1024 * 1024)} MB, which exceeds the {config.MaxAttachmentMegabytes} MB limit.");
        }

        var message = new MimeMessage();
        message.From.Add(MailboxAddress.Parse(config.FromAddress));
        message.To.Add(MailboxAddress.Parse(toAddress));
        message.Subject = string.IsNullOrWhiteSpace(bookTitle) ? "Send to Kindle" : bookTitle;

        var builder = new BodyBuilder
        {
            TextBody = $"Sent from Jellyfin: {bookTitle}"
        };

        // Use the original filename so Amazon's converter keeps the title sensible.
        var attachmentName = Path.GetFileName(filePath);
        await using (var stream = File.OpenRead(filePath))
        {
            builder.Attachments.Add(attachmentName, ReadAllBytes(stream));
        }

        message.Body = builder.ToMessageBody();

        using var client = new SmtpClient();
        var secureOption = config.UseStartTls
            ? SecureSocketOptions.StartTls
            : (config.SmtpPort == 465 ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.Auto);

        await client.ConnectAsync(config.SmtpHost, config.SmtpPort, secureOption, cancellationToken).ConfigureAwait(false);

        if (!string.IsNullOrEmpty(config.SmtpUsername))
        {
            await client.AuthenticateAsync(config.SmtpUsername, config.SmtpPassword, cancellationToken).ConfigureAwait(false);
        }

        await client.SendAsync(message, cancellationToken).ConfigureAwait(false);
        await client.DisconnectAsync(true, cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Sent '{Title}' ({Size} bytes) to {Address}", bookTitle, fileInfo.Length, toAddress);
    }

    private static byte[] ReadAllBytes(Stream stream)
    {
        using var ms = new MemoryStream();
        stream.CopyTo(ms);
        return ms.ToArray();
    }
}
