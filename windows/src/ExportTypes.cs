using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Threading;

namespace GearLab
{
    public enum ExportScope
    {
        Current,
        Selected
    }

    public enum ExportFormat
    {
        Jpg,
        Png
    }

    public sealed class ExportSettings
    {
        public ExportScope Scope;
        public int Width;
        public ExportFormat Format;
        public int Quality;
        public string Folder;

        public ExportSettings()
        {
            Scope = ExportScope.Current;
            Width = 2160;
            Format = ExportFormat.Jpg;
            Quality = 100;
            Folder = "";
        }

        public ExportSettings Clone()
        {
            ExportSettings copy = new ExportSettings();
            copy.Scope = Scope;
            copy.Width = Width;
            copy.Format = Format;
            copy.Quality = Quality;
            copy.Folder = Folder;
            return copy;
        }

        public string FormatLabel
        {
            get { return Format == ExportFormat.Png ? "PNG" : "JPG"; }
        }

        public string Extension
        {
            get { return Format == ExportFormat.Png ? ".png" : ".jpg"; }
        }
    }

    public sealed class BatchExportResult
    {
        public int Completed;
        public int Failed;
        public readonly List<string> Errors = new List<string>();
    }

    public static class BatchExporter
    {
        public static BatchExportResult Run(IList<string> paths, IList<StyleSettings> styles,
            StyleSettings style, ExportSettings settings, Action<int, string> progress,
            Func<bool> isCanceled)
        {
            if (paths == null || paths.Count == 0) throw new ArgumentException("没有可导出的照片。");
            if (style == null) style = new StyleSettings();
            if (settings == null) settings = new ExportSettings();

            Directory.CreateDirectory(settings.Folder);
            BatchExportResult result = new BatchExportResult();
            int total = paths.Count;
            HashSet<string> usedNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            for (int i = 0; i < paths.Count; i++)
            {
                if (isCanceled != null && isCanceled()) break;

                string path = paths[i];
                try
                {
                    StyleSettings photoStyle = styles != null && i < styles.Count && styles[i] != null
                        ? styles[i] : style;
                    if (photoStyle == null) photoStyle = new StyleSettings();
                    CameraTemplate template = CameraLibrary.Find(photoStyle.CameraId);
                    if (progress != null)
                        progress((int)Math.Round(i * 100.0 / total),
                            "正在渲染 " + (i + 1) + " / " + total + "  ·  " + Path.GetFileName(path));

                    EXIFData exif;
                    int loadEdge = Math.Max(2600, settings.Width * 2);
                    using (Image image = ImageUtil.LoadOriented(path, loadEdge, out exif))
                    using (Bitmap bitmap = RenderEngine.Render(image, template, photoStyle, settings.Width))
                    {
                        string dest = BuildDestination(path, i, total, settings, template, usedNames);
                        RenderEngine.Save(bitmap, dest, settings.Format == ExportFormat.Png ? "png" : "jpg",
                            settings.Quality);
                    }
                    result.Completed++;

                    if (progress != null)
                        progress((int)Math.Round((i + 1) * 100.0 / total),
                            "已保存 " + (i + 1) + " / " + total);
                }
                catch (Exception ex)
                {
                    result.Failed++;
                    result.Errors.Add(Path.GetFileName(path) + ": " + ex.Message);
                }
            }
            return result;
        }

        private static string BuildDestination(string sourcePath, int index, int total,
            ExportSettings settings, CameraTemplate template, HashSet<string> usedNames)
        {
            string source = ImageUtil.SafeFileName(Path.GetFileNameWithoutExtension(sourcePath));
            source = source.Replace(' ', '-');
            string prefix = total > 1 ? "GearLab_" + (index + 1).ToString("00") + "_" : "GearLab_";
            string safeModel = ImageUtil.SafeFileName(template.Model).Replace(' ', '-');
            string baseName = prefix + source + "_" + safeModel;
            string candidate = baseName + settings.Extension;
            int suffix = 2;
            while (usedNames.Contains(candidate) || File.Exists(Path.Combine(settings.Folder, candidate)))
            {
                candidate = baseName + "_" + suffix + settings.Extension;
                suffix++;
            }
            usedNames.Add(candidate);
            return Path.Combine(settings.Folder, candidate);
        }
    }
}
