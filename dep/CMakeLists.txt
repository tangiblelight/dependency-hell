cmake_minimum_required(VERSION 3.20)

project(dep)

add_library(dep SHARED src/dep.c)
target_sources(dep PUBLIC FILE_SET HEADERS BASE_DIRS include FILES include/dep.h)
target_include_directories(dep PUBLIC include)
install(TARGETS dep FILE_SET HEADERS)
