using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Windows.Forms;

namespace GearLab
{
    public sealed class ExportDialog : Form
    {
        private readonly MainForm _main;
        private ExportSettings _settings;
        private string _folder;
        private bool _dragQuality;
        private string _hover = "";

        private RectangleF _closeRect;
        private RectangleF _scopeCurrent;
        private RectangleF _scopeSelected;
        private RectangleF _sizeCard0;
        private RectangleF _sizeCard1;
        private RectangleF _sizeCard2;
        private RectangleF _formatJpg;
        private RectangleF _formatPng;
        private RectangleF _qualityTrack;
        private RectangleF _browseRect;
        private RectangleF _cancelRect;
        private RectangleF _exportRect;

        private static readonly int[] Widths = { 1080, 1440, 2160 };
        private static readonly string[] WidthNames = { "标准", "高清", "超清" };

        public ExportSettings Settings { get { return _settings; } }

        public ExportDialog(MainForm main, bool preferBatch)
        {
            _main = main;
            Text = preferBatch ? "批量导出" : "导出作品";
            FormBorderStyle = FormBorderStyle.None;
            StartPosition = FormStartPosition.CenterParent;
            ShowInTaskbar = false;
            KeyPreview = true;
            DoubleBuffered = true;
            BackColor = Palette.Bg;
            ClientSize = Ui.PS(620f, 574f);

            _folder = main.ExportFolder;
            _settings = new ExportSettings();
            _settings.Scope = preferBatch && main.ExportSelectionCount > 0
                ? ExportScope.Selected : ExportScope.Current;
            _settings.Folder = _folder;
            _settings.Width = 2160;
            _settings.Format = ExportFormat.Jpg;
            _settings.Quality = 100;
            if (main.LastExportSettings != null)
            {
                _settings.Width = main.LastExportSettings.Width;
                _settings.Format = main.LastExportSettings.Format;
                _settings.Quality = main.LastExportSettings.Quality;
                if (!String.IsNullOrEmpty(main.LastExportSettings.Folder))
                    _folder = main.LastExportSettings.Folder;
            }
        }

        protected override CreateParams CreateParams
        {
            get
            {
                CreateParams cp = base.CreateParams;
                cp.ClassStyle |= 0x20000;
                return cp;
            }
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            try
            {
                int preference = 2;
                NativeMethods.DwmSetWindowAttribute(Handle, 33, ref preference, 4);
                int dark = 1;
                NativeMethods.DwmSetWindowAttribute(Handle, 20, ref dark, 4);
            }
            catch { }
        }

