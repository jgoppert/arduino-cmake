#=============================================================================#
# Author: QueezyTheGreat                                                      #
# Date:   26.04.2011                                                          #
#                                                                             #
# Description: Arduino CMake example                                          #
#                                                                             #
#=============================================================================#
#set(CMAKE_TOOLCHAIN_FILE cmake/ArduinoSimToolchain.cmake) # Arduino Toolchain
set(CMAKE_TOOLCHAIN_FILE cmake/ArduinoToolchain.cmake) # Arduino Toolchain

cmake_minimum_required(VERSION 2.8)

include(cmake/Platform/Arduino.cmake)

#====================================================================#
#  Setup Project                                                     #
#====================================================================#
project(ArduinoExample C CXX)

option(TEST "Enable testing" ON)
option(DEBUG "Enable debug" OFF)

# modify flags from default toolchain flags
#set(APM_OPT_FLAGS "-Wformat -Wall -Wshadow -Wpointer-arith -Wcast-align -Wwrite-strings -Wformat=2")
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${APM_OPT_FLAGS}")
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${APM_OPT_FLAGS} -Wno-reorder")
#set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${APM_OPT_FLAGS} -Wl,--relax")

#add_subdirectory(example)  # Add example directory to build

# debug output
if (DEBUG)
    arduino_debug_on()
endif()

include_directories(${ARDUINOSIM_PATH})
#add_definitions(-DDESKTOP_BUILD=1)

# projects
#generate_arduino_firmware(
    #FIRMWARE Blink
    #SKETCH ${CMAKE_SOURCE_DIR}/example/Blink
    #BOARD mega2560
    #PORT /dev/ttyUSB0
    #NO_AUTOLIBS)

#generate_arduino_example(
    #EXAMPLE SoftwareSerialExample
    #BOARD mega2560
    #LIBRARY SoftwareSerial
    #PORT /dev/ttyUSB0)

if (TEST)
    #generate_arduino_firmware(
        #FIRMWARE Blink2
        #SKETCH ${CMAKE_SOURCE_DIR}/test/Blink2
        #BOARD mega
        #PORT /dev/ttyUSB0)

    generate_arduino_firmware(
        FIRMWARE ArduPlane
        SKETCH ${CMAKE_SOURCE_DIR}/test/ArduPlane
        BOARD mega
        PORT /dev/ttyUSB0)

    #generate_arduino_firmware(
        #FIRMWARE ArduCopter
        #SKETCH ${CMAKE_SOURCE_DIR}/test/ArduCopter
        #BOARD mega
        #PORT /dev/ttyUSB0)

endif()
