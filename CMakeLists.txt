cmake_minimum_required(VERSION 3.0.0)
project(cpp-stages VERSION 1.0.0)

find_package(GTSAM REQUIRED)

# Add a simple executable
add_executable(main
  src/main.cpp
)
target_include_directories(main
  PRIVATE
    ${GTSAM_INCLUDE_DIR}
)
target_link_libraries(main
  gtsam
)
set_target_properties(main PROPERTIES CMAKE_CXX_STANDARD 11)

# Install to the default location
include(GNUInstallDirs)
install(TARGETS main)

# Add a unit test with GTest
include(CTest)
if(BUILD_TESTING)
  # Use FetchContent to retrieve the Google Test source code.
  include(FetchContent)
  FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG main
  )
  FetchContent_MakeAvailable(googletest)
  # After Google Test is available, it still needs included in tehe project.
  include(GoogleTest)
  # Create the testing executable.
  add_executable(test_gtsam
    test/test_gtsam.cpp
  )
  target_include_directories(test_gtsam
    PRIVATE
      ${GTSAM_INCLUDE_DIR}
  )
  target_link_libraries(test_gtsam
    gtest_main
    gtsam
  )
  set_target_properties(test_gtsam PROPERTIES CMAKE_CXX_STANDARD 11)
  gtest_discover_tests(test_gtsam)  
endif(BUILD_TESTING)
