using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Windows.Forms;

namespace GearLab
{
    public sealed class MainForm : Form
    {
        public readonly List<PhotoItem> Photos = new List<PhotoItem>();
        public readonly StyleSettings Style = new StyleSettings();
        public bool SyncAllPhotos = true;
        public int SelectedIndex = -1;
        public bool IsBusy;
        public bool IsSyncingInspector;
        public string ExportFolder;
        public ExportSettings LastExportSettings;

        private readonly TopBar _topBar;
        private readonly PhotoRail _rail;
        private readonly PreviewStage _preview;
        private readonly Inspector _inspector;
        private readonly Timer _previewTimer;
        private readonly string[] _initialPaths;
        private readonly bool _loadDemo;
        private readonly string _initialCamera;
        private readonly string _initialExportFolder;
        private bool _loaded;
        private DateTime _lastPreviewRequest = DateTime.MinValue;

        public MainForm(string[] initialPaths, bool loadDemo, string cameraId, string exportFolder)
        {
            _initialPaths = initialPaths;
            _loadDemo = loadDemo;
            _initialCamera = cameraId;
            _initialExportFolder = exportFolder;

            Text = "GearLab 器材研究所";
            FormBorderStyle = FormBorderStyle.None;
            StartPosition = FormStartPosition.Manual;
            BackColor = Palette.Bg;
            DoubleBuffered = true;
            KeyPreview = true;
            AllowDrop = true;
            AutoScaleMode = AutoScaleMode.None;
            MinimumSize = new Size(1120, 720);

            try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); }
            catch { }

