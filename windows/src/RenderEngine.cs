using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;

namespace GearLab
{
    public sealed class RenderPlan
    {
        public int Width;
        public int Height;
        public int TopHeight;
        public RectangleF CameraRect;
        public RectangleF PhotoRect;
        public RectangleF TitleRect;
        public RectangleF SubtitleRect;
        public float TitleSize;
        public float SubtitleSize;
        public string TitleText;
        public string SubtitleText;
    }

    public static class RenderEngine
    {
        public static Bitmap Render(Image photo, CameraTemplate template, StyleSettings style, int width)
        {
            if (photo == null) throw new ArgumentNullException("photo");
            if (template == null) template = CameraLibrary.All[0];
            if (style == null) style = new StyleSettings();
            style.Clamp();

            if (width < 320) width = 320;
            if (width > 4000) width = 4000;

            float photoAspect = photo.Width / (float)Math.Max(1, photo.Height);
            RenderPlan plan = BuildPlan(width, photoAspect, template, style);

            Bitmap output = new Bitmap(plan.Width, plan.Height, PixelFormat.Format24bppRgb);
            output.SetResolution(96, 96);
            using (Graphics g = Graphics.FromImage(output))
            {
                Configure(g);
                using (SolidBrush paper = new SolidBrush(Palette.Paper))
                    g.FillRectangle(paper, 0, 0, plan.Width, plan.Height);
                Color topColor = style.TopColor;
                if (topColor.A < 255) topColor = Color.FromArgb(255, topColor);
                using (SolidBrush top = new SolidBrush(topColor))
                    g.FillRectangle(top, 0, 0, plan.Width, plan.TopHeight);

                DrawTop(g, photo, template, style, plan);
                DrawPhoto(g, photo, plan);
            }
            return output;
        }

        /// <summary>
        /// Equal-height bands: the camera/title band and the complete photograph
        /// each take exactly 1/2 of the canvas height. The complete photo is shown
        /// at its source aspect ratio, so nothing is cropped. Hiding the title does
        /// not change the 1:1 band split.
        /// </summary>
        public static RenderPlan BuildPlan(int width, float photoAspect, CameraTemplate template, StyleSettings style)
        {
            if (photoAspect <= 0f) photoAspect = 1f;
            if (style == null) style = new StyleSettings();
            style.Clamp();

            RenderPlan plan = new RenderPlan();
            plan.Width = Math.Max(320, width);

            float w = plan.Width;
            int band = Math.Max(2, (int)Math.Round(w / photoAspect));
            int totalH = band * 2;

            // Safety for extremely tall originals: reduce the whole render size
            // uniformly. Each band still remains equal.
            if (totalH > 12000)
            {
                band = 6000;
                totalH = band * 2;
                plan.Width = Math.Max(320, (int)Math.Round(band * photoAspect));
                w = plan.Width;
            }

            plan.TopHeight = band;
            plan.Height = totalH;

            string title = GetTitle(template, style);
            plan.TitleText = title;
            plan.SubtitleText = style.ShowTitle && !String.IsNullOrWhiteSpace(style.Subtitle)
                ? style.Subtitle.Trim() : "";
            bool hasTitle = !String.IsNullOrWhiteSpace(title);

            plan.TitleSize = w * 0.0335f;
            plan.SubtitleSize = w * 0.0120f;
            float titleGap = w * 0.012f;
            float blockH = 0f;
            if (hasTitle)
            {
                blockH = plan.TitleSize * 1.28f;
                if (!String.IsNullOrWhiteSpace(plan.SubtitleText))
                    blockH += plan.SubtitleSize * 2.0f;
            }

            // Fit the camera into the fixed top band. The band height is driven by
            // the photo, not by the title; hiding the title only frees more room.
            float margin = w * 0.025f;
            float availableH = Math.Max(12f, band - margin * 2f);
            float maxArtH = availableH - (hasTitle ? titleGap + blockH : 0f);
            if (maxArtH < 12f) maxArtH = 12f;

            float artW = w * style.CameraScale;
            float artH = artW / template.ArtAspect;
            if (artH > maxArtH)
            {
                artH = maxArtH;
                artW = artH * template.ArtAspect;
            }
            if (artW > w * 0.92f)
            {
                artW = w * 0.92f;
                artH = artW / template.ArtAspect;
            }

            float contentH = artH + (hasTitle ? titleGap + blockH : 0f);
            float startY = (band - contentH) / 2f;
            if (startY < margin * 0.2f) startY = margin * 0.2f;

            plan.CameraRect = new RectangleF((w - artW) / 2f, startY, artW, artH);
            plan.PhotoRect = new RectangleF(0, band, w, band);

            if (hasTitle)
            {
                float titleTop = startY + artH + titleGap;
                plan.TitleRect = new RectangleF(w * 0.08f, titleTop, w * 0.84f, plan.TitleSize * 1.35f);
                plan.SubtitleRect = new RectangleF(w * 0.08f,
                    titleTop + plan.TitleSize * 1.32f, w * 0.84f, plan.SubtitleSize * 1.8f);
            }
            else
            {
                plan.TitleRect = RectangleF.Empty;
                plan.SubtitleRect = RectangleF.Empty;
            }

            return plan;
        }

        public static string GetTitle(CameraTemplate template, StyleSettings style)
        {
            if (!style.ShowTitle) return "";
            if (!String.IsNullOrWhiteSpace(style.Title)) return style.Title.Trim();
            return template.DisplayName;
        }

