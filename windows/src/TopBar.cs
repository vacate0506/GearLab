using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace GearLab
{
    public sealed class TopBar : BufferedControl
    {
        private readonly MainForm _main;
        private string _hover = "";
        private RectangleF _importRect;
        private RectangleF _exportRect;
        private RectangleF _minRect;
        private RectangleF _maxRect;
        private RectangleF _closeRect;

        public TopBar(MainForm main)
        {
            _main = main;
            Cursor = Cursors.Default;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            BeginScaled(e);
            Graphics g = e.Graphics;
            float w = Width / Ui.Scale;
            float h = Height / Ui.Scale;

            g.Clear(Palette.TopBar);
            using (LinearGradientBrush glow = new LinearGradientBrush(
                new RectangleF(0, 0, w, h), Color.FromArgb(10, 12, 14), Color.FromArgb(14, 16, 19), 0f))
            {
                g.FillRectangle(glow, 0, 0, w, h);
            }
            Ui.HLine(g, 0, h - 1, w, Palette.LineSoft);

            DrawBrand(g);
            DrawLocalBadge(g, w);

            _closeRect = new RectangleF(w - 50f, 0, 50f, h);
            _maxRect = new RectangleF(w - 90f, 0, 40f, h);
            _minRect = new RectangleF(w - 130f, 0, 40f, h);

            float actionsY = (h - 40f) / 2f;
            _exportRect = new RectangleF(w - 140f - 126f, actionsY, 126f, 40f);
            _importRect = new RectangleF(_exportRect.X - 112f, actionsY, 104f, 40f);

            DrawWindowButton(g, _minRect, "min");
            DrawWindowButton(g, _maxRect, "max");
            DrawWindowButton(g, _closeRect, "close");
            DrawActionButton(g, _importRect, "导入照片", false);
            DrawActionButton(g, _exportRect, "导出作品", true);
            Ui.VLine(g, w - 150f, 21f, h - 21f, Palette.LineSoft);
        }

        private void DrawBrand(Graphics g)
        {
            RectangleF mark = new RectangleF(20f, 18f, 34f, 34f);
            using (LinearGradientBrush fill = new LinearGradientBrush(mark,
                Color.FromArgb(255, 112, 66), Color.FromArgb(234, 67, 27), 90f))
            using (GraphicsPath path = GraphicsHelper.RoundedRect(mark, 9f))
                g.FillPath(fill, path);
            Ui.DrawAperture(g, mark, Color.FromArgb(32, 22, 17), Palette.Accent, 2.1f);

            Ui.Tracked(g, "GEARLAB", Ui.LatinBodyBold, Palette.Text, 67f, 19f, 2.2f);
            Ui.Text(g, "器材研究所  /  CAMERA STORY", Ui.Tiny, Palette.Muted, 67f, 38f);
        }

        private void DrawLocalBadge(Graphics g, float w)
        {
            if (w < 1140f) return;
            float groupW = 228f;
            float x = Math.Max(360f, w * 0.5f - groupW / 2f);
            using (SolidBrush dot = new SolidBrush(Palette.Green))
                g.FillEllipse(dot, x, 32f, 5f, 5f);
            Ui.Text(g, "本地处理", Ui.Tiny, Palette.Muted, x + 12f, 26f);
            Ui.Text(g, "照片不会离开这台电脑", Ui.Tiny, Palette.Faint, x + 72f, 26f);
        }

        private void DrawWindowButton(Graphics g, RectangleF rect, string id)
        {
            bool hover = _hover == id;
            bool close = id == "close";
            if (hover)
            {
                Color fill = close ? Color.FromArgb(215, 65, 48) : Palette.SurfaceHover;
                Ui.FillRound(g, RectangleF.Inflate(rect, -8f, -13f), 7f, fill);
            }
            Color color = close && hover ? Color.White : Palette.Muted;
            float cx = rect.X + rect.Width / 2f;
            float cy = rect.Y + rect.Height / 2f;
            if (id == "close") Ui.DrawClose(g, cx, cy, 9f, color, 1.2f);
            else if (id == "max")
            {
                if (_main.WindowState == FormWindowState.Maximized)
                {
                    using (Pen pen = new Pen(color, 1.1f))
                    {
                        g.DrawRectangle(pen, cx - 4f, cy - 5f, 7f, 7f);
                        g.DrawRectangle(pen, cx - 1f, cy - 2f, 7f, 7f);
                    }
                }
                else Ui.DrawMaximize(g, cx, cy, 10f, color, 1.1f);
            }
            else Ui.DrawMinimize(g, cx, cy, 10f, color, 1.1f);
        }

        private void DrawActionButton(Graphics g, RectangleF rect, string label, bool primary)
        {
            bool hover = _hover == (primary ? "export" : "import");
            bool enabled = !primary || _main.HasPhotos;
            Color fill;
            Color border;
            Color text;
            if (primary)
            {
                fill = !enabled ? Palette.PanelRaised : (hover ? Palette.AccentHover : Palette.Accent);
                border = fill;
                text = !enabled ? Palette.Faint : Color.FromArgb(28, 19, 15);
            }
            else
            {
                fill = hover ? Palette.SurfaceHover : Palette.Surface;
                border = hover ? Palette.Line : Palette.LineSoft;
                text = Palette.Text;
            }
            Ui.FillRound(g, rect, 9f, fill);
            Ui.StrokeRound(g, rect, 9f, border, 1f);

            float cy = rect.Y + rect.Height / 2f;
            if (primary)
            {
                Ui.DrawDownload(g, rect.X + 22f, cy, 14f, text, 1.5f);
                Ui.Text(g, label, Ui.SmallBold, text, rect.X + 36f, cy - 8f);
            }
            else
            {
                Ui.DrawPlus(g, rect.X + 21f, cy, 10f, text, 1.4f);
                Ui.Text(g, label, Ui.Small, text, rect.X + 32f, cy - 7.5f);
            }
        }

        private string HitTest(PointF p)
        {
            if (_closeRect.Contains(p)) return "close";
            if (_maxRect.Contains(p)) return "max";
            if (_minRect.Contains(p)) return "min";
            if (_exportRect.Contains(p) && _main.HasPhotos) return "export";
            if (_importRect.Contains(p)) return "import";
            return "";
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            string hit = HitTest(Ui.LogicalPoint(e.Location));
            if (hit != _hover)
            {
                _hover = hit;
                Cursor = hit.Length > 0 ? Cursors.Hand : Cursors.Default;
                Invalidate();
            }
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            base.OnMouseLeave(e);
            if (_hover.Length > 0)
            {
                _hover = "";
                Cursor = Cursors.Default;
                Invalidate();
            }
        }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            if (e.Button != MouseButtons.Left) return;
            string hit = HitTest(Ui.LogicalPoint(e.Location));
            if (hit == "close") { _main.Close(); return; }
            if (hit == "max") { _main.ToggleMaximize(); return; }
            if (hit == "min") { _main.WindowState = FormWindowState.Minimized; return; }
            if (hit == "import") { _main.ImportPhotos(); return; }
            if (hit == "export") { _main.RequestExport(); return; }
            if (e.Clicks == 2)
            {
                _main.ToggleMaximize();
                return;
            }
            NativeMethods.ReleaseCapture();
            NativeMethods.SendMessage(_main.Handle, NativeMethods.WM_NCLBUTTONDOWN, NativeMethods.HTCAPTION, 0);
        }
    }
}
