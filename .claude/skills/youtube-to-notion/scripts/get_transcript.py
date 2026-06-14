#!/usr/bin/env python3
"""YouTube 트랜스크립트 추출기 - 한국어 우선, 영어 fallback"""

import sys
import re
import json

def extract_video_id(url: str) -> str:
    patterns = [
        r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([a-zA-Z0-9_-]{11})',
        r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})',
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    raise ValueError(f"YouTube URL에서 video ID를 추출할 수 없습니다: {url}")

def get_transcript(url: str) -> dict:
    from youtube_transcript_api import YouTubeTranscriptApi
    from youtube_transcript_api._errors import TranscriptsDisabled, NoTranscriptFound

    video_id = extract_video_id(url)
    video_url = f"https://www.youtube.com/watch?v={video_id}"

    try:
        api = YouTubeTranscriptApi()
        transcript_list = api.list(video_id=video_id)

        # 우선순위: 한국어 → 영어 → 기타
        transcript = None
        lang_used = None

        for langs in [['ko'], ['en']]:
            try:
                transcript = transcript_list.find_transcript(langs)
                lang_used = langs[0]
                break
            except Exception:
                continue

        if not transcript:
            # 첫 번째 사용 가능한 자막 사용
            for t in transcript_list:
                transcript = t
                lang_used = t.language_code
                break

        if not transcript:
            return {
                "video_id": video_id,
                "url": video_url,
                "error": "사용 가능한 자막을 찾을 수 없습니다.",
                "transcript": None
            }

        fetched = transcript.fetch()

        # 전체 텍스트 구성 (타임스탬프 포함)
        full_text = ""
        total_duration = 0
        for snippet in fetched:
            start = int(snippet.start)
            mins, secs = divmod(start, 60)
            hours, mins = divmod(mins, 60)
            if hours > 0:
                timestamp = f"[{hours:02d}:{mins:02d}:{secs:02d}]"
            else:
                timestamp = f"[{mins:02d}:{secs:02d}]"
            full_text += f"{timestamp} {snippet.text}\n"
            total_duration = int(snippet.start + snippet.duration)

        # 영상 길이 포맷
        mins, secs = divmod(total_duration, 60)
        hours, mins = divmod(mins, 60)
        if hours > 0:
            duration_str = f"{hours}시간 {mins}분"
        else:
            duration_str = f"{mins}분 {secs}초"

        return {
            "video_id": video_id,
            "url": video_url,
            "language": lang_used,
            "duration": duration_str,
            "transcript": full_text,
            "entry_count": len(fetched)
        }

    except TranscriptsDisabled:
        return {
            "video_id": video_id,
            "url": video_url,
            "error": "이 영상은 자막이 비활성화되어 있습니다.",
            "transcript": None
        }
    except Exception as e:
        return {
            "video_id": video_id,
            "url": video_url,
            "error": str(e),
            "transcript": None
        }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "사용법: python3 get_transcript.py <YouTube URL>"}))
        sys.exit(1)

    url = sys.argv[1]
    result = get_transcript(url)
    print(json.dumps(result, ensure_ascii=False, indent=2))
