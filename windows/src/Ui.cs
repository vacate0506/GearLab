using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace GearLab
{
    public static class Palette
    {
        public static readonly Color Bg = Color.FromArgb(10, 11, 13);
        public static readonly Color TopBar = Color.FromArgb(12, 14, 16);
        public static readonly Color Panel = Color.FromArgb(16, 18, 21);
        public static readonly Color PanelRaised = Color.FromArgb(20, 22, 25);
        public static readonly Color PanelSoft = Color.FromArgb(23, 25, 29);
        public static readonly Color Surface = Color.FromArgb(26, 29, 33);
        public static readonly Color SurfaceHover = Color.FromArgb(33, 36, 41);
        public static readonly Color Input = Color.FromArgb(23, 25, 28);
        public static readonly Color Line = Color.FromArgb(42, 46, 51);
        public static readonly Color LineSoft = Color.FromArgb(29, 32, 36);
        public static readonly Color Text = Color.FromArgb(243, 241, 235);
        public static readonly Color TextSoft = Color.FromArgb(206, 203, 195);
        public static readonly Color Muted = Color.FromArgb(139, 140, 136);
        public static readonly Color Faint = Color.FromArgb(94, 96, 93);
        public static readonly Color Accent = Color.FromArgb(255, 92, 46);
        public static readonly Color AccentHover = Color.FromArgb(255, 116, 73);
        public static readonly Color AccentSoft = Color.FromArgb(56, 32, 24);
        public static readonly Color Green = Color.FromArgb(102, 197, 149);
        public static readonly Color Red = Color.FromArgb(221, 93, 78);
        public static readonly Color Paper = Color.FromArgb(255, 255, 255);
        public static readonly Color Ink = Color.FromArgb(20, 20, 20);
        public static readonly Color InkMuted = Color.FromArgb(112, 108, 99);
        public static readonly Color CardWhite = Color.FromArgb(250, 249, 246);

        public static Color Alpha(Color color, int alpha)
        {
            if (alpha < 0) alpha = 0;
            if (alpha > 255) alpha = 255;
            return Color.FromArgb(alpha, color.R, color.G, color.B);
        }

        public static Color Mix(Color a, Color b, float t)
        {
            if (t <= 0f) return a;
            if (t >= 1f) return b;
            return Color.FromArgb(
                (int)Math.Round(a.A + (b.A - a.A) * t),
                (int)Math.Round(a.R + (b.R - a.R) * t),
                (int)Math.Round(a.G + (b.G - a.G) * t),
                (int)Math.Round(a.B + (b.B - a.B) * t));
        }
    }

    public static class Ui
    {
        public static float Scale = 1f;

        public static readonly Font Micro = Cn(9.2f, FontStyle.Regular);
        public static readonly Font MicroBold = Cn(9.2f, FontStyle.Bold);
        public static readonly Font Tiny = Cn(10.2f, FontStyle.Regular);
        public static readonly Font TinyBold = Cn(10.2f, FontStyle.Bold);
        public static readonly Font Small = Cn(11.2f, FontStyle.Regular);
        public static readonly Font SmallBold = Cn(11.2f, FontStyle.Bold);
        public static readonly Font Body = Cn(12.2f, FontStyle.Regular);
        public static readonly Font BodyBold = Cn(12.2f, FontStyle.Bold);
        public static readonly Font Title = Cn(15.2f, FontStyle.Bold);
        public static readonly Font Headline = Cn(22f, FontStyle.Bold);
        public static readonly Font Display = Cn(30f, FontStyle.Bold);

        public static readonly Font LatinTiny = Latin(9.2f, FontStyle.Regular);
        public static readonly Font LatinTinyBold = Latin(9.2f, FontStyle.Bold);
        public static readonly Font LatinSmall = Latin(10.4f, FontStyle.Regular);
        public static readonly Font LatinSmallBold = Latin(10.4f, FontStyle.Bold);
        public static readonly Font LatinBody = Latin(11.8f, FontStyle.Regular);
        public static readonly Font LatinBodyBold = Latin(11.8f, FontStyle.Bold);
        public static readonly Font LatinTitle = Latin(15f, FontStyle.Bold);
        public static readonly Font Mono = MonoFont(9.6f, FontStyle.Regular);
        public static readonly Font MonoBold = MonoFont(9.6f, FontStyle.Bold);

        public static float L(float physical)
        {
            return physical / Scale;
        }

        public static int Px(float logical)
        {
            return (int)Math.Round(logical * Scale);
        }

        public static Size PS(float width, float height)
        {
            return new Size(Px(width), Px(height));
        }

        public static Rectangle PRect(float x, float y, float w, float h)
        {
            return new Rectangle(Px(x), Px(y), Px(w), Px(h));
        }

        public static PointF LogicalPoint(Point p)
        {
            return new PointF(p.X / Scale, p.Y / Scale);
        }

        public static Font Cn(float size, FontStyle style)
        {
            try { return new Font("Microsoft YaHei UI", size, style, GraphicsUnit.Pixel); }
            catch { return new Font(FontFamily.GenericSansSerif, size, style, GraphicsUnit.Pixel); }
        }

        public static Font Latin(float size, FontStyle style)
        {
            try { return new Font("Segoe UI", size, style, GraphicsUnit.Pixel); }
            catch { return new Font(FontFamily.GenericSansSerif, size, style, GraphicsUnit.Pixel); }
        }

        public static Font MonoFont(float size, FontStyle style)
        {
            try { return new Font("Consolas", size, style, GraphicsUnit.Pixel); }
            catch { return new Font(FontFamily.GenericMonospace, size, style, GraphicsUnit.Pixel); }
        }

        public static Font DisplayFont(float size, bool bold, string sample)
        {
            bool cjk = ContainsCjk(sample);
            if (cjk) return Cn(size, bold ? FontStyle.Bold : FontStyle.Regular);
            try
            {
                return new Font("Bahnschrift", size, bold ? FontStyle.Bold : FontStyle.Regular, GraphicsUnit.Pixel);
            }
            catch
            {
                return Latin(size, bold ? FontStyle.Bold : FontStyle.Regular);
            }
        }

        public static bool ContainsCjk(string text)
        {
            if (String.IsNullOrEmpty(text)) return false;
            for (int i = 0; i < text.Length; i++)
            {
                char c = text[i];
                if (c >= 0x2E80 && c <= 0x9FFF) return true;
                if (c >= 0xF900 && c <= 0xFAFF) return true;
            }
            return false;
        }

        public static void Configure(Graphics g)
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;
            g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;
        }

        public static void Text(Graphics g, string text, Font font, Color color, float x, float y)
        {
            using (SolidBrush brush = new SolidBrush(color))
                g.DrawString(text, font, brush, x, y);
        }

        public static void Text(Graphics g, string text, Font font, Color color, RectangleF rect)
        {
            Text(g, text, font, color, rect, StringAlignment.Near, StringAlignment.Near);
        }

        public static void Text(Graphics g, string text, Font font, Color color, RectangleF rect,
            StringAlignment align, StringAlignment lineAlign)
        {
            using (SolidBrush brush = new SolidBrush(color))
            using (StringFormat fmt = new StringFormat())
            {
                fmt.Alignment = align;
                fmt.LineAlignment = lineAlign;
                fmt.Trimming = StringTrimming.EllipsisCharacter;
                fmt.FormatFlags = StringFormatFlags.NoWrap;
                g.DrawString(text, font, brush, rect, fmt);
            }
        }

        public static void Tracked(Graphics g, string text, Font font, Color color, float x, float y, float tracking)
        {
            using (SolidBrush brush = new SolidBrush(color))
            {
                float cursor = x;
                for (int i = 0; i < text.Length; i++)
                {
                    string part = text.Substring(i, 1);
                    g.DrawString(part, font, brush, cursor, y);
                    cursor += g.MeasureString(part, font).Width + tracking;
                }
            }
        }

        public static void TrackedCentered(Graphics g, string text, Font font, Color color, float centerX, float y, float tracking)
        {
            float width = 0;
            for (int i = 0; i < text.Length; i++)
                width += g.MeasureString(text.Substring(i, 1), font).Width + tracking;
            if (width > 0) width -= tracking;
            Tracked(g, text, font, color, centerX - width / 2f, y, tracking);
        }

        public static void FillRound(Graphics g, RectangleF rect, float radius, Color color)
        {
            GraphicsHelper.FillRounded(g, rect, radius, color);
        }

        public static void StrokeRound(Graphics g, RectangleF rect, float radius, Color color, float width)
        {
            GraphicsHelper.StrokeRounded(g, rect, radius, color, width);
        }

        public static void HLine(Graphics g, float x1, float y, float x2, Color color)
        {
            using (Pen pen = new Pen(color, 1f))
                g.DrawLine(pen, x1, y, x2, y);
        }

        public static void VLine(Graphics g, float x, float y1, float y2, Color color)
        {
            using (Pen pen = new Pen(color, 1f))
                g.DrawLine(pen, x, y1, x, y2);
        }

        public static void DrawPlus(Graphics g, float cx, float cy, float size, Color color, float width)
        {
            using (Pen pen = new Pen(color, width))
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                g.DrawLine(pen, cx - size / 2f, cy, cx + size / 2f, cy);
                g.DrawLine(pen, cx, cy - size / 2f, cx, cy + size / 2f);
            }
        }

        public static void DrawClose(Graphics g, float cx, float cy, float size, Color color, float width)
        {
            using (Pen pen = new Pen(color, width))
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                g.DrawLine(pen, cx - size / 2f, cy - size / 2f, cx + size / 2f, cy + size / 2f);
                g.DrawLine(pen, cx + size / 2f, cy - size / 2f, cx - size / 2f, cy + size / 2f);
            }
        }

        public static void DrawMinimize(Graphics g, float cx, float cy, float size, Color color, float width)
        {
            using (Pen pen = new Pen(color, width))
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                g.DrawLine(pen, cx - size / 2f, cy, cx + size / 2f, cy);
            }
        }

        public static void DrawMaximize(Graphics g, float cx, float cy, float size, Color color, float width)
        {
            RectangleF rect = new RectangleF(cx - size / 2f, cy - size / 2f, size, size);
            StrokeRound(g, rect, 1.5f, color, width);
        }

        public static void DrawArrowUpRight(Graphics g, float cx, float cy, float size, Color color, float width)
        {
            using (Pen pen = new Pen(color, width))
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                pen.LineJoin = LineJoin.Round;
                g.DrawLine(pen, cx - size * 0.35f, cy + size * 0.35f, cx + size * 0.35f, cy - size * 0.35f);
                g.DrawLine(pen, cx - size * 0.02f, cy - size * 0.35f, cx + size * 0.35f, cy - size * 0.35f);
                g.DrawLine(pen, cx + size * 0.35f, cy - size * 0.35f, cx + size * 0.35f, cy + size * 0.02f);
            }
        }

        public static void DrawDownload(Graphics g, float cx, float cy, float size, Color color, float width)
        {
            using (Pen pen = new Pen(color, width))
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                pen.LineJoin = LineJoin.Round;
                g.DrawLine(pen, cx, cy - size * 0.45f, cx, cy + size * 0.18f);
                g.DrawLine(pen, cx - size * 0.24f, cy - size * 0.04f, cx, cy + size * 0.2f);
                g.DrawLine(pen, cx + size * 0.24f, cy - size * 0.04f, cx, cy + size * 0.2f);
                g.DrawLine(pen, cx - size * 0.38f, cy + size * 0.42f, cx + size * 0.38f, cy + size * 0.42f);
            }
        }

        public static void DrawChevron(Graphics g, float cx, float cy, float size, Color color, float width, bool down)
        {
            using (Pen pen = new Pen(color, width))
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                pen.LineJoin = LineJoin.Round;
                float y1 = cy - (down ? size * 0.18f : -size * 0.18f);
                float y2 = cy + (down ? size * 0.22f : -size * 0.22f);
                g.DrawLine(pen, cx - size * 0.35f, y1, cx, y2);
                g.DrawLine(pen, cx, y2, cx + size * 0.35f, y1);
            }
        }

        public static void DrawCheck(Graphics g, RectangleF rect, Color color, float width)
        {
            using (Pen pen = new Pen(color, width))
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                pen.LineJoin = LineJoin.Round;
                PointF a = new PointF(rect.X + rect.Width * 0.16f, rect.Y + rect.Height * 0.54f);
                PointF b = new PointF(rect.X + rect.Width * 0.41f, rect.Y + rect.Height * 0.78f);
                PointF c = new PointF(rect.X + rect.Width * 0.84f, rect.Y + rect.Height * 0.25f);
                g.DrawLines(pen, new PointF[] { a, b, c });
            }
        }

        public static void DrawAperture(Graphics g, RectangleF rect, Color color, Color center, float stroke)
        {
            float cx = rect.X + rect.Width / 2f;
            float cy = rect.Y + rect.Height / 2f;
            float radius = Math.Min(rect.Width, rect.Height) * 0.34f;
            using (Pen pen = new Pen(color, stroke))
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                for (int i = 0; i < 6; i++)
                {
                    double a0 = Math.PI * 2 * i / 6.0 + 0.15;
                    double a1 = a0 + 0.92;
                    PointF p0 = new PointF(cx + (float)Math.Cos(a0) * radius, cy + (float)Math.Sin(a0) * radius);
                    PointF p1 = new PointF(cx + (float)Math.Cos(a1) * radius, cy + (float)Math.Sin(a1) * radius);
                    g.DrawLine(pen, p0, p1);
                }
            }
            using (SolidBrush brush = new SolidBrush(center))
                g.FillEllipse(brush, cx - radius * 0.22f, cy - radius * 0.22f, radius * 0.44f, radius * 0.44f);
        }

        public static void DrawCameraGlyph(Graphics g, RectangleF rect, Color color, float width)
        {
            using (Pen pen = new Pen(color, width))
            {
                pen.LineJoin = LineJoin.Round;
                float x = rect.X;
                float y = rect.Y + rect.Height * 0.18f;
                float w = rect.Width;
                float h = rect.Height * 0.72f;
                GraphicsPath body = GraphicsHelper.RoundedRect(new RectangleF(x, y, w, h), 5f);
                g.DrawPath(pen, body);
                body.Dispose();
                float bumpW = w * 0.28f;
                g.DrawLine(pen, x + w * 0.24f, y, x + w * 0.3f, y - rect.Height * 0.12f);
                g.DrawLine(pen, x + w * 0.3f, y - rect.Height * 0.12f, x + w * 0.3f + bumpW, y - rect.Height * 0.12f);
                g.DrawLine(pen, x + w * 0.3f + bumpW, y - rect.Height * 0.12f, x + w * 0.36f + bumpW, y);
                float lensR = Math.Min(w, h) * 0.235f;
                g.DrawEllipse(pen, x + w / 2f - lensR, y + h / 2f - lensR, lensR * 2f, lensR * 2f);
            }
            using (SolidBrush flash = new SolidBrush(color))
                g.FillEllipse(flash, rect.X + rect.Width * 0.82f, rect.Y + rect.Height * 0.18f, 2.2f, 2.2f);
        }

        public static RectangleF CenterRect(RectangleF area, float width, float height)
        {
            return new RectangleF(area.X + (area.Width - width) / 2f,
                area.Y + (area.Height - height) / 2f, width, height);
        }

        public static string ShortNumber(int value)
        {
            return value.ToString("00", CultureInfo.InvariantCulture);
        }
    }

    internal static class NativeMethods
    {
        public const int WM_NCLBUTTONDOWN = 0xA1;
        public const int HTCAPTION = 0x2;
        public const int WM_NCHITTEST = 0x84;
        public const int HTLEFT = 10;
        public const int HTRIGHT = 11;
        public const int HTTOP = 12;
        public const int HTTOPLEFT = 13;
        public const int HTTOPRIGHT = 14;
        public const int HTBOTTOM = 15;
        public const int HTBOTTOMLEFT = 16;
        public const int HTBOTTOMRIGHT = 17;
        public const int EM_SETCUEBANNER = 0x1501;

        [DllImport("user32.dll")]
        public static extern bool ReleaseCapture();

        [DllImport("user32.dll")]
        public static extern IntPtr SendMessage(IntPtr hWnd, int msg, int wParam, int lParam);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        public static extern IntPtr SendMessage(IntPtr hWnd, int msg, int wParam, string lParam);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern int GetDpiForWindow(IntPtr hWnd);

        [DllImport("dwmapi.dll")]
        public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
    }

    public class BufferedControl : Control
    {
        public BufferedControl()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint |
                     ControlStyles.OptimizedDoubleBuffer |
                     ControlStyles.ResizeRedraw |
                     ControlStyles.UserPaint, true);
            SetStyle(ControlStyles.Selectable, false);
        }

        protected void BeginScaled(PaintEventArgs e)
        {
            Ui.Configure(e.Graphics);
            e.Graphics.ScaleTransform(Ui.Scale, Ui.Scale);
        }
    }
}
