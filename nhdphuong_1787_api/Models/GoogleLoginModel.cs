using System.ComponentModel.DataAnnotations;

namespace nhdphuong_1787_api.Models
{
    public class GoogleLoginModel
    {
        [Required(ErrorMessage = "IdToken là bắt buộc.")]
        public string IdToken { get; set; } = string.Empty;
    }
}
