using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Windows.Forms;

namespace GearLab
{
    public sealed class PhotoRail : BufferedControl
    {
        private readonly MainForm _main;
        private int _hoverIndex = -1;
        private int _hoverRemove = -1;
        private bool _hoverAdd;
        private int _scroll;
        private int _contentHeight;

        private const float Pad = 14f;
        private const float HeaderH = 62f;
        private const float FooterH = 88f;
        private const float CardH = 148f;
        private const float CardGap = 9f;
        private const float ThumbH = 112f;

        public PhotoRail(MainForm main)
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

            DrawPanel(g, w, h);
            DrawHeader(g, w);
            DrawFooter(g, w, h);

            RectangleF viewport = new RectangleF(Pad, HeaderH + 8f, w - Pad * 2f, h - HeaderH - FooterH - 16f);
            GraphicsState state = g.Save();
            g.SetClip(viewport, CombineMode.Intersect);

            if (_main.Photos.Count == 0)
            {
                DrawEmpty(g, viewport);
                _contentHeight = 0;
            }
            else
            {
                DrawCards(g, viewport);
            }
            g.Restore(state);
            if (_contentHeight > viewport.Height)
            {
                using (LinearGradientBrush fade = new LinearGradientBrush(
                    new RectangleF(viewport.X, viewport.Bottom - 22f, viewport.Width, 22f),
                    Color.FromArgb(0, 16, 18, 21), Color.FromArgb(255, 16, 18, 21), 90f))
                {
                    g.FillRectangle(fade, viewport.X, viewport.Bottom - 22f, viewport.Width, 22f);
                }
            }
            DrawScrollbar(g, viewport, h);
        }

        private void DrawPanel(Graphics g, float w, float h)
        {
            Ui.FillRound(g, new RectangleF(0, 0, w, h), 14f, Palette.Panel);
            Ui.StrokeRound(g, new RectangleF(0.5f, 0.5f, w - 1f, h - 1f), 14f, Palette.LineSoft, 1f);
        }

        private void DrawHeader(Graphics g, float w)
        {
            Ui.Text(g, "照片库", Ui.Title, Palette.Text, Pad, 18f);
            int count = _main.Photos.Count;
            string countText = count.ToString("00");
            float countW = 24f;
            float countX = Pad + 72f;
            using (SolidBrush brush = new SolidBrush(Palette.PanelSoft))
                g.FillEllipse(brush, countX, 21f, countW, 20f);
            Ui.Text(g, countText, Ui.LatinTinyBold, Palette.Muted,
                new RectangleF(countX, 21f, countW, 20f), StringAlignment.Center, StringAlignment.Center);

            float addSize = 28f;
            RectangleF addRect = new RectangleF(w - Pad - addSize, 16f, addSize, addSize);
            Ui.FillRound(g, addRect, 8f, _hoverAdd ? Palette.SurfaceHover : Palette.PanelSoft);
            Ui.StrokeRound(g, addRect, 8f, _hoverAdd ? Palette.Line : Palette.LineSoft, 1f);
            Ui.DrawPlus(g, addRect.X + addRect.Width / 2f, addRect.Y + addRect.Height / 2f, 11f,
                _hoverAdd ? Palette.Text : Palette.Muted, 1.4f);

            Ui.HLine(g, Pad, HeaderH, w - Pad, Palette.LineSoft);
        }

