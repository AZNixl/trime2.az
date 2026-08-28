/*
 * SPDX-FileCopyrightText: 2015 - 2026 Rime community
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package com.osfans.trime.ui.settings

import com.osfans.trime.Config
import com.osfans.trime.theme.ThemeManager
import org.luaj.Globals
import org.luaj.LuaTable
import org.luaj.lib.ResourceFinder
import org.luaj.lib.jse.JsePlatform
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.text.Collator
import java.util.Locale

internal data class NamedItem(
    val id: String,
    val displayName: String,
)

internal fun localeComparator(): Comparator<String> {
    val collator = Collator.getInstance(Locale.getDefault())
    return Comparator { s1, s2 -> collator.compare(s1, s2) }
}

internal fun List<NamedItem>.sortByDisplayName(): List<NamedItem> {
    val comp = localeComparator()
    return sortedWith(
        Comparator { a, b ->
            val r = comp.compare(a.displayName, b.displayName)
            if (r != 0) r else comp.compare(a.id, b.id)
        },
    )
}

internal object LuaNames {
    private fun newEnv(globals: Globals): LuaTable {
        val env = LuaTable()
        val mt = LuaTable()
        mt.set("__index", globals)
        env.setmetatable(mt)
        return env
    }

    private fun nameFromLua(
        globals: Globals,
        path: String,
        id: String,
    ): String {
        val env = newEnv(globals)
        return try {
            val chunk = globals.loadfilex(path, env)
            if (chunk.isfunction()) {
                chunk.call()
                val luaName = env.get("name")
                if (luaName.isstring()) {
                    return luaName.tojstring() + " (" + id + ")"
                }
            }
            id
        } catch (e: Exception) {
            "$id ($e)"
        }
    }

    fun themeItems(): List<NamedItem> {
        val globals = JsePlatform.standardGlobals()
        globals.finder = ThemeManager.getFinder()
        return Config.getThemes()
            .map { id -> NamedItem(id, nameFromLua(globals, Config.getThemePath(id, "main.lua"), id)) }
    }

    fun styleItems(): List<NamedItem> {
        val globals = JsePlatform.standardGlobals()
        globals.finder = ThemeManager.getFinder()
        return Config.getStyles()
            .map { id -> NamedItem(id, nameFromLua(globals, Config.getStylePath(id, "main.lua"), id)) }
    }

    fun keyboardItems(): List<NamedItem> {
        val globals = JsePlatform.standardGlobals()
        globals.finder = keyboardFinder()
        val items = mutableListOf<NamedItem>()
        for (raw in Config.getKeyboards()) {
            val id = raw.replace(".lua", "")
            val displayName = keyboardNameFromLua(globals, id)
            if (displayName.isNullOrEmpty()) continue
            items.add(NamedItem(id, displayName))
        }
        return items
    }

    private fun keyboardNameFromLua(
        globals: Globals,
        keyboardId: String,
    ): String? {
        val env = newEnv(globals)
        return try {
            val path = Config.getKeyboardPath(keyboardId)
            val chunk = globals.loadfilex(path, env)
            if (chunk.isfunction()) {
                chunk.call()
                if (!env.get("lock").toboolean()) {
                    return null
                }
                val nameValue = env.get("name")
                if (nameValue.isstring()) {
                    return nameValue.tojstring() + " (" + keyboardId + ")"
                }
            }
            keyboardId
        } catch (e: Exception) {
            "$keyboardId ($e)"
        }
    }

    private fun keyboardFinder(): ResourceFinder =
        object : ResourceFinder {
            override fun findResource(name: String): InputStream? {
                if (name.isEmpty()) return null
                try {
                    if (File(name).exists()) {
                        return FileInputStream(name)
                    }
                } catch (_: Exception) {
                }
                return try {
                    FileInputStream(File(Config.getKeyboardDir(), name))
                } catch (_: Exception) {
                    null
                }
            }

            override fun findFile(filename: String): String? {
                if (filename.isEmpty()) return null
                if (filename.startsWith("/")) return filename
                return File(Config.getKeyboardDir(), filename).absolutePath
            }
        }
}