        private static void DrawTop(Graphics g, Image photo, CameraTemplate template, StyleSettings style, RenderPlan plan)
        {
            CameraRenderer.DrawComposite(g, template, plan.CameraRect, photo, style, style.ScreenGlare);

            if (String.IsNullOrWhiteSpace(plan.TitleText)) return;

            float maxWidth = plan.TitleRect.Width;
            float size = plan.TitleSize;
            Font font = Ui.DisplayFont(size, true, plan.TitleText);
            SizeF measured = g.MeasureString(plan.TitleText, font);
            while (measured.Width > maxWidth && size > plan.Width * 0.018f)
            {
                font.Dispose();
                size -= Math.Max(0.7f, plan.Width * 0.0011f);
                font = Ui.DisplayFont(size, true, plan.TitleText);
                measured = g.MeasureString(plan.TitleText, font);
            }

            Color ink = InkOn(style.TopColor);
            Color mutedInk = MutedInkOn(style.TopColor);
            using (SolidBrush brush = new SolidBrush(ink))
            using (StringFormat fmt = new StringFormat())
            {
                fmt.Alignment = StringAlignment.Center;
                fmt.LineAlignment = StringAlignment.Near;
                fmt.Trimming = StringTrimming.EllipsisCharacter;
                fmt.FormatFlags = StringFormatFlags.NoWrap;
                g.DrawString(plan.TitleText, font, brush, plan.TitleRect, fmt);
            }
            font.Dispose();

            if (!String.IsNullOrWhiteSpace(plan.SubtitleText))
            {
                float subSize = plan.SubtitleSize;
                Font subFont = Ui.Cn(subSize, FontStyle.Regular);
                if (!Ui.ContainsCjk(plan.SubtitleText))
                    subFont = Ui.Latin(subSize, FontStyle.Regular);
                using (SolidBrush brush = new SolidBrush(mutedInk))
                using (StringFormat fmt = new StringFormat())
                {
                    fmt.Alignment = StringAlignment.Center;
                    fmt.LineAlignment = StringAlignment.Near;
                    fmt.Trimming = StringTrimming.EllipsisCharacter;
                    fmt.FormatFlags = StringFormatFlags.NoWrap;
                    g.DrawString(plan.SubtitleText.ToUpperInvariant(), subFont, brush,
                        plan.SubtitleRect, fmt);
                }
                subFont.Dispose();
            }
        }

        private static Color InkOn(Color background)
        {
            float luma = 0.2126f * background.R + 0.7152f * background.G + 0.0722f * background.B;
            return luma < 145f ? Color.FromArgb(247, 245, 238) : Palette.Ink;
        }

        private static Color MutedInkOn(Color background)
        {
            float luma = 0.2126f * background.R + 0.7152f * background.G + 0.0722f * background.B;
            return luma < 145f ? Color.FromArgb(196, 255, 255, 255) : Palette.InkMuted;
        }

        private static void DrawPhoto(Graphics g, Image photo, RenderPlan plan)
        {
            RectangleF rect = plan.PhotoRect;
            if (rect.Height < 1f) return;

            GraphicsState state = g.Save();
            g.SetClip(new RectangleF(0, 0, plan.Width, plan.Height));
            InterpolationMode old = g.InterpolationMode;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            // Draw the complete photograph. The rectangle has the source aspect
            // ratio, so no part of the image is cropped.
            g.DrawImage(photo, new RectangleF(0, rect.Y, plan.Width, rect.Height));
            g.InterpolationMode = old;
            g.Restore(state);
        }

        private static void Configure(Graphics g)
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAliasGridFit;
        }

        public static Size MeasureOutput(int width, float photoAspect, CameraTemplate template, StyleSettings style)
        {
            RenderPlan plan = BuildPlan(width, photoAspect, template, style);
            return new Size(plan.Width, plan.Height);
        }

        public static void Save(Bitmap bitmap, string path, string format, int quality)
        {
            string folder = Path.GetDirectoryName(path);
            if (!String.IsNullOrEmpty(folder)) Directory.CreateDirectory(folder);
            if (String.Equals(format, "png", StringComparison.OrdinalIgnoreCase))
            {
                bitmap.Save(path, ImageFormat.Png);
                return;
            }

            ImageCodecInfo encoder = FindJpegEncoder();
            if (encoder == null)
            {
                bitmap.Save(path, ImageFormat.Jpeg);
                return;
            }
            using (EncoderParameters parameters = new EncoderParameters(1))
            {
                parameters.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, (long)quality);
                bitmap.Save(path, encoder, parameters);
            }
        }

        private static ImageCodecInfo FindJpegEncoder()
        {
            ImageCodecInfo[] codecs = ImageCodecInfo.GetImageEncoders();
            for (int i = 0; i < codecs.Length; i++)
            {
                if (codecs[i].FormatID == ImageFormat.Jpeg.Guid) return codecs[i];
            }
            return null;
        }

        public static string DimensionsLabel(int width, float photoAspect, CameraTemplate template, StyleSettings style)
        {
            Size size = MeasureOutput(width, photoAspect, template, style);
            return size.Width.ToString(CultureInfo.InvariantCulture) + " × " +
                   size.Height.ToString(CultureInfo.InvariantCulture);
        }
    }
}
