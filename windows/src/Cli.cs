using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;

namespace GearLab
{
    internal static class Cli
    {
        [STAThread]
        private static int Main(string[] args)
        {
            try
            {
                return Run(args);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("GearLab CLI error: " + ex.Message);
                return 1;
            }
        }

        private static int Run(string[] args)
        {
            if (args.Length == 0 || Has(args, "--help") || Has(args, "-h"))
            {
                PrintHelp();
                return 0;
            }
            if (Has(args, "--list") || Has(args, "--list-cameras"))
            {
                for (int i = 0; i < CameraLibrary.All.Count; i++)
                {
                    CameraTemplate t = CameraLibrary.All[i];
                    Console.WriteLine(t.Id + "\t" + t.DisplayName + "\t" + t.LensLine);
                }
                return 0;
            }
            if (Has(args, "--resources"))
            {
                string[] names = System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceNames();
                Array.Sort(names, StringComparer.Ordinal);
                for (int i = 0; i < names.Length; i++) Console.WriteLine(names[i]);
                return 0;
            }
            if (Has(args, "--extract-test"))
            {
                string folder = Value(args, "--extract-test");
                Console.WriteLine("LocalApplicationData=" + Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData));
                Console.WriteLine("Temp=" + Path.GetTempPath());
                Console.WriteLine("Folder=" + folder);
                Directory.CreateDirectory(folder);
                string[] names = { "dsc-2492-sea.jpg", "dsc-2435-harbor.jpg", "dsc-2387-street.jpg", "dsc-2441-beach.jpg" };
                for (int i = 0; i < names.Length; i++)
                {
                    string path = Path.Combine(folder, names[i]);
                    try
                    {
                        byte[] bytes = EmbeddedAssets.ReadBytes("samples." + names[i]);
                        File.WriteAllBytes(path, bytes);
                        Console.WriteLine("Wrote " + path + " (" + bytes.Length + ")");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine("FAILED " + path + ": " + ex);
                    }
                }
                return 0;
            }

            StyleSettings style = new StyleSettings();
            string cameraId = Value(args, "--camera");
            if (!String.IsNullOrEmpty(cameraId)) style.CameraId = cameraId;
            CameraTemplate template = CameraLibrary.Find(style.CameraId);

            string widthText = Value(args, "--width");
            int width = 2160;
            if (!String.IsNullOrEmpty(widthText)) int.TryParse(widthText, out width);
            if (width < 640) width = 640;
            if (width > 3000) width = 3000;

            string qualityText = Value(args, "--quality");
            int quality = 100;
            if (!String.IsNullOrEmpty(qualityText)) int.TryParse(qualityText, out quality);
            if (quality < 60) quality = 60;
            if (quality > 100) quality = 100;

            string fit = Value(args, "--screen");
            if (fit == "fit") style.ScreenFit = ScreenFitMode.Fit;
            if (fit == "fill") style.ScreenFit = ScreenFitMode.Fill;
            if (Has(args, "--glare")) style.ScreenGlare = true;

            string bg = Value(args, "--bg");
            if (String.IsNullOrEmpty(bg)) bg = Value(args, "--background");
            if (!String.IsNullOrEmpty(bg))
            {
                Color parsed;
                if (!TryParseColor(bg, out parsed))
                {
                    Console.Error.WriteLine("Invalid --bg colour: " + bg);
                    return 2;
                }
                style.TopColor = parsed;
            }

            string title = Value(args, "--title");
            if (title != null) style.Title = title;
            string subtitle = Value(args, "--subtitle");
            if (subtitle != null) style.Subtitle = subtitle;
            if (Has(args, "--no-title")) style.ShowTitle = false;

            string output = Value(args, "--out");
            if (String.IsNullOrEmpty(output))
                output = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "exports");

            bool demo = Has(args, "--demo");
            string input = Value(args, "--input");

            if (demo && String.IsNullOrEmpty(input))
            {
                return RenderDemo(output, style, width, quality);
            }

            if (String.IsNullOrEmpty(input))
            {
                Console.Error.WriteLine("Missing --input. Use --help for usage.");
                return 2;
            }

            List<string> files = new List<string>();
            if (Directory.Exists(input))
            {
                string[] found = Directory.GetFiles(input, "*.*", SearchOption.TopDirectoryOnly);
                Array.Sort(found, StringComparer.OrdinalIgnoreCase);
                for (int i = 0; i < found.Length; i++)
                    if (ImageUtil.IsSupported(found[i])) files.Add(found[i]);
                if (files.Count == 0)
                {
                    found = Directory.GetFiles(input, "*.*", SearchOption.AllDirectories);
                    Array.Sort(found, StringComparer.OrdinalIgnoreCase);
                    for (int i = 0; i < found.Length; i++)
                        if (ImageUtil.IsSupported(found[i])) files.Add(found[i]);
                }
            }
            else if (File.Exists(input))
            {
                files.Add(input);
            }
            else
            {
                Console.Error.WriteLine("Input not found: " + input);
                return 2;
            }

            if (files.Count == 0)
            {
                Console.Error.WriteLine("No supported images found.");
                return 2;
            }

