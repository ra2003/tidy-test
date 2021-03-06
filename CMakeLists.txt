# tidy-test - root CMakeLists.txt
# CMakeLists.txt, generated gencmake.pl, on 2015/05/20 11:53:57
cmake_minimum_required( VERSION 2.8.8 )

# CMakeScripts or use the ones that come by default with CMake.
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMakeModules ${CMAKE_MODULE_PATH})

project( tidy-test )

# The version number.
#set( TT_MAJOR 5 )
#set( TT_MINOR 7 )
#set( TT_POINT 3 )
#------------------------------------------------------------------------
# Verion Information
#   The version and date are found in `version.txt`; update *that*
#   file when required. It will be read into variable `versionFile`
#   (stripping any newlines or spaces). This file must be formatted into
#   two lines: the dot-separated MAJOR.MINOR.POINT version, followed by
#   the date separated YEAR.MONTH.DAY release date.
#------------------------------------------------------------------------
file(READ version.txt versionFile)
if (NOT versionFile)
    message(FATAL_ERROR "Unable to determine test tidy version. version.txt file is missing.")
endif()
string(STRIP "${versionFile}" VERSION_TEXT)
string(REGEX REPLACE "(.*)[\r\n|\n](.*)" "\\1" LIBTIDY_VERSION ${VERSION_TEXT})
string(REGEX REPLACE "(.*)[\r\n|\n](.*)" "\\2" LIBTIDY_DATE ${VERSION_TEXT})
# Establish version number
if (LIBTIDY_VERSION)
    string(REPLACE "." ";" VERSION_LIST ${LIBTIDY_VERSION})
    list(GET VERSION_LIST 0 TT_MAJOR)
    list(GET VERSION_LIST 1 TT_MINOR)
    list(GET VERSION_LIST 2 TT_POINT)
else ()
    message(FATAL_ERROR "*** FAILED to get a VERSION from version.txt!")
endif ()   
# Establish version date
if (LIBTIDY_DATE)
    string(REPLACE "." ";" DATE_LIST ${LIBTIDY_DATE})
    list(GET DATE_LIST 0 TT_YEAR)
    list(GET DATE_LIST 1 TT_MONTH)
    list(GET DATE_LIST 2 TT_DAY)
else ()
    message(FATAL_ERROR "*** FAILED to get a DATE from version.txt!")
endif ()

# Option to test libtidy-0.99, libtidy-5.0.0, ... compatibility - should FAIL with 5.5.5 onwards
option( USE_TIDY5_API "Set ON to test backward compatibility to libtidy-0.99, 5.0.0, onwards." OFF )
option( USE_TIDY_STATIC "Set OFF to only search for shared library" ON )

add_definitions( -DTIDY_TEST )
add_definitions( -DTT_VERSION="${TT_MAJOR}.${TT_MINOR}.${TT_POINT}" )
add_definitions( -DTT_DATE="${TT_YEAR}-${TT_MONTH}-${TT_DAY}" )

if(CMAKE_COMPILER_IS_GNUCXX)
    set( WARNING_FLAGS -Wall )
endif(CMAKE_COMPILER_IS_GNUCXX)

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang") 
   set( WARNING_FLAGS "-Wall -Wno-overloaded-virtual" )
endif() 

if(WIN32 AND MSVC)
    # turn off various warnings - none needed in this compile
    set(WARNING_FLAGS "${WARNING_FLAGS} /wd4996")
    # foreach(warning 4244 4251 4267 4275 4290 4786 4305)
    #     set(WARNING_FLAGS "${WARNING_FLAGS} /wd${warning}")
    # endforeach(warning)
    set( MSVC_FLAGS "-DNOMINMAX -D_USE_MATH_DEFINES -D_CRT_SECURE_NO_WARNINGS -D_SCL_SECURE_NO_WARNINGS -D__CRT_NONSTDC_NO_WARNINGS" )
    # if (${MSVC_VERSION} EQUAL 1600)
    #    set( MSVC_LD_FLAGS "/FORCE:MULTIPLE" )
    # endif (${MSVC_VERSION} EQUAL 1600)
    #set( NOMINMAX 1 )
    # to distinguish between debug and release libs
    set( CMAKE_DEBUG_POSTFIX "d" )
    # list(APPEND extra_LIBS Psapi Shlwapi Dnsapi odbc32 odbccp32)
    list(APPEND extra_LIBS Ws2_32 Winmm)
else()
    # items for unix
    set(WARNING_FLAGS "${WARNING_FLAGS} -Wno-unused-but-set-variable -Wno-unused-variable -Wno-switch")
     option(ADD_ASAN_LIB "Set to yes to put 'asan' link first" NO)
     if (ADD_ASAN_LIB)
        list( APPEND add_LIBS asan )
     endif ()   
endif()

set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${WARNING_FLAGS} ${MSVC_FLAGS} -D_REENTRANT" )
set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${WARNING_FLAGS} ${MSVC_FLAGS} -D_REENTRANT" )
set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${MSVC_LD_FLAGS}" )

