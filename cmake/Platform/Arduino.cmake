#=============================================================================#
# generate_arduino_firmware()
#=============================================================================#
#
#   generaters firmware and libraries for Arduino devices
#
# The arguments are as follows:
#
#      FIRMWARE       # The name of the firmware target [REQUIRED]
#      BOARD          # Board name (such as uno, mega2560, ...) [REQUIRED]
#      SRCS           # Sources [must have SRCS or SKETCH]
#      SKETCH         # Arduino sketch [must have SRCS or SKETCH]
#      HDRS           # Headers 
#      PORT           # Serial port, for upload and serial targets
#      AFLAGS         # Override global Avrdude flags for target
#      SERIAL         # Serial command for serial target
#      NO_AUTOLIBS    # Disables Arduino library detection
#      DESKTOP_IGNORE # Sources to ignore for Desktop build
#      DESKTOP        # Enables the desktop build
#
# Here is a short example for a target named test:
#    
#       generate_arduino_firmware(
#           FIRMWARE test
#           SRCS test.cpp 
#                test2.cpp
#           HDRS test.h test2.h
#           BOARD uno)
#
#=============================================================================#
# generate_arduino_library()
#=============================================================================#
#   generaters firmware and libraries for Arduino devices
#
# The arguments are as follows:
#
#      NAME           # The name of the firmware target [REQUIRED]
#      BOARD          # Board name (such as uno, mega2560, ...) [REQUIRED]
#      SRCS           # Sources [must have SRCS or SKETCH]
#      HDRS           # Headers 
#      NO_AUTOLIBS    # Disables Arduino library detection
#
# Here is a short example for a target named test:
#    
#       generate_arduino_library(
#           NAME test
#           SRCS test.cpp 
#                test2.cpp
#           HDRS test.h test2.h
#           BOARD uno)
#
#=============================================================================#
# generate_arduino_example(LIBRARY_NAME EXAMPLE_NAME BOARD_ID [PORT] [SERIAL])
#=============================================================================#
#
#        BOARD_ID     - Board ID
#        LIBRARY_NAME - Library name
#        EXAMPLE_NAME - Example name
#        PORT         - Serial port [optional]
#        SERIAL       - Serial command [optional]
# Creates a example from the specified library.
#
#
#=============================================================================#
# print_board_list()
#=============================================================================#
#
# Print list of detected Arduino Boards.
#
#=============================================================================#
# print_programmer_list()
#=============================================================================#
#
# Print list of detected Programmers.
#
#=============================================================================#
# print_programmer_settings(PROGRAMMER)
#=============================================================================#
#
#        PROGRAMMER - programmer id
#
# Print the detected Programmer settings.
#
#=============================================================================#
# print_board_settings(ARDUINO_BOARD)
#=============================================================================#
#
#        ARDUINO_BOARD - Board id
#
# Print the detected Arduino board settings.

include(CMakeParseArguments)

#=============================================================================#
#                           User Functions                                    
#=============================================================================#

#=============================================================================#
# [PUBLIC/USER]
#
# print_board_list()
#
# see documentation at top
#=============================================================================#
function(PRINT_BOARD_LIST)
    message(STATUS "Arduino Boards:")
    print_list(ARDUINO_BOARDS)
    message(STATUS "")
endfunction()

#=============================================================================#
# [PUBLIC/USER]
#
# print_programmer_list()
#
# see documentation at top
#=============================================================================#
function(PRINT_PROGRAMMER_LIST)
    message(STATUS "Arduino Programmers:")
    print_list(ARDUINO_PROGRAMMERS)
    message(STATUS "")
endfunction()

#=============================================================================#
# [PUBLIC/USER]
#
# print_programmer_settings(PROGRAMMER)
#
# see documentation at top
#=============================================================================#
function(PRINT_PROGRAMMER_SETTINGS PROGRAMMER)
    if(${PROGRAMMER}.SETTINGS)
        message(STATUS "Programmer ${PROGRAMMER} Settings:")
        print_settings(${PROGRAMMER})
    endif()
endfunction()

# [PUBLIC/USER]
#
# print_board_settings(ARDUINO_BOARD)
#
# see documentation at top
function(PRINT_BOARD_SETTINGS ARDUINO_BOARD)
    if(${ARDUINO_BOARD}.SETTINGS)
        message(STATUS "Arduino ${ARDUINO_BOARD} Board:")
        print_settings(${ARDUINO_BOARD})
    endif()
endfunction()

#=============================================================================#
# [PUBLIC/USER]
#
# generate_arduino_library()
#
# see documentation at top
#=============================================================================#
function(GENERATE_ARDUINO_LIBRARY)

    cmake_parse_arguments(INPUT "NO_AUTOLIBS" "NAME;BOARD" "SRCS;HDRS;LIBS" ${ARGN})
    error_for_unparsed(INPUT)
    required_variables(VARS INPUT_NAME MSG "must define name for library")
    arduino_debug_msg("Generating ${INPUT_NAME}")
    required_variables(VARS SRCS INPUT_BOARD MSG "must define for target ${INPUT_NAME}")

    arduino_debug_msg("Generating ${TARGET_NAME}")
    
    set(ALL_LIBS)
    set(ALL_SRCS ${INPUT_SRCS} ${INPUT_HDRS})

    setup_arduino_core(
        LIBRARY CORE_LIB
        BOARD ${INPUT_BOARD})

    find_arduino_libraries(
        LIBS TARGET_LIBS
        SRCS "${ALL_SRCS}")
    set(LIB_COMPILE_FLAGS)
    foreach(LIB_DEP ${TARGET_LIBS})
        set(LIB_COMPILE_FLAGS "${LIB_COMPILE_FLAGS} -I${LIB_DEP}")
    endforeach()

    if(NOT INPUT_NO_AUTOLIBS)
        setup_arduino_libraries(
            LIBRARIES ALL_LIBS
            BOARD ${INPUT_BOARD}
            SRCS "${ALL_SRCS}"
            COMPILE_FLAGS "${LIB_COMPILE_FLAGS}")
    endif()

    list(APPEND ALL_LIBS ${CORE_LIB} ${INPUT_LIBS})
        
    add_library(${TARGET_NAME} ${ALL_SRCS})
    target_link_libraries(${TARGET_NAME} ${ALL_LIBS} "-lc -lm")
endfunction()

#=============================================================================#
# [PUBLIC/USER]
# see documentation at top
#=============================================================================#
function(GENERATE_ARDUINO_FIRMWARE)

    cmake_parse_arguments(INPUT "NO_AUTOLIBS;DESKTOP" "FIRMWARE;BOARD;PORT;SKETCH;SERIAL" "SRCS;DESKTOP_COMPILE_FLAGS;DESKTOP_SRCS;HDRS;LIBS;AFLAGS;DESKTOP_IGNORE" ${ARGN})
    error_for_unparsed(INPUT)
    required_variables(VARS INPUT_FIRMWARE MSG "must define name for target")
    message(STATUS "Generating ${INPUT_FIRMWARE}")
    required_variables(VARS INPUT_BOARD MSG "must define for target ${INPUT_FIRMWARE}")

    if ( (NOT INPUT_DESKTOP) AND ARDUINO_DESKTOP)
        return()
    endif()

    set(ALL_LIBS)
    set(ALL_SRCS ${INPUT_SRCS} ${INPUT_HDRS})

    setup_arduino_core(
        LIBRARY CORE_LIB
        BOARD ${INPUT_BOARD})


    if (ARDUINO_DESKTOP)
        list(APPEND ALL_SRCS ${INPUT_DESKTOP_SRCS}) 
    endif()

    if(NOT "${INPUT_SKETCH}" STREQUAL "")
        setup_arduino_sketch(
            SKETCH "${INPUT_SKETCH}"
            SRCS ALL_SRCS
            DESKTOP_IGNORE "${INPUT_DESKTOP_IGNORE}")
    endif()

    required_variables(VARS ALL_SRCS MSG "must define SRCS or SKETCH for target ${INPUT_FIRMWARE}")

    find_arduino_libraries(
        LIBS TARGET_LIBS
        SRCS "${ALL_SRCS}")

    set(LIB_COMPILE_FLAGS)
    foreach(LIB_DEP ${TARGET_LIBS})
        set(LIB_COMPILE_FLAGS "${LIB_COMPILE_FLAGS} -I${LIB_DEP}")
    endforeach()

    if (ARDUINO_DESKTOP)
        set(LIB_COMPILE_FLAGS "${LIB_COMPILE_FLAGS} ${INPUT_DESKTOP_COMPILE_FLAGS}") 
    endif()

    if(NOT INPUT_NO_AUTOLIBS)
        setup_arduino_libraries(
            LIBRARIES ALL_LIBS
            BOARD "${INPUT_BOARD}"
            SRCS "${ALL_SRCS}"
            COMPILE_FLAGS "${LIB_COMPILE_FLAGS}")
    endif()
    
    list(APPEND ALL_LIBS ${CORE_LIB} ${INPUT_LIBS})
    
    setup_arduino_target(
        TARGET "${INPUT_FIRMWARE}"
        BOARD "${INPUT_BOARD}"
        SRCS "${ALL_SRCS}"
        LIBS "${ALL_LIBS}"
        COMPILE_FLAGS "-I${INPUT_SKETCH} ${LIB_COMPILE_FLAGS}")
    
    if(INPUT_PORT)
        setup_arduino_upload(${INPUT_BOARD} ${INPUT_FIRMWARE} ${INPUT_PORT})
    endif()
    
    if(INPUT_SERIAL)
        setup_serial_target(${INPUT_FIRMWARE} "${INPUT_SERIAL}")
    endif()

