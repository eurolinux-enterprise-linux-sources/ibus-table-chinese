# - Module for working with Fedora and EPEL releases.
#
# This module provides convenient targets and macros for Fedora and EPEL
# releases by using fedpkg, koji, and bodhi
#
# This module check following files for dependencies:
#  1. ~/.fedora-upload-ca.cert : Ensure it has certificate file to submit to Fedora.
#  2. fedpkg : Required to submit to fedora.
#  3. koji : Required to submit to fedora.
#  4. bodhi : Required to submit to fedora.
#
#  If on of above file is missing, this module will be skipped.
#
# This module read the supported release information from cmake-fedora.conf
# It finds cmake-fedora.conf in following order:
# 1. Current directory
# 2. Path as defined CMAKE_SOURCE_DIR
# 3. /etc/cmake-fedora.conf
#
# Includes:
#   ManageMessage
#
# Defines following variables:
#    CMAKE_FEDORA_CONF: Path to cmake_fedora.conf
#    FEDPKG_CMD: Path to fedpkg
#    KOJI_CMD: Path to koji
#    GIT_CMD: Path to git
#    BODHI_CMD: Path to bodhi
#    KOJI_BUILD_SCRATCH_CMD: Path to koji-build-scratch
#    FEDORA_RAWHIDE_VER: Fedora Rawhide version.
#    FEDORA_SUPPORTED_VERS: Fedora supported versions.
#    EPEL_SUPPORTED_VERS: EPEL supported versions.
#    FEDPKG_DIR: Dir for fedpkg
#    FEDORA_KAMA: Fedora Karma. Default:3
#    FEDORA_UNSTABLE_KARMA: Fedora unstable Karma. Default:3
#    FEDORA_AUTO_KARMA: Whether to use fedora Karma system. Default:"True"
#
# Defines following functions:
#   RELEASE_FEDORA(tagList)
#   - Release this project to specified Fedora and EPEL releases.
#     Arguments:
#     + tagList: Fedora and EPEL dist tags that this project submit to.
#       E.g. "f18", "f17", "el7"
#       You can also specify "fedora" for fedora current releases,
#       and/or "epel" for EPEL current releases.
#
#     Reads following variables:
#     + PRJ_SRPM_FILE: Project SRPM
#     + FEDPKG_DIR: Directory for fedpkg checkout.
#       Default: FedPkg.
#     Reads and define following variables:
#     + FEDORA_RAWHIDE_VER: Numeric version of rawhide, such as 18
#     + FEDORA_SUPPORTED_VERS: Numeric versions of currently supported Fedora,
#       such as 17;16
#     + EPEL_SUPPORTED_VERS: Numeric versions of currently supported EPEL
#       since version 5. Such as 6;5
#     + FEDORA_KARMA: Karma for auto pushing.
#       Default: 3
#     + FEDORA_UNSTABLE_KARMA: Karma for auto unpushing.
#       Default: 3
#     + FEDORA_AUTO_KARMA: Whether to enable auto pushing/unpushing
#       Default: True
#     Defines following targets:
#     + release_fedora: Make necessary steps for releasing on fedora,
#       such as making source file tarballs, source rpms, build with fedpkg
#       and upload to bodhi.
#     + bodhi_new: Submit the package to bodhi
#     + fedpkg_<tag>_build: Build for tag
#     + fedpkg_<tag>_commit: Import, commit and push
#     + koji_build_scratch: Scratch build using koji
#
#

