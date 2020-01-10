# - Manage installation
# Convenient collection of macros and functions to manage installation.
#
# Defines following macros:
#   MANAGE_INSTALL(var file1 [file2 ....])
#   - Managed install. Files are installed to the path specified by var.
#     This macro also sets 'MANAGE_INSTALL_$var' as files that associate to this var
#     The files that are associated to this var is
#     Read and define:
#     + MANAGE_INSTALL_$var : Files to be installed under var.
#     Arguments:
#     + var: A variable that contains install destination path
#     + file1 ... : File to be installed to $var
#

IF(NOT DEFINED _MANAGE_INSTALL_CMAKE_)
    SET (_MANAGE_INSTALL_CMAKE_ "DEFINED")
    SET(MANAGE_INSTALL_FILES "")

    MACRO(MANAGE_INSTALL var file1)
	LIST(APPEND MANAGE_INSTALL_${var} ${file1} ${ARGN})
	INSTALL(FILES $file1 ${ARGN}
	    DESTINATION "${var}")
    ENDMACRO(MANAGE_INSTALL var file1)
ENDIF(NOT DEFINED _MANAGE_INSTALL_CMAKE_)
