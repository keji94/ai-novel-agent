#!/usr/bin/env python3
"""
三江速评数据采集工具
从起点图(qidiantu.com)获取三江推荐书单，通过起点中文网移动版采集章节内容，缓存到本地JSON文件。

用法:
    python sanjiang.py fetch-cache [--max-chapters N]   # 触发异步采集
    python sanjiang.py task-status <taskId>               # 查询任务状态
    python sanjiang.py books [--book-name NAME] [--date DATE]  # 查询书籍列表
    python sanjiang.py book --book-name NAME [--author-name AUTHOR]  # 获取书籍详情
"""

import argparse
import json
import logging
import os
import re
import subprocess
import sys
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.parse import quote

# Fix Windows terminal encoding: default stdout/stderr use GBK which garbles Chinese
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("需要安装依赖: pip install requests beautifulsoup4", file=sys.stderr)
    sys.exit(1)

# ============================================================
# Configuration
# ============================================================

SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
DATA_DIR = Path(os.environ.get("SANJIANG_DATA_DIR", PROJECT_ROOT / "cache" / "sanjiang"))
BOOKS_DIR = DATA_DIR / "books"
TASKS_DIR = DATA_DIR / "tasks"
BOOK_INDEX_FILE = DATA_DIR / "book_index.json"

QIDIAN_MOBILE_BOOK_URL = "https://m.qidian.com/book/{book_id}/"
QIDIAN_MOBILE_CATALOG_URL = "https://m.qidian.com/book/{book_id}/catalog/"
QIDIAN_MOBILE_CHAPTER_URL = "https://m.qidian.com/chapter/{book_id}/{chapter_id}/"
QIDIAN_TU_URL = "https://www.qidiantu.com/bang/1/6/{date}"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Cache-Control": "max-age=0",
    "sec-ch-ua": '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": '"Windows"',
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
}

QIDIAN_MOBILE_HEADERS = {
    "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
                  "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 "
                  "Mobile/15E148 Safari/604.1",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "zh-CN,zh;q=0.9",
    "Accept-Encoding": "gzip, deflate",
}

CONCURRENT_CHAPTERS = 1
BATCH_DELAY_SEC = 3.0
BOOK_DELAY_SEC = 5.0
REQUEST_TIMEOUT = 15
PAID_CONTENT_MIN_LEN = 500
MAX_RETRIES = 3

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
    stream=sys.stderr,
)
log = logging.getLogger("sanjiang")

# ============================================================
# Utility
# ============================================================


def get_monday(d: Optional[date] = None) -> date:
    if d is None:
        d = date.today()
    return d - timedelta(days=d.weekday())


def get_latest_sunday(d: Optional[date] = None) -> date:
    """获取最近一个周日（三江榜按周日发布）。
    如果今天就是周日，返回今天；否则返回上一个周日。
    """
    if d is None:
        d = date.today()
    return d - timedelta(days=(d.weekday() + 1) % 7)


def json_dumps(obj: Any) -> str:
    return json.dumps(obj, ensure_ascii=False, indent=2)


def output_json(obj: dict):
    print(json_dumps(obj))


# ============================================================
# HTTP Client
# ============================================================

_session = requests.Session()
_session.headers.update(HEADERS)


def http_get(url: str, timeout: int = REQUEST_TIMEOUT) -> Optional[str]:
    try:
        resp = _session.get(url, timeout=timeout)
        resp.raise_for_status()
        resp.encoding = resp.apparent_encoding or "utf-8"
        return resp.text
    except Exception as e:
        log.warning("HTTP GET 失败: %s - %s", url, e)
        return None


_mobile_session = requests.Session()
_mobile_session.headers.update(QIDIAN_MOBILE_HEADERS)


