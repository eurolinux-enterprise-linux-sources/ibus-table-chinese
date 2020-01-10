# - RPM generation, maintaining (remove old rpm) and verification (rpmlint).
# This module provides macros that provides various rpm building and
# verification targets.
#
# This module needs variable from ManageArchive, so INCLUDE(ManageArchive)
# before this module.
#
# Includes:
#   ManageMessage
#   ManageTarget
#
# Reads and defines following variables if dependencies are satisfied:
#   PRJ_RPM_SPEC_IN_FILE: spec.in that generate spec
#   PRJ_RPM_SPEC_FILE: spec file for rpmbuild.
#   RPM_DIST_TAG: (optional) Current distribution tag such as el5, fc10.
#     Default: Distribution tag from rpm --showrc
#
#   RPM_BUILD_TOPDIR: (optional) Directory of  the rpm topdir.
#     Default: ${CMAKE_BINARY_DIR}
#
#   RPM_BUILD_SPECS: (optional) Directory of generated spec files
#     and RPM-ChangeLog.
#     Note this variable is not for locating
#     SPEC template (project.spec.in), RPM-ChangeLog source files.
#     These are located through the path of spec_in.
#     Default: ${RPM_BUILD_TOPDIR}/SPECS
#
#   RPM_BUILD_SOURCES: (optional) Directory of source (tar.gz or zip) files.
#     Default: ${RPM_BUILD_TOPDIR}/SOURCES
#
#   RPM_BUILD_SRPMS: (optional) Directory of source rpm files.
#     Default: ${RPM_BUILD_TOPDIR}/SRPMS
#
#   RPM_BUILD_RPMS: (optional) Directory of generated rpm files.
#     Default: ${RPM_BUILD_TOPDIR}/RPMS
#
#   RPM_BUILD_BUILD: (optional) Directory for RPM build.
#     Default: ${RPM_BUILD_TOPDIR}/BUILD
#
#   RPM_BUILD_BUILDROOT: (optional) Directory for RPM build.
#     Default: ${RPM_BUILD_TOPDIR}/BUILDROOT
#
# Defines following variables:
#   RPM_IGNORE_FILES: A list of exclude file patterns for PackSource.
#     This value is appended to SOURCE_ARCHIVE_IGNORE_FILES after including
#     this module.
#
# Defines following Macros:
#   PACK_RPM()
#   - Generate spec and pack rpm  according to the spec file.
#     Arguments:
#     Targets:
#     + srpm: Build srpm (rpmbuild -bs).
#     + rpm: Build rpm and srpm (rpmbuild -bb)
#     + rpmlint: Run rpmlint to generated rpms.
#     + clean_rpm": Clean all rpm and build files.
#     + clean_pkg": Clean all source packages, rpm and build files.
#     + clean_old_rpm: Remove old rpm and build files.
#     + clean_old_pkg: Remove old source packages and rpms.
#     This macro defines following variables:
#     + PRJ_RELEASE: Project release with distribution tags. (e.g. 1.fc13)
#     + PRJ_RELEASE_NO: Project release number, without distribution tags. (e.g. 1)
#     + PRJ_SRPM_FILE: Path to generated SRPM file, including relative path.
#     + PRJ_RPM_BUILD_ARCH: Architecture to be build.
#     + PRJ_RPM_FILES: Binary RPM files to be build.
#
#   RPM_MOCK_BUILD()
#   - Add mock related targets.
#     Targets:
#     + rpm_mock_i386: Make i386 rpm
#     + rpm_mock_x86_64: Make x86_64 rpm
#     This macor reads following variables?:
#     + MOCK_RPM_DIST_TAG: Prefix of mock configure file, such as "fedora-11", "fedora-rawhide", "epel-5".
#         Default: Convert from RPM_DIST_TAG
#

