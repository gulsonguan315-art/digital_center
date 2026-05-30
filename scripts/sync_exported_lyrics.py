import os
import sys
import threading
import subprocess
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from tkinter.scrolledtext import ScrolledText

def embed_lrc_to_audio(audio_path, lrc_content):
    ext = os.path.splitext(audio_path)[1].lower()
    if ext == '.mp3':
        from mutagen.mp3 import MP3
        from mutagen.id3 import ID3, USLT
        audio = MP3(audio_path, ID3=ID3)
        try:
            audio.add_tags()
        except Exception:
            pass
        audio.tags.delall("USLT")
        audio.tags.add(USLT(encoding=3, lang='eng', desc='lyrics', text=lrc_content))
        audio.save()
    elif ext == '.flac':
        from mutagen.flac import FLAC
        audio = FLAC(audio_path)
        audio["lyrics"] = lrc_content
        audio.save()
    elif ext in ('.m4a', '.mp4'):
        from mutagen.mp4 import MP4
        audio = MP4(audio_path)
        audio["\xa9lyr"] = [lrc_content]
        audio.save()
    else:
        raise ValueError(f"Unsupported format: {ext}")

class SyncLyricsGui:
    def __init__(self, root):
        self.root = root
        self.root.title("🎶 App 歌词微调同步器 (Sync Lyrics to NAS)")
        self.root.geometry("750x550")
        
        self.style = ttk.Style()
        self.style.theme_use("vista" if os.name == "nt" else "clam")

        main_frame = ttk.Frame(self.root, padding="15")
        main_frame.pack(fill=tk.BOTH, expand=True)

        title_label = tk.Label(
            main_frame, text="App 导出歌词 -> 自动内嵌至 NAS 音乐库", 
            font=("Microsoft YaHei", 12, "bold"), fg="#2c3e50"
        )
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 15), sticky="w")

        # 1. 导出缓存目录选择
        ttk.Label(main_frame, text="1. App 导出的缓存目录 (exported_lyrics):").grid(row=1, column=0, sticky="w", pady=5)
        self.cache_entry = ttk.Entry(main_frame, width=45)
        self.cache_entry.grid(row=1, column=1, sticky="we", padx=10, pady=5)
        ttk.Button(main_frame, text="浏览...", command=self.browse_cache).grid(row=1, column=2, pady=5)

        # 2. NAS 映射盘符选择
        ttk.Label(main_frame, text="2. NAS 音乐库映射目录 (例如 Z:\\):").grid(row=2, column=0, sticky="w", pady=5)
        self.nas_entry = ttk.Entry(main_frame, width=45)
        self.nas_entry.grid(row=2, column=1, sticky="we", padx=10, pady=5)
        ttk.Button(main_frame, text="浏览...", command=self.browse_nas).grid(row=2, column=2, pady=5)

        # 执行按钮
        self.run_btn = tk.Button(
            main_frame, text="🚀 立即内嵌同步所有歌词并清理缓存", font=("Microsoft YaHei", 10, "bold"),
            bg="#27ae60", fg="white", activebackground="#2ecc71", height=2,
            command=self.start_sync
        )
        self.run_btn.grid(row=3, column=0, columnspan=3, sticky="we", pady=(15, 15))

        # 日志
        self.log_text = ScrolledText(main_frame, height=12, font=("Consolas", 9), bg="#2c3e50", fg="#ecf0f1")
        self.log_text.grid(row=4, column=0, columnspan=3, sticky="nsew")
        self.log_text.insert(tk.END, "[READY] 请配置上述两个目录后点击同步按钮。\n")
        self.log_text.configure(state=tk.DISABLED)

        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(4, weight=1)

    def browse_cache(self):
        d = filedialog.askdirectory(title="选择 exported_lyrics 文件夹")
        if d:
            self.cache_entry.delete(0, tk.END)
            self.cache_entry.insert(0, os.path.normpath(d))

    def browse_nas(self):
        d = filedialog.askdirectory(title="选择 NAS 音乐库映射根目录")
        if d:
            self.nas_entry.delete(0, tk.END)
            self.nas_entry.insert(0, os.path.normpath(d))

    def log(self, message):
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.insert(tk.END, message)
        self.log_text.see(tk.END)
        self.log_text.configure(state=tk.DISABLED)

    def start_sync(self):
        cache_dir = self.cache_entry.get().strip()
        nas_dir = self.nas_entry.get().strip()

        if not os.path.exists(cache_dir):
            messagebox.showerror("错误", "缓存目录不存在！")
            return
        if not os.path.exists(nas_dir):
            messagebox.showerror("错误", "NAS目录不存在！")
            return

        self.run_btn.configure(state=tk.DISABLED, bg="#95a5a6", text="正在同步内嵌中...")
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.delete(1.0, tk.END)
        self.log_text.configure(state=tk.DISABLED)

        threading.Thread(target=self.sync_worker, args=(cache_dir, nas_dir), daemon=True).start()

    def sync_worker(self, cache_dir, nas_dir):
        try:
            import mutagen
        except ImportError:
            self.root.after(0, lambda: messagebox.showerror("缺少依赖", "请先在终端运行: pip install mutagen"))
            self.root.after(0, lambda: self.run_btn.configure(state=tk.NORMAL, bg="#27ae60", text="🚀 立即内嵌同步所有歌词并清理缓存"))
            return

        success_count = 0
        error_count = 0

        # 遍历缓存中所有的 .lrc 文件
        for root, _, files in os.walk(cache_dir):
            for f in files:
                if f.lower().endswith('.lrc'):
                    lrc_cache_path = os.path.join(root, f)
                    
                    # 剥离 cache_dir 前缀，获得形如: 周杰伦/七里香/七里香.lrc 的相对路径
                    rel_path = os.path.relpath(lrc_cache_path, cache_dir)
                    
                    # 在 NAS 里寻找同名的音频文件 (.mp3, .flac, .m4a)
                    base_rel_path, _ = os.path.splitext(rel_path)
                    
                    found_audio = False
                    for ext in ('.mp3', '.flac', '.m4a', '.mp4'):
                        nas_audio_path = os.path.join(nas_dir, base_rel_path + ext)
                        if os.path.exists(nas_audio_path):
                            found_audio = True
                            self.log(f"[SYNC] 找到目标音频文件: {os.path.basename(nas_audio_path)}\n")
                            try:
                                # 读出歌词
                                with open(lrc_cache_path, 'r', encoding='utf-8') as lf:
                                    lrc_content = lf.read()
                                
                                # 内嵌
                                embed_lrc_to_audio(nas_audio_path, lrc_content)
                                self.log(f"   └─ 成功内嵌歌词并保存！\n")
                                
                                # 强制更新 NAS 文件的修改时间，触发 Gonic 扫描
                                import time
                                now = time.time()
                                os.utime(nas_audio_path, (now, now))

                                # 同步成功后，删除缓存里的 .lrc 文件
                                os.remove(lrc_cache_path)
                                success_count += 1
                            except Exception as e:
                                self.log(f"   └─ ❌ 内嵌失败: {e}\n")
                                error_count += 1
                            break
                    
                    if not found_audio:
                        self.log(f"[SKIP] 未在 NAS 中找到对应的音频文件: {rel_path}\n")
                        error_count += 1

        self.log(f"\n[FINISH] 同步完毕！成功: {success_count} 首, 失败/跳过: {error_count} 首。\n")
        
        # 清理 App 本地歌词缓存 (解决因文件 Size 不变导致哈希不变，App 无法刷新歌词的问题)
        music_cache_dir = os.path.dirname(cache_dir)
        if os.path.basename(cache_dir) == "exported_lyrics" and os.path.exists(music_cache_dir):
            count = 0
            for f in os.listdir(music_cache_dir):
                if f.startswith("lyrics_") and f.endswith(".json"):
                    try:
                        os.remove(os.path.join(music_cache_dir, f))
                        count += 1
                    except Exception:
                        pass
            if count > 0:
                self.log(f"[CLEANUP] 成功清理 {count} 个 App 旧歌词缓存。切歌即可拉取最新内嵌歌词！\n")

        # 尝试触发 Gonic
        if success_count > 0:
            self.trigger_gonic_scan()

        self.root.after(0, lambda: self.run_btn.configure(state=tk.NORMAL, bg="#27ae60", text="🚀 立即内嵌同步所有歌词并清理缓存"))
        self.root.after(0, lambda: messagebox.showinfo("完成", f"同步完成！\n成功: {success_count}\n异常: {error_count}"))

    def trigger_gonic_scan(self):
        import urllib.request
        import hashlib
        import json
        import random
        import string
        
        gonic_url = "http://192.168.0.2:4747/rest"
        u = "gulson"
        p = "a130s339"
        
        salt = "".join(random.choices(string.ascii_letters + string.digits, k=10))
        token = hashlib.md5((p + salt).encode('utf-8')).hexdigest()
        auth_params = f"u={u}&t={token}&s={salt}&v=1.16.1&c=gui_sync&f=json"
        
        try:
            url = f"{gonic_url}/startScan.view?{auth_params}"
            with urllib.request.urlopen(url, timeout=5) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                status = data.get('subsonic-response', {}).get('status', 'failed')
                self.log(f"[GONIC] 触发扫描状态: {status}\n")
        except Exception as e:
            self.log(f"[GONIC] 触发扫描失败: {e}\n")

if __name__ == "__main__":
    root = tk.Tk()
    app = SyncLyricsGui(root)
    root.mainloop()
