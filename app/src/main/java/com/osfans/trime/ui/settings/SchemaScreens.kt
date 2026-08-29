/*
 * SPDX-FileCopyrightText: 2015 - 2026 Rime community
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package com.osfans.trime.ui.settings

import android.widget.Toast
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.twotone.Ballot
import androidx.compose.material.icons.twotone.Folder
import androidx.compose.material.icons.twotone.KeyboardAlt
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.osfans.trime.Config
import com.osfans.trime.TrimeService
import com.osfans.trime.core.DataManager
import com.osfans.trime.core.Rime
import com.osfans.trime.core.SchemaItem
import com.osfans.trime.dialog.DeployDialog
import com.osfans.trime.util.Function
import java.io.File

private fun List<SchemaItem>.sortedByName(): List<SchemaItem> {
    val comp = localeComparator()
    return sortedWith(
        Comparator { a, b ->
            val n1 = a.name
            val n2 = b.name
            if (n1 != null && n2 != null) comp.compare(n1, n2) else comp.compare(a.id, b.id)
        },
    )
}

@Composable
private fun RequireService(hint: String): Boolean {
    val context = LocalContext.current
    if (TrimeService.getInstance() == null) {
        LaunchedEffect(Unit) {
            Toast.makeText(context, "请先启用输入法", Toast.LENGTH_SHORT).show()
        }
        return false
    }
    return true
}

@Composable
fun SchemaSelectScreen(
    onBack: () -> Unit,
    onNavigateToManage: () -> Unit,
) {
    PickerScaffold(title = "输入方案", onBack = onBack) { innerPadding ->
        if (!RequireService("请先启用输入法")) {
            PickerHint(innerPadding, "请先启用输入法")
            return@PickerScaffold
        }
        val context = LocalContext.current
        val currentSchemaId = remember { Rime.getCurrentRimeSchema() }
        if (currentSchemaId == ".default") {
            PickerHint(innerPadding, "没有方案，请先添加启用方案")
            return@PickerScaffold
        }
        val schemas = remember { Rime.getRimeSchemaList()?.toList()?.sortedByName() }
        if (schemas == null) {
            LaunchedEffect(Unit) {
                Toast.makeText(context, "请先启用输入法", Toast.LENGTH_SHORT).show()
            }
            PickerHint(innerPadding, "请先启用输入法")
            return@PickerScaffold
        }
        var current by remember { mutableStateOf(currentSchemaId) }
        LazyColumn(
            modifier =
            Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            contentPadding = innerPadding,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                SettingsSection(title = "选择方案") {
                    SettingsItem(
                        icon = Icons.TwoTone.Ballot,
                        title = "管理方案",
                        subtitle = "添加或移除已启用的方案",
                        onClick = onNavigateToManage,
                        showArrow = true,
                    )
                }
            }
            item {
                SettingsSection(title = "当前方案") {
                    schemas.forEachIndexed { index, schema ->
                        RadioSettingsItem(
                            icon = Icons.TwoTone.KeyboardAlt,
                            title = schema.name ?: schema.id,
                            subtitle = schema.id,
                            selected = schema.id == current,
                            onClick = {
                                current = schema.id
                                Rime.selectRimeSchema(schema.id)
                                Function.saveString(context, "select_schema_id", schema.id)
                                onBack()
                            },
                        )
                        if (index < schemas.lastIndex) SectionDivider()
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SchemaManageScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    val serviceAvailable = remember { TrimeService.getInstance() != null }
    var checkedIds by remember {
        mutableStateOf(
            if (serviceAvailable) {
                Rime.getSelectedRimeSchemaList()
                    ?.map { it.id }
                    ?.toSet()
                    .orEmpty()
            } else {
                emptySet()
            },
        )
    }
    LaunchedEffect(Unit) {
        DataManager.sync()
    }
    Scaffold(
        containerColor = MaterialTheme.colorScheme.surface,
        topBar = {
            TopAppBar(
                title = { Text("管理方案") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = null,
                        )
                    }
                },
                colors =
                TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                ),
            )
        },
        bottomBar = {
            if (serviceAvailable) {
                Surface(
                    color = MaterialTheme.colorScheme.surface,
                    tonalElevation = 2.dp,
                ) {
                    Button(
                        onClick = {
                            Rime.selectRimeSchemas(checkedIds.toTypedArray())
                            DeployDialog(context).show()
                        },
                        modifier =
                        Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                    ) {
                        Text("确定")
                    }
                }
            }
        },
    ) { innerPadding ->
        if (!serviceAvailable) {
            LaunchedEffect(Unit) {
                Toast.makeText(context, "请先启用输入法", Toast.LENGTH_SHORT).show()
            }
            PickerHint(innerPadding, "请先启用输入法")
            return@Scaffold
        }
        val schemas = remember { Rime.getAvailableRimeSchemaList()?.toList()?.sortedByName().orEmpty() }
        LazyColumn(
            modifier =
            Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            contentPadding = innerPadding,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                SettingsSection(title = "启用方案") {
                    schemas.forEachIndexed { index, schema ->
                        CheckSettingsItem(
                            icon = Icons.TwoTone.Ballot,
                            title = schema.name ?: schema.id,
                            subtitle = schema.id,
                            checked = schema.id in checkedIds,
                            onCheckedChange = { checked ->
                                checkedIds =
                                    if (checked) {
                                        checkedIds + schema.id
                                    } else {
                                        checkedIds - schema.id
                                    }
                            },
                        )
                        if (index < schemas.lastIndex) SectionDivider()
                    }
                }
            }
        }
    }
}

@Composable
fun SchemaGroupScreen(
    onBack: () -> Unit,
    onNavigateToSchemaSelect: () -> Unit,
) {
    var showCreateDialog by remember { mutableStateOf(false) }
    PickerScaffold(
        title = "方案组",
        onBack = onBack,
        actions = {
            TextButton(onClick = { showCreateDialog = true }) {
                Text("新建")
            }
        },
    ) { innerPadding ->
        val context = LocalContext.current
        var groups by remember {
            mutableStateOf(Config.getGroups().sortedWith(localeComparator()))
        }
        var current by remember { mutableStateOf(Config.getGroup()) }
        LazyColumn(
            modifier =
            Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            contentPadding = innerPadding,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                SettingsSection(title = "选择方案组") {
                    SettingsItem(
                        icon = Icons.TwoTone.KeyboardAlt,
                        title = "选择方案",
                        subtitle = "在当前方案组内切换输入方案",
                        onClick = onNavigateToSchemaSelect,
                        showArrow = true,
                    )
                    SectionDivider()
                    groups.forEachIndexed { index, group ->
                        RadioSettingsItem(
                            icon = Icons.TwoTone.Folder,
                            title = group,
                            selected = group == current,
                            onClick = {
                                current = group
                                Config.setGroup(group)
                                TrimeService.getInstance()?.restart()
                                onBack()
                            },
                        )
                        if (index < groups.lastIndex) SectionDivider()
                    }
                }
            }
        }
        if (showCreateDialog) {
            var newName by remember { mutableStateOf("") }
            AlertDialog(
                onDismissRequest = { showCreateDialog = false },
                containerColor = MaterialTheme.colorScheme.surface,
                title = { Text("新建方案组") },
                text = {
                    TextField(
                        value = newName,
                        onValueChange = { newName = it },
                        singleLine = true,
                        placeholder = { Text("输入新方案组名称") },
                        modifier = Modifier.fillMaxWidth(),
                    )
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            val name = newName.trim()
                            if (name.isNotEmpty()) {
                                File(Config.getDataDir(), "schemas/$name").mkdirs()
                                groups = Config.getGroups().sortedWith(localeComparator())
                            }
                            showCreateDialog = false
                        },
                    ) {
                        Text("创建")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showCreateDialog = false }) {
                        Text("取消")
                    }
                },
            )
        }
    }
}
