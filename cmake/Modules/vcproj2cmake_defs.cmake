# reset common variables used by all converted CMakeLists.txt files
set(V2C_LIBS )
set(V2C_SOURCES )

# Pre-define hook include filenames
# (may be redefined/overridden by local content!)
set(V2C_HOOK_PROJECT ${V2C_LOCAL_CONFIG_DIR}/hook_project.txt)
set(V2C_HOOK_PROJECT ${V2C_LOCAL_CONFIG_DIR}/hook_project.txt)
set(V2C_HOOK_POST_SOURCES ${V2C_LOCAL_CONFIG_DIR}/hook_post_sources.txt)
set(V2C_HOOK_POST_DEFINITIONS ${V2C_LOCAL_CONFIG_DIR}/hook_post_definitions.txt)
set(V2C_HOOK_POST_TARGET ${V2C_LOCAL_CONFIG_DIR}/hook_post_target.txt)
set(V2C_HOOK_POST ${V2C_LOCAL_CONFIG_DIR}/hook_post.txt)
