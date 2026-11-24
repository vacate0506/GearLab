using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;

namespace GearLab
{
    public enum ScreenFitMode
    {
        Fill,
        Fit
    }

    public sealed class CameraTemplate
    {
        public string Id;
        public string Brand;
        public string Model;
        public string DisplayName;
        public string CardModel;
        public string LensLine;
        public string ResourceName;
        public float ArtAspect;
        public RectangleF Screen;
        public string Accent;
        public bool IsRealProduct;

        public CameraTemplate(string id, string brand, string model, string displayName,
            string cardModel, string lensLine, string resourceName, float artAspect,
            RectangleF screen, string accent, bool isRealProduct)
        {
            Id = id;
            Brand = brand;
            Model = model;
            DisplayName = displayName;
            CardModel = cardModel;
            LensLine = lensLine;
            ResourceName = resourceName;
            ArtAspect = artAspect;
            Screen = screen;
            Accent = accent;
            IsRealProduct = isRealProduct;
        }
    }

    public sealed class StyleSettings
    {
        public string CameraId;
        public float CameraScale;
        public bool ShowTitle;
        public string Title;
        public string Subtitle;
        public ScreenFitMode ScreenFit;
        public bool ScreenGlare;
        public Color TopColor;

        public StyleSettings()
        {
            CameraId = "ricoh-gr4";
            CameraScale = 0.50f;
            ShowTitle = true;
            Title = "";
            Subtitle = "";
            ScreenFit = ScreenFitMode.Fill;
            ScreenGlare = false;
            TopColor = Color.White;
        }

        public StyleSettings Clone()
        {
            StyleSettings copy = new StyleSettings();
            copy.CameraId = CameraId;
            copy.CameraScale = CameraScale;
            copy.ShowTitle = ShowTitle;
            copy.Title = Title;
            copy.Subtitle = Subtitle;
            copy.ScreenFit = ScreenFit;
            copy.ScreenGlare = ScreenGlare;
            copy.TopColor = TopColor;
            return copy;
        }

        public void CopyFrom(StyleSettings other)
        {
            if (other == null) return;
            CameraId = other.CameraId;
            CameraScale = other.CameraScale;
            ShowTitle = other.ShowTitle;
            Title = other.Title;
            Subtitle = other.Subtitle;
            ScreenFit = other.ScreenFit;
            ScreenGlare = other.ScreenGlare;
            TopColor = other.TopColor;
        }

        public void Clamp()
        {
            if (CameraScale < 0.34f) CameraScale = 0.34f;
            if (CameraScale > 0.72f) CameraScale = 0.72f;
            if (Title == null) Title = "";
            if (Subtitle == null) Subtitle = "";
        }
    }

    public sealed class PhotoItem
    {
        public string Path;
        public string FileName;
        public long FileSize;
        public int Width;
        public int Height;
        public string CaptureCamera;
        public string CameraId;
        public StyleSettings Style;
        public bool ExportSelected = true;
        public Image Thumbnail;

        private Image _preview;

        public Image Preview
        {
            get
            {
                if (_preview == null)
                {
                    EXIFData ignored;
                    _preview = ImageUtil.LoadOriented(Path, 2600, out ignored);
                }
                return _preview;
            }
        }

        public void DropPreview()
        {
            if (_preview != null)
            {
                _preview.Dispose();
                _preview = null;
            }
        }

        public void Dispose()
        {
            DropPreview();
            if (Thumbnail != null)
            {
                Thumbnail.Dispose();
                Thumbnail = null;
            }
        }

        public string SizeLabel
        {
            get
            {
                if (FileSize <= 0) return "";
                if (FileSize >= 1024L * 1024L)
                    return (FileSize / (1024.0 * 1024.0)).ToString("0.0", CultureInfo.InvariantCulture) + " MB";
                return Math.Max(1, (int)Math.Round(FileSize / 1024.0)) + " KB";
            }
        }

        public string FormatLabel
        {
            get
            {
                string ext = System.IO.Path.GetExtension(FileName).TrimStart('.').ToUpperInvariant();
                if (ext == "JPEG" || ext == "JPE") ext = "JPG";
                return ext;
            }
        }
    }

    public sealed class EXIFData
    {
        public string CameraName;

        public EXIFData()
        {
            CameraName = "";
        }

