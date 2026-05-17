if(NOT DEFINED OUTPUT_FILE)
    message(FATAL_ERROR "OUTPUT_FILE variable is not set.")
endif()
if(NOT DEFINED VERSION_TEMPLATE)
    message(FATAL_ERROR "Missing VERSION_TEMPLATE variable.")
endif()

find_package(Git QUIET)
if(Git_FOUND)
  # Generate a git-describe version string from Git repository tags
  execute_process(
    COMMAND ${GIT_EXECUTABLE} describe --abbrev=8 --dirty --always --tags --long
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE git_describe
    RESULT_VARIABLE GIT_DESCRIBE_ERROR_CODE
    OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT GIT_DESCRIBE_ERROR_CODE EQUAL 0)
        message(FATAL_ERROR "Git describe failed with error code ${GIT_DESCRIBE_ERROR_CODE}")
        return()
    endif()
  execute_process(
    COMMAND ${GIT_EXECUTABLE} rev-parse --short=8 -q HEAD
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE git_commit
    RESULT_VARIABLE GIT_DESCRIBE_ERROR_CODE
    OUTPUT_STRIP_TRAILING_WHITESPACE)
else()
  message(FATAL_ERROR "Git is not installed")
  return()
endif()

if(git_describe
   MATCHES
   "(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)(-[.0-9A-Za-z-]+)?([+][.0-9A-Za-z-]+)?$"
)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --tags --abbrev=0
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE git_tag
        RESULT_VARIABLE GIT_DESCRIBE_ERROR_CODE
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-list --count ${git_tag}..HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE git_distance
        RESULT_VARIABLE GIT_DESCRIBE_ERROR_CODE
        OUTPUT_STRIP_TRAILING_WHITESPACE)
else()
    set(wrong_tag ${git_describe})
    set(git_describe 0.0.0-0-${git_describe})
    set(git_distance 0)
    string(REGEX MATCH "(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)(-[.0-9A-Za-z-]+)?([+][.0-9A-Za-z-]+)?$" _ ${git_describe})
    message(WARNING "Git tag isn't valid semantic version: [${wrong_tag}]. Using placeholder as git tag : [${git_describe}]")
endif()
set(git_semver ${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3})

set(GIT_SEMVER ${git_semver})
set(GIT_COMMIT ${git_commit})
set(GIT_DESCRIBE ${git_describe})
set(GIT_MAJOR ${CMAKE_MATCH_1})
set(GIT_MINOR ${CMAKE_MATCH_2})
set(GIT_PATCH ${CMAKE_MATCH_3})
set(GIT_DISTANCE ${git_distance})

message("--------------------------------------------------")
message("     Git version: ${git_describe}")
message("--------------------------------------------------")

configure_file(
    "${VERSION_TEMPLATE}"
    "${OUTPUT_FILE}"
    @ONLY
)
