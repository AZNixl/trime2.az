/*
 * SPDX-FileCopyrightText: 2015 - 2026 Rime community
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package com.osfans.trime.candidate;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.GradientDrawable;
import android.preference.PreferenceManager;
import android.text.TextUtils;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.PopupWindow;
import android.widget.ScrollView;
import android.widget.TextView;

import com.androlua.LuaApplication;
import com.osfans.trime.TrimeService;
import com.osfans.trime.core.CandidateItem;
import com.osfans.trime.core.Rime;
import com.osfans.trime.theme.KeyStyle;
import com.osfans.trime.theme.Style;
import com.osfans.trime.theme.ThemeManager;

import java.util.ArrayList;

/**
 * 展开候选面板（原生整合自 AZ 候选面板显示优化脚本）。
 * 点击候选栏 ▽ 打开：卡片式全部候选，支持笔划筛选、工具栏四方位停靠。
 */
public class CandidatePanelView extends LinearLayout {

    public static final String PREF_TOOL_POS = "candidate_panel_toolpos";

    private static final int MAX_PER_ROW = 6;
    private static final int PAGE_SIZE = 500;

    private final TrimeService mTrime;
    private final String mToolPos;
    private final boolean mVerticalBar; // 工具栏在左/右
    private LinearLayout mContent;
    private View mScroll; // ScrollView 或 HorizontalScrollView
    private FrameLayout mTrack;
    private View mThumb;
    private PopupWindow mPopup;

    // 配色
    private final int mPanelBg;
    private final int mCardBg;
    private final int mTextColor;
    private final int mCommentColor;
    private final int mAccent;

    public CandidatePanelView(Context context) {
        super(context);
        mTrime = TrimeService.getInstance();
        mToolPos = PreferenceManager.getDefaultSharedPreferences(context)
                .getString(PREF_TOOL_POS, "bottom");
        mVerticalBar = mToolPos.equals("left") || mToolPos.equals("right");

        Style root = ThemeManager.getStyle();
        KeyStyle key = root.getKeyStyle("key", root.getKeyStyle("key"));
        mCardBg = key.getBackgroundColor();
        mTextColor = key.getTextColor();
        mCommentColor = adjustAlpha(mTextColor, 0x99);
        Style kb = root.getStyle("keyboard");
        mPanelBg = kb.getBackgroundColor(0xFFE3E4E9);
        KeyStyle enter = root.getKeyStyle("enter", key);
        int accent = enter.getBackgroundColor();
        mAccent = (accent == 0 || accent == Color.TRANSPARENT) ? 0xFF30C190 : accent;

        setOrientation(mVerticalBar ? HORIZONTAL : VERTICAL);
        setBackgroundColor(mPanelBg);
        int pad = dp(4);
        setPadding(pad, pad, pad, pad);
        build();
    }

    private static int dp(float v) {
        return ThemeManager.dp2px(v);
    }

    private static int adjustAlpha(int color, int alpha) {
        return (color & 0x00FFFFFF) | (alpha << 24);
    }

    private GradientDrawable roundRect(int color, int radius) {
        GradientDrawable gd = new GradientDrawable();
        gd.setColor(color);
        gd.setCornerRadius(radius);
        return gd;
    }

