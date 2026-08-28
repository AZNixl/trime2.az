/*
 * SPDX-FileCopyrightText: 2015 - 2026 Rime community
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package com.osfans.trime.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.androlua.LuaUtil
import com.osfans.trime.core.DataManager
import com.osfans.trime.ui.settings.SettingsApp
import com.osfans.trime.ui.theme.TrimeSettingsTheme

class SettingsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DataManager.sync()
        enableEdgeToEdge()
        setContent {
            TrimeSettingsTheme {
                SettingsApp()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        LuaUtil.checkStorage(this)
    }
}
