# Directory module copied by tests/run_case.py ("extra_dirs") inside and outside
# the project tree (spec 4.6.8, TC-78). The target name comes from the source
# directory, so several copies can be added to one project.
string(SHA1 _id "${CMAKE_CURRENT_SOURCE_DIR}")
string(SUBSTRING "${_id}" 0 8 _id)
add_library(extra_${_id} STATIC extra.c)
