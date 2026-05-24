import os
import time
import sys
import glob
import subprocess
import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from tkinter.scrolledtext import ScrolledText

# --- Audio Lyrics Embedding Engine ---

def read_lrc_content(lrc_path):
    """
    自适应读取歌词文件，支持 UTF-8, UTF-8-sig (带有BOM), GB18030, GBK 等多种 Windows 常见编码，并采用严格错误捕获避免乱码。
    """
    encodings = ['utf-8-sig', 'utf-8', 'gb18030', 'gbk', 'gb2312', 'utf-16', 'ansi']
    for enc in encodings:
        try:
            with open(lrc_path, 'r', encoding=enc, errors='strict') as f:
                content = f.read().strip()
                if content:
                    return content
        except Exception:
            continue
    # 强力 fallback，忽略错误读取
    with open(lrc_path, 'r', encoding='gb18030', errors='ignore') as f:
        return f.read().strip()

def fix_lrc_timestamps(lrc_text):
    """
    将 LRC 时间戳的毫秒位从 2 位补全为 3 位（例如 [00:11.61] -> [00:11.610]）。
    只修改时间戳格式，歌词文字内容完全不变。
    这是为了绕过 Gonic 服务端只识别 2 位毫秒格式并将其过滤掉的缺陷。
    """
    import re
    def pad_ms(m):
        ms = m.group(3)
        if len(ms) == 1:
            ms = ms + '00'
        elif len(ms) == 2:
            ms = ms + '0'
        # 已经是 3 位或以上，不动
        return f"[{m.group(1)}:{m.group(2)}.{ms}]"
    return re.sub(r'\[(\d+):(\d+)\.(\d+)\]', pad_ms, lrc_text)

def embed_lyrics_to_audio(audio_path, lrc_content):
    """
    利用 mutagen 库向音频写入内嵌歌词。
    """
    ext = os.path.splitext(audio_path)[1].lower()
    
    if ext == '.mp3':
        from mutagen.mp3 import MP3
        from mutagen.id3 import ID3, USLT
        
        audio = MP3(audio_path, ID3=ID3)
        try:
            audio.add_tags()
        except Exception:
            pass
        
        # 移除已有的 USLT (Unsynchronized lyrics) 帧并重新添加
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
        audio["\xa9lyr"] = [lrc_content]  # M4A 的歌词标签是 \xa9lyr，入参需要是列表
        audio.save()
        
    else:
        raise ValueError(f"不支持的音频文件格式: {ext}")


# --- Tkinter GUI Application ---