    private void build() {
        // 滚动区
        if (mVerticalBar) {
            ScrollView sv = new ScrollView(getContext());
            sv.setVerticalScrollBarEnabled(false);
            mScroll = sv;
            mContent = new LinearLayout(getContext());
            mContent.setOrientation(VERTICAL);
            sv.addView(mContent, new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        } else {
            HorizontalScrollView hv = new HorizontalScrollView(getContext());
            hv.setHorizontalScrollBarEnabled(false);
            mScroll = hv;
            mContent = new LinearLayout(getContext());
            mContent.setOrientation(HORIZONTAL);
            hv.addView(mContent, new ViewGroup.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT));
        }

        // 工具列/行：▲ 收起、滚动条、笔（笔划筛选）
        TextView btnClose = makeToolButton("▲", "收起");
        btnClose.setOnClickListener(v -> close());

        TextView btnStroke = makeToolButton("笔", "笔划筛选");
        btnStroke.setOnClickListener(v -> {
            if (mPopup != null && mPopup.isShowing()) {
                dismissPopup();
            } else {
                showStrokePopup(v);
            }
        });
        btnStroke.setOnLongClickListener(v -> {
            showPosPopup(v);
            return true;
        });

        mTrack = new FrameLayout(getContext());
        mThumb = new View(getContext());
        mThumb.setBackground(roundRect(mAccent, dp(10)));
        attachScrollSync();

        if (mVerticalBar) {
            LinearLayout side = new LinearLayout(getContext());
            side.setOrientation(VERTICAL);
            side.setGravity(Gravity.CENTER_HORIZONTAL);
            LayoutParams closeLp = new LayoutParams(LayoutParams.MATCH_PARENT, dp(40));
            closeLp.setMargins(dp(2), dp(2), dp(2), dp(2));
            side.addView(btnClose, closeLp);
            LayoutParams trackLp = new LayoutParams(dp(40), 0);
            trackLp.weight = 1;
            trackLp.setMargins(0, dp(2), 0, dp(2));
            side.addView(mTrack, trackLp);
            LayoutParams strokeLp = new LayoutParams(LayoutParams.MATCH_PARENT, dp(40));
            strokeLp.setMargins(dp(2), dp(2), dp(2), dp(2));
            side.addView(btnStroke, strokeLp);
            FrameLayout.LayoutParams thumbLp = new FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, dp(72));
            thumbLp.leftMargin = dp(2);
            thumbLp.rightMargin = dp(2);
            mTrack.addView(mThumb, thumbLp);

            LayoutParams scrollLp = new LayoutParams(0, LayoutParams.MATCH_PARENT);
            scrollLp.weight = 1;
            LayoutParams sideLp = new LayoutParams(dp(44), LayoutParams.MATCH_PARENT);
            if (mToolPos.equals("left")) {
                addView(side, sideLp);
                addView(mScroll, scrollLp);
            } else {
                addView(mScroll, scrollLp);
                addView(side, sideLp);
            }
        } else {
            LinearLayout toolRow = new LinearLayout(getContext());
            toolRow.setOrientation(HORIZONTAL);
            toolRow.setGravity(Gravity.CENTER_VERTICAL);
            LayoutParams closeLp = new LayoutParams(dp(40), dp(40));
            closeLp.setMargins(dp(2), dp(2), dp(2), dp(2));
            toolRow.addView(btnClose, closeLp);
            LayoutParams trackLp = new LayoutParams(0, dp(40));
            trackLp.weight = 1;
            trackLp.setMargins(dp(4), 0, dp(4), 0);
            toolRow.addView(mTrack, trackLp);
            LayoutParams strokeLp = new LayoutParams(dp(40), dp(40));
            strokeLp.setMargins(dp(2), dp(2), dp(2), dp(2));
            toolRow.addView(btnStroke, strokeLp);
            FrameLayout.LayoutParams thumbLp = new FrameLayout.LayoutParams(dp(72), LayoutParams.MATCH_PARENT);
            thumbLp.topMargin = dp(2);
            thumbLp.bottomMargin = dp(2);
            mTrack.addView(mThumb, thumbLp);

            LayoutParams contentLp = new LayoutParams(LayoutParams.MATCH_PARENT, 0);
            contentLp.weight = 1;
            if (mToolPos.equals("top")) {
                addView(toolRow, new LayoutParams(LayoutParams.MATCH_PARENT, dp(46)));
                addView(mScroll, contentLp);
            } else {
                addView(mScroll, contentLp);
                addView(toolRow, new LayoutParams(LayoutParams.MATCH_PARENT, dp(46)));
            }
        }

