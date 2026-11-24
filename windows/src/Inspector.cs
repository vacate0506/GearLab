using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace GearLab
{
    public sealed class Inspector : BufferedControl
    {
        private readonly MainForm _main;
        private readonly TextBox _titleBox;
        private readonly TextBox _subtitleBox;

        private const float Pad = 18f;
        private const float HeaderH = 58f;
        private const float FooterH = 100f;
        private const float ContentTop = 72f;
        private const float CardH = 116f;
        private const float CardGap = 8f;
        private const float FieldH = 32f;

        private float _scroll;
        private float _contentHeight;
        private string _dragSlider = "";
        private string _hover = "";
        private RectangleF _exportCurrentRect;
        private RectangleF _exportBatchRect;
        private RectangleF _resetRect;
        private RectangleF _syncRect;

        private readonly string[] _fitLabels = { "填充", "完整" };
        private float _sec2Y;
        private float _titleFieldY;
        private float _subtitleFieldY;
        private float _end2Y;
        private float _sec3Y;
        private float _aspectY;
        private float _allocationY;
        private float _cameraLabelY;
        private float _cameraTrackY;
        private float _noteY;
        private float _end3Y;
        private float _sec4Y;
        private float _backdropLabelY;
        private float _backdropPresetY;
        private float _end4Y;
        private float _sec5Y;
        private float _fitY;
        private float _glareY;

        private float _cameraScrollX;
        private RectangleF _cameraPrevRect;
        private RectangleF _cameraNextRect;
        private RectangleF _cameraViewportRect;
        private RectangleF _backdropChipRect;
        private readonly RectangleF[] _backdropPresetRects = new RectangleF[8];

        private static readonly Color[] BackdropPresets =
        {
            Color.FromArgb(255, 255, 255),
            Color.FromArgb(244, 239, 230),
            Color.FromArgb(231, 226, 216),
            Color.FromArgb(216, 226, 212),
            Color.FromArgb(213, 226, 235),
            Color.FromArgb(232, 217, 212),
            Color.FromArgb(45, 46, 49),
            Color.FromArgb(23, 24, 27)
        };

        public Inspector(MainForm main)
        {
            _main = main;
            Cursor = Cursors.Default;

            _titleBox = CreateTextBox("留空则使用相机型号", 70);
            _subtitleBox = CreateTextBox("地点 · 日期 · 一句话（可选）", 90);
            _titleBox.TextChanged += delegate
            {
                if (_main.IsSyncingInspector) return;
                _main.Style.Title = _titleBox.Text.Trim();
                _main.ApplyStyleChange();
            };
            _subtitleBox.TextChanged += delegate
            {
                if (_main.IsSyncingInspector) return;
                _main.Style.Subtitle = _subtitleBox.Text.Trim();
                _main.ApplyStyleChange();
            };
            _titleBox.GotFocus += delegate { Invalidate(); };
            _titleBox.LostFocus += delegate { Invalidate(); };
            _subtitleBox.GotFocus += delegate { Invalidate(); };
            _subtitleBox.LostFocus += delegate { Invalidate(); };

            // Fixed vertical rhythm of the inspector. Camera templates scroll
            // horizontally in one compact row so 11 bodies still leave room for
            // the background-colour controls and the screen options.
            _sec2Y = ContentTop + 26f + CardH + 14f + 15f;
            _titleFieldY = _sec2Y + 29f;
            _subtitleFieldY = _titleFieldY + FieldH + 8f;
            _end2Y = _subtitleFieldY + FieldH + 14f;
            _sec3Y = _end2Y + 15f;
            _aspectY = _sec3Y + 28f;
            _allocationY = _aspectY + 26f;
            _cameraLabelY = _allocationY + 32f;
            _cameraTrackY = _cameraLabelY + 22f;
            _noteY = _cameraTrackY + 26f;
            _end3Y = _noteY + 38f;
            _sec4Y = _end3Y + 15f;
            _backdropLabelY = _sec4Y + 28f;
            _backdropPresetY = _backdropLabelY + 28f;
            _end4Y = _backdropPresetY + 42f;
            _sec5Y = _end4Y + 15f;
            _fitY = _sec5Y + 28f;
            _glareY = _fitY + 46f;
            _contentHeight = _glareY + 46f;
        }

        private TextBox CreateTextBox(string cue, int maxLength)
        {
            TextBox box = new TextBox();
            box.BorderStyle = BorderStyle.None;
            box.BackColor = Palette.Input;
            box.ForeColor = Palette.Text;
            box.Font = Ui.Cn(11.2f * Ui.Scale, FontStyle.Regular);
            box.MaxLength = maxLength;
            box.ShortcutsEnabled = true;
            box.TabStop = false;
            Controls.Add(box);
            if (box.IsHandleCreated) SetCue(box, cue);
            else box.HandleCreated += delegate { SetCue(box, cue); };
            return box;
        }

        private static void SetCue(TextBox box, string cue)
        {
            try { NativeMethods.SendMessage(box.Handle, NativeMethods.EM_SETCUEBANNER, 1, cue); }
            catch { }
        }

        public void ReloadFromStyle()
        {
            _main.IsSyncingInspector = true;
            _titleBox.Text = _main.Style.Title;
            _subtitleBox.Text = _main.Style.Subtitle;
            _main.IsSyncingInspector = false;
            UpdateEnabledState();
            UpdateCue();
            EnsureCameraVisible();
            Invalidate();
        }

        public void RefreshCameraCue()
        {
            UpdateCue();
            EnsureCameraVisible();
            Invalidate();
        }

        private void UpdateCue()
        {
            CameraTemplate template = _main.CurrentCamera;
            SetCue(_titleBox, "留空则使用 " + template.DisplayName);
        }

        private void UpdateEnabledState()
        {
            bool enabled = _main.Style.ShowTitle;
            _titleBox.Enabled = enabled;
            _subtitleBox.Enabled = enabled;
            _titleBox.ForeColor = enabled ? Palette.Text : Palette.Faint;
            _subtitleBox.ForeColor = enabled ? Palette.Text : Palette.Faint;
        }

        private float W { get { return Width / Ui.Scale; } }
        private float H { get { return Height / Ui.Scale; } }
        private float ContentW { get { return W - Pad * 2f; } }

        protected override void OnPaint(PaintEventArgs e)
        {
            BeginScaled(e);
            Graphics g = e.Graphics;
            float w = W;
            float h = H;

            DrawPanel(g, w, h);
            DrawHeader(g, w);
            DrawFooter(g, w, h);

            float viewportTop = HeaderH;
            float viewportBottom = h - FooterH;
            RectangleF viewport = new RectangleF(0, viewportTop, w, Math.Max(1f, viewportBottom - viewportTop));
            GraphicsState state = g.Save();
            g.SetClip(viewport, CombineMode.Intersect);
            g.TranslateTransform(0, -_scroll);
            DrawContent(g, w, h);
            g.Restore(state);

            if (ScrollMax > 0f)
            {
                using (LinearGradientBrush fade = new LinearGradientBrush(
                    new RectangleF(0, viewport.Bottom - 20f, w, 20f),
                    Color.FromArgb(0, 16, 18, 21), Color.FromArgb(255, 16, 18, 21), 90f))
                {
                    g.FillRectangle(fade, 0, viewport.Bottom - 20f, w, 20f);
                }
            }
            DrawScrollbar(g, viewport);
            PositionTextBoxes();
        }

        private void DrawPanel(Graphics g, float w, float h)
        {
            Ui.FillRound(g, new RectangleF(0, 0, w, h), 14f, Palette.Panel);
            Ui.StrokeRound(g, new RectangleF(0.5f, 0.5f, w - 1f, h - 1f), 14f, Palette.LineSoft, 1f);
        }

        private void DrawHeader(Graphics g, float w)
        {
            Ui.Text(g, "版面设置", Ui.Title, Palette.Text, Pad, 17f);
            Ui.Tracked(g, "STYLE", Ui.LatinTiny, Palette.Faint, Pad + 76f, 23f, 1.2f);

            _resetRect = new RectangleF(w - Pad - 42f, 17f, 42f, 22f);
            if (_hover == "reset")
                Ui.FillRound(g, _resetRect, 6f, Palette.Surface);
            Ui.Text(g, "重置", Ui.Micro, _hover == "reset" ? Palette.Text : Palette.Muted,
                _resetRect, StringAlignment.Center, StringAlignment.Center);

            _syncRect = new RectangleF(_resetRect.X - 46f, 18f, 36f, 20f);
            Ui.Text(g, "同步全部", Ui.Micro,
                _main.SyncAllPhotos ? Palette.TextSoft : Palette.Faint,
                _syncRect.X - 54f, 23f);
            DrawSwitch(g, _syncRect, _main.SyncAllPhotos, "sync", Palette.Accent);

            Ui.HLine(g, Pad, HeaderH, w - Pad, Palette.LineSoft);
        }

        private void DrawContent(Graphics g, float w, float h)
        {
            DrawSectionHeader(g, w, ContentTop, "01", "相机模板", "");
            DrawCameraStrip(g, w);
            Ui.HLine(g, Pad, ContentTop + 26f + CardH + 14f, w - Pad, Palette.LineSoft);

            // 02 — Title
            DrawSectionHeader(g, w, _sec2Y, "02", "标题与文字", "");
            DrawSwitch(g, new RectangleF(w - Pad - 36f, _sec2Y + 1f, 36f, 20f), _main.Style.ShowTitle,
                "showtitle", Palette.Accent);
            Ui.Text(g, "显示", Ui.Micro, Palette.Faint, w - Pad - 76f, _sec2Y + 4f);
            DrawField(g, new RectangleF(Pad, _titleFieldY, ContentW, FieldH), "标题", _titleBox.Focused);
            DrawField(g, new RectangleF(Pad, _subtitleFieldY, ContentW, FieldH), "副标题", _subtitleBox.Focused);
            Ui.HLine(g, Pad, _end2Y, w - Pad, Palette.LineSoft);

            // 03 — Layout. The canvas is determined by the source photograph:
            // a compact camera/title band above, a full-bleed photo below,
            // with both halves taking exactly 1:1 of the canvas height.
            DrawSectionHeader(g, w, _sec3Y, "03", "版面", "");
            Ui.Text(g, "照片比例", Ui.Small, Palette.TextSoft, Pad, _aspectY);
            DrawStaticValue(g, w, "跟随原图", _aspectY);
            Ui.Text(g, "版面分配", Ui.Small, Palette.TextSoft, Pad, _allocationY);
            DrawStaticValue(g, w, "上下 1 : 1", _allocationY);
            DrawSlider(g, w, _cameraLabelY, "相机大小", "camera",
                _main.Style.CameraScale, 0.34f, 0.72f,
                Math.Round(_main.Style.CameraScale * 100f) + "%");
            Ui.Text(g, "照片完整不裁切；隐藏标题也保持上下 1:1。", Ui.Micro, Palette.Faint, Pad, _noteY);
            Ui.HLine(g, Pad, _end3Y, w - Pad, Palette.LineSoft);

            // 04 — Camera band background color
            DrawSectionHeader(g, w, _sec4Y, "04", "相机背景", "");
            DrawBackdropControls(g, w);

            // 05 — Screen
            DrawSectionHeader(g, w, _sec5Y, "05", "相机屏幕", "");
            Ui.Text(g, "照片显示", Ui.Small, Palette.TextSoft, Pad, _fitY + 8f);
            DrawFitSegment(g, new RectangleF(w - Pad - 132f, _fitY, 132f, 30f));
            Ui.Text(g, "屏幕反光", Ui.Small, Palette.TextSoft, Pad, _glareY + 3f);
            Ui.Text(g, "默认关闭；开启后更接近真实相机的玻璃质感", Ui.Micro, Palette.Faint, Pad, _glareY + 21f);
            DrawSwitch(g, new RectangleF(w - Pad - 36f, _glareY + 1f, 36f, 20f), _main.Style.ScreenGlare,
                "glare", Palette.Accent);

            _contentHeight = _glareY + 46f;
        }

        private void DrawCameraStrip(Graphics g, float w)
        {
            float cardW = (ContentW - CardGap) / 2f;
            float cardsTop = ContentTop + 26f;
            int count = CameraLibrary.All.Count;
            float totalW = count * cardW + (count - 1) * CardGap;
            float maxScroll = Math.Max(0f, totalW - ContentW);
            if (_cameraScrollX > maxScroll) _cameraScrollX = maxScroll;
            if (_cameraScrollX < 0f) _cameraScrollX = 0f;

            _cameraViewportRect = new RectangleF(Pad, cardsTop, ContentW, CardH);
            Ui.Text(g, _main.SyncAllPhotos ? "全部照片同步" : "仅当前照片",
                Ui.Micro, Palette.Faint, w - Pad - 168f, ContentTop + 6f);

            GraphicsState state = g.Save();
            g.SetClip(_cameraViewportRect, CombineMode.Intersect);
            for (int i = 0; i < count; i++)
            {
                float x = Pad - _cameraScrollX + i * (cardW + CardGap);
                if (x + cardW < Pad - 2f || x > Pad + ContentW + 2f) continue;
                CameraTemplate template = CameraLibrary.All[i];
                RectangleF card = new RectangleF(x, cardsTop, cardW, CardH);
                bool selected = template.Id == _main.Style.CameraId;
                CameraRenderer.DrawThumb(g, template, card, _main.SelectedThumbnail, selected, _main.Style);
                if (_hover == "camera:" + template.Id && !selected)
                    Ui.StrokeRound(g, card, 9f, Color.FromArgb(150, 255, 255, 255), 1f);
            }
            g.Restore(state);

            // Horizontal scroll affordance: chevrons plus a slim progress track.
            _cameraPrevRect = new RectangleF(w - Pad - 48f, ContentTop + 3f, 20f, 20f);
            _cameraNextRect = new RectangleF(w - Pad - 23f, ContentTop + 3f, 20f, 20f);
            bool canPrev = _cameraScrollX > 0.5f;
            bool canNext = _cameraScrollX < maxScroll - 0.5f;
            Ui.Text(g, count + " 款", Ui.Micro, Palette.Faint, w - Pad - 76f, ContentTop + 6f);
            Ui.FillRound(g, _cameraPrevRect, 6f,
                _hover == "camera-prev" && canPrev ? Palette.SurfaceHover : Palette.Input);
            Ui.FillRound(g, _cameraNextRect, 6f,
                _hover == "camera-next" && canNext ? Palette.SurfaceHover : Palette.Input);
            Ui.StrokeRound(g, _cameraPrevRect, 6f, Palette.LineSoft, 1f);
            Ui.StrokeRound(g, _cameraNextRect, 6f, Palette.LineSoft, 1f);
            DrawSideChevron(g, _cameraPrevRect.X + 10f, _cameraPrevRect.Y + 10f, 7.5f,
                canPrev ? Palette.TextSoft : Color.FromArgb(70, Palette.Faint), true);
            DrawSideChevron(g, _cameraNextRect.X + 10f, _cameraNextRect.Y + 10f, 7.5f,
                canNext ? Palette.TextSoft : Color.FromArgb(70, Palette.Faint), false);

            if (maxScroll > 0.5f)
            {
                RectangleF track = new RectangleF(Pad, cardsTop + CardH + 4f, ContentW, 3f);
                Ui.FillRound(g, track, 1.5f, Palette.Line);
                float thumbW = Math.Max(30f, ContentW * ContentW / totalW);
                float t = _cameraScrollX / maxScroll;
                RectangleF thumb = new RectangleF(track.X + (track.Width - thumbW) * t,
                    track.Y, thumbW, 3f);
                Ui.FillRound(g, thumb, 1.5f, Color.FromArgb(210, Palette.Accent));
            }
        }

        private void DrawBackdropControls(Graphics g, float w)
        {
            Ui.Text(g, "相机背景", Ui.Small, Palette.TextSoft, Pad, _backdropLabelY);

            Color color = _main.Style.TopColor;
            _backdropChipRect = new RectangleF(w - Pad - 92f, _backdropLabelY - 4f, 92f, 25f);
            Ui.FillRound(g, _backdropChipRect, 7f, color);
            float luma = 0.2126f * color.R + 0.7152f * color.G + 0.0722f * color.B;
            Color chipInk = luma < 145f ? Color.FromArgb(245, 242, 235) : Color.FromArgb(32, 31, 29);
            Ui.StrokeRound(g, RectangleF.Inflate(_backdropChipRect, -0.5f, -0.5f), 7f,
                _hover == "backdrop-custom" ? Palette.Accent : Color.FromArgb(90, 255, 255, 255), 1f);
            string hex = "#" + color.R.ToString("X2") + color.G.ToString("X2") + color.B.ToString("X2");
            Ui.Text(g, hex, Ui.LatinTinyBold, chipInk, _backdropChipRect,
                StringAlignment.Center, StringAlignment.Center);

            for (int i = 0; i < BackdropPresets.Length; i++)
            {
                float per = ContentW / BackdropPresets.Length;
                RectangleF dot = new RectangleF(Pad + per * i + (per - 18f) / 2f,
                    _backdropPresetY, 18f, 18f);
                _backdropPresetRects[i] = dot;
                Color preset = BackdropPresets[i];
                using (SolidBrush brush = new SolidBrush(preset))
                    g.FillEllipse(brush, dot);
                bool same = SameColor(preset, color);
                if (same)
                    Ui.StrokeRound(g, RectangleF.Inflate(dot, 2f, 2f), 11f, Palette.Accent, 1.5f);
                else
                    Ui.StrokeRound(g, RectangleF.Inflate(dot, -0.5f, -0.5f), 9f,
                        _hover == "backdrop:" + i ? Palette.TextSoft : Color.FromArgb(80, 0, 0, 0), 1f);
            }
            Ui.Text(g, "点击色板或右上色块自定义；只影响上半幅", Ui.Micro, Palette.Faint,
                Pad, _backdropPresetY + 25f);
        }

        private static bool SameColor(Color a, Color b)
        {
            return a.R == b.R && a.G == b.G && a.B == b.B;
        }

        private static void DrawSideChevron(Graphics g, float cx, float cy, float size, Color color, bool left)
        {
            using (Pen pen = new Pen(color, 1.4f))
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                float dx = left ? size * 0.28f : -size * 0.28f;
                g.DrawLine(pen, cx + dx, cy - size * 0.42f, cx - dx, cy);
                g.DrawLine(pen, cx - dx, cy, cx + dx, cy + size * 0.42f);
            }
        }

        private void DrawStaticValue(Graphics g, float w, string value, float y)
        {
            Ui.Text(g, value, Ui.Small, Palette.Muted,
                new RectangleF(w - Pad - 110f, y, 110f, 18f), StringAlignment.Far, StringAlignment.Near);
        }

        private void DrawSectionHeader(Graphics g, float w, float y, string number, string title, string value)
        {
            Ui.Text(g, number, Ui.LatinTinyBold, Palette.Accent, Pad, y + 3f);
            Ui.Text(g, title, Ui.SmallBold, Palette.Text, Pad + 25f, y + 1f);
            if (!String.IsNullOrEmpty(value))
                Ui.Text(g, value, Ui.Micro, Palette.Faint, w - Pad - 60f, y + 4f);
        }

        private void DrawField(Graphics g, RectangleF rect, string label, bool focused)
        {
            Ui.Text(g, label, Ui.Micro, Palette.Faint, rect.X, rect.Y + 10f);
            RectangleF box = new RectangleF(rect.X + 52f, rect.Y, rect.Width - 52f, rect.Height);
            Color border = focused ? Palette.Accent : (_main.Style.ShowTitle ? Palette.Line : Palette.LineSoft);
            Ui.FillRound(g, box, 7f, _main.Style.ShowTitle ? Palette.Input : Palette.Panel);
            Ui.StrokeRound(g, box, 7f, border, 1f);
        }

        private void DrawFitSegment(Graphics g, RectangleF rect)
        {
            Ui.FillRound(g, rect, 7f, Palette.Input);
            Ui.StrokeRound(g, rect, 7f, Palette.LineSoft, 1f);
            float cell = rect.Width / 2f;
            for (int i = 0; i < 2; i++)
            {
                bool selected = (int)_main.Style.ScreenFit == i;
                RectangleF r = new RectangleF(rect.X + i * cell + 2f, rect.Y + 2f, cell - 4f, rect.Height - 4f);
                if (selected)
                {
                    Ui.FillRound(g, r, 5f, Palette.Surface);
                    Ui.StrokeRound(g, r, 5f, Palette.Line, 1f);
                }
                Ui.Text(g, _fitLabels[i], Ui.Micro, selected ? Palette.Accent : Palette.Muted,
                    r, StringAlignment.Center, StringAlignment.Center);
            }
        }

        private void DrawSlider(Graphics g, float w, float y, string label, string id, float value,
            float min, float max, string valueText)
        {
            Ui.Text(g, label, Ui.Small, Palette.TextSoft, Pad, y);
            Ui.Text(g, valueText, Ui.Mono, Palette.Muted, w - Pad - 38f, y + 1f);
            float trackY = y + 22f;
            float trackW = w - Pad * 2f;
            RectangleF track = new RectangleF(Pad, trackY, trackW, 4f);
            Ui.FillRound(g, track, 2f, Palette.Line);
            float t = (value - min) / (max - min);
            if (t < 0f) t = 0f;
            if (t > 1f) t = 1f;
            float thumbX = track.X + trackW * t;
            Ui.FillRound(g, new RectangleF(track.X, track.Y, Math.Max(2f, trackW * t), 4f), 2f, Palette.Accent);
            using (SolidBrush outer = new SolidBrush(Palette.Panel))
                g.FillEllipse(outer, thumbX - 7f, trackY - 5f, 14f, 14f);
            using (SolidBrush knob = new SolidBrush(_dragSlider == id ? Palette.AccentHover : Palette.Accent))
                g.FillEllipse(knob, thumbX - 4f, trackY - 3f, 8f, 8f);
            if (_dragSlider == id)
            {
                using (Pen ring = new Pen(Color.FromArgb(90, Palette.Accent), 1f))
                    g.DrawEllipse(ring, thumbX - 9f, trackY - 8f, 18f, 18f);
            }
        }

        private void DrawSwitch(Graphics g, RectangleF rect, bool on, string id, Color accent)
        {
            Ui.FillRound(g, rect, rect.Height / 2f, on ? Palette.AccentSoft : Palette.Input);
            Ui.StrokeRound(g, rect, rect.Height / 2f, on ? Color.FromArgb(80, accent) : Palette.Line, 1f);
            float knob = rect.Height - 6f;
            float x = on ? rect.Right - knob - 3f : rect.X + 3f;
            using (SolidBrush brush = new SolidBrush(on ? accent : Palette.Faint))
                g.FillEllipse(brush, x, rect.Y + 3f, knob, knob);
        }

        private void DrawFooter(Graphics g, float w, float h)
        {
            float y = h - FooterH;
            Ui.HLine(g, Pad, y, w - Pad, Palette.LineSoft);
            int selectedCount = _main.ExportSelectionCount;
            bool canSingle = _main.HasPhotos && !_main.IsBusy;
            bool canBatch = canSingle && selectedCount > 0;
            float currentW = 132f;
            _exportCurrentRect = new RectangleF(Pad, y + 15f, currentW, 44f);
            _exportBatchRect = new RectangleF(Pad + currentW + 8f, y + 15f,
                ContentW - currentW - 8f, 44f);

            Color currentFill = !canSingle ? Palette.Surface :
                (_hover == "export-current" ? Palette.SurfaceHover : Palette.Input);
            Ui.FillRound(g, _exportCurrentRect, 9f, currentFill);
            Ui.StrokeRound(g, _exportCurrentRect, 9f, Palette.Line, 1f);
            Ui.Text(g, "导出当前", Ui.Small, canSingle ? Palette.Text : Palette.Faint,
                _exportCurrentRect, StringAlignment.Center, StringAlignment.Center);

            Color batchFill = !canBatch ? Palette.Surface :
                (_hover == "export-batch" ? Palette.AccentHover : Palette.Accent);
            Ui.FillRound(g, _exportBatchRect, 9f, batchFill);
            Color batchInk = canBatch ? Color.FromArgb(29, 19, 15) : Palette.Faint;
            Ui.DrawDownload(g, _exportBatchRect.X + 22f, _exportBatchRect.Y + 22f, 14f, batchInk, 1.5f);
            Ui.Text(g, "批量导出 " + selectedCount, Ui.SmallBold, batchInk,
                _exportBatchRect.X + 36f, _exportBatchRect.Y + 13f);
            Ui.Text(g, "PNG/JPG", Ui.LatinTiny, canBatch ? Color.FromArgb(63, 46, 38) : Palette.Faint,
                _exportBatchRect.Right - 51f, _exportBatchRect.Y + 15f);

            string info = "完整照片  ·  不裁切  ·  本地处理";
            PhotoItem selected = _main.SelectedPhoto;
            if (selected != null)
            {
                float aspect = selected.Width / (float)Math.Max(1, selected.Height);
                info = "完整照片  ·  " +
                    RenderEngine.DimensionsLabel(1080, aspect, _main.CurrentCamera, _main.Style) +
                    " px  ·  本地处理";
            }
            Ui.Text(g, info, Ui.Micro, Palette.Faint, Pad, y + 70f);
        }

        private float ScrollMax
        {
            get
            {
                float visible = H - FooterH - HeaderH;
                float contentSpan = Math.Max(visible, _contentHeight - HeaderH);
                return Math.Max(0f, contentSpan - visible);
            }
        }

        private void DrawScrollbar(Graphics g, RectangleF viewport)
        {
            float max = ScrollMax;
            if (max <= 0f) return;
            float visible = viewport.Height;
            float trackH = visible - 14f;
            float contentSpan = Math.Max(visible, _contentHeight - HeaderH);
            float thumbH = Math.Max(34f, trackH * (visible / contentSpan));
            float pos = Math.Min(1f, _scroll / max);
            float x = W - 6f;
            using (SolidBrush track = new SolidBrush(Color.FromArgb(34, 37, 41)))
                g.FillRectangle(track, x, HeaderH + 7f, 3f, trackH);
            using (SolidBrush thumb = new SolidBrush(Color.FromArgb(112, 114, 116)))
                g.FillRectangle(thumb, x, HeaderH + 7f + (trackH - thumbH) * pos, 3f, thumbH);
        }

        private void PositionTextBoxes()
        {
            if (_titleBox == null) return;
            PlaceTextBox(_titleBox, Pad + 52f + 10f, _titleFieldY, ContentW - 52f - 20f);
            PlaceTextBox(_subtitleBox, Pad + 52f + 10f, _subtitleFieldY, ContentW - 52f - 20f);
        }

        private void PlaceTextBox(TextBox box, float x, float contentY, float width)
        {
            float top = contentY - _scroll;
            int h = Math.Max(Ui.Px(18f), box.PreferredHeight);
            box.SetBounds(Ui.Px(x), Ui.Px(top + (FieldH - h / Ui.Scale) / 2f), Ui.Px(width), h);
            float viewTop = HeaderH;
            float viewBottom = H - FooterH;
            bool inView = top >= viewTop - 2f && top + FieldH <= viewBottom + 2f;
            box.Visible = _main.Style.ShowTitle && inView;
        }

        protected override void OnSizeChanged(EventArgs e)
        {
            base.OnSizeChanged(e);
            if (_titleBox != null)
            {
                _titleBox.Font = Ui.Cn(11.2f * Ui.Scale, FontStyle.Regular);
                _subtitleBox.Font = Ui.Cn(11.2f * Ui.Scale, FontStyle.Regular);
            }
            ClampScroll();
            PositionTextBoxes();
            Invalidate();
        }

        private void ClampScroll()
        {
            float max = ScrollMax;
            if (_scroll > max) _scroll = max;
            if (_scroll < 0f) _scroll = 0f;
        }

        private float CameraCardWidth
        {
            get { return (ContentW - CardGap) / 2f; }
        }

        private float CameraMaxScroll
        {
            get
            {
                int count = CameraLibrary.All.Count;
                float totalW = count * CameraCardWidth + Math.Max(0, count - 1) * CardGap;
                return Math.Max(0f, totalW - ContentW);
            }
        }

        private RectangleF CameraCardRect(int index)
        {
            float top = ContentTop + 26f - _scroll;
            float x = Pad - _cameraScrollX + index * (CameraCardWidth + CardGap);
            return new RectangleF(x, top, CameraCardWidth, CardH);
        }

        private bool CameraRowContains(PointF p)
        {
            float top = ContentTop + 26f - _scroll;
            return p.Y >= top - 2f && p.Y <= top + CardH + 2f &&
                   p.X >= Pad && p.X <= Pad + ContentW;
        }

        private void ScrollCameras(int direction)
        {
            _cameraScrollX += direction * (CameraCardWidth + CardGap);
            if (_cameraScrollX < 0f) _cameraScrollX = 0f;
            if (_cameraScrollX > CameraMaxScroll) _cameraScrollX = CameraMaxScroll;
            Invalidate();
        }

        private void EnsureCameraVisible()
        {
            int index = 0;
            for (int i = 0; i < CameraLibrary.All.Count; i++)
            {
                if (CameraLibrary.All[i].Id == _main.Style.CameraId) { index = i; break; }
            }
            float left = index * (CameraCardWidth + CardGap);
            float right = left + CameraCardWidth;
            if (left < _cameraScrollX) _cameraScrollX = left;
            if (right > _cameraScrollX + ContentW) _cameraScrollX = right - ContentW;
            if (_cameraScrollX < 0f) _cameraScrollX = 0f;
            if (_cameraScrollX > CameraMaxScroll) _cameraScrollX = CameraMaxScroll;
        }

        private RectangleF FitRect()
        {
            return new RectangleF(W - Pad - 132f, _fitY - _scroll, 132f, 30f);
        }

        private RectangleF ShowTitleSwitchRect()
        {
            return new RectangleF(W - Pad - 36f, _sec2Y + 1f - _scroll, 36f, 20f);
        }

        private RectangleF GlareSwitchRect()
        {
            return new RectangleF(W - Pad - 36f, _glareY + 1f - _scroll, 36f, 20f);
        }

        private string HitTest(PointF p)
        {
            if (_syncRect.Contains(p)) return "sync";
            if (_resetRect.Contains(p)) return "reset";
            if (_main.HasPhotos && !_main.IsBusy && _exportCurrentRect.Contains(p))
                return "export-current";
            if (_main.HasPhotos && !_main.IsBusy && _main.ExportSelectionCount > 0 &&
                _exportBatchRect.Contains(p)) return "export-batch";

            RectangleF prev = new RectangleF(_cameraPrevRect.X, _cameraPrevRect.Y - _scroll,
                _cameraPrevRect.Width, _cameraPrevRect.Height);
            RectangleF next = new RectangleF(_cameraNextRect.X, _cameraNextRect.Y - _scroll,
                _cameraNextRect.Width, _cameraNextRect.Height);
            if (_cameraScrollX > 0.5f && prev.Contains(p)) return "camera-prev";
            if (_cameraScrollX < CameraMaxScroll - 0.5f && next.Contains(p)) return "camera-next";

            if (CameraRowContains(p))
            {
                for (int i = 0; i < CameraLibrary.All.Count; i++)
                {
                    if (CameraCardRect(i).Contains(p)) return "camera:" + CameraLibrary.All[i].Id;
                }
            }

            RectangleF chip = new RectangleF(_backdropChipRect.X, _backdropChipRect.Y - _scroll,
                _backdropChipRect.Width, _backdropChipRect.Height);
            if (chip.Contains(p)) return "backdrop-custom";
            for (int i = 0; i < _backdropPresetRects.Length; i++)
            {
                RectangleF dot = _backdropPresetRects[i];
                if (dot.IsEmpty) continue;
                RectangleF hitDot = new RectangleF(dot.X, dot.Y - _scroll, dot.Width, dot.Height);
                if (hitDot.Contains(p)) return "backdrop:" + i;
            }

            RectangleF fit = FitRect();
            if (fit.Contains(p))
                return p.X < fit.X + fit.Width / 2f ? "fit:fill" : "fit:fit";
            if (ShowTitleSwitchRect().Contains(p)) return "showtitle";
            if (GlareSwitchRect().Contains(p)) return "glare";
            if (Math.Abs(p.Y - (_cameraTrackY - _scroll)) < 16f &&
                p.X >= Pad - 8f && p.X <= W - Pad + 8f) return "slider:camera";
            return "";
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            PointF p = Ui.LogicalPoint(e.Location);
            if (_dragSlider.Length > 0)
            {
                UpdateSlider(p);
                return;
            }
            string hit = HitTest(p);
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
            _hover = "";
            Cursor = Cursors.Default;
            Invalidate();
        }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            if (e.Button != MouseButtons.Left) return;
            PointF p = Ui.LogicalPoint(e.Location);
            string hit = HitTest(p);
            if (hit == "sync")
            {
                _main.SetSyncAllPhotos(!_main.SyncAllPhotos);
                Invalidate();
                return;
            }
            if (hit == "reset")
            {
                _main.ResetStyle();
                ReloadFromStyle();
                return;
            }
            if (hit == "export-current")
            {
                _main.RequestExport(false);
                return;
            }
            if (hit == "export-batch")
            {
                _main.RequestExport(true);
                return;
            }
            if (hit == "camera-prev")
            {
                ScrollCameras(-1);
                return;
            }
            if (hit == "camera-next")
            {
                ScrollCameras(1);
                return;
            }
            if (hit == "backdrop-custom")
            {
                PickBackdropColor();
                return;
            }
            if (hit.StartsWith("backdrop:"))
            {
                int index;
                if (int.TryParse(hit.Substring(9), out index) &&
                    index >= 0 && index < BackdropPresets.Length)
                {
                    _main.Style.TopColor = BackdropPresets[index];
                    _main.ApplyStyleChange();
                }
                return;
            }
            if (hit.StartsWith("camera:"))
            {
                _main.SelectCamera(hit.Substring(7));
                RefreshCameraCue();
                return;
            }
            if (hit.StartsWith("fit:"))
            {
                _main.Style.ScreenFit = hit == "fit:fill" ? ScreenFitMode.Fill : ScreenFitMode.Fit;
                _main.ApplyStyleChange();
                return;
            }
            if (hit == "showtitle")
            {
                _main.Style.ShowTitle = !_main.Style.ShowTitle;
                UpdateEnabledState();
                _main.ApplyStyleChange();
                return;
            }
            if (hit == "glare")
            {
                _main.Style.ScreenGlare = !_main.Style.ScreenGlare;
                _main.ApplyStyleChange();
                return;
            }
            if (hit.StartsWith("slider:"))
            {
                _dragSlider = hit.Substring(7);
                UpdateSlider(p);
                return;
            }
        }

        protected override void OnMouseUp(MouseEventArgs e)
        {
            base.OnMouseUp(e);
            if (_dragSlider.Length > 0)
            {
                _dragSlider = "";
                Invalidate();
            }
        }

        protected override void OnMouseWheel(MouseEventArgs e)
        {
            base.OnMouseWheel(e);
            PointF p = Ui.LogicalPoint(e.Location);
            if (CameraRowContains(p))
            {
                if (CameraMaxScroll <= 0f) return;
                _cameraScrollX -= e.Delta / 2f;
                if (_cameraScrollX < 0f) _cameraScrollX = 0f;
                if (_cameraScrollX > CameraMaxScroll) _cameraScrollX = CameraMaxScroll;
                Invalidate();
                return;
            }
            float max = ScrollMax;
            if (max <= 0f) return;
            _scroll -= e.Delta / 4f;
            if (_scroll < 0f) _scroll = 0f;
            if (_scroll > max) _scroll = max;
            PositionTextBoxes();
            Invalidate();
        }

        private void PickBackdropColor()
        {
            using (ColorDialog dialog = new ColorDialog())
            {
                dialog.FullOpen = true;
                dialog.Color = _main.Style.TopColor;
                if (dialog.ShowDialog(this) != DialogResult.OK) return;
                _main.Style.TopColor = Color.FromArgb(255, dialog.Color);
                _main.ApplyStyleChange();
            }
        }

        private void UpdateSlider(PointF p)
        {
            float trackW = W - Pad * 2f;
            float t = (p.X - Pad) / trackW;
            if (t < 0f) t = 0f;
            if (t > 1f) t = 1f;
            if (_dragSlider == "camera")
                _main.Style.CameraScale = 0.34f + t * 0.38f;
            _main.Style.Clamp();
            _main.ApplyStyleChange();
        }
    }
}
