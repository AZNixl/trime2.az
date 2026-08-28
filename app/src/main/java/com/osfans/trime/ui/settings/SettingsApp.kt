/*
 * SPDX-FileCopyrightText: 2015 - 2026 Rime community
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package com.osfans.trime.ui.settings

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController

internal object SettingsRoutes {
    const val MAIN = "main"
    const val SCHEMA_GROUP = "schema_group"
    const val SCHEMA_MANAGE = "schema_manage"
    const val SCHEMA_SELECT = "schema_select"
    const val THEME = "theme"
    const val STYLE = "style"
    const val KEYBOARD = "keyboard"
}

@Composable
fun SettingsApp() {
    val navController = rememberNavController()
    NavHost(
        navController = navController,
        startDestination = SettingsRoutes.MAIN,
    ) {
        composable(SettingsRoutes.MAIN) {
            SettingsMainContent(
                onNavigateToSchemaGroup = { navController.navigate(SettingsRoutes.SCHEMA_GROUP) },
                onNavigateToSchemaManage = { navController.navigate(SettingsRoutes.SCHEMA_MANAGE) },
                onNavigateToSchemaSelect = { navController.navigate(SettingsRoutes.SCHEMA_SELECT) },
                onNavigateToTheme = { navController.navigate(SettingsRoutes.THEME) },
                onNavigateToStyle = { navController.navigate(SettingsRoutes.STYLE) },
                onNavigateToKeyboard = { navController.navigate(SettingsRoutes.KEYBOARD) },
            )
        }
        composable(SettingsRoutes.SCHEMA_GROUP) {
            SchemaGroupScreen(
                onBack = { navController.popBackStack() },
                onNavigateToSchemaSelect = { navController.navigate(SettingsRoutes.SCHEMA_SELECT) },
            )
        }
        composable(SettingsRoutes.SCHEMA_MANAGE) {
            SchemaManageScreen(onBack = { navController.popBackStack() })
        }
        composable(SettingsRoutes.SCHEMA_SELECT) {
            SchemaSelectScreen(
                onBack = { navController.popBackStack() },
                onNavigateToManage = { navController.navigate(SettingsRoutes.SCHEMA_MANAGE) },
            )
        }
        composable(SettingsRoutes.THEME) {
            ThemeSelectScreen(onBack = { navController.popBackStack() })
        }
        composable(SettingsRoutes.STYLE) {
            StyleSelectScreen(onBack = { navController.popBackStack() })
        }
        composable(SettingsRoutes.KEYBOARD) {
            KeyboardSelectScreen(onBack = { navController.popBackStack() })
        }
    }
}
