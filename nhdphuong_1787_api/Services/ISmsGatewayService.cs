namespace nhdphuong_1787_api.Services
{
    public interface ISmsGatewayService
    {
        Task<bool> SendSmsAsync(string phoneNumber, string message);
        string NormalizePhone(string phone);
        void SetDynamicGatewayUrl(string url);
        string? GetActiveGatewayUrl();
        Task<(bool isOnline, string? model, string? activeUrl)> CheckGatewayHealthAsync();
    }
}