def http_get_mobile(url: str, timeout: int = REQUEST_TIMEOUT, retries: int = MAX_RETRIES) -> Optional[str]:
    """请求起点移动版（使用 iPhone UA），带指数退避重试"""
    for attempt in range(retries + 1):
        try:
            resp = _mobile_session.get(url, timeout=timeout)
            if resp.status_code == 403:
                if attempt < retries:
                    wait = 5 * (attempt + 1) + 3
                    log.info("403 触发限流，等待 %ds 后重试: %s", wait, url)
                    time.sleep(wait)
                    # 重建 session 清除 cookies
                    _mobile_session.cookies.clear()
                    continue
                log.warning("HTTP GET(mobile) 403: %s (已重试 %d 次)", url, retries)
                return None
            resp.raise_for_status()
            resp.encoding = resp.apparent_encoding or "utf-8"
            return resp.text
        except requests.exceptions.ConnectionError as e:
            if attempt < retries:
                wait = 5 * (attempt + 1)
                log.info("连接断开，等待 %ds 后重试: %s", wait, url)
                time.sleep(wait)
                continue
            log.warning("HTTP GET(mobile) 连接失败: %s - %s", url, e)
            return None
        except Exception as e:
            if attempt < retries:
                time.sleep(2 * (attempt + 1))
                continue
            log.warning("HTTP GET(mobile) 失败: %s - %s", url, e)
            return None


# ============================================================
# Qidian Mobile Parser (起点中文网移动版)
# ============================================================


class QidianMobileParser:
    """起点中文网移动版 (m.qidian.com) 解析器

    特点：服务端渲染，无需登录，包含完整章节目录和免费章节内容。
    """

    @staticmethod
    def parse_book_info(html: str) -> Dict:
        """解析书籍详情页，提取基本信息"""
        soup = BeautifulSoup(html, "html.parser")
        title = soup.title.string.split("(")[0].strip() if soup.title else ""
        # 从 title 提取书名和作者
        m = re.match(r"(.+?)\((.+?)\)", soup.title.string) if soup.title else None
        book_name = m.group(1).strip() if m else title
        author = m.group(2).strip() if m else ""

        description = ""
        intro_el = soup.select_one(".book-intro") or soup.select_one(".intro")
        if intro_el:
            description = f"简介：\n{intro_el.get_text(strip=True)}"

        cover_url = ""
        img = soup.select_one(".book-cover img") or soup.select_one(".detail__img img")
        if img:
            cover_url = img.get("src") or img.get("data-src", "")

        return {
            "title": book_name,
            "author": author,
            "description": description,
            "coverUrl": cover_url,
        }

    @staticmethod
    def parse_catalog(html: str) -> List[Dict]:
        """解析目录页，提取章节列表

        数据来源：服务端渲染的 JSON（vite-plugin-ssr_pageContext）
        返回: [{"id": chapter_id, "name": chapter_name, "wordCount": cnt, "uuid": uuid}, ...]
        """
        if not html:
            return []

        # 从服务端渲染的 JSON 中提取章节数据
        # 使用括号计数提取完整 JSON（避免 .*? 非贪婪匹配截断）
        marker = '{"pageContext":'
        idx = html.find(marker)
        if idx < 0:
            log.warning("目录页未找到 pageContext JSON")
            return []

        # 括号计数找到完整 JSON
        depth = 0
        end = idx
        for i in range(idx, min(idx + 100000, len(html))):
            if html[i] == '{':
                depth += 1
            elif html[i] == '}':
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
        else:
            log.warning("目录页 JSON 括号未闭合")
            return []

        raw = html[idx:end]
        try:
            data = json.loads(raw)
        except json.JSONDecodeError as e:
            log.warning("目录页 JSON 解析失败: %s", e)
            return []

        page_data = data.get("pageContext", {}).get("pageProps", {}).get("pageData", {})
        if not page_data:
            log.warning("目录页 pageData 为空")
            return []

        chapters = []
        for vs_block in page_data.get("vs", []):
            for ch in vs_block.get("cs", []):
                chapters.append({
                    "id": ch.get("id"),
                    "name": ch.get("cN", ""),
                    "wordCount": ch.get("cnt", 0),
                    "uuid": ch.get("uuid"),
                })

        log.info("解析到 %d 个章节", len(chapters))
        return chapters

    @staticmethod
    def parse_chapter_content(html: str) -> Optional[str]:
        """解析章节内容页，提取正文文本"""
        if not html:
            return None

        soup = BeautifulSoup(html, "html.parser")

        # 起点移动版正文容器
        content_el = None
        for sel in [
            ".j_readContent",
            ".read-content",
            ".content",
            ".chapter-content",
            ".chapter-wrapper",
        ]:
            content_el = soup.select_one(sel)
            if content_el:
                break

        if not content_el:
            log.warning("章节页未找到正文容器")
            return None

        paragraphs = content_el.select("p")
        if not paragraphs:
            text = content_el.get_text(strip=True)
            return text if len(text) >= PAID_CONTENT_MIN_LEN else None

        content = "\n\n".join(
            p.get_text(strip=True) for p in paragraphs if p.get_text(strip=True)
        )
        return content if len(content) >= PAID_CONTENT_MIN_LEN else None


