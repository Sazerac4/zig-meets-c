include_guard(GLOBAL)
find_program(ZIG_EXECUTABLE zig)
if(NOT ZIG_EXECUTABLE)
  message(FATAL_ERROR "Zig not found")
  return()
endif()

function(zig_add_module)
  set(options)
  set(oneValueArgs
    NAME
    LINK_TO
    SRC_ROOT
    TRANSLATE_IN
    TRANSLATE_OUT
  )
  set(multiValueArgs
    TARGET
    TRANSLATE_DEPENDS
    BUILD_OPTS
    TRANSLATE_OPTS
  )
  cmake_parse_arguments(ARG
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  if(NOT ARG_NAME)
    message(FATAL_ERROR "zig_add_module: NAME is required")
  endif()
  if(NOT ARG_LINK_TO)
    message(FATAL_ERROR "zig_add_module: LINK_TO is required")
  endif()
  if(NOT ARG_SRC_ROOT)
    message(FATAL_ERROR "zig_add_module: SRC_ROOT is required")
  endif()
  if(NOT ARG_TARGET)
    message(FATAL_ERROR "zig_add_module: TARGET is required")
  endif()

  # ----------------------------------------------------------------
  # Common Settings
  # ----------------------------------------------------------------
  set(ARG_EMIT_BIN ${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}.o)
  set(ARG_EMIT_H   ${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}.h) # FIXME: -femit-h not working, for future use

  # Add the Zig object to the main target to link against
  target_sources(${ARG_LINK_TO} PRIVATE ${ARG_EMIT_BIN})
  target_link_options(${ARG_LINK_TO}
    PRIVATE
    -z noexecstack # Fix executable stack warning caused by missing .note.GNU-stack in ${ARG_EMIT_BIN}
  )
  # Create the root target
  add_custom_target(${ARG_NAME})

  # ----------------------------------------------------------------
  # Optional translate-c stage
  # ----------------------------------------------------------------
  if(ARG_TRANSLATE_IN)

    if(NOT EXISTS ${ARG_TRANSLATE_IN})
      message(FATAL_ERROR "${ARG_TRANSLATE_IN} does not exist")
    endif()

    # Collect all target dependencies
    collect_all_target(${ARG_LINK_TO} _targets)
    # Collect all define, include and system include from theses targets
    collect_options_from_targets("${_targets}" OPTIONS_DEF OPTIONS_INC OPTIONS_SYS)

    # Create argument lists to pass to translate-c (Work with cmake-generator-expression)
    if(OPTIONS_DEF)
      set(_DEF -D$<JOIN:${OPTIONS_DEF},;-D>)
    endif()
    if(OPTIONS_INC)
      set(_INC -I$<JOIN:${OPTIONS_INC},;-I>)
    endif()
    if(OPTIONS_SYS)
      set(_SYS -isystem $<JOIN:${OPTIONS_SYS},;-isystem >)
    endif()

    # Compiler Related system include (libc)
    if(CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES)
      set(_IMPLICIT_SYS -isystem $<JOIN:${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES},;-isystem >)
    endif()
    # Collect sysroot include if defined
    set(_SYSROOT "")
      if(CMAKE_SYSROOT)
        list(APPEND _SYSROOT "--sysroot" "${CMAKE_SYSROOT}")
        if(EXISTS "${CMAKE_SYSROOT}/include")
          list(APPEND _IMPLICIT_SYS "-isystem" "${CMAKE_SYSROOT}/include")
        endif()
    endif()

    add_custom_command(
      OUTPUT ${ARG_TRANSLATE_OUT}
      COMMAND ${ZIG_EXECUTABLE} translate-c ${ARG_TRANSLATE_IN} ${ARG_TARGET} ${ARG_TRANSLATE_OPTS}
        "${_SYSROOT}" "${_DEF}" "${_INC}" "${_SYS}" "${_IMPLICIT_SYS}" > ${ARG_TRANSLATE_OUT} # FIXME: Ok on windows ?
      DEPENDS ${ARG_TRANSLATE_IN} ${ARG_TRANSLATE_DEPENDS}
      COMMAND_EXPAND_LISTS
      COMMENT "(${ARG_NAME}) Translating C to Zig"
    )
    add_custom_target(${ARG_NAME}-translate DEPENDS ${ARG_TRANSLATE_OUT})
    add_dependencies(${ARG_NAME} ${ARG_NAME}-translate)
  endif()

  # ----------------------------------------------------------------
  # Zig build-obj stage
  # ----------------------------------------------------------------
  add_custom_command(
    OUTPUT ${ARG_EMIT_BIN}
    COMMAND ${ZIG_EXECUTABLE} build-obj ${ARG_SRC_ROOT}
            ${ARG_TARGET} -femit-bin=${ARG_EMIT_BIN} -femit-h=${ARG_EMIT_H} -fno-unwind-tables -fno-ubsan-rt "${_SYSROOT}" ${ARG_RELEASE} ${ARG_BUILD_OPTS}
    DEPENDS ${ARG_SRC_ROOT} ${ARG_TRANSLATE_OUT}
    COMMAND_EXPAND_LISTS
    COMMENT "(${ARG_NAME}) Compiling Zig"
  )
  add_custom_target(${ARG_NAME}-emit-bin DEPENDS ${ARG_EMIT_BIN})
  add_dependencies(${ARG_NAME} ${ARG_NAME}-emit-bin)
endfunction()


# ----------------------------------------------------------------
# Utils function
# ----------------------------------------------------------------
function(collect_all_target target all_targets)
  # --- internal recursive helper ---
  function(_collect t)
    if(NOT TARGET "${t}")
      return()
    endif()

    # Avoid visiting twice (cycle protection)
    list(FIND _visited "${t}" _idx)
    if(NOT _idx EQUAL -1)
      return()
    endif()
    list(APPEND _visited "${t}")

    # Try to collect interface link libraries
    get_target_property(_deps "${t}" INTERFACE_LINK_LIBRARIES)
    if(NOT _deps OR _deps STREQUAL "_deps-NOTFOUND")
      # Fallback for static/shared libs
      get_target_property(_deps "${t}" LINK_LIBRARIES)
    endif()

    # Recurse
    foreach(dep IN LISTS _deps)
      if(TARGET "${dep}")
        _collect("${dep}")
      endif()
    endforeach()

    # Add to result (global accumulation)
    set(_collected ${_collected} "${t}" PARENT_SCOPE)
    set(_visited ${_visited} PARENT_SCOPE)
  endfunction()

  # Initialize globals
  set(_visited "")
  set(_collected "")

  # Start recursion
  _collect("${target}")

  # Remove duplicates & return
  list(REMOVE_DUPLICATES _collected)
  set(${all_targets} "${_collected}" PARENT_SCOPE)
endfunction()

# TODO: We can probably improve this finder function
function(collect_options_from_targets targets DEF INC SYS_INC)

  set(_def_list "")
  set(_inc_list "")
  set(_sys_inc_list "")

  foreach(element ${targets})

    get_target_property(_incs ${element} INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(_sysincs ${element} INTERFACE_SYSTEM_INCLUDE_DIRECTORIES)
    get_target_property(_defs ${element} INTERFACE_COMPILE_DEFINITIONS)

    # -------------------------
    # Defines
    # -------------------------
    if(NOT _defs STREQUAL "_defs-NOTFOUND")
      list(APPEND _def_list ${_defs})
    endif()

    # -------------------------
    # SYSTEM includes
    # -------------------------
    if(NOT _sysincs STREQUAL "_sysincs-NOTFOUND")
      list(APPEND _sys_inc_list ${_sysincs})
    endif()

    # -------------------------
    # NORMAL includes filtered
    # -------------------------
    # Note: For INTERFACE targets, the same directory may appear in both
    # INTERFACE_INCLUDE_DIRECTORIES and INTERFACE_SYSTEM_INCLUDE_DIRECTORIES.
    # We exclude -I<include> from the list if the -isystem <include> exist.
    if(NOT _incs STREQUAL "_incs-NOTFOUND")
      foreach(dir ${_incs})
        list(FIND _sys_inc_list "${dir}" _is_sys)
        if(_is_sys EQUAL -1)
          list(APPEND _inc_list ${dir})
        endif()
      endforeach()
    endif()

  endforeach()

  # Just in case remove duplicate
  list(REMOVE_DUPLICATES _def_list)
  list(REMOVE_DUPLICATES _inc_list)
  list(REMOVE_DUPLICATES _sys_inc_list)
  # Store the results in the parent scope
  set(${DEF} "${_def_list}" PARENT_SCOPE)
  set(${INC} "${_inc_list}" PARENT_SCOPE)
  set(${SYS_INC} "${_sys_inc_list}" PARENT_SCOPE)

endfunction()
