# - Modules for managing targets and outputs.
#
# Defines following macros:
#   ADD_CUSTOM_TARGET_COMMAND(target OUTPUT file1 [file2 ..] COMMAND
#   command1 ...)
#   - Combine ADD_CUSTOM_TARGET and ADD_CUSTOM_COMMAND.
#     Always build when making the target, also specify the output files
#     Arguments:
#     + target: target for this command
#     + file1, file2 ... : Files to be outputted by this command
#     + command1 ... : Command to be run. The rest arguments are same with
#                      ADD_CUSTOM_TARGET.
#

IF(NOT DEFINED _MANAGE_TARGET_CMAKE_)
    SET(_MANAGE_TARGET_CMAKE_ "DEFINED")
    MACRO(ADD_CUSTOM_TARGET_COMMAND target OUTPUT)
	SET(_outputFileList "")
	SET(_optionList "")
	SET(_outputFileMode 1)
	FOREACH(_t ${ARGN})
	    IF(_outputFileMode)
		IF(_t STREQUAL "COMMAND")
		    SET(_outputFileMode 0)
		    LIST(APPEND _optionList "${_t}")
		ELSE(_t STREQUAL "COMMAND")
		    LIST(APPEND _outputFileList "${_t}")
		ENDIF(_t STREQUAL "COMMAND")
	    ELSE(_outputFileMode)
		LIST(APPEND _optionList "${_t}")
	    ENDIF(_outputFileMode)
	ENDFOREACH(_t ${ARGN})
	#MESSAGE("ADD_CUSTOM_TARGET(${target} ${_optionList})")
	ADD_CUSTOM_TARGET(${target} ${_optionList})
	#MESSAGE("ADD_CUSTOM_COMMAND(OUTPUT ${_outputFileList}  ${_optionList})")
	ADD_CUSTOM_COMMAND(OUTPUT ${_outputFileList}  ${_optionList})
    ENDMACRO(ADD_CUSTOM_TARGET_COMMAND)

ENDIF(NOT DEFINED _MANAGE_TARGET_CMAKE_)

