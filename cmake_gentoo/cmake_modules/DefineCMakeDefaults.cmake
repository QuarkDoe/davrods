# Use colored output
# since cmake 2.4.0
set( CMAKE_COLOR_MAKEFILE TRUE )

# Set the default build type to release with debug info
if( NOT CMAKE_BUILD_TYPE )
  set( CMAKE_BUILD_TYPE RelWithDebInfo
    CACHE STRING
      "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
  )
endif( NOT CMAKE_BUILD_TYPE )
