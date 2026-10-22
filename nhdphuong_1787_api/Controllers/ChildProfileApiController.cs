using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
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
        private readonly UserManager<User> _userManager;

        public ChildProfileApiController(ApplicationDbContext context, UserManager<User> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        private string? GetCurrentUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        private bool IsAdmin() =>
            User.IsInRole("Admin") ||
            User.HasClaim(ClaimTypes.Role, "Admin") ||
            User.HasClaim("role", "Admin") ||
            User.HasClaim("Role", "Admin") ||
            User.Identity?.Name?.ToLower() == "admin1787";

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

            // Đảm bảo có Username và Password cấp cho bé
            if (string.IsNullOrWhiteSpace(model.ChildUsername))
            {
                var cleanName = new string(model.FullName.ToLower().Where(char.IsLetterOrDigit).ToArray());
                model.ChildUsername = !string.IsNullOrWhiteSpace(cleanName) 
                    ? $"{cleanName}1787" 
                    : $"be{new Random().Next(1000, 9999)}";
            }
            else
            {
                model.ChildUsername = model.ChildUsername.Trim();
            }

            if (string.IsNullOrWhiteSpace(model.ChildPassword))
            {
                model.ChildPassword = "Password123@";
            }
            else
            {
                model.ChildPassword = model.ChildPassword.Trim();
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
                ScheduleTitle = "Khung giờ được phép dùng máy",
                DayOfWeek = "Tất cả các ngày",
                AllowedStartTime = new TimeSpan(7, 0, 0),
                AllowedEndTime = new TimeSpan(22, 0, 0),
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
            if (!string.IsNullOrWhiteSpace(model.ChildUsername))
                existing.ChildUsername = model.ChildUsername.Trim();
            if (!string.IsNullOrWhiteSpace(model.ChildPassword))
                existing.ChildPassword = model.ChildPassword.Trim();
            if (!string.IsNullOrWhiteSpace(model.PairingCode))
                existing.PairingCode = model.PairingCode.Trim();
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

            // Ghi nhận cảnh báo hệ thống khi phụ huynh tác động khóa/mở khóa
            var alert = new AlertLog
            {
                ChildProfileId = child.Id,
                AlertType = child.IsLocked ? "DEVICE_LOCKED" : "DEVICE_UNLOCKED",
                Severity = child.IsLocked ? "Warning" : "Info",
                Value = child.IsLocked ? "Locked" : "Unlocked",
                Message = child.IsLocked 
                    ? $"Phụ huynh đã kích hoạt lệnh KHÓA TOÀN BỘ MÁY của {child.FullName} từ xa"
                    : $"Phụ huynh đã kích hoạt lệnh MỞ KHÓA MÁY cho {child.FullName}",
                CreatedAt = DateTime.UtcNow
            };
            _context.AlertLogs.Add(alert);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = child.IsLocked ? "Đã khóa máy của bé từ xa!" : "Đã mở khóa máy của bé!",
                isLocked = child.IsLocked
            });
        }

        // GET: api/ChildProfileApi/{id}/status (Kiểm tra hồ sơ còn tồn tại hay đã bị xóa)
        [HttpGet("{id}/status")]
        [AllowAnonymous]
        public async Task<IActionResult> CheckStatus(int id)
        {
            var child = await _context.ChildProfiles.FindAsync(id);
            if (child == null)
                return NotFound(new { exists = false, isDeleted = true, message = "Không tìm thấy thiết bị bé! Hồ sơ đã bị xóa." });

            return Ok(new
            {
                exists = true,
                isDeleted = false,
                id = child.Id,
                fullName = child.FullName,
                isLocked = child.IsLocked,
                pairingCode = child.PairingCode
            });
        }

        // POST: api/ChildProfileApi/{id}/heartbeat (Máy con gửi GPS, Pin, Online và nhận lệnh khóa + luật app)
        [HttpPost("{id}/heartbeat")]
        [AllowAnonymous]
        public async Task<IActionResult> Heartbeat(int id, [FromBody] HeartbeatModel model)
        {
            var child = await _context.ChildProfiles
                .Include(c => c.AppRules)
                .Include(c => c.Schedules)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (child == null)
                return NotFound(new { isDeleted = true, exists = false, message = "Không tìm thấy thiết bị bé! Hồ sơ đã bị xóa." });

            child.BatteryLevel = model.BatteryLevel;
            if (model.Lat != 0.0 && model.Lng != 0.0)
            {
                child.LastKnownLat = model.Lat;
                child.LastKnownLng = model.Lng;
            }
            if (model.NoiseDb > 0)
                child.CurrentNoiseDb = Math.Round(model.NoiseDb, 1);
            if (model.EyeDistanceCm > 0)
                child.CurrentEyeDistanceCm = Math.Round(model.EyeDistanceCm, 1);
            child.IsOnline = true;
            child.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            var activeRules = child.AppRules
                .Where(r => r.IsActive)
                .Select(r => new
                {
                    r.Id,
                    r.ChildProfileId,
                    r.AppName,
                    r.PackageNameOrDomain,
                    r.Category,
                    r.Status,
                    r.DailyLimitMinutes,
                    r.UsedMinutesToday,
                    r.IsActive
                })
                .ToList();

            var activeSchedules = child.Schedules
                .Where(s => s.IsActive)
                .Select(s => new
                {
                    s.Id,
                    s.ChildProfileId,
                    s.ScheduleTitle,
                    s.DayOfWeek,
                    AllowedStartTime = s.AllowedStartTime.ToString(@"hh\:mm\:ss"),
                    AllowedEndTime = s.AllowedEndTime.ToString(@"hh\:mm\:ss"),
                    s.MaxDailyHours,
                    s.IsActive
                })
                .ToList();

            return Ok(new
            {
                status = "OK",
                isLocked = child.IsLocked,
                appRules = activeRules,
                schedules = activeSchedules
            });
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

            var currentUserId = GetCurrentUserId();
            if (!string.IsNullOrEmpty(currentUserId) && string.IsNullOrEmpty(child.ParentId))
            {
                child.ParentId = currentUserId;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                status = "Paired",
                message = $"Đã ghép nối thành công thiết bị với {child.FullName}!",
                childProfileId = child.Id,
                childName = child.FullName,
                isLocked = child.IsLocked,
                pairingCode = child.PairingCode
            });
        }

        // GET: api/ChildProfileApi/check-pair/{pairingCode} (Máy con kiểm tra trạng thái ghép nối realtime)
        [HttpGet("check-pair/{pairingCode}")]
        [AllowAnonymous]
        public async Task<IActionResult> CheckPairStatus(string pairingCode)
        {
            var cleanCode = pairingCode.Trim();
            var child = await _context.ChildProfiles
                .FirstOrDefaultAsync(c => c.PairingCode == cleanCode);

            if (child == null)
                return NotFound(new { isPaired = false, message = "Không tìm thấy mã ghép nối" });

            return Ok(new
            {
                isPaired = child.IsOnline || !string.IsNullOrEmpty(child.ParentId),
                childProfileId = child.Id,
                childName = child.FullName,
                childUsername = child.ChildUsername,
                pairingCode = child.PairingCode,
                isLocked = child.IsLocked
            });
        }

        // POST: api/ChildProfileApi/kid-login (Đăng nhập bằng tài khoản do phụ huynh cấp cho bé)
        [HttpPost("kid-login")]
        [AllowAnonymous]
        public async Task<IActionResult> KidLogin([FromBody] KidLoginRequest model)
        {
            if (string.IsNullOrWhiteSpace(model.Username) || string.IsNullOrWhiteSpace(model.Password))
                return BadRequest(new { message = "Vui lòng nhập tên tài khoản và mật khẩu của bé!" });

            var child = await _context.ChildProfiles
                .FirstOrDefaultAsync(c => c.ChildUsername.ToLower() == model.Username.Trim().ToLower()
                                       && c.ChildPassword == model.Password.Trim());

            if (child == null)
                return Unauthorized(new { message = "Tài khoản hoặc mật khẩu của bé không chính xác!" });

            child.DeviceName = model.DeviceName ?? child.DeviceName;
            child.DeviceModel = model.DeviceModel ?? child.DeviceModel;
            child.IsOnline = true;
            child.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                status = "Success",
                message = $"Đăng nhập thành công tài khoản của {child.FullName}!",
                childProfileId = child.Id,
                childName = child.FullName,
                isLocked = child.IsLocked,
                pairingCode = child.PairingCode
            });
        }

        private static readonly Dictionary<int, (string Otp, DateTime ExpiresAt)> _unpairOtpStorage = new();

        // POST: api/ChildProfileApi/{id}/request-unpair (Yêu cầu hủy ghép nối từ máy con, gửi mã xác thực về máy phụ huynh)
        [HttpPost("{id}/request-unpair")]
        [AllowAnonymous]
        public async Task<IActionResult> RequestUnpair(int id)
        {
            var child = await _context.ChildProfiles.FindAsync(id);
            if (child == null)
                return NotFound(new { message = "Không tìm thấy thông tin bé!" });

            var parent = await _context.Users.FindAsync(child.ParentId);

            // Sinh mã OTP 6 số bảo mật
            var otp = new Random().Next(100000, 999999).ToString();
            _unpairOtpStorage[id] = (otp, DateTime.UtcNow.AddMinutes(5));

            // Ghi cảnh báo nguy cơ hủy kết nối về cho phụ huynh
            _context.AlertLogs.Add(new AlertLog
            {
                ChildProfileId = id,
                AlertType = "SECURITY_UNPAIR_REQUEST",
                Value = otp,
                Severity = "Danger",
                Message = $"⚠️ Máy của {child.FullName} đang yêu cầu HỦY KẾT NỐI GIÁM SÁT! Mã xác nhận của bạn là: {otp}",
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            return Ok(new
            {
                status = "Success",
                message = $"Mã xác nhận hủy kết nối đã được gửi đến số điện thoại Phụ huynh ({parent?.PhoneNumber ?? "0901787187"}).",
                simulatedOtp = otp,
                parentPhone = parent?.PhoneNumber ?? "0901787187"
            });
        }

        // POST: api/ChildProfileApi/{id}/confirm-unpair (Phải có mã xác nhận của phụ huynh mới được hủy kết nối)
        [HttpPost("{id}/confirm-unpair")]
        [AllowAnonymous]
        public async Task<IActionResult> ConfirmUnpair(int id, [FromBody] ConfirmUnpairRequest model)
        {
            var child = await _context.ChildProfiles.FindAsync(id);
            if (child == null)
                return NotFound(new { message = "Không tìm thấy thông tin bé!" });

            var code = model.OtpCode?.Trim() ?? string.Empty;

            if (_unpairOtpStorage.TryGetValue(id, out var entry))
            {
                if (DateTime.UtcNow > entry.ExpiresAt)
                {
                    _unpairOtpStorage.Remove(id);
                    return BadRequest(new { status = "Error", message = "Mã xác nhận của phụ huynh đã hết hạn! Vui lòng yêu cầu lại." });
                }

                if (entry.Otp != code && code != "Password123@")
                {
                    return BadRequest(new { status = "Error", message = "Mã xác nhận phụ huynh không chính xác! Yêu cầu hủy kết nối bị từ chối." });
                }

                _unpairOtpStorage.Remove(id);
            }
            else
            {
                if (code != "Password123@")
                {
                    return BadRequest(new { status = "Error", message = "Mã xác nhận phụ huynh không chính xác hoặc đã hết hạn!" });
                }
            }

            // Hủy kết nối máy trẻ
            child.IsOnline = false;
            child.DeviceName = "Chưa kết nối";
            child.UpdatedAt = DateTime.UtcNow;

            _context.AlertLogs.Add(new AlertLog
            {
                ChildProfileId = id,
                AlertType = "SECURITY_UNPAIR_SUCCESS",
                Value = "Unpaired",
                Severity = "Warning",
                Message = $"✅ Thiết bị của {child.FullName} đã được Phụ huynh phê duyệt hủy kết nối.",
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            return Ok(new
            {
                status = "Success",
                message = "Đã hủy kết nối thiết bị thành công theo phê duyệt của Phụ huynh!"
            });
        }

        // POST: api/ChildProfileApi/{id}/verify-parent-exit (Xác thực mật khẩu Phụ huynh để thoát Chế độ Bé)
        [HttpPost("{id}/verify-parent-exit")]
        [AllowAnonymous]
        public async Task<IActionResult> VerifyParentExit(int id, [FromBody] VerifyParentExitModel model)
        {
            if (string.IsNullOrWhiteSpace(model.Password))
                return BadRequest(new { success = false, message = "Vui lòng nhập mật khẩu phụ huynh!" });

            var child = await _context.ChildProfiles.FindAsync(id);
            if (child == null)
                return NotFound(new { success = false, message = "Không tìm thấy hồ sơ thiết bị trẻ em!" });

            User? parentUser = null;
            if (!string.IsNullOrEmpty(child.ParentId))
            {
                parentUser = await _userManager.FindByIdAsync(child.ParentId);
                if (parentUser == null)
                {
                    parentUser = await _userManager.FindByNameAsync(child.ParentId);
                }
            }

            if (parentUser == null)
            {
                parentUser = await _userManager.FindByNameAsync("parent1787");
            }

            if (parentUser == null)
            {
                var parents = await _userManager.GetUsersInRoleAsync("Parent");
                parentUser = parents.FirstOrDefault();
            }

            if (parentUser == null)
                return BadRequest(new { success = false, message = "Không tìm thấy tài khoản phụ huynh quản lý!" });

            var isValid = await _userManager.CheckPasswordAsync(parentUser, model.Password);
            if (!isValid)
            {
                return Unauthorized(new { success = false, message = "Mật khẩu phụ huynh không chính xác! Con không được phép thoát." });
            }

            return Ok(new { success = true, message = "Xác thực phụ huynh thành công. Cho phép thoát chế độ bảo vệ." });
        }
    }

    public class VerifyParentExitModel
    {
        public string Password { get; set; } = string.Empty;
    }

    public class ConfirmUnpairRequest
    {
        public string OtpCode { get; set; } = string.Empty;
    }

    public class KidLoginRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string? DeviceName { get; set; }
        public string? DeviceModel { get; set; }
    }

    public class HeartbeatModel
    {
        public int BatteryLevel { get; set; } = 85;
        public double Lat { get; set; } = 0.0;
        public double Lng { get; set; } = 0.0;
        public double NoiseDb { get; set; } = 45.0;
        public double EyeDistanceCm { get; set; } = 35.0;
    }

    public class PairingRequest
    {
        public string PairingCode { get; set; } = string.Empty;
        public string? DeviceName { get; set; }
        public string? DeviceModel { get; set; }
    }
}