        public static EXIFData FromImage(Image image)
        {
            EXIFData data = new EXIFData();
            try
            {
                string make = ReadAscii(image, 0x010F);
                string model = ReadAscii(image, 0x0110);
                if (!String.IsNullOrWhiteSpace(model))
                {
                    if (!String.IsNullOrWhiteSpace(make) &&
                        !model.StartsWith(make, StringComparison.OrdinalIgnoreCase))
                        data.CameraName = make + " " + model;
                    else
                        data.CameraName = model;
                }
                else if (!String.IsNullOrWhiteSpace(make))
                {
                    data.CameraName = make;
                }
            }
            catch
            {
            }
            return data;
        }

        private static string ReadAscii(Image image, int tag)
        {
            try
            {
                int[] ids = image.PropertyIdList;
                for (int i = 0; i < ids.Length; i++)
                {
                    if (ids[i] != tag) continue;
                    PropertyItem item = image.GetPropertyItem(tag);
                    if (item == null || item.Value == null) return "";
                    string text = System.Text.Encoding.ASCII.GetString(item.Value).Trim('\0', ' ', '\r', '\n');
                    return text;
                }
            }
            catch
            {
            }
            return "";
        }
    }

    public static class ImageUtil
    {
        public static readonly string[] SupportedExtensions =
            { ".jpg", ".jpeg", ".jpe", ".png", ".bmp", ".tif", ".tiff" };

        public static bool IsSupported(string path)
        {
            if (String.IsNullOrWhiteSpace(path)) return false;
            string ext = System.IO.Path.GetExtension(path).ToLowerInvariant();
            for (int i = 0; i < SupportedExtensions.Length; i++)
                if (SupportedExtensions[i] == ext) return true;
            return false;
        }

        public static PhotoItem Inspect(string path)
        {
            PhotoItem item = new PhotoItem();
            item.Path = path;
            item.FileName = System.IO.Path.GetFileName(path);
            try { item.FileSize = new FileInfo(path).Length; }
            catch { item.FileSize = 0; }

            using (Image source = Image.FromFile(path))
            {
                EXIFData exif = EXIFData.FromImage(source);
                item.CaptureCamera = exif.CameraName;
                int orientation = ReadOrientation(source);
                item.Width = SwapOrientation(orientation) ? source.Height : source.Width;
                item.Height = SwapOrientation(orientation) ? source.Width : source.Height;
                item.Thumbnail = CreateOriented(source, orientation, 520);
            }
            return item;
        }

        public static Image LoadOriented(string path, int maxEdge, out EXIFData exif)
        {
            using (Image source = Image.FromFile(path))
            {
                exif = EXIFData.FromImage(source);
                int orientation = ReadOrientation(source);
                return CreateOriented(source, orientation, maxEdge);
            }
        }

        public static Bitmap CreateOriented(Image source, int orientation, int maxEdge)
        {
            int srcW = source.Width;
            int srcH = source.Height;
            double scale = 1.0;
            if (maxEdge > 0)
            {
                int longEdge = Math.Max(srcW, srcH);
                if (longEdge > maxEdge) scale = (double)maxEdge / longEdge;
            }
            int drawW = Math.Max(1, (int)Math.Round(srcW * scale));
            int drawH = Math.Max(1, (int)Math.Round(srcH * scale));
            int finalW = SwapOrientation(orientation) ? drawH : drawW;
            int finalH = SwapOrientation(orientation) ? drawW : drawH;

            Bitmap bitmap = new Bitmap(finalW, finalH, PixelFormat.Format32bppArgb);
            bitmap.SetResolution(96, 96);
            using (Graphics g = Graphics.FromImage(bitmap))
            {
                g.CompositingQuality = CompositingQuality.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.DrawImage(source, new Rectangle(0, 0, drawW, drawH));
            }

            RotateFlipType transform;
            if (TryGetTransform(orientation, out transform)) bitmap.RotateFlip(transform);
            return bitmap;
        }

        public static int ReadOrientation(Image image)
        {
            try
            {
                int[] ids = image.PropertyIdList;
                for (int i = 0; i < ids.Length; i++)
                {
                    if (ids[i] != 0x0112) continue;
                    PropertyItem item = image.GetPropertyItem(0x0112);
                    if (item == null || item.Value == null || item.Value.Length < 2) return 1;
                    return BitConverter.ToUInt16(item.Value, 0);
                }
            }
            catch
            {
            }
            return 1;
        }

        private static bool SwapOrientation(int orientation)
        {
            return orientation >= 5 && orientation <= 8;
        }

        private static bool TryGetTransform(int orientation, out RotateFlipType transform)
        {
            switch (orientation)
            {
                case 2: transform = RotateFlipType.RotateNoneFlipX; return true;
                case 3: transform = RotateFlipType.Rotate180FlipNone; return true;
                case 4: transform = RotateFlipType.RotateNoneFlipY; return true;
                case 5: transform = RotateFlipType.Rotate90FlipX; return true;
                case 6: transform = RotateFlipType.Rotate90FlipNone; return true;
                case 7: transform = RotateFlipType.Rotate270FlipX; return true;
                case 8: transform = RotateFlipType.Rotate270FlipNone; return true;
                default: transform = RotateFlipType.RotateNoneFlipNone; return false;
            }
        }

