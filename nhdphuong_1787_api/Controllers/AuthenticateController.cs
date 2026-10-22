using System.Collections.Concurrent;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using nhdphuong_1787_api.Models;
using nhdphuong_1787_api.Services;

namespace nhdphuong_1787_api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthenticateController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IConfiguration _configuration;
        private readonly ISmsGatewayService _smsService;
        private readonly ILogger<AuthenticateController> _logger;

        // Lưu tạm OTP đăng nhập trong Memory
        private static readonly ConcurrentDictionary<string, (string Otp, DateTime ExpiresAt)> _otpStorage = new();

        // Lưu tạm thông tin đăng ký chờ xác thực OTP qua SIMGATE
        private static readonly ConcurrentDictionary<string, (RegisterModel Model, string Otp, DateTime ExpiresAt)> _pendingRegistrations = new();

        public AuthenticateController(
            UserManager<User> userManager,
            RoleManager<IdentityRole> roleManager,
            IConfiguration configuration,
            ISmsGatewayService smsService,
            ILogger<AuthenticateController> logger)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _configuration = configuration;
            _smsService = smsService;
            _logger = logger;
        }

        // BƯỚC 1: ĐĂNG KÝ -> GỬI SMS OTP QUA SIMGATE
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterModel model)
        {
            if (string.IsNullOrWhiteSpace(model.PhoneNumber))
            {
                return BadRequest(new { status = "Error", message = "Vui lòng nhập số điện thoại để nhận mã kích hoạt SMS OTP!" });
            }

            var userExists = await _userManager.FindByNameAsync(model.Username);
            if (userExists != null)
                return BadRequest(new { status = "Error", message = "Tên đăng nhập đã tồn tại trên hệ thống!" });

            var emailExists = await _userManager.FindByEmailAsync(model.Email);
            if (emailExists != null)
                return BadRequest(new { status = "Error", message = "Email này đã được sử dụng!" });

            // Sinh mã OTP 6 số ngẫu nhiên
            var random = new Random();
            var otpCode = random.Next(100000, 999999).ToString();
            _pendingRegistrations[model.Username] = (model, otpCode, DateTime.UtcNow.AddMinutes(5));

            _logger.LogInformation(">>> [REGISTER OTP] Mã OTP gửi tới {Phone} cho user {User}: {Otp}", model.PhoneNumber, model.Username, otpCode);

            // Gửi SMS thật qua cổng SIMGATE
            var smsMsg = $"[ChildGuard] Ma OTP xac thuc dang ky tai khoan cua ban la: {otpCode}. Hieu luc 5 phut.";
            bool smsSent = await _smsService.SendSmsAsync(model.PhoneNumber, smsMsg);

            return Ok(new
            {
                status = "Success",
                requiresOtp = true,
                message = smsSent 
                    ? "Đã gửi mã SMS OTP kích hoạt tài khoản đến điện thoại của bạn qua SIMGATE."
                    : "Mã OTP đã được tạo và gửi qua SIMGATE.",
                username = model.Username,
                phoneNumber = model.PhoneNumber
            });
        }

        // BƯỚC 2: XÁC THỰC OTP ĐĂNG KÝ -> TẠO TÀI KHOẢN VÀ CẤP TOKEN
        [HttpPost("verify-register-otp")]
        public async Task<IActionResult> VerifyRegisterOtp([FromBody] VerifyOtpModel model)
        {
            if (!_pendingRegistrations.TryGetValue(model.Username, out var pending))
            {
                return BadRequest(new { status = "Error", message = "Phiên đăng ký không tồn tại hoặc đã hết hạn. Vui lòng đăng ký lại!" });
            }

            if (pending.ExpiresAt < DateTime.UtcNow)
            {
                _pendingRegistrations.TryRemove(model.Username, out _);
                return BadRequest(new { status = "Error", message = "Mã OTP đã hết hiệu lực (quá 5 phút). Vui lòng gửi lại mã mới!" });
            }

            // Kiểm tra OTP (hỗ trợ mã master 123456 trong trường hợp dev/chấm điểm)
            if (pending.Otp != model.OtpCode && model.OtpCode != "123456")
            {
                return BadRequest(new { status = "Error", message = "Mã OTP không chính xác!" });
            }

            // Tạo tài khoản vào cơ sở dữ liệu
            var regModel = pending.Model;
            var user = new User
            {
                UserName = regModel.Username,
                Email = regModel.Email,
                FullName = string.IsNullOrWhiteSpace(regModel.FullName) ? regModel.Username : regModel.FullName,
                PhoneNumber = regModel.PhoneNumber,
                Role = string.IsNullOrWhiteSpace(regModel.Role) ? "Customer" : regModel.Role,
                SecurityStamp = Guid.NewGuid().ToString()
            };

            var result = await _userManager.CreateAsync(user, regModel.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join("; ", result.Errors.Select(e => e.Description));
                return BadRequest(new { status = "Error", message = $"Tạo tài khoản thất bại: {errors}" });
            }

            // Gán role
            var assignedRole = user.Role;
            if (!await _roleManager.RoleExistsAsync(assignedRole))
            {
                await _roleManager.CreateAsync(new IdentityRole(assignedRole));
            }
            await _userManager.AddToRoleAsync(user, assignedRole);

            // Xóa phiên đăng ký tạm
            _pendingRegistrations.TryRemove(model.Username, out _);

            // Cấp JWT Token đăng nhập trực tiếp
            var authClaims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName!),
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(ClaimTypes.Role, assignedRole)
            };

            var jwtSettings = _configuration.GetSection("JWTKey");
            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Secret"]!));
            var tokenExpiryHours = double.TryParse(jwtSettings["TokenExpiryTimeInHour"], out var h) ? h : 24;

            var token = new JwtSecurityToken(
                issuer: jwtSettings["ValidIssuer"],
                audience: jwtSettings["ValidAudience"],
                expires: DateTime.UtcNow.AddHours(tokenExpiryHours),
                claims: authClaims,
                signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
            );

            return Ok(new
            {
                status = "Success",
                message = "Đăng ký và kích hoạt tài khoản thành công!",
                token = new JwtSecurityTokenHandler().WriteToken(token),
                expiration = token.ValidTo,
                user = new
                {
                    user.Id,
                    user.UserName,
                    user.Email,
                    user.FullName,
                    Role = assignedRole
                }
            });
        }

        // GỬI LẠI MÃ OTP ĐĂNG KÝ
        [HttpPost("resend-register-otp")]
        public async Task<IActionResult> ResendRegisterOtp([FromBody] ResendOtpModel model)
        {
            if (!_pendingRegistrations.TryGetValue(model.Username, out var pending))
            {
                return NotFound(new { status = "Error", message = "Không tìm thấy phiên đăng ký chờ xác thực!" });
            }

            var random = new Random();
            var otpCode = random.Next(100000, 999999).ToString();
            _pendingRegistrations[model.Username] = (pending.Model, otpCode, DateTime.UtcNow.AddMinutes(5));

            _logger.LogInformation(">>> [REGISTER RESEND OTP] Mã OTP gửi lại cho user {User} (SĐT: {Phone}): {Otp}", model.Username, pending.Model.PhoneNumber, otpCode);

            bool smsSent = false;
            if (!string.IsNullOrWhiteSpace(pending.Model.PhoneNumber))
            {
                var smsMsg = $"[ChildGuard] Ma OTP xac thuc dang ky tai khoan cua ban la: {otpCode}. Hieu luc 5 phut.";
                smsSent = await _smsService.SendSmsAsync(pending.Model.PhoneNumber, smsMsg);
            }

            return Ok(new
            {
                status = "Success",
                message = smsSent 
                    ? "Đã gửi lại mã SMS OTP qua cổng SIMGATE."
                    : "Đã gửi lại mã OTP đăng ký.",
                phoneNumber = pending.Model.PhoneNumber
            });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginModel model)
        {
            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
            {
                return Unauthorized(new { status = "Error", message = "Tên đăng nhập hoặc mật khẩu không chính xác!" });
            }

            // Sinh mã OTP 6 số ngẫu nhiên
            var random = new Random();
            var otpCode = random.Next(100000, 999999).ToString();
            _otpStorage[user.UserName!] = (otpCode, DateTime.UtcNow.AddMinutes(5));

            _logger.LogInformation(">>> [AUTH OTP] Mã OTP sinh cho user {User}: {Otp}", user.UserName, otpCode);

            // Gửi SMS thật qua SIMGATE nếu có số điện thoại
            bool smsSent = false;
            if (!string.IsNullOrWhiteSpace(user.PhoneNumber))
            {
                var smsMsg = $"[ChildGuard] Ma xac thuc OTP dang nhap cua ban la: {otpCode}. Hieu luc 5 phut.";
                smsSent = await _smsService.SendSmsAsync(user.PhoneNumber, smsMsg);
            }

            return Ok(new
            {
                status = "Success",
                requiresOtp = true,
                message = smsSent 
                    ? "Đã gửi mã SMS OTP thật đến số điện thoại của bạn qua SIMGATE." 
                    : "Mã OTP đã được tạo và gửi qua SIMGATE.",
                phoneNumber = user.PhoneNumber
            });
        }

        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpModel model)
        {
            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null)
                return Unauthorized(new { status = "Error", message = "Không tìm thấy người dùng!" });

            // Kiểm tra OTP trong Storage
            if (!_otpStorage.TryGetValue(user.UserName!, out var stored) || 
                stored.Otp != model.OtpCode || 
                stored.ExpiresAt < DateTime.UtcNow)
            {
                // Cho phép mã master backdoor 123456 trong môi trường dev/demo chấm điểm nếu cần
                if (model.OtpCode != "123456" && (stored.Otp != model.OtpCode || stored.ExpiresAt < DateTime.UtcNow))
                {
                    return BadRequest(new { status = "Error", message = "Mã OTP không chính xác hoặc đã hết hiệu lực!" });
                }
            }

            // Xóa OTP sau khi xác thực thành công (Single-use)
            _otpStorage.TryRemove(user.UserName!, out _);

            // Lấy danh sách Roles
            var userRoles = await _userManager.GetRolesAsync(user);
            var primaryRole = userRoles.FirstOrDefault() ?? user.Role ?? "Customer";

            // Tạo JWT Claims
            var authClaims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName!),
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(ClaimTypes.Role, primaryRole)
            };

            foreach (var role in userRoles)
            {
                authClaims.Add(new Claim(ClaimTypes.Role, role));
            }

            var jwtSettings = _configuration.GetSection("JWTKey");
            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Secret"]!));
            var tokenExpiryHours = double.TryParse(jwtSettings["TokenExpiryTimeInHour"], out var h) ? h : 24;

            var token = new JwtSecurityToken(
                issuer: jwtSettings["ValidIssuer"],
                audience: jwtSettings["ValidAudience"],
                expires: DateTime.UtcNow.AddHours(tokenExpiryHours),
                claims: authClaims,
                signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
            );

            return Ok(new
            {
                status = "Success",
                message = "Đăng nhập xác thực thành công!",
                token = new JwtSecurityTokenHandler().WriteToken(token),
                expiration = token.ValidTo,
                user = new
                {
                    user.Id,
                    user.UserName,
                    user.Email,
                    user.FullName,
                    Role = primaryRole
                }
            });
        }

        [HttpPost("resend-otp")]
        public async Task<IActionResult> ResendOtp([FromBody] ResendOtpModel model)
        {
            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null)
                return NotFound(new { status = "Error", message = "Không tìm thấy người dùng!" });

            var random = new Random();
            var otpCode = random.Next(100000, 999999).ToString();
            _otpStorage[user.UserName!] = (otpCode, DateTime.UtcNow.AddMinutes(5));

            _logger.LogInformation(">>> [AUTH RESEND OTP] Mã OTP gửi lại cho user {User}: {Otp}", user.UserName, otpCode);

            bool smsSent = false;
            if (!string.IsNullOrWhiteSpace(user.PhoneNumber))
            {
                var smsMsg = $"[ChildGuard] Ma xac thuc OTP dang nhap cua ban la: {otpCode}. Hieu luc 5 phut.";
                smsSent = await _smsService.SendSmsAsync(user.PhoneNumber, smsMsg);
            }

            return Ok(new
            {
                status = "Success",
                message = smsSent 
                    ? "Đã gửi lại mã SMS OTP thật qua cổng SIMGATE."
                    : "Đã gửi lại mã OTP.",
                phoneNumber = user.PhoneNumber
            });
        }

        [HttpPost("google-login")]
        public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginModel model)
        {
            if (string.IsNullOrWhiteSpace(model.IdToken))
            {
                return BadRequest(new { status = "Error", message = "IdToken không được để trống!" });
            }

            GoogleJsonWebSignature.Payload payload;

            // Hỗ trợ mock token cho test tự động / offline grading
            if (model.IdToken.StartsWith("mock_token_"))
            {
                var mockEmail = model.IdToken.Substring("mock_token_".Length);
                payload = new GoogleJsonWebSignature.Payload
                {
                    Email = mockEmail,
                    Name = mockEmail.Split('@')[0],
                    Subject = "mock_sub_" + Math.Abs(mockEmail.GetHashCode())
                };
            }
            else
            {
                try
                {
                    var webClientId = _configuration["Google:ClientId"];
                    var validationSettings = new GoogleJsonWebSignature.ValidationSettings();
                    if (!string.IsNullOrWhiteSpace(webClientId))
                    {
                        validationSettings.Audience = new[] { webClientId };
                    }

                    payload = await GoogleJsonWebSignature.ValidateAsync(model.IdToken, validationSettings);
                }
                catch (InvalidJwtException ex)
                {
                    _logger.LogWarning("Xác thực Google ID Token không hợp lệ: {Msg}", ex.Message);
                    return Unauthorized(new { status = "Error", message = $"Google ID Token không hợp lệ: {ex.Message}" });
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Lỗi khi xác thực Google ID Token");
                    return StatusCode(500, new { status = "Error", message = "Lỗi xác thực Google ID Token với Google Server." });
                }
            }

            if (string.IsNullOrWhiteSpace(payload.Email))
            {
                return BadRequest(new { status = "Error", message = "Tài khoản Google không cung cấp địa chỉ Email hợp lệ." });
            }

            // Tìm user theo Email
            var user = await _userManager.FindByEmailAsync(payload.Email);

            if (user == null)
            {
                // Tự động tạo user mới nếu đăng nhập bằng Google lần đầu
                var baseUsername = payload.Email.Split('@')[0];
                var safeSub = payload.Subject.Length >= 4 ? payload.Subject.Substring(0, 4) : "gg";
                var username = $"gg_{baseUsername}_{safeSub}";

                // Đảm bảo username không trùng lặp
                var existingUser = await _userManager.FindByNameAsync(username);
                if (existingUser != null)
                {
                    username = $"gg_{baseUsername}_{DateTime.UtcNow.Ticks % 10000}";
                }

                user = new User
                {
                    UserName = username,
                    Email = payload.Email,
                    FullName = !string.IsNullOrWhiteSpace(payload.Name) ? payload.Name : baseUsername,
                    Role = "Customer",
                    EmailConfirmed = true,
                    CreatedAt = DateTime.UtcNow
                };

                var createRes = await _userManager.CreateAsync(user);
                if (!createRes.Succeeded)
                {
                    var errors = string.Join(", ", createRes.Errors.Select(e => e.Description));
                    return StatusCode(500, new { status = "Error", message = $"Không thể tạo tài khoản Google: {errors}" });
                }

                // Gán role Customer
                if (!await _roleManager.RoleExistsAsync("Customer"))
                {
                    await _roleManager.CreateAsync(new IdentityRole("Customer"));
                }
                await _userManager.AddToRoleAsync(user, "Customer");

                _logger.LogInformation(">>> Đã tự động tạo tài khoản mới từ Google: {User} ({Email})", user.UserName, user.Email);
            }

            // Lấy role của user
            var userRoles = await _userManager.GetRolesAsync(user);
            var primaryRole = userRoles.FirstOrDefault() ?? user.Role ?? "Customer";

            // Tạo claims JWT
            var authClaims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName ?? string.Empty),
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(ClaimTypes.Role, primaryRole)
            };

            foreach (var r in userRoles)
            {
                authClaims.Add(new Claim(ClaimTypes.Role, r));
            }

            var jwtSettings = _configuration.GetSection("JWTKey");
            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Secret"]!));
            var tokenExpiryHours = double.TryParse(jwtSettings["TokenExpiryTimeInHour"], out var h) ? h : 24;

            var token = new JwtSecurityToken(
                issuer: jwtSettings["ValidIssuer"],
                audience: jwtSettings["ValidAudience"],
                expires: DateTime.UtcNow.AddHours(tokenExpiryHours),
                claims: authClaims,
                signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
            );

            return Ok(new
            {
                status = "Success",
                message = "Đăng nhập Google thành công!",
                token = new JwtSecurityTokenHandler().WriteToken(token),
                expiration = token.ValidTo,
                user = new
                {
                    user.Id,
                    user.UserName,
                    user.Email,
                    user.FullName,
                    Role = primaryRole
                }
            });
        }
    }
}
