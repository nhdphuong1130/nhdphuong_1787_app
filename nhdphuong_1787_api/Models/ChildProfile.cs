using System.Text.Json.Serialization;

namespace nhdphuong_1787_api.Models
{
    public class ChildProfile
    {
        public int Id { get; set; }
        public string ParentId { get; set; } = string.Empty;
        
        [JsonIgnore]
        public virtual User? Parent { get; set; }

        public string FullName { get; set; } = string.Empty;
        public int Age { get; set; } = 8;
        public string? AvatarUrl { get; set; }
        public string DeviceName { get; set; } = "Android Phone";
        public string DeviceModel { get; set; } = "Samsung / Emulator";
        public string PairingCode { get; set; } = "178701";
        public int BatteryLevel { get; set; } = 85;
        public bool IsOnline { get; set; } = true;
        public bool IsLocked { get; set; } = false;

        // GPS coordinates
        public double LastKnownLat { get; set; } = 10.762622;
        public double LastKnownLng { get; set; } = 106.660172;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation
        public virtual ICollection<AppRule> AppRules { get; set; } = new List<AppRule>();
        public virtual ICollection<ScreenTimeSchedule> Schedules { get; set; } = new List<ScreenTimeSchedule>();
        public virtual ICollection<AlertLog> AlertLogs { get; set; } = new List<AlertLog>();
    }
}
