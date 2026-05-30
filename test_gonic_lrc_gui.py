import os
import sys
import threading
import subprocess
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from tkinter.scrolledtext import ScrolledText

# 伪造的测试歌词，强制使用 3 位毫秒格式 [mm:ss.xxx]
# 并且模拟了一段“纯音乐”的歌词内容，方便你测试 Gonic 的读取表现
FAKE_LRC_CONTENT = """[00:00.000] 这是伪造的纯音乐测试歌词
[00:02.500] 专门用于测试 Gonic 是否识别 3 位毫秒格式
[00:05.250] 🎵 (Music Playing)
[00:10.125] 🎵 (Instrumental)
[00:15.550] 测试结束
"""

def strip_embedded_lyrics(audio_path):
    """
    清除音频文件中内嵌的歌词元数据，确保 Gonic 只能读取外置的 .lrc 文件
    """
    ext = os.path.splitext(audio_path)[1].lower()
    changed = False

    if ext == '.mp3':
        from mutagen.mp3 import MP3
        from mutagen.id3 import ID3
        audio = MP3(audio_path, ID3=ID3)
        if audio.tags:
            # 删除所有 USLT (Unsynchronized lyrics) 和 SYLT (Synchronized lyrics) 帧
            if audio.tags.delall("USLT"): changed = True
            if audio.tags.delall("SYLT"): changed = True
            if changed: audio.save()

    elif ext == '.flac':
        from mutagen.flac import FLAC
        audio = FLAC(audio_path)
        if "lyrics" in audio:
            del audio["lyrics"]
            changed = True
        if "LYRICS" in audio:
            del audio["LYRICS"]
            changed = True
        if changed: audio.save()

    elif ext in ('.m4a', '.mp4'):
        from mutagen.mp4 import MP4
        audio = MP4(audio_path)
        if "\xa9lyr" in audio:
            del audio["\xa9lyr"]
            changed = True
        if changed: audio.save()

    else:
        raise ValueError(f"不支持的格式: {ext}")
    
    return changed


class GonicLrcTesterGui:
    def __init__(self, root):
        self.root = root
        self.root.title("Gonic 歌词验证测试工具 (Strip & Forge LRC)")
        self.root.geometry("680x500")

        self.style = ttk.Style()
        self.style.theme_use("vista" if os.name == "nt" else "clam")

        main_frame = ttk.Frame(self.root, padding="15")
        main_frame.pack(fill=tk.BOTH, expand=True)

        title_label = tk.Label(
            main_frame, text="清除内嵌歌词并生成 3位毫秒 伪造 LRC", 
            font=("Microsoft YaHei", 12, "bold"), fg="#e74c3c"
        )
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 15), sticky="w")

        ttk.Label(main_frame, text="目标测试目录:").grid(row=1, column=0, sticky="w")
        self.dir_entry = ttk.Entry(main_frame, width=50)
        self.dir_entry.grid(row=1, column=1, sticky="we", padx=10)
        ttk.Button(main_frame, text="选择目录...", command=self.browse_dir).grid(row=1, column=2)

        tip = ttk.Label(
            main_frame, 
            text="程序将会：\n1. 抹除该目录下所有音频的内嵌歌词\n2. 生成包含纯音乐文案的 3位毫秒 .lrc 测试文件", 
            foreground="#7f8c8d", font=("Microsoft YaHei", 9)
        )
        tip.grid(row=2, column=1, columnspan=2, sticky="w", pady=(5, 15))

        self.run_btn = tk.Button(
            main_frame, text="⚡ 开始执行验证脚本", font=("Microsoft YaHei", 10, "bold"),
            bg="#e74c3c", fg="white", activebackground="#c0392b", height=2,
            command=self.start_process
        )
        self.run_btn.grid(row=3, column=0, columnspan=3, sticky="we", pady=(0, 15))

        self.log_text = ScrolledText(main_frame, height=12, font=("Consolas", 9), bg="#2c3e50", fg="#ecf0f1")
        self.log_text.grid(row=4, column=0, columnspan=3, sticky="nsew")
        self.log_text.insert(tk.END, "[READY] 请选择一个小范围的测试目录进行验证实验...\n")
        self.log_text.configure(state=tk.DISABLED)

        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(4, weight=1)

    def browse_dir(self):
        dir_selected = filedialog.askdirectory(title="选择测试目录")
        if dir_selected:
            self.dir_entry.delete(0, tk.END)
            self.dir_entry.insert(0, os.path.normpath(dir_selected))

    def log(self, message):
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.insert(tk.END, message)
        self.log_text.see(tk.END)
        self.log_text.configure(state=tk.DISABLED)

    def start_process(self):
        directory = self.dir_entry.get().strip()
        if not directory or not os.path.exists(directory):
            messagebox.showerror("错误", "目录无效")
            return

        self.run_btn.configure(state=tk.DISABLED, bg="#95a5a6", text="正在处理...")
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.delete(1.0, tk.END)
        self.log_text.configure(state=tk.DISABLED)
        
        self.log(f"[START] 目标目录: {directory}\n")
        threading.Thread(target=self.worker, args=(directory,), daemon=True).start()

    def worker(self, directory):
        try:
            import mutagen
        except ImportError:
            self.root.after(0, lambda: messagebox.showerror("缺少依赖", "请先在终端运行: pip install mutagen"))
            self.root.after(0, lambda: self.run_btn.configure(state=tk.NORMAL, bg="#e74c3c", text="⚡ 开始执行验证脚本"))
            return

        supported_exts = ('.mp3', '.flac', '.m4a', '.mp4')
        count = 0

        for root, _, files in os.walk(directory):
            for f in files:
                if f.lower().endswith(supported_exts):
                    song_path = os.path.join(root, f)
                    base_path, _ = os.path.splitext(song_path)
                    lrc_path = base_path + ".lrc"
                    song_name = os.path.basename(song_path)

                    try:
                        # 1. 擦除内嵌歌词
                        changed = strip_embedded_lyrics(song_path)
                        if changed:
                            self.log(f"[CLEAR] 清除了内嵌歌词: {song_name}\n")
                        
                        # 2. 生成伪造的 LRC
                        with open(lrc_path, 'w', encoding='utf-8') as lf:
                            lf.write(FAKE_LRC_CONTENT)
                        self.log(f"[FORGE] 生成了 3位毫秒 LRC: {os.path.basename(lrc_path)}\n")
                        
                        # 3. 触摸文件修改时间，触发 Gonic 增量扫描
                        import time
                        now = time.time()
                        os.utime(song_path, (now, now))
                        
                        count += 1
                    except Exception as e:
                        self.log(f"[ERROR] 处理 {song_name} 失败: {e}\n")

        self.log(f"\n[FINISH] 处理完毕！共处理了 {count} 首歌曲。\n")
        self.log("请前往 Gonic 扫描媒体库，并在 App 中播放这首歌，看看能否读取到纯音乐文案以及动画是否流畅！\n")
        self.root.after(0, lambda: self.run_btn.configure(state=tk.NORMAL, bg="#e74c3c", text="⚡ 开始执行验证脚本"))
        self.root.after(0, lambda: messagebox.showinfo("完成", f"已成功处理 {count} 首歌曲。"))

if __name__ == "__main__":
    root = tk.Tk()
    app = GonicLrcTesterGui(root)
    root.mainloop()