            // Default output lives inside the application/project folder, not the
            // user's Pictures library. Fall back only if that folder is read-only.
            string exports = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "exports");
            bool workspaceWritable = false;
            try
            {
                Directory.CreateDirectory(exports);
                string probe = Path.Combine(exports, ".write-test");
                File.WriteAllText(probe, "ok");
                File.Delete(probe);
                workspaceWritable = true;
            }
            catch { }
            if (workspaceWritable)
            {
                ExportFolder = exports;
            }
            else
            {
                string pictures = Environment.GetFolderPath(Environment.SpecialFolder.MyPictures);
                if (String.IsNullOrWhiteSpace(pictures))
                    pictures = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Pictures");
                ExportFolder = Path.Combine(pictures, "GearLab");
            }
            if (!String.IsNullOrWhiteSpace(_initialExportFolder))
            {
                try { ExportFolder = Path.GetFullPath(_initialExportFolder); }
                catch { }
            }

            _topBar = new TopBar(this);
            _rail = new PhotoRail(this);
            _preview = new PreviewStage(this);
            _inspector = new Inspector(this);

            Controls.Add(_topBar);
            Controls.Add(_rail);
            Controls.Add(_preview);
            Controls.Add(_inspector);
            _preview.AllowDrop = true;
            _rail.AllowDrop = true;
            _inspector.AllowDrop = true;
            _topBar.AllowDrop = true;

            DragEventHandler dragEnter = OnDragEnter;
            DragEventHandler dragDrop = OnDragDrop;
            DragEnter += dragEnter;
            DragDrop += dragDrop;
            _preview.DragEnter += dragEnter;
            _preview.DragDrop += dragDrop;
            _rail.DragEnter += dragEnter;
            _rail.DragDrop += dragDrop;
            _inspector.DragEnter += dragEnter;
            _inspector.DragDrop += dragDrop;
            _topBar.DragEnter += dragEnter;
            _topBar.DragDrop += dragDrop;

            _previewTimer = new Timer();
            _previewTimer.Interval = 45;
            _previewTimer.Tick += delegate
            {
                _previewTimer.Stop();
                RenderPreview();
            };

            Load += OnFormLoad;
            Resize += delegate
            {
                if (!_loaded) return;
                LayoutChildren();
                if (DateTime.Now - _lastPreviewRequest > TimeSpan.FromMilliseconds(250))
                    RequestPreview();
            };
            FormClosing += delegate { DisposePhotos(); };
            _inspector.ReloadFromStyle();
        }

        public bool HasPhotos { get { return Photos.Count > 0; } }

        public int ExportSelectionCount
        {
            get
            {
                int count = 0;
                for (int i = 0; i < Photos.Count; i++)
                    if (Photos[i].ExportSelected) count++;
                return count;
            }
        }

        public void NotifyExportSelectionChanged()
        {
            _rail.Invalidate();
            _inspector.Invalidate();
            _topBar.Invalidate();
        }

        public PhotoItem SelectedPhoto
        {
            get
            {
                if (SelectedIndex < 0 || SelectedIndex >= Photos.Count) return null;
                return Photos[SelectedIndex];
            }
        }

        public Image SelectedThumbnail
        {
            get
            {
                PhotoItem item = SelectedPhoto;
                return item == null ? null : item.Thumbnail;
            }
        }

        public CameraTemplate CurrentCamera
        {
            get { return CameraLibrary.Find(Style.CameraId); }
        }

        private void OnFormLoad(object sender, EventArgs e)
        {
            Ui.Scale = DeviceDpi / 96f;
            if (Ui.Scale < 1f) Ui.Scale = 1f;

            Rectangle working = Screen.FromHandle(Handle).WorkingArea;
            float logicalW = working.Width / Ui.Scale;
            float logicalH = working.Height / Ui.Scale;
            float targetW = Math.Min(1480f, logicalW - 40f);
            float targetH = Math.Min(980f, logicalH - 40f);
            if (targetW < 1120f) targetW = Math.Min(1120f, logicalW);
            if (targetH < 720f) targetH = Math.Min(720f, logicalH);
            ClientSize = Ui.PS(targetW, targetH);
            Location = new Point(working.X + (working.Width - Width) / 2,
                working.Y + (working.Height - Height) / 2);
            MinimumSize = Ui.PS(1120f, 720f);

            if (!String.IsNullOrEmpty(_initialCamera))
            {
                CameraTemplate template = CameraLibrary.Find(_initialCamera);
                Style.CameraId = template.Id;
            }
            _inspector.ReloadFromStyle();

            LayoutChildren();
            _loaded = true;
            ApplyWindowCorners();

            if (_initialPaths != null && _initialPaths.Length > 0)
                AddPaths(_initialPaths, false);
            else if (_loadDemo)
                LoadSamples();
            else
                RenderPreview();

            Shown += delegate
            {
                BeginInvoke((MethodInvoker)delegate
                {
                    ActiveControl = null;
                    _preview.Invalidate();
                });
            };
        }

        private void ApplyWindowCorners()
        {
            try
            {
                int preference = 2;
                NativeMethods.DwmSetWindowAttribute(Handle, 33, ref preference, 4);
                int dark = 1;
                NativeMethods.DwmSetWindowAttribute(Handle, 20, ref dark, 4);
            }
            catch
            {
            }
        }

        public void LayoutChildren()
        {
            if (!_loaded && Ui.Scale <= 0f) return;
            float w = ClientSize.Width / Ui.Scale;
            float h = ClientSize.Height / Ui.Scale;
            const float topH = 70f;
            const float pad = 12f;
            const float gap = 10f;

            float railW = w < 1300f ? 224f : 246f;
            float inspectorW = w < 1300f ? 380f : 420f;
            float bodyY = topH;
            float bodyH = Math.Max(220f, h - topH - pad);
            float railX = pad;
            float inspectorX = w - pad - inspectorW;
            float previewX = railX + railW + gap;
            float previewW = Math.Max(240f, inspectorX - previewX - gap);

            _topBar.SetBounds(0, 0, ClientSize.Width, Ui.Px(topH));
            _rail.SetBounds(Ui.Px(railX), Ui.Px(bodyY), Ui.Px(railW), Ui.Px(bodyH));
            _preview.SetBounds(Ui.Px(previewX), Ui.Px(bodyY), Ui.Px(previewW), Ui.Px(bodyH));
            _inspector.SetBounds(Ui.Px(inspectorX), Ui.Px(bodyY), Ui.Px(inspectorW), Ui.Px(bodyH));
        }

        public void ToggleMaximize()
        {
            if (WindowState == FormWindowState.Maximized)
            {
                WindowState = FormWindowState.Normal;
            }
            else
            {
                MaximizedBounds = Screen.FromHandle(Handle).WorkingArea;
                WindowState = FormWindowState.Maximized;
            }
        }

        public void ImportPhotos()
        {
            using (OpenFileDialog dialog = new OpenFileDialog())
            {
                dialog.Title = "选择照片";
                dialog.Filter = "照片文件|*.jpg;*.jpeg;*.jpe;*.png;*.bmp;*.tif;*.tiff|所有文件|*.*";
                dialog.Multiselect = true;
                dialog.RestoreDirectory = true;
                if (dialog.ShowDialog(this) == DialogResult.OK)
                    AddPaths(dialog.FileNames, true);
            }
        }

        public void LoadSamples()
        {
            string[] samples = EmbeddedAssets.ExtractDemoSamples();
            if (samples.Length == 0)
            {
                ShowToast("示例不可用", "无法释放内置示例照片，请直接导入自己的照片。", "", null);
                return;
            }
            int before = Photos.Count;
            AddPaths(samples, true);
            if (Photos.Count > before)
                SelectPhoto(before);
            else
                ApplySelectedPhotoStyle();
            RequestPreview();
            _rail.Invalidate();
            _inspector.Invalidate();
            _preview.Invalidate();
        }

        public void AddPaths(IEnumerable<string> paths, bool notify)
        {
            if (paths == null) return;
            List<string> candidates = new List<string>();
            foreach (string path in paths)
            {
                if (String.IsNullOrWhiteSpace(path)) continue;
                if (Directory.Exists(path))
                {
                    try
                    {
                        string[] files = Directory.GetFiles(path);
                        Array.Sort(files, StringComparer.OrdinalIgnoreCase);
                        for (int i = 0; i < files.Length; i++) candidates.Add(files[i]);
                    }
                    catch
                    {
                    }
                }
                else if (File.Exists(path))
                {
                    candidates.Add(path);
                }
            }

            int added = 0;
            int failed = 0;
            int firstAdded = -1;
            try
            {
                Cursor = Cursors.WaitCursor;
                for (int i = 0; i < candidates.Count; i++)
                {
                    string path = candidates[i];
                    if (!ImageUtil.IsSupported(path)) continue;
                    bool exists = false;
                    for (int j = 0; j < Photos.Count; j++)
                    {
                        if (String.Equals(Photos[j].Path, path, StringComparison.OrdinalIgnoreCase))
                        {
                            exists = true;
                            break;
                        }
                    }
                    if (exists) continue;

                    try
                    {
                        PhotoItem item = ImageUtil.Inspect(path);
                        item.Style = Style.Clone();
                        item.CameraId = item.Style.CameraId;
                        Photos.Add(item);
                        if (firstAdded < 0) firstAdded = Photos.Count - 1;
                        added++;
                    }
                    catch
                    {
                        failed++;
                    }
                }
            }
            finally
            {
                Cursor = Cursors.Default;
            }

            if (firstAdded >= 0) SelectedIndex = firstAdded;
            if (SelectedIndex < 0 && Photos.Count > 0) SelectedIndex = 0;
            ApplySelectedPhotoStyle();
            DropUnusedPreviews();
            RequestPreview();
            _rail.Invalidate();
            _inspector.Invalidate();
            _topBar.Invalidate();
            _preview.Invalidate();

            if (notify && added > 0)
            {
                string message = failed > 0
                    ? "已加入 " + added + " 张，另有 " + failed + " 个文件无法读取。"
                    : "照片已加入，选择相机模板后即可导出。";
                ShowToast("已导入 " + added + " 张照片", message, "", null);
            }
            else if (failed > 0 && added == 0)
            {
                ShowToast("无法导入", "请确认文件为 JPG、PNG、TIFF 或 BMP 格式。", "", null);
            }
        }

        public void SelectPhoto(int index)
        {
            if (index < 0 || index >= Photos.Count) return;
            SelectedIndex = index;
            ApplySelectedPhotoStyle();
            DropUnusedPreviews();
            RequestPreview();
            _rail.Invalidate();
            _inspector.Invalidate();
            _preview.Invalidate();
        }

        public void RemovePhoto(int index)
        {
            if (index < 0 || index >= Photos.Count) return;
            PhotoItem item = Photos[index];
            Photos.RemoveAt(index);
            item.Dispose();
            if (Photos.Count == 0) SelectedIndex = -1;
            else if (SelectedIndex >= Photos.Count) SelectedIndex = Photos.Count - 1;
            else if (index < SelectedIndex) SelectedIndex--;
            if (SelectedIndex >= 0) ApplySelectedPhotoStyle();
            DropUnusedPreviews();
            RequestPreview();
            _rail.Invalidate();
            _inspector.Invalidate();
            _preview.Invalidate();
            _topBar.Invalidate();
        }

        public void RemoveSelected()
        {
            if (SelectedIndex >= 0) RemovePhoto(SelectedIndex);
        }

        private void DropUnusedPreviews()
        {
            for (int i = 0; i < Photos.Count; i++)
                if (i != SelectedIndex) Photos[i].DropPreview();
        }

        public void SelectCamera(string id)
        {
            CameraTemplate template = CameraLibrary.Find(id);
            Style.CameraId = template.Id;
            ApplyStyleChange();
            _inspector.RefreshCameraCue();
            _rail.Invalidate();
        }

        public void SetSyncAllPhotos(bool enabled)
        {
            if (SyncAllPhotos == enabled) return;
            SyncAllPhotos = enabled;
            if (enabled)
                CaptureStyleToAllPhotos();
            else
                CaptureStyleTo(SelectedPhoto);
            _inspector.Invalidate();
            _rail.Invalidate();
            RequestPreview();
        }

        private void CaptureStyleTo(PhotoItem item)
        {
            if (item == null) return;
            item.Style = Style.Clone();
            item.CameraId = item.Style.CameraId;
        }

        private void CaptureStyleToAllPhotos()
        {
            for (int i = 0; i < Photos.Count; i++)
                CaptureStyleTo(Photos[i]);
        }

        private void ApplySelectedPhotoStyle()
        {
            if (SyncAllPhotos) return;
            PhotoItem item = SelectedPhoto;
            if (item == null) return;
            if (item.Style == null)
            {
                item.Style = Style.Clone();
                item.CameraId = item.Style.CameraId;
                return;
            }
            Style.CopyFrom(item.Style);
            item.CameraId = Style.CameraId;
            _inspector.ReloadFromStyle();
        }

        public void ResetStyle()
        {
            Style.CameraId = "ricoh-gr4";
            PhotoItem item = SelectedPhoto;
            if (item != null) item.CameraId = "ricoh-gr4";
            Style.CameraScale = 0.50f;
            Style.ShowTitle = true;
            Style.Title = "";
            Style.Subtitle = "";
            Style.ScreenFit = ScreenFitMode.Fill;
            Style.ScreenGlare = false;
            Style.TopColor = Color.White;
            _inspector.ReloadFromStyle();
            ApplyStyleChange();
        }

        public void ApplyStyleChange()
        {
            Style.Clamp();
            if (SyncAllPhotos)
                CaptureStyleToAllPhotos();
            else
                CaptureStyleTo(SelectedPhoto);
            RequestPreview();
            _inspector.Invalidate();
            _preview.Invalidate();
            _topBar.Invalidate();
        }

        public void RequestPreview()
        {
            _lastPreviewRequest = DateTime.Now;
            _previewTimer.Stop();
            _previewTimer.Start();
        }

        private void RenderPreview()
        {
            if (!HasPhotos || SelectedPhoto == null)
            {
                _preview.SetPreview(null);
                return;
            }

            try
            {
                PhotoItem item = SelectedPhoto;
                Image image = item.Preview;
                if (image == null) throw new InvalidOperationException("无法读取这张照片。");
                int width = _preview.GetRenderWidth();
                Bitmap bitmap = RenderEngine.Render(image, CurrentCamera, Style, width);
                _preview.SetPreview(bitmap);
            }
            catch (Exception ex)
            {
                _preview.SetError(ex.Message);
            }
        }

        public void RequestExport()
        {
            RequestExport(false);
        }

        public void RequestExport(bool batch)
        {
            if (IsBusy) return;
            if (!HasPhotos)
            {
                ShowToast("还没有照片", "先导入一张照片，再导出作品。", "", null);
                return;
            }
            if (batch && ExportSelectionCount == 0)
            {
                ShowToast("还没有勾选照片", "点击照片缩略图右上角的勾选框，选择要批量导出的照片。", "", null);
                return;
            }

            using (ExportDialog dialog = new ExportDialog(this, batch))
            {
                if (dialog.ShowDialog(this) != DialogResult.OK) return;
                StartExport(dialog.Settings);
            }
        }

        private void StartExport(ExportSettings settings)
        {
            if (settings == null) return;
            List<string> paths = new List<string>();
            List<StyleSettings> styles = new List<StyleSettings>();
            if (settings.Scope == ExportScope.Selected)
            {
                for (int i = 0; i < Photos.Count; i++)
                {
                    if (!Photos[i].ExportSelected) continue;
                    paths.Add(Photos[i].Path);
                    styles.Add(Photos[i].Style != null ? Photos[i].Style.Clone() : Style.Clone());
                }
            }
            else
            {
                if (SelectedPhoto == null) return;
                paths.Add(SelectedPhoto.Path);
                styles.Add(Style.Clone());
            }
            if (paths.Count == 0)
            {
                ShowToast("没有可导出的照片", "请勾选至少一张照片后重试。", "", null);
                return;
            }

            IsBusy = true;
            _inspector.Invalidate();
            _topBar.Invalidate();
            BatchExportResult result = null;
            try
            {
                ExportSettings captured = settings.Clone();
                StyleSettings style = Style.Clone();
                using (ExportProgressForm progress = new ExportProgressForm(delegate(BackgroundWorker worker)
                {
                    result = BatchExporter.Run(paths, styles, style, captured,
                        delegate(int percent, string message) { worker.ReportProgress(percent, message); },
                        delegate { return worker.CancellationPending; });
                }))
                {
                    progress.ShowDialog(this);
                    if (progress.Error != null)
                    {
                        ShowToast("导出失败", progress.Error.Message, "", null);
                        return;
                    }
                    if (progress.Canceled)
                    {
                        ShowToast("已停止导出", "已完成的文件会保留在导出目录。", "", null);
                        return;
                    }
                }
            }
            catch (Exception ex)
            {
                ShowToast("导出失败", ex.Message, "", null);
                return;
            }
            finally
            {
                IsBusy = false;
                _inspector.Invalidate();
                _topBar.Invalidate();
            }

            if (result == null) return;
            ExportFolder = settings.Folder;
            LastExportSettings = settings;
            if (result.Failed > 0)
            {
                string detail = result.Errors.Count > 0 ? result.Errors[0] : "请检查导出目录权限。";
                ShowToast("导出完成，但有 " + result.Failed + " 个失败", detail, "", null);
            }
            else
            {
                ShowToast("导出完成 · " + result.Completed + " 个文件",
                    "作品已保存到 " + ShortPath(settings.Folder), "打开", OpenExportFolder);
            }
        }

        private static string ShortPath(string path)
        {
            if (String.IsNullOrEmpty(path)) return "";
            if (path.Length <= 48) return path;
            return path.Substring(0, 18) + "…" + path.Substring(path.Length - 27);
        }

        public void OpenExportFolder()
        {
            try
            {
                if (Directory.Exists(ExportFolder))
                    Process.Start("explorer.exe", "\"" + ExportFolder + "\"");
            }
            catch
            {
            }
        }

        public void ShowToast(string title, string message, string action, Action handler)
        {
            _preview.ShowToast(title, message, action, handler);
        }

        private void OnDragEnter(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(DataFormats.FileDrop))
                e.Effect = DragDropEffects.Copy;
        }

        private void OnDragDrop(object sender, DragEventArgs e)
        {
            string[] files = e.Data.GetData(DataFormats.FileDrop) as string[];
            if (files != null && files.Length > 0) AddPaths(files, true);
        }

        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == (Keys.Control | Keys.O))
            {
                ImportPhotos();
                return true;
            }
            if (keyData == (Keys.Control | Keys.E) || keyData == (Keys.Control | Keys.S))
            {
                RequestExport();
                return true;
            }
            if (keyData == Keys.Delete && !(ActiveControl is TextBox))
            {
                RemoveSelected();
                return true;
            }
            if (keyData == Keys.F11)
            {
                ToggleMaximize();
                return true;
            }
            if (keyData == Keys.Left && !(ActiveControl is TextBox) && Photos.Count > 0)
            {
                SelectPhoto((SelectedIndex - 1 + Photos.Count) % Photos.Count);
                return true;
            }
            if (keyData == Keys.Right && !(ActiveControl is TextBox) && Photos.Count > 0)
            {
                SelectPhoto((SelectedIndex + 1) % Photos.Count);
                return true;
            }
            return base.ProcessCmdKey(ref msg, keyData);
        }

        protected override void OnDpiChanged(DpiChangedEventArgs e)
        {
            base.OnDpiChanged(e);
            if (!_loaded) return;
            float oldScale = Ui.Scale;
            ui_apply_scale(e.DeviceDpiNew / 96f);
            int newW = (int)Math.Round(ClientSize.Width / oldScale * Ui.Scale);
            int newH = (int)Math.Round(ClientSize.Height / oldScale * Ui.Scale);
            ClientSize = new Size(newW, newH);
            LayoutChildren();
            _inspector.ReloadFromStyle();
            _preview.Invalidate();
        }

        private void ui_apply_scale(float scale)
        {
            if (scale < 1f) scale = 1f;
            Ui.Scale = scale;
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == NativeMethods.WM_NCHITTEST && WindowState == FormWindowState.Normal)
            {
                int screenX = (short)((long)m.LParam & 0xFFFF);
                int screenY = (short)(((long)m.LParam >> 16) & 0xFFFF);
                Point p = PointToClient(new Point(screenX, screenY));
                int b = Ui.Px(8f);
                bool left = p.X <= b;
                bool right = p.X >= ClientSize.Width - b;
                bool top = p.Y <= 3;
                bool bottom = p.Y >= ClientSize.Height - b;
                int hit = 0;
                if (left && top) hit = NativeMethods.HTTOPLEFT;
                else if (right && top) hit = NativeMethods.HTTOPRIGHT;
                else if (left && bottom) hit = NativeMethods.HTBOTTOMLEFT;
                else if (right && bottom) hit = NativeMethods.HTBOTTOMRIGHT;
                else if (left) hit = NativeMethods.HTLEFT;
                else if (right) hit = NativeMethods.HTRIGHT;
                else if (top) hit = NativeMethods.HTTOP;
                else if (bottom) hit = NativeMethods.HTBOTTOM;
                if (hit != 0)
                {
                    m.Result = (IntPtr)hit;
                    return;
                }
            }
            base.WndProc(ref m);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            using (LinearGradientBrush bg = new LinearGradientBrush(
                new Rectangle(0, 0, Math.Max(1, ClientSize.Width), Math.Max(1, ClientSize.Height)),
                Color.FromArgb(11, 12, 14), Color.FromArgb(8, 9, 11), 90f))
            {
                e.Graphics.FillRectangle(bg, ClientRectangle);
            }
            using (Pen edge = new Pen(Palette.LineSoft, 1f))
                e.Graphics.DrawRectangle(edge, 0, 0, ClientSize.Width - 1, ClientSize.Height - 1);
        }

        private void DisposePhotos()
        {
            for (int i = 0; i < Photos.Count; i++) Photos[i].Dispose();
            Photos.Clear();
        }
    }
}
