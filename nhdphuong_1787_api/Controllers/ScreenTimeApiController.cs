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
    public class ScreenTimeApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ScreenTimeApiController(ApplicationDbContext context)
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

        // GET: api/ScreenTimeApi?childId=1
        [HttpGet]
        public async Task<IActionResult> GetSchedules([FromQuery] int childId)
        {
            var userId = GetCurrentUserId();
            var child = await _context.ChildProfiles.FirstOrDefaultAsync(c => c.Id == childId);
            if (child == null)
                return NotFound(new { message = "Không tìm thấy hồ sơ bé tương ứng!" });

            if (!IsAdmin() && child.ParentId != userId)
                return Forbid();

            var schedules = await _context.ScreenTimeSchedules
                .Where(s => s.ChildProfileId == childId)
                .OrderBy(s => s.ScheduleTitle)
                .ToListAsync();

            return Ok(schedules);
        }

        // POST: api/ScreenTimeApi
        [HttpPost]
        public async Task<IActionResult> CreateSchedule([FromBody] ScreenTimeSchedule model)
        {
            var userId = GetCurrentUserId();
            var child = await _context.ChildProfiles.FirstOrDefaultAsync(c => c.Id == model.ChildProfileId);
            if (child == null)
                return NotFound(new { message = "Không tìm thấy hồ sơ bé tương ứng!" });

            if (!IsAdmin() && child.ParentId != userId)
                return Forbid();

            model.CreatedAt = DateTime.UtcNow;
            _context.ScreenTimeSchedules.Add(model);
            await _context.SaveChangesAsync();

            return Ok(model);
        }

        // PUT: api/ScreenTimeApi/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateSchedule(int id, [FromBody] ScreenTimeSchedule model)
        {
            var userId = GetCurrentUserId();
            var existing = await _context.ScreenTimeSchedules.Include(s => s.ChildProfile).FirstOrDefaultAsync(s => s.Id == id);
            if (existing == null)
                return NotFound(new { message = "Không tìm thấy lịch biểu!" });

            if (!IsAdmin() && existing.ChildProfile?.ParentId != userId)
                return Forbid();

            existing.ScheduleTitle = model.ScheduleTitle;
            existing.DayOfWeek = model.DayOfWeek;
            existing.AllowedStartTime = model.AllowedStartTime;
            existing.AllowedEndTime = model.AllowedEndTime;
            existing.MaxDailyHours = model.MaxDailyHours;
            existing.IsActive = model.IsActive;

            await _context.SaveChangesAsync();
            return Ok(existing);
        }

        // DELETE: api/ScreenTimeApi/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteSchedule(int id)
        {
            var userId = GetCurrentUserId();
            var existing = await _context.ScreenTimeSchedules.Include(s => s.ChildProfile).FirstOrDefaultAsync(s => s.Id == id);
            if (existing == null)
                return NotFound(new { message = "Không tìm thấy lịch biểu!" });

            if (!IsAdmin() && existing.ChildProfile?.ParentId != userId)
                return Forbid();

            _context.ScreenTimeSchedules.Remove(existing);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa lịch biểu thành công!" });
        }

        // GET: api/ScreenTimeApi/child/{childId} (Dành cho máy con đồng bộ lịch biểu)
        [HttpGet("child/{childId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetChildSchedules(int childId)
        {
            var schedules = await _context.ScreenTimeSchedules
                .Where(s => s.ChildProfileId == childId && s.IsActive)
                .OrderBy(s => s.ScheduleTitle)
                .ToListAsync();
            return Ok(schedules);
        }

        // PATCH: api/ScreenTimeApi/{id}/toggle (Bật/tắt nhanh lịch biểu)
        [HttpPatch("{id}/toggle")]
        [AllowAnonymous]
        public async Task<IActionResult> ToggleSchedule(int id)
        {
            var existing = await _context.ScreenTimeSchedules.FindAsync(id);
            if (existing == null)
                return NotFound(new { message = "Không tìm thấy lịch biểu!" });

            existing.IsActive = !existing.IsActive;
            await _context.SaveChangesAsync();

            return Ok(new { success = true, isActive = existing.IsActive, message = existing.IsActive ? "Đã bật lịch biểu!" : "Đã tắt lịch biểu!" });
        }
    }
}
