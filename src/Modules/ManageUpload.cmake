# - Upload files to hosting services.
# You can either use sftp, scp or supply custom command for upload.
# The custom command should be in following format:
#    cmd [OPTIONS] [url]
#
# This module defines following macros:
#   MACRO(MANAGE_UPLOAD_MAKE_TARGET varPrefix fileAlias [uploadOptions])
#   - Make a target for upload files.
#     If <varPrefix>_HOST_ALIAS is not empty, the target is
#     upload_${${varPrefix}_HOST_ALIAS}_${fileAlias}, otherwise, the target is
#     upload_${${varPrefix}_HOST_ALIAS}_${fileAlias}
#     Arguments:
#     + varPrefix: Variable prefix
#     + fileAlias: File alias which will be used as part of target name
#     + uploadOptions: Options for the upload command
#     Reads following variables:
#     + <varPrefix>_CMD: Upload command
#     + <varPrefix>_DEPENDS: Extra files that the upload load target depends on.
#     + <varPrefix>_HOST_ALIAS: (Optional) Host alias which will be used as part of target name.
#     + <varPrefix>_HOST_URL: Host URL
#     + <varPrefix>_REMOTE_DIR: (Optional) Remote dir/
#     + <varPrefix>_UPLOAD_FILES: Files to be uploaded. The target depends on these files.
#     + <varPrefix>_UPLOAD_OPTIONS: Options for upload command.
#     + <varPrefix>_USER: (Optional) User for uploading
#
# This module defines following macros:
#   MANAGE_UPLOAD_CMD(cmd fileAlias [USER user] [HOST_URL hostUrl]
#     [HOST_ALIAS hostAlias] [UPLOAD_FILES files] [REMOTE_DIR remoteDir]
#     [UPLOAD_OPTIONS options] [DEPENDS files])
#   - Make a upload target for a upload command
#     Arguments:
#     + cmd: Command to do the
#     + fileAlias: File alias which will be used as part of target name
#     + DEPENDS files: Extra files that the upload load target depends on.
#     + HOST_ALIAS hostAlias: (Optional) Host alias which will be used as part of target name.
#     + HOST_URL hostUrl: Host URL
#     + REMOTE_DIR remoteDir: (Optional) Remote dir/
#     + UPLOAD_FILES files : Files to be uploaded. The target depends on these files.
#     + UPLOAD_OPTIONS options: Options for upload command.
#     + USER user: (Optional) User for uploading
#
#   MANAGE_UPLOAD_SFTP(fileAlias [USER user] [HOST_URL hostUrl]
#     [HOST_ALIAS hostAlias] [UPLOAD_FILES files] [REMOTE_DIR remoteDir]
#     [UPLOAD_OPTIONS options] [DEPENDS files])
#   - Make a upload target for sftp
#     Arguments: See section MANAGE_UPLOAD_CMD
#
#   MANAGE_UPLOAD_SCP(fileAlias [USER user] [HOST_URL hostUrl]
#     [HOST_ALIAS hostAlias] [UPLOAD_FILES files] [REMOTE_DIR remoteDir]
#     [UPLOAD_OPTIONS options] [DEPENDS files])
#   - Make a upload target for scp
#     Arguments: See section MANAGE_UPLOAD_CMD
#
#   MANAGE_UPLOAD_FEDORAHOSTED(fileAlias [USER user]
#     [UPLOAD_FILES files] [REMOTE_DIR remoteDir]
#     [UPLOAD_OPTIONS options] [DEPENDS files])
#   - Make a upload target for uploading to FedoraHosted
#     Arguments: See section MANAGE_UPLOAD_CMD
#
#   MANAGE_UPLOAD_SOURCEFORGE(fileAlias [USER user]
#     [UPLOAD_FILES files] [REMOTE_DIR remoteDir]
#     [UPLOAD_OPTIONS options] [DEPENDS files])
#   - Make a upload target for uploading to SourceForge
#     Arguments: See section MANAGE_UPLOAD_CMD
#
#