# ============================================================
# SanJiang Web Parser
# ============================================================


class SanJiangParser:
    """起点图(qidiantu.com) 三江推荐页面解析器"""

    @staticmethod
    def parse_book_list(html: str) -> List[Dict]:
        if not html:
            return []
        soup = BeautifulSoup(html, "html.parser")
        table = soup.select_one("#shoucang_table")
        if not table:
            log.warning("未找到 #shoucang_table")
            return []

        books = []
        for row in table.select("tbody tr"):
            book = SanJiangParser._parse_row(row)
            if book:
                books.append(book)

        log.info("解析到 %d 本三江推荐书籍", len(books))
        return books

    @staticmethod
    def _parse_row(row) -> Optional[Dict]:
        tds = row.select("td")
        if len(tds) < 9:
            return None

        ranking = SanJiangParser._to_int(tds[0].get_text(strip=True))
        category = tds[1].get_text(strip=True)

        book_link = tds[2].select_one("a")
        book_name = book_link.get_text(strip=True) if book_link else tds[2].get_text(strip=True)
        book_url = book_link.get("href") if book_link else None

        author_link = tds[3].select_one("a")
        author_name = author_link.get_text(strip=True) if author_link else tds[3].get_text(strip=True)

        level = tds[4].get_text(strip=True)
        initial_words = SanJiangParser._parse_value(tds[5])
        word_increment = SanJiangParser._parse_value(tds[6])
        initial_fav = SanJiangParser._parse_value(tds[7])
        fav_increment = SanJiangParser._parse_value(tds[8])

        daily_fav = []
        for i in range(9, min(16, len(tds))):
            daily_fav.append(SanJiangParser._parse_value(tds[i]) or 0)

        return {
            "ranking": ranking,
            "bookName": book_name,
            "bookDetailUrl": book_url,
            "authorName": author_name,
            "level": level,
            "category": category,
            "initialWordCount": initial_words,
            "wordCountIncrement": word_increment,
            "initialFavoriteCount": initial_fav,
            "favoriteCountIncrement": fav_increment,
            "dailyFavoriteIncrements": daily_fav,
        }

    @staticmethod
    def _parse_value(td) -> Optional[int]:
        val = td.get("value")
        if val:
            try:
                return int(val)
            except ValueError:
                pass
        return None

    @staticmethod
    def _to_int(text: str) -> Optional[int]:
        try:
            return int(text.strip())
        except (ValueError, AttributeError):
            return None


# ============================================================
# Novel Fetcher
# ============================================================


