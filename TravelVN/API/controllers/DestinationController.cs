using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using TravelVN.API.Models;

namespace TravelVN.API.Controller;

[ApiController, Route("api/[controller]")]
public class DestinationController(IWebHostEnvironment environment, ILogger<DestinationController> logger) : BaseController
{
    [HttpGet]
    public IActionResult List(int page = 1, int pageSize = 10, int? categoryId = null, string? keyword = null)
    {
        if (page < 1 || pageSize is < 1 or > 100) return BadRequest();
        return Ok(Provider.Destination.List(page, pageSize, categoryId, keyword));
    }

    [HttpGet("{id:int}")]
    public IActionResult Detail(int id)
    {
        var item = Provider.Destination.Find(id);
        return item is null ? NotFound() : Ok(item);
    }

    [HttpPost, Authorize(Roles = "Admin")]
    public async Task<IActionResult> Add([FromForm] DestinationForm form)
    {
        if (form.Image is null) return BadRequest("Image is required.");
        return await Save(null, form);
    }

    [HttpPut("{id:int}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Edit(int id, [FromForm] DestinationForm form)
    {
        var existing = Provider.Destination.Find(id);
        return existing is null ? NotFound() : await Save(existing, form);
    }

    [HttpDelete("{id:int}"), Authorize(Roles = "Admin")]
    public IActionResult Delete(int id)
    {
        Destination? item;
        try
        {
            item = Provider.Destination.Delete(id);
        }
        catch (SqlException exception) when (exception.Number == 547)
        {
            return Conflict("This destination is referenced by other records.");
        }

        if (item is null) return NotFound();
        if (item.Image is not null && !Provider.Destination.UsesImage(item.Image)) DeleteImage(item.Image);
        if (!string.IsNullOrEmpty(item.Gallery))
        {
            try
            {
                foreach (var path in JsonSerializer.Deserialize<string[]>(item.Gallery) ?? [])
                {
                    if (!string.IsNullOrEmpty(path) && !Provider.Destination.UsesImage(path))
                        DeleteImage(path);
                }
            }
            catch (JsonException exception)
            {
                logger.LogWarning(exception, "Invalid gallery for deleted destination {DestinationId}", id);
            }
        }
        return NoContent();
    }

    private async Task<IActionResult> Save(Destination? existing, DestinationForm form)
    {
        var item = new Destination
        {
            DestinationId = existing?.DestinationId ?? 0,
            CategoryId = form.CategoryId,
            Name = form.Name.Trim(),
            Province = form.Province.Trim(),
            Address = form.Address,
            ShortDescription = form.ShortDescription,
            Description = form.Description,
            Latitude = form.Latitude,
            Longitude = form.Longitude,
            TicketPrice = form.TicketPrice,
            OpeningHours = form.OpeningHours,
            Image = existing?.Image
        };

        string? uploaded = null;
        if (form.Image is { } image)
        {
            var extension = Path.GetExtension(image.FileName).ToLowerInvariant();
            if (image.Length is <= 0 or > 5_242_880 || extension is not (".jpg" or ".jpeg" or ".png" or ".webp"))
                return BadRequest("Use a JPEG, PNG or WebP image up to 5 MB.");

            uploaded = $"uploads/destinations/{Guid.NewGuid():N}{extension}";
            var path = Path.Combine(environment.WebRootPath, uploaded);
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            try
            {
                await using var output = System.IO.File.Create(path);
                await image.CopyToAsync(output);
            }
            catch
            {
                DeleteImage(uploaded);
                throw;
            }
            item.Image = uploaded;
        }

        bool saved = false;
        try
        {
            if (existing is null)
            {
                int id = Provider.Destination.Add(item);
                saved = true;
                item.DestinationId = id;
                return CreatedAtAction(nameof(Detail), new { id }, item);
            }

            saved = Provider.Destination.Edit(item, existing.Image) == 1;
            if (!saved) return Conflict("The destination changed. Reload and retry.");
        }
        catch (SqlException exception) when (exception.Number == 547)
        {
            return BadRequest("The selected category does not exist.");
        }
        finally
        {
            if (!saved && uploaded is not null) DeleteImage(uploaded);
        }

        if (uploaded is not null && existing.Image is { } old && !Provider.Destination.UsesImage(old))
            DeleteImage(old);
        return NoContent();
    }

    private void DeleteImage(string image)
    {
        const string folder = "uploads/destinations/";
        if (!image.StartsWith(folder, StringComparison.Ordinal)) return;
        var name = image[folder.Length..];
        if (name.Length == 0 || name.IndexOfAny(['/', '\\', ':']) >= 0 || name is "." or "..") return;
        try
        {
            System.IO.File.Delete(Path.Combine(environment.WebRootPath, folder, name));
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
        {
            logger.LogWarning(exception, "Could not remove destination image {Image}", image);
        }
    }
}

public class DestinationForm
{
    [Range(1, int.MaxValue)] public int CategoryId { get; set; }
    [Required, StringLength(150)] public string Name { get; set; } = "";
    [Required, StringLength(100)] public string Province { get; set; } = "";
    [StringLength(255)] public string? Address { get; set; }
    [StringLength(500)] public string? ShortDescription { get; set; }
    public string? Description { get; set; }
    [Range(-90, 90)] public decimal? Latitude { get; set; }
    [Range(-180, 180)] public decimal? Longitude { get; set; }
    [Range(typeof(decimal), "0", "9999999999999999.99")] public decimal TicketPrice { get; set; }
    [StringLength(100)] public string? OpeningHours { get; set; }
    public IFormFile? Image { get; set; }
}