        public static void DrawCover(Graphics g, Image image, RectangleF dest, float radius)
        {
            if (image == null || dest.Width <= 0 || dest.Height <= 0) return;
            GraphicsState state = g.Save();
            if (radius > 0.1f)
            {
                using (GraphicsPath clip = GraphicsHelper.RoundedRect(dest, radius))
                    g.SetClip(clip, CombineMode.Intersect);
            }
            else
            {
                g.SetClip(dest, CombineMode.Intersect);
            }

            double scale = Math.Max(dest.Width / image.Width, dest.Height / image.Height);
            double dw = image.Width * scale;
            double dh = image.Height * scale;
            float dx = dest.X + (dest.Width - (float)dw) / 2f;
            float bias = 0.5f;
            if (image.Height > image.Width * 1.12 && dest.Width > dest.Height * 1.12)
                bias = 0.28f;
            float dy = dest.Y + (dest.Height - (float)dh) * bias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(image, new RectangleF(dx, dy, (float)dw, (float)dh));
            g.Restore(state);
        }

        public static void DrawFit(Graphics g, Image image, RectangleF dest)
        {
            if (image == null || dest.Width <= 0 || dest.Height <= 0) return;
            double scale = Math.Min(dest.Width / image.Width, dest.Height / image.Height);
            float dw = (float)(image.Width * scale);
            float dh = (float)(image.Height * scale);
            float dx = dest.X + (dest.Width - dw) / 2f;
            float dy = dest.Y + (dest.Height - dh) / 2f;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(image, new RectangleF(dx, dy, dw, dh));
        }

        public static string SafeFileName(string name)
        {
            if (String.IsNullOrWhiteSpace(name)) return "GearLab";
            char[] invalid = System.IO.Path.GetInvalidFileNameChars();
            for (int i = 0; i < invalid.Length; i++)
                name = name.Replace(invalid[i], '-');
            name = name.Trim('-', ' ', '.');
            if (name.Length == 0) return "GearLab";
            if (name.Length > 80) name = name.Substring(0, 80).TrimEnd('-');
            return name;
        }
    }

    public static class GraphicsHelper
    {
        public static GraphicsPath RoundedRect(RectangleF bounds, float radius)
        {
            GraphicsPath path = new GraphicsPath();
            float diameter = Math.Max(0, radius * 2f);
            if (diameter <= 0.1f)
            {
                path.AddRectangle(bounds);
                path.CloseFigure();
                return path;
            }
            if (diameter > bounds.Width) diameter = bounds.Width;
            if (diameter > bounds.Height) diameter = bounds.Height;
            RectangleF arc = new RectangleF(bounds.X, bounds.Y, diameter, diameter);
            path.AddArc(arc, 180, 90);
            arc.X = bounds.Right - diameter;
            path.AddArc(arc, 270, 90);
            arc.Y = bounds.Bottom - diameter;
            path.AddArc(arc, 0, 90);
            arc.X = bounds.X;
            path.AddArc(arc, 90, 90);
            path.CloseFigure();
            return path;
        }

        public static void FillRounded(Graphics g, RectangleF bounds, float radius, Color color)
        {
            using (GraphicsPath path = RoundedRect(bounds, radius))
            using (SolidBrush brush = new SolidBrush(color))
                g.FillPath(brush, path);
        }

        public static void StrokeRounded(Graphics g, RectangleF bounds, float radius, Color color, float width)
        {
            using (GraphicsPath path = RoundedRect(bounds, radius))
            using (Pen pen = new Pen(color, width))
                g.DrawPath(pen, path);
        }

        public static void DrawShadow(Graphics g, RectangleF rect, float radius, float strength)
        {
            for (int i = 10; i >= 1; i--)
            {
                float grow = i * 1.8f;
                int alpha = (int)(strength * (1.0f - (float)i / 12f) * 0.05f * 255f);
                if (alpha <= 0) continue;
                RectangleF layer = RectangleF.Inflate(rect, grow, grow * 0.75f);
                layer.Y += grow * 0.45f;
                using (GraphicsPath path = RoundedRect(layer, radius + grow))
                using (SolidBrush brush = new SolidBrush(Color.FromArgb(alpha, 0, 0, 0)))
                    g.FillPath(brush, path);
            }
        }
    }
}
