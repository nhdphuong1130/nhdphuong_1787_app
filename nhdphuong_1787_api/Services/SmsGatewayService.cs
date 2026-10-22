using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace nhdphuong_1787_api.Services
{
    public class SmsGatewayService : ISmsGatewayService
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<SmsGatewayService> _logger;

        public SmsGatewayService(
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            ILogger<SmsGatewayService> logger)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _logger = logger;
        }

        public string NormalizePhone(string phone)
        {
            if (string.IsNullOrWhiteSpace(phone)) return string.Empty;
            var cleaned = new string(phone.Where(c => char.IsDigit(c) || c == '+').ToArray()).Trim();

            // Nếu bắt đầu bằng +84, đổi sang 0 để SIMGATE gửi đúng chuẩn nội địa
            if (cleaned.StartsWith("+84"))
            {
                return "0" + cleaned.Substring(3);
            }
            if (cleaned.StartsWith("84") && cleaned.Length > 9)
            {
                return "0" + cleaned.Substring(2);
            }
            return cleaned;
        }

        private static string? _dynamicUrl;

        public void SetDynamicGatewayUrl(string url)
        {
            if (!string.IsNullOrWhiteSpace(url))
            {
                _dynamicUrl = url.Trim();
                _logger.LogInformation(">>> [SMS GATEWAY] Cập nhật URL động thành công: {Url}", _dynamicUrl);
            }
        }

        public string? GetActiveGatewayUrl() => _dynamicUrl;

        public async Task<(bool isOnline, string? model, string? activeUrl)> CheckGatewayHealthAsync()
        {
            var gatewayConfig = _configuration.GetSection("SmsGateway");
            var configuredUrl = gatewayConfig["Url"] ?? "http://127.0.0.1:8080";
            var username = gatewayConfig["Username"] ?? "sms";
            var password = gatewayConfig["Password"] ?? "0vzi2T1_";

            var candidateUrls = new List<string?>
            {
                _dynamicUrl,
                configuredUrl,
                "https://diameter-squad-rabbit-regardless.trycloudflare.com",
                "http://192.168.1.219:8080",
                "http://127.0.0.1:8080"
            }.Where(u => !string.IsNullOrWhiteSpace(u)).Select(u => u!).Distinct().ToList();

            foreach (var baseUrl in candidateUrls)
            {
                try
                {
                    var client = _httpClientFactory.CreateClient();
                    client.Timeout = TimeSpan.FromSeconds(4);
                    var authString = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{username}:{password}"));
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", authString);

                    var resp = await client.GetAsync(baseUrl.TrimEnd('/'));
                    if (resp.IsSuccessStatusCode)
                    {
                        var body = await resp.Content.ReadAsStringAsync();
                        return (true, body, baseUrl);
                    }
                }
                catch
                {
                    // ignore
                }
            }

            return (false, null, null);
        }

        public async Task<bool> SendSmsAsync(string phoneNumber, string message)
        {
            var gatewayConfig = _configuration.GetSection("SmsGateway");
            var configuredUrl = gatewayConfig["Url"] ?? "http://127.0.0.1:8080";
            var username = gatewayConfig["Username"] ?? "sms";
            var password = gatewayConfig["Password"] ?? "0vzi2T1_";

            var normalizedPhone = NormalizePhone(phoneNumber);
            if (string.IsNullOrEmpty(normalizedPhone))
            {
                _logger.LogWarning("Số điện thoại không hợp lệ để gửi SMS qua SIMGATE: {Phone}", phoneNumber);
                return false;
            }

            var candidateUrls = new List<string?>
            {
                _dynamicUrl,
                configuredUrl,
                "https://diameter-squad-rabbit-regardless.trycloudflare.com",
                "http://192.168.1.219:8080",
                "http://127.0.0.1:8080"
            }.Where(u => !string.IsNullOrWhiteSpace(u)).Select(u => u!).Distinct().ToList();

            foreach (var baseUrl in candidateUrls)
            {
                try
                {
                    var client = _httpClientFactory.CreateClient();
                    client.Timeout = TimeSpan.FromSeconds(5);

                    var authString = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{username}:{password}"));
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", authString);

                    var payload = new
                    {
                        message = message,
                        phoneNumbers = new[] { normalizedPhone }
                    };

                    var requestUrl = $"{baseUrl.TrimEnd('/')}/message";
                    var jsonContent = new StringContent(
                        JsonSerializer.Serialize(payload),
                        Encoding.UTF8,
                        "application/json"
                    );

                    _logger.LogInformation("Đang gửi SMS thật qua SIMGATE tới {Phone}: {Url}", normalizedPhone, requestUrl);

                    var response = await client.PostAsync(requestUrl, jsonContent);
                    var responseBody = await response.Content.ReadAsStringAsync();

                    if (response.IsSuccessStatusCode)
                    {
                        _logger.LogInformation("Gửi SMS thật thành công qua SIMGATE tới {Phone}. Response: {Resp}", normalizedPhone, responseBody);
                        return true;
                    }
                    else
                    {
                        _logger.LogWarning("SIMGATE trả về status HTTP {Code}: {Resp}", response.StatusCode, responseBody);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning("Không thể kết nối SIMGATE tại {Url} ({Msg}). Đang thử endpoint khác nếu có...", baseUrl, ex.Message);
                }
            }

            _logger.LogError("Không thể gửi tin nhắn SMS tới {Phone} qua bất kỳ cổng SIMGATE nào.", normalizedPhone);
            return false;
        }
    }
}