        private void DrawFooter(Graphics g, float w, float h)
        {
            float y = h - FooterH;
            Ui.HLine(g, Pad, y, w - Pad, Palette.LineSoft);
            PhotoItem selected = _main.SelectedPhoto;
            if (selected == null)
            {
                Ui.Text(g, "拖入照片开始", Ui.Small, Palette.TextSoft, Pad, y + 18f);
                Ui.Text(g, "支持 JPG / PNG / TIFF / BMP", Ui.Tiny, Palette.Faint, Pad, y + 39f);
                Ui.Text(g, "Ctrl + O 导入", Ui.Micro, Palette.Faint, Pad, y + 60f);
                return;
            }

            Ui.Text(g, selected.FileName, Ui.Small, Palette.Text, new RectangleF(Pad, y + 16f, w - Pad * 2f, 18f));
            CameraTemplate selectedCamera = CameraLibrary.Find(selected.CameraId);
            string meta = selected.Width + " × " + selected.Height + " px  ·  " + selectedCamera.CardModel;
            if (!String.IsNullOrEmpty(selected.SizeLabel)) meta += "  ·  " + selected.SizeLabel;
            Ui.Text(g, meta, Ui.Micro, Palette.Muted, Pad, y + 37f);
            Ui.Text(g, "已选 " + _main.ExportSelectionCount + " / " + _main.Photos.Count +
                " 张  ·  右上角勾选批量导出", Ui.Micro, Palette.Faint, Pad, y + 58f);
            Ui.Text(g, "本地处理", Ui.Micro, Palette.Green, w - Pad - 44f, y + 58f);
        }

        private void DrawCards(Graphics g, RectangleF viewport)
        {
            float cardW = viewport.Width - 2f;
            float x = viewport.X;
            float startY = viewport.Y - _scroll;
            _contentHeight = (int)(_main.Photos.Count * (CardH + CardGap) - CardGap);

            for (int i = 0; i < _main.Photos.Count; i++)
            {
                PhotoItem photo = _main.Photos[i];
                float y = startY + i * (CardH + CardGap);
                RectangleF cardRect = new RectangleF(x, y, cardW, CardH);
                if (cardRect.Bottom < viewport.Y - 4f || cardRect.Y > viewport.Bottom + 4f) continue;
                DrawCard(g, photo, i, cardRect, viewport);
            }
        }

        private void DrawCard(Graphics g, PhotoItem photo, int index, RectangleF card, RectangleF viewport)
        {
            bool selected = index == _main.SelectedIndex;
            bool hover = index == _hoverIndex;
            RectangleF thumb = new RectangleF(card.X, card.Y, card.Width, ThumbH);
            GraphicsState state = g.Save();
            using (GraphicsPath clip = GraphicsHelper.RoundedRect(thumb, 9f))
                g.SetClip(clip, CombineMode.Intersect);
            using (SolidBrush fill = new SolidBrush(Color.FromArgb(21, 23, 26)))
                g.FillRectangle(fill, thumb);
            if (photo.Thumbnail != null)
                ImageUtil.DrawCover(g, photo.Thumbnail, thumb, 0f);
            using (LinearGradientBrush fade = new LinearGradientBrush(
                new RectangleF(thumb.X, thumb.Y + thumb.Height - 52f, thumb.Width, 52f),
                Color.FromArgb(0, 0, 0, 0), Color.FromArgb(92, 0, 0, 0), 90f))
            {
                g.FillRectangle(fade, thumb.X, thumb.Y + thumb.Height - 52f, thumb.Width, 52f);
            }
            g.Restore(state);

            Color border = selected ? Palette.Accent : (hover ? Palette.Line : Color.FromArgb(35, 38, 43));
            Ui.StrokeRound(g, thumb, 9f, border, selected ? 2f : 1f);

            string number = (index + 1).ToString("00");
            RectangleF numberRect = new RectangleF(thumb.X + 8f, thumb.Y + 8f, 28f, 20f);
            Ui.FillRound(g, numberRect, 6f, Color.FromArgb(170, 10, 11, 13));
            Ui.Text(g, number, Ui.LatinTinyBold, Color.FromArgb(238, 236, 230),
                numberRect, StringAlignment.Center, StringAlignment.Center);

            if (selected || hover)
            {
                RectangleF removeRect = new RectangleF(thumb.Right - 28f, thumb.Y + 7f, 22f, 22f);
                Ui.FillRound(g, removeRect, 6f, Color.FromArgb(180, 11, 12, 14));
                Ui.DrawClose(g, removeRect.X + 11f, removeRect.Y + 11f, 8f, Color.FromArgb(220, 217, 210), 1.2f);
            }

            Color nameColor = selected ? Palette.Text : Palette.TextSoft;
            Ui.Text(g, photo.FileName, Ui.Small, nameColor,
                new RectangleF(card.X + 1f, thumb.Bottom + 7f, card.Width - 2f, 17f));
            CameraTemplate camera = CameraLibrary.Find(photo.CameraId);
            string meta = photo.Width + " × " + photo.Height + "  ·  " + camera.CardModel;
            Ui.Text(g, meta, Ui.Micro, selected ? Palette.Muted : Palette.Faint,
                new RectangleF(card.X + 1f, thumb.Bottom + 25f, card.Width - 2f, 15f));

            RectangleF checkRect = new RectangleF(thumb.Right - 30f, thumb.Y + 8f, 22f, 22f);
            Ui.FillRound(g, checkRect, 5f, photo.ExportSelected
                ? Palette.Accent : Color.FromArgb(165, 11, 12, 14));
            Ui.StrokeRound(g, checkRect, 5f,
                photo.ExportSelected ? Palette.Accent : Color.FromArgb(130, 255, 255, 255), 1f);
            if (photo.ExportSelected)
            {
                Ui.DrawCheck(g, RectangleF.Inflate(checkRect, -5f, -5f),
                    Color.FromArgb(30, 20, 16), 1.7f);
            }

            if (selected || hover)
            {
                RectangleF removeRect = new RectangleF(thumb.Right - 29f, thumb.Bottom - 29f, 22f, 22f);
                Ui.FillRound(g, removeRect, 6f, Color.FromArgb(185, 11, 12, 14));
                Ui.DrawClose(g, removeRect.X + 11f, removeRect.Y + 11f, 8f,
                    Color.FromArgb(225, 222, 214), 1.2f);
            }

            if (selected)
            {
                using (SolidBrush accent = new SolidBrush(Palette.Accent))
                    g.FillEllipse(accent, card.X, card.Bottom - 7f, 4f, 4f);
            }
        }

