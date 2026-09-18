using System.Security.Cryptography;
using System.Text;

namespace MyDiary.Data.Extensions;

/// <summary>
/// AES-256-GCM connection string decryption (migrated from Project B).
/// SECURITY NOTE: The AES key must NOT be hardcoded in production.
///   → Store in Azure Key Vault / AWS Secrets Manager / environment variable.
///   → This implementation reads from the "ConnectionStringEncryptionKey"
///     environment variable, with a development fallback.
/// Output format: Base64(12-byte-nonce + 16-byte-tag + ciphertext)
/// </summary>
public static class ConnectionStringDecryptor
{
    private const int NonceSizeBytes = 12;
    private const int TagSizeBytes   = 16;

    private static byte[] GetKey()
    {
        // PROD: read from environment / secrets manager
        var key = Environment.GetEnvironmentVariable("MD_CONN_ENCRYPTION_KEY")
                  ?? "01234567890123456789012345678901"; // dev fallback only
        return Encoding.UTF8.GetBytes(key.PadRight(32)[..32]);
    }

    public static string Decrypt(string cipherBase64)
    {
        if (string.IsNullOrWhiteSpace(cipherBase64))
            throw new ArgumentNullException(nameof(cipherBase64));

        byte[] raw         = Convert.FromBase64String(Normalize(cipherBase64));
        byte[] nonce       = raw[..NonceSizeBytes];
        byte[] tag         = raw[NonceSizeBytes..(NonceSizeBytes + TagSizeBytes)];
        byte[] cipherBytes = raw[(NonceSizeBytes + TagSizeBytes)..];
        byte[] plainBytes  = new byte[cipherBytes.Length];

        using var aesGcm = new AesGcm(GetKey(), TagSizeBytes);
        aesGcm.Decrypt(nonce, cipherBytes, tag, plainBytes);

        return Encoding.UTF8.GetString(plainBytes);
    }

    /// <summary>
    /// Decrypts all ConnectionStrings from configuration.
    /// Returns plain-text values keyed by name.
    /// In development with plain-text values, returns as-is.
    /// </summary>
    public static Dictionary<string, string> DecryptAll(IConfiguration configuration)
    {
        var result  = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var section = configuration.GetSection("ConnectionStrings");

        foreach (var child in section.GetChildren())
        {
            if (string.IsNullOrWhiteSpace(child.Value)) continue;

            try
            {
                result[child.Key] = Decrypt(child.Value);
            }
            catch
            {
                // If decryption fails the value is likely plain-text (dev mode) — use as-is
                result[child.Key] = child.Value;
            }
        }

        return result;
    }

    private static string Normalize(string s)
    {
        s = s.Replace(" ", "+").TrimEnd('=');
        return (s.Length % 4) switch
        {
            2 => s + "==",
            3 => s + "=",
            _ => s
        };
    }
}