            string extension = String.Equals(Value(args, "--format"), "png", StringComparison.OrdinalIgnoreCase) ? ".png" : ".jpg";
            string singleFile = files.Count == 1 && Path.HasExtension(output) ? output : null;
            if (singleFile != null)
            {
                string ext = Path.GetExtension(singleFile).ToLowerInvariant();
                if (ext == ".png") extension = ".png";
                else if (ext == ".jpg" || ext == ".jpeg") extension = ".jpg";
            }
            else
            {
                Directory.CreateDirectory(output);
            }

            int count = 0;
            for (int i = 0; i < files.Count; i++)
            {
                string dest;
                if (singleFile != null)
                {
                    dest = singleFile;
                }
                else
                {
                    string baseName = ImageUtil.SafeFileName(Path.GetFileNameWithoutExtension(files[i]));
                    dest = Path.Combine(output, "GearLab_" + baseName + "_" + template.Id + extension);
                }

                EXIFData exif;
                using (Image image = ImageUtil.LoadOriented(files[i], Math.Max(2600, width * 2), out exif))
                using (Bitmap bitmap = RenderEngine.Render(image, template, style, width))
                {
                    RenderEngine.Save(bitmap, dest, extension == ".png" ? "png" : "jpg", quality);
                    Console.WriteLine("Rendered " + dest + "  (" + bitmap.Width + " × " + bitmap.Height + ")");
                }
                count++;
            }

            Console.WriteLine("Done. " + count + " file(s).");
            return 0;
        }

        private static int RenderDemo(string outputFolder, StyleSettings baseStyle, int width, int quality)
        {
            string[] samples = EmbeddedAssets.ExtractDemoSamples();
            if (samples.Length == 0)
            {
                Console.Error.WriteLine("Bundled demo photographs are missing.");
                return 3;
            }
            Directory.CreateDirectory(outputFolder);
            string street = samples[0];
            for (int i = 0; i < CameraLibrary.All.Count; i++)
            {
                CameraTemplate template = CameraLibrary.All[i];
                StyleSettings style = baseStyle.Clone();
                style.CameraId = template.Id;

                EXIFData exif;
                using (Image image = ImageUtil.LoadOriented(street, Math.Max(2600, width * 2), out exif))
                using (Bitmap bitmap = RenderEngine.Render(image, template, style, width))
                {
                    string path = Path.Combine(outputFolder, (i + 1).ToString("00") + "-" + template.Id + ".jpg");
                    RenderEngine.Save(bitmap, path, "jpg", quality);
                    Console.WriteLine("Rendered " + path);
                }
            }
            Console.WriteLine("Demo complete: " + outputFolder);
            return 0;
        }

        private static bool TryParseColor(string text, out Color color)
        {
            color = Color.White;
            text = (text ?? "").Trim();
            if (text.Length == 0) return false;
            try
            {
                if (text[0] == '#')
                {
                    string hex = text.Substring(1);
                    if (hex.Length == 3)
                        hex = "" + hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
                    if (hex.Length != 6) return false;
                    int r = Convert.ToInt32(hex.Substring(0, 2), 16);
                    int g = Convert.ToInt32(hex.Substring(2, 2), 16);
                    int b = Convert.ToInt32(hex.Substring(4, 2), 16);
                    color = Color.FromArgb(r, g, b);
                    return true;
                }
                Color named = Color.FromName(text);
                if (!named.IsKnownColor && !named.IsSystemColor) return false;
                color = Color.FromArgb(255, named);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static bool Has(string[] args, string name)
        {
            for (int i = 0; i < args.Length; i++)
                if (String.Equals(args[i], name, StringComparison.OrdinalIgnoreCase)) return true;
            return false;
        }

        private static string Value(string[] args, string name)
        {
            for (int i = 0; i < args.Length; i++)
            {
                if (!String.Equals(args[i], name, StringComparison.OrdinalIgnoreCase)) continue;
                if (i + 1 < args.Length) return args[i + 1];
                return "";
            }
            return null;
        }

        private static void PrintHelp()
        {
            Console.WriteLine("GearLab 器材研究所 · Camera Story Composer");
            Console.WriteLine();
            Console.WriteLine("Usage:");
            Console.WriteLine("  GearLabCLI.exe --input <file-or-folder> --out <file-or-folder> [options]");
            Console.WriteLine("  GearLabCLI.exe --demo --out <folder> [options]");
            Console.WriteLine();
            Console.WriteLine("The camera band and the full photo band each take 1:1 of the canvas height.");
            Console.WriteLine("Use --list-cameras to see the 11 bundled templates.");
            Console.WriteLine();
            Console.WriteLine("Options:");
            Console.WriteLine("  --camera <id>       e.g. ricoh-gr4 | nikon-z8 | lumix-s9-s");
            Console.WriteLine("  --width <px>        Output width, default 2160 (超清)");
            Console.WriteLine("  --quality <60-100>  JPG quality, default 100 (maximum)");
            Console.WriteLine("  --bg <colour>       Camera band background (#RRGGBB or name)");
            Console.WriteLine("  --screen <mode>     fill | fit");
            Console.WriteLine("  --glare             Enable screen glass reflection (off by default)");
            Console.WriteLine("  --title <text>      Custom title (empty uses camera name)");
            Console.WriteLine("  --subtitle <text>   Optional subtitle");
            Console.WriteLine("  --no-title          Hide the title");
            Console.WriteLine("  --format <fmt>      jpg | png");
            Console.WriteLine("  --list-cameras      List bundled camera templates");
        }
    }
}