#  CURL_FOUND          - True if curl found.
#  CURL_INCLUDE_DIRS   - where to find curl/curl.h, etc.
#  CURL_LIBRARIES      - List of libraries when using curl.
#  CURL_VERSION_STRING - the version of curl found (since CMake 2.8.8)
find_package(CURL)
if (CURL_FOUND)
    message(STATUS "*** CURL found inc ${CURL_INCLUDE_DIRS} lib ${CURL_LIBRARIES}")
    include_directories( ${CURL_INCLUDE_DIRS} )
    list( APPEND add_LIBS ${CURL_LIBRARIES} )
    get_filename_component(_LIB_NAME ${CURL_LIBRARIES} NAME)
    set(_MSG "SHARED")
    if ( "${_LIB_NAME}" STREQUAL "libcurl.lib" )
        add_definitions( -DCURL_STATICLIB=1 )
        set(CURL_STATICLIB 1)
        set(_MSG "STATIC")
    endif ()
    message(STATUS "cURL version ${CURL_VERSION_STRING} type ${_MSG}")
else ()
    message(STATUS "*** CURL NOT FOUND")
endif ()

if (CURL_STATICLIB)
    #   ZLIB_INCLUDE_DIRS   - where to find zlib.h, etc.
    #   ZLIB_LIBRARIES      - List of libraries when using zlib.
    #   ZLIB_FOUND          - True if zlib found.
    find_package(ZLIB)
    if (ZLIB_FOUND)
        message(STATUS "*** ZLIB found inc ${ZLIB_INCLUDE_DIRS} lib ${ZLIB_LIBRARIES}")
        include_directories( ${ZLIB_INCLUDE_DIRS} )
        list( APPEND add_LIBS ${ZLIB_LIBRARIES} )
    else ()
        message(FATAL_ERROR "*** ZLIB NOT FOUND. Needed for CURL static!")
    endif ()
endif ()

# configuration file, if needed
# configure_file( ${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h )
# add_definitions( -DHAVE_CONFIG_H )
# include_directories( ${CMAKE_BINARY_DIR} )

if (USE_TIDY5_API)
    message(STATUS "*** Using Tidy 5 API")
    add_definitions( -DUSE_TIDY5_API )
else()
   message(STATUS "*** Using current Tidy API - no locale test")
endif()

#  TIDY_FOUND          - True if tidy found.
#  TIDY_INCLUDE_DIRS   - where to find tidy.h, etc.
#  TIDY_LIBRARIES      - List of libraries when using tidy.
find_package( Tidy )
if (TIDY_FOUND)
    message(STATUS "*** Tidy found inc ${TIDY_INCLUDE_DIRS} lib ${TIDY_LIBRARIES}")
    include_directories( ${TIDY_INCLUDE_DIRS} )
    list(APPEND add_LIBS ${TIDY_LIBRARIES})
else ()
    message(FATAL_ERROR "*** Tidy NOT found! Maybe set ENV TIDY_ROOT to install location")
endif ()

# Total libs 1, exes ?
#################################################
##### LIBRARIES 1 #####
#################################################
set(name utillib)
set(dir src/utils)
include_directories( ${dir} )
set(${name}_SRCS 
    ${dir}/sprtf.c
    ${dir}/utils.cxx
    )
set(${name}_HDRS 
    ${dir}/sprtf.h
    ${dir}/utils.hxx
    )
if (WIN32)
    list(APPEND ${name}_SRCS ${dir}/httpio.c)
    list(APPEND ${name}_HDRS ${dir}/httpio.h)
endif ()
add_library( ${name} ${${name}_SRCS} ${${name}_HDRS} )
list(APPEND add_LIBS ${name})
# deal with install, if any...
#install( TARGETS ${name}
#    RUNTIME DESTINATION bin
#    LIBRARY DESTINATION lib
#    ARCHIVE DESTINATION lib )
#install(FILES ${${name}_HDRS} DESTINATION include)

#################################################
##### EXECUTABLE 1 #####
#################################################

