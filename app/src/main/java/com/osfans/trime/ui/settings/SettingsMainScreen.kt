/*
 * SPDX-FileCopyrightText: 2015 - 2026 Rime community
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Main screen layout ported from the Xime project (GPL-3.0),
 * https://github.com/AZNixl/Xime.az
 */

package com.osfans.trime.ui.settings

import android.content.Intent
import android.net.Uri
import android.view.inputmethod.InputMethodManager
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.twotone.Ballot
import androidx.compose.material.icons.twotone.CloudUpload
import androidx.compose.material.icons.twotone.Extension
import androidx.compose.material.icons.twotone.Folder
import androidx.compose.material.icons.twotone.FormatPaint
import androidx.compose.material.icons.twotone.GetApp
import androidx.compose.material.icons.twotone.Keyboard
import androidx.compose.material.icons.twotone.KeyboardAlt
import androidx.compose.material.icons.twotone.Palette
import androidx.compose.material.icons.twotone.ToggleOn
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MediumTopAppBar
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusEvent
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.osfans.trime.ToolActivity
import com.osfans.trime.TrimeService
import com.osfans.trime.dialog.DeployDialog

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsMainContent(
    onNavigateToSchemaGroup: () -> Unit,
    onNavigateToSchemaManage: () -> Unit,
    onNavigateToSchemaSelect: () -> Unit,
    onNavigateToTheme: () -> Unit,
    onNavigateToStyle: () -> Unit,
    onNavigateToKeyboard: () -> Unit,
) {
    val context = LocalContext.current
    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        containerColor = MaterialTheme.colorScheme.surface,
        topBar = {
            MediumTopAppBar(
                title = { Text("设置") },
                colors =
                TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    scrolledContainerColor = MaterialTheme.colorScheme.surface,
                    navigationIconContentColor = Color.Unspecified,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                    actionIconContentColor = Color.Unspecified,
                ),
                scrollBehavior = scrollBehavior,
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier =
            Modifier
                .fillMaxSize()
                .nestedScroll(scrollBehavior.nestedScrollConnection)
                .consumeWindowInsets(innerPadding)
                .padding(horizontal = 16.dp)
                .imePadding(),
            contentPadding = innerPadding,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                SettingsSection(title = "输入法") {
                    SettingsItem(
                        icon = Icons.TwoTone.ToggleOn,
                        title = "切换输入法",
                        subtitle = "选择当前使用的输入法",
                        onClick = {
                            val imm =
                                context.getSystemService(android.content.Context.INPUT_METHOD_SERVICE)
                                    as InputMethodManager
                            imm.showInputMethodPicker()
                        },
                    )
                    SectionDivider()
                    var testText by remember { mutableStateOf("") }
                    var isFocused by remember { mutableStateOf(false) }
                    Column(
                        modifier =
                        Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                    ) {
                        Box(
                            modifier =
                            Modifier
                                .fillMaxWidth()
                                .onFocusEvent { isFocused = it.isFocused }
                                .clip(RoundedCornerShape(28.dp))
                                .background(
                                    if (isFocused) {
                                        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                                    } else {
                                        MaterialTheme.colorScheme.onSurface.copy(alpha = 0.04f)
                                    },
                                ).padding(horizontal = 16.dp, vertical = 14.dp),
                        ) {
                            BasicTextField(
                                value = testText,
                                onValueChange = { testText = it },
                                modifier = Modifier.fillMaxWidth(),
                                textStyle =
                                MaterialTheme.typography.bodyMedium.copy(
                                    color = MaterialTheme.colorScheme.onSurface,
                                ),
                                singleLine = false,
                                maxLines = 3,
                                decorationBox = { innerTextField ->
                                    Box {
                                        if (testText.isEmpty() && !isFocused) {
                                            Text(
                                                "点击此处开始输入测试...",
                                                style = MaterialTheme.typography.bodyMedium,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                                            )
                                        }
                                        innerTextField()
                                    }
                                },
                            )
                        }
                        if (testText.isNotEmpty()) {
                            Row(
                                modifier =
                                Modifier
                                    .fillMaxWidth()
                                    .padding(top = 8.dp),
                                horizontalArrangement = Arrangement.End,
                            ) {
                                TextButton(onClick = { testText = "" }) {
                                    Text(
                                        "清除",
                                        style = MaterialTheme.typography.bodyMedium,
                                    )
                                }
                            }
                        }
                    }
                }
            }

            item {
                SettingsSection(title = "方案") {
                    SettingsItem(
                        icon = Icons.TwoTone.Folder,
                        title = "方案组",
                        subtitle = "切换和管理方案分组",
                        onClick = onNavigateToSchemaGroup,
                        showArrow = true,
                    )
                    SectionDivider()
                    SettingsItem(
                        icon = Icons.TwoTone.Ballot,
                        title = "管理方案",
                        subtitle = "添加或移除已启用的方案",
                        onClick = onNavigateToSchemaManage,
                        showArrow = true,
                    )
                    SectionDivider()
                    SettingsItem(
                        icon = Icons.TwoTone.KeyboardAlt,
                        title = "输入方案",
                        subtitle = "选择当前使用的输入方案",
                        onClick = onNavigateToSchemaSelect,
                        showArrow = true,
                    )
                    SectionDivider()
                    SettingsItem(
                        icon = Icons.TwoTone.CloudUpload,
                        title = "部署",
                        subtitle = "重新部署方案并生效",
                        onClick = {
                            if (TrimeService.getInstance() == null) {
                                Toast.makeText(context, "请先启用输入法", Toast.LENGTH_SHORT).show()
                            } else {
                                DeployDialog(context).show()
                            }
                        },
                    )
                }
            }

            item {
                SettingsSection(title = "外观") {
                    SettingsItem(
                        icon = Icons.TwoTone.Palette,
                        title = "键盘主题",
                        subtitle = "选择键盘整体主题",
                        onClick = onNavigateToTheme,
                        showArrow = true,
                    )
                    SectionDivider()
                    SettingsItem(
                        icon = Icons.TwoTone.FormatPaint,
                        title = "颜色样式",
                        subtitle = "选择当前主题的配色样式",
                        onClick = onNavigateToStyle,
                        showArrow = true,
                    )
                    SectionDivider()
                    SettingsItem(
                        icon = Icons.TwoTone.Keyboard,
                        title = "默认键盘",
                        subtitle = "选择默认显示的键盘布局",
                        onClick = onNavigateToKeyboard,
                        showArrow = true,
                    )
                }
            }

            item {
                SettingsSection(title = "其他") {
                    SettingsItem(
                        icon = Icons.TwoTone.Extension,
                        title = "工具",
                        subtitle = "运行扩展工具脚本",
                        onClick = {
                            context.startActivity(Intent(context, ToolActivity::class.java))
                        },
                        showArrow = true,
                    )
                    SectionDivider()
                    SettingsItem(
                        icon = Icons.TwoTone.GetApp,
                        title = "下载更多版本",
                        subtitle = "github.com/nirenr/trime2/releases",
                        onClick = {
                            context.startActivity(
                                Intent(
                                    Intent.ACTION_VIEW,
                                    Uri.parse("https://github.com/nirenr/trime2/releases"),
                                ),
                            )
                        },
                    )
                }
            }
        }
    }
}
