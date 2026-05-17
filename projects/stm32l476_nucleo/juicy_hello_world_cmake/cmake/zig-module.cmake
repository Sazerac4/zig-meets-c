include_guard(GLOBAL)
find_program(ZIG_EXECUTABLE zig)
if(NOT ZIG_EXECUTABLE)
    message(FATAL_ERROR "Zig not found")
    return()
endif()

function(add_zig_module)
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
    )
    cmake_parse_arguments(arg
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )

    if(NOT arg_NAME)
        message(FATAL_ERROR "add_zig_module: NAME is required")
    endif()
    if(NOT arg_LINK_TO)
        message(FATAL_ERROR "add_zig_module: LINK_TO is required")
    endif()
    if(NOT arg_SRC_ROOT)
        message(FATAL_ERROR "add_zig_module: SRC_ROOT is required")
    endif()
    if(NOT arg_TARGET)
        message(FATAL_ERROR "add_zig_module: TARGET is required")
    endif()

    # ----------------------------------------------------------------------------------------------------
    # Common Settings
    # ----------------------------------------------------------------------------------------------------
    # Optimization level selection
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(arg_RELEASE -ODebug)
    elseif (CMAKE_BUILD_TYPE STREQUAL "Release")
        set(arg_RELEASE -OReleaseSafe)
    elseif( CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
        set(arg_RELEASE -OReleaseSafe -fno-strip)
    elseif (CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
        set(arg_RELEASE -OReleaseSmall)
    else()
        message(FATAL_ERROR "${CMAKE_BUILD_TYPE} is not a valid build type")
    endif()

    set(arg_EMIT_BIN ${CMAKE_CURRENT_BINARY_DIR}/${arg_NAME}.o)
    set(arg_EMIT_H   ${CMAKE_CURRENT_BINARY_DIR}/${arg_NAME}.h) # FIXME: -femit-h not working, for future use

    # Add the Zig object to the main target to link against
    target_sources(${arg_LINK_TO} PRIVATE ${arg_EMIT_BIN})
    target_link_options(${arg_LINK_TO}
        PRIVATE
        -z noexecstack # Fix executable stack warning caused by missing .note.GNU-stack in ${arg_EMIT_BIN}
    )
    # Create the root target
    add_custom_target(${arg_NAME})

    # ----------------------------------------------------------------------------------------------------
    # Optional translate-c stage
    # ----------------------------------------------------------------------------------------------------
    if(arg_TRANSLATE_IN)

        if(NOT EXISTS ${arg_TRANSLATE_IN})
            message(FATAL_ERROR "${arg_TRANSLATE_IN} does not exist")
        endif()

        # Collect all target dependencies
        collect_all_target(${arg_LINK_TO} _targets)
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

        add_custom_command(
            OUTPUT ${arg_TRANSLATE_OUT}
            COMMAND zig translate-c ${arg_TRANSLATE_IN} ${arg_TARGET} "${_DEF}" "${_INC}" "${_SYS}" "${_IMPLICIT_SYS}" > ${arg_TRANSLATE_OUT}
            DEPENDS ${arg_TRANSLATE_IN} ${arg_TRANSLATE_DEPENDS}
            COMMAND_EXPAND_LISTS
            COMMENT "(${arg_NAME}) Translating C to Zig"
        )
        add_custom_target(${arg_NAME}-translate DEPENDS ${arg_TRANSLATE_OUT})
        add_dependencies(${arg_NAME} ${arg_NAME}-translate)
    endif()

    # ----------------------------------------------------------------------------------------------------
    # Zig build-obj stage
    # ----------------------------------------------------------------------------------------------------
    add_custom_command(
        OUTPUT ${arg_EMIT_BIN}
        COMMAND zig build-obj ${arg_SRC_ROOT}
                ${arg_TARGET} -femit-bin=${arg_EMIT_BIN} -femit-h=${arg_EMIT_H} -fno-unwind-tables -fno-ubsan-rt ${arg_RELEASE} ${arg_BUILD_OPTS}
        DEPENDS ${arg_SRC_ROOT} ${arg_TRANSLATE_OUT}
        COMMENT "(${arg_NAME}) Compiling Zig"
    )
    add_custom_target(${arg_NAME}-emit-bin DEPENDS ${arg_EMIT_BIN})
    add_dependencies(${arg_NAME} ${arg_NAME}-emit-bin)
endfunction()


# ----------------------------------------------------------------------------------------------------
# Utils function
# ----------------------------------------------------------------------------------------------------
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
