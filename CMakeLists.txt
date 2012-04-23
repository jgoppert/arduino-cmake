#=============================================================================#
# Author: QueezyTheGreat                                                      #
# Date:   26.04.2011                                                          #
#                                                                             #
# Description: Arduino CMake example                                          #
#                                                                             #
#=============================================================================#
set(CMAKE_TOOLCHAIN_FILE cmake/ArduinoToolchain.cmake) # Arduino Toolchain

cmake_minimum_required(VERSION 2.8)

#====================================================================#
#  Setup Project                                                     #
#====================================================================#
project(ArduinoExample C CXX)

option(TEST "Enable testing" ON)
option(DEBUG "Enable debug" ON)

# modify flags from default toolchain flags
set(APM_OPT_FLAGS "-Wformat -Wall -Wshadow -Wpointer-arith -Wcast-align -Wwrite-strings -Wformat=2")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${APM_OPT_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${APM_OPT_FLAGS} -Wno-reorder")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${APM_OPT_FLAGS} -Wl,--relax")

#add_subdirectory(example)  # Add example directory to build

# debug output
if (DEBUG)
    arduino_debug_on()
endif()

# projects

file(GLOB APM_DESKTOP_SUPPORT_SRCS "${CMAKE_SOURCE_DIR}/libraries/Desktop/support/*")

#generate_arduino_firmware(
    #FIRMWARE Blink
    #SKETCH ${CMAKE_SOURCE_DIR}/example/Blink
    #BOARD mega2560
    #PORT /dev/ttyUSB0
    #DESKTOP
    #DESKTOP_SRCS
        #${CMAKE_SOURCE_DIR}/libraries/Desktop/support/main.cpp
        #${CMAKE_SOURCE_DIR}/libraries/Desktop/support/Arduino.cpp
        #${CMAKE_SOURCE_DIR}/libraries/Desktop/support/FastSerial.cpp
        #${CMAKE_SOURCE_DIR}/libraries/Desktop/support/sitl_gps.cpp
        #${CMAKE_SOURCE_DIR}/libraries/Desktop/support/sitl.cpp
    #DESKTOP_COMPILE_FLAGS "-I${CMAKE_SOURCE_DIR}/libraries/Desktop/include -DSKETCH=\\\"Blink\\\""
    #NO_AUTOLIBS
    #)

#generate_arduino_example(
    #EXAMPLE SoftwareSerialExample
    #BOARD mega2560
    #LIBRARY SoftwareSerial
    #PORT /dev/ttyUSB0
    #)

if (TEST)

    #generate_arduino_firmware(
        #FIRMWARE Blink2
        #SKETCH ${CMAKE_SOURCE_DIR}/test/Blink2
        #BOARD mega
        #PORT /dev/ttyUSB0)

    #message(STATUS "${APM_DESKTOP_SUPPORT_SRCS}")
    generate_arduino_firmware(
        FIRMWARE ArduPlane
        SKETCH ${CMAKE_SOURCE_DIR}/test/ArduPlane
        BOARD mega2560
        DESKTOP
        DESKTOP_IGNORE
            I2C/I2C.cpp
            DataFlash/DataFlash_APM1.cpp
            FastSerial/FastSerial.cpp
            AP_Compass/AP_Compass_HMC5843.cpp
            AP_Baro/AP_Baro_BMP085.cpp
        DESKTOP_SRCS ${APM_DESKTOP_SUPPORT_SRCS}
        DESKTOP_COMPILE_FLAGS "-I${CMAKE_SOURCE_DIR}/libraries/Desktop/include -DSKETCH=\\\"ArduPlane\\\""
        PORT /dev/ttyUSB0)

    #generate_arduino_firmware(
        #FIRMWARE ArduCopter
        #SKETCH ${CMAKE_SOURCE_DIR}/test/ArduCopter
        #BOARD mega
        #PORT /dev/ttyUSB0)

endif()
