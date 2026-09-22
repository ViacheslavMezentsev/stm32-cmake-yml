# Add to the existing executable; do not create a separate library/project.
target_sources(${PROJECT_NAME} PRIVATE Src/probe.c Src/probe.cpp)
target_include_directories(${PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Inc")
