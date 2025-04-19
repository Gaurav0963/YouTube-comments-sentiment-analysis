import yt_dlp
import csv
import sys

def get_latest_videos(channel_url, max_results=5):
    ydl_opts = {
        'quiet': True,
        'extract_flat': True,
        'playlistend': max_results
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            result = ydl.extract_info(channel_url, download=False)
        except Exception as e:
            print(f"❌ Error fetching videos: {e}")
            return []

        videos = []

        if 'entries' in result:
            for i in range(len(result['entries'])):
                try:
                    for entry in result['entries'][i]['entries']:
                        videos.append(entry.get("url", ""))
                except KeyError:
                    print("⚠️ Skipping an entry due to unexpected structure.")
        else:
            print("❌ No videos found or invalid channel URL.")

        return videos[:max_results]

def fetch_comments(video_url, max_comments):
    ydl_opts = {
        'quiet': True,
        'getcomments': True,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            result = ydl.extract_info(video_url, download=False)
            return result.get('comments', [])[:max_comments]
        except Exception as e:
            print(f"❌ Error fetching comments for {video_url}: {e}")
            return []

def save_comments_to_csv(video_urls, csv_filename, max_comments):
    all_comments = []

    for video_url in video_urls:
        comments = fetch_comments(video_url, max_comments)
        for comment in comments:
            all_comments.append([
                comment.get('author', 'Unknown'),
                comment.get('text', 'No Text'),
            ])

    if not all_comments:
        print("⚠️ No comments found.")
        return

    with open(csv_filename, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(["Comment Author", "Comment Text"])
        writer.writerows(all_comments)

    print(f"✅ Comments saved to {csv_filename}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("❌ Usage: python fetch_comments.py <YouTube Channel URL>")
        sys.exit(1)

    channel_url = sys.argv[1]
    max_comments = 10
    video_urls = get_latest_videos(channel_url)
    save_comments_to_csv(video_urls, "comments.csv", max_comments)
