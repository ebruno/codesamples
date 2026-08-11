# Functional Implementation Workflow

**Objective:** 
Implement the C++ Ringbuffer library by strictly following the specifications defined in `ringbuffer/prompts/common/cpp/functional.md` and the platform-specific specifications in `ringbuffer/prompts/<os>/cpp/functional.md`.

**Inputs:**
1. **Target OS**: The operating system to target (e.g., `fedora`, `debian`, `ubuntu`). If not specified, all OSes in `ringbuffer/src/` are processed.
2. **Target Version**: An optional version override (e.g., `43`, `12`). If provided, this overrides the default version specified in each OS's `create_functional.md`. If not provided, use the default version from the target OS's prompt.

**Process:**
1. **Target Selection**:
   - **Targeting**: 
     - **Specified Platform**: If the user request specifies a target platform (e.g., "implement functional for debian"), verify its existence in `ringbuffer/src/`. If the requested platform is missing from `ringbuffer/src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `ringbuffer/src/`). Process only the requested platforms that are implemented.
     - **General Request**: Otherwise, iterate through **all** OS directories found in `ringbuffer/src/` (e.g., debian, fedora, macos).
   - **Entry Point**: When targeting a specific OS, first consult `ringbuffer/prompts/<os>/cpp/create_functional.md` (if it exists) for immediate requirements and platform-specific directives.
   - **Language**: This workflow specifically targets the C++ implementation.

2. **Execution Steps**:
   For the selected OS directory, perform the following.

   **Workflow Precedence:** Execute this common workflow's Step 0 first for version resolution. Then execute `ringbuffer/prompts/<os>/cpp/create_functional.md` as the **PRIMARY** document and skip this common workflow's Steps 1-6. This common workflow serves as a reference for structure and provides the version resolution mechanism.

   **Note:** `create_functional.md` is read as a data source for version resolution in Step 0, then executed as the PRIMARY document afterward.

   0. **Environment Setup**:
      - **Resolve Version**: Determine the Target Version from Inputs (see above). If not provided by the user, read the default version from `ringbuffer/prompts/<os>/cpp/create_functional.md`. Log: `VERSION=<resolved_version>`.
      - **Validate Existing Dockerfile**: If the Dockerfile exists, verify that the resolved Target Version matches its base image tag. If it does not match, log an error and stop processing — the requested version conflicts with the existing container configuration.
      - **Create & Validate Container**: If the Dockerfile does not exist (functional phase), create a minimal Dockerfile in `ringbuffer/src/<os>/cpp/containers/Dockerfile` using the resolved version as the base image tag (e.g., `FROM fedora:<version>`). Attempt to pull or build the container image using the platform-appropriate runtime:
        - **macOS host**: use `container` to pull/build the image.
        - **Linux host**: use `podman` to pull/build the image.

        If the runtime is not available, log: `WARNING: Container runtime unavailable — version <version> could not be validated. Proceeding without container validation.` If the pull/build fails, log: `ERROR: Version <version> is not a supported base image for <OS>. Stopping processing.` and terminate.
      - **Navigate**: `cd ringbuffer/src/<os>/cpp`
      - **Log Initialization**: Create the log directory `logs/` if it does not exist. Initialize `functional.log` with the start timestamp, action description, and resolved version as per the "Generation Process Logging" requirement.

**Reporting:**

Once implementation is complete, generate a summary report at `ringbuffer/src/<os>/reports/implementation_report.md`.

**Template Precedence:** Use the reporting template defined in `ringbuffer/prompts/<os>/cpp/create_functional.md`. If none is defined, use the generic template below.

# Implementation Report - [OS Name] <use the version resolved in Step 0, e.g., "44">
**Date:** [YYYY-MM-DD HH:MM:SS]
**Target Version:** <use the version resolved in Step 0, e.g., "44">
**Start Time:** [YYYY-MM-DD HH:MM:SS]
**End Time:** [YYYY-MM-DD HH:MM:SS]
**Elapsed Time:** [Duration]

## Status
**Implementation Complete:** [Yes/No]
**Self-Audit Passed:** [Yes/No]

## Artifacts Created
- **Headers**: [List of .hpp files]
- **Source Files**: [List of .cpp files]
- **Logs**: `functional.log` created and updated.

## Compliance Notes
- **Function Distribution**: Verified no file exceeds 3 functions.
- **Include Order**: Verified `ringbuffer.hpp` is first in all `.cpp` files.
- **Naming**: Verified trailing underscore convention for private members.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
