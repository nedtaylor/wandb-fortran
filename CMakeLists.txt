cmake_minimum_required(VERSION 3.21)

project(wandb-fortran VERSION 0.1.0 LANGUAGES C Fortran)

include(CTest)
include(GNUInstallDirs)

function(_wf_python_query output_var python_code)
    execute_process(
        COMMAND "${Python3_EXECUTABLE}" -c "${python_code}"
        OUTPUT_VARIABLE _wf_query_output
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
    )
    set(${output_var} "${_wf_query_output}" PARENT_SCOPE)
endfunction()

find_package(Python3 REQUIRED COMPONENTS Interpreter Development)

_wf_python_query(WF_PYTHON_HOME "import sys; print(sys.prefix)")
_wf_python_query(WF_PYTHON_PURELIB "import sysconfig; print(sysconfig.get_path('purelib') or '')")
_wf_python_query(WF_PYTHON_PLATLIB "import sysconfig; print(sysconfig.get_path('platlib') or '')")
_wf_python_query(WF_PYTHON_LIBDIR "import sysconfig; print(sysconfig.get_config_var('LIBDIR') or '')")

set(WF_PYTHON_PATH "${WF_PYTHON_PURELIB}")
if(WF_PYTHON_PLATLIB AND NOT WF_PYTHON_PLATLIB STREQUAL WF_PYTHON_PURELIB)
    string(APPEND WF_PYTHON_PATH ":${WF_PYTHON_PLATLIB}")
endif()

set(wandb_fortran_sources
    src/wf/wf_c_bindings.f90
    src/wf/wf_run.f90
    src/wf/wf_config.f90
    src/wf/wf_sweep.f90
    src/wf.f90
    src/wf_c.c
)

add_library(wandb_fortran ${wandb_fortran_sources})
set_target_properties(
    wandb_fortran
    PROPERTIES
        OUTPUT_NAME wandb_fortran
        C_STANDARD 99
        C_STANDARD_REQUIRED YES
        C_EXTENSIONS NO
        Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod"
        POSITION_INDEPENDENT_CODE ON
)

target_include_directories(
    wandb_fortran
    PUBLIC
        "${CMAKE_CURRENT_BINARY_DIR}/mod"
        "${PROJECT_SOURCE_DIR}/include"
    PRIVATE
        "${PROJECT_SOURCE_DIR}/src"
)

target_link_libraries(wandb_fortran PUBLIC Python3::Python)

install(
    TARGETS wandb_fortran
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)

install(
    FILES
        include/wandb.h
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

install(
    DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod/"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

if(WF_PYTHON_LIBDIR)
    set_target_properties(
        wandb_fortran
        PROPERTIES
            BUILD_RPATH "${WF_PYTHON_LIBDIR}"
            INSTALL_RPATH "${WF_PYTHON_LIBDIR}"
        )
endif()

if(BUILD_TESTING)
    add_executable(test_logging test/test_logging.f90)
    target_link_libraries(test_logging PRIVATE wandb_fortran)

    if(WF_PYTHON_LIBDIR)
        set_target_properties(
            test_logging
            PROPERTIES
                BUILD_RPATH "${WF_PYTHON_LIBDIR}"
                INSTALL_RPATH "${WF_PYTHON_LIBDIR}"
        )
    endif()

    add_test(NAME test_logging COMMAND test_logging)
    set_tests_properties(
        test_logging
        PROPERTIES
            ENVIRONMENT
                "WANDB_MODE=offline;WF_PYTHON_BIN=${Python3_EXECUTABLE};WF_PYTHON_HOME=${WF_PYTHON_HOME};WF_PYTHON_PATH=${WF_PYTHON_PATH}"
    )
endif()
