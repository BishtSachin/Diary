using MyDiary.Core.Services;
using RequestPortal.Core.Abstractions;
using RequestPortal.Core.Models;

namespace RequestPortal.Core.Services;

public sealed class EventFeedService : IEventFeedService
{
    public const int MaxPhotosPerPost = 5;
    public const long MaxPhotoBytes = 5L * 1024 * 1024;

    private readonly IEventFeedRepo _repo;
    private readonly IEventMediaStore _media;

    public EventFeedService(IEventFeedRepo repo, IEventMediaStore media)
    {
        _repo = repo;
        _media = media;
    }

    public Task<IReadOnlyList<Vertical>> GetPostableVerticalsAsync(string actorEmp, bool isSuperAdmin, CancellationToken ct = default)
        => isSuperAdmin ? _repo.ListActiveVerticalsAsync(ct) : _repo.ListAdminVerticalsAsync(actorEmp, ct);

    public Task<IReadOnlyList<Vertical>> ListAllVerticalsAsync(CancellationToken ct = default)
        => _repo.ListActiveVerticalsAsync(ct);

    public Task<IReadOnlyList<UpcomingEventItem>> ListEventsAsync(long? verticalId, CancellationToken ct = default)
        => _repo.ListEventsAsync(verticalId, ct);

    public Task<IReadOnlyList<FeedPost>> GetFeedAsync(long? verticalId, int take, CancellationToken ct = default)
        => _repo.ListFeedAsync(verticalId, take, ct);

    public async Task<long> CreateEventAsync(CreateEventDto dto, string actorEmp, bool isSuperAdmin, CancellationToken ct = default)
    {
        await EnsurePostableAsync(actorEmp, isSuperAdmin, dto.VerticalId, ct);
        if (string.IsNullOrWhiteSpace(dto.Name)) throw new InvalidOperationException("Event name is required.");
        var id = await _repo.InsertEventAsync(dto, actorEmp, ct);
        await _repo.LogAsync("EVENT_CREATED", "EVENT", id, actorEmp, dto.VerticalId, dto.Name, ct);
        return id;
    }

    public async Task<long> CreatePostAsync(CreatePostDto dto, string actorEmp, bool isSuperAdmin, CancellationToken ct = default)
    {
        await EnsurePostableAsync(actorEmp, isSuperAdmin, dto.VerticalId, ct);

        var images = (dto.Images ?? new()).Take(MaxPhotosPerPost).ToList();
        if (images.Any(i => i.Data.LongLength > MaxPhotoBytes))
            throw new InvalidOperationException("Each photo must be 5 MB or smaller.");

        var postId = await _repo.InsertPostAsync(dto, actorEmp, ct);

        var seq = 0;
        foreach (var img in images)
        {
            var path = await _media.SaveAsync(postId, img.FileName, img.Data, ct);
            await _repo.InsertPostImageAsync(postId, path, img.FileName, img.ContentType, img.Data.LongLength, seq++, ct);
        }

        await _repo.LogAsync("POST_CREATED", "POST", postId, actorEmp, dto.VerticalId,
            $"caption_len={dto.Caption?.Length ?? 0};images={images.Count};event={dto.EventId};tag={dto.TagId}", ct);
        return postId;
    }

    // ── Tags ──────────────────────────────────────────────────────────────────
    public Task<IReadOnlyList<EventTag>> ListTagsAsync(bool onlyEnabled, CancellationToken ct = default)
        => _repo.ListTagsAsync(onlyEnabled, ct);

    public async Task<long> AddTagAsync(string name, string actorEmp, CancellationToken ct = default)
    {
        name = name.Trim();
        if (string.IsNullOrWhiteSpace(name)) throw new InvalidOperationException("Tag name is required.");
        if (!name.StartsWith('#')) name = "#" + name;
        name = name.Replace(" ", "");
        var id = await _repo.InsertTagAsync(name, actorEmp, ct);
        await _repo.LogAsync("TAG_ADDED", "TAG", id, actorEmp, null, name, ct);
        return id;
    }

    public async Task SetTagEnabledAsync(long id, bool enabled, string actorEmp, CancellationToken ct = default)
    {
        await _repo.SetTagEnabledAsync(id, enabled, ct);
        await _repo.LogAsync(enabled ? "TAG_ENABLED" : "TAG_DISABLED", "TAG", id, actorEmp, null, null, ct);
    }

    // ── Archival ──────────────────────────────────────────────────────────────
    public async Task<int> ArchiveOldContentAsync(int olderThanDays, CancellationToken ct = default)
    {
        var cutoff = AppTime.Now.AddDays(-olderThanDays);
        var posts = await _repo.ListPostsToArchiveAsync(cutoff, ct);
        foreach (var post in posts)
        {
            foreach (var img in post.Images)
            {
                try
                {
                    var newPath = await _media.MoveToArchiveAsync(img.FilePath, ct);
                    await _repo.UpdateImagePathArchivedAsync(img.Id, newPath, ct);
                }
                catch { /* keep going; DB flag still set below */ }
            }
            await _repo.MarkPostArchivedAsync(post.Id, ct);
            await _repo.LogAsync("POST_ARCHIVED", "POST", post.Id, "SYSTEM", post.VerticalId, null, ct);
        }
        return posts.Count;
    }

    public Task<int> PurgeOldLogsAsync(int retentionYears, CancellationToken ct = default)
        => _repo.PurgeLogsOlderThanAsync(AppTime.Now.AddYears(-retentionYears), ct);

    // ── Helpers ───────────────────────────────────────────────────────────────
    private async Task EnsurePostableAsync(string actorEmp, bool isSuperAdmin, long verticalId, CancellationToken ct)
    {
        var allowed = await GetPostableVerticalsAsync(actorEmp, isSuperAdmin, ct);
        if (!allowed.Any(v => v.Id == verticalId))
            throw new InvalidOperationException("You are not authorised to post for this vertical.");
    }
}