        private void DrawEmpty(Graphics g, RectangleF viewport)
        {
            RectangleF area = new RectangleF(viewport.X, viewport.Y + 2f, viewport.Width, Math.Min(306f, viewport.Height - 4f));
            using (Pen pen = new Pen(Palette.Line, 1f))
            {
                pen.DashStyle = DashStyle.Dash;
                pen.DashPattern = new float[] { 3f, 4f };
                using (GraphicsPath path = GraphicsHelper.RoundedRect(area, 12f))
                    g.DrawPath(pen, path);
            }
            float cx = area.X + area.Width / 2f;
            float cy = area.Y + 94f;
            using (SolidBrush circle = new SolidBrush(Palette.PanelSoft))
                g.FillEllipse(circle, cx - 27f, cy - 27f, 54f, 54f);
            Ui.DrawPlus(g, cx, cy, 19f, Palette.Muted, 1.4f);
            Ui.Text(g, "拖入照片", Ui.BodyBold, Palette.TextSoft,
                new RectangleF(area.X, cy + 44f, area.Width, 22f), StringAlignment.Center, StringAlignment.Near);
            Ui.Text(g, "或点击右侧 + 选择文件", Ui.Tiny, Palette.Faint,
                new RectangleF(area.X, cy + 69f, area.Width, 18f), StringAlignment.Center, StringAlignment.Near);
            Ui.Text(g, "JPG  ·  PNG  ·  TIFF  ·  BMP", Ui.Micro, Palette.Faint,
                new RectangleF(area.X, area.Bottom - 42f, area.Width, 16f), StringAlignment.Center, StringAlignment.Near);
        }

        private void DrawScrollbar(Graphics g, RectangleF viewport, float h)
        {
            if (_contentHeight <= viewport.Height) return;
            float trackX = viewport.Right + 3f;
            float trackH = viewport.Height - 10f;
            float thumbH = Math.Max(38f, trackH * (viewport.Height / _contentHeight));
            float maxScroll = Math.Max(1, _contentHeight - (int)viewport.Height);
            float pos = Math.Min(1f, _scroll / maxScroll);
            float thumbY = viewport.Y + 5f + (trackH - thumbH) * pos;
            using (SolidBrush track = new SolidBrush(Color.FromArgb(34, 37, 41)))
                g.FillRectangle(track, trackX, viewport.Y + 5f, 3f, trackH);
            using (SolidBrush thumb = new SolidBrush(Color.FromArgb(112, 114, 116)))
                g.FillRectangle(thumb, trackX, thumbY, 3f, thumbH);
        }

