using System.Security.Cryptography;
using System.Text;

namespace StickBy.Api.Services;

public interface IEncryptionService
{
    string Encrypt(string plainText, Guid userId);
    string Decrypt(string cipherText, Guid userId);
}

public class EncryptionService : IEncryptionService
{
    private readonly byte[] _masterKey;

    public EncryptionService(IConfiguration configuration)
    {
        var keyString = configuration["Encryption:MasterKey"]
            ?? throw new InvalidOperationException("Encryption:MasterKey not configured");
        _masterKey = Convert.FromBase64String(keyString);
    }

    public string Encrypt(string plainText, Guid userId)
    {
        var userKey = DeriveUserKey(userId);
        using var aes = Aes.Create();
        aes.Key = userKey;
        aes.GenerateIV();

        using var encryptor = aes.CreateEncryptor();
        var plainBytes = Encoding.UTF8.GetBytes(plainText);
        var cipherBytes = encryptor.TransformFinalBlock(plainBytes, 0, plainBytes.Length);

        var result = new byte[aes.IV.Length + cipherBytes.Length];
        Buffer.BlockCopy(aes.IV, 0, result, 0, aes.IV.Length);
        Buffer.BlockCopy(cipherBytes, 0, result, aes.IV.Length, cipherBytes.Length);

        return Convert.ToBase64String(result);
    }

    public string Decrypt(string cipherText, Guid userId)
    {
        var userKey = DeriveUserKey(userId);
        var fullCipher = Convert.FromBase64String(cipherText);

        using var aes = Aes.Create();
        aes.Key = userKey;

        var iv = new byte[aes.BlockSize / 8];
        var cipher = new byte[fullCipher.Length - iv.Length];

        Buffer.BlockCopy(fullCipher, 0, iv, 0, iv.Length);
        Buffer.BlockCopy(fullCipher, iv.Length, cipher, 0, cipher.Length);

        aes.IV = iv;

        using var decryptor = aes.CreateDecryptor();
        var plainBytes = decryptor.TransformFinalBlock(cipher, 0, cipher.Length);

        return Encoding.UTF8.GetString(plainBytes);
    }

    private byte[] DeriveUserKey(Guid userId)
    {
        using var hmac = new HMACSHA256(_masterKey);
        return hmac.ComputeHash(userId.ToByteArray());
    }
}
