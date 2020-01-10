# - Software Translation support
# This module supports software translation by:
#   1) Creates gettext related targets.
#   2) Communicate to Zanata servers.
#
# Defines following targets:
#   + translations: Make the translation files.
#     This target itself does nothing but provide a target for others to
#     depend on.
#     If macro MANAGE_GETTEXT is used, then it depends on the target gmo_files.
#
# Defines following variables:
#   + XGETTEXT_OPTIONS_C: Usual xgettext options for C programs.
#
# Defines following macros:
#   MANAGE_GETTEXT [ALL] SRCS src1 [src2 [...]]
#	[LOCALES locale1 [locale2 [...]]]
#	[POTFILE potfile]
#	[XGETTEXT_OPTIONS xgettextOpt]]
#	)
#   - Provide Gettext support like pot file generation and
#     gmo file generation.
#     You can specify supported locales with LOCALES ...
#     or omit the locales to use all the po files.
#
#     Arguments:
#     + ALL: (Optional) make target "all" depends on gettext targets.
#     + SRCS src1 [src2 [...]]: File list of source code that contains msgid.
#     + LOCALES locale1 [local2 [...]]:(optional) Locale list to be generated.
#       Currently, only the format: lang_Region (such as fr_FR) is supported.
#     + POTFILE potFile: (optional) pot file to be referred.
#       Default: ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot
#     + XGETTEXT_OPTIONS xgettextOpt: (optional) xgettext_options.
#       Default: ${XGETTEXT_OPTIONS_C}
#     Defines following variables:
#     + GETTEXT_MSGMERGE_CMD: the full path to the msgmerge tool.
#     + GETTEXT_MSGFMT_CMD: the full path to the msgfmt tool.
#     + XGETTEXT_CMD: the full path to the xgettext.
#     Targets:
#     + pot_file: Generate the pot_file.
#     + gmo_files: Converts input po files into the binary output mo files.
#
#   MANAGE_ZANATA(serverUrl [YES])
#   - Use Zanata (was flies) as translation service.
#     Arguments:
#     + serverUrl: The URL of Zanata server
#     + YES: Assume yes for all questions.
#     Reads following variables:
#     + ZANATA_XML_FILE: Path to zanata.xml
#       Default:${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml
#     + ZANATA_INI_FILE: Path to zanata.ini
#       Default:${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml
#     + ZANATA_PUSH_OPTIONS: Options for zanata push
#     + ZANATA_PULL_OPTIONS: Options for zanata pull
#     Targets:
#     + zanata_project_create: Create project with PROJECT_NAME in zanata
#       server.
#     + zanata_version_create: Create version PRJ_VER in zanata server.
#     + zanata_push: Push source messages to zanata server
#     + zanata_push_trans: Push source messages and translations to zanata server.
#     + zanata_pull: Pull translations from zanata server.
#


