using System.ComponentModel.DataAnnotations;

namespace nhdphuong_1787_api.Models
{
    public class RegisterModel
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;

        public string? FullName { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Role { get; set; } = "Customer"; // Default to Customer (Parent)
    }

    public class LoginModel
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;
    }

    public class VerifyOtpModel
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        public string OtpCode { get; set; } = string.Empty;
    }

    public class ResendOtpModel
    {
        [Required]
        public string Username { get; set; } = string.Empty;
    }
}