class NovelFetcher:
    """小说内容获取器：通过起点移动版获取章节内容

    流程：从起点图获取 bookId → 获取移动版目录页 → 提取章节列表 → 并发获取免费章节内容
    """

    @staticmethod
    def _extract_book_id(book_detail_url: str) -> Optional[str]:
        """从起点图的书籍链接提取 bookId
        格式: /info/1044155341 或 /info/1044155341/d
        """
        if not book_detail_url:
            return None
        m = re.search(r'/info/(\d+)', book_detail_url)
        return m.group(1) if m else None

    @staticmethod
    def fetch_novel(
        novel_name: str,
        author_name: str = "",
        max_chapters: int = 0,
        detail_url: str = "",
    ) -> Optional[Dict]:
        """获取小说详情和章节内容

        Args:
            novel_name: 书名
            author_name: 作者名
            max_chapters: 最大章节数，0=全部免费章节
            detail_url: 起点图书籍链接（包含 bookId）
        """
        # 提取 bookId
        book_id = NovelFetcher._extract_book_id(detail_url)
        if not book_id:
            log.warning("无法从链接提取 bookId: %s", detail_url)
            return None

        # 获取基本信息
        book_url = QIDIAN_MOBILE_BOOK_URL.format(book_id=book_id)
        book_html = http_get_mobile(book_url)
        if not book_html:
            log.warning("无法访问起点移动版书籍页: %s", book_url)
            return None

        basic_info = QidianMobileParser.parse_book_info(book_html)

        # 获取章节目录
        catalog_url = QIDIAN_MOBILE_CATALOG_URL.format(book_id=book_id)
        catalog_html = http_get_mobile(catalog_url)
        if not catalog_html:
            log.warning("无法访问起点移动版目录页: %s", catalog_url)
            return None

        all_chapters = QidianMobileParser.parse_catalog(catalog_html)
        if not all_chapters:
            log.warning("未获取到任何章节: %s", novel_name)
            return None

        # 限制章节数
        target = all_chapters
        if max_chapters and max_chapters > 0 and len(all_chapters) > max_chapters:
            target = all_chapters[:max_chapters]
            log.info("限制获取前 %d 章（共 %d 章）", max_chapters, len(all_chapters))

        # 并发获取章节内容
        chapters = NovelFetcher._fetch_chapters_concurrently(book_id, target)

        if not chapters:
            log.warning("未获取到任何章节内容: %s", novel_name)
            return None

        total_words = sum(len(ch.get("content", "")) for ch in chapters)

        return {
            "bookName": basic_info.get("title") or novel_name,
            "authorName": basic_info.get("author") or author_name,
            "description": basic_info.get("description", ""),
            "coverUrl": basic_info.get("coverUrl", ""),
            "chapterCount": len(chapters),
            "totalWords": total_words,
            "chapters": chapters,
        }

    @staticmethod
    def _fetch_chapters_concurrently(book_id: str, chapter_metas: List[Dict]) -> List[Dict]:
        """串行获取章节内容（避免触发起点限流）"""
        results: List[Dict] = []
        for i, meta in enumerate(chapter_metas):
            try:
                ch = NovelFetcher._fetch_single_chapter(book_id, meta)
                if ch:
                    results.append(ch)
            except Exception as e:
                log.warning("获取章节失败: %s - %s", meta.get("name"), e)
            # 章节之间延迟
            if i < len(chapter_metas) - 1:
                time.sleep(BATCH_DELAY_SEC)

        results.sort(key=lambda x: x["index"])
        return results

    @staticmethod
    def _fetch_single_chapter(book_id: str, meta: Dict) -> Optional[Dict]:
        chapter_id = meta.get("id")
        if not chapter_id:
            return None

        url = QIDIAN_MOBILE_CHAPTER_URL.format(book_id=book_id, chapter_id=chapter_id)
        html = http_get_mobile(url)
        if not html:
            return None

        content = QidianMobileParser.parse_chapter_content(html)
        if not content:
            return None

        return {
            "index": meta.get("uuid", 0),
            "title": meta.get("name", ""),
            "content": content,
        }


# ============================================================
# Cache Manager
# ============================================================


