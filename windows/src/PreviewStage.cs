using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace GearLab
{
    public sealed class PreviewStage : BufferedControl
    {
        private readonly MainForm _main;
        private Bitmap _preview;
        private string _photoName = "";
        private string _meta = "";
        private bool _error;
        private string _errorText = "";
        private bool _hoverImport;
        private bool _hoverSample;
        private RectangleF _importRect;
        private RectangleF _sampleRect;

        private string _toastTitle = "";
        private string _toastMessage = "";
        private string _toastAction = "";
        private Action _toastActionHandler;
        private Timer _toastTimer;
        private RectangleF _toastActionRect;
        private bool _hoverToastAction;

        public PreviewStage(MainForm main)
        {
            _main = main;
            Cursor = Cursors.Default;
            _toastTimer = new Timer();
            _toastTimer.Interval = 4800;
            _toastTimer.Tick += delegate
            {
                _toastTimer.Stop();
                _toastTitle = "";
                _toastMessage = "";
                _toastAction = "";
                _toastActionHandler = null;
                Invalidate();
            };
        }

        public void ShowToast(string title, string message, string action, Action actionHandler)
        {
            _toastTitle = title ?? "";
            _toastMessage = message ?? "";
            _toastAction = action ?? "";
            _toastActionHandler = actionHandler;
            _toastTimer.Stop();
            _toastTimer.Start();
            Invalidate();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && _toastTimer != null)
            {
                _toastTimer.Stop();
                _toastTimer.Dispose();
                _toastTimer = null;
            }
            base.Dispose(disposing);
        }

        public void SetPreview(Bitmap bitmap)
        {
            if (_preview != null) _preview.Dispose();
            _preview = bitmap;
            _error = false;
            _errorText = "";
            PhotoItem photo = _main.SelectedPhoto;
            _photoName = photo == null ? "" : photo.FileName;
            _meta = photo == null ? "" : (photo.Width + " × " + photo.Height + " px");
            Invalidate();
        }

        public void SetError(string message)
        {
            if (_preview != null) _preview.Dispose();
            _preview = null;
            _error = true;
            _errorText = message;
            Invalidate();
        }

        public int GetRenderWidth()
        {
            float contentW = Width / Ui.Scale - 84f;
            int w = (int)Math.Round(contentW * 1.55f);
            if (w < 760) w = 760;
            if (w > 1200) w = 1200;
            return w;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            BeginScaled(e);
            Graphics g = e.Graphics;
            float w = Width / Ui.Scale;
            float h = Height / Ui.Scale;

            DrawPanel(g, w, h);
            DrawDots(g, w, h);
            DrawHeader(g, w);

            RectangleF area = new RectangleF(38f, 62f, Math.Max(40f, w - 76f), Math.Max(40f, h - 62f - 62f));
            if (!_main.HasPhotos)
            {
                DrawWelcome(g, area, w);
            }
            else if (_error)
            {
                DrawError(g, area);
            }
            else if (_preview != null)
            {
                DrawCanvas(g, area, w);
            }
            else
            {
                DrawLoading(g, area);
            }

            DrawFooter(g, w, h);
            DrawToast(g, w, h);
        }

        private void DrawToast(Graphics g, float w, float h)
        {
            if (String.IsNullOrEmpty(_toastTitle)) return;
            float width = Math.Min(470f, w - 52f);
            float x = (w - width) / 2f;
            float y = h - 118f;
            RectangleF rect = new RectangleF(x, y, width, 70f);
            GraphicsHelper.DrawShadow(g, rect, 10f, 1.2f);
            Ui.FillRound(g, rect, 10f, Color.FromArgb(242, 22, 25, 28));
            Ui.StrokeRound(g, rect, 10f, Color.FromArgb(65, 70, 75), 1f);
            using (SolidBrush accent = new SolidBrush(Palette.Accent))
                g.FillRectangle(accent, rect.X + 1f, rect.Y + 16f, 3f, rect.Height - 32f);
            Ui.Text(g, _toastTitle, Ui.SmallBold, Palette.Text, rect.X + 18f, rect.Y + 14f);
            Ui.Text(g, _toastMessage, Ui.Micro, Palette.Muted,
                new RectangleF(rect.X + 18f, rect.Y + 34f, rect.Width - 110f, 26f));
            if (!String.IsNullOrEmpty(_toastAction))
            {
                _toastActionRect = new RectangleF(rect.Right - 92f, rect.Y + 22f, 78f, 26f);
                if (_hoverToastAction)
                    Ui.FillRound(g, _toastActionRect, 6f, Palette.SurfaceHover);
                Ui.Text(g, _toastAction, Ui.Micro, Palette.Accent,
                    _toastActionRect, StringAlignment.Center, StringAlignment.Center);
            }
            else
            {
                _toastActionRect = RectangleF.Empty;
            }
        }

        private void DrawPanel(Graphics g, float w, float h)
        {
            using (LinearGradientBrush bg = new LinearGradientBrush(
                new RectangleF(0, 0, w, h),
                Color.FromArgb(12, 14, 17), Color.FromArgb(9, 10, 12), 90f))
            {
                using (GraphicsPath path = GraphicsHelper.RoundedRect(new RectangleF(0, 0, w, h), 14f))
                    g.FillPath(bg, path);
            }
            Ui.StrokeRound(g, new RectangleF(0.5f, 0.5f, w - 1f, h - 1f), 14f, Palette.LineSoft, 1f);
        }

        private void DrawDots(Graphics g, float w, float h)
        {
            using (SolidBrush dot = new SolidBrush(Color.FromArgb(32, 36, 40)))
            {
                for (float y = 82f; y < h - 70f; y += 24f)
                {
                    for (float x = 24f; x < w - 20f; x += 24f)
                        g.FillEllipse(dot, x, y, 1.4f, 1.4f);
                }
            }
        }

        private void DrawHeader(Graphics g, float w)
        {
            using (SolidBrush dot = new SolidBrush(Palette.Accent))
                g.FillEllipse(dot, 22f, 28f, 5f, 5f);
            Ui.Text(g, "预览", Ui.SmallBold, Palette.Text, 34f, 21f);
            Ui.Tracked(g, "LIVE COMPOSITION", Ui.LatinTiny, Palette.Faint, 76f, 25f, 0.9f);

            string label = "完整照片";
            PhotoItem photo = _main.SelectedPhoto;
            if (photo != null)
            {
                float aspect = photo.Width / (float)Math.Max(1, photo.Height);
                label = "完整照片   ·   " +
                    RenderEngine.DimensionsLabel(1080, aspect, _main.CurrentCamera, _main.Style);
            }
            Ui.Text(g, label, Ui.LatinTiny, Palette.Muted,
                new RectangleF(w - 280f, 18f, 256f, 20f), StringAlignment.Far, StringAlignment.Near);
            Ui.HLine(g, 20f, 52f, w - 20f, Palette.LineSoft);
        }

        private void DrawCanvas(Graphics g, RectangleF area, float w)
        {
            float ratio = _preview.Width / (float)Math.Max(1, _preview.Height);
            float availableW = area.Width;
            float availableH = area.Height;
            float posterW = Math.Min(availableW, availableH * ratio);
            float posterH = posterW / ratio;
            if (posterH > availableH)
            {
                posterH = availableH;
                posterW = posterH * ratio;
            }
            RectangleF poster = new RectangleF(area.X + (area.Width - posterW) / 2f,
                area.Y + (area.Height - posterH) / 2f, posterW, posterH);

            GraphicsHelper.DrawShadow(g, poster, 3f, 1.4f);
            using (SolidBrush white = new SolidBrush(Color.White))
                g.FillRectangle(white, poster);
            InterpolationMode old = g.InterpolationMode;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(_preview, poster);
            g.InterpolationMode = old;
            using (Pen line = new Pen(Color.FromArgb(34, 0, 0, 0), 1f))
                g.DrawRectangle(line, poster.X, poster.Y, poster.Width, poster.Height);
        }

        private void DrawWelcome(Graphics g, RectangleF area, float w)
        {
            float centerY = area.Y + area.Height * 0.48f;
            RectangleF iconRect = new RectangleF(area.X + area.Width / 2f - 34f, centerY - 130f, 68f, 56f);
            using (SolidBrush circle = new SolidBrush(Palette.PanelSoft))
                g.FillEllipse(circle, iconRect.X - 16f, iconRect.Y - 16f, iconRect.Width + 32f, iconRect.Height + 32f);
            Ui.DrawCameraGlyph(g, iconRect, Palette.TextSoft, 1.5f);

            Ui.Text(g, "让器材，成为照片的一部分", Ui.Headline, Palette.Text,
                new RectangleF(area.X, centerY - 44f, area.Width, 38f),
                StringAlignment.Center, StringAlignment.Near);
            Ui.Text(g, "照片完整展开不裁切；相机区与照片区上下各占一半。", Ui.Small, Palette.Muted,
                new RectangleF(area.X, centerY + 2f, area.Width, 24f),
                StringAlignment.Center, StringAlignment.Near);

            float buttonW = 158f;
            float buttonH = 42f;
            float gap = 12f;
            float totalW = buttonW * 2f + gap;
            float left = area.X + (area.Width - totalW) / 2f;
            float top = centerY + 48f;
            _importRect = new RectangleF(left, top, buttonW, buttonH);
            _sampleRect = new RectangleF(left + buttonW + gap, top, buttonW, buttonH);

            Color primary = _hoverImport ? Palette.AccentHover : Palette.Accent;
            Ui.FillRound(g, _importRect, 9f, primary);
            Ui.DrawPlus(g, _importRect.X + 24f, _importRect.Y + 21f, 11f, Color.FromArgb(31, 20, 16), 1.5f);
            Ui.Text(g, "导入照片", Ui.SmallBold, Color.FromArgb(31, 20, 16), _importRect.X + 40f, _importRect.Y + 12f);

            Ui.FillRound(g, _sampleRect, 9f, _hoverSample ? Palette.SurfaceHover : Palette.Surface);
            Ui.StrokeRound(g, _sampleRect, 9f, _hoverSample ? Palette.Line : Palette.LineSoft, 1f);
            Ui.Text(g, "载入示例", Ui.Small, Palette.Text, _sampleRect.X + 42f, _sampleRect.Y + 12f);
            Ui.DrawCameraGlyph(g, new RectangleF(_sampleRect.X + 17f, _sampleRect.Y + 12f, 18f, 16f), Palette.Muted, 1.1f);

            Ui.Text(g, "支持 JPG  ·  PNG  ·  TIFF  ·  BMP   /   Ctrl + O", Ui.Micro, Palette.Faint,
                new RectangleF(area.X, top + 66f, area.Width, 18f),
                StringAlignment.Center, StringAlignment.Near);
        }

        private void DrawError(Graphics g, RectangleF area)
        {
            Ui.Text(g, "预览生成失败", Ui.Title, Palette.Text,
                new RectangleF(area.X, area.Y + area.Height / 2f - 30f, area.Width, 28f),
                StringAlignment.Center, StringAlignment.Near);
            Ui.Text(g, _errorText, Ui.Small, Palette.Muted,
                new RectangleF(area.X, area.Y + area.Height / 2f + 4f, area.Width, 22f),
                StringAlignment.Center, StringAlignment.Near);
        }

        private void DrawLoading(Graphics g, RectangleF area)
        {
            Ui.Text(g, "正在生成预览…", Ui.Small, Palette.Muted,
                new RectangleF(area.X, area.Y + area.Height / 2f - 12f, area.Width, 24f),
                StringAlignment.Center, StringAlignment.Near);
        }

        private void DrawFooter(Graphics g, float w, float h)
        {
            float y = h - 58f;
            Ui.HLine(g, 20f, y, w - 20f, Palette.LineSoft);
            PhotoItem photo = _main.SelectedPhoto;
            if (photo != null)
            {
                Ui.Text(g, _photoName, Ui.Tiny, Palette.TextSoft, 22f, y + 18f);
                string meta = _meta + "  ·  " + _main.CurrentCamera.DisplayName;
                if (!String.IsNullOrEmpty(_main.Style.Subtitle))
                    meta += "  ·  " + _main.Style.Subtitle;
                Ui.Text(g, meta, Ui.Micro, Palette.Faint, 22f, y + 36f);
            }
            else
            {
                Ui.Text(g, "尚未导入照片", Ui.Tiny, Palette.Faint, 22f, y + 22f);
            }

            string right = "PNG / JPG  ·  最高 2160 px";
            Ui.Text(g, right, Ui.Micro, Palette.Faint, w - 22f - 158f, y + 27f);
            using (SolidBrush blue = new SolidBrush(Palette.Green))
                g.FillEllipse(blue, w - 22f - 168f, y + 30f, 4f, 4f);
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            PointF p = Ui.LogicalPoint(e.Location);
            bool actionHover = !_toastActionRect.IsEmpty && _toastActionRect.Contains(p);
            if (actionHover != _hoverToastAction)
            {
                _hoverToastAction = actionHover;
                Invalidate();
            }
            if (_main.HasPhotos)
            {
                Cursor = actionHover ? Cursors.Hand : Cursors.Default;
                return;
            }
            bool hi = _importRect.Contains(p);
            bool hs = _sampleRect.Contains(p);
            Cursor = hi || hs || actionHover ? Cursors.Hand : Cursors.Default;
            if (hi != _hoverImport || hs != _hoverSample)
            {
                _hoverImport = hi;
                _hoverSample = hs;
                Invalidate();
            }
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            base.OnMouseLeave(e);
            _hoverImport = false;
            _hoverSample = false;
            _hoverToastAction = false;
            Cursor = Cursors.Default;
            Invalidate();
        }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            if (e.Button != MouseButtons.Left) return;
            PointF p = Ui.LogicalPoint(e.Location);
            if (!_toastActionRect.IsEmpty && _toastActionRect.Contains(p))
            {
                Action handler = _toastActionHandler;
                if (handler != null) handler();
                return;
            }
            if (_main.HasPhotos) return;
            if (_importRect.Contains(p)) _main.ImportPhotos();
            else if (_sampleRect.Contains(p)) _main.LoadSamples();
        }
    }
}
