/*
 * SPDX-FileCopyrightText: 2015 - 2026 Rime community
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package com.osfans.trime.keyboard;

import android.content.SharedPreferences;
import android.os.SystemClock;
import android.preference.PreferenceManager;
import android.view.HapticFeedbackConstants;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.ViewParent;
import android.view.inputmethod.InputConnection;

import com.androlua.LuaApplication;
import com.osfans.trime.TrimeService;
import com.osfans.trime.core.Rime;

/**
 * 按键手势（原生整合自 AZ 行为脚本）：
 * 1. 退格键向左滑动 → 逐字选择删除，抬起时删除选区；干净单击保持原退格行为
 * 2. 空格键滑动 → 移动光标（左右逐字、上下一行），可选两侧边缘起手进入选择模式
 */
public class KeyGestures {

    // 退格滑动删除
    public static final String PREF_BS_ENABLED = "gesture_bs_enabled";
    public static final String PREF_BS_STEP = "gesture_bs_step";
    public static final String PREF_BS_THRESHOLD = "gesture_bs_threshold";
    // 空格滑动移光标
    public static final String PREF_SPACE_ENABLED = "gesture_space_enabled";
    public static final String PREF_SPACE_HS = "gesture_space_hs";
    public static final String PREF_SPACE_VS = "gesture_space_vs";
    public static final String PREF_SPACE_THRESHOLD = "gesture_space_threshold";
    public static final String PREF_SPACE_SELECT_EDGE = "gesture_space_select_edge";

    private static final int ROLE_NONE = 0;
    private static final int ROLE_BACKSPACE = 1;
    private static final int ROLE_SPACE = 2;

    private static class State {
        int role = ROLE_NONE;
        boolean engaged = false;
        float startX, startY;
        long downTime;
        // 退格选择
        int anchor = -1;
        int selected = 0;
        // 空格移动
        boolean selectMode = false;
        int cursor = -1;
        int total = -1;
    }

    private static SharedPreferences getPrefs() {
        return PreferenceManager.getDefaultSharedPreferences(LuaApplication.getInstance());
    }

    private static int roleOf(KeyView view) {
        if (view.getKey() == null || view.getKey().getClick() == null)
            return ROLE_NONE;
        int code = view.getKey().getClick().getCode();
        if (code == KeyEvent.KEYCODE_DEL)
            return ROLE_BACKSPACE;
        if (code == KeyEvent.KEYCODE_SPACE)
            return ROLE_SPACE;
        return ROLE_NONE;
    }

    private static void requestNoIntercept(KeyView view) {
        ViewParent parent = view.getParent();
        if (parent != null)
            parent.requestDisallowInterceptTouchEvent(true);
    }

    private static void silence(KeyView view) {
        view.setPressed(false);
        view.cancelLongPress();
    }

