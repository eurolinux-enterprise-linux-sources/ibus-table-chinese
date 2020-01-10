# - Modules for manipulate version and ChangeLogs
#
# Includes:
#   ManageVariable
#   DateTimeFormat
#
# Included by:
#   PackSource
#
# Defines following functions:
#   RELEASE_NOTES_READ_FILE([releaseFile])
#   - Load release file information.
#     Arguments:
#     + releaseFile: (Optional) release file to be read.
#       This file should contain following definition:
#       + PRJ_VER: Release version.
#       + SUMMARY: Summary of the release. Will be output as CHANGE_SUMMARY.
#          and a [Changes] section tag, below which listed the change in the
#          release.
#       Default:RELEASE-NOTES.txt
#     This macro reads or define following variables:
#     + RELEASE_TARGETS: Sequence of release targets.
#     This macro outputs following files:
#     + ChangeLog: Log of changes.
#       Depends on ChangeLog.prev and releaseFile.
#     This macro sets following variables:
#     + PRJ_VER: Release version.
#     + CHANGE_SUMMARY: Summary of changes.
#     + CHANGELOG_ITEMS: Lines below the [Changes] tag.
#     + RELEASE_NOTES_FILE: The loaded release file.
#     + PRJ_DOC_DIR: Documentation for the project.
#       Default: ${DOC_DIR}/${PROJECT_NAME}-${PRJ_VER}
#
#

IF(NOT DEFINED _MANAGE_VERSION_CMAKE_)
    SET(_MANAGE_VERSION_CMAKE_ "DEFINED")
    INCLUDE(ManageMessage)
    INCLUDE(ManageVariable)

    SET(CHANGELOG_FILE "${CMAKE_BINARY_DIR}/ChangeLog" CACHE FILEPATH
	"ChangeLog")
    SET(CHANGELOG_PREV_FILE "${CMAKE_SOURCE_DIR}/ChangeLog.prev" CACHE FILEPATH
	"ChangeLog.prev")

    ADD_CUSTOM_TARGET(changelog_prev_update
	COMMAND ${CMAKE_COMMAND} -E copy ${CHANGELOG_FILE} ${CHANGELOG_PREV_FILE}
	DEPENDS ${CHANGELOG_FILE}
	COMMENT "${CHANGELOG_FILE} are saving as ${CHANGELOG_PREV_FILE}"
	)

    FUNCTION(RELEASE_NOTES_READ_FILE)
	FOREACH(_arg ${ARGN})
	    IF(EXISTS ${_arg})
		SET(RELEASE_NOTES_FILE ${_arg} CACHE FILEPATH "Release File")
	    ENDIF(EXISTS ${_arg})
	ENDFOREACH(_arg ${ARGN})

	IF(NOT RELEASE_NOTES_FILE)
	    SET(RELEASE_NOTES_FILE "RELEASE-NOTES.txt" CACHE FILEPATH "Release Notes")
	ENDIF(NOT RELEASE_NOTES_FILE)

	FILE(STRINGS "${RELEASE_NOTES_FILE}" _release_lines)

	SET(_changeItemSection 0)
	SET(_changeItems "")
	## Parse release file
	FOREACH(_line ${_release_lines})
	    IF(_changeItemSection)
		### Append lines in change section
		IF(_changeItems)
		    SET(_changeItems  "${_changeItems}\n${_line}")
		ELSE(_changeItems)
		    SET(_changeItems  "${_line}")
		ENDIF(_changeItems)
	    ELSEIF("${_line}" MATCHES "^[[]Changes[]]")
		### Start the change section
		SET(_changeItemSection 1)
	    ELSE(_changeItemSection)
		### Variable Setting section
		SETTING_STRING_GET_VARIABLE(var value "${_line}")
		#MESSAGE("var=${var} value=${value}")
		IF(NOT var MATCHES "#")
		    IF(var STREQUAL "PRJ_VER")
			SET_COMPILE_ENV(${var} "${value}" CACHE STRING "Project Version" FORCE)
		    ELSEIF(var STREQUAL "SUMMARY")
			SET(CHANGE_SUMMARY "${value}" CACHE STRING "Change Summary" FORCE)
		    ELSE(var STREQUAL "PRJ_VER")
			SET(${var} "${value}" CACHE STRING "${var}" FORCE)
		    ENDIF(var STREQUAL "PRJ_VER")
		ENDIF(NOT var MATCHES "#")
	    ENDIF(_changeItemSection)
	ENDFOREACH(_line ${_release_line})

	IF(_changeSection EQUAL 0)
	    MESSAGE(FATAL_ERROR "${RELEASE_NOTES_FILE} does not have a [Changes] tag!")
	ELSEIF("${_changeItems}" STREQUAL "")
	    MESSAGE(FATAL_ERROR "${RELEASE_NOTES_FILE} does not have ChangeLog items!")
	ENDIF(_changeSection EQUAL 0)

	FILE(WRITE "${CMAKE_FEDORA_TMP_DIR}/ChangeLog.this" "${_changeItems}")

	SET_COMPILE_ENV(PRJ_DOC_DIR "${DOC_DIR}/${PROJECT_NAME}-${PRJ_VER}"
	    CACHE PATH "Project docdir prefix" FORCE)

	CHANGELOG_WRITE_FILE()
    ENDFUNCTION(RELEASE_NOTES_READ_FILE)

    FUNCTION(CHANGELOG_WRITE_FILE)
	INCLUDE(DateTimeFormat)

	FILE(WRITE ${CHANGELOG_FILE} "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}\n")
	FILE(READ "${CMAKE_FEDORA_TMP_DIR}/ChangeLog.this" _changeLog_items)

	FILE(APPEND ${CHANGELOG_FILE} "${_changeLog_items}\n\n")
	FILE(READ ${CHANGELOG_PREV_FILE} CHANGELOG_PREV)
	FILE(APPEND ${CHANGELOG_FILE} "${CHANGELOG_PREV}")
	SET(CMAKE_CACHE_TXT "${CMAKE_BINARY_DIR}/CMakeCache.txt")

	ADD_CUSTOM_COMMAND(OUTPUT ${CHANGELOG_FILE}
	    COMMAND ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
	    DEPENDS ${RELEASE_NOTES_FILE} ${CHANGELOG_PREV_FILE}
	    COMMENT "Building ${CHANGELOG_FILE}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(changelog ALL
	    DEPENDS ${CHANGELOG_FILE}
	    VERBATIM
	    )

    ENDFUNCTION(CHANGELOG_WRITE_FILE)



ENDIF(NOT DEFINED _MANAGE_VERSION_CMAKE_)

