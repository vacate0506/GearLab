using System;
using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace GearLab
{
    public sealed class ExportProgressForm : Form
    {
        private readonly Action<BackgroundWorker> _work;
        private readonly BackgroundWorker _worker;
        private int _progress;
        private string _status = "准备导出…";
        private bool _canceled;
        private bool _finished;
        private Exception _error;
        private bool _hoverCancel;
        private RectangleF _cancelRect;

        public bool Canceled { get { return _canceled; } }
        public Exception Error { get { return _error; } }

        public ExportProgressForm(Action<BackgroundWorker> work)
        {
            _work = work;
            Text = "正在导出";
            FormBorderStyle = FormBorderStyle.None;
            StartPosition = FormStartPosition.CenterParent;
            ShowInTaskbar = false;
            KeyPreview = true;
            DoubleBuffered = true;
            BackColor = Palette.Bg;
            ClientSize = Ui.PS(460f, 218f);

            _worker = new BackgroundWorker();
            _worker.WorkerReportsProgress = true;
            _worker.WorkerSupportsCancellation = true;
            _worker.DoWork += delegate(object sender, DoWorkEventArgs e)
            {
                _work(_worker);
            };
            _worker.ProgressChanged += delegate(object sender, ProgressChangedEventArgs e)
            {
                _progress = e.ProgressPercentage;
                if (e.UserState != null) _status = e.UserState.ToString();
                Invalidate();
            };
            _worker.RunWorkerCompleted += delegate(object sender, RunWorkerCompletedEventArgs e)
            {
                _finished = true;
                if (e.Error != null) _error = e.Error;
                Close();
            };
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
            }
            catch { }
        }

        protected override void OnShown(EventArgs e)
        {
            base.OnShown(e);
            if (Owner != null)
                Location = new Point(Owner.Left + (Owner.Width - Width) / 2,
                    Owner.Top + (Owner.Height - Height) / 2);
            if (!_worker.IsBusy) _worker.RunWorkerAsync();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Ui.Configure(e.Graphics);
            e.Graphics.ScaleTransform(Ui.Scale, Ui.Scale);
            Graphics g = e.Graphics;
            float w = ClientSize.Width / Ui.Scale;
            float h = ClientSize.Height / Ui.Scale;

            using (LinearGradientBrush bg = new LinearGradientBrush(
                new RectangleF(0, 0, w, h), Color.FromArgb(19, 21, 24), Color.FromArgb(12, 13, 16), 90f))
                g.FillRectangle(bg, 0, 0, w, h);
            using (Pen border = new Pen(Color.FromArgb(52, 56, 61), 1f))
                g.DrawRectangle(border, 0.5f, 0.5f, w - 1f, h - 1f);

            Ui.Text(g, _canceled ? "正在停止…" : "正在导出", Ui.Title, Palette.Text, 28f, 28f);
            Ui.Text(g, "所有渲染都在本地完成。", Ui.Micro, Palette.Muted, 28f, 51f);
            Ui.Text(g, _progress + "%", Ui.MonoBold, Palette.Accent, w - 74f, 34f);

            RectangleF track = new RectangleF(28f, 88f, w - 56f, 6f);
            Ui.FillRound(g, track, 3f, Palette.Line);
            float fillW = Math.Max(0f, track.Width * (_progress / 100f));
            if (fillW > 1f) Ui.FillRound(g, new RectangleF(track.X, track.Y, fillW, 6f), 3f, Palette.Accent);

            Ui.Text(g, _status, Ui.Micro, Palette.Muted,
                new RectangleF(28f, 108f, w - 56f, 32f));

            _cancelRect = new RectangleF(w - 28f - 108f, h - 56f, 108f, 34f);
            Ui.FillRound(g, _cancelRect, 8f,
                _canceled ? Palette.PanelSoft : (_hoverCancel ? Palette.SurfaceHover : Palette.Input));
            Ui.StrokeRound(g, _cancelRect, 8f, Palette.LineSoft, 1f);
            Ui.Text(g, _canceled ? "请稍候" : "取消", Ui.Small, _canceled ? Palette.Faint : Palette.TextSoft,
                _cancelRect, StringAlignment.Center, StringAlignment.Center);
            Ui.Text(g, "已完成的照片不会被删除", Ui.Micro, Palette.Faint,
                new RectangleF(28f, h - 49f, 230f, 20f));
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            PointF p = new PointF(e.X / Ui.Scale, e.Y / Ui.Scale);
            bool hover = !_canceled && _cancelRect.Contains(p);
            Cursor = hover ? Cursors.Hand : Cursors.Default;
            if (hover != _hoverCancel)
            {
                _hoverCancel = hover;
                Invalidate();
            }
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            base.OnMouseLeave(e);
            _hoverCancel = false;
            Cursor = Cursors.Default;
            Invalidate();
        }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            if (e.Button != MouseButtons.Left || _canceled) return;
            PointF p = new PointF(e.X / Ui.Scale, e.Y / Ui.Scale);
            if (_cancelRect.Contains(p))
            {
                _canceled = true;
                _status = "正在等待当前照片保存完成…";
                _worker.CancelAsync();
                Invalidate();
            }
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (!_finished && _worker.IsBusy && !_canceled)
            {
                e.Cancel = true;
                _canceled = true;
                _status = "正在等待当前照片保存完成…";
                _worker.CancelAsync();
                Invalidate();
                return;
            }
            base.OnFormClosing(e);
        }
    }
}