class CacheManager:
    """书籍缓存管理器（JSON 文件存储）"""

    def __init__(self):
        BOOKS_DIR.mkdir(parents=True, exist_ok=True)

    def _book_filename(self, book_name: str, author_name: str, report_date: str) -> str:
        safe = re.sub(r'[\\/:*?"<>|]', "_", f"{book_name}_{author_name}_{report_date}")
        return f"{safe}.json"

    def save_book(self, book_data: Dict, report_date: str, extra: Dict = None) -> Dict:
        filename = self._book_filename(
            book_data["bookName"], book_data["authorName"], report_date
        )
        filepath = BOOKS_DIR / filename

        cache_entry = {
            "bookName": book_data["bookName"],
            "authorName": book_data["authorName"],
            "authorLevel": (extra or {}).get("authorLevel", ""),
            "category": (extra or {}).get("category", book_data.get("category", "")),
            "description": book_data.get("description", ""),
            "coverUrl": book_data.get("coverUrl", ""),
            "detailUrl": (extra or {}).get("detailUrl", ""),
            "chapterCount": book_data.get("chapterCount", 0),
            "totalWords": book_data.get("totalWords", 0),
            "reportDate": report_date,
            "createdAt": datetime.now().isoformat(),
            "chapters": book_data.get("chapters", []),
        }
        filepath.write_text(json_dumps(cache_entry), encoding="utf-8")
        self._update_index(cache_entry, filename)
        log.info("缓存保存: %s → %s", book_data["bookName"], filepath.name)
        return cache_entry

    def _update_index(self, entry: Dict, filename: str):
        index = self._load_index()
        report_date = entry["reportDate"]
        if report_date not in index:
            index[report_date] = []

        simple = self._to_simple_info(entry, filename)
        for i, item in enumerate(index[report_date]):
            if (
                item["bookName"] == entry["bookName"]
                and item["authorName"] == entry["authorName"]
            ):
                index[report_date][i] = simple
                break
        else:
            index[report_date].append(simple)

        BOOK_INDEX_FILE.parent.mkdir(parents=True, exist_ok=True)
        BOOK_INDEX_FILE.write_text(json_dumps(index), encoding="utf-8")

    @staticmethod
    def _to_simple_info(entry: Dict, filename: str) -> Dict:
        return {
            "bookName": entry["bookName"],
            "authorName": entry["authorName"],
            "authorLevel": entry.get("authorLevel", ""),
            "category": entry.get("category", ""),
            "description": entry.get("description", ""),
            "coverUrl": entry.get("coverUrl", ""),
            "detailUrl": entry.get("detailUrl", ""),
            "chapterCount": entry.get("chapterCount", 0),
            "totalWords": entry.get("totalWords", 0),
            "reportDate": entry["reportDate"],
            "createdAt": entry.get("createdAt", ""),
            "_fileName": filename,
        }

    @staticmethod
    def _load_index() -> Dict:
        if BOOK_INDEX_FILE.exists():
            return json.loads(BOOK_INDEX_FILE.read_text(encoding="utf-8"))
        return {}

    def get_books_by_date(self, report_date: str) -> List[Dict]:
        return self._load_index().get(report_date, [])

    def search_books(self, book_name: str) -> List[Dict]:
        index = self._load_index()
        results = []
        for books in index.values():
            for book in books:
                if book_name.lower() in book["bookName"].lower():
                    results.append(book)
        return results

    def get_all_latest_books(self) -> List[Dict]:
        index = self._load_index()
        if not index:
            return []
        latest_date = max(index.keys())
        return index[latest_date]

    def get_book_detail(
        self, book_name: str, author_name: str = ""
    ) -> Optional[Dict]:
        index = self._load_index()

        # 精确匹配
        for books in index.values():
            for book in books:
                if book["bookName"] == book_name:
                    if not author_name or book["authorName"] == author_name:
                        return self._load_book_file(book.get("_fileName", ""))

        # 模糊匹配（仅书名）
        if not author_name:
            for books in index.values():
                for book in books:
                    if book_name.lower() in book["bookName"].lower():
                        return self._load_book_file(book.get("_fileName", ""))

        return None

    def book_exists(self, book_name: str, author_name: str, report_date: str) -> bool:
        filename = self._book_filename(book_name, author_name, report_date)
        return (BOOKS_DIR / filename).exists()

    @staticmethod
    def _load_book_file(filename: str) -> Optional[Dict]:
        if not filename:
            return None
        filepath = BOOKS_DIR / filename
        if filepath.exists():
            return json.loads(filepath.read_text(encoding="utf-8"))
        return None


# ============================================================
# Task Manager
# ============================================================