        protected override void OnShown(EventArgs e)
        {
            base.OnShown(e);
            if (Owner != null)
            {
                Location = new Point(Owner.Left + (Owner.Width - Width) / 2,
                    Owner.Top + (Owner.Height - Height) / 2);
            }
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Ui.Configure(e.Graphics);
            e.Graphics.ScaleTransform(Ui.Scale, Ui.Scale);
            Graphics g = e.Graphics;
            float w = ClientSize.Width / Ui.Scale;
            float h = ClientSize.Height / Ui.Scale;

            using (LinearGradientBrush bg = new LinearGradientBrush(
                new RectangleF(0, 0, w, h), Color.FromArgb(18, 20, 23), Color.FromArgb(12, 13, 16), 90f))
                g.FillRectangle(bg, 0, 0, w, h);
            using (Pen border = new Pen(Color.FromArgb(52, 56, 61), 1f))
                g.DrawRectangle(border, 0.5f, 0.5f, w - 1f, h - 1f);

            string heading = _settings.Scope == ExportScope.Selected ? "批量导出" : "导出作品";
            Ui.Text(g, heading, Ui.Headline, Palette.Text, 28f, 22f);
            Ui.Text(g, "使用每张照片自己的设置，生成本地作品。", Ui.Tiny, Palette.Muted, 28f, 53f);
            _closeRect = new RectangleF(w - 54f, 14f, 38f, 38f);
            if (_hover == "close")
                Ui.FillRound(g, _closeRect, 7f, Palette.SurfaceHover);
            Ui.DrawClose(g, _closeRect.X + 19f, _closeRect.Y + 19f, 10f, Palette.Muted, 1.2f);
            Ui.HLine(g, 28f, 86f, w - 28f, Palette.LineSoft);

            DrawSectionLabel(g, "01", "导出方式", 103f);
            float scopeY = 123f;
            int selectedCount = _main.ExportSelectionCount;
            if (selectedCount == 0 && _settings.Scope == ExportScope.Selected)
                _settings.Scope = ExportScope.Current;
            _scopeCurrent = new RectangleF(28f, scopeY, 152f, 36f);
            _scopeSelected = new RectangleF(188f, scopeY, 152f, 36f);
            DrawScopeSegment(g, selectedCount);

            DrawSectionLabel(g, "02", "输出尺寸", 181f);
            float cardY = 201f;
            float cardW = (w - 56f - 20f) / 3f;
            _sizeCard0 = new RectangleF(28f, cardY, cardW, 74f);
            _sizeCard1 = new RectangleF(28f + cardW + 10f, cardY, cardW, 74f);
            _sizeCard2 = new RectangleF(28f + (cardW + 10f) * 2f, cardY, cardW, 74f);
            for (int i = 0; i < 3; i++)
            {
                RectangleF card = i == 0 ? _sizeCard0 : (i == 1 ? _sizeCard1 : _sizeCard2);
                bool selected = _settings.Width == Widths[i];
                Ui.FillRound(g, card, 9f, selected ? Palette.Surface : Palette.Input);
                Ui.StrokeRound(g, card, 9f, selected ? Palette.Accent : Palette.LineSoft,
                    selected ? 1.5f : 1f);
                Ui.Text(g, WidthNames[i], Ui.Micro, selected ? Palette.Accent : Palette.Faint,
                    card.X + 12f, card.Y + 10f);
                Ui.Text(g, Widths[i].ToString(), Ui.MonoBold, selected ? Palette.Text : Palette.TextSoft,
                    card.X + 12f, card.Y + 27f);
                Ui.Text(g, "完整照片 · 高度自动", Ui.Micro, selected ? Palette.Muted : Palette.Faint,
                    card.X + 12f, card.Y + 52f);
            }

            DrawSectionLabel(g, "03", "格式与画质", 297f);
            _formatJpg = new RectangleF(28f, 317f, 92f, 34f);
            _formatPng = new RectangleF(126f, 317f, 92f, 34f);
            DrawFormatButton(g, _formatJpg, "JPG", _settings.Format == ExportFormat.Jpg);
            DrawFormatButton(g, _formatPng, "PNG", _settings.Format == ExportFormat.Png);
            Ui.Text(g, "JPG 画质", Ui.Micro, _settings.Format == ExportFormat.Jpg ? Palette.Muted : Palette.Faint,
                250f, 308f);
            Ui.Text(g, _settings.Quality.ToString(), Ui.Mono, _settings.Format == ExportFormat.Jpg ? Palette.TextSoft : Palette.Faint,
                w - 52f, 308f);
            _qualityTrack = new RectangleF(250f, 331f, w - 302f, 4f);
            DrawQuality(g);

            DrawSectionLabel(g, "04", "保存位置", 375f);
            RectangleF folderRect = new RectangleF(28f, 395f, w - 56f, 42f);
            Ui.FillRound(g, folderRect, 8f, Palette.Input);
            Ui.StrokeRound(g, folderRect, 8f, Palette.LineSoft, 1f);
            using (Pen icon = new Pen(Palette.Muted, 1.1f))
            {
                RectangleF folderIcon = new RectangleF(folderRect.X + 13f, folderRect.Y + 13f, 17f, 14f);
                g.DrawRectangle(icon, folderIcon.X, folderIcon.Y + 2f, folderIcon.Width, folderIcon.Height - 2f);
                g.DrawLine(icon, folderIcon.X, folderIcon.Y + 2f, folderIcon.X + 7f, folderIcon.Y + 2f);
            }
            string folderText = _folder;
            if (String.IsNullOrEmpty(folderText)) folderText = "请选择导出目录";
            Ui.Text(g, folderText, Ui.Tiny, Palette.TextSoft,
                new RectangleF(folderRect.X + 38f, folderRect.Y + 12f, folderRect.Width - 132f, 20f));
            _browseRect = new RectangleF(folderRect.Right - 84f, folderRect.Y + 7f, 74f, 28f);
            Ui.FillRound(g, _browseRect, 6f, _hover == "browse" ? Palette.SurfaceHover : Palette.PanelSoft);
            Ui.Text(g, "更改", Ui.Micro, Palette.Text, _browseRect, StringAlignment.Center, StringAlignment.Center);

            Ui.HLine(g, 28f, 463f, w - 28f, Palette.LineSoft);
            int count = _settings.Scope == ExportScope.Current ? 1 : _main.ExportSelectionCount;
            string sizeText;
            if (_settings.Scope == ExportScope.Current && _main.SelectedPhoto != null)
            {
                float aspect = _main.SelectedPhoto.Width / (float)Math.Max(1, _main.SelectedPhoto.Height);
                Size size = RenderEngine.MeasureOutput(_settings.Width, aspect,
                    _main.CurrentCamera, _main.Style);
                sizeText = size.Width + " × " + size.Height + " px";
            }
            else
            {
                sizeText = _settings.Width + " px 宽 · 高度按各张自动 · 各按自身设置";
            }
            string summary = "将导出 " + count + " 个文件  ·  " + sizeText + "  ·  " + _settings.FormatLabel;
            Ui.Text(g, summary, Ui.Micro, Palette.Faint, 28f, 482f);

            _exportRect = new RectangleF(w - 28f - 164f, 498f, 164f, 44f);
            _cancelRect = new RectangleF(_exportRect.X - 10f - 94f, 498f, 94f, 44f);
            bool exportEnabled = _main.Photos.Count > 0;
            Ui.FillRound(g, _exportRect, 9f, _hover == "export" ? Palette.AccentHover : Palette.Accent);
            Ui.DrawDownload(g, _exportRect.X + 24f, _exportRect.Y + 22f, 14f, Color.FromArgb(29, 19, 15), 1.5f);
            Ui.Text(g, "导出", Ui.SmallBold, Color.FromArgb(29, 19, 15), _exportRect.X + 40f, _exportRect.Y + 13f);
            Ui.FillRound(g, _cancelRect, 9f, _hover == "cancel" ? Palette.SurfaceHover : Palette.PanelSoft);
            Ui.StrokeRound(g, _cancelRect, 9f, Palette.LineSoft, 1f);
            Ui.Text(g, "取消", Ui.Small, Palette.TextSoft, _cancelRect, StringAlignment.Center, StringAlignment.Center);
        }

