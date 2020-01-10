# - Module that perform release task.
# This module provides common targets for release or post-release chores.
#
#  Defines following macros:
#  MANAGE_RELEASE(releaseTargets)
#  - Run release targets and the target "after_release_commit".
#    This macro skips the missing targets so distro package maintainers
#    do not have to get the irrelevant dependencies.
#    For the "hard" requirement, please use cmake command
#      "ADD_DEPENDENCIES".
#    Arguments:
#    + releaseTargets: Targets need to be done for a release.
#      Note that sequence of the targets does not guarantee the
#      sequence of execution.
#    Defines following targets:
#    + release: Perform everything required for a release.
#      Reads following variables:
#      + RELEASE_DEPENDS_FILES: List of files that the release depends.
#        Note that the sequence of the target does not guarantee the
#        sequence of execution.
#

IF(NOT DEFINED _MANAGE_RELEASE_CMAKE_)
    SET(_MANAGE_RELEASE_CMAKE_ "DEFINED")
    INCLUDE(ManageMessage)

    MACRO(MANAGE_RELEASE)
	## Target: release
	ADD_CUSTOM_TARGET(release
	    DEPENDS ${RELEASE_DEPENDS_FILES}
	    COMMENT "Releasing ${PROJECT_NAME}-${PRJ_VER}"
	    )

	## Remove the missing targets
	SET(_releaseTargets "")
	FOREACH(_target ${ARGN})
	    IF(TARGET ${_target})
		LIST(APPEND _releaseTargets "${_target}")
	    ELSE(TARGET ${_target})
		M_MSG(${M_OFF} "Target ${_target} does not exist, skipped.")
	    ENDIF(TARGET ${_target})
	ENDFOREACH(_target ${ARGN})

	IF(_releaseTargets)
	    ADD_DEPENDENCIES(release ${_releaseTargets})
	ENDIF(_releaseTargets)

	## Run after release
	#ADD_CUSTOM_COMMAND(TARGET release
	#    POST_BUILD
	#    COMMAND make after_release_commit
	#    COMMENT "After released ${PROJECT_NAME}-${PRJ_VER}"
	#    )

    ENDMACRO(MANAGE_RELEASE)
ENDIF(NOT DEFINED _MANAGE_RELEASE_CMAKE_)

