# - Manage build environment such as environment variables and compile flags.
# This module predefine various environment variables, cmake policies, and
# compile flags.
#
# The setting can be viewed and modified by ccmake.
#
# List of frequently used variable and compile flags:
#    + CMAKE_INSTALL_PREFIX: Compile flag whose value is ${CMAKE_INSTALL_PREFIX}.
#    + BIN_DIR: Directory for executable.
#      Default:  ${CMAKE_INSTALL_PREFIX}/bin
#    + DATA_DIR: Directory for architecture independent data files.
#      Default: ${CMAKE_INSTALL_PREFIX}/share
#    + DOC_DIR: Directory for documentation
#      Default: ${DATA_DIR}/doc
#    + SYSCONF_DIR: System wide configuration files.
#      Default: /etc
#    + LIB_DIR: System wide library path.
#      Default: ${CMAKE_INSTALL_PREFIX}/lib for 32 bit,
#               ${CMAKE_INSTALL_PREFIX}/lib64 for 64 bit.
#    + LIBEXEC_DIR: Executables that are not meant to be executed by user directly.
#      Default: ${CMAKE_INSTALL_PREFIX}/libexec
#    + PROJECT_NAME: Project name
#
# Defines following macros:
#   SET_COMPILE_ENV(var default_value [ENV_NAME env_name]
#     [CACHE type docstring [FORCE]])
#   - Ensure a variable is set to nonempty value, then add the variable and value to
#     compiling definition.
#     The value is determined by following order:
#     1. Value of var if var is defined.
#     2. Environment variable with the same name (or specified via ENV_NAME)
#     3. Parameter default_value
#     Parameters:
#     + var: Variable to be set
#     + default_value: Default value of the var
#     + env_name: (Optional)The name of environment variable.
#       Only need if different from var.
#     + CACHE type docstring [FORCE]:
#       Same with "SET" command.
#
#  SET_USUAL_COMPILE_ENVS()
#  - Set the most often used variable and compile flags.
#    It defines compile flags according to the values of corresponding variables,
#    usually under the same or similar name.
#    If a corresponding variable is not defined yet, then a default value is assigned
#    to that variable, then define the flag.
#
#    Defines following flags according to the variable with same name.
#    + CMAKE_INSTALL_PREFIX: Compile flag whose value is ${CMAKE_INSTALL_PREFIX}.
#    + BIN_DIR: Directory for executable.
#      Default:  ${CMAKE_INSTALL_PREFIX}/bin
#    + DATA_DIR: Directory for architecture independent data files.
#      Default: ${CMAKE_INSTALL_PREFIX}/share
#    + DOC_DIR: Directory for documentation
#      Default: ${DATA_DIR}/doc
#    + SYSCONF_DIR: System wide configuration files.
#      Default: /etc
#    + LIB_DIR: System wide library path.
#      Default: ${CMAKE_INSTALL_PREFIX}/lib for 32 bit,
#               ${CMAKE_INSTALL_PREFIX}/lib64 for 64 bit.
#    + LIBEXEC_DIR: Executables that are not meant to be executed by user directly.
#      Default: ${CMAKE_INSTALL_PREFIX}/libexec
#    + PROJECT_NAME: Project name
#    + PRJ_VER: Project version
#    + PRJ_DATA_DIR: Data directory for the project.
#      Default: ${DATA_DIR}/${PROJECT_NAME}
#    + PRJ_DOC_DIR: DocuFILEPATH = File chooser dialog.
#      Default: ${DOC_DIR}/${PROJECT_NAME}-${PRJ_VER}