        private void DrawSectionLabel(Graphics g, string number, string title, float y)
        {
            Ui.Text(g, number, Ui.LatinTinyBold, Palette.Accent, 28f, y);
            Ui.Text(g, title, Ui.SmallBold, Palette.TextSoft, 50f, y - 2f);
        }

        private void DrawScopeSegment(Graphics g, int selectedCount)
        {
            RectangleF container = RectangleF.Union(_scopeCurrent, _scopeSelected);
            Ui.FillRound(g, container, 8f, Palette.Input);
            Ui.StrokeRound(g, container, 8f, Palette.LineSoft, 1f);
            DrawScopeCell(g, _scopeCurrent, "当前单张", _settings.Scope == ExportScope.Current, true);
            DrawScopeCell(g, _scopeSelected, "已选 " + selectedCount + " 张",
                _settings.Scope == ExportScope.Selected, selectedCount > 0);
        }

        private void DrawScopeCell(Graphics g, RectangleF cell, string label, bool selected, bool enabled)
        {
            if (selected && enabled)
            {
                Ui.FillRound(g, RectangleF.Inflate(cell, -3f, -3f), 6f, Palette.Surface);
                Ui.StrokeRound(g, RectangleF.Inflate(cell, -3f, -3f), 6f, Palette.Line, 1f);
            }
            Color color = !enabled ? Palette.Faint : (selected ? Palette.Accent : Palette.Muted);
            Ui.Text(g, label, Ui.Small, color, cell, StringAlignment.Center, StringAlignment.Center);
        }

        private void DrawFormatButton(Graphics g, RectangleF rect, string label, bool selected)
        {
            Ui.FillRound(g, rect, 7f, selected ? Palette.Surface : Palette.Input);
            Ui.StrokeRound(g, rect, 7f, selected ? Palette.Accent : Palette.LineSoft, selected ? 1.3f : 1f);
            Ui.Text(g, label, Ui.SmallBold, selected ? Palette.Text : Palette.Muted,
                rect, StringAlignment.Center, StringAlignment.Center);
        }

        private void DrawQuality(Graphics g)
        {
            Ui.FillRound(g, _qualityTrack, 2f, Palette.Line);
            float t = (_settings.Quality - 60f) / 40f;
            if (t < 0f) t = 0f;
            if (t > 1f) t = 1f;
            float x = _qualityTrack.X + _qualityTrack.Width * t;
            Ui.FillRound(g, new RectangleF(_qualityTrack.X, _qualityTrack.Y, _qualityTrack.Width * t, 4f), 2f,
                _settings.Format == ExportFormat.Jpg ? Palette.Accent : Palette.Faint);
            using (SolidBrush knob = new SolidBrush(_settings.Format == ExportFormat.Jpg ? Palette.Accent : Palette.Faint))
                g.FillEllipse(knob, x - 5f, _qualityTrack.Y - 3f, 10f, 10f);
            Ui.Text(g, "60", Ui.Micro, Palette.Faint, _qualityTrack.X, _qualityTrack.Y + 10f);
            Ui.Text(g, "100", Ui.Micro, Palette.Faint, _qualityTrack.Right - 18f, _qualityTrack.Y + 10f);
        }