IF(NOT DEFINED _MANAGE_RPM_CMAKE_)
    SET (_MANAGE_RPM_CMAKE_ "DEFINED")

    INCLUDE(ManageMessage)
    INCLUDE(ManageTarget)
    SET(_manage_rpm_dependency_missing 0)

    FIND_PROGRAM(RPMBUILD_CMD NAMES "rpmbuild-md5")
    IF("${RPMBUILD_CMD}" STREQUAL "RPMBUILD_CMD-NOTFOUND")
	M_MSG(${M_OFF} "rpmbuild is not found in PATH, rpm build support is disabled.")
	SET(_manage_rpm_dependency_missing 1)
    ENDIF("${RPMBUILD_CMD}" STREQUAL "RPMBUILD_CMD-NOTFOUND")

    SET(_PRJ_RPM_SPEC_IN_FILE_SEARCH_NAMES  "${PROJECT_NAME}.spec.in" "project.spec.in")
    SET(_PRJ_RPM_SPEC_IN_FILE_SEARCH_PATH "${CMAKE_SOURCE_DIR}/SPECS" "SPECS" "." "${RPM_BUILD_TOPDIR}/SPECS")
    FIND_FILE(PRJ_RPM_SPEC_IN_FILE NAMES ${_PRJ_RPM_SPEC_IN_FILE_SEARCH_NAMES} PATHS ${_PRJ_RPM_SPEC_IN_FILE_SEARCH_PATH})
    IF(PRJ_RPM_SPEC_IN_FILE STREQUAL "PRJ_RPM_SPEC_IN_FILE-NOTFOUND")
	M_MSG(${M_OFF} "Cannot find ${PROJECT}.spec.in or project .in"
	    "${_PRJ_RPM_SPEC_IN_FILE_SEARCH_PATH}")
	M_MSG(${M_OFF} "rpm build support is disabled.")
	SET(_manage_rpm_dependency_missing 1)
    ENDIF(PRJ_RPM_SPEC_IN_FILE STREQUAL "PRJ_RPM_SPEC_IN_FILE-NOTFOUND")

    IF(NOT _manage_rpm_dependency_missing)
	INCLUDE(ManageVariable)
	SET (SPEC_FILE_WARNING "This file is generated, please modified the .spec.in file instead!")

	EXECUTE_PROCESS(COMMAND rpm --showrc
	    COMMAND grep -E "dist[[:space:]]*\\."
	    COMMAND sed -e "s/^.*dist\\s*\\.//"
	    COMMAND tr \\n \\t
	    COMMAND sed  -e s/\\t//
	    OUTPUT_VARIABLE _RPM_DIST_TAG)

	SET(RPM_DIST_TAG "${_RPM_DIST_TAG}" CACHE STRING "RPM Dist Tag")
	SET(RPM_BUILD_TOPDIR "${CMAKE_BINARY_DIR}" CACHE PATH "RPM topdir")
	SET(RPM_BUILD_SPECS "${RPM_BUILD_TOPDIR}/SPECS" CACHE PATH "RPM SPECS dir")
	SET(RPM_BUILD_SOURCES "${RPM_BUILD_TOPDIR}/SOURCES" CACHE PATH "RPM SOURCES dir")
	SET(RPM_BUILD_SRPMS "${RPM_BUILD_TOPDIR}/SRPMS" CACHE PATH "RPM SRPMS dir")
	SET(RPM_BUILD_RPMS "${RPM_BUILD_TOPDIR}/RPMS" CACHE PATH "RPM RPMS dir")
	SET(RPM_BUILD_BUILD "${RPM_BUILD_TOPDIR}/BUILD" CACHE PATH "RPM BUILD dir")
	SET(RPM_BUILD_BUILDROOT "${RPM_BUILD_TOPDIR}/BUILDROOT" CACHE PATH "RPM BUILDROOT dir")

	## RPM spec.in and RPM-ChangeLog.prev
	SET(PRJ_RPM_SPEC_FILE "${RPM_BUILD_SPECS}/${PROJECT_NAME}.spec" CACHE FILEPATH "spec")
	SET(PRJ_RPM_SPEC_IN_FILE "${_PRJ_RPM_SPEC_IN_FILE}" CACHE FILEPATH "spec.in")
	GET_FILENAME_COMPONENT(_PRJ_RPM_SPEC_IN_DIR "${PRJ_RPM_SPEC_IN_FILE}" PATH)
	SET(PRJ_RPM_SPEC_IN_DIR "${_PRJ_RPM_SPEC_IN_DIR}" CACHE INTERNAL "Dir contains spec.in")
	SET(RPM_CHANGELOG_PREV_FILE "${PRJ_RPM_SPEC_IN_DIR}/RPM-ChangeLog.prev" CACHE FILEPATH "ChangeLog.prev for RPM")
	SET(RPM_CHANGELOG_FILE "${RPM_BUILD_SPECS}/RPM-ChangeLog" CACHE FILEPATH "ChangeLog for RPM")

	# Add RPM build directories in ignore file list.
	GET_FILENAME_COMPONENT(_rpm_build_sources_basename ${RPM_BUILD_SOURCES} NAME)
	GET_FILENAME_COMPONENT(_rpm_build_srpms_basename ${RPM_BUILD_SRPMS} NAME)
	GET_FILENAME_COMPONENT(_rpm_build_rpms_basename ${RPM_BUILD_RPMS} NAME)
	GET_FILENAME_COMPONENT(_rpm_build_build_basename ${RPM_BUILD_BUILD} NAME)
	GET_FILENAME_COMPONENT(_rpm_build_buildroot_basename ${RPM_BUILD_BUILDROOT} NAME)
	SET(RPM_IGNORE_FILES
	    "/${_rpm_build_sources_basename}/" "/${_rpm_build_srpms_basename}/" "/${_rpm_build_rpms_basename}/"
	    "/${_rpm_build_build_basename}/" "/${_rpm_build_buildroot_basename}/" "debug.*s.list")
	LIST(APPEND SOURCE_ARCHIVE_IGNORE_FILES ${RPM_IGNORE_FILES})

    ENDIF(NOT _manage_rpm_dependency_missing)

    FUNCTION(PRJ_RPM_SPEC_IN_READ_FILE)
	SETTING_FILE_GET_VARIABLE(_releaseStr Release "${PRJ_RPM_SPEC_IN_FILE}" ":")
	STRING(REPLACE "%{?dist}" ".${RPM_DIST_TAG}" _PRJ_RELEASE ${_releaseStr})
	STRING(REPLACE "%{?dist}" "" _PRJ_RELEASE_NO ${_releaseStr})
	#MESSAGE("_releaseTag=${_releaseTag} _releaseStr=${_releaseStr}")

	SET(PRJ_RELEASE ${_PRJ_RELEASE} CACHE STRING "Release with dist" FORCE)
	SET(PRJ_RELEASE_NO ${_PRJ_RELEASE_NO} CACHE STRING "Release w/o dist" FORCE)
	SET(PRJ_SRPM "${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE}.src.rpm" CACHE STRING "PRJ SRPM" FORCE)
	SET(PRJ_SRPM_FILE "${RPM_BUILD_SRPMS}/${PRJ_SRPM}" CACHE FILEPATH "PRJ SRPM File" FORCE)

	## GET BuildArch
	SETTING_FILE_GET_VARIABLE(_archStr BuildArch "${PRJ_RPM_SPEC_IN_FILE}" ":")
	IF(NOT _archStr STREQUAL "noarch")
	    SET(_archStr ${CMAKE_HOST_SYSTEM_PROCESSOR})
	ENDIF(NOT _archStr STREQUAL "noarch")
	SET(PRJ_RPM_BUILD_ARCH "${_archStr}" CACHE STRING "BuildArch")

	## Main rpm
	SET(PRJ_RPM_FILES "${RPM_BUILD_RPMS}/${PRJ_RPM_BUILD_ARCH}/${PROJECT_NAME}-${PRJ_VER}-${PRJ_RELEASE}.${PRJ_RPM_BUILD_ARCH}.rpm"
	    CACHE STRING "RPM files" FORCE)

	## Obtains sub packages
	## [TODO]
    ENDFUNCTION(PRJ_RPM_SPEC_IN_READ_FILE)

    MACRO(RPM_CHANGELOG_WRITE_FILE)
	INCLUDE(DateTimeFormat)

	FILE(WRITE ${RPM_CHANGELOG_FILE} "* ${TODAY_CHANGELOG} ${MAINTAINER} - ${PRJ_VER}-${PRJ_RELEASE_NO}\n")
	FILE(READ "${CMAKE_FEDORA_TMP_DIR}/ChangeLog.this" CHANGELOG_ITEMS)

	FILE(APPEND ${RPM_CHANGELOG_FILE} "${CHANGELOG_ITEMS}\n\n")

	# Update RPM_ChangeLog
	# Use this instead of FILE(READ is to avoid error when reading '\'
	# character.
	EXECUTE_PROCESS(COMMAND cat "${RPM_CHANGELOG_PREV_FILE}"
	    OUTPUT_VARIABLE RPM_CHANGELOG_PREV
	    OUTPUT_STRIP_TRAILING_WHITESPACE)

	FILE(APPEND ${RPM_CHANGELOG_FILE} "${RPM_CHANGELOG_PREV}")

	ADD_CUSTOM_COMMAND(OUTPUT ${RPM_CHANGELOG_FILE}
	    COMMAND ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
	    DEPENDS ${CHANGELOG_FILE} ${RPM_CHANGELOG_PREV_FILE}
	    COMMENT "Write ${RPM_CHANGELOG_FILE}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(rpm_changelog_prev_update
	    COMMAND ${CMAKE_COMMAND} -E copy ${RPM_CHANGELOG_FILE} ${RPM_CHANGELOG_PREV_FILE}
	    DEPENDS ${RPM_CHANGELOG_FILE}
	    COMMENT "${RPM_CHANGELOG_FILE} are saving as ${RPM_CHANGELOG_PREV_FILE}"
	    )

	IF(TARGET after_release_commit_pre)
	    ADD_DEPENDENCIES(after_release_commit_pre rpm_changelog_prev_update)
	ENDIF(TARGET after_release_commit_pre)
    ENDMACRO(RPM_CHANGELOG_WRITE_FILE)

    MACRO(PACK_RPM)
	IF(NOT _manage_rpm_dependency_missing )
	    PRJ_RPM_SPEC_IN_READ_FILE()
	    RPM_CHANGELOG_WRITE_FILE()

	    # Generate spec
	    CONFIGURE_FILE(${PRJ_RPM_SPEC_IN_FILE} ${PRJ_RPM_SPEC_FILE})

	    #-------------------------------------------------------------------
	    # RPM build commands and targets

	    FILE(MAKE_DIRECTORY  ${RPM_BUILD_BUILD})

	    # Don't worry about SRPMS, RPMS and BUILDROOT, it will be created by rpmbuild

	    ADD_CUSTOM_TARGET_COMMAND(srpm
		OUTPUT ${PRJ_SRPM_FILE}
		COMMAND ${RPMBUILD_CMD} -bs ${PRJ_RPM_SPEC_FILE}
		--define '_sourcedir ${RPM_BUILD_SOURCES}'
		--define '_builddir ${RPM_BUILD_BUILD}'
		--define '_srcrpmdir ${RPM_BUILD_SRPMS}'
		--define '_rpmdir ${RPM_BUILD_RPMS}'
		--define '_specdir ${RPM_BUILD_SPECS}'
		DEPENDS ${PRJ_RPM_SPEC_FILE} ${SOURCE_ARCHIVE_FILE}
		COMMENT "Building srpm"
		)

	    # RPMs (except SRPM)

	    ADD_CUSTOM_TARGET_COMMAND(rpm
		OUTPUT ${PRJ_RPM_FILES}
		COMMAND ${RPMBUILD_CMD} -ba  ${PRJ_RPM_SPEC_FILE}
		--define '_sourcedir ${RPM_BUILD_SOURCES}'
		--define '_builddir ${RPM_BUILD_BUILD}'
		--define '_buildrootdir ${RPM_BUILD_BUILDROOT}'
		--define '_srcrpmdir ${RPM_BUILD_SRPMS}'
		--define '_rpmdir ${RPM_BUILD_RPMS}'
		--define '_specdir ${RPM_BUILD_SPECS}'
		DEPENDS ${PRJ_RPM_SPEC_FILE} ${PRJ_SRPM_FILE}
		COMMENT "Building rpm"
		)


	    ADD_CUSTOM_TARGET(install_rpms
		COMMAND find ${RPM_BUILD_RPMS}/${PRJ_RPM_BUILD_ARCH}
		-name '${PROJECT_NAME}*-${PRJ_VER}-${PRJ_RELEASE_NO}.*.${PRJ_RPM_BUILD_ARCH}.rpm' !
		-name '${PROJECT_NAME}-debuginfo-${PRJ_RELEASE_NO}.*.${PRJ_RPM_BUILD_ARCH}.rpm'
		-print -exec sudo rpm --upgrade --hash --verbose '{}' '\\;'
		DEPENDS ${PRJ_RPM_FILES}
		COMMENT "Install all rpms except debuginfo"
		)

	    ADD_CUSTOM_TARGET(rpmlint
		COMMAND find .
		-name '${PROJECT_NAME}*-${PRJ_VER}-${PRJ_RELEASE_NO}.*.rpm'
		-print -exec rpmlint '{}' '\\;'
		DEPENDS ${PRJ_SRPM_FILE} ${PRJ_RPM_FILES}
		)

	    ADD_CUSTOM_TARGET(clean_old_rpm
		COMMAND find .
		-name '${PROJECT_NAME}*.rpm' ! -name '${PROJECT_NAME}*-${PRJ_VER}-${PRJ_RELEASE_NO}.*.rpm'
		-print -delete
		COMMAND find ${RPM_BUILD_BUILD}
		-path '${PROJECT_NAME}*' ! -path '${RPM_BUILD_BUILD}/${PROJECT_NAME}-${PRJ_VER}-*'
		-print -delete
		COMMENT "Cleaning old rpms and build."
		)

	    ADD_CUSTOM_TARGET(clean_old_pkg
		)

	    ADD_DEPENDENCIES(clean_old_pkg clean_old_rpm clean_old_pack_src)

	    ADD_CUSTOM_TARGET(clean_rpm
		COMMAND find . -name '${PROJECT_NAME}-*.rpm' -print -delete
		COMMENT "Cleaning rpms.."
		)
	    ADD_CUSTOM_TARGET(clean_pkg
		)

	    ADD_DEPENDENCIES(clean_rpm clean_old_rpm)
	    ADD_DEPENDENCIES(clean_pkg clean_rpm clean_pack_src)
	ENDIF(NOT _manage_rpm_dependency_missing )
    ENDMACRO(PACK_RPM)

    MACRO(RPM_MOCK_BUILD)
	IF(NOT _manage_rpm_dependency_missing )
	    FIND_PROGRAM(MOCK_CMD mock)
	    IF(MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")
		M_MSG(${M_OFF} "mock is not found in PATH, mock support disabled.")
	    ELSE(MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")
		IF(NOT PRJ_RPM_BUILD_ARCH STREQUAL "noarch")
		    IF(NOT DEFINED MOCK_RPM_DIST_TAG)
			STRING(REGEX MATCH "^fc([1-9][0-9]*)"  _fedora_mock_dist "${RPM_DIST_TAG}")
			STRING(REGEX MATCH "^el([1-9][0-9]*)"  _el_mock_dist "${RPM_DIST_TAG}")

			IF (_fedora_mock_dist)
			    STRING(REGEX REPLACE "^fc([1-9][0-9]*)" "fedora-\\1" MOCK_RPM_DIST_TAG "${RPM_DIST_TAG}")
			ELSEIF (_el_mock_dist)
			    STRING(REGEX REPLACE "^el([1-9][0-9]*)" "epel-\\1" MOCK_RPM_DIST_TAG "${RPM_DIST_TAG}")
			ELSE (_fedora_mock_dist)
			    SET(MOCK_RPM_DIST_TAG "fedora-devel")
			ENDIF(_fedora_mock_dist)
		    ENDIF(NOT DEFINED MOCK_RPM_DIST_TAG)

		    #MESSAGE ("MOCK_RPM_DIST_TAG=${MOCK_RPM_DIST_TAG}")
		    ADD_CUSTOM_TARGET(rpm_mock_i386
			COMMAND ${CMAKE_COMMAND} -E make_directory ${RPM_BUILD_RPMS}/i386
			COMMAND ${MOCK_CMD} -r  "${MOCK_RPM_DIST_TAG}-i386" --resultdir="${RPM_BUILD_RPMS}/i386" ${PRJ_SRPM_FILE}
			DEPENDS ${PRJ_SRPM_FILE}
			)

		    ADD_CUSTOM_TARGET(rpm_mock_x86_64
			COMMAND ${CMAKE_COMMAND} -E make_directory ${RPM_BUILD_RPMS}/x86_64
			COMMAND ${MOCK_CMD} -r  "${MOCK_RPM_DIST_TAG}-x86_64" --resultdir="${RPM_BUILD_RPMS}/x86_64" ${PRJ_SRPM_FILE}
			DEPENDS ${PRJ_SRPM_FILE}
			)
		ENDIF(NOT PRJ_RPM_BUILD_ARCH STREQUAL "noarch")
	    ENDIF(MOCK_CMD STREQUAL "MOCK_CMD-NOTFOUND")
	ENDIF(NOT _manage_rpm_dependency_missing )

    ENDMACRO(RPM_MOCK_BUILD)

ENDIF(NOT DEFINED _MANAGE_RPM_CMAKE_)

