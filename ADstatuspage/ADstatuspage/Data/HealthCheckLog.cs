namespace ADstatuspage.Data;

public class HealthCheckLog
{
    public int Id { get; set; }
    public string Section { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int DurationMs { get; set; }
    public DateTime Timestamp { get; set; }
    public string? OptionalMessage { get; set; }
}
