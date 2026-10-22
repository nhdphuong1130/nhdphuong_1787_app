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
    public class AlertLogApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public AlertLogApiController(ApplicationDbContext context)
        {
            _context = context;
        }

        private string? GetCurrentUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        private bool IsAdmin() =>
            User.IsInRole("Admin") ||
            User.HasClaim(ClaimTypes.Role, "Admin") ||
            User.HasClaim("role", "Admin") ||
            User.HasClaim("Role", "Admin") ||
            User.Identity?.Name?.ToLower() == "admin1787";

        // GET: api/AlertLogApi?childId=1
        [HttpGet]
        public async Task<IActionResult> GetAlerts([FromQuery] int? childId)
        {
            var userId = GetCurrentUserId();
            var query = _context.AlertLogs
                .Include(a => a.ChildProfile)
                .AsQueryable();

            if (!IsAdmin())
            {
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized();
                }
                // Cô lập dữ liệu: Phụ huynh chỉ nhìn thấy cảnh báo thuộc về các con của chính mình
                query = query.Where(a => a.ChildProfile != null && a.ChildProfile.ParentId == userId);
            }

            if (childId.HasValue && childId.Value > 0)
            {
                query = query.Where(a => a.ChildProfileId == childId.Value);
            }

            var alerts = await query
                .OrderByDescending(a => a.CreatedAt)
                .Take(50)
                .ToListAsync();

            return Ok(alerts);
        }

        // POST: api/AlertLogApi
        [HttpPost]
        [AllowAnonymous] // Cho phép máy trẻ gửi cảnh báo lên mà không cần phức tạp hóa token
        public async Task<IActionResult> CreateAlert([FromBody] AlertLog model)
        {
            model.CreatedAt = DateTime.UtcNow;
            _context.AlertLogs.Add(model);
            await _context.SaveChangesAsync();

            return Ok(model);
        }
    }
}
