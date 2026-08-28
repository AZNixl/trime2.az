/*
 * SPDX-FileCopyrightText: 2015 - 2026 Rime community
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package com.osfans.trime.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.twotone.FormatPaint
import androidx.compose.material.icons.twotone.Keyboard
import androidx.compose.material.icons.twotone.Palette
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.osfans.trime.Config
import com.osfans.trime.TrimeService
import com.osfans.trime.core.Rime

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun PickerScaffold(
    title: String,
    onBack: () -> Unit,
    actions: @Composable RowScope.() -> Unit = {},
    content: @Composable (PaddingValues) -> Unit,
) {
    Scaffold(
        containerColor = MaterialTheme.colorScheme.surface,
        topBar = {
            TopAppBar(
                title = { Text(title) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = null,
                        )
                    }
                },
                actions = actions,
                colors =
                    TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.surface,
                        titleContentColor = MaterialTheme.colorScheme.onSurface,
                    ),
            )
        },
    ) { innerPadding ->
        content(innerPadding)
    }
}

@Composable
internal fun PickerHint(
    innerPadding: PaddingValues,
    text: String,
) {
    Box(
        modifier =
            Modifier
                .fillMaxSize()
                .padding(innerPadding),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
fun ThemeSelectScreen(onBack: () -> Unit) {
    PickerScaffold(title = "键盘主题", onBack = onBack) { innerPadding ->
        if (Rime.getCurrentRimeSchema() == ".default") {
            PickerHint(innerPadding, "请先正确配置")
            return@PickerScaffold
        }
        val items = remember { LuaNames.themeItems().sortByDisplayName() }
        var current by remember { mutableStateOf(Config.getTheme()) }
        LazyColumn(
            modifier =
                Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
            contentPadding = innerPadding,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                SettingsSection(title = "选择主题") {
                    items.forEachIndexed { index, item ->
                        RadioSettingsItem(
                            icon = Icons.TwoTone.Palette,
                            title = item.displayName,
                            subtitle = null,
                            selected = item.id == current,
                            onClick = {
                                current = item.id
                                Config.setTheme(item.id)
                                TrimeService.getInstance()?.setTheme(item.id)
                                onBack()
                            },
                        )
                        if (index < items.lastIndex) SectionDivider()
                    }
                }
            }
        }
    }
}

@Composable
fun StyleSelectScreen(onBack: () -> Unit) {
    PickerScaffold(title = "颜色样式", onBack = onBack) { innerPadding ->
        if (Rime.getCurrentRimeSchema() == ".default") {
            PickerHint(innerPadding, "请先正确配置")
            return@PickerScaffold
        }
        val items = remember { LuaNames.styleItems().sortByDisplayName() }
        var current by remember { mutableStateOf(Config.getStyle()) }
        LazyColumn(
            modifier =
                Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
            contentPadding = innerPadding,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                SettingsSection(title = "选择样式") {
                    items.forEachIndexed { index, item ->
                        RadioSettingsItem(
                            icon = Icons.TwoTone.FormatPaint,
                            title = item.displayName,
                            subtitle = null,
                            selected = item.id == current,
                            onClick = {
                                current = item.id
                                Config.setStyle(item.id)
                                TrimeService.getInstance()?.setStyle(item.id)
                                onBack()
                            },
                        )
                        if (index < items.lastIndex) SectionDivider()
                    }
                }
            }
        }
    }
}

@Composable
fun KeyboardSelectScreen(onBack: () -> Unit) {
    PickerScaffold(title = "默认键盘", onBack = onBack) { innerPadding ->
        if (Rime.getCurrentRimeSchema() == ".default") {
            PickerHint(innerPadding, "请先正确配置")
            return@PickerScaffold
        }
        val items =
            remember {
                listOf(NamedItem("", "自动匹配")) + LuaNames.keyboardItems().sortByDisplayName()
            }
        var current by remember { mutableStateOf(Config.getKeyboard()) }
        LazyColumn(
            modifier =
                Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
            contentPadding = innerPadding,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                SettingsSection(title = "选择默认键盘") {
                    items.forEachIndexed { index, item ->
                        RadioSettingsItem(
                            icon = Icons.TwoTone.Keyboard,
                            title = item.displayName,
                            subtitle = null,
                            selected = item.id == current,
                            onClick = {
                                current = item.id
                                Config.setKeyboard(item.id)
                                TrimeService.getInstance()?.setKeyboard(item.id)
                                onBack()
                            },
                        )
                        if (index < items.lastIndex) SectionDivider()
                    }
                }
            }
        }
    }
}