IF(NOT DEFINED _MANAGE_RELEASE_FEDORA_)
    SET(_MANAGE_RELEASE_FEDORA_ "DEFINED")
    INCLUDE(ManageMessage)
    INCLUDE(ManageTarget)
    SET(_manage_release_fedora_dependencies_missing 0)
    SET(KOJI_BUILD_SCRATCH "koji-build-scratch" CACHE INTERNAL "Koji build scratch name")

    FIND_FILE(CMAKE_FEDORA_CONF cmake-fedora.conf "." "${CMAKE_SOURCE_DIR}" "${SYSCONF_DIR}")
    M_MSG(${M_INFO1} "CMAKE_FEDORA_CONF=${CMAKE_FEDORA_CONF}")
    IF("${CMAKE_FEDORA_CONF}" STREQUAL "CMAKE_FEDORA_CONF-NOTFOUND")
	M_MSG(${M_OFF} "cmake-fedora.conf cannot be found! Fedora release support disabled.")
	SET(_manage_release_fedora_dependencies_missing 1)
    ENDIF("${CMAKE_FEDORA_CONF}" STREQUAL "CMAKE_FEDORA_CONF-NOTFOUND")

    FIND_PROGRAM(FEDPKG_CMD fedpkg)
    IF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program fedpkg is not found! Fedora support disabled.")
	SET(_manage_release_fedora_dependencies_missing 1)
    ENDIF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")

    FIND_PROGRAM(KOJI_CMD koji)
    IF(KOJI_CMD STREQUAL "KOJI_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program koji is not found! Koji support disabled.")
    ENDIF(KOJI_CMD STREQUAL "KOJI_CMD-NOTFOUND")

    FIND_PROGRAM(GIT_CMD git)
    IF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program git is not found! Fedora support disabled.")
	SET(_manage_release_fedora_dependencies_missing 1)
    ENDIF(FEDPKG_CMD STREQUAL "FEDPKG_CMD-NOTFOUND")

    FIND_PROGRAM(BODHI_CMD bodhi)
    IF(BODHI_CMD STREQUAL "BODHI_CMD-NOTFOUND")
	M_MSG(${M_OFF} "Program bodhi is not found! Bodhi support disabled.")
    ENDIF(BODHI_CMD STREQUAL "BODHI_CMD-NOTFOUND")


    ## Set variables
    IF(NOT _manage_release_fedora_dependencies_missing)
	# Set release tags according to CMAKE_FEDORA_CONF
	SETTING_FILE_GET_ALL_VARIABLES(${CMAKE_FEDORA_CONF})

	SET(FEDORA_RAWHIDE_VER "${FEDORA_RAWHIDE_VERSION}"
	    CACHE STRING "Fedora Rawhide ver" FORCE)
	STRING_SPLIT(_FEDORA_SUPPORTED_VERS " " ${FEDORA_SUPPORTED_VERSIONS})
	SET(FEDORA_SUPPORTED_VERS ${_FEDORA_SUPPORTED_VERS}
	    CACHE STRING "Fedora supported vers" FORCE)

	STRING_SPLIT(_EPEL_SUPPORTED_VERS " " ${EPEL_SUPPORTED_VERSIONS})
	SET(EPEL_SUPPORTED_VERS ${_EPEL_SUPPORTED_VERS}
	    CACHE STRING "EPEL supported vers" FORCE)

	SET(FEDORA_KOJI_TAG_POSTFIX "" CACHE STRING "Koji Fedora tag prefix")
	SET(EPEL_KOJI_TAG_POSTFIX "-testing-candidate"
	    CACHE STRING "Koji EPEL tag prefix")

	SET(BODHI_TEMPLATE_FILE "${CMAKE_FEDORA_TMP_DIR}/bodhi.template"
	    CACHE FILEPATH "Bodhi template file"
	    )

	SET(FEDPKG_DIR "${CMAKE_BINARY_DIR}/FedPkg" CACHE PATH "FedPkg dir")
	FILE(MAKE_DIRECTORY ${FEDPKG_DIR})

	GET_FILENAME_COMPONENT(_FEDPKG_DIR_NAME ${FEDPKG_DIR} NAME)
	LIST(APPEND SOURCE_ARCHIVE_IGNORE_FILES "/${_FEDPKG_DIR_NAME}/")

	## Fedora package variables
	SET(FEDORA_KARMA "3" CACHE STRING "Fedora Karma")
	SET(FEDORA_UNSTABLE_KARMA "-3" CACHE STRING "Fedora unstable Karma")
	SET(FEDORA_AUTO_KARMA "True" CACHE STRING "Fedora auto Karma")

	FIND_PROGRAM(KOJI_BUILD_SCRATCH_CMD ${KOJI_BUILD_SCRATCH} PATHS ${CMAKE_BINARY_DIR}/scripts . )
	IF(KOJI_BUILD_SCRATCH_CMD STREQUAL "KOJI_BUILD_SCRATCH_CMD-NOTFOUND")
	    M_MSG(${M_OFF} "Program koji_build_scratch is not found!")
	ENDIF(KOJI_BUILD_SCRATCH_CMD STREQUAL "KOJI_BUILD_SCRATCH_CMD-NOTFOUND")

	SET(FEDPKG_PRJ_DIR "${FEDPKG_DIR}/${PROJECT_NAME}")

	## Don't use what is in git, otherwise it will be cleaned
	## By make clean
	SET(FEDPKG_PRJ_DIR_GIT "${FEDPKG_PRJ_DIR}/.git/.cmake-fedora")

	ADD_CUSTOM_COMMAND(OUTPUT ${FEDPKG_PRJ_DIR_GIT}
	    COMMAND [ -d ${FEDPKG_PRJ_DIR} ] || ${FEDPKG_CMD} clone ${PROJECT_NAME}
	    COMMAND ${CMAKE_COMMAND} -E touch ${FEDPKG_PRJ_DIR_GIT}
	    COMMENT "Making FedPkg directory"
	    WORKING_DIRECTORY ${FEDPKG_DIR}
	    VERBATIM
	    )

    ENDIF(NOT _manage_release_fedora_dependencies_missing)

    FUNCTION(RELEASE_ADD_KOJI_BUILD_SCRATCH)
	IF(NOT _manage_release_fedora_dependencies_missing)
	    ADD_CUSTOM_TARGET(koji_build_scratch
		COMMAND ${KOJI_BUILD_SCRATCH_CMD} ${PRJ_SRPM_FILE} ${ARGN}
		DEPENDS "${PRJ_SRPM_FILE}"
		COMMENT "koji scratch build on ${PRJ_SRPM_FILE}"
		VERBATIM
		)
	ENDIF(NOT _manage_release_fedora_dependencies_missing)
	ADD_DEPENDENCIES(koji_build_scratch rpmlint)
	ADD_DEPENDENCIES(tag_pre koji_build_scratch)
    ENDFUNCTION(RELEASE_ADD_KOJI_BUILD_SCRATCH)

    # Convert fedora koji tag to bodhi tag
    FUNCTION(_RELEASE_TO_BODHI_TAG bodhiTag tag)
	STRING(REGEX REPLACE "f([0-9]+)" "fc\\1" _tag_replace "${tag}")
	IF(_tag_replace STREQUAL "")
	    SET(${bodhiTag} "${tag}" PARENT_SCOPE)
	ELSE(_tag_replace STREQUAL "")
	    SET(${bodhiTag} "${_tag_replace}" PARENT_SCOPE)
	ENDIF(_tag_replace STREQUAL "")
    ENDFUNCTION(_RELEASE_TO_BODHI_TAG bodhiTag tag)

    FUNCTION(RELEASE_ADD_FEDPKG_TARGETS tag)
	IF(NOT _manage_release_fedora_dependencies_missing)
	    SET(_branch ${tag})
	    IF("${tag}" STREQUAL "f${FEDORA_RAWHIDE_VER}")
		SET(_branch "master")
	    ENDIF("${tag}" STREQUAL "f${FEDORA_RAWHIDE_VER}")

	    _RELEASE_TO_BODHI_TAG(_bodhi_tag "${tag}")

	    ## Fedpkg import and commit
	    SET(_import_opt "")
	    IF(NOT ver EQUAL FEDORA_RAWHIDE_VER)
		SET(_import_opt "-b ${tag}")
	    ENDIF(NOT ver EQUAL FEDORA_RAWHIDE_VER)

	    #Commit summary
	    IF (DEFINED CHANGE_SUMMARY)
		SET (COMMIT_MSG  "-m" "${CHANGE_SUMMARY}")
	    ELSE(DEFINED CHANGE_SUMMARY)
		SET (COMMIT_MSG  "-m"  "On releasing ${PRJ_VER}-${PRJ_RELEASE_NO}")
	    ENDIF(DEFINED CHANGE_SUMMARY)
	    # Depends on tag file instead of target "tag"
	    # To avoid excessive scratch build and rpmlint
	    SET(_commit_opt --push --tag )

	    SET(_fedpkg_nvrd "${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE_NO}.${_bodhi_tag}")
	    SET(_fedpkg_nvrd_commit_file
		"${CMAKE_FEDORA_TMP_DIR}/${_fedpkg_nvrd}.commit")

	    IF(_branch STREQUAL "master")
		# Can't use ADD_CUSTOM_TARGET_COMMAND here, as the COMMIT_SUMMARY may have semi-colon ':'
		ADD_CUSTOM_COMMAND(OUTPUT "${FEDPKG_NVR_RAWHIDE_COMMIT_FILE}"
		    COMMAND test -d ${PROJECT_NAME} || ${FEDPKG_CMD} clone ${PROJECT_NAME}
		    COMMAND ${FEDPKG_CMD} switch-branch ${_branch}
		    COMMAND ${GIT_CMD} pull --all
		    COMMAND ${FEDPKG_CMD} import "${PRJ_SRPM_FILE}"
		    COMMAND ${FEDPKG_CMD} commit ${_commit_opt} -m "${CHANGE_SUMMARY}"
		    COMMAND ${GIT_CMD} push --all
		    COMMAND ${CMAKE_COMMAND} -E touch "${FEDPKG_NVR_RAWHIDE_COMMIT_FILE}"
		    DEPENDS "${FEDPKG_PRJ_DIR_GIT}" "${MANAGE_SOURCE_VERSION_CONTROL_TAG_FILE}" "${PRJ_SRPM_FILE}"
		    WORKING_DIRECTORY ${FEDPKG_PRJ_DIR}
		    COMMENT "fedpkg commit on ${_branch} with ${PRJ_SRPM_FILE}"
		    VERBATIM
		    )

		ADD_CUSTOM_TARGET(fedpkg_${_branch}_commit
		    DEPENDS ${FEDPKG_NVR_RAWHIDE_COMMIT_FILE}
		    )
	    ELSE(_branch STREQUAL "master")
		ADD_CUSTOM_COMMAND(OUTPUT "${_fedpkg_nvrd_commit_file}"
		    COMMAND ${FEDPKG_CMD} switch-branch ${_branch}
		    COMMAND ${GIT_CMD} pull
		    COMMAND ${GIT_CMD} merge -m "Merge branch 'master' into ${_branch}" master
		    COMMAND ${FEDPKG_CMD} push
		    COMMAND ${CMAKE_COMMAND} -E touch "${_fedpkg_nvrd_commit_file}"
		    DEPENDS "${FEDPKG_NVR_RAWHIDE_COMMIT_FILE}"
		    WORKING_DIRECTORY ${FEDPKG_PRJ_DIR}
		    COMMENT "fedpkg commit on ${_branch} with ${PRJ_SRPM_FILE}"
		    VERBATIM
		    )

		ADD_CUSTOM_TARGET(fedpkg_${_branch}_commit
		    DEPENDS "${_fedpkg_nvrd_commit_file}"
		    )
	    ENDIF(_branch STREQUAL "master")

	    ## Fedpkg build
	    SET(_fedpkg_nvrd_build_file
		"${CMAKE_FEDORA_TMP_DIR}/${_fedpkg_nvrd}")

	    ADD_CUSTOM_COMMAND(OUTPUT "${_fedpkg_nvrd_build_file}"
		COMMAND ${FEDPKG_CMD} switch-branch ${_branch}
		COMMAND ${FEDPKG_CMD} build
		COMMAND ${CMAKE_COMMAND} -E touch "${_fedpkg_nvrd_build_file}"
		DEPENDS "${_fedpkg_nvrd_commit_file}"
		WORKING_DIRECTORY ${FEDPKG_PRJ_DIR}
		COMMENT "fedpkg build on ${_branch}"
		VERBATIM
		)

	    ADD_CUSTOM_TARGET(fedpkg_${_branch}_build
		DEPENDS "${_fedpkg_nvrd_build_file}"
		)

	    ADD_DEPENDENCIES(bodhi_new fedpkg_${_branch}_build)

	    ## Fedpkg update
	    SET(_fedpkg_nvrd_update_file
		"${CMAKE_FEDORA_TMP_DIR}/${_fedpkg_nvrd}.update")

	    ADD_CUSTOM_TARGET_COMMAND(fedpkg_${_branch}_update
		OUTPUT "${_fedpkg_nvrd_update_file}"
		COMMAND ${FEDPKG_CMD} switch-branch ${_branch}
		COMMAND ${FEDPKG_CMD} update
		COMMAND ${CMAKE_COMMAND} -E touch "${_fedpkg_nvrd_build_file}"
		DEPENDS ${_fedpkg_nvrd_build_file}
		WORKING_DIRECTORY ${FEDPKG_PRJ_DIR}
		COMMENT "fedpkg build on ${_branch}"
		VERBATIM
		)

	ENDIF(NOT _manage_release_fedora_dependencies_missing)
    ENDFUNCTION(RELEASE_ADD_FEDPKG_TARGETS tag)

    MACRO(_append_notes _file)
    	STRING(REGEX REPLACE "\n" "\n " _notes "${CHANGELOG_ITEMS}")
    	FILE(APPEND "${_file}" "notes=${_notes}\n\n")
    ENDMACRO(_append_notes _file)

    FUNCTION(RELEASE_APPEND_BODHI_FILE tag)
	IF(NOT _manage_release_fedora_dependencies_missing)
	    # Rawhide does not go to bodhi
	    IF(NOT "${tag}" STREQUAL "f${FEDORA_RAWHIDE_VER}")
		_RELEASE_TO_BODHI_TAG(_bodhi_tag "${tag}")

		FILE(APPEND ${BODHI_TEMPLATE_FILE} "[${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE_NO}.${_bodhi_tag}]\n\n")

		IF(BODHI_UPDATE_TYPE)
		    FILE(APPEND ${BODHI_TEMPLATE_FILE} "type=${BODHI_UPDATE_TYPE}\n\n")
		ELSE(BODHI_UPDATE_TYPE)
		    FILE(APPEND ${BODHI_TEMPLATE_FILE} "type=bugfix\n\n")
		ENDIF(BODHI_UPDATE_TYPE)

		FILE(APPEND ${BODHI_TEMPLATE_FILE} "request=testing\n")
		FILE(APPEND ${BODHI_TEMPLATE_FILE} "bugs=${REDHAT_BUGZILLA}\n")

		_append_notes(${BODHI_TEMPLATE_FILE})

		FILE(APPEND ${BODHI_TEMPLATE_FILE} "autokarma=${FEDORA_AUTO_KARMA}\n")
		FILE(APPEND ${BODHI_TEMPLATE_FILE} "stable_karma=${FEDORA_KARMA}\n")
		FILE(APPEND ${BODHI_TEMPLATE_FILE} "unstable_karma=${FEDORA_UNSTABLE_KARMA}\n")
		FILE(APPEND ${BODHI_TEMPLATE_FILE} "close_bugs=True\n")

		IF(SUGGEST_REBOOT)
		    FILE(APPEND ${BODHI_TEMPLATE_FILE} "suggest_reboot=True\n")
		ELSE(SUGGEST_REBOOT)
		    FILE(APPEND ${BODHI_TEMPLATE_FILE} "suggest_reboot=False\n\n")
		ENDIF(SUGGEST_REBOOT)
	    ENDIF(NOT "${tag}" STREQUAL "f${FEDORA_RAWHIDE_VER}")
	ENDIF(NOT _manage_release_fedora_dependencies_missing)
    ENDFUNCTION(RELEASE_APPEND_BODHI_FILE tag)

    FUNCTION(RELEASE_FEDORA)
	IF(NOT _manage_release_fedora_dependencies_missing)
	    ## Parse tags
	    SET(_build_list "f${FEDORA_RAWHIDE_VER}")
	    FOREACH(_rel ${ARGN})
		IF(_rel STREQUAL "fedora")
		    FOREACH(_ver ${FEDORA_SUPPORTED_VERS})
			LIST(APPEND _build_list "f${_ver}")
		    ENDFOREACH(_ver ${FEDORA_SUPPORTED_VERS})
		ELSEIF(_rel STREQUAL "epel")
		    FOREACH(_ver ${EPEL_SUPPORTED_VERS})
			LIST(APPEND _build_list "el${_ver}")
		    ENDFOREACH(_ver ${FEDORA_SUPPORTED_VERS})
		ELSE(_rel STREQUAL "fedora")
		    LIST(APPEND _build_list "${_rel}")
		ENDIF(_rel STREQUAL "fedora")
	    ENDFOREACH(_rel ${ARGN})
	    LIST(REMOVE_DUPLICATES _build_list)

	    IF(BODHI_USER)
		SET(_bodhi_login "-u ${BODHI_USER}")
	    ENDIF(BODHI_USER)

	    ADD_CUSTOM_TARGET(bodhi_new
		COMMAND ${BODHI_CMD} --new ${_bodhi_login} --file ${BODHI_TEMPLATE_FILE}
		DEPENDS "${BODHI_TEMPLATE_FILE}"
		COMMENT "Submit new release to bodhi (Fedora)"
		VERBATIM
		)

	    # NVRD: Name-Version-Release-Dist
	    SET(FEDPKG_NVR_RAWHIDE "${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE_NO}.fc${FEDORA_RAWHIDE_VER}")
	    SET(FEDPKG_NVR_RAWHIDE_COMMIT_FILE "${CMAKE_FEDORA_TMP_DIR}/${FEDPKG_NVR_RAWHIDE}.commit")

	    ## Create targets
	    FILE(REMOVE "${BODHI_TEMPLATE_FILE}")
	    RELEASE_ADD_KOJI_BUILD_SCRATCH(${_build_list})
	    FOREACH(_tag ${_build_list})
		RELEASE_ADD_FEDPKG_TARGETS("${_tag}")
		RELEASE_APPEND_BODHI_FILE("${_tag}")
	    ENDFOREACH(_tag ${_build_list})

	    ADD_CUSTOM_TARGET(release_fedora
		COMMENT "Release for Fedora")

	    ADD_DEPENDENCIES(release_fedora bodhi_new)

	ENDIF(NOT _manage_release_fedora_dependencies_missing)
    ENDFUNCTION(RELEASE_FEDORA)
ENDIF(NOT DEFINED _MANAGE_RELEASE_FEDORA_)