IF(NOT DEFINED _MANAGE_TRANSLATION_CMAKE_)
    SET(_MANAGE_TRANSLATION_CMAKE_ "DEFINED")
    SET(XGETTEXT_OPTIONS_C
	--language=C --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 -s
	--package-name=${PROJECT_NAME} --package-version=${PRJ_VER})
    SET(MANAGE_TRANSLATION_GETTEXT_MSGMERGE_OPTIONS "--indent" "--update" "--backup=none" CACHE STRING "msgmerge options")
    SET_DIRECTORY_PROPERTIES(PROPERTIES CLEAN_NO_CUSTOM "1")

    INCLUDE(ManageMessage)
    IF(NOT TARGET translations)
	ADD_CUSTOM_TARGET(translations
	    COMMENT "Making translations"
	    )
    ENDIF(NOT TARGET translations)

    #========================================
    # GETTEXT support

    MACRO(MANAGE_GETTEXT_INIT)
	FIND_PROGRAM(XGETTEXT_CMD xgettext)
	IF(XGETTEXT_CMD STREQUAL "XGETTEXT_CMD-NOTFOUND")
	    SET(_gettext_dependency_missing 1)
	    M_MSG(${M_OFF} "xgettext not found! gettext support disabled.")
	ENDIF(XGETTEXT_CMD STREQUAL "XGETTEXT_CMD-NOTFOUND")

	FIND_PROGRAM(GETTEXT_MSGMERGE_CMD msgmerge)
	IF(GETTEXT_MSGMERGE_CMD STREQUAL "GETTEXT_MSGMERGE_CMD-NOTFOUND")
	    SET(_gettext_dependency_missing 1)
	    M_MSG(${M_OFF} "msgmerge not found! gettext support disabled.")
	ENDIF(GETTEXT_MSGMERGE_CMD STREQUAL "GETTEXT_MSGMERGE_CMD-NOTFOUND")

	FIND_PROGRAM(GETTEXT_MSGFMT_CMD msgfmt)
	IF(GETTEXT_MSGFMT_CMD STREQUAL "GETTEXT_MSGFMT_CMD-NOTFOUND")
	    SET(_gettext_dependency_missing 1)
	    M_MSG(${M_OFF} "msgfmt not found! gettext support disabled.")
	ENDIF(GETTEXT_MSGFMT_CMD STREQUAL "GETTEXT_MSGFMT_CMD-NOTFOUND")

    ENDMACRO(MANAGE_GETTEXT_INIT)

    FUNCTION(MANAGE_GETTEXT)
	SET(_gettext_dependency_missing 0)
	MANAGE_GETTEXT_INIT()
	IF(NOT _gettext_dependency_missing)
	    SET(_stage "")
	    SET(_all "")
	    SET(_srcList "")
	    SET(_srcList_abs "")
	    SET(_localeList "")
	    SET(_potFile "")
	    SET(_xgettext_option_list "")
	    FOREACH(_arg ${ARGN})
		IF(_arg STREQUAL "ALL")
		    SET(_all "ALL")
		ELSEIF(_arg STREQUAL "SRCS")
		    SET(_stage "SRCS")
		ELSEIF(_arg STREQUAL "LOCALES")
		    SET(_stage "LOCALES")
		ELSEIF(_arg STREQUAL "XGETTEXT_OPTIONS")
		    SET(_stage "XGETTEXT_OPTIONS")
		ELSEIF(_arg STREQUAL "POTFILE")
		    SET(_stage "POTFILE")
		ELSE(_arg STREQUAL "ALL")
		    IF(_stage STREQUAL "SRCS")
			FILE(RELATIVE_PATH _relFile ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${_arg})
			LIST(APPEND _srcList ${_relFile})
			GET_FILENAME_COMPONENT(_absPoFile ${_arg} ABSOLUTE)
			LIST(APPEND _srcList_abs ${_absPoFile})
		    ELSEIF(_stage STREQUAL "LOCALES")
			LIST(APPEND _localeList ${_arg})
		    ELSEIF(_stage STREQUAL "XGETTEXT_OPTIONS")
			LIST(APPEND _xgettext_option_list ${_arg})
		    ELSEIF(_stage STREQUAL "POTFILE")
			SET(_potFile "${_arg}")
		    ELSE(_stage STREQUAL "SRCS")
			M_MSG(${M_WARN} "MANAGE_GETTEXT: not recognizing arg ${_arg}")
		    ENDIF(_stage STREQUAL "SRCS")
		ENDIF(_arg STREQUAL "ALL")
	    ENDFOREACH(_arg ${ARGN})

	    # Default values
	    IF(_xgettext_option_list STREQUAL "")
		SET(_xgettext_option_list ${XGETTEXT_OPTIONS_C})
	    ENDIF(_xgettext_option_list STREQUAL "")

	    IF(_potFile STREQUAL "")
		SET(_potFile "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pot")
	    ENDIF(_potFile STREQUAL "")

	    IF(NOT _localeList)
		FILE(GLOB _poFiles "*.po")
		FOREACH(_poFile ${_poFiles})
		    GET_FILENAME_COMPONENT(_locale "${_poFile}" NAME_WE)
		    LIST(APPEND _localeList "${_locale}")
		ENDFOREACH(_poFile ${_poFiles})
	    ENDIF(NOT _localeList)

	    M_MSG(${M_INFO2} "XGETTEXT=${XGETTEXT_CMD} ${_xgettext_option_list} -o ${_potFile} ${_srcList}")
	    ADD_CUSTOM_COMMAND(OUTPUT ${_potFile}
		COMMAND ${XGETTEXT_CMD} ${_xgettext_option_list} -o ${_potFile} ${_srcList}
		DEPENDS ${_srcList_abs}
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMENT "Extract translatable messages to ${_potFile}"
		)

	    ADD_CUSTOM_TARGET(pot_file ${_all}
		DEPENDS ${_potFile}
		)

	    ### Generating gmo files
	    SET(_gmoFileList "")
	    SET(_absGmoFileList "")
	    SET(_absPoFileList "")
	    GET_FILENAME_COMPONENT(_potBasename ${_potFile} NAME_WE)
	    GET_FILENAME_COMPONENT(_potDir ${_potFile} PATH)
	    GET_FILENAME_COMPONENT(_absPotFile ${_potFile} ABSOLUTE)
	    GET_FILENAME_COMPONENT(_absPotDir ${_absPotFile} PATH)
	    FOREACH(_locale ${_localeList})
		SET(_absGmoFile ${_absPotDir}/${_locale}.gmo)
		SET(_absPoFile ${_absPotDir}/${_locale}.po)

		ADD_CUSTOM_COMMAND(OUTPUT ${_absPoFile}
		    COMMAND ${GETTEXT_MSGMERGE_CMD}
		    ${MANAGE_TRANSLATION_GETTEXT_MSGMERGE_OPTIONS} ${_absPoFile} ${_potFile}
		    DEPENDS ${_potFile}
		    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		    COMMENT "${GETTEXT_MSGMERGE_CMD} ${MANAGE_TRANSLATION_GETTEXT_MSGMERGE_OPTIONS} ${_absPoFile} ${_potFile}"
		    )

		ADD_CUSTOM_COMMAND(OUTPUT ${_absGmoFile}
		    COMMAND ${GETTEXT_MSGFMT_CMD} -o ${_absGmoFile} ${_absPoFile}
		    DEPENDS ${_absPoFile}
		    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		    COMMENT "${GETTEXT_MSGFMT_CMD} -o ${_absGmoFile} ${_absPoFile}"
		    )

		#MESSAGE("_absPoFile=${_absPoFile} _absPotDir=${_absPotDir} _lang=${_lang} curr_bin=${CMAKE_CURRENT_BINARY_DIR}")
		INSTALL(FILES ${_absGmoFile} DESTINATION share/locale/${_locale}/LC_MESSAGES RENAME ${_potBasename}.mo)
		LIST(APPEND _absGmoFileList ${_absGmoFile})
		LIST(APPEND _absPoFileList ${_absPoFile})
	    ENDFOREACH(_locale ${_localeList})
	    SET_DIRECTORY_PROPERTIES(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${_absGmoFileList};${_potFile}" )

	    SET(MANAGE_TRANSLATION_GETTEXT_PO_FILES ${_absPoFileList} CACHE STRING "PO files")

	    ADD_CUSTOM_TARGET(gmo_files ${_all}
		DEPENDS ${_absGmoFileList}
		COMMENT "Generate gmo files for translation"
		)

	    ADD_DEPENDENCIES(translations gmo_files)
	ENDIF(NOT _gettext_dependency_missing)
    ENDFUNCTION(MANAGE_GETTEXT)


    #========================================
    # ZANATA support
    MACRO(MANAGE_ZANATA serverUrl)
	SET(ZANATA_SERVER "${serverUrl}")
	FIND_PROGRAM(ZANATA_CMD zanata)
	SET(_manage_zanata_dependencies_missing 0)
	IF(ZANATA_CMD STREQUAL "ZANATA_CMD-NOTFOUND")
	    SET(_manage_zanata_dependencies_missing 1)
	    M_MSG(${M_OFF} "zanata (python client) not found! zanata support disabled.")
	ENDIF(ZANATA_CMD STREQUAL "ZANATA_CMD-NOTFOUND")

	SET(ZANATA_XML_FILE "${CMAKE_CURRENT_SOURCE_DIR}/zanata.xml" CACHE FILEPATH "zanata.xml")
	IF(NOT EXISTS "${ZANATA_XML_FILE}")
	    SET(_manage_zanata_dependencies_missing 1)
	    M_MSG(${M_OFF} "zanata.xml is not found! Zanata support disabled.")
	ENDIF(NOT EXISTS "${ZANATA_XML_FILE}")

	SET(ZANATA_INI_FILE "$ENV{HOME}/.config/zanata.ini" CACHE FILEPATH "zanata.ni")
	IF(NOT EXISTS "${ZANATA_INI_FILE}")
	    SET(_manage_zanata_dependencies_missing 1)
	    M_MSG(${M_OFF} "zanata.ini is not found! Zanata support disabled.")
	ENDIF(NOT EXISTS "${ZANATA_INI_FILE}")

	IF(NOT _manage_zanata_dependencies_missing)
	    SET(_zanata_args --url "${ZANATA_SERVER}"
		--project-config "${ZANATA_XML_FILE}" --user-config "${ZANATA_INI_FILE}")

	    # Parsing arguments
	    SET(_yes "")
	    FOREACH(_arg ${ARGN})
		IF(_arg STREQUAL "YES")
		    SET(_yes "yes" "|")
		ENDIF(_arg STREQUAL "YES")
	    ENDFOREACH(_arg ${ARGN})

	    ADD_CUSTOM_TARGET(zanata_project_create
		COMMAND ${ZANATA_CMD} project create ${PROJECT_NAME} ${_zanata_args}
		--project-name "${PROJECT_NAME}" --project-desc "${PRJ_SUMMARY}"
		COMMENT "Creating project ${PROJECT_NAME} on Zanata server ${serverUrl}"
		VERBATIM
		)

	    ADD_CUSTOM_TARGET(zanata_version_create
		COMMAND ${ZANATA_CMD} version create
		${PRJ_VER} ${_zanata_args} --project-id "${PROJECT_NAME}"
		COMMENT "Creating version ${PRJ_VER} on Zanata server ${serverUrl}"
		VERBATIM
		)

	    SET(_po_files_depend "")
	    IF(MANAGE_TRANSLATION_GETTEXT_PO_FILES)
		SET(_po_files_depend "DEPENDS" ${MANAGE_TRANSLATION_GETTEXT_PO_FILES})
	    ENDIF(MANAGE_TRANSLATION_GETTEXT_PO_FILES)
	    # Zanata push
	    ADD_CUSTOM_TARGET(zanata_push
		COMMAND ${_yes}
		${ZANATA_CMD} push ${_zanata_args} ${ZANATA_PUSH_OPTIONS}
		${_po_files_depend}
		COMMENT "Push source messages to zanata server ${ZANATA_SERVER}"
		VERBATIM
		)
	    ADD_DEPENDENCIES(zanata_push pot_file)

	    # Zanata push with translation
	    ADD_CUSTOM_TARGET(zanata_push_trans
		COMMAND ${_yes}
		${ZANATA_CMD} push ${_zanata_args} --push-type both ${ZANATA_PUSH_OPTIONS}
		${_po_files_depend}
		COMMENT "Push source messages and translations to zanata server ${ZANATA_SERVER}"
		VERBATIM
		)

	    ADD_DEPENDENCIES(zanata_push_trans pot_file)

	    # Zanata pull
	    ADD_CUSTOM_TARGET(zanata_pull
		COMMAND ${_yes}
		${ZANATA_CMD} pull ${_zanata_args} ${ZANATA_PULL_OPTIONS}
		COMMENT "Pull translations fro zanata server ${ZANATA_SERVER}"
		VERBATIM
		)

	ENDIF(NOT _manage_zanata_dependencies_missing)
    ENDMACRO(MANAGE_ZANATA serverUrl)

ENDIF(NOT DEFINED _MANAGE_TRANSLATION_CMAKE_)

