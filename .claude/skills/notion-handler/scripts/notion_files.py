"""Notion file_upload helper - 노션 자체 storage에 파일 업로드.

Notion API의 file_upload 엔드포인트 (2024년 후반 도입) 사용.
무료 플랜: 5MB/장 제한.

사용:
    from notion_files import upload_file, files_property_value
    upload_id = upload_file("/path/to/img.jpg")
    prop_value = files_property_value(["/path/img1.jpg", "/path/img2.jpg"])
"""
import os, json, requests, mimetypes
from typing import List, Dict

NOTION_TOKEN = os.environ.get("NOTION_TOKEN")
HEADERS = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Notion-Version": "2022-06-28",
}


def create_upload(filename: str, content_type: str) -> Dict:
    r = requests.post(
        "https://api.notion.com/v1/file_uploads",
        headers={**HEADERS, "Content-Type": "application/json"},
        json={"mode": "single_part", "filename": filename, "content_type": content_type},
    )
    r.raise_for_status()
    return r.json()


def send_upload(upload_id: str, file_path: str) -> Dict:
    ct = mimetypes.guess_type(file_path)[0] or "application/octet-stream"
    with open(file_path, "rb") as f:
        files = {"file": (os.path.basename(file_path), f, ct)}
        r = requests.post(
            f"https://api.notion.com/v1/file_uploads/{upload_id}/send",
            headers=HEADERS,
            files=files,
        )
    r.raise_for_status()
    return r.json()


def upload_file(file_path: str) -> str:
    """파일 업로드 후 upload_id 반환."""
    fn = os.path.basename(file_path)
    ct = mimetypes.guess_type(file_path)[0] or "image/jpeg"
    up = create_upload(fn, ct)
    upload_id = up["id"]
    send_upload(upload_id, file_path)
    return upload_id


def files_property_value(file_paths: List[str]) -> Dict:
    """노션 files 속성 값 생성 (각 파일 업로드 후 reference 묶어서 반환)."""
    items = []
    for p in file_paths:
        uid = upload_file(p)
        items.append({
            "type": "file_upload",
            "file_upload": {"id": uid},
            "name": os.path.basename(p),
        })
    return {"files": items}


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("usage: python notion_files.py <file_path> [file_path...]")
        sys.exit(1)
    for p in sys.argv[1:]:
        uid = upload_file(p)
        print(f"{p} -> {uid}")