class TaskManager:
    """任务状态管理器（JSON 文件存储）"""

    def __init__(self):
        TASKS_DIR.mkdir(parents=True, exist_ok=True)

    def create_task(self, report_date: str, max_chapter_count: int) -> str:
        task_id = uuid.uuid4().hex[:16]
        task = {
            "taskId": task_id,
            "taskType": "FETCH_AND_CACHE",
            "state": "PENDING",
            "reportDate": report_date,
            "maxChapterCount": max_chapter_count,
            "totalBooks": 0,
            "processedBooks": 0,
            "successCount": 0,
            "failedCount": 0,
            "currentBookName": None,
            "errorMessage": None,
            "createdAt": datetime.now().isoformat(),
            "startedAt": None,
            "completedAt": None,
        }
        self._save_task(task)
        return task_id

    def get_task(self, task_id: str) -> Optional[Dict]:
        filepath = TASKS_DIR / f"{task_id}.json"
        if filepath.exists():
            return json.loads(filepath.read_text(encoding="utf-8"))
        return None

    def update_task(self, task_id: str, **updates):
        task = self.get_task(task_id)
        if not task:
            return
        task.update(updates)
        self._save_task(task)

    @staticmethod
    def _save_task(task: Dict):
        filepath = TASKS_DIR / f"{task['taskId']}.json"
        filepath.write_text(json_dumps(task), encoding="utf-8")


# ============================================================
# Core: Fetch & Cache
# ============================================================


def execute_fetch_and_cache(task_id: str, report_date: str, max_chapters: int):
    tm = TaskManager()
    cm = CacheManager()

    tm.update_task(task_id, state="RUNNING", startedAt=datetime.now().isoformat())

    try:
        log.info("[Task-%s] 从起点图获取三江书籍列表", task_id)
        url = QIDIAN_TU_URL.format(date=report_date)
        html = http_get(url)

        if not html:
            tm.update_task(
                task_id, state="FAILED",
                errorMessage="无法访问起点图网站",
                completedAt=datetime.now().isoformat(),
            )
            return

        book_infos = SanJiangParser.parse_book_list(html)
        if not book_infos:
            tm.update_task(
                task_id, state="FAILED",
                errorMessage="未获取到任何书籍信息（可能不是周一发布日）",
                completedAt=datetime.now().isoformat(),
            )
            return

        tm.update_task(task_id, totalBooks=len(book_infos))
        log.info("[Task-%s] 获取到 %d 本书籍", task_id, len(book_infos))

        success_count = 0
        failed_count = 0

        for i, info in enumerate(book_infos):
            book_name = info["bookName"]
            tm.update_task(task_id, processedBooks=i, currentBookName=book_name)
            log.info("[Task-%s] [%d/%d] %s", task_id, i + 1, len(book_infos), book_name)

            if cm.book_exists(book_name, info["authorName"], report_date):
                log.info("[Task-%s] 已缓存，跳过: %s", task_id, book_name)
                success_count += 1
                tm.update_task(task_id, successCount=success_count)
                continue

            try:
                novel = NovelFetcher.fetch_novel(
                    novel_name=book_name,
                    author_name=info["authorName"],
                    max_chapters=max_chapters,
                    detail_url=info.get("bookDetailUrl", ""),
                )
                if novel:
                    cm.save_book(novel, report_date, extra={
                        "authorLevel": info.get("level", ""),
                        "category": info.get("category", ""),
                        "detailUrl": info.get("bookDetailUrl", ""),
                    })
                    success_count += 1
                    log.info(
                        "[Task-%s] 成功: %s (%d章, %d字)",
                        task_id, book_name, novel.get("chapterCount", 0),
                        novel.get("totalWords", 0),
                    )
                else:
                    failed_count += 1
                    log.warning("[Task-%s] 失败: %s", task_id, book_name)
            except Exception as e:
                failed_count += 1
                log.error("[Task-%s] 异常: %s - %s", task_id, book_name, e)

            # 书籍之间延迟，避免触发起点限流
            if i < len(book_infos) - 1:
                time.sleep(BOOK_DELAY_SEC)

            tm.update_task(task_id, successCount=success_count, failedCount=failed_count)

        tm.update_task(
            task_id,
            state="COMPLETED",
            processedBooks=len(book_infos),
            currentBookName=None,
            completedAt=datetime.now().isoformat(),
        )
        log.info("[Task-%s] 完成: 成功=%d, 失败=%d", task_id, success_count, failed_count)

    except Exception as e:
        log.error("[Task-%s] 执行失败: %s", task_id, e)
        tm.update_task(
            task_id, state="FAILED", errorMessage=str(e),
            completedAt=datetime.now().isoformat(),
        )