        private RectangleF AddButtonRect(float w)
        {
            return new RectangleF(w - Pad - 28f, 16f, 28f, 28f);
        }

        private RectangleF ViewportRect()
        {
            float w = Width / Ui.Scale;
            float h = Height / Ui.Scale;
            return new RectangleF(Pad, HeaderH + 8f, w - Pad * 2f, h - HeaderH - FooterH - 16f);
        }

        private int IndexAt(PointF p)
        {
            if (_main.Photos.Count == 0) return -1;
            RectangleF viewport = ViewportRect();
            if (!viewport.Contains(p)) return -1;
            float y = p.Y - viewport.Y + _scroll;
            int index = (int)Math.Floor(y / (CardH + CardGap));
            if (index < 0 || index >= _main.Photos.Count) return -1;
            float local = y - index * (CardH + CardGap);
            if (local > CardH) return -1;
            return index;
        }

        private RectangleF CheckRect(int index)
        {
            RectangleF viewport = ViewportRect();
            float y = viewport.Y - _scroll + index * (CardH + CardGap);
            return new RectangleF(viewport.X + viewport.Width - 2f - 30f, y + 8f, 22f, 22f);
        }

        private bool CheckHit(PointF p, int index)
        {
            return CheckRect(index).Contains(p);
        }

        private bool RemoveHit(PointF p, int index)
        {
            RectangleF viewport = ViewportRect();
            float y = viewport.Y - _scroll + index * (CardH + CardGap);
            RectangleF removeRect = new RectangleF(viewport.X + viewport.Width - 2f - 29f,
                y + ThumbH - 29f, 22f, 22f);
            return removeRect.Contains(p);
        }

        private bool EmptyZoneContains(PointF p)
        {
            return _main.Photos.Count == 0 && ViewportRect().Contains(p);
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            PointF p = Ui.LogicalPoint(e.Location);
            bool hoverAdd = AddButtonRect(Width / Ui.Scale).Contains(p);
            int index = IndexAt(p);
            int remove = index >= 0 && RemoveHit(p, index) ? index : -1;
            bool cursorHand = hoverAdd || index >= 0 || EmptyZoneContains(p);
            Cursor = cursorHand ? Cursors.Hand : Cursors.Default;
            if (hoverAdd != _hoverAdd || index != _hoverIndex || remove != _hoverRemove)
            {
                _hoverAdd = hoverAdd;
                _hoverIndex = index;
                _hoverRemove = remove;
                Invalidate();
            }
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            base.OnMouseLeave(e);
            _hoverAdd = false;
            _hoverIndex = -1;
            _hoverRemove = -1;
            Cursor = Cursors.Default;
            Invalidate();
        }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            if (e.Button != MouseButtons.Left) return;
            PointF p = Ui.LogicalPoint(e.Location);
            if (AddButtonRect(Width / Ui.Scale).Contains(p))
            {
                _main.ImportPhotos();
                return;
            }
            int index = IndexAt(p);
            if (index >= 0)
            {
                if (CheckHit(p, index))
                {
                    _main.Photos[index].ExportSelected = !_main.Photos[index].ExportSelected;
                    _main.NotifyExportSelectionChanged();
                    Invalidate();
                }
                else if (RemoveHit(p, index))
                {
                    _main.RemovePhoto(index);
                }
                else
                {
                    _main.SelectPhoto(index);
                }
                return;
            }
            if (EmptyZoneContains(p)) _main.ImportPhotos();
        }

        protected override void OnMouseWheel(MouseEventArgs e)
        {
            base.OnMouseWheel(e);
            if (_contentHeight <= ViewportRect().Height) return;
            int max = _contentHeight - (int)ViewportRect().Height;
            _scroll -= e.Delta / 2;
            if (_scroll < 0) _scroll = 0;
            if (_scroll > max) _scroll = max;
            Invalidate();
        }
    }
}