    /**
     * 在 KeyView.onTouchEvent 开头调用；返回 true 表示事件已被手势消费。
     */
    public static boolean handleTouchEvent(KeyView view, MotionEvent event) {
        State st = (State) view.getTag();
        int action = event.getActionMasked();

        if (action == MotionEvent.ACTION_DOWN) {
            if (st == null) {
                st = new State();
                view.setTag(st);
            }
            st.role = roleOf(view);
            st.engaged = false;
            st.anchor = -1;
            st.selected = 0;
            st.selectMode = false;
            st.cursor = -1;
            st.total = -1;
            st.startX = event.getX();
            st.startY = event.getY();
            st.downTime = SystemClock.uptimeMillis();
            if (st.role == ROLE_SPACE && getPrefs().getBoolean(PREF_SPACE_ENABLED, true)) {
                float edge = getPrefs().getFloat(PREF_SPACE_SELECT_EDGE, 0f);
                float w = view.getWidth();
                if (edge > 0 && w > 0) {
                    float frac = event.getX() / w;
                    st.selectMode = frac < edge || frac > 1 - edge;
                }
            }
            return false; // 放行：保留原生按下态与震动
        }

        if (st == null || st.role == ROLE_NONE)
            return false;

        if (action == MotionEvent.ACTION_MOVE) {
            if (st.role == ROLE_BACKSPACE)
                return handleBackspaceMove(view, st, event);
            else
                return handleSpaceMove(view, st, event);
        }

        if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) {
            if (st.engaged) {
                if (action == MotionEvent.ACTION_UP) {
                    if (st.role == ROLE_BACKSPACE)
                        finishBackspaceDelete(view, st);
                }
                silence(view);
                st.engaged = false;
                st.role = ROLE_NONE;
                return true; // 消费抬起，避免触发按键本身
            }
            st.role = ROLE_NONE;
            return false;
        }
        return false;
    }

    // ---------------- 退格滑动删除 ----------------

    private static boolean handleBackspaceMove(KeyView view, State st, MotionEvent event) {
        SharedPreferences p = getPrefs();
        if (!p.getBoolean(PREF_BS_ENABLED, true))
            return false;
        int threshold = p.getInt(PREF_BS_THRESHOLD, 60);
        int step = p.getInt(PREF_BS_STEP, 51);
        if (step < 8) step = 8;

        float dx = st.startX - event.getX(); // 向左为正
        float dy = Math.abs(event.getY() - st.startY);

        if (!st.engaged) {
            if (dx < threshold || dy > dx)
                return false; // 未过阈值或非左滑，放行
            if (Rime.isComposing())
                return false; // 编码中不打断
            TrimeService trime = TrimeService.getInstance();
            InputConnection ic = trime == null ? null : trime.getCurrentInputConnection();
            if (ic == null)
                return false;
            CharSequence before = ic.getTextBeforeCursor(100000, 0);
            if (before == null || before.length() == 0)
                return false;
            st.anchor = before.length();
            st.engaged = true;
            st.selected = 0;
            silence(view);
            view.cancelLongPress();
            requestNoIntercept(view);
        }

        TrimeService trime = TrimeService.getInstance();
        InputConnection ic = trime == null ? null : trime.getCurrentInputConnection();
        if (ic == null)
            return true;
        int chars = (int) (dx / step);
        if (chars > st.selected) {
            int n = chars - st.selected;
            st.selected = chars;
            int start = Math.max(0, st.anchor - st.selected);
            ic.setSelection(start, st.anchor);
            for (int i = 0; i < n; i++)
                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP,
                        HapticFeedbackConstants.FLAG_IGNORE_GLOBAL_SETTING);
            // 消耗步进，基准前移，保持手感连续
            st.startX -= n * step;
        }
        return true;
    }

    private static void finishBackspaceDelete(KeyView view, State st) {
        if (st.selected <= 0)
            return;
        TrimeService trime = TrimeService.getInstance();
        if (trime == null)
            return;
        InputConnection ic = trime.getCurrentInputConnection();
        if (ic == null)
            return;
        ic.commitText("", 1); // 用空文本替换选区，完成删除
        view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS,
                HapticFeedbackConstants.FLAG_IGNORE_GLOBAL_SETTING);
    }

    // ---------------- 空格滑动移光标 ----------------

    private static boolean handleSpaceMove(KeyView view, State st, MotionEvent event) {
        SharedPreferences p = getPrefs();
        if (!p.getBoolean(PREF_SPACE_ENABLED, true))
            return false;
        int threshold = p.getInt(PREF_SPACE_THRESHOLD, 15);
        int hs = p.getInt(PREF_SPACE_HS, 70);
        int vs = p.getInt(PREF_SPACE_VS, 46);
        if (hs < 5) hs = 5;
        if (vs < 5) vs = 5;

        float hDist = event.getX() - st.startX;
        float vDist = event.getY() - st.startY;

        if (!st.engaged) {
            if (Math.abs(hDist) < threshold && Math.abs(vDist) < threshold)
                return false; // 微动/单击完全放行
            st.engaged = true;
            silence(view);
            view.cancelLongPress();
            requestNoIntercept(view);
            if (st.selectMode) {
                TrimeService trime = TrimeService.getInstance();
                InputConnection ic = trime == null ? null : trime.getCurrentInputConnection();
                if (ic != null) {
                    CharSequence b = ic.getTextBeforeCursor(100000, 0);
                    CharSequence a = ic.getTextAfterCursor(100000, 0);
                    if (b != null && a != null) {
                        st.anchor = b.length();
                        st.cursor = b.length();
                        st.total = b.length() + a.length();
                    } else {
                        st.selectMode = false;
                    }
                } else {
                    st.selectMode = false;
                }
            }
        }

        // 低于单步灵敏度：只接管不移动（消抖）
        if (Math.abs(hDist) < hs && Math.abs(vDist) < vs)
            return true;

        TrimeService trime = TrimeService.getInstance();
        if (trime == null)
            return true;
        InputConnection ic = trime.getCurrentInputConnection();
        if (ic == null)
            return true;

        int hSteps = 0, vSteps = 0;
        if (hDist > hs) hSteps = (int) (hDist / hs);
        else if (hDist < -hs) hSteps = (int) (-hDist / hs);
        if (vDist > vs) vSteps = (int) (vDist / vs);
        else if (vDist < -vs) vSteps = (int) (-vDist / vs);

        if (st.selectMode) {
            int delta = (hSteps > 0 ? hSteps : -hSteps) * (hDist > 0 ? 1 : -1)
                    + (vSteps > 0 ? vSteps : -vSteps) * (vDist > 0 ? 1 : -1) * 40;
            if (delta != 0) {
                int nc = st.cursor + delta;
                if (nc < 0) nc = 0;
                if (nc > st.total) nc = st.total;
                int s = Math.min(st.anchor, nc), e = Math.max(st.anchor, nc);
                if (ic.setSelection(s, e))
                    st.cursor = nc;
                if (hSteps != 0) st.startX += hSteps * hs * (hDist > 0 ? 1 : -1);
                if (vSteps != 0) st.startY += vSteps * vs * (vDist > 0 ? 1 : -1);
            }
        } else {
            for (int i = 0; i < hSteps; i++) {
                if (hDist > 0) {
                    CharSequence t = ic.getTextAfterCursor(1, 0);
                    if (t != null && t.length() > 0) trime.sendEvent("{Right}");
                } else {
                    CharSequence t = ic.getTextBeforeCursor(1, 0);
                    if (t != null && t.length() > 0) trime.sendEvent("{Left}");
                }
            }
            for (int i = 0; i < vSteps; i++) {
                trime.sendEvent(vDist > 0 ? "{Down}" : "{Up}");
            }
            if (hSteps != 0) st.startX += hSteps * hs * (hDist > 0 ? 1 : -1);
            if (vSteps != 0) st.startY += vSteps * vs * (vDist > 0 ? 1 : -1);
        }
        silence(view);
        return true;
    }
}
