# Library sources from libavif's upstream libyuv revision 26e56be0f984.
set(libyuv_source "${CMAKE_CURRENT_SOURCE_DIR}/third_party/libyuv/source")
add_library(avif_yuv OBJECT
    "${libyuv_source}/compare.cc"
    "${libyuv_source}/compare_common.cc"
    "${libyuv_source}/compare_gcc.cc"
    "${libyuv_source}/compare_win.cc"
    "${libyuv_source}/convert_argb.cc"
    "${libyuv_source}/convert.cc"
    "${libyuv_source}/convert_from_argb.cc"
    "${libyuv_source}/convert_from.cc"
    "${libyuv_source}/convert_jpeg.cc"
    "${libyuv_source}/convert_to_argb.cc"
    "${libyuv_source}/convert_to_i420.cc"
    "${libyuv_source}/cpu_id.cc"
    "${libyuv_source}/mjpeg_decoder.cc"
    "${libyuv_source}/mjpeg_validate.cc"
    "${libyuv_source}/planar_functions.cc"
    "${libyuv_source}/rotate_any.cc"
    "${libyuv_source}/rotate_argb.cc"
    "${libyuv_source}/rotate.cc"
    "${libyuv_source}/rotate_common.cc"
    "${libyuv_source}/rotate_gcc.cc"
    "${libyuv_source}/rotate_lsx.cc"
    "${libyuv_source}/rotate_win.cc"
    "${libyuv_source}/row_any.cc"
    "${libyuv_source}/row_common.cc"
    "${libyuv_source}/row_gcc.cc"
    "${libyuv_source}/row_lasx.cc"
    "${libyuv_source}/row_lsx.cc"
    "${libyuv_source}/row_rvv.cc"
    "${libyuv_source}/row_win.cc"
    "${libyuv_source}/scale_any.cc"
    "${libyuv_source}/scale_argb.cc"
    "${libyuv_source}/scale.cc"
    "${libyuv_source}/scale_common.cc"
    "${libyuv_source}/scale_gcc.cc"
    "${libyuv_source}/scale_lsx.cc"
    "${libyuv_source}/scale_rgb.cc"
    "${libyuv_source}/scale_rvv.cc"
    "${libyuv_source}/scale_uv.cc"
    "${libyuv_source}/scale_win.cc"
    "${libyuv_source}/video_common.cc")
target_compile_features(avif_yuv PRIVATE cxx_std_11)
target_include_directories(avif_yuv PUBLIC third_party/libyuv/include)
set_target_properties(avif_yuv PROPERTIES POSITION_INDEPENDENT_CODE ON CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON)

set(libyuv_arch "${CMAKE_SYSTEM_PROCESSOR}")
if(CMAKE_CXX_COMPILER_ARCHITECTURE_ID)
    set(libyuv_arch "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}")
endif()
if(APPLE AND CMAKE_OSX_ARCHITECTURES)
    set(libyuv_arch "${CMAKE_OSX_ARCHITECTURES}")
endif()
string(TOLOWER "${libyuv_arch}" libyuv_arch)
if(libyuv_arch MATCHES "^(arm64|aarch64)$")
    if(MSVC)
        target_compile_definitions(avif_yuv PRIVATE LIBYUV_DISABLE_NEON LIBYUV_DISABLE_SVE LIBYUV_DISABLE_SME)
    else()
        set(neon64_sources
            "${libyuv_source}/compare_neon64.cc" "${libyuv_source}/rotate_neon64.cc"
            "${libyuv_source}/row_neon64.cc" "${libyuv_source}/scale_neon64.cc")
        set(sve_source "${libyuv_source}/row_sve.cc")
        target_sources(avif_yuv PRIVATE ${neon64_sources} "${sve_source}")
        set_source_files_properties(${neon64_sources} PROPERTIES
            COMPILE_OPTIONS "-march=armv8.2-a+dotprod+i8mm")
        set_source_files_properties("${sve_source}" PROPERTIES
            COMPILE_OPTIONS "-march=armv8.5-a+i8mm+sve2")

        # libyuv's SME kernels use the AArch64 streaming ABI.
        if(NOT WIN32)
            set(sme_sources "${libyuv_source}/rotate_sme.cc"
                "${libyuv_source}/row_sme.cc" "${libyuv_source}/scale_sme.cc")
            target_sources(avif_yuv PRIVATE ${sme_sources})
            set_source_files_properties(${sme_sources} PROPERTIES
                COMPILE_OPTIONS "-march=armv9-a+i8mm+sme")
        else()
            target_compile_definitions(avif_yuv PRIVATE LIBYUV_DISABLE_SME)
        endif()
    endif()
elseif(libyuv_arch MATCHES "^(arm|armv[7-9].*)$" AND NOT MSVC)
    set(neon_sources
        "${libyuv_source}/compare_neon.cc"
        "${libyuv_source}/rotate_neon.cc"
        "${libyuv_source}/row_neon.cc"
        "${libyuv_source}/scale_neon.cc")
    target_sources(avif_yuv PRIVATE ${neon_sources})
    target_compile_definitions(avif_yuv PRIVATE LIBYUV_NEON=1)
    set_source_files_properties(${neon_sources} PROPERTIES COMPILE_OPTIONS "-mfpu=neon")
elseif(APPLE AND CMAKE_OSX_ARCHITECTURES MATCHES ";")
    # Each slice has the correct x86 sources. Arm feature objects need a separate target architecture.
    target_compile_definitions(avif_yuv PRIVATE LIBYUV_DISABLE_NEON LIBYUV_DISABLE_SVE LIBYUV_DISABLE_SME)
endif()