IF(NOT DEFINED _MANAGE_ENVIRONMENT_CMAKE_)
    SET(_MANAGE_ENVIRONMENT_CMAKE_ "DEFINED")
    SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS ON)
    CMAKE_POLICY(VERSION 2.6.2)

    MACRO(SET_COMPILE_ENV var default_value)
	SET(_stage "")
	SET(_env "${var}")
	SET(_setOpts "")
	SET(_force 0)
	FOREACH(_arg ${ARGN})
	    IF(_arg STREQUAL "ENV_NAME")
		SET(_stage "ENV_NAME")
	    ELSEIF(_arg STREQUAL "CACHE")
		SET(_stage "_CACHE")
	    ELSE(_arg STREQUAL "ENV_NAME")
		IF(_stage STREQUAL "ENV_NAME")
		    SET(_env "${_arg}")
		ELSEIF(_stage STREQUAL "_CACHE")
		    LIST(APPEND _setOpts "${_arg}")
		    IF(_arg STREQUAL "FORCE")
			SET(_force 1)
		    ENDIF(_arg STREQUAL "FORCE")
		ENDIF(_stage STREQUAL "ENV_NAME")
	    ENDIF(_arg STREQUAL "ENV_NAME")
	ENDFOREACH(_arg ${ARGN})

	IF(NOT "${_setOpts}" STREQUAL "")
	    LIST(INSERT _setOpts 0 "CACHE")
	ENDIF(NOT "${_setOpts}" STREQUAL "")

	# Set the variable
	IF(_force)
	    IF(NOT "$ENV{${_env}}" STREQUAL "")
		SET(${var} "$ENV{${_env}}" ${_setOpts})
	    ELSE(NOT "$ENV{${_env}}" STREQUAL "")
		SET(${var} "${default_value}" ${_setOpts})
	    ENDIF(NOT "$ENV{${_env}}" STREQUAL "")
	ELSE(_force)
	    IF(NOT "${${var}}" STREQUAL "")
		SET(${var} "${${var}}" ${_setOpts})
	    ELSEIF(NOT "$ENV{${_env}}" STREQUAL "")
		SET(${var} "$ENV{${_env}}" ${_setOpts})
	    ELSE(NOT "${${var}}" STREQUAL "")
		# Default value
		SET(${var} "${default_value}" ${_setOpts})
	    ENDIF(NOT "${${var}}" STREQUAL "")
	ENDIF(_force)

	# Enforce CMP0005 to new, yet pop after ADD_DEFINITION
	CMAKE_POLICY(PUSH)
	CMAKE_POLICY(SET CMP0005 NEW)
	ADD_DEFINITIONS(-D${_env}=${${var}})
	CMAKE_POLICY(POP)
	M_MSG(${M_INFO2} "SET(${var} ${${var}})")
    ENDMACRO(SET_COMPILE_ENV var default_value)

    MACRO(MANAGE_CMAKE_POLICY policyName defaultValue)
	IF(POLICY ${policyName})
	    CMAKE_POLICY(GET "${policyName}" _cmake_policy_value)
	    IF(_cmake_policy_value STREQUAL "")
		# Policy not defined yet
		CMAKE_POLICY(SET "${policyName}" "${defaultValue}")
	    ENDIF(_cmake_policy_value STREQUAL "")
	ENDIF(POLICY ${policyName})
    ENDMACRO(MANAGE_CMAKE_POLICY policyName defaultValue)

    ####################################################################
    # Recommended policy setting
    #
    # CMP0005: Preprocessor definition values are now escaped automatically.
    # OLD:Preprocessor definition values are not escaped.
    MANAGE_CMAKE_POLICY(CMP0005 NEW)

    # CMP0009: FILE GLOB_RECURSE calls should not follow symlinks by default.
    # OLD: FILE GLOB_RECURSE calls follow symlinks
    MANAGE_CMAKE_POLICY(CMP0009 NEW)

    # CMP0017: Prefer files from the CMake module directory when including from there.
    # OLD: Prefer files from CMAKE_MODULE_PATH regardless
    MANAGE_CMAKE_POLICY(CMP0017 NEW)

    # Include should be put after the cmake policy
    INCLUDE(ManageMessage)
    M_MSG(${M_INFO1} "CMAKE_HOST_SYSTEM=${CMAKE_HOST_SYSTEM}")
    M_MSG(${M_INFO1} "CMAKE_SYSTEM=${CMAKE_SYSTEM}")

    ####################################################################
    # CMake Variables
    #
    SET_COMPILE_ENV(BIN_DIR  "${CMAKE_INSTALL_PREFIX}/bin"
	CACHE PATH "Binary dir")
    SET_COMPILE_ENV(DATA_DIR "${CMAKE_INSTALL_PREFIX}/share"
	CACHE PATH "Data dir")
    SET_COMPILE_ENV(DOC_DIR  "${DATA_DIR}/doc"
	CACHE PATH "Documentation dir")
    SET_COMPILE_ENV(SYSCONF_DIR "/etc"
	CACHE PATH "System configuration dir")
    SET_COMPILE_ENV(LIBEXEC_DIR "${CMAKE_INSTALL_PREFIX}/libexec"
	CACHE PATH "LIBEXEC dir")

    IF(CMAKE_SYSTEM_PROCESSOR MATCHES "64")
	SET_COMPILE_ENV(IS_64 "64" CACHE STRING "IS_64")
    ENDIF(CMAKE_SYSTEM_PROCESSOR MATCHES "64")

    SET_COMPILE_ENV(LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib${IS_64}"
	CACHE PATH "Library dir")

    SET_COMPILE_ENV(PROJECT_NAME "${PROJECT_NAME}")
    SET_COMPILE_ENV(PRJ_DATA_DIR "${DATA_DIR}/${PROJECT_NAME}")

    # Directory to store cmake-fedora specific temporary files.
    IF(NOT CMAKE_FEDORA_TMP_DIR)
	SET(CMAKE_FEDORA_TMP_DIR "${CMAKE_BINARY_DIR}/NO_PACK")
    ENDIF(NOT CMAKE_FEDORA_TMP_DIR)

    ADD_CUSTOM_COMMAND(OUTPUT ${CMAKE_FEDORA_TMP_DIR}
	COMMAND cmake -E make_directory ${CMAKE_FEDORA_TMP_DIR}
	COMMENT "Create CMAKE_FEDORA_TMP_DIR"
	)
ENDIF(NOT DEFINED _MANAGE_ENVIRONMENT_CMAKE_)