# tidy EXECUTABLE from [src],
# have 1 C/C++ sources, 0 headers
set(name tidy-test)
set(dir src)
set(${name}_SRCS
    ${dir}/tidy.c
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
# deal with install, if any...
#install( TARGETS ${name} DESTINATION bin )

if (USE_TIDY5_API)
set(name tidy-test-prev)
set(dir src)
set(${name}_SRCS
    ${dir}/tidy-prev.c
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
# deal with install, if any...
#install( TARGETS ${name} DESTINATION bin )

endif (USE_TIDY5_API)

set(name tidy-opts)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.c
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
# deal with install, if any...
#install( TARGETS ${name} DESTINATION bin )

set(name test71)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.cxx
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
# deal with install, if any...
#install( TARGETS ${name} DESTINATION bin )

set(name test226)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.cxx
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
# deal with install, if any...
#install( TARGETS ${name} DESTINATION bin )

if (WIN32)
    # TODO: Not yet ported to unix
    set(name tidy-url)
    set(dir src)
    set(${name}_SRCS
        ${dir}/${name}.cxx
        )
    add_executable( ${name} ${${name}_SRCS} )
    if (add_LIBS)
        target_link_libraries( ${name} ${add_LIBS} ${extra_LIBS} )
    endif ()
    if (MSVC)
        set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
    endif ()
    # deal with install, if any...
    #install( TARGETS ${name} DESTINATION bin )
endif ()

set(name tidy-tree)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.cxx
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
# deal with install, if any...
#install( TARGETS ${name} DESTINATION bin )

if (CURL_FOUND)
    set(name htmltidy)
    set(dir src)
    set(${name}_SRCS
        ${dir}/${name}.c
        )
    add_executable( ${name} ${${name}_SRCS} )
    target_link_libraries( ${name} ${add_LIBS}  ${extra_LIBS} )
    if (MSVC)
        set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
    endif ()
    # deal with install, if any...
    #install( TARGETS ${name} DESTINATION bin )

    set(name url2text)
    set(dir src)
    set(${name}_SRCS
        ${dir}/${name}.cxx
        )
    add_executable( ${name} ${${name}_SRCS} )
    target_link_libraries( ${name} ${add_LIBS} ${extra_LIBS} )
    if (MSVC)
        set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
    endif ()
    # deal with install, if any...
    #install( TARGETS ${name} DESTINATION bin )
endif ()

###############################################################
### utiltity/tool to convert leading spaces in a file to tabs
set(name space2tab)
set(dir src/tools)
set(${name}_SRCS
    ${dir}/${name}.c
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()

### utiltity/tool to convert leading tabs in a file to spaces
### is more or less a duplicate of the tab2space console tool in tidy source
set(name tab2spaces)
set(dir src/tools)
set(${name}_SRCS
    ${dir}/${name}.c
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()

################################################################
### build the sample code
set(name sample)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.c
    )
add_executable( ${name} ${${name}_SRCS} )
target_link_libraries( ${name} ${add_LIBS} )
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()

################################################################
### test-get-options.c
set(name test-get-options)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.c
    )
add_executable( ${name} ${${name}_SRCS} )
target_link_libraries( ${name} ${add_LIBS} )
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()

################################################################
### tidy-json.cxx
set(name tidy-json)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.cxx
    )
add_executable( ${name} ${${name}_SRCS} )
target_link_libraries( ${name} ${add_LIBS} )
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()

################################################################
### test-tidy.cxx - an idea to run tests internally
set(name test-tidy)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.cxx
    )
add_executable( ${name} ${${name}_SRCS} )
target_link_libraries( ${name} ${add_LIBS} )
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()

if (USE_TIDY5_API)
    ################################################################
    ### tidy-locale.c - show current local as tidy sees it
    set(name tidy-locale)
    set(dir src)
    set(${name}_SRCS
        ${dir}/${name}.c
        )
    add_executable( ${name} ${${name}_SRCS} )
    target_link_libraries( ${name} ${add_LIBS} )
    if (MSVC)
        set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
    endif ()
endif ()

################################################################
### test-locale.c - show current local like tidy sees it
### 2018-11-30 - I18N isn't working (mostly) via changing the environment variables #783
set(name test-locale)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.c
    )
add_executable( ${name} ${${name}_SRCS} )
target_link_libraries( ${name} ${add_LIBS} )
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()

################################################################
### tidy-buf-test - Issue #413 - Using tidyParseBuffer
set(name tidy-buf-test)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.c
    )
add_executable( ${name} ${${name}_SRCS} )
target_link_libraries( ${name} ${add_LIBS} )
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()

################################################################
### issue-452 - oops, seems this is only for MS? compilers TODO: check...
### gcc 4.8.4 : warning: ‘auto’ changes meaning in C++11; please remove it [-Wc++0x-compat], then
### error: ‘showErrors’ does not name a type
###     auto showErrors = tidyOptGetValue(tidyDoc, TidyShowErrors);
### ALSO
### error: ‘nullptr’ was not declared in this scope
###     if (showErrors!=nullptr) {
if (MSVC)
    set(name issue-452)
    set(dir src)
    set(${name}_SRCS ${dir}/${name}.cxx)
    add_executable( ${name} ${${name}_SRCS} )
    target_link_libraries( ${name} ${add_LIBS} )
    if (MSVC)
        set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
    endif ()
endif ()

################################################################
### build the sample2 code
set(name sample2)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.c
    )
add_executable( ${name} ${${name}_SRCS} )
target_link_libraries( ${name} ${add_LIBS} )
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()

################################################################
if (WIN32)
    # ONLY FOR WIN32 - generic load DLL
    set( name load-dll )
    set( dir src)
    set(${name}_SRCS
        ${dir}/${name}.cxx
        )
    add_executable( ${name} ${${name}_SRCS} )
    if (add_LIBS)
        target_link_libraries( ${name} ${add_LIBS} )
    endif ()
    if (MSVC)
        set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
    endif ()
endif (WIN32)

# 20190204 Is. #788 maybe exposed a case where output to a TidyBuffer
# could have an overrun... but not yet proved. This uses the 
# same technique as oss-fuzz projet tidy-html5/tidy_fuzzer.c
# to try to repeat the possible bug...
set(name tidy-by-buf)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.c
    )
add_executable( ${name} ${${name}_SRCS} )
target_link_libraries( ${name} ${add_LIBS} )
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()

# eof
