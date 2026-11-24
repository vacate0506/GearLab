using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

namespace GearLab
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            AppDomain.CurrentDomain.UnhandledException += delegate(object sender, UnhandledExceptionEventArgs e)
            {
                WriteCrashLog(e.ExceptionObject as Exception);
            };
            Application.ThreadException += delegate(object sender, System.Threading.ThreadExceptionEventArgs e)
            {
                WriteCrashLog(e.Exception);
            };

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            bool demo = false;
            string camera = null;
            string exportFolder = null;
            List<string> files = new List<string>();

            for (int i = 0; i < args.Length; i++)
            {
                string arg = args[i];
                if (String.Equals(arg, "--demo", StringComparison.OrdinalIgnoreCase))
                {
                    demo = true;
                }
                else if (String.Equals(arg, "--camera", StringComparison.OrdinalIgnoreCase))
                {
                    if (i + 1 < args.Length) camera = args[++i];
                }
                else if (String.Equals(arg, "--export-dir", StringComparison.OrdinalIgnoreCase))
                {
                    if (i + 1 < args.Length) exportFolder = args[++i];
                }
                else if (File.Exists(arg) && ImageUtil.IsSupported(arg))
                {
                    files.Add(arg);
                }
            }

            using (MainForm form = new MainForm(files.ToArray(), demo, camera, exportFolder))
            {
                Application.Run(form);
            }
        }

        private static void WriteCrashLog(Exception exception)
        {
            try
            {
                string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "GearLab-crash.log");
                File.AppendAllText(path, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + Environment.NewLine +
                    (exception == null ? "Unknown exception" : exception.ToString()) + Environment.NewLine + Environment.NewLine);
            }
            catch
            {
            }
        }
    }
}
