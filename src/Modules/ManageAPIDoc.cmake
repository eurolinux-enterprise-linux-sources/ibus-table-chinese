# - Mage generated API documents
# This module is for API document generation, such as doxygen.
# Defines following macros:
#   MANAGE_APIDOC_DOXYGEN(doxygen_in doc_dir)
#   - This macro generate documents according to doxygen template.
#     Arguments:
#     + doxygen_in: Doxygen template file.
#     + doc_dir: Document source directory to be copied from.
#     Reads following variable:
#     + PRJ_DOC_DIR: Directory for document
#
#
IF(NOT DEFINED _MANAGE_APIDOC_CMAKE_)
    SET(_MANAGE_APIDOC_CMAKE_ "DEFINED")
    INCLUDE(ManageMessage)

    MACRO(MANAGE_APIDOC_DOXYGEN doxygen_in doc_dir)
	SET(SOURCE_ARCHIVE_IGNORE_FILES ${SOURCE_ARCHIVE_IGNORE_FILES} "/Doxyfile$")
	SET(_manage_apidoc_doxygen_dependency_missing 0)
	IF(NOT PRJ_DOC_DIR)
	    M_MSG(${M_OFF} "PRJ_DOC_DIR undefined. Doxygen support disabled.")
	    SET(_manage_apidoc_doxygen_dependency_missing 1)
	ENDIF(NOT PRJ_DOC_DIR)

	FIND_PACKAGE(doxygen)
	IF(NOT PACKAGE_FOUND_NAME)
	    M_MSG(${M_OFF} "Package doxygen not found. Doxygen support disabled.")
	    SET(_manage_apidoc_doxygen_dependency_missing 1)
	ENDIF(NOT PACKAGE_FOUND_NAME)

	FIND_PROGRAM(DOXYGEN_CMD doxygen)
	IF(DOXYGEN_CMD STREQUAL "DOXYGEN_CMD-NOTFOUND")
	    M_MSG(${M_OFF} "Program doxygen not found. Doxygen support disabled.")
	    SET(_manage_apidoc_doxygen_dependency_missing 1)
	ENDIF(DOXYGEN_CMD STREQUAL "DOXYGEN_CMD-NOTFOUND")

	IF(NOT _manage_apidoc_doxygen_dependency_missing)
	    CONFIGURE_FILE(${doxygen_in} Doxyfile)

	    ADD_CUSTOM_TARGET(doxygen
		COMMAND "${DOXYGEN_CMD}" "Doxyfile"
		)

	    INSTALL(DIRECTORY ${doc_dir}
		DESTINATION "${PRJ_DOC_DIR}"
		)
	ENDIF(NOT _manage_apidoc_doxygen_dependency_missing)
    ENDMACRO(MANAGE_APIDOC_DOXYGEN doxygen_template)
ENDIF(NOT DEFINED _MANAGE_APIDOC_CMAKE_)