# ============================================================
# CLI Commands
# ============================================================


def cmd_fetch_cache(args):
    if args.date:
        report_date = args.date
    else:
        report_date = get_latest_sunday().isoformat()
    max_chapters = args.max_chapters if args.max_chapters != 0 else 0

    tm = TaskManager()
    task_id = tm.create_task(report_date, max_chapters or 20)

    log_file = TASKS_DIR / f"{task_id}.log"
    script_path = str(Path(__file__).absolute())
    worker_cmd = [sys.executable, script_path, "_worker", task_id, report_date, str(max_chapters or 20)]

    try:
        with open(log_file, "w") as f:
            kwargs = {}
            if os.name == "nt":
                kwargs["creationflags"] = subprocess.DETACHED_PROCESS | subprocess.CREATE_NO_WINDOW
            else:
                kwargs["start_new_session"] = True

            subprocess.Popen(
                worker_cmd,
                stdout=f,
                stderr=subprocess.STDOUT,
                **kwargs,
            )
        log.info("后台任务已启动: %s (日志: %s)", task_id, log_file)
    except Exception as e:
        log.warning("无法启动后台进程: %s，回退到线程模式", e)
        t = threading.Thread(
            target=execute_fetch_and_cache,
            args=(task_id, report_date, max_chapters or 20),
            daemon=True,
        )
        t.start()

    output_json({
        "success": True,
        "message": "任务已创建，请通过taskId查询执行状态",
        "taskId": task_id,
        "reportDate": report_date,
        "maxChapterCount": max_chapters or 20,
    })


def cmd_task_status(args):
    tm = TaskManager()
    task = tm.get_task(args.task_id)

    if not task:
        output_json({"success": False, "message": "任务不存在"})
        return

    output_json({"success": True, **task})


def cmd_books(args):
    cm = CacheManager()

    if args.book_name:
        books = cm.search_books(args.book_name)
    elif args.date:
        books = cm.get_books_by_date(args.date)
    else:
        books = cm.get_all_latest_books()

    for b in books:
        b.pop("_fileName", None)

    output_json({"success": True, "total": len(books), "books": books})


def cmd_book(args):
    cm = CacheManager()
    book = cm.get_book_detail(args.book_name, args.author_name or "")

    if not book:
        output_json({
            "success": False,
            "message": "未找到书籍缓存",
            "bookName": args.book_name,
        })
        return

    output_json({"success": True, **book})


def cmd_worker(args):
    """内部命令：后台采集 worker"""
    execute_fetch_and_cache(args.task_id, args.report_date, int(args.max_chapters))


# ============================================================
# Main
# ============================================================


def main():
    parser = argparse.ArgumentParser(
        description="三江速评数据采集工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command")

    # fetch-cache
    p = sub.add_parser("fetch-cache", help="触发异步获取三江书单")
    p.add_argument(
        "--max-chapters", type=int, default=20,
        help="最大章节数，0=全部免费章节 (默认: 20)",
    )
    p.add_argument("--date", help="指定日期 (YYYY-MM-DD)，默认自动获取最近周日")
    p.set_defaults(func=cmd_fetch_cache)

    # task-status
    p = sub.add_parser("task-status", help="查询任务状态")
    p.add_argument("task_id", help="任务ID")
    p.set_defaults(func=cmd_task_status)

    # books
    p = sub.add_parser("books", help="查询书籍列表")
    p.add_argument("--book-name", help="书名（模糊匹配）")
    p.add_argument("--date", help="日期 (YYYY-MM-DD)")
    p.set_defaults(func=cmd_books)

    # book
    p = sub.add_parser("book", help="获取书籍详情")
    p.add_argument("--book-name", required=True, help="书名")
    p.add_argument("--author-name", help="作者名")
    p.set_defaults(func=cmd_book)

    # _worker (内部命令，不显示在帮助中)
    p = sub.add_parser("_worker", help=argparse.SUPPRESS)
    p.add_argument("task_id")
    p.add_argument("report_date")
    p.add_argument("max_chapters")
    p.set_defaults(func=cmd_worker)

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    args.func(args)


if __name__ == "__main__":
    main()
