#!/usr/bin/env python3
"""Build afi_corpus.json for offline AFI search from local Essential AFI PDFs."""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

try:
    from pypdf import PdfReader
except ImportError:
    print("Install pypdf: pip install pypdf", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "MyAFBase/MyAFBase/Resources/AFI/afi_corpus.json"

PUBLICATIONS = [
    {
        "id": "dress-appearance",
        "title": "Dress & Appearance",
        "publication": "DAFI 36-2903",
        "url": "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2903/dafi36-2903.pdf",
    },
    {
        "id": "afh1",
        "title": "The Air Force",
        "publication": "AFH 1 · Blue Book",
        "url": "https://static.e-publishing.af.mil/production/1/af_a1/publication/afh1/afh1.pdf",
    },
    {
        "id": "enlisted-force",
        "title": "Enlisted Force",
        "publication": "DAFI 36-2618",
        "url": "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2618/dafi36-2618.pdf",
    },
    {
        "id": "officer-pd",
        "title": "Officer Development",
        "publication": "DAFI 36-2643",
        "url": "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2643/dafi36-2643.pdf",
    },
    {
        "id": "fitness",
        "title": "Fitness Program",
        "publication": "DAFI 36-2905",
        "url": "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2905/dafi36-2905.pdf",
    },
    {
        "id": "decorations",
        "title": "Decorations",
        "publication": "DAFMAN 36-2806",
        "url": "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafman36-2806/dafman36-2806.pdf",
    },
    {
        "id": "leave",
        "title": "Military Leave",
        "publication": "DAFI 36-3003",
        "url": "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-3003/dafi36-3003.pdf",
    },
    {
        "id": "justice",
        "title": "Military Justice",
        "publication": "DAFI 51-201",
        "url": "https://static.e-publishing.af.mil/production/1/af_ja/publication/dafi51-201/dafi51-201.pdf",
    },
]

CHUNK_SIZE = 900
CHUNK_OVERLAP = 120
MIN_CHUNK_LENGTH = 60

# Table-of-contents dot leaders, e.g. "Figure 3.7. Shaving Waiver Example. ........ 22"
DOT_LEADER_RE = re.compile(r"\.{4,}")
# Running page headers/footers, e.g. "4 DAFI36-2903 29 FEBRUARY 2024" or
# "AFH 1, AIRMAN 15 February 2025 446"
HEADER_FOOTER_RE = re.compile(
    r"^\s*\d{0,4}\s*(?:DAFI|DAFMAN|DAFH|AFMAN|AFI|AFH|AFPD)\s*\d[\d\-. ]*.{0,40}?"
    r"(?:JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)"
    r"\s+\d{4}\s*\d{0,4}\s*$",
    re.IGNORECASE,
)
PAGE_NUMBER_LINE_RE = re.compile(r"^\s*\d{1,4}\s*$")
CHAPTER_RE = re.compile(r"^\s*Chapter\s+(\d{1,2})\s*[—–\-]?\s*(.*)$", re.IGNORECASE)
# Numbered AFI paragraph at the start of a chunk, e.g. "4.1.2." — how airmen cite AFIs.
# Figure/Table references ("Figure 3.6.") are excluded.
PARAGRAPH_REF_RE = re.compile(r"(?<!Figure )(?<!Table )\b(\d{1,2}(?:\.\d{1,3}){1,4})\.\s")


@dataclass
class Chunk:
    id: str
    publication_id: str
    publication: str
    title: str
    section: str | None
    page: int | None
    text: str

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "publication_id": self.publication_id,
            "publication": self.publication,
            "title": self.title,
            "section": self.section,
            "page": self.page,
            "text": self.text,
        }


def clean_text(text: str) -> str:
    text = text.replace("\x00", " ")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def title_case_heading(heading: str) -> str:
    # Body sentences that merely start with "Chapter N" sometimes sneak in;
    # drop URLs and anything after them.
    heading = re.split(r"https?://", heading)[0]
    heading = heading.strip(" .,—–-")
    # PDF extraction sometimes glues table headers onto chapter headings
    # (e.g. "DRESS AND APPEARANCE SSgt TSgt MSgt"). Cut at the first
    # mixed-case abbreviation such as a rank.
    abbrev = re.search(r"\b[A-Z]{2,}[a-z]+\b", heading)
    if abbrev:
        heading = heading[: abbrev.start()]
    heading = heading.strip(" .,—–-")
    if heading.isupper():
        heading = heading.title()
    return heading[:48].strip()


def clean_page(page_text: str) -> tuple[str, str | None]:
    """Remove TOC dot leaders, running headers/footers, and bare page numbers.

    Returns the cleaned page text plus the last chapter heading found on this page
    (used to carry the current chapter across pages).
    """
    kept_lines: list[str] = []
    chapter: str | None = None

    for raw_line in page_text.splitlines():
        line = re.sub(r"[ \t]+", " ", raw_line.replace("\x00", " ")).strip()
        if not line:
            kept_lines.append("")
            continue
        if DOT_LEADER_RE.search(line):
            continue
        if HEADER_FOOTER_RE.match(line):
            continue
        if PAGE_NUMBER_LINE_RE.match(line):
            continue

        chapter_match = CHAPTER_RE.match(line)
        if chapter_match:
            number, rest = chapter_match.groups()
            rest = title_case_heading(rest)
            chapter = f"Chapter {number}" + (f" — {rest}" if rest else "")
            chapter = chapter[:80]

        kept_lines.append(line)

    return clean_text("\n".join(kept_lines)), chapter