        private void Browse()
        {
            using (FolderBrowserDialog dialog = new FolderBrowserDialog())
            {
                dialog.Description = "选择导出目录";
                dialog.SelectedPath = Directory.Exists(_folder) ? _folder : _main.ExportFolder;
                dialog.ShowNewFolderButton = true;
                if (dialog.ShowDialog(this) == DialogResult.OK)
                {
                    _folder = dialog.SelectedPath;
                    Invalidate();
                }
            }
        }

        private void Finish()
        {
            if (String.IsNullOrWhiteSpace(_folder)) return;
            if (_settings.Scope == ExportScope.Selected && _main.ExportSelectionCount == 0)
                _settings.Scope = ExportScope.Current;
            _settings.Folder = _folder;
            _settings.Quality = Math.Max(60, Math.Min(100, _settings.Quality));
            DialogResult = DialogResult.OK;
            Close();
        }

        private string HitTest(PointF p)
        {
            if (_closeRect.Contains(p)) return "close";
            if (_scopeCurrent.Contains(p)) return "scope:current";
            if (_scopeSelected.Contains(p) && _main.ExportSelectionCount > 0)
                return "scope:selected";
            if (_sizeCard0.Contains(p)) return "size:0";
            if (_sizeCard1.Contains(p)) return "size:1";
            if (_sizeCard2.Contains(p)) return "size:2";
            if (_formatJpg.Contains(p)) return "format:jpg";
            if (_formatPng.Contains(p)) return "format:png";
            if (_browseRect.Contains(p)) return "browse";
            if (_cancelRect.Contains(p)) return "cancel";
            if (_exportRect.Contains(p)) return "export";
            if (Math.Abs(p.Y - (_qualityTrack.Y + 2f)) < 13f && p.X >= _qualityTrack.X - 8f &&
                p.X <= _qualityTrack.Right + 8f) return "quality";
            return "";
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            PointF p = new PointF(e.X / Ui.Scale, e.Y / Ui.Scale);
            if (_dragQuality)
            {
                float t = (p.X - _qualityTrack.X) / _qualityTrack.Width;
                if (t < 0f) t = 0f;
                if (t > 1f) t = 1f;
                _settings.Quality = (int)Math.Round(60 + t * 40);
                Invalidate();
                return;
            }
            string hit = HitTest(p);
            if (hit != _hover)
            {
                _hover = hit;
                Cursor = hit.Length > 0 ? (hit == "quality" ? Cursors.Hand : Cursors.Hand) : Cursors.Default;
                Invalidate();
            }
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            base.OnMouseLeave(e);
            _hover = "";
            Cursor = Cursors.Default;
            Invalidate();
        }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            if (e.Button != MouseButtons.Left) return;
            PointF p = new PointF(e.X / Ui.Scale, e.Y / Ui.Scale);
            string hit = HitTest(p);
            if (hit == "close" || hit == "cancel") { DialogResult = DialogResult.Cancel; Close(); return; }
            if (hit == "browse") { Browse(); return; }
            if (hit == "export") { Finish(); return; }
            if (hit == "scope:current") { _settings.Scope = ExportScope.Current; Invalidate(); return; }
            if (hit == "scope:selected") { _settings.Scope = ExportScope.Selected; Invalidate(); return; }
            if (hit.StartsWith("size:")) { _settings.Width = Widths[Int32.Parse(hit.Substring(5))]; Invalidate(); return; }
            if (hit == "format:jpg")
            {
                _settings.Format = ExportFormat.Jpg;
                Invalidate();
                return;
            }
            if (hit == "format:png")
            {
                _settings.Format = ExportFormat.Png;
                Invalidate();
                return;
            }
            if (hit == "quality" && _settings.Format == ExportFormat.Jpg)
            {
                _dragQuality = true;
                float t = (p.X - _qualityTrack.X) / _qualityTrack.Width;
                if (t < 0f) t = 0f;
                if (t > 1f) t = 1f;
                _settings.Quality = (int)Math.Round(60 + t * 40);
                Invalidate();
                return;
            }
            if (p.Y < 86f)
            {
                NativeMethods.ReleaseCapture();
                NativeMethods.SendMessage(Handle, NativeMethods.WM_NCLBUTTONDOWN, NativeMethods.HTCAPTION, 0);
            }
        }

        protected override void OnMouseUp(MouseEventArgs e)
        {
            base.OnMouseUp(e);
            if (_dragQuality)
            {
                _dragQuality = false;
                Invalidate();
            }
        }

        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == Keys.Escape)
            {
                DialogResult = DialogResult.Cancel;
                Close();
                return true;
            }
            if (keyData == Keys.Enter)
            {
                Finish();
                return true;
            }
            return base.ProcessCmdKey(ref msg, keyData);
        }
    }
}
