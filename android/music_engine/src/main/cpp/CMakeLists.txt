# Puente nativo de NuvTune sobre TagLib (requerimiento seccion 2 y 13.1).
#
# TagLib se compila estaticamente dentro de libnuvtune_taglib.so; no se
# distribuye como biblioteca compartida aparte.

cmake_minimum_required(VERSION 3.22.1)
project(nuvtune_taglib LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# TagLib: solo la biblioteca, sin bindings, ejemplos ni pruebas.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_BINDINGS OFF CACHE BOOL "" FORCE)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(VISIBILITY_HIDDEN ON CACHE BOOL "" FORCE)

# Formatos que necesita la aplicacion (requerimiento seccion 6). Se apagan
# los formatos de tracker y los exoticos que no forman parte del alcance.
set(WITH_APE ON CACHE BOOL "" FORCE)
set(WITH_ASF ON CACHE BOOL "" FORCE)
set(WITH_MP4 ON CACHE BOOL "" FORCE)
set(WITH_RIFF ON CACHE BOOL "" FORCE)
set(WITH_VORBIS ON CACHE BOOL "" FORCE)
set(WITH_TRUEAUDIO OFF CACHE BOOL "" FORCE)
set(WITH_DSF OFF CACHE BOOL "" FORCE)
set(WITH_MOD OFF CACHE BOOL "" FORCE)
set(WITH_SHORTEN OFF CACHE BOOL "" FORCE)

# zlib viene con el NDK y habilita los marcos ID3v2 comprimidos.
set(WITH_ZLIB ON CACHE BOOL "" FORCE)

add_subdirectory(taglib EXCLUDE_FROM_ALL)

add_library(nuvtune_taglib SHARED taglib_jni.cpp)

# TagLib declara sus directorios de encabezados con include_directories() a
# nivel de directorio y solo expone INSTALL_INTERFACE en el objetivo `tag`.
# Consumido con add_subdirectory no propaga nada, asi que se declaran aqui.
target_include_directories(nuvtune_taglib
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/taglib/taglib
        ${CMAKE_CURRENT_SOURCE_DIR}/taglib/taglib/toolkit
        # taglib_config.h y config.h son generados por CMake.
        ${CMAKE_CURRENT_BINARY_DIR}/taglib)

target_link_libraries(nuvtune_taglib
    PRIVATE
        tag
        android
        log
        z)

target_compile_options(nuvtune_taglib PRIVATE -fvisibility=hidden -Wall)
