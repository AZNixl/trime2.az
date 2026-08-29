# SPDX-FileCopyrightText: 2015 - 2024 Rime community
#
# SPDX-License-Identifier: GPL-3.0-or-later

# if you want to add some new plugins, add them to librime_jni/rime_jni.cc too
set(RIME_PLUGINS librime-lua librime-octagram librime-predict)

# symlink plugins
foreach(plugin ${RIME_PLUGINS})
  if(NOT EXISTS "${CMAKE_SOURCE_DIR}/librime/plugins/${plugin}")
    file(CREATE_LINK "${CMAKE_SOURCE_DIR}/${plugin}"
         "${CMAKE_SOURCE_DIR}/librime/plugins/${plugin}" COPY_ON_ERROR SYMBOLIC)
  endif()
endforeach()

# librime-lua
if(NOT EXISTS "${CMAKE_SOURCE_DIR}/librime/plugins/librime-lua/thirdparty")
  file(CREATE_LINK "${CMAKE_SOURCE_DIR}/librime-lua-deps"
       "${CMAKE_SOURCE_DIR}/librime/plugins/librime-lua/thirdparty"
       COPY_ON_ERROR SYMBOLIC)
endif()

# Apply the Lua 5.4 Android compatibility fix to liolib.c (fixes fseeko/ftello
# being unavailable on 32-bit devices below API 24).
#
# lua's lprefix.h forces _FILE_OFFSET_BITS=64, which makes bionic gate
# fseeko/ftello behind API 24 on 32-bit ABIs. Guard the LUA_USE_POSIX l_fseek
# branch so that 32-bit Android below API 24 falls back to fseek/ftell.
# Patched in-place at configure time (no git/patch dependency), idempotent.
string(ASCII 10 LUA_NL)
set(LUA_LIOLIB_SRC
    "${CMAKE_SOURCE_DIR}/librime/plugins/librime-lua/thirdparty/lua5.4/liolib.c")
if(EXISTS "${LUA_LIOLIB_SRC}")
  file(READ "${LUA_LIOLIB_SRC}" LUA_LIOLIB_CONTENT)
  string(FIND "${LUA_LIOLIB_CONTENT}" "ANDROID" LUA_ALREADY_PATCHED)
  if(LUA_ALREADY_PATCHED EQUAL -1)
    string(FIND "${LUA_LIOLIB_CONTENT}" "#if !defined(l_fseek)" LUA_ANCHOR_POS)
    if(LUA_ANCHOR_POS GREATER -1)
      string(SUBSTRING "${LUA_LIOLIB_CONTENT}" ${LUA_ANCHOR_POS} -1 LUA_SUB_CONTENT)
      string(FIND "${LUA_SUB_CONTENT}" "#if defined(LUA_USE_POSIX)" LUA_REL_POS)
      if(LUA_REL_POS GREATER -1)
        math(EXPR LUA_TARGET_POS "${LUA_ANCHOR_POS} + ${LUA_REL_POS}")
        string(SUBSTRING "${LUA_LIOLIB_CONTENT}" ${LUA_TARGET_POS} -1 LUA_TARGET_CONTENT)
        string(FIND "${LUA_TARGET_CONTENT}" "${LUA_NL}" LUA_REL_NL_POS)
        if(LUA_REL_NL_POS GREATER -1)
          math(EXPR LUA_NL_POS "${LUA_TARGET_POS} + ${LUA_REL_NL_POS}")
          string(SUBSTRING "${LUA_LIOLIB_CONTENT}" 0 ${LUA_TARGET_POS} LUA_HEAD)
          string(SUBSTRING "${LUA_LIOLIB_CONTENT}" ${LUA_NL_POS} -1 LUA_TAIL)
          math(EXPR LUA_SUFFIX_START "${LUA_TARGET_POS} + 26")
          math(EXPR LUA_SUFFIX_LEN "${LUA_NL_POS} - ${LUA_SUFFIX_START}")
          string(SUBSTRING "${LUA_LIOLIB_CONTENT}" ${LUA_SUFFIX_START} ${LUA_SUFFIX_LEN} LUA_SUFFIX)
          set(LUA_PATCHED_LINE
            "#if defined(LUA_USE_POSIX) && \\${LUA_NL}   (!defined(ANDROID) || (defined(__LP64__) || ANDROID_PLATFORM >= 24))${LUA_SUFFIX}")
          set(LUA_LIOLIB_CONTENT "${LUA_HEAD}${LUA_PATCHED_LINE}${LUA_TAIL}")
          file(WRITE "${LUA_LIOLIB_SRC}" "${LUA_LIOLIB_CONTENT}")
        endif()
      endif()
    endif()
  endif()
endif()

option(BUILD_TEST "" OFF)
option(BUILD_STATIC "" ON)
add_subdirectory(librime)
target_compile_options(
  rime-static PRIVATE "-ffile-prefix-map=${CMAKE_CURRENT_SOURCE_DIR}=." "-Wno-error=deprecated-declarations")

target_compile_options(
  rime-lua-objs PRIVATE "-ffile-prefix-map=${CMAKE_CURRENT_SOURCE_DIR}=.")

target_compile_options(
  rime-octagram-objs PRIVATE "-ffile-prefix-map=${CMAKE_CURRENT_SOURCE_DIR}=.")