IF(NOT DEFINED _MANAGE_UPLOAD_CMAKE_)
    SET(_MANAGE_UPLOAD_CMAKE_ "DEFINED")
    INCLUDE(ManageMessage)

    # MANAGE_UPLOAD_GET_OPTIONS cmd [USER user] [HOST_URL hostUrl] [HOST_ALIAS hostAlias]
    #  [UPLOAD_FILES files] [REMOTE_DIR remoteDir] [UPLOAD_OPTIONS sftpOptions] [DEPENDS files]

    MACRO(_MANAGE_UPLOAD_GET_OPTIONS varList varPrefix)
	SET(_optName "")	## OPTION name
	SET(_opt "")		## Variable that hold option values
	SET(VALID_OPTIONS "USER" "HOST_URL" "HOST_ALIAS" "UPLOAD_FILES" "REMOTE_DIR" "UPLOAD_OPTIONS" "DEPENDS")
	FOREACH(_arg ${ARGN})
	    LIST(FIND VALID_OPTIONS "${_arg}" _optIndex)
	    IF(_optIndex EQUAL -1)
		IF(NOT _optName STREQUAL "")
		    ## Append to existing variable
		    LIST(APPEND ${_opt} "${_arg}")
		    SET(${_opt} "${_opt}" PARENT_SCOPE)
		ENDIF(NOT _optName STREQUAL "")
	    ELSE(_optIndex EQUAL -1)
		## Obtain option name and variable name
		LIST(GET VALID_OPTIONS  ${_optIndex} _optName)
		SET(_opt "${varPrefix}_${_optName}")

		## If variable is not in varList, then set cache and add it to varList
		LIST(FIND ${varList} "${_opt}" _varIndex)
		IF(_varIndex EQUAL -1)
		    SET(${_opt} "" PARENT_SCOPE)
		    LIST(APPEND ${varList} "${_opt}")
		ENDIF(_varIndex EQUAL -1)
	    ENDIF(_optIndex EQUAL -1)
	ENDFOREACH(_arg ${ARGN})
    ENDMACRO(_MANAGE_UPLOAD_GET_OPTIONS varPrefix varList)

    MACRO(MANAGE_UPLOAD_MAKE_TARGET varPrefix fileAlias)
	SET(_target "upload")
	IF(NOT "${varPrefix}_HOST_ALIAS" STREQUAL "")
	    SET(_target "${_target}_${${varPrefix}_HOST_ALIAS}")
	ENDIF(NOT "${varPrefix}_HOST_ALIAS" STREQUAL "")
	SET(_target "${_target}_${fileAlias}")

	## Determine url for upload
	IF(NOT "${varPrefix}_HOST_URL" STREQUAL "")
	    IF("${varPrefix}_USER" STREQUAL "")
		SET(UPLOAD_URL "${${varPrefix}_USER}@${${varPrefix}_HOST_URL}")
	    ELSE("${varPrefix}_USER" STREQUAL "")
		SET(UPLOAD_URL "${${varPrefix}_HOST_URL}")
	    ENDIF("${varPrefix}_USER" STREQUAL "")
	ELSE(NOT "${varPrefix}_HOST_URL" STREQUAL "")
	    SET(UPLOAD_URL "")
	ENDIF(NOT "${varPrefix}_HOST_URL" STREQUAL "")

	IF(NOT "${varPrefix}_REMOTE_DIR" STREQUAL "")
	    SET(UPLOAD_URL "${UPLOAD_URL}:${${varPrefix}_REMOTE_DIR}")
	ENDIF(NOT "${varPrefix}_REMOTE_DIR" STREQUAL "")

	ADD_CUSTOM_TARGET(${_target}
	    COMMAND ${${varPrefix}_UPLOAD_CMD} ${${varPrefix}_UPLOAD_OPTIONS} ${ARGN} ${UPLOAD_URL}
	    DEPENDS ${${varPrefix}_UPLOAD_FILES} ${${varPrefix}_DEPENDS}
	    ${_DEPENDS}
	    COMMENT "${${varPrefix}_HOST_ALIAS} uploading ${fileAlias}."
	    VERBATIM
	    )
    ENDMACRO(MANAGE_UPLOAD_MAKE_TARGET varPrefix fileAlias)

    FUNCTION(MANAGE_UPLOAD_CMD cmd fileAlias)
	FIND_PROGRAM(UPLOAD_CMD "${cmd}")
	IF(UPLOAD_CMD STREQUAL "UPLOAD_CMD-NOTFOUND")
	    M_MSG(${M_OFF} "Program ${cmd} is not found! Upload with ${cmd} disabled.")
	ELSE(UPLOAD_CMD STREQUAL "UPLOAD_CMD-NOTFOUND")
	    _MANAGE_UPLOAD_GET_OPTIONS(varList "upload_${fileAlias}" ${ARGN})
	    SET(upload_UPLOAD_CMD ${UPLOAD_CMD})
	    MANAGE_UPLOAD_MAKE_TAGET("upload" "${fileAlias}")
	ENDIF(UPLOAD_CMD STREQUAL "UPLOAD_CMD-NOTFOUND")
    ENDFUNCTION(MANAGE_UPLOAD_CMD cmd fileAlias)

    FUNCTION(MANAGE_UPLOAD_SFTP fileAlias)
	MANAGE_UPLOAD_CMD(sftp ${fileAlias} ${ARGN})
    ENDFUNCTION(MANAGE_UPLOAD_SFTP fileAlias)

    FUNCTION(MANAGE_UPLOAD_SCP fileAlias)
	MANAGE_UPLOAD_CMD(scp ${fileAlias} ${ARGN})
    ENDFUNCTION(MANAGE_UPLOAD_SCP fileAlias)

    #MACRO(MANAGE_UPLOAD_GOOGLE_UPLOAD)
    #	FIND_PROGRAM(CURL_CMD curl)
    #	IF(CURL_CMD STREQUAL "CURL_CMD-NOTFOUND")
    #	    MESSAGE(FATAL_ERROR "Need curl to perform google upload")
    #	ENDIF(CURL_CMD STREQUAL "CURL_CMD-NOTFOUND")
    #ENDMACRO(MANAGE_UPLOAD_GOOGLE_UPLOAD)
    FUNCTION(MANAGE_UPLOAD_FEDORAHOSTED fileAlias)
	FIND_PROGRAM(fedorahosted_${fileAlias}_UPLOAD_CMD "scp")
	IF(fedorahosted_${fileAlias}_UPLOAD_CMD STREQUAL "fedorahosted_${fileAlias}_UPLOAD_CMD-NOTFOUND")
	    M_MSG(${M_OFF} "Program ${cmd} is not found! Upload with fedorahost disabled.")
	ELSE(fedorahosted_${fileAlias}_UPLOAD_CMD STREQUAL "fedorahosted_${fileAlias}_UPLOAD_CMD-NOTFOUND")
	    _MANAGE_UPLOAD_GET_OPTIONS(varList "fedorahosted_${fileAlias}" HOST_ALIAS "fedorahosted"
		HOST_URL "fedorahosted.org" REMOTE_DIR  "${PROJECT_NAME}" ${ARGN})
	MANAGE_UPLOAD_MAKE_TARGET("fedorahosted_${fileAlias}" "${fileAlias}" ${fedorahosted_${fileAlias}_UPLOAD_FILES})
	ENDIF(fedorahosted_${fileAlias}_UPLOAD_CMD STREQUAL "fedorahosted_${fileAlias}_UPLOAD_CMD-NOTFOUND")
    ENDFUNCTION(MANAGE_UPLOAD_FEDORAHOSTED fileAlias)

    FUNCTION(MANAGE_UPLOAD_SOURCEFORGE_FILE_RELEASE fileAlias)
	FIND_PROGRAM(sourceforge_${fileAlias}_UPLOAD_CMD "sftp")
	IF(sourceforge_${fileAlias}_UPLOAD_CMD STREQUAL "sourceforge_${fileAlias}_UPLOAD_CMD-NOTFOUND")
	    M_MSG(${M_OFF} "Program ${cmd} is not found! Upload with sourceforge disabled.")
	ELSE(sourceforge_${fileAlias}_UPLOAD_CMD STREQUAL "sourceforge_${fileAlias}_UPLOAD_CMD-NOTFOUND")
	    _MANAGE_UPLOAD_GET_OPTIONS(varList "sourceforge_${fileAlias}" ${ARGN} HOST_ALIAS "sourceforge"
	        HOST_URL "frs.sourceforge.net")
	    IF(sourceforge_${fileAlias}_USER)
		SET(sourceforge_${fileAlias}_REMOTE_DIR "/home/frs/project/${PROJECT_NAME}")
	    ENDIF(sourceforge_${fileAlias}_USER)
	    SET("sourceforge_${fileAlias}_UPLOAD_CMD" "sftp")
	MANAGE_UPLOAD_MAKE_TARGET("sourceforge_${fileAlias}" "${fileAlias}")
    ENDIF(sourceforge_${fileAlias}_UPLOAD_CMD STREQUAL "sourceforge_${fileAlias}_UPLOAD_CMD-NOTFOUND")
    ENDFUNCTION(MANAGE_UPLOAD_SOURCEFORGE_FILE_RELEASE fileAlias)
ENDIF(NOT DEFINED _MANAGE_UPLOAD_CMAKE_)

