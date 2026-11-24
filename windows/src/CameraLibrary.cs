using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Reflection;

namespace GearLab
{
    public static class EmbeddedAssets
    {
        private const string Prefix = "GearLab.Resources.";

        public static bool Exists(string name)
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            return assembly.GetManifestResourceInfo(Prefix + name) != null;
        }

        public static byte[] ReadBytes(string name)
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            using (Stream stream = assembly.GetManifestResourceStream(Prefix + name))
            {
                if (stream == null)
                    throw new InvalidOperationException("Missing embedded asset: " + name);
                using (MemoryStream memory = new MemoryStream())
                {
                    byte[] buffer = new byte[32768];
                    int read;
                    while ((read = stream.Read(buffer, 0, buffer.Length)) > 0)
                        memory.Write(buffer, 0, read);
                    return memory.ToArray();
                }
            }
        }

        public static Image LoadImage(string name)
        {
            byte[] bytes = ReadBytes(name);
            using (MemoryStream stream = new MemoryStream(bytes))
            using (Image source = Image.FromStream(stream))
            {
                Bitmap copy = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
                copy.SetResolution(96, 96);
                using (Graphics g = Graphics.FromImage(copy))
                {
                    g.CompositingMode = CompositingMode.SourceCopy;
                    g.DrawImage(source, new Rectangle(0, 0, source.Width, source.Height));
                }
                return copy;
            }
        }

        public static string[] ExtractDemoSamples()
        {
            string[] names = { "dsc-2492-sea.jpg", "dsc-2435-harbor.jpg", "dsc-2387-street.jpg", "dsc-2441-beach.jpg" };
            List<string> folders = new List<string>();
            folders.Add(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "samples"));
            string local = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            if (!String.IsNullOrEmpty(local))
                folders.Add(Path.Combine(local, "GearLab", "samples"));
            folders.Add(Path.Combine(Path.GetTempPath(), "GearLab", "samples"));

            for (int f = 0; f < folders.Count; f++)
            {
                string folder = folders[f];
                try
                {
                    Directory.CreateDirectory(folder);
                    List<string> paths = new List<string>();
                    bool ok = true;
                    for (int i = 0; i < names.Length; i++)
                    {
                        string name = names[i];
                        string path = Path.Combine(folder, name);
                        try
                        {
                            if (!File.Exists(path))
                            {
                                byte[] bytes = ReadBytes("samples." + name);
                                File.WriteAllBytes(path, bytes);
                            }
                            if (!File.Exists(path))
                            {
                                ok = false;
                                break;
                            }
                            paths.Add(path);
                        }
                        catch
                        {
                            ok = false;
                            break;
                        }
                    }
                    if (ok && paths.Count == names.Length) return paths.ToArray();
                }
                catch
                {
                }
            }
            return new string[0];
        }
    }

    public static class CameraLibrary
    {
        private static readonly List<CameraTemplate> Templates = BuildTemplates();
        private static readonly Dictionary<string, Image> ArtCache = new Dictionary<string, Image>();
        private static readonly object CacheLock = new object();

        private static List<CameraTemplate> BuildTemplates()
        {
            List<CameraTemplate> list = new List<CameraTemplate>();

            // All camera art comes from the user's D:\ai_img reference set.
            // Each PNG is a background-removed product photo. Screen boxes are
            // normalized against the trimmed art and match the blank rear LCD.
            list.Add(new CameraTemplate(
                "ricoh-gr4", "RICOH", "GR IV", "Ricoh GR IV", "GR IV",
                "Rear view", "cameras.ricoh-gr4.png",
                855f / 502f,
                new RectangleF(0.035088f, 0.137450f, 0.676023f, 0.784861f),
                "#B7B5AE", true));

            list.Add(new CameraTemplate(
                "fujifilm-x100vi", "FUJIFILM", "X100VI", "Fujifilm X100VI",
                "X100VI", "Rear view", "cameras.fujifilm-x100vi-silver.png",
                632f / 362f,
                new RectangleF(0.1076f, 0.3011f, 0.5301f, 0.6215f),
                "#A6192E", true));

            list.Add(new CameraTemplate(
                "fujifilm-xm5", "FUJIFILM", "X-M5", "Fujifilm X-M5",
                "X-M5", "Rear view", "cameras.fujifilm-xm5-silver.png",
                632f / 367f,
                new RectangleF(0.1677f, 0.2343f, 0.6044f, 0.6894f),
                "#A6192E", true));

            list.Add(new CameraTemplate(
                "nikon-z5ii", "NIKON", "Z5II", "Nikon Z5II", "Z5II",
                "Rear view", "cameras.nikon-z5ii.png",
                678f / 494f,
                new RectangleF(0.1327f, 0.4251f, 0.5383f, 0.5020f),
                "#C5A24A", true));

            list.Add(new CameraTemplate(
                "nikon-z6iii", "NIKON", "Z6III", "Nikon Z6III", "Z6III",
                "Rear view", "cameras.nikon-z6iii.png",
                678f / 481f,
                new RectangleF(0.1490f, 0.4595f, 0.4985f, 0.4449f),
                "#C5A24A", true));

            list.Add(new CameraTemplate(
                "nikon-z8", "NIKON", "Z8", "Nikon Z8", "Z8",
                "Rear view", "cameras.nikon-z8.png",
                586f / 459f,
                new RectangleF(0.0734f, 0.4227f, 0.5973f, 0.5054f),
                "#C5A24A", true));

            list.Add(new CameraTemplate(
                "nikon-zr", "NIKON", "ZR", "Nikon ZR", "ZR",
                "Rear view", "cameras.nikon-zr.png",
                678f / 435f,
                new RectangleF(0.1372f, 0.1563f, 0.6460f, 0.7379f),
                "#C5A24A", true));

            list.Add(new CameraTemplate(
                "sony-a7c2", "SONY", "α7C II", "Sony α7C II", "α7C II",
                "Rear view", "cameras.sony-a7c2.png",
                518f / 290f,
                new RectangleF(0.1795f, 0.3552f, 0.4517f, 0.5448f),
                "#75919A", true));

            list.Add(new CameraTemplate(
                "sony-a7c2-s", "SONY", "α7C II", "Sony α7C II",
                "α7C II", "Rear view", "cameras.sony-a7c2-silver.png",
                632f / 353f,
                new RectangleF(0.1804f, 0.3569f, 0.4525f, 0.5382f),
                "#75919A", true));

            list.Add(new CameraTemplate(
                "lumix-s9", "LUMIX", "Lumix S9", "Lumix S9", "LUMIX S9",
                "Rear view", "cameras.lumix-s9.png",
                624f / 359f,
                new RectangleF(0.1827f, 0.3593f, 0.4679f, 0.5432f),
                "#4E6A78", true));

            list.Add(new CameraTemplate(
                "lumix-s9-s", "LUMIX", "Lumix S9", "Lumix S9",
                "LUMIX S9", "Rear view", "cameras.lumix-s9-silver.png",
                1704f / 981f,
                new RectangleF(0.1837f, 0.3588f, 0.4654f, 0.5423f),
                "#4E6A78", true));

            return list;
        }

        public static IList<CameraTemplate> All
        {
            get { return Templates; }
        }

        public static CameraTemplate Find(string id)
        {
            for (int i = 0; i < Templates.Count; i++)
            {
                if (String.Equals(Templates[i].Id, id, StringComparison.OrdinalIgnoreCase))
                    return Templates[i];
            }
            return Templates[0];
        }

        public static Image GetArt(CameraTemplate template)
        {
            if (template == null) return null;
            lock (CacheLock)
            {
                Image image;
                if (ArtCache.TryGetValue(template.ResourceName, out image)) return image;
                image = EmbeddedAssets.LoadImage(template.ResourceName);
                ArtCache[template.ResourceName] = image;
                return image;
            }
        }
    }

    public static class CameraRenderer
    {
        public static RectangleF ScreenRect(CameraTemplate template, RectangleF artRect)
        {
            return new RectangleF(
                artRect.X + template.Screen.X * artRect.Width,
                artRect.Y + template.Screen.Y * artRect.Height,
                template.Screen.Width * artRect.Width,
                template.Screen.Height * artRect.Height);
        }

        public static void DrawComposite(Graphics g, CameraTemplate template, RectangleF artRect,
            Image photo, StyleSettings style, bool drawGlass)
        {
            if (template == null) return;
            Image art = CameraLibrary.GetArt(template);
            if (art == null) return;

            if (template.IsRealProduct)
                DrawStudioShadow(g, artRect);

            InterpolationMode oldInterpolation = g.InterpolationMode;
            PixelOffsetMode oldOffset = g.PixelOffsetMode;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(art, artRect);
            g.InterpolationMode = oldInterpolation;
            g.PixelOffsetMode = oldOffset;

            RectangleF screen = ScreenRect(template, artRect);
            DrawScreen(g, screen, photo, style, drawGlass);
        }

        public static void DrawScreen(Graphics g, RectangleF screen, Image photo, StyleSettings style, bool drawGlass)
        {
            if (screen.Width <= 0 || screen.Height <= 0) return;

            GraphicsState state = g.Save();
            using (GraphicsPath clip = GraphicsHelper.RoundedRect(screen, 1.2f))
                g.SetClip(clip, CombineMode.Intersect);

            using (SolidBrush black = new SolidBrush(Color.FromArgb(7, 8, 9)))
                g.FillRectangle(black, screen);

            if (photo != null)
            {
                if (style != null && style.ScreenFit == ScreenFitMode.Fit)
                {
                    ImageUtil.DrawFit(g, photo, screen);
                }
                else
                {
                    double scale = Math.Max(screen.Width / photo.Width, screen.Height / photo.Height);
                    float pw = (float)(photo.Width * scale);
                    float ph = (float)(photo.Height * scale);
                    float px = screen.X + (screen.Width - pw) / 2f;
                    float py = screen.Y + (screen.Height - ph) / 2f;
                    g.DrawImage(photo, new RectangleF(px, py, pw, ph));
                }
            }

            if (drawGlass)
            {
                // A restrained diagonal glass reflection.
                using (LinearGradientBrush sheen = new LinearGradientBrush(
                    new RectangleF(screen.X, screen.Y, screen.Width, screen.Height),
                    Color.FromArgb(26, 255, 255, 255), Color.FromArgb(0, 255, 255, 255), 38f))
                {
                    g.FillRectangle(sheen, screen);
                }
                using (LinearGradientBrush depth = new LinearGradientBrush(
                    new RectangleF(screen.X, screen.Y, screen.Width, screen.Height),
                    Color.FromArgb(44, 0, 0, 0), Color.FromArgb(0, 0, 0, 0), 90f))
                {
                    depth.SetSigmaBellShape(0.1f, 0.55f);
                    g.FillRectangle(depth, screen);
                }
                using (Pen edge = new Pen(Color.FromArgb(110, 0, 0, 0), 1f))
                    g.DrawRectangle(edge, screen.X + 0.5f, screen.Y + 0.5f, screen.Width - 1f, screen.Height - 1f);
            }
            g.Restore(state);
        }

        private static void DrawStudioShadow(Graphics g, RectangleF art)
        {
            float cx = art.X + art.Width * 0.50f;
            float cy = art.Y + art.Height * 0.884f;
            RectangleF ellipse = new RectangleF(cx - art.Width * 0.43f, cy - art.Height * 0.032f,
                art.Width * 0.86f, art.Height * 0.064f);
            using (GraphicsPath path = new GraphicsPath())
            {
                path.AddEllipse(ellipse);
                using (PathGradientBrush brush = new PathGradientBrush(path))
                {
                    brush.CenterPoint = new PointF(cx, cy + art.Height * 0.006f);
                    brush.CenterColor = Color.FromArgb(54, 18, 17, 16);
                    brush.SurroundColors = new Color[] { Color.FromArgb(0, 255, 255, 255) };
                    g.FillPath(brush, path);
                }
            }
        }

        public static void DrawThumb(Graphics g, CameraTemplate template, RectangleF card, Image photo,
            bool selected, StyleSettings style)
        {
            GraphicsState state = g.Save();
            using (GraphicsPath clip = GraphicsHelper.RoundedRect(card, 9f))
                g.SetClip(clip, CombineMode.Intersect);

            using (SolidBrush white = new SolidBrush(Color.FromArgb(250, 249, 246)))
                g.FillRectangle(white, card);

            float artW = card.Width - 8f;
            float artH = artW / template.ArtAspect;
            float labelH = 31f;
            if (artH > card.Height - labelH - 4f)
            {
                artH = card.Height - labelH - 4f;
                artW = artH * template.ArtAspect;
            }
            RectangleF art = new RectangleF(card.X + (card.Width - artW) / 2f, card.Y + 3f, artW, artH);
            DrawComposite(g, template, art, photo, style, false);

            // Fade the illustration into the label strip.
            RectangleF labelRect = new RectangleF(card.X, card.Bottom - labelH - 2f, card.Width, labelH + 2f);
            using (LinearGradientBrush fade = new LinearGradientBrush(
                new RectangleF(labelRect.X, labelRect.Y - 12f, labelRect.Width, labelRect.Height + 12f),
                Color.FromArgb(0, 250, 249, 246), Color.FromArgb(255, 250, 249, 246), 90f))
            {
                g.FillRectangle(fade, labelRect);
            }

            using (SolidBrush brandBrush = new SolidBrush(Color.FromArgb(123, 117, 107)))
            using (StringFormat brandFormat = new StringFormat())
            {
                brandFormat.Alignment = StringAlignment.Near;
                g.DrawString(template.Brand, Ui.LatinTinyBold, brandBrush,
                    new RectangleF(card.X + 10f, card.Bottom - labelH - 1f, card.Width - 20f, 12f),
                    brandFormat);
            }
            using (SolidBrush modelBrush = new SolidBrush(Color.FromArgb(29, 28, 26)))
            using (StringFormat modelFormat = new StringFormat())
            {
                modelFormat.Alignment = StringAlignment.Near;
                modelFormat.Trimming = StringTrimming.EllipsisCharacter;
                modelFormat.FormatFlags = StringFormatFlags.NoWrap;
                g.DrawString(template.CardModel, Ui.LatinSmallBold, modelBrush,
                    new RectangleF(card.X + 10f, card.Bottom - labelH + 10f, card.Width - 20f, 18f),
                    modelFormat);
            }

            g.Restore(state);

            if (selected)
            {
                Ui.StrokeRound(g, RectangleF.Inflate(card, -1f, -1f), 10f, Palette.Accent, 2f);
                using (SolidBrush dot = new SolidBrush(Palette.Accent))
                    g.FillEllipse(dot, card.Right - 17f, card.Y + 8f, 7f, 7f);
            }
            else
            {
                Ui.StrokeRound(g, RectangleF.Inflate(card, -0.5f, -0.5f), 9f, Color.FromArgb(224, 220, 211), 1f);
            }
        }
    }
}