class LyricsEmbedderGui:
    def __init__(self, root):
        self.root = root
        self.root.title("🎵 音乐歌词内嵌神器 (LRC Lyrics Embedder) 🚀")
        self.root.geometry("760x580")
        self.root.minsize(700, 480)
        
        # 风格配置
        self.style = ttk.Style()
        self.style.theme_use("vista" if os.name == "nt" else "clam")

        # 主网格布局容器
        main_frame = ttk.Frame(self.root, padding="15")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # 标题
        title_label = tk.Label(
            main_frame, 
            text="音频 LRC 歌词批量内嵌工具", 
            font=("Microsoft YaHei", 14, "bold"), 
            fg="#2c3e50"
        )
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 15), sticky="w")

        # 1. 目录配置
        ttk.Label(main_frame, text="音频歌曲目录:", font=("Microsoft YaHei", 10, "bold")).grid(row=1, column=0, sticky="w", pady=5)
        
        self.dir_entry = ttk.Entry(main_frame, width=55)
        self.dir_entry.grid(row=1, column=1, sticky="we", padx=(0, 10), pady=5)
        
        # 🌟 默认值自动设定为用户指定的 A:\Media\Music
        default_dir = r"A:\Media\Music"
        if os.path.exists(default_dir):
            self.dir_entry.insert(0, os.path.normpath(default_dir))
        else:
            self.dir_entry.insert(0, default_dir)

        browse_btn = ttk.Button(main_frame, text="选择目录...", command=self.browse_dir)
        browse_btn.grid(row=1, column=2, pady=5)

        dir_tip = ttk.Label(
            main_frame, 
            text="提示：程序将自动递归遍历该目录下（包含所有子文件夹）的所有音频文件，寻找同名的 .lrc 歌词文件并进行内嵌。", 
            foreground="#7f8c8d", 
            font=("Microsoft YaHei", 8)
        )
        dir_tip.grid(row=2, column=1, columnspan=2, sticky="w", pady=(0, 15))

        # 2. 依赖管理栏（专为无 mutagen 环境设计，一键全自动后台安装）
        dep_frame = ttk.LabelFrame(main_frame, text=" ⚡ 依赖环境管理 ", padding="10")
        dep_frame.grid(row=3, column=0, columnspan=3, sticky="we", pady=(0, 15))
        
        dep_tip = ttk.Label(dep_frame, text="内嵌歌词需要第三方组件 'mutagen'。如果你尚未安装，请点击右侧按钮一键安装：", font=("Microsoft YaHei", 9))
        dep_tip.pack(side=tk.LEFT, fill=tk.X, expand=True)

        self.install_btn = ttk.Button(dep_frame, text="一键安装 mutagen", command=self.install_dependency)
        self.install_btn.pack(side=tk.RIGHT, padx=5)

        # 3. 操作大按钮
        self.run_btn = tk.Button(
            main_frame, 
            text="🚀 开始批量内嵌歌词", 
            font=("Microsoft YaHei", 11, "bold"),
            bg="#27ae60", 
            fg="white", 
            activebackground="#2ecc71",
            activeforeground="white",
            relief=tk.FLAT,
            height=2,
            command=self.start_embedding
        )
        self.run_btn.grid(row=4, column=0, columnspan=3, sticky="we", pady=(0, 15))

        # 4. 执行状态与日志控制台
        ttk.Label(main_frame, text="执行实时日志:", font=("Microsoft YaHei", 9, "bold")).grid(row=5, column=0, sticky="w", pady=5)
        
        self.log_text = ScrolledText(main_frame, height=15, font=("Consolas", 9), bg="#2c3e50", fg="#ecf0f1", insertbackground="white")
        self.log_text.grid(row=6, column=0, columnspan=3, sticky="nsew", pady=5)
        self.log_text.insert(tk.END, "[READY] 准备就绪。请确认文件夹路径后，点击“开始批量内嵌歌词”按钮。\n")
        self.log_text.configure(state=tk.DISABLED)

        # 网格拉伸比例自适应
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(6, weight=1)

    def browse_dir(self):
        dir_selected = filedialog.askdirectory(title="选择音频文件目录")
        if dir_selected:
            dir_selected = os.path.normpath(dir_selected)
            self.dir_entry.delete(0, tk.END)
            self.dir_entry.insert(0, dir_selected)

    def log(self, message):
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.insert(tk.END, message)
        self.log_text.see(tk.END)
        self.log_text.configure(state=tk.DISABLED)

    def install_dependency(self):
        """
        在后台启动线程一键执行 pip install mutagen，保证 GUI 界面不卡死
        """
        self.install_btn.configure(state=tk.DISABLED)
        self.log("\n[SETUP] 开始后台安装必要组件 'mutagen'，请稍后...\n")
        threading.Thread(target=self.pip_installer_worker, daemon=True).start()

    def pip_installer_worker(self):
        try:
            startupinfo = None
            if os.name == 'nt':
                # 防止 Windows 弹出黑框
                startupinfo = subprocess.STARTUPINFO()
                startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            
            process = subprocess.run(
                [sys.executable, "-m", "pip", "install", "mutagen"],
                capture_output=True,
                text=True,
                startupinfo=startupinfo
            )
            
            if process.returncode == 0:
                self.root.after(0, lambda: self.log("[SETUP SUCCESS] 'mutagen' 库安装成功！现可正常执行内嵌任务。\n"))
                messagebox.showinfo("依赖安装成功", "必要组件 mutagen 已成功安装！")
            else:
                self.root.after(0, lambda: self.log(f"[SETUP ERROR] 安装失败，原因: {process.stderr}\n"))
                messagebox.showerror("安装失败", f"安装失败，请手动在终端输入 pip install mutagen 安装。\n错误信息:\n{process.stderr}")
        except Exception as e:
            self.root.after(0, lambda: self.log(f"[SETUP ERROR] 出现异常: {e}\n"))
        finally:
            self.root.after(0, lambda: self.install_btn.configure(state=tk.NORMAL))

    def start_embedding(self):
        directory = self.dir_entry.get().strip()
        
        if not directory:
            messagebox.showerror("错误", "请选择需要处理的音频歌曲目录！")
            return
        if not os.path.exists(directory):
            messagebox.showerror("错误", f"找不到指定目录: {directory}")
            return

        # 锁定按钮，启动后台工作线程
        self.run_btn.configure(state=tk.DISABLED, bg="#95a5a6", text="⚡ 正在遍历并内嵌歌词...")
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.delete(1.0, tk.END)
        self.log_text.configure(state=tk.DISABLED)

        self.log(f"[START] 开始启动歌词批量嵌入引擎...\n")
        self.log(f"[INFO] 目标目录: {directory}\n")
        self.log("-" * 60 + "\n")

        threading.Thread(target=self.embedding_worker, args=(directory,), daemon=True).start()

    def embedding_worker(self, directory):
        try:
            # 1. 检查 mutagen 是否安装
            try:
                import mutagen
            except ImportError:
                self.root.after(0, self.handle_missing_dependency)
                return

            # 2. 递归遍历目录寻找支持的音频文件
            supported_exts = ('.mp3', '.flac', '.m4a', '.mp4')
            songs_found = []
            
            for root, dirs, files in os.walk(directory):
                for f in files:
                    if f.lower().endswith(supported_exts):
                        songs_found.append(os.path.join(root, f))
            
            self.log(f"[INFO] 目录检索完成。共扫描出支持的音频文件 {len(songs_found)} 个。\n")
            self.log(f"[INFO] 正在逐个搜寻同名 .lrc 歌词文件并写入...\n\n")

            success_count = 0
            skipped_count = 0
            error_count = 0

            for idx, song_path in enumerate(songs_found):
                base_path, ext = os.path.splitext(song_path)
                lrc_path = base_path + ".lrc"
                song_name = os.path.basename(song_path)
                
                # 在控制台以进度条形式更新展示
                if idx % 10 == 0 and idx > 0:
                    self.log(f"[PROGRESS] 已分析并处理 {idx}/{len(songs_found)} 个音频文件...\n")

                if os.path.exists(lrc_path):
                    try:
                        lrc_content = read_lrc_content(lrc_path)
                        # 自动修正时间戳毫秒位为3位，防止 Gonic 过滤时间戳导致歌词无法滚动
                        lrc_content = fix_lrc_timestamps(lrc_content)
                        if not lrc_content:
                            self.log(f"[SKIP] {song_name} -> 歌词文件内容为空，跳过。\n")
                            skipped_count += 1
                            continue
                        
                        # 1. 写入音频元数据标签 (供车载/本地播放器使用)
                        embed_lyrics_to_audio(song_path, lrc_content)
                        
                        # 2. 将原歌词 .lrc 文件在本地【原地安全重写】为标准 UTF-8 无 BOM 格式
                        with open(lrc_path, 'w', encoding='utf-8') as f:
                            f.write(lrc_content)
                            
                        # 3. 自动检测并删除可能残留的多余同名 .txt 文件，强迫症福音，实现一歌双档极致整洁！
                        txt_path = base_path + ".txt"
                        if os.path.exists(txt_path):
                            try:
                                os.remove(txt_path)
                            except Exception:
                                pass
                            
                        # 4. 热触碰修改时间戳，强制 Gonic 识别并触发扫描
                        now = time.time()
                        os.utime(song_path, (now, now))
                        
                        self.log(f"[SUCCESS] 嵌入并完美清洗.lrc: {song_name}\n")
                        success_count += 1
                    except Exception as e:
                        self.log(f"[ERROR] 写入失败: {song_name} | 原因: {e}\n")
                        error_count += 1
                else:
                    # 没找到歌词，静默跳过
                    skipped_count += 1

            # 任务结束汇报
            self.log("\n" + "=" * 60 + "\n")
            self.log("[FINISH] 歌词嵌入任务全部执行完毕！\n")
            self.log(f" └─ 🎉 成功内嵌歌词: {success_count} 首\n")
            self.log(f" └─ 💤 未找到歌词跳过: {skipped_count} 首\n")
            if error_count > 0:
                self.log(f" └─ ❌ 写入遭遇失败: {error_count} 首\n")
            self.log("=" * 60 + "\n")

            # 自动通知 Gonic 服务器刷新
            if success_count > 0:
                self.log("[INFO] 正在通知 Gonic 服务器启动增量扫描...\n")
                self.trigger_gonic_scan()

            # 成功提示弹窗
            self.root.after(0, lambda: self.embedding_finished(True, success_count, error_count))

        except Exception as e:
            self.root.after(0, lambda: self.embedding_finished(False, str(e)))

    def trigger_gonic_scan(self):
        import urllib.request
        import urllib.parse
        import hashlib
        import json
        import random
        import string
        
        gonic_url = "http://192.168.0.2:4747/rest"
        u = "gulson"
        p = "a130s339"
        
        salt = "".join(random.choices(string.ascii_letters + string.digits, k=10))
        token = hashlib.md5((p + salt).encode('utf-8')).hexdigest()
        auth_params = f"u={u}&t={token}&s={salt}&v=1.16.1&c=gui_embedder&f=json"
        
        try:
            url = f"{gonic_url}/startScan.view?{auth_params}"
            with urllib.request.urlopen(url, timeout=5) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                status = data.get('subsonic-response', {}).get('status', 'failed')
                self.log(f"[GONIC] 自动触发 Gonic 服务器重新扫描成功，状态: {status}\n")
        except Exception as e:
            self.log(f"[GONIC ERROR] 自动触发 Gonic 重新扫描失败: {e}\n")

    def handle_missing_dependency(self):
        self.run_btn.configure(state=tk.NORMAL, bg="#27ae60", text="🚀 开始批量内嵌歌词")
        self.log("[ERROR] 致命错误：本地未检测到第三方音频库 'mutagen'。\n")
        self.log("[HELP] 解决办法：\n")
        self.log("   1. 点击上方的“一键安装 mutagen”按钮，程序将自动为您联网下载安装。\n")
        self.log("   2. 或者，在您的系统命令行终端运行: pip install mutagen 进行手动安装。\n")
        messagebox.showerror("缺少必要依赖", "本地缺少必要依赖库 'mutagen'！\n\n请点击上方的“一键安装 mutagen”按钮进行自动安装，然后再运行本程序。")

    def embedding_finished(self, success, success_count_or_err, error_count=0):
        self.run_btn.configure(state=tk.NORMAL, bg="#27ae60", text="🚀 开始批量内嵌歌词")
        if success:
            messagebox.showinfo(
                "嵌入完成", 
                f"歌词嵌入任务成功执行！\n\n本次共成功内嵌歌词：{success_count_or_err} 首。\n写入失败：{error_count} 首。"
            )
        else:
            self.log(f"[FATAL ERROR] 任务异常终止: {success_count_or_err}\n")
            messagebox.showerror("执行异常", f"执行失败，发生未知错误：\n{success_count_or_err}")

if __name__ == "__main__":
    root = tk.Tk()
    app = LyricsEmbedderGui(root)
    root.mainloop()
