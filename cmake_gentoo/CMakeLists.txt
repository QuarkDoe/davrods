cmake_minimum_required( VERSION 3.5.0 FATAL_ERROR )
#=====================================================

project( davrods C )

#-----------------------------------------------------

set(
    CMAKE_MODULE_PATH
    ${CMAKE_SOURCE_DIR}/cmake_modules/
)

set( DAVRODS_VERSION "1.4.1" )
set( IRODS_REQ_VERSION "4.2.5" CACHE STRING "iRODS client library version" )

get_filename_component( DAVRODS_SOURCE_DIR "${CMAKE_SOURCE_DIR}/.." ABSOLUTE )

include( DefineCMakeDefaults )
include( RequireOutOfSourceBuild )

option( LOG_VERBOSE "Be davrods log more verbose" OFF )

find_package( IRODS ${IRODS_REQ_VERSION} REQUIRED CONFIG )
message( STATUS "iRODS found" )
include( ${IRODS_TARGETS_PATH} )

find_program( APXS apxs DOC "Apache/HTTPD extension tool location" )
if( NOT APXS )
    message( FATAL_ERROR "Could not find apxs utility - make sure the apache/httpd dev package is installed" )
endif()

# Get platform-dependent HTTPD include paths.
execute_process( COMMAND ${APXS} -q exp_includedir OUTPUT_VARIABLE HTTPD_INCLUDE_DIR OUTPUT_STRIP_TRAILING_WHITESPACE )
execute_process( COMMAND ${APXS} -q sysconfdir     OUTPUT_VARIABLE HTTPD_CONF_DIR    OUTPUT_STRIP_TRAILING_WHITESPACE )
execute_process( COMMAND ${APXS} -q APR_INCLUDEDIR OUTPUT_VARIABLE APR_INCLUDE_DIR   OUTPUT_STRIP_TRAILING_WHITESPACE )
# Get installation paths (local to the build system).
execute_process( COMMAND ${APXS} -q exp_libexecdir OUTPUT_VARIABLE HTTPD_BUILDSYS_MODULE_DIR OUTPUT_STRIP_TRAILING_WHITESPACE )

include_directories( ${HTTPD_INCLUDE_DIR} ${APR_INCLUDE_DIR} )

set( CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,relro,-z,now" )

set(
    SOURCES
    ${DAVRODS_SOURCE_DIR}/src/mod_davrods.c
    ${DAVRODS_SOURCE_DIR}/src/auth.c
    ${DAVRODS_SOURCE_DIR}/src/common.c
    ${DAVRODS_SOURCE_DIR}/src/config.c
    ${DAVRODS_SOURCE_DIR}/src/prop.c
    ${DAVRODS_SOURCE_DIR}/src/propdb.c
    ${DAVRODS_SOURCE_DIR}/src/repo.c
    ${DAVRODS_SOURCE_DIR}/src/lock_local.c
    ${DAVRODS_SOURCE_DIR}/src/byterange.c
)

add_library( mod_davrods SHARED ${SOURCES} )

set_property( TARGET mod_davrods PROPERTY C_STANDARD 11 )

set(
    COMPILE_DEFS
    _REENTRANT
    DAVRODS_ENABLE_PROVIDER_NOLOCKS
    DAVRODS_ENABLE_PROVIDER_LOCALLOCK
)

if( LOG_VERBOSE )
    list( APPEND COMPILE_DEFS DAVRODS_DEBUG_DESPERATE )
endif( LOG_VERBOSE )

target_compile_options(
    mod_davrods PRIVATE
    -Wno-unused-parameter
    -Wno-missing-field-initializers
    -Wno-format # Due to APR/iRODS format specifier oddities.
    -fexceptions
    -fstack-protector-strong
    --param=ssp-buffer-size=4
)
target_compile_definitions(
    mod_davrods PRIVATE
    ${COMPILE_DEFS}
)

target_link_libraries( mod_davrods irods_client )

# Remove "lib" prefix from module SO file.
set_property( TARGET mod_davrods PROPERTY PREFIX "" )

install( TARGETS mod_davrods DESTINATION ${HTTPD_BUILDSYS_MODULE_DIR} )

install(
    FILES       ${DAVRODS_SOURCE_DIR}/aux/rpm/davrods.conf
    DESTINATION ${HTTPD_CONF_DIR}/modules.d
    RENAME      10-davrods.conf
)

install(
    FILES       ${DAVRODS_SOURCE_DIR}/aux/rpm/davrods-vhost.conf
                ${DAVRODS_SOURCE_DIR}/aux/rpm/davrods-anonymous-vhost.conf
    DESTINATION ${HTTPD_CONF_DIR}/vhosts.d/
)

install(
    FILES       ${DAVRODS_SOURCE_DIR}/aux/common/irods_environment.json
    DESTINATION ${HTTPD_CONF_DIR}/irods/
)

install(
    FILES       ${DAVRODS_SOURCE_DIR}/aux/common/listing/head.html
                ${DAVRODS_SOURCE_DIR}/aux/common/listing/header.html
                ${DAVRODS_SOURCE_DIR}/aux/common/listing/footer.html
                ${DAVRODS_SOURCE_DIR}/aux/common/listing/README.md
    DESTINATION ${HTTPD_CONF_DIR}/irods/
)

install(
    FILES       ${DAVRODS_SOURCE_DIR}/README.md
                ${DAVRODS_SOURCE_DIR}/COPYING 
                ${DAVRODS_SOURCE_DIR}/COPYING.LESSER 
                ${DAVRODS_SOURCE_DIR}/changelog.txt
    DESTINATION /usr/share/doc/davrods-${DAVRODS_VERSION}/
)

install(
    DIRECTORY
    DESTINATION /var/lib/davrods
)