        fill();
    }

    private TextView makeToolButton(String text, String desc) {
        TextView tv = new TextView(getContext());
        tv.setText(text);
        tv.setTextSize(15);
        tv.setTextColor(mTextColor);
        tv.setGravity(Gravity.CENTER);
        tv.setBackground(roundRect(adjustAlpha(mCardBg, 0xFF), dp(14)));
        tv.setContentDescription(desc);
        return tv;
    }

    // ---------------- 候选填充 ----------------

    public void fill() {
        CandidatesManager.reset();
        ArrayList<CandidateItem> items = CandidatesManager.next(PAGE_SIZE);
        if (mVerticalBar) {
            buildRows(items);
        } else {
            buildColumns(items);
        }
        scrollHome();
    }

    private void scrollHome() {
        if (mScroll instanceof ScrollView)
            ((ScrollView) mScroll).smoothScrollTo(0, 0);
        else if (mScroll instanceof HorizontalScrollView)
            ((HorizontalScrollView) mScroll).smoothScrollTo(0, 0);
    }

    private View makeCard(CandidateItem item, int widthPx) {
        LinearLayout card = new LinearLayout(getContext());
        card.setOrientation(VERTICAL);
        card.setGravity(Gravity.CENTER);
        card.setBackground(roundRect(mCardBg, dp(12)));
        int padH = dp(10), padV = dp(6);
        card.setPadding(padH, padV, padH, padV);

        TextView tv = new TextView(getContext());
        tv.setText(item.getText());
        tv.setTextSize(TypedValue.COMPLEX_UNIT_SP, 17);
        tv.setTextColor(mTextColor);
        tv.setGravity(Gravity.CENTER);
        tv.setMaxLines(1);
        tv.setEllipsize(TextUtils.TruncateAt.END);
        card.addView(tv, new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));

        String comment = item.getComment();
        if (!TextUtils.isEmpty(comment)) {
            TextView cv = new TextView(getContext());
            cv.setText(comment);
            cv.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            cv.setTextColor(mCommentColor);
            cv.setGravity(Gravity.CENTER);
            cv.setMaxLines(1);
            cv.setEllipsize(TextUtils.TruncateAt.END);
            card.addView(cv, new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));
        }

        card.setOnClickListener(v -> {
            int idx = item.getIndex();
            mTrime.selectCandidate(idx);
            if (!Rime.isComposing()) {
                close();
            } else {
                fill();
            }
        });
        return card;
    }

    private int measureCardWidth(CandidateItem item) {
        TextView probe = new TextView(getContext());
        probe.setTextSize(TypedValue.COMPLEX_UNIT_SP, 17);
        probe.setText(item.getText());
        probe.measure(0, 0);
        int w = probe.getMeasuredWidth() + dp(20);
        String comment = item.getComment();
        if (!TextUtils.isEmpty(comment)) {
            TextView pc = new TextView(getContext());
            pc.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            pc.setText(comment);
            pc.measure(0, 0);
            w = Math.max(w, pc.getMeasuredWidth() + dp(20));
        }
        return w;
    }

    // 竖向模式：行拼装（每行最多 MAX_PER_ROW 张卡片）
    private void buildRows(ArrayList<CandidateItem> items) {
        mContent.removeAllViews();
        int screenW = getResources().getDisplayMetrics().widthPixels;
        int sideW = mVerticalBar ? dp(48) : dp(4);
        int rowAvail = screenW - dp(4) * 2 - sideW;

        int n = items.size();
        int i = 0;
        while (i < n) {
            ArrayList<Integer> rowItems = new ArrayList<>();
            rowItems.add(i);
            int rowNeed = measureCardWidth(items.get(i));
            i++;
            while (i < n && rowItems.size() < MAX_PER_ROW) {
                int w = measureCardWidth(items.get(i));
                if (rowNeed + w + dp(6) * (rowItems.size() + 1) > rowAvail) break;
                rowItems.add(i);
                rowNeed += w;
                i++;
            }
            LinearLayout row = new LinearLayout(getContext());
            row.setOrientation(HORIZONTAL);
            for (int idx : rowItems) {
                int w = Math.max(1, measureCardWidth(items.get(idx)));
                View card = makeCard(items.get(idx), w);
                LinearLayout.LayoutParams lp = new LayoutParams(w, LayoutParams.WRAP_CONTENT);
                lp.setMargins(dp(3), dp(3), dp(3), dp(3));
                row.addView(card, lp);
            }
            mContent.addView(row, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));
        }
    }

    // 横向模式：列拼装（每列竖排，列宽取最宽卡片）
    private void buildColumns(ArrayList<CandidateItem> items) {
        mContent.removeAllViews();
        int availH = mScroll.getHeight();
        if (availH <= 0) {
            post(() -> buildColumns(items));
            return;
        }
        TextView probe = new TextView(getContext());
        probe.setTextSize(TypedValue.COMPLEX_UNIT_SP, 17);
        probe.setText("字");
        probe.measure(0, 0);
        int lineH = probe.getMeasuredHeight() + dp(12);
        TextView probe2 = new TextView(getContext());
        probe2.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        probe2.setText("注");
        probe2.measure(0, 0);
        int cardH1 = lineH + dp(12);
        int cardH2 = cardH1 + probe2.getMeasuredHeight() + dp(2);

        ArrayList<ArrayList<CandidateItem>> columns = new ArrayList<>();
        ArrayList<Integer> colWidths = new ArrayList<>();
        ArrayList<CandidateItem> col = new ArrayList<>();
        int colH = 0, colW = 0;
        for (CandidateItem item : items) {
            int ch = TextUtils.isEmpty(item.getComment()) ? cardH1 : cardH2;
            int cw = measureCardWidth(item);
            if (colH > 0 && colH + ch > availH) {
                columns.add(col);
                colWidths.add(colW);
                col = new ArrayList<>();
                colH = 0;
                colW = 0;
            }
            colH += ch;
            if (cw > colW) colW = cw;
            col.add(item);
        }
        if (!col.isEmpty()) {
            columns.add(col);
            colWidths.add(colW);
        }

        for (int c = 0; c < columns.size(); c++) {
            LinearLayout colView = new LinearLayout(getContext());
            colView.setOrientation(VERTICAL);
            for (CandidateItem item : columns.get(c)) {
                View card = makeCard(item, colWidths.get(c));
                LinearLayout.LayoutParams lp = new LayoutParams(colWidths.get(c), LayoutParams.WRAP_CONTENT);
                lp.setMargins(dp(3), dp(3), dp(3), dp(3));
                colView.addView(card, lp);
            }
            mContent.addView(colView, new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT));
        }
    }

    // ---------------- 滚动条同步与拖动 ----------------

    private void attachScrollSync() {
        Runnable sync = new Runnable() {
            @Override
            public void run() {
                updateThumb();
            }
        };
        if (mScroll instanceof ScrollView) {
            ((ScrollView) mScroll).getViewTreeObserver()
                    .addOnScrollChangedListener(sync);
        } else if (mScroll instanceof HorizontalScrollView) {
            ((HorizontalScrollView) mScroll).getViewTreeObserver()
                    .addOnScrollChangedListener(sync);
        }
        mThumb.setOnTouchListener((v, ev) -> {
            switch (ev.getActionMasked()) {
                case android.view.MotionEvent.ACTION_DOWN:
                case android.view.MotionEvent.ACTION_MOVE:
                    dragThumb(ev);
                    return true;
            }
            return false;
        });
    }

    private int scrollOffset() {
        if (mScroll instanceof ScrollView)
            return mScroll.getScrollY();
        return mScroll.getScrollX();
    }

    private int viewportSize() {
        if (mScroll instanceof ScrollView)
            return mScroll.getHeight();
        return mScroll.getWidth();
    }

    private int contentSize() {
        if (mScroll instanceof ScrollView)
            return mContent.getHeight();
        return mContent.getWidth();
    }

    private int contentRange() {
        return Math.max(0, contentSize() - viewportSize());
    }

    private void updateThumb() {
        if (mTrack == null || mThumb == null) return;
        int range = contentRange();
        if (mVerticalBar) {
            int trackH = mTrack.getHeight();
            int thumbH = mThumb.getHeight();
            if (trackH <= 0 || thumbH <= 0) return;
            if (range <= 0) {
                mThumb.setTranslationY(0);
                return;
            }
            float frac = (float) scrollOffset() / range;
            float max = trackH - thumbH;
            mThumb.setTranslationY(frac * max);
        } else {
            int trackW = mTrack.getWidth();
            int thumbW = mThumb.getWidth();
            if (trackW <= 0 || thumbW <= 0) return;
            if (range <= 0) {
                mThumb.setTranslationX(0);
                return;
            }
            float frac = (float) scrollOffset() / range;
            float max = trackW - thumbW;
            mThumb.setTranslationX(frac * max);
        }
    }

    private void dragThumb(android.view.MotionEvent ev) {
        int range = contentRange();
        if (range <= 0) return;
        if (mVerticalBar) {
            int trackH = mTrack.getHeight();
            int thumbH = mThumb.getHeight();
            float max = trackH - thumbH;
            if (max <= 0) return;
            float y = ev.getY() - thumbH / 2f;
            if (y < 0) y = 0;
            if (y > max) y = max;
            int target = (int) (y / max * range);
            if (mScroll instanceof ScrollView)
                ((ScrollView) mScroll).scrollTo(0, target);
        } else {
            int trackW = mTrack.getWidth();
            int thumbW = mThumb.getWidth();
            float max = trackW - thumbW;
            if (max <= 0) return;
            float x = ev.getX() - thumbW / 2f;
            if (x < 0) x = 0;
            if (x > max) x = max;
            int target = (int) (x / max * range);
            if (mScroll instanceof HorizontalScrollView)
                ((HorizontalScrollView) mScroll).scrollTo(target, 0);
        }
    }

    // ---------------- 笔划筛选弹层 ----------------

    private void showStrokePopup(View anchor) {
        dismissPopup();
        LinearLayout row = new LinearLayout(getContext());
        row.setOrientation(HORIZONTAL);
        row.setGravity(Gravity.CENTER);
        row.setPadding(dp(8), dp(6), dp(8), dp(6));
        row.setBackground(roundRect(mCardBg, dp(12)));

        String[][] strokes = {
                {"h", "一"}, {"s", "丨"}, {"p", "丿"}, {"n", "丶"}, {"z", "乙"}, {null, "✕"},
        };
        for (String[] st : strokes) {
            TextView btn = new TextView(getContext());
            btn.setText(st[1]);
            btn.setTextSize(18);
            btn.setTextColor(st[0] != null ? mTextColor : mAccent);
            btn.setGravity(Gravity.CENTER);
            btn.setBackground(roundRect(adjustAlpha(mPanelBg, 0xFF), dp(14)));
            LinearLayout.LayoutParams lp = new LayoutParams(dp(44), dp(44));
            lp.setMargins(dp(3), dp(3), dp(3), dp(3));
            btn.setLayoutParams(lp);
            btn.setOnClickListener(v -> {
                if (st[0] != null) {
                    CandidatesManager.filterStroke(st[0], st[1]);
                } else {
                    CandidatesManager.resetFilter();
                }
                fill();
            });
            row.addView(btn);
        }

        mPopup = new PopupWindow(row, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        mPopup.setOutsideTouchable(false);
        mPopup.setBackgroundDrawable(new ColorDrawable(0));
        row.measure(0, 0);
        int w = row.getMeasuredWidth();
        int h = row.getMeasuredHeight();
        mPopup.showAsDropDown(anchor, -(w - anchor.getWidth()), -h - anchor.getHeight() - dp(8));
    }

    // ---------------- 工具栏位置菜单（长按 笔） ----------------

    private void showPosPopup(View anchor) {
        dismissPopup();
        LinearLayout col = new LinearLayout(getContext());
        col.setOrientation(VERTICAL);
        col.setPadding(dp(8), dp(8), dp(8), dp(8));
        col.setBackground(roundRect(mCardBg, dp(12)));

        String[][] opts = {
                {"顶部", "top"}, {"底部", "bottom"}, {"左侧", "left"}, {"右侧", "right"},
        };
        for (String[] opt : opts) {
            TextView btn = new TextView(getContext());
            btn.setText(opt[0]);
            btn.setTextSize(15);
            btn.setGravity(Gravity.CENTER);
            boolean selected = opt[1].equals(mToolPos);
            btn.setTextColor(selected ? 0xFFFFFFFF : mTextColor);
            btn.setBackground(roundRect(selected ? mAccent : adjustAlpha(mPanelBg, 0xFF), dp(14)));
            LinearLayout.LayoutParams lp = new LayoutParams(dp(88), dp(40));
            lp.setMargins(dp(2), dp(3), dp(2), dp(3));
            btn.setLayoutParams(lp);
            btn.setOnClickListener(v -> {
                PreferenceManager.getDefaultSharedPreferences(LuaApplication.getInstance())
                        .edit().putString(PREF_TOOL_POS, opt[1]).apply();
                dismissPopup();
                rebuild();
            });
            col.addView(btn);
        }

        mPopup = new PopupWindow(col, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        mPopup.setOutsideTouchable(true);
        mPopup.setBackgroundDrawable(new ColorDrawable(0));
        col.measure(0, 0);
        int w = col.getMeasuredWidth();
        int h = col.getMeasuredHeight();
        mPopup.showAsDropDown(anchor, -(w - anchor.getWidth()), -h - anchor.getHeight() - dp(8));
    }

    private void dismissPopup() {
        if (mPopup != null) {
            try {
                mPopup.dismiss();
            } catch (Exception ignored) {
            }
            mPopup = null;
        }
    }

    /** 位置变更后重建：由 TrimeService 重新创建并显示面板 */
    private void rebuild() {
        TrimeService trime = TrimeService.getInstance();
        if (trime != null) {
            trime.showCandidatePanel();
        }
    }

    public void close() {
        dismissPopup();
        CandidatesManager.resetFilter();
        TrimeService trime = TrimeService.getInstance();
        if (trime != null) {
            trime.hideCandidatePanel();
        }
    }

    @Override
    protected void onDetachedFromWindow() {
        dismissPopup();
        super.onDetachedFromWindow();
    }
}