def alpha_ratio(text: str) -> float:
    if not text:
        return 0.0
    letters = sum(1 for ch in text if ch.isalpha() or ch.isspace())
    return letters / len(text)


def section_label(chapter: str | None, piece: str) -> str | None:
    """Combine the running chapter with the first cited paragraph number in the chunk."""
    paragraph = None
    match = PARAGRAPH_REF_RE.search(piece[:250])
    if match:
        paragraph = match.group(1)

    if chapter and paragraph:
        return f"{chapter} · Para {paragraph}"
    if chapter:
        return chapter
    if paragraph:
        return f"Para {paragraph}"
    return None


def chunk_page_text(
    page_text: str,
    publication: dict,
    page_number: int,
    chapter: str | None,
) -> list[Chunk]:
    text = page_text
    if len(text) < MIN_CHUNK_LENGTH:
        return []

    chunks: list[Chunk] = []
    start = 0
    local_index = 0

    while start < len(text):
        end = min(len(text), start + CHUNK_SIZE)
        if end < len(text):
            # Prefer breaking at a sentence boundary, falling back to a word boundary.
            sentence_break = text.rfind(". ", start + CHUNK_SIZE // 2, end)
            if sentence_break > start:
                end = sentence_break + 1
            else:
                break_at = text.rfind(" ", start + CHUNK_SIZE // 2, end)
                if break_at > start:
                    end = break_at

        piece = clean_text(text[start:end])
        if len(piece) >= MIN_CHUNK_LENGTH and alpha_ratio(piece) >= 0.6:
            chunk_id = f"{publication['id']}-p{page_number:04d}-{local_index:03d}"
            chunks.append(
                Chunk(
                    id=chunk_id,
                    publication_id=publication["id"],
                    publication=publication["publication"],
                    title=publication["title"],
                    section=section_label(chapter, piece),
                    page=page_number,
                    text=piece,
                )
            )
            local_index += 1

        if end >= len(text):
            break
        start = max(end - CHUNK_OVERLAP, start + 1)
        # Snap to the next word boundary so chunks never begin mid-word.
        if start > 0 and start < len(text) and not text[start - 1].isspace():
            next_space = text.find(" ", start)
            if next_space != -1 and next_space < end:
                start = next_space + 1

    return chunks


def extract_chunks(publication: dict, pdf_path: Path) -> list[Chunk]:
    reader = PdfReader(str(pdf_path))
    all_chunks: list[Chunk] = []
    current_chapter: str | None = None

    for page_idx, page in enumerate(reader.pages, start=1):
        try:
            page_text = page.extract_text() or ""
        except Exception as exc:  # noqa: BLE001
            print(f"  Skipping page {page_idx}: {exc}")
            continue

        cleaned, chapter = clean_page(page_text)
        if chapter:
            current_chapter = chapter
        all_chunks.extend(chunk_page_text(cleaned, publication, page_idx, current_chapter))

    return all_chunks


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Build afi_corpus.json from Essential AFI PDFs.")
    parser.add_argument(
        "--pdf-dir",
        type=Path,
        default=ROOT / "MyAFBase/MyAFBase/Resources/AFI/PDFs",
        help="Directory containing PDFs named by publication id (e.g. leave.pdf).",
    )
    args = parser.parse_args()

    cache_dir = args.pdf_dir
    all_chunks: list[Chunk] = []

    for publication in PUBLICATIONS:
        pdf_path = cache_dir / f"{publication['id']}.pdf"
        try:
            if not pdf_path.exists():
                print(f"Missing {pdf_path}", file=sys.stderr)
                print(
                    f"  Download from e-Publishing in your browser:\n  {publication['url']}",
                    file=sys.stderr,
                )
                continue
            pub_chunks = extract_chunks(publication, pdf_path)
            print(f"{publication['publication']}: {len(pub_chunks)} chunks")
            all_chunks.extend(pub_chunks)
        except Exception as exc:  # noqa: BLE001
            print(f"Failed {publication['publication']}: {exc}", file=sys.stderr)

    if not all_chunks:
        print("No chunks extracted.", file=sys.stderr)
        print(
            "\nManual setup:\n"
            "1. Open each URL below in a browser and save the PDF.\n"
            "2. Rename files to match publication id (e.g. leave.pdf, fitness.pdf).\n"
            f"3. Place them in: {cache_dir}\n"
            "4. Re-run this script.\n",
            file=sys.stderr,
        )
        for publication in PUBLICATIONS:
            print(f"  {publication['id']}.pdf  ←  {publication['url']}", file=sys.stderr)
        sys.exit(1)

    payload = {
        "version": datetime.now(timezone.utc).strftime("%Y.%m.%d.%H%M"),
        "dataUpdatedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "chunks": [chunk.to_dict() for chunk in all_chunks],
    }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {len(all_chunks)} chunks to {OUTPUT}")


if __name__ == "__main__":
    main()