endfunction()

#=============================================================================#
# [PUBLIC/USER]
#
# generate_arduino_example()
#
# see documentation at top
#=============================================================================#
function(GENERATE_ARDUINO_EXAMPLE)

    cmake_parse_arguments(INPUT "DESKTOP" "LIBRARY;EXAMPLE;BOARD;PORT;SERIAL" "" ${ARGN})
    error_for_unparsed(INPUT)
    required_variables(VARS INPUT_EXAMPLE MSG "must define name for example")
    required_variables(VARS INPUT_BOARD INPUT_LIBRARY MSG "must define for example ${INPUT_EXAMPLE}")

    if ( (NOT INPUT_DESKTOP) AND ARDUINO_DESKTOP)
        return()
    endif()

    set(TARGET_NAME "example-${INPUT_LIBRARY}-${INPUT_EXAMPLE}")

    message(STATUS "Generating ${TARGET_NAME}")

    set(ALL_LIBS)
    set(ALL_SRCS)

    setup_arduino_core(
        LIBRARY CORE_LIB
        BOARD "${INPUT_BOARD}")

    setup_arduino_example("${INPUT_LIBRARY}" "${INPUT_EXAMPLE}" ALL_SRCS)

    if(NOT ALL_SRCS)
        message(FATAL_ERROR "Missing sources for example, aborting!")
    endif()

    find_arduino_libraries(
        LIBS TARGET_LIBS
        SRCS "${ALL_SRCS}")

    set(LIB_COMPILE_FLAGS)
    foreach(LIB_DEP ${TARGET_LIBS})
        set(LIB_COMPILE_FLAGS "${LIB_COMPILE_FLAGS} -I${LIB_DEP}")
    endforeach()

    setup_arduino_libraries(
            LIBRARIES ALL_LIBS
            BOARD "${INPUT_BOARD}"
            SRCS "${ALL_SRCS}"
            COMPILE_FLAGS "${LIB_COMPILE_FLAGS}")

    list(APPEND ALL_LIBS ${CORE_LIB} ${INPUT_LIBS})
    
    setup_arduino_target(
        TARGET "${TARGET_NAME}"
        BOARD "${INPUT_BOARD}"
        SRCS "${ALL_SRCS}"
        LIBS "${ALL_LIBS}"
        COMPILE_FLAGS "${LIB_COMPILE_FLAGS}")

    if(INPUT_PORT)
        setup_arduino_upload(${INPUT_BOARD} ${TARGET_NAME} ${INPUT_PORT})
    endif()
    
    if(INPUT_SERIAL)
        setup_serial_target(${TARGET_NAME} "${INPUT_SERIAL}")
    endif()
endfunction()

#=============================================================================#
#                        Internal Functions                                   
#=============================================================================#

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# load_board_settings()
#
# Load the Arduino SDK board settings from the boards.txt file.
#
#=============================================================================#
function(LOAD_BOARD_SETTINGS)
    load_arduino_style_settings(ARDUINO_BOARDS "${ARDUINO_BOARDS_PATH}")
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
#=============================================================================#
function(LOAD_PROGRAMMERS_SETTINGS)
    load_arduino_style_settings(ARDUINO_PROGRAMMERS "${ARDUINO_PROGRAMMERS_PATH}")
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# get_arduino_flags(COMPILE_FLAGS LINK_FLAGS BOARD_ID)
#
#       COMPILE_FLAGS_VAR -Variable holding compiler flags
#       LINK_FLAGS_VAR - Variable holding linker flags
#       BOARD_ID - The board id name
#
# Configures the the build settings for the specified Arduino Board.
#
#=============================================================================#
function(get_arduino_flags COMPILE_FLAGS_VAR LINK_FLAGS_VAR BOARD_ID)
    set(BOARD_CORE ${${BOARD_ID}.build.core})
    if(BOARD_CORE)
        if(ARDUINO_SDK_VERSION MATCHES "([0-9]+)[.]([0-9]+)")
            string(REPLACE "." "" ARDUINO_VERSION_DEFINE "${ARDUINO_SDK_VERSION}") # Normalize version (remove all periods)
            set(ARDUINO_VERSION_DEFINE "")
            if(CMAKE_MATCH_1 GREATER 0)
                set(ARDUINO_VERSION_DEFINE "${CMAKE_MATCH_1}")
            endif()
            if(CMAKE_MATCH_2 GREATER 10)
                set(ARDUINO_VERSION_DEFINE "${ARDUINO_VERSION_DEFINE}${CMAKE_MATCH_2}")
            else()
                set(ARDUINO_VERSION_DEFINE "${ARDUINO_VERSION_DEFINE}0${CMAKE_MATCH_2}")
            endif()
        else()
            message("Invalid Arduino SDK Version (${ARDUINO_SDK_VERSION})")
        endif()

        # output
        set(COMPILE_FLAGS " ${ARDUINO_TOOLCHAIN_COMPILE_FLAGS} -DARDUINO=${ARDUINO_VERSION_DEFINE} -I${ARDUINO_CORES_PATH}/${BOARD_CORE} -I${ARDUINO_LIBRARIES_PATH}")
        set(LINK_FLAGS "")

        if (NOT ARDUINO_DESKTOP)
            set(COMPILE_FLAGS "${COMPILE_FLAGS} -mmcu=${${BOARD_ID}.build.mcu} -DF_CPU=${${BOARD_ID}.build.f_cpu}")
            set(LINK_FLAGS "${LINK_FLAGS} -mmcu=${${BOARD_ID}.build.mcu}")
        endif()

        if(ARDUINO_SDK_VERSION VERSION_GREATER 1.0 OR ARDUINO_SDK_VERSION VERSION_EQUAL 1.0)
            set(PIN_HEADER ${${BOARD_ID}.build.variant})
            set(COMPILE_FLAGS "${COMPILE_FLAGS} -I${ARDUINO_VARIANTS_PATH}/${PIN_HEADER}")
        endif()

        # output 
        set(${COMPILE_FLAGS_VAR} "${COMPILE_FLAGS}" PARENT_SCOPE)
        set(${LINK_FLAGS_VAR} "${LINK_FLAGS}" PARENT_SCOPE)

    else()
        message(FATAL_ERROR "Invalid Arduino board ID (${BOARD_ID}), aborting.")
    endif()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_core()
#
#        LIBRARY    -  Variable name that will hold the generated library name
#        BOARD_ID    - Arduino board id
#
# Creates the Arduino Core library for the specified board,
# each board gets it's own version of the library.
#
#=============================================================================#
function(setup_arduino_core)

    cmake_parse_arguments(INPUT "" "LIBRARY;BOARD" "" ${ARGN})
    error_for_unparsed(INPUT)
    required_variables(VARS INPUT_BOARD MSG "must define for library ${INPUT_LIB_PATH}") 

    set(CORE_LIB_NAME ${INPUT_BOARD}_CORE)
    set(BOARD_CORE ${${INPUT_BOARD}.build.core})
    if(BOARD_CORE AND NOT TARGET ${CORE_LIB_NAME})
        set(BOARD_CORE_PATH ${ARDUINO_CORES_PATH}/${BOARD_CORE})
        if (NOT ARDUINO_DESKTOP)
            setup_arduino_library(
                LIBRARIES CORE_LIB_NAME 
                BOARD "${INPUT_BOARD}"
                LIB_PATH "${BOARD_CORE_PATH}"
                COMPILE_FLAGS "${ARDUINO_COMPILE_FLAGS}"
                LINK_FLAGS "${ARDUINO_LINK_FLAGS}"
                IGNORE_SRCS "${BOARD_CORE_PATH}/main.cxx" # Debian/Ubuntu fix
                IS_CORE
                )
            set(${INPUT_LIBRARY} ${CORE_LIB_NAME} PARENT_SCOPE)
        endif()
    endif()

endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# find_arduino_libraries()
#
#      LIBS         - Variable name which will hold the results
#      SRCS         - Sources that will be analyzed
#
#     returns a list of paths to libraries found.
#
#  Finds all Arduino type libraries included in sources. Available libraries
#  are ${ARDUINO_SDK_PATH}/libraries and ${CMAKE_CURRENT_SOURCE_DIR}.
#
#  A Arduino library is a folder that has the same name as the include header.
#  For example, if we have a include "#include <LibraryName.h>" then the following
#  directory structure is considered a Arduino library:
#
#     LibraryName/
#          |- LibraryName.h
#          `- LibraryName.c
#
#  If such a directory is found then all sources within that directory are considred
#  to be part of that Arduino library.
#
#=============================================================================#
function(find_arduino_libraries)

    cmake_parse_arguments(INPUT "" "LIBS" "SRCS" ${ARGN})
    error_for_unparsed(INPUT)
    required_variables(VARS INPUT_LIBS INPUT_SRCS MSG "must define") 

    set(ARDUINO_LIBS )

    get_property(LIBRARY_SEARCH_PATH
        DIRECTORY     # Property Scope
        PROPERTY LINK_DIRECTORIES)

    set(LIB_SEARCH_PATHS
        ${LIBRARY_SEARCH_PATH}
        ${ARDUINO_LIBRARIES_PATH}
        ${CMAKE_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/libraries
        ${ARDUINO_EXTRA_LIBRARIES_PATH})

    set(INCLUDE_REGEX "[#]include *[<\"]([^\n]+)[>\"]")

    foreach(SRC ${INPUT_SRCS})
        #message(STATUS "src: ${SRC}")
        file(READ "${SRC}" SRC_CONTENTS)
        string(REGEX MATCHALL "${INCLUDE_REGEX}" INCLUDE_STRINGS "${SRC_CONTENTS}")
        foreach(INCLUDE_STRING ${INCLUDE_STRINGS})
            string(REGEX REPLACE "${INCLUDE_REGEX}" "\\1" INCLUDE_FILE "${INCLUDE_STRING}")
            get_filename_component(INCLUDE_NAME "${INCLUDE_FILE}" NAME_WE)
            #message(STATUS "include string: ${INCLUDE_STRING}")
            #message(STATUS "include file: ${INCLUDE_FILE}")
            #message(STATUS "include name: ${INCLUDE_NAME}")
            foreach(LIB_SEARCH_PATH ${LIB_SEARCH_PATHS})
                if(EXISTS ${LIB_SEARCH_PATH}/${INCLUDE_NAME}/${INCLUDE_FILE})
                    list(APPEND ARDUINO_LIBS ${LIB_SEARCH_PATH}/${INCLUDE_NAME})
                    break()
                endif()
            endforeach()
        endforeach()
    endforeach()

    if(ARDUINO_LIBS)
        list(REMOVE_DUPLICATES ARDUINO_LIBS)
    endif()

    set(${INPUT_LIBS} ${ARDUINO_LIBS} PARENT_SCOPE)

endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_library()
#
#        LIBRARIES      - Vairable wich will hold the generated library names
#        BOARD          - Board name
#        LIB_PATH       - path of the library
#        COMPILE_FLAGS  - compile flags
#        LINK_FLAGS     - link flags
#        IGNORE_SRCS    - sources to ignore
#        IS_CORE        - is this the core library
#
# Creates an Arduino library, with all it's library dependencies.
#
#      ${LIB_NAME}_RECURSE controls if the library will recurse
#      when looking for source files.
#
#=============================================================================#

function(setup_arduino_library)

    cmake_parse_arguments(INPUT "IS_CORE" "LIBRARIES;BOARD;LIB_PATH"
        "COMPILE_FLAGS;LINK_FLAGS;IGNORE_SRCS" ${ARGN})
    error_for_unparsed(INPUT)
    required_variables(VARS INPUT_LIB_PATH MSG "must define name for library") 
    required_variables(VARS INPUT_BOARD MSG "must define for library ${INPUT_LIB_PATH}") 

    # For known libraries can list recurse here
    set(Wire_RECURSE True)
    set(Ethernet_RECURSE True)
    set(SD_RECURSE True)
    set(Desktop True)

    set(LIB_TARGETS)

    if (NOT INPUT_IS_CORE AND NOT ARDUINO_DESKTOP)
        set(LIB_TARGETS "${INPUT_BOARD}_CORE")
    endif()

    get_filename_component(LIB_NAME ${INPUT_LIB_PATH} NAME)

    if (INPUT_IS_CORE)
        set(TARGET_LIB_NAME "${INPUT_BOARD}_CORE")
    else()
        set(TARGET_LIB_NAME "${INPUT_BOARD}_${LIB_NAME}")
    endif()

    if(NOT TARGET ${TARGET_LIB_NAME})

        # Detect if recursion is needed
        if (NOT DEFINED ${LIB_NAME}_RECURSE)
            set(${LIB_NAME}_RECURSE False)
        endif()

        if (${${LIB_NAME}_RECURSE})
            set(LIB_RECURSE "RECURSE")
        else()
            set(LIB_RECURSE "")
        endif()

        find_sources(
            SRCS LIB_SRCS
            PATH "${INPUT_LIB_PATH}"
            IGNORE "${INPUT_IGNORE_SRCS}"
            ${LIB_RECURSE})

        if(LIB_SRCS)

            arduino_debug_msg("Generating ${TARGET_LIB_NAME} library")

            add_library(${TARGET_LIB_NAME} STATIC ${LIB_SRCS})

            get_arduino_flags(ARDUINO_COMPILE_FLAGS ARDUINO_LINK_FLAGS ${INPUT_BOARD})

            find_arduino_libraries(
                LIBS LIB_DEPS
                SRCS "${LIB_SRCS}")

            foreach(LIB_DEP ${LIB_DEPS})
                setup_arduino_library(
                    LIBRARIES DEP_LIB_SRCS
                    BOARD ${INPUT_BOARD}
                    LIB_PATH ${LIB_DEP}
                    COMPILE_FLAGS "${INPUT_COMPILE_FLAGS}"
                    LINK_FLAGS "${INPUT_LINK_FLAGS}")
                list(APPEND LIB_TARGETS ${DEP_LIB_SRCS})
            endforeach()

            set_target_properties(${TARGET_LIB_NAME} PROPERTIES
                COMPILE_FLAGS "${ARDUINO_COMPILE_FLAGS} -I${INPUT_LIB_PATH} -I${INPUT_LIB_PATH}/utility ${INPUT_COMPILE_FLAGS}"
                LINK_FLAGS "${ARDUINO_LINK_FLAGS} ${INPUT_LINK_FLAGS}")

            target_link_libraries(${TARGET_LIB_NAME} ${LIB_TARGETS})
            list(APPEND LIB_TARGETS ${TARGET_LIB_NAME})

        endif()
    else()
        # Target already exists, skiping creating
        list(APPEND LIB_TARGETS ${TARGET_LIB_NAME})
    endif()
    if(LIB_TARGETS)
        list(REMOVE_DUPLICATES LIB_TARGETS)
    endif()
    set(${INPUT_LIBRARIES} ${LIB_TARGETS} PARENT_SCOPE)
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_libraries()
#
#        LIBRARIES      - Vairable wich will hold the generated library names
#        BOARD          - Board ID
#        SRCS           - source files
#        COMPILE_FLAGS  - Compile flags
#        LINK_FLAGS     - Linker flags
#
# Finds and creates all dependency libraries based on sources.
#
#=============================================================================#
function(setup_arduino_libraries)

    cmake_parse_arguments(INPUT "" "LIBRARIES;BOARD" "SRCS;COMPILE_FLAGS;LINK_FLAGS" ${ARGN})
    error_for_unparsed(INPUT)
    required_variables(VARS INPUT_BOARD INPUT_SRCS MSG "must define") 

    set(LIB_TARGETS)
    find_arduino_libraries(
        LIBS TARGET_LIBS
        SRCS "${INPUT_SRCS}")
    foreach(TARGET_LIB ${TARGET_LIBS})
        # Create static library instead of returning sources
        setup_arduino_library(
            LIBRARIES LIB_DEPS
            BOARD ${INPUT_BOARD}
            LIB_PATH ${TARGET_LIB}
            COMPILE_FLAGS "${INPUT_COMPILE_FLAGS}"
            LINK_FLAGS "${INPUT_LINK_FLAGS}")
        list(APPEND LIB_TARGETS ${LIB_DEPS})
    endforeach()

    set(${INPUT_LIBRARIES} ${LIB_TARGETS} PARENT_SCOPE)
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_target()
#
#        TARGET_NAME - Target name
#        BOARD - The arduino board
#        SRCS    - All sources
#        LIBS    - All libraries
#        COMPILE_FLAGS    - Compile flags
#        LINK_FLAGS    - Linker flags
#
# Creates an Arduino firmware target.
#
#=============================================================================#
function(setup_arduino_target)

    cmake_parse_arguments(INPUT "" "TARGET;BOARD" "SRCS;LIBS;COMPILE_FLAGS;LINK_FLAGS" ${ARGN})
    error_for_unparsed(INPUT)
    required_variables(VARS INPUT_TARGET INPUT_BOARD INPUT_SRCS MSG "must define name for library")

    set(LIB_COMPILE_FLAGS "")
    foreach(LIB_DEP ${INPUT_LIBS})
        set(LIB_COMPILE_FLAGS "${LIB_COMPILE_FLAGS} -I${LIB_DEP}")
    endforeach()

    add_executable(${INPUT_TARGET} ${INPUT_SRCS})
    set_target_properties(${INPUT_TARGET} PROPERTIES SUFFIX ".elf")

    get_arduino_flags(ARDUINO_COMPILE_FLAGS ARDUINO_LINK_FLAGS  ${INPUT_BOARD})

    set_target_properties(${INPUT_TARGET} PROPERTIES
                COMPILE_FLAGS "${ARDUINO_COMPILE_FLAGS} ${INPUT_COMPILE_FLAGS} ${LIB_COMPILE_FLAGS}"
                LINK_FLAGS "${ARDUINO_LINK_FLAGS} ${INPUT_LINK_FLAGS}")
    target_link_libraries(${INPUT_TARGET} ${INPUT_LIBS} "-lc -lm")

    set(TARGET_PATH ${CMAKE_CURRENT_BINARY_DIR}/${INPUT_TARGET})
    add_custom_command(TARGET ${INPUT_TARGET} POST_BUILD
                        COMMAND ${CMAKE_OBJCOPY}
                        ARGS     ${ARDUINO_OBJCOPY_EEP_FLAGS}
                                 ${TARGET_PATH}.elf
                                 ${TARGET_PATH}.eep
                        COMMENT "Generating EEP image"
                        VERBATIM)

    # Convert firmware image to ASCII HEX format
    add_custom_command(TARGET ${INPUT_TARGET} POST_BUILD
                        COMMAND ${CMAKE_OBJCOPY}
                        ARGS    ${ARDUINO_OBJCOPY_HEX_FLAGS}
                                ${TARGET_PATH}.elf
                                ${TARGET_PATH}.hex
                        COMMENT "Generating HEX image"
                        VERBATIM)

    # Display target size
    add_custom_command(TARGET ${INPUT_TARGET} POST_BUILD
                        COMMAND ${CMAKE_COMMAND}
                        ARGS    -DFIRMWARE_IMAGE=${TARGET_PATH}.hex
                                -P ${ARDUINO_SIZE_SCRIPT}
                        COMMENT "Calculating image size"
                        VERBATIM)

    # Create ${INPUT_TARGET}-size target
    add_custom_target(${INPUT_TARGET}-size
                        COMMAND ${CMAKE_COMMAND}
                                -DFIRMWARE_IMAGE=${TARGET_PATH}.hex
                                -P ${ARDUINO_SIZE_SCRIPT}
                        DEPENDS ${INPUT_TARGET}
                        COMMENT "Calculating ${INPUT_TARGET} image size")
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_upload(BOARD_ID TARGET_NAME PORT)
#
#        BOARD_ID    - Arduino board id
#        TARGET_NAME - Target name
#        PORT        - Serial port for upload
#
# Create an upload target (${TARGET_NAME}-upload) for the specified Arduino target.
#
#=============================================================================#
function(setup_arduino_upload BOARD_ID TARGET_NAME PORT)
# setup_arduino_bootloader_upload()
    setup_arduino_bootloader_upload(${TARGET_NAME} ${BOARD_ID} ${PORT})

    # Add programmer support if defined
    if(${TARGET_NAME}_PROGRAMMER AND ${${TARGET_NAME}_PROGRAMMER}.protocol)
        setup_arduino_programmer_burn(${TARGET_NAME} ${BOARD_ID} ${${TARGET_NAME}_PROGRAMMER} ${PORT})
        setup_arduino_bootloader_burn(${TARGET_NAME} ${BOARD_ID} ${${TARGET_NAME}_PROGRAMMER} ${PORT})
    endif()
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_bootloader_upload(TARGET_NAME BOARD_ID PORT)
#
#      TARGET_NAME - target name
#      BOARD_ID    - board id
#      PORT        - serial port
#
# Set up target for upload firmware via the bootloader.
#
# The target for uploading the firmware is ${TARGET_NAME}-upload .
#
#=============================================================================#
function(setup_arduino_bootloader_upload TARGET_NAME BOARD_ID PORT)
    set(UPLOAD_TARGET ${TARGET_NAME}-upload)
    set(AVRDUDE_ARGS)

    setup_arduino_bootloader_args(${BOARD_ID} ${TARGET_NAME} ${PORT} AVRDUDE_ARGS)

    if(NOT AVRDUDE_ARGS)
        message("Could not generate default avrdude bootloader args, aborting!")
        return()
    endif()

    list(APPEND AVRDUDE_ARGS "-Uflash:w:${TARGET_NAME}.hex")
    add_custom_target(${UPLOAD_TARGET}
                     ${ARDUINO_AVRDUDE_PROGRAM} 
                        ${AVRDUDE_ARGS}
                     DEPENDS ${TARGET_NAME})
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_programmer_burn(TARGET_NAME BOARD_ID PROGRAMMER)
#
#      TARGET_NAME - name of target to burn
#      BOARD_ID    - board id
#      PROGRAMMER  - programmer id
# 
# Sets up target for burning firmware via a programmer.
#
# The target for burning the firmware is ${TARGET_NAME}-burn .
#
#=============================================================================#
function(setup_arduino_programmer_burn TARGET_NAME BOARD_ID PROGRAMMER)
    set(PROGRAMMER_TARGET ${TARGET_NAME}-burn)

    set(AVRDUDE_ARGS)

    setup_arduino_programmer_args(${BOARD_ID} ${PROGRAMMER} ${TARGET_NAME} ${PORT} AVRDUDE_ARGS)

    if(NOT AVRDUDE_ARGS)
        message("Could not generate default avrdude programmer args, aborting!")
        return()
    endif()

    list(APPEND AVRDUDE_ARGS "-Uflash:w:${TARGET_NAME}.hex")

    add_custom_target(${PROGRAMMER_TARGET}
                     ${ARDUINO_AVRDUDE_PROGRAM} 
                        ${AVRDUDE_ARGS}
                     DEPENDS ${TARGET_NAME})
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_bootloader_burn(TARGET_NAME BOARD_ID PROGRAMMER)
# 
#      TARGET_NAME - name of target to burn
#      BOARD_ID    - board id
#      PROGRAMMER  - programmer id
#
# Create a target for burning a bootloader via a programmer.
#
# The target for burning the bootloader is ${TARGET_NAME}-burn-bootloader
#
#=============================================================================#
function(setup_arduino_bootloader_burn TARGET_NAME BOARD_ID PROGRAMMER PORT)
    set(BOOTLOADER_TARGET ${TARGET_NAME}-burn-bootloader)

    set(AVRDUDE_ARGS)

    setup_arduino_programmer_args(${BOARD_ID} ${PROGRAMMER} ${TARGET_NAME} ${PORT} AVRDUDE_ARGS)

    if(NOT AVRDUDE_ARGS)
        message("Could not generate default avrdude programmer args, aborting!")
        return()
    endif()

    foreach( ITEM unlock_bits high_fuses low_fuses path file)
        if(NOT ${BOARD_ID}.bootloader.${ITEM})
            message("Missing ${BOARD_ID}.bootloader.${ITEM}, not creating bootloader burn target ${BOOTLOADER_TARGET}.")
            return()
        endif()
    endforeach()

    if(NOT EXISTS "${ARDUINO_BOOTLOADERS_PATH}/${${BOARD_ID}.bootloader.path}/${${BOARD_ID}.bootloader.file}")
        message("${ARDUINO_BOOTLOADERS_PATH}/${${BOARD_ID}.bootloader.path}/${${BOARD_ID}.bootloader.file}")
        message("Missing bootloader image, not creating bootloader burn target ${BOOTLOADER_TARGET}.")
        return()
    endif()

    # Erase the chip
    list(APPEND AVRDUDE_ARGS "-e")

    # Set unlock bits and fuses (because chip is going to be erased)
    list(APPEND AVRDUDE_ARGS "-Ulock:w:${${BOARD_ID}.bootloader.unlock_bits}:m")
    if(${BOARD_ID}.bootloader.extended_fuses)
        list(APPEND AVRDUDE_ARGS "-Uefuse:w:${${BOARD_ID}.bootloader.extended_fuses}:m")
    endif()
    list(APPEND AVRDUDE_ARGS
        "-Uhfuse:w:${${BOARD_ID}.bootloader.high_fuses}:m"
        "-Ulfuse:w:${${BOARD_ID}.bootloader.low_fuses}:m")

    # Set bootloader image
    list(APPEND AVRDUDE_ARGS "-Uflash:w:${${BOARD_ID}.bootloader.file}:i")

    # Set lockbits
    list(APPEND AVRDUDE_ARGS "-Ulock:w:${${BOARD_ID}.bootloader.lock_bits}:m")

    # Create burn bootloader target
    add_custom_target(${BOOTLOADER_TARGET}
                     ${ARDUINO_AVRDUDE_PROGRAM} 
                        ${AVRDUDE_ARGS}
                     WORKING_DIRECTORY ${ARDUINO_BOOTLOADERS_PATH}/${${BOARD_ID}.bootloader.path}
                     DEPENDS ${TARGET_NAME})
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_programmer_args(PROGRAMMER OUTPUT_VAR)
#
#      PROGRAMMER  - programmer id
#      TARGET_NAME - target name
#      OUTPUT_VAR  - name of output variable for result
#
# Sets up default avrdude settings for burning firmware via a programmer.
#=============================================================================#
function(setup_arduino_programmer_args BOARD_ID PROGRAMMER TARGET_NAME PORT OUTPUT_VAR)
    set(AVRDUDE_ARGS ${${OUTPUT_VAR}})

    set(AVRDUDE_FLAGS ${ARDUINO_AVRDUDE_FLAGS})
    if(DEFINED ${TARGET_NAME}_AFLAGS)
        set(AVRDUDE_FLAGS ${${TARGET_NAME}_AFLAGS})
    endif()

    list(APPEND AVRDUDE_ARGS "-C${ARDUINO_AVRDUDE_CONFIG_PATH}")

    #TODO: Check mandatory settings before continuing
    if(NOT ${PROGRAMMER}.protocol)
        message(FATAL_ERROR "Missing ${PROGRAMMER}.protocol, aborting!")
    endif()

    list(APPEND AVRDUDE_ARGS "-c${${PROGRAMMER}.protocol}") # Set programmer

    if(${PROGRAMMER}.communication STREQUAL "usb")
        list(APPEND AVRDUDE_ARGS "-Pusb") # Set USB as port
    elseif(${PROGRAMMER}.communication STREQUAL "serial")
        list(APPEND AVRDUDE_ARGS "-P${PORT}") # Set port
        if(${PROGRAMMER}.speed)
            list(APPEND AVRDUDE_ARGS "-b${${PROGRAMMER}.speed}") # Set baud rate
        endif()
    endif()

    if(${PROGRAMMER}.force)
        list(APPEND AVRDUDE_ARGS "-F") # Set force
    endif()

    if(${PROGRAMMER}.delay)
        list(APPEND AVRDUDE_ARGS "-i${${PROGRAMMER}.delay}") # Set delay
    endif()

    list(APPEND AVRDUDE_ARGS "-p${${BOARD_ID}.build.mcu}")  # MCU Type

    list(APPEND AVRDUDE_ARGS ${AVRDUDE_FLAGS})

    set(${OUTPUT_VAR} ${AVRDUDE_ARGS} PARENT_SCOPE)
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_bootloader_args(BOARD_ID TARGET_NAME PORT OUTPUT_VAR)
#
#      BOARD_ID    - board id
#      TARGET_NAME - target name
#      PORT        - serial port
#      OUTPUT_VAR  - name of output variable for result
#
# Sets up default avrdude settings for uploading firmware via the bootloader.
#=============================================================================#
function(setup_arduino_bootloader_args BOARD_ID TARGET_NAME PORT OUTPUT_VAR)
    set(AVRDUDE_ARGS ${${OUTPUT_VAR}})

    set(AVRDUDE_FLAGS ${ARDUINO_AVRDUDE_FLAGS})
    if(DEFINED ${TARGET_NAME}_AFLAGS)
        set(AVRDUDE_FLAGS ${${TARGET_NAME}_AFLAGS})
    endif()

    list(APPEND AVRDUDE_ARGS
        "-C${ARDUINO_AVRDUDE_CONFIG_PATH}"  # avrdude config
        "-p${${BOARD_ID}.build.mcu}"        # MCU Type
        )

    # Programmer
    if(${BOARD_ID}.upload.protocol STREQUAL "stk500")
        list(APPEND AVRDUDE_ARGS "-cstk500v1")
    else()
        list(APPEND AVRDUDE_ARGS "-c${${BOARD_ID}.upload.protocol}")
    endif()

    list(APPEND AVRDUDE_ARGS
        "-b${${BOARD_ID}.upload.speed}"     # Baud rate
        "-P${PORT}"                         # Serial port
        "-D"                                # Dont erase
        )  

    list(APPEND AVRDUDE_ARGS ${AVRDUDE_FLAGS})

    set(${OUTPUT_VAR} ${AVRDUDE_ARGS} PARENT_SCOPE)
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# find_sources()
#
#        SRCS       - Variable name that will hold the detected sources
#        PATH       - The base path
#        IGNORE     - Files to ignore
#        RECURSE    - Whether or not to recurse
#
# Finds all C/C++ sources located at the specified path.
#
#=============================================================================#
function(find_sources)

    cmake_parse_arguments(INPUT "RECURSE" "SRCS;PATH" "IGNORE" ${ARGN})
    error_for_unparsed(INPUT)
    required_variables(VARS INPUT_PATH MSG "must define search path")

    set(FILE_SEARCH_LIST
        ${INPUT_PATH}/*.cpp
        ${INPUT_PATH}/*.c
        ${INPUT_PATH}/*.cc
        ${INPUT_PATH}/*.cxx
        ${INPUT_PATH}/*.h
        ${INPUT_PATH}/*.hh
        ${INPUT_PATH}/*.hxx)

    if( ${INPUT_RECURSE} )
        file(GLOB_RECURSE LIB_FILES ${FILE_SEARCH_LIST})
    else()
        file(GLOB LIB_FILES ${FILE_SEARCH_LIST})
    endif()

    if(LIB_FILES)
        set(${INPUT_SRCS} ${LIB_FILES} PARENT_SCOPE)
    endif()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_serial_target(TARGET_NAME CMD)
#
#         TARGET_NAME - Target name
#         CMD         - Serial terminal command
#
# Creates a target (${TARGET_NAME}-serial) for launching the serial termnial.
#
#=============================================================================#
function(setup_serial_target TARGET_NAME CMD)
    string(CONFIGURE "${CMD}" FULL_CMD @ONLY)
    add_custom_target(${TARGET_NAME}-serial
                      ${FULL_CMD})
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# detect_arduino_version(VAR_NAME)
#
#       VAR_NAME - Variable name where the detected version will be saved
#
# Detects the Arduino SDK Version based on the revisions.txt file.
#
#=============================================================================#
function(detect_arduino_version VAR_NAME)
    if(ARDUINO_VERSION_PATH)
        file(READ ${ARDUINO_VERSION_PATH} ARD_VERSION)
        if("${ARD_VERSION}" MATCHES " *[0]+([0-9]+)")
            set(${VAR_NAME} 0.${CMAKE_MATCH_1} PARENT_SCOPE)
        elseif("${ARD_VERSION}" MATCHES "[ ]*([0-9]+[.][0-9]+)")
            set(${VAR_NAME} ${CMAKE_MATCH_1} PARENT_SCOPE)
        endif()
    endif()
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# load_arduino_style_settings(SETTINGS_LIST SETTINGS_PATH)
#
#      SETTINGS_LIST - Variable name of settings list
#      SETTINGS_PATH - File path of settings file to load.
#
# Load a Arduino style settings file into the cache.
# 
#  Examples of this type of settings file is the boards.txt and
# programmers.txt files located in ${ARDUINO_SDK}/hardware/arduino.
#
# Settings have to following format:
#
#      entry.setting[.subsetting] = value
#
# where [.subsetting] is optional
#
# For example, the following settings:
#
#      uno.name=Arduino Uno
#      uno.upload.protocol=stk500
#      uno.upload.maximum_size=32256
#      uno.build.mcu=atmega328p
#      uno.build.core=arduino
#
# will generate the follwoing equivalent CMake variables:
#
#      set(uno.name "Arduino Uno")
#      set(uno.upload.protocol     "stk500")
#      set(uno.upload.maximum_size "32256")
#      set(uno.build.mcu  "atmega328p")
#      set(uno.build.core "arduino")
#
#      set(uno.SETTINGS  name upload build)              # List of settings for uno
#      set(uno.upload.SUBSETTINGS protocol maximum_size) # List of sub-settings for uno.upload
#      set(uno.build.SUBSETTINGS mcu core)               # List of sub-settings for uno.build
# 
#  The ${ENTRY_NAME}.SETTINGS variable lists all settings for the entry, while
# ${ENTRY_NAME}.SUBSETTINGS variables lists all settings for a sub-setting of
# a entry setting pair.
#
#  These variables are generated in order to be able to  programatically traverse
# all settings (for a example see print_board_settings() function).
#
#=============================================================================#
function(LOAD_ARDUINO_STYLE_SETTINGS SETTINGS_LIST SETTINGS_PATH)

    if(NOT ${SETTINGS_LIST} AND EXISTS ${SETTINGS_PATH})
    file(STRINGS ${SETTINGS_PATH} FILE_ENTRIES)  # Settings file split into lines

    foreach(FILE_ENTRY ${FILE_ENTRIES})
        if("${FILE_ENTRY}" MATCHES "^[^#]+=.*")
            string(REGEX MATCH "^[^=]+" SETTING_NAME  ${FILE_ENTRY})
            string(REGEX MATCH "[^=]+$" SETTING_VALUE ${FILE_ENTRY})
            string(REPLACE "." ";" ENTRY_NAME_TOKENS ${SETTING_NAME})
            string(STRIP "${SETTING_VALUE}" SETTING_VALUE)

            list(LENGTH ENTRY_NAME_TOKENS ENTRY_NAME_TOKENS_LEN)

            # Add entry to settings list if it does not exist
            list(GET ENTRY_NAME_TOKENS 0 ENTRY_NAME)
            list(FIND ${SETTINGS_LIST} ${ENTRY_NAME} ENTRY_NAME_INDEX)
            if(ENTRY_NAME_INDEX LESS 0)
                # Add entry to main list
                list(APPEND ${SETTINGS_LIST} ${ENTRY_NAME})
            endif()

            # Add entry setting to entry settings list if it does not exist
            set(ENTRY_SETTING_LIST ${ENTRY_NAME}.SETTINGS)
            list(GET ENTRY_NAME_TOKENS 1 ENTRY_SETTING)
            list(FIND ${ENTRY_SETTING_LIST} ${ENTRY_SETTING} ENTRY_SETTING_INDEX)
            if(ENTRY_SETTING_INDEX LESS 0)
                # Add setting to entry
                list(APPEND ${ENTRY_SETTING_LIST} ${ENTRY_SETTING})
                set(${ENTRY_SETTING_LIST} ${${ENTRY_SETTING_LIST}}
                    CACHE INTERNAL "Arduino ${ENTRY_NAME} Board settings list")
            endif()

            set(FULL_SETTING_NAME ${ENTRY_NAME}.${ENTRY_SETTING})

            # Add entry sub-setting to entry sub-settings list if it does not exists
            if(ENTRY_NAME_TOKENS_LEN GREATER 2)
                set(ENTRY_SUBSETTING_LIST ${ENTRY_NAME}.${ENTRY_SETTING}.SUBSETTINGS)
                list(GET ENTRY_NAME_TOKENS 2 ENTRY_SUBSETTING)
                list(FIND ${ENTRY_SUBSETTING_LIST} ${ENTRY_SUBSETTING} ENTRY_SUBSETTING_INDEX)
                if(ENTRY_SUBSETTING_INDEX LESS 0)
                    list(APPEND ${ENTRY_SUBSETTING_LIST} ${ENTRY_SUBSETTING})
                    set(${ENTRY_SUBSETTING_LIST}  ${${ENTRY_SUBSETTING_LIST}}
                        CACHE INTERNAL "Arduino ${ENTRY_NAME} Board sub-settings list")
                endif()
                set(FULL_SETTING_NAME ${FULL_SETTING_NAME}.${ENTRY_SUBSETTING})
            endif()

            # Save setting value
            set(${FULL_SETTING_NAME} ${SETTING_VALUE}
                CACHE INTERNAL "Arduino ${ENTRY_NAME} Board setting")
            

        endif()
    endforeach()
    set(${SETTINGS_LIST} ${${SETTINGS_LIST}}
        CACHE STRING "List of detected Arduino Board configurations")
    mark_as_advanced(${SETTINGS_LIST})
    endif()
endfunction()

#=============================================================================#
# print_settings(ENTRY_NAME)
#
#      ENTRY_NAME - name of entry
#
# Print the entry settings (see load_arduino_syle_settings()).
#
#=============================================================================#
function(PRINT_SETTINGS ENTRY_NAME)
    if(${ENTRY_NAME}.SETTINGS)

        foreach(ENTRY_SETTING ${${ENTRY_NAME}.SETTINGS})
            if(${ENTRY_NAME}.${ENTRY_SETTING})
                message(STATUS "   ${ENTRY_NAME}.${ENTRY_SETTING}=${${ENTRY_NAME}.${ENTRY_SETTING}}")
            endif()
            if(${ENTRY_NAME}.${ENTRY_SETTING}.SUBSETTINGS)
                foreach(ENTRY_SUBSETTING ${${ENTRY_NAME}.${ENTRY_SETTING}.SUBSETTINGS})
                    if(${ENTRY_NAME}.${ENTRY_SETTING}.${ENTRY_SUBSETTING})
                        message(STATUS "   ${ENTRY_NAME}.${ENTRY_SETTING}.${ENTRY_SUBSETTING}=${${ENTRY_NAME}.${ENTRY_SETTING}.${ENTRY_SUBSETTING}}")
                    endif()
                endforeach()
            endif()
            message(STATUS "")
        endforeach()
    endif()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# print_list(SETTINGS_LIST)
#
#      SETTINGS_LIST - Variables name of settings list
#
# Print list settings and names (see load_arduino_syle_settings()).
#=============================================================================#
function(PRINT_LIST SETTINGS_LIST)
    if(${SETTINGS_LIST})
        set(MAX_LENGTH 0)
        foreach(ENTRY_NAME ${${SETTINGS_LIST}})
            string(LENGTH "${ENTRY_NAME}" CURRENT_LENGTH)
            if(CURRENT_LENGTH GREATER MAX_LENGTH)
                set(MAX_LENGTH ${CURRENT_LENGTH})
            endif()
        endforeach()
        foreach(ENTRY_NAME ${${SETTINGS_LIST}})
            string(LENGTH "${ENTRY_NAME}" CURRENT_LENGTH)
            math(EXPR PADDING_LENGTH "${MAX_LENGTH}-${CURRENT_LENGTH}")
            set(PADDING "")
            foreach(X RANGE ${PADDING_LENGTH})
                set(PADDING "${PADDING} ")
            endforeach()
            message(STATUS "   ${PADDING}${ENTRY_NAME}: ${${ENTRY_NAME}.name}")
        endforeach()
    endif()
endfunction()

#=============================================================================#
# setup_arduino_example()
#=============================================================================#
function(SETUP_ARDUINO_EXAMPLE LIBRARY_NAME EXAMPLE_NAME OUTPUT_VAR)
    set(EXAMPLE_SKETCH_PATH )

    get_property(LIBRARY_SEARCH_PATH
                 DIRECTORY     # Property Scope
                 PROPERTY LINK_DIRECTORIES)
    foreach(LIB_SEARCH_PATH ${LIBRARY_SEARCH_PATH} ${ARDUINO_LIBRARIES_PATH} ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/libraries)
        if(EXISTS "${LIB_SEARCH_PATH}/${LIBRARY_NAME}/examples/${EXAMPLE_NAME}")
            set(EXAMPLE_SKETCH_PATH "${LIB_SEARCH_PATH}/${LIBRARY_NAME}/examples/${EXAMPLE_NAME}")
            break()
        endif()
    endforeach()

    if(EXAMPLE_SKETCH_PATH)
        setup_arduino_sketch(
            SKETCH ${EXAMPLE_SKETCH_PATH}
            SRCS SKETCH_CPP)
        set("${OUTPUT_VAR}" ${${OUTPUT_VAR}} ${SKETCH_CPP} PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Could not find example ${EXAMPLE_NAME} from library ${LIBRARY_NAME}")
    endif()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_sketch()
#
#      SKETCH - Path to sketch directory
#      SRCS  - Variable name where to save generated sketch source
#      DESKTOP_IGNORE  - Sources to ignore for desktop build
#
# Generates C++ sources from Arduino Sketch.
#=============================================================================#
function(SETUP_ARDUINO_SKETCH)

    cmake_parse_arguments(INPUT "" "SKETCH;SRCS" "DESKTOP_IGNORE" ${ARGN})
    error_for_unparsed(INPUT)
    required_variables(VARS INPUT_SKETCH MSG "must define sketch path")

    get_filename_component(SKETCH_NAME "${INPUT_SKETCH}" NAME)
    get_filename_component(SKETCH_PATH "${INPUT_SKETCH}" ABSOLUTE)

    if(EXISTS "${SKETCH_PATH}")
        set(SKETCH_CPP  ${CMAKE_CURRENT_BINARY_DIR}/${SKETCH_NAME}.cpp)
        set(MAIN_SKETCH ${SKETCH_PATH}/${SKETCH_NAME})

        if(EXISTS "${MAIN_SKETCH}.pde")
            set(MAIN_SKETCH "${MAIN_SKETCH}.pde")
        elseif(EXISTS "${MAIN_SKETCH}.ino")
            set(MAIN_SKETCH "${MAIN_SKETCH}.ino")
        else()
            message(FATAL_ERROR "Could not find main sketch (${SKETCH_NAME}.pde or ${SKETCH_NAME}.ino) at ${SKETCH_PATH}!")
        endif()
        arduino_debug_msg("sketch: ${MAIN_SKETCH}")

        # Find all sketch files
        file(GLOB SKETCH_SOURCES ${SKETCH_PATH}/*.pde ${SKETCH_PATH}/*.ino)

        list(REMOVE_ITEM SKETCH_SOURCES ${MAIN_SKETCH})

        if (ARDUINO_DESKTOP)
            list(REMOVE_ITEM SKETCH_SOURCES ${MAIN_SKETCH} ${INPUT_DESKTOP_IGNORE})
        endif()

        #foreach(SKETCH_SOURCE ${SKETCH_SOURCES})
            #message(STATUS "${SKETCH_SOURCE}")
        #endforeach()

        list(SORT SKETCH_SOURCES)

        generate_cpp_from_sketch("${MAIN_SKETCH}" "${SKETCH_SOURCES}" "${SKETCH_CPP}")

        # Regenerate build system if sketch changes
        add_custom_command(OUTPUT ${SKETCH_CPP}
                           COMMAND ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
                           WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                           DEPENDS ${MAIN_SKETCH} ${SKETCH_SOURCES}
                           COMMENT "Regnerating ${SKETCH_NAME} Sketch")
        set_source_files_properties(${SKETCH_CPP} PROPERTIES GENERATED TRUE)

        set("${INPUT_SRCS}" ${${INPUT_SRCS}} ${SKETCH_CPP} PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Sketch does not exist: ${SKETCH_PDE}")
    endif()
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# generate_cpp_from_sketch(MAIN_SKETCH_PATH SKETCH_SOURCES SKETCH_CPP)
#
#         MAIN_SKETCH_PATH - Main sketch file path
#         SKETCH_SOURCES   - Setch source paths
#         SKETCH_CPP       - Name of file to generate
#
# Generate C++ source file from Arduino sketch files.
#=============================================================================#
function(GENERATE_CPP_FROM_SKETCH MAIN_SKETCH_PATH SKETCH_SOURCES SKETCH_CPP)
    file(WRITE ${SKETCH_CPP} "// automatically generated by arduino-cmake\n")
    file(READ  ${MAIN_SKETCH_PATH} MAIN_SKETCH)

    # remove comments
    remove_comments(MAIN_SKETCH MAIN_SKETCH_NO_COMMENTS)

    # find first statement
    string(REGEX MATCH "[\n][_a-zA-Z0-9]+[^\n]*" FIRST_STATEMENT "${MAIN_SKETCH_NO_COMMENTS}")
    string(FIND "${MAIN_SKETCH}" "${FIRST_STATEMENT}" HEAD_LENGTH)
    if ("${HEAD_LENGTH}" STREQUAL "-1")
        set(HEAD_LENGTH 0)
    endif()
    #message(STATUS "FIRST STATEMENT: ${FIRST_STATEMENT}")
    #message(STATUS "FIRST STATEMENT POSITION: ${HEAD_LENGTH}")
    string(LENGTH "${MAIN_SKETCH}" MAIN_SKETCH_LENGTH)

    string(SUBSTRING "${MAIN_SKETCH}" 0 ${HEAD_LENGTH} SKETCH_HEAD)
    #arduino_debug_msg("SKETCH_HEAD:\n${SKETCH_HEAD}")

    # find the body of the main pde
    math(EXPR BODY_LENGTH "${MAIN_SKETCH_LENGTH}-${HEAD_LENGTH}")
    string(SUBSTRING "${MAIN_SKETCH}" "${HEAD_LENGTH}+1" "${BODY_LENGTH}-1" SKETCH_BODY)
    #arduino_debug_msg("BODY:\n${SKETCH_BODY}")

    # write the file head
    file(APPEND ${SKETCH_CPP} "#line 1 \"${MAIN_SKETCH_PATH}\"\n${SKETCH_HEAD}")

    # add arduino include header
    file(APPEND ${SKETCH_CPP} "#line 1 \"autogenerated\"\n")
    if(ARDUINO_SDK_VERSION VERSION_LESS 1.0)
        file(APPEND ${SKETCH_CPP} "#include \"WProgram.h\"\n")
    else()
        file(APPEND ${SKETCH_CPP} "#include \"Arduino.h\"\n")
    endif()

    # add function prototypes
    foreach(SKETCH_SOURCE_PATH ${SKETCH_SOURCES} ${MAIN_SKETCH_PATH})
        arduino_debug_msg("Sketch: ${SKETCH_SOURCE_PATH}")
        file(READ ${SKETCH_SOURCE_PATH} SKETCH_SOURCE)
        remove_comments(SKETCH_SOURCE SKETCH_SOURCE)

        set(ALPHA "a-zA-Z")
        set(NUM "0-9")
        set(ALPHANUM "${ALPHA}${NUM}")
        set(WORD "_${ALPHANUM}")
        set(LINE_START "(^|[\n])")
        set(QUALIFIERS "([${ALPHA}]+[ ])*")
        set(TYPE "[${WORD}]+([ ]*[\n][\t]*|[ ])")
        set(FNAME "[${WORD}]+[ ]?[\n]?[\t]*[ ]*")
        set(FARGS "[(]([\t]*[ ]*[*&]?[ ]?[${WORD}](\\[([${NUM}]+)?\\])*[,]?[ ]*[\n]?)*([,]?[ ]*[\n]?)?[)]")
        set(BODY_START "([ ]*[\n][\t]*|[ ]|[\n])*{")
        set(PROTOTYPE_PATTERN "${LINE_START}${QUALIFIERS}${TYPE}${FNAME}${FARGS}${BODY_START}")

        string(REGEX MATCHALL "${PROTOTYPE_PATTERN}" SKETCH_PROTOTYPES "${SKETCH_SOURCE}")

        # Write function prototypes
        file(APPEND ${SKETCH_CPP} "\n//=== START Forward: ${SKETCH_SOURCE_PATH}\n")
        foreach(SKETCH_PROTOTYPE ${SKETCH_PROTOTYPES})  
            string(REPLACE "\n" " " SKETCH_PROTOTYPE "${SKETCH_PROTOTYPE}")
            string(REPLACE "{" "" SKETCH_PROTOTYPE "${SKETCH_PROTOTYPE}")
            arduino_debug_msg("\tprototype: ${SKETCH_PROTOTYPE};")
            file(APPEND ${SKETCH_CPP} "${SKETCH_PROTOTYPE};\n")
        endforeach()
        file(APPEND ${SKETCH_CPP} "//=== END Forward: ${SKETCH_SOURCE_PATH}\n")
    endforeach()
    
    # Write Sketch CPP source
    get_num_lines("${SKETCH_HEAD}" HEAD_NUM_LINES)
    file(APPEND ${SKETCH_CPP} "#line ${HEAD_NUM_LINES} \"${MAIN_SKETCH_PATH}\"\n")
    file(APPEND ${SKETCH_CPP} "\n${SKETCH_BODY}")
    foreach (SKETCH_SOURCE_PATH ${SKETCH_SOURCES})
        file(READ ${SKETCH_SOURCE_PATH} SKETCH_SOURCE)
        file(APPEND ${SKETCH_CPP} "\n//=== START : ${SKETCH_SOURCE_PATH}\n")
        file(APPEND ${SKETCH_CPP} "#line 1 \"${SKETCH_SOURCE_PATH}\"\n")
        file(APPEND ${SKETCH_CPP} "${SKETCH_SOURCE}")
        file(APPEND ${SKETCH_CPP} "\n//=== END : ${SKETCH_SOURCE_PATH}\n")
    endforeach()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_arduino_size_script(OUTPUT_VAR)
#
#        OUTPUT_VAR - Output variable that will contain the script path
#
# Generates script used to display the firmware size.
#=============================================================================#
function(SETUP_ARDUINO_SIZE_SCRIPT OUTPUT_VAR)
    set(ARDUINO_SIZE_SCRIPT_PATH ${CMAKE_BINARY_DIR}/CMakeFiles/FirmwareSize.cmake)

    file(WRITE ${ARDUINO_SIZE_SCRIPT_PATH} "
    set(AVRSIZE_PROGRAM ${AVRSIZE_PROGRAM})
    set(AVRSIZE_FLAGS --target=ihex -d)

    execute_process(COMMAND \${AVRSIZE_PROGRAM} \${AVRSIZE_FLAGS} \${FIRMWARE_IMAGE}
                    OUTPUT_VARIABLE SIZE_OUTPUT)

    string(STRIP \"\${SIZE_OUTPUT}\" SIZE_OUTPUT)

    # Convert lines into a list
    string(REPLACE \"\\n\" \";\" SIZE_OUTPUT \"\${SIZE_OUTPUT}\")

    list(GET SIZE_OUTPUT 1 SIZE_ROW)

    if(SIZE_ROW MATCHES \"[ \\t]*[0-9]+[ \\t]*[0-9]+[ \\t]*[0-9]+[ \\t]*([0-9]+)[ \\t]*([0-9a-fA-F]+).*\")
        message(\"Total size \${CMAKE_MATCH_1} bytes\")
    endif()")

    set(${OUTPUT_VAR} ${ARDUINO_SIZE_SCRIPT_PATH} PARENT_SCOPE)
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
#  arduino_debug_on()
#
# Enables Arduino module debugging.
#=============================================================================#
function(ARDUINO_DEBUG_ON)
    set(ARDUINO_DEBUG True PARENT_SCOPE)
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
#  arduino_debug_off()
#
# Disables Arduino module debugging.
#=============================================================================#
function(ARDUINO_DEBUG_OFF)
    set(ARDUINO_DEBUG False PARENT_SCOPE)
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# arduino_debug_msg(MSG)
#
#        MSG - Message to print
#
# Print Arduino debugging information. In order to enable printing
# use arduino_debug_on() and to disable use arduino_debug_off().
#=============================================================================#
function(ARDUINO_DEBUG_MSG MSG)
    if(ARDUINO_DEBUG)
        message("## ${MSG}")
    endif()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# remove_comments(SRC_VAR OUT_VAR)
#
#        SRC_VAR - variable holding sources
#        OUT_VAR - variable holding sources with no comments
#
#=============================================================================#
function(REMOVE_COMMENTS SRC_VAR OUT_VAR)
    string(REGEX REPLACE "[\\./\\\\]" "_" FILE "${NAME}")

    set(SRC ${${SRC_VAR}})

    #message(STATUS "removing comments from: ${FILE}")
    #file(WRITE "${CMAKE_BINARY_DIR}/${FILE}_pre_remove_comments.txt" ${SRC})
    #message(STATUS "\n${SRC}")

    # remove all comments
    string(REGEX REPLACE "([/][/][^\n]*)|([/][\\*]([^\\*]|([\\*]+[^/\\*]))*[\\*]+[/])" "" OUT "${SRC}")

    #file(WRITE "${CMAKE_BINARY_DIR}/${FILE}_post_remove_comments.txt" ${SRC})
    #message(STATUS "\n${SRC}")

    set(${OUT_VAR} ${OUT} PARENT_SCOPE)

endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#=============================================================================#
function(GET_NUM_LINES VAR NUM_LINES)
    string(REGEX MATCHALL "[\n]" MATCH_LIST "${VAR}")
    list(LENGTH MATCH_LIST NUM)
    set(${NUM_LINES} ${NUM} PARENT_SCOPE)
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#=============================================================================#
function(REQUIRED_VARIABLES)
    cmake_parse_arguments(INPUT "" "MSG" "VARS" ${ARGN})
    error_for_unparsed(INPUT)
    foreach(VAR ${INPUT_VARS})
        #message(STATUS "processing: ${VAR}")
        if ("${${VAR}}" STREQUAL "")
            message(FATAL_ERROR "${VAR} not set: ${INPUT_MSG}")
        endif()
    endforeach()
endfunction()

#=============================================================================#
# error_for_unparsed()
#=============================================================================#
function(ERROR_FOR_UNPARSED PREFIX)
    set(ARGS "${${PREFIX}_UNPARSED_ARGUMENTS}")
    if (NOT ( "${ARGS}" STREQUAL "") )
        message(FATAL_ERROR "unparsed argument: ${ARGS}")
    endif()
endfunction()

#=============================================================================#
#                         System Paths                                        #
#=============================================================================#
if(UNIX)
    include(Platform/UnixPaths)
    if(APPLE)
        list(APPEND CMAKE_SYSTEM_PREFIX_PATH ~/Applications
                                             /Applications
                                             /Developer/Applications
                                             /sw        # Fink
                                             /opt/local) # MacPorts
    endif()
elseif(WIN32)
    include(Platform/WindowsPaths)
endif()

#=============================================================================#
#                         Arduino Settings                                    
#=============================================================================#
set(ARDUINO_OBJCOPY_EEP_FLAGS -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load
    --no-change-warnings --change-section-lma .eeprom=0   CACHE STRING "")
set(ARDUINO_OBJCOPY_HEX_FLAGS -O ihex -R .eeprom          CACHE STRING "")
set(ARDUINO_AVRDUDE_FLAGS -V                              CACHE STRING "")

#=============================================================================#
#                          Initialization                                     
#=============================================================================#
if(NOT ARDUINO_FOUND)
    set(ARDUINO_PATHS)
    foreach(VERSION 22 1)
        list(APPEND ARDUINO_PATHS arduino-00${VERSION})
    endforeach()

    file(GLOB SDK_PATH_HINTS /usr/share/arduino*
                             /opt/local/arduino*
                             /usr/local/share/arduino*)
    list(SORT SDK_PATH_HINTS)
    list(REVERSE SDK_PATH_HINTS)

    find_path(ARDUINO_SDK_PATH
              NAMES lib/version.txt
              PATH_SUFFIXES share/arduino
                            Arduino.app/Contents/Resources/Java/
                            ${ARDUINO_PATHS}
              HINTS ${SDK_PATH_HINTS}
              DOC "Arduino SDK path.")

    if(ARDUINO_SDK_PATH)
        if(WIN32)
            list(APPEND CMAKE_SYSTEM_PREFIX_PATH ${ARDUINO_SDK_PATH}/hardware/tools/avr/bin)
            list(APPEND CMAKE_SYSTEM_PREFIX_PATH ${ARDUINO_SDK_PATH}/hardware/tools/avr/utils/bin)
        elseif(APPLE)
            list(APPEND CMAKE_SYSTEM_PREFIX_PATH ${ARDUINO_SDK_PATH}/hardware/tools/avr/bin)
        endif()
    else()
        message(FATAL_ERROR "Could not find Arduino SDK (set ARDUINO_SDK_PATH)!")
    endif()

    find_file(ARDUINO_CORES_PATH
              NAMES cores
              PATHS ${ARDUINO_SDK_PATH}
              PATH_SUFFIXES hardware/arduino
              DOC "Path to directory containing the Arduino core sources.")

    find_file(ARDUINO_VARIANTS_PATH
              NAMES variants 
              PATHS ${ARDUINO_SDK_PATH}
              PATH_SUFFIXES hardware/arduino
              DOC "Path to directory containing the Arduino variant sources.")

    find_file(ARDUINO_BOOTLOADERS_PATH
              NAMES bootloaders
              PATHS ${ARDUINO_SDK_PATH}
              PATH_SUFFIXES hardware/arduino
              DOC "Path to directory containing the Arduino bootloader images and sources.")

    find_file(ARDUINO_LIBRARIES_PATH
              NAMES libraries
              PATHS ${ARDUINO_SDK_PATH}
              DOC "Path to directory containing the Arduino libraries.")

    find_file(ARDUINO_BOARDS_PATH
              NAMES boards.txt
              PATHS ${ARDUINO_SDK_PATH}
              PATH_SUFFIXES hardware/arduino
              DOC "Path to Arduino boards definition file.")

    find_file(ARDUINO_PROGRAMMERS_PATH
        NAMES programmers.txt
        PATHS ${ARDUINO_SDK_PATH}
        PATH_SUFFIXES hardware/arduino
        DOC "Path to Arduino programmers definition file.")

    find_file(ARDUINO_VERSION_PATH
        NAMES lib/version.txt
        PATHS ${ARDUINO_SDK_PATH}
        DOC "Path to Arduino version file.")

    find_program(ARDUINO_AVRDUDE_PROGRAM
        NAMES avrdude
        PATHS ${ARDUINO_SDK_PATH}
        PATH_SUFFIXES hardware/tools
        NO_DEFAULT_PATH)

    find_program(ARDUINO_AVRDUDE_PROGRAM
        NAMES avrdude
        DOC "Path to avrdude programmer binary.")

    find_program(AVRSIZE_PROGRAM
        NAMES avr-size)

    find_file(ARDUINO_AVRDUDE_CONFIG_PATH
        NAMES avrdude.conf
        PATHS ${ARDUINO_SDK_PATH} /etc/avrdude
        PATH_SUFFIXES hardware/tools
                      hardware/tools/avr/etc
        DOC "Path to avrdude programmer configuration file.")

    # Ensure that all required paths are found
    required_variables(VARS 
        ARDUINO_CORES_PATH
        ARDUINO_BOOTLOADERS_PATH
        ARDUINO_LIBRARIES_PATH
        ARDUINO_BOARDS_PATH
        ARDUINO_PROGRAMMERS_PATH
        ARDUINO_VERSION_PATH
        ARDUINO_AVRDUDE_FLAGS
        ARDUINO_AVRDUDE_PROGRAM
        ARDUINO_AVRDUDE_CONFIG_PATH
        AVRSIZE_PROGRAM
        MSG "Invalid Arduino SDK path (${ARDUINO_SDK_PATH}).\n")

    detect_arduino_version(ARDUINO_SDK_VERSION)
    set(ARDUINO_SDK_VERSION ${ARDUINO_SDK_VERSION} CACHE STRING "Arduino SDK Version")

    if(ARDUINO_SDK_VERSION VERSION_LESS 0.19)
         message(FATAL_ERROR "Unsupported Arduino SDK (require verion 0.19 or higher)")
    endif()

    message(STATUS "Arduino SDK version ${ARDUINO_SDK_VERSION}: ${ARDUINO_SDK_PATH}")

    setup_arduino_size_script(ARDUINO_SIZE_SCRIPT)
    set(ARDUINO_SIZE_SCRIPT ${ARDUINO_SIZE_SCRIPT} CACHE INTERNAL "Arduino Size Script")

    load_board_settings()
    load_programmers_settings()

    #print_board_list()
    #print_programmer_list()

    set(ARDUINO_FOUND True CACHE INTERNAL "Arduino Found")
    mark_as_advanced(
        ARDUINO_CORES_PATH
        ARDUINO_VARIANTS_PATH
        ARDUINO_BOOTLOADERS_PATH
        ARDUINO_LIBRARIES_PATH
        ARDUINO_BOARDS_PATH
        ARDUINO_PROGRAMMERS_PATH
        ARDUINO_VERSION_PATH
        ARDUINO_AVRDUDE_FLAGS
        ARDUINO_AVRDUDE_PROGRAM
        ARDUINO_AVRDUDE_CONFIG_PATH
        ARDUINO_OBJCOPY_EEP_FLAGS
        ARDUINO_OBJCOPY_HEX_FLAGS
        AVRSIZE_PROGRAM)
endif()
