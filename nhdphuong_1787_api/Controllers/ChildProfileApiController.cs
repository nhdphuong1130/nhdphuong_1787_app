using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using nhdphuong_1787_api.Models;

namespace nhdphuong_1787_api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ChildProfileApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ChildProfileApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        private string? GetCurrentUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        private bool IsAdmin() => User.IsInRole("Admin");

        // GET: api/ChildProfileApi
        [HttpGet]
        public async Task<IActionResult> GetChildren()
        {
            var userId = GetCurrentUserId();
            IQueryable<ChildProfile> query = _context.ChildProfiles
                .Include(c => c.AppRules)
                .Include(c => c.Schedules)
                .Include(c => c.AlertLogs);

            if (!IsAdmin())
            {
                query = query.Where(c => c.ParentId == userId);
            }

            var children = await query.OrderByDescending(c => c.UpdatedAt).ToListAsync();
            return Ok(children);
        }

        // GET: api/ChildProfileApi/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetChild(int id)
        {
            var userId = GetCurrentUserId();
            var child = await _context.ChildProfiles
                .Include(c => c.AppRules)
                .Include(c => c.Schedules)
                .Include(c => c.AlertLogs)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (child == null)
                return NotFound(new { message = "Không tìm thấy hồ sơ bé!" });

            if (!IsAdmin() && child.ParentId != userId)
                return Forbid();

            return Ok(child);
        }

        // POST: api/ChildProfileApi
        [HttpPost]
        public async Task<IActionResult> CreateChild([FromBody] ChildProfile model)
        {
            var userId = GetCurrentUserId();
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            model.ParentId = userId;
            model.UpdatedAt = DateTime.UtcNow;

            // Tự sinh PairingCode 6 chữ số nếu chưa có
            if (string.IsNullOrWhiteSpace(model.PairingCode))
            {
                model.PairingCode = new Random().Next(100000, 999999).ToString();
            }

            _context.ChildProfiles.Add(model);
            await _context.SaveChangesAsync();

            // Tự sinh một vài quy tắc mặc định cho bé
            var defaultRules = new List<AppRule>
            {
                new AppRule { ChildProfileId = model.Id, AppName = "TikTok", Category = "SocialMedia", Status = "Blocked", DailyLimitMinutes = 0 },
                new AppRule { ChildProfileId = model.Id, AppName = "YouTube", Category = "Entertainment", Status = "Limited", DailyLimitMinutes = 45 },
                new AppRule { ChildProfileId = model.Id, AppName = "Roblox", Category = "Game", Status = "Limited", DailyLimitMinutes = 30 },
                new AppRule { ChildProfileId = model.Id, AppName = "Duolingo", Category = "Education", Status = "Allowed", DailyLimitMinutes = 120 }
            };
            _context.AppRules.AddRange(defaultRules);

            // Tự sinh một lịch biểu mặc định
            var defaultSchedule = new ScreenTimeSchedule
            {
                ChildProfileId = model.Id,
                ScheduleTitle = "Khung giờ học bài tối",
                DayOfWeek = "Thứ 2 - Thứ 6",
                AllowedStartTime = new TimeSpan(19, 0, 0),
                AllowedEndTime = new TimeSpan(21, 0, 0),
                MaxDailyHours = 2,
                IsActive = true
            };
            _context.ScreenTimeSchedules.Add(defaultSchedule);

            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetChild), new { id = model.Id }, model);
        }

        // PUT: api/ChildProfileApi/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateChild(int id, [FromBody] ChildProfile model)
        {
            var userId = GetCurrentUserId();
            var existing = await _context.ChildProfiles.FindAsync(id);
            if (existing == null)
                return NotFound(new { message = "Không tìm thấy hồ sơ bé!" });

            if (!IsAdmin() && existing.ParentId != userId)
                return Forbid();

            existing.FullName = model.FullName;
            existing.Age = model.Age;
            existing.AvatarUrl = model.AvatarUrl ?? existing.AvatarUrl;
            existing.DeviceName = model.DeviceName;
            existing.DeviceModel = model.DeviceModel;
            existing.BatteryLevel = model.BatteryLevel;
            existing.IsOnline = model.IsOnline;
            existing.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(existing);
        }

        // DELETE: api/ChildProfileApi/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteChild(int id)
        {
            var userId = GetCurrentUserId();
            var existing = await _context.ChildProfiles.FindAsync(id);
            if (existing == null)
                return NotFound(new { message = "Không tìm thấy hồ sơ bé!" });

            if (!IsAdmin() && existing.ParentId != userId)
                return Forbid();

            _context.ChildProfiles.Remove(existing);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã xóa hồ sơ bé thành công!" });
        }

        // POST: api/ChildProfileApi/{id}/lock-toggle (Khóa khẩn cấp từ xa)
        [HttpPost("{id}/lock-toggle")]
        public async Task<IActionResult> ToggleLock(int id)
        {
            var userId = GetCurrentUserId();
            var child = await _context.ChildProfiles.FindAsync(id);
            if (child == null)
                return NotFound(new { message = "Không tìm thấy hồ sơ bé!" });

            if (!IsAdmin() && child.ParentId != userId)
                return Forbid();

            child.IsLocked = !child.IsLocked;
            child.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = child.IsLocked ? "Đã khóa máy của bé từ xa!" : "Đã mở khóa máy của bé!",
                isLocked = child.IsLocked
            });
        }

        // POST: api/ChildProfileApi/{id}/heartbeat (Máy con gửi GPS, Pin, Online)
        [HttpPost("{id}/heartbeat")]
        [AllowAnonymous]
        public async Task<IActionResult> Heartbeat(int id, [FromBody] HeartbeatModel model)
        {
            var child = await _context.ChildProfiles.FindAsync(id);
            if (child == null)
                return NotFound(new { message = "Không tìm thấy thiết bị bé!" });

            child.BatteryLevel = model.BatteryLevel;
            child.LastKnownLat = model.Lat;
            child.LastKnownLng = model.Lng;
            child.IsOnline = true;
            child.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(new { status = "OK", isLocked = child.IsLocked });
        }

        // POST: api/ChildProfileApi/pair (Quét mã QR ghép nối)
        [HttpPost("pair")]
        [AllowAnonymous]
        public async Task<IActionResult> PairDevice([FromBody] PairingRequest model)
        {
            var child = await _context.ChildProfiles
                .FirstOrDefaultAsync(c => c.PairingCode == model.PairingCode);

            if (child == null)
                return NotFound(new { message = "Mã ghép nối không hợp lệ hoặc đã hết hạn!" });

            child.DeviceName = model.DeviceName ?? child.DeviceName;
            child.DeviceModel = model.DeviceModel ?? child.DeviceModel;
            child.IsOnline = true;
            child.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                status = "Paired",
                message = $"Đã ghép nối thành công thiết bị với {child.FullName}!",
                childProfileId = child.Id,
                childName = child.FullName,
                isLocked = child.IsLocked
            });
        }
    }

    public class HeartbeatModel
    {
        public int BatteryLevel { get; set; } = 85;
        public double Lat { get; set; } = 10.762622;
        public double Lng { get; set; } = 106.660172;
    }

    public class PairingRequest
    {
        public string PairingCode { get; set; } = string.Empty;
        public string? DeviceName { get; set; }
        public string? DeviceModel { get; set; }
    }
}
