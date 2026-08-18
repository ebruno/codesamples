# Functional Implementation Workflow

**Objective:** 
Implement the C++ Ringbuffer library by strictly following the specifications defined in `prompts/common/cpp/functional.md` and the platform-specific specifications in `prompts/<os>/cpp/functional.md`.

**Inputs:**
1. **Target OS**: The operating system to target (e.g., `fedora`, `debian`, `ubuntu`). If not specified, all OSes in `src/` are processed.
2. **Target Version**: An optional version override (e.g., `43`, `12`). If provided, this overrides the default version specified in each OS's `create_functional.md`. If not provided, use the default version from the target OS's prompt.

**Process:**
1. **Target Selection**:
   - **Targeting**: 
     - **Specified Platform**: If the user request specifies a target platform (e.g., "implement functional for debian"), verify its existence in `src/`. If the requested platform is missing from `src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `src/`). Process only the requested platforms that are implemented.
     - **General Request**: Otherwise, iterate through **all** OS directories found in `src/` (e.g., debian, fedora, macos).
   - **Entry Point**: When targeting a specific OS, first consult `prompts/<os>/cpp/create_functional.md` (if it exists) for immediate requirements and platform-specific directives.
   - **Language**: This workflow specifically targets the C++ implementation.

2. **Execution Steps**:
   For the selected OS directory, perform the following.

   **Workflow Precedence:** Execute this common workflow's Step 0 first for version resolution. Then execute `prompts/<os>/cpp/create_functional.md` as the **PRIMARY** document and skip this common workflow's Steps 1-6. This common workflow serves as a reference for structure and provides the version resolution mechanism.

   **Note:** `create_functional.md` is read as a data source for version resolution in Step 0, then executed as the PRIMARY document afterward.

   0. **Environment Setup**:
      - **Resolve Version**: Determine the Target Version from Inputs (see above). If not provided by the user, read the default version from `prompts/<os>/cpp/create_functional.md`.
        - **macOS target**: If the user did not provide a version override, detect the host OS.
          - If `uname -s` returns `Darwin`, run `sw_vers --productVersion` to get the macOS version (e.g., "15.0.1"). Extract the major version number (e.g., `15`). Validate that it is **15 or higher** — valid macOS versions are 15 (Sequoia) and above. Log: `VERSION=<major_version>` (e.g., `VERSION=15`).
          - **macOS Host Detection**: When `uname -s` returns `Darwin`, the host OS is macOS. Use `sw_vers --productVersion` to get the actual macOS version (e.g., "26.5.2"). Example:
            ```
            $ sw_vers --productVersion
            26.5.2
            ```
            Full output:
            ```
            $ sw_vers
            ProductName:		macOS
            ProductVersion:		26.5.2
            BuildVersion:		25F84
            ```
            Help: `sw_vers -h` → Usage: sw_vers [--help|--productName|--productVersion|--productVersionExtra|--buildVersion]
          - **Apple Container Runtime**: macOS uses the `container` command (Apple Container), NOT Docker or podman. This is unique to macOS Apple Silicon machines. Key subcommands:
            - `container run` — Run a container
            - `container build` / `container image build` — Build an image from Dockerfile
            - `container images` / `container image list` — List images
            - `container system status` — Show container services status
            - `container system version` — Show container runtime version
            Help: `container --help` → Overview of all subcommands (run, build, images, exec, logs, etc.)
            System help: `container system --help` → df, dns, kernel, logs, property, start, status, stop, version
          - **Service Management**: The `container` daemon does NOT start automatically on macOS. Before using any container commands, ensure the service is running:
            - Check status: `container system status` — shows whether container services are active
            - Start service: `container system start` — starts the container daemon and required services
            - If status shows services are not running, execute `container system start` before proceeding with any container operations.
          - If the host OS is NOT macOS, STOP and display:
            ```
            ERROR: macOS version number is required.

            This workflow targets the macOS platform but the host OS is not macOS.
            Please either:
              1. Run this workflow on a macOS host, or
              2. Provide an explicit version override (e.g., "implement functional for macos --version 15").
            ```
      - Log: `VERSION=<resolved_version>`.
      - **Validate Existing Dockerfile (Linux targets only)**: If the target `<os>` is NOT `macos`:
        - If the Dockerfile exists, verify that the resolved Target Version matches its base image tag. If it does not match, log an error and stop processing — the requested version conflicts with the existing container configuration.
      - If the target IS `macos`, log: `[timestamp] Dockerfile validation skipped — macOS is native-only.` and proceed.
      - **Create & Validate Container (Linux targets only)**: If the target `<os>` is NOT `macos`:
        - If the Dockerfile does not exist (functional phase), create a minimal Dockerfile in `src/<os>/cpp/containers/Dockerfile` using the resolved version as the base image tag (e.g., `FROM fedora:<version>`). Attempt to pull or build the container image using the platform-appropriate runtime:
          - **macOS host**: use `container` to pull/build the image.
          - **Linux host**: use `podman` to pull/build the image.

          If the runtime is not available, log: `WARNING: Container runtime unavailable — version <version> could not be validated. Proceeding without container validation.` If the pull/build fails, log: `ERROR: Version <version> is not a supported base image for <OS>. Stopping processing.` and terminate.
      - If the target IS `macos`, log: `[timestamp] Container creation skipped — macOS is native-only.` and proceed.
      - **Navigate**: `cd src/<os>/cpp`
      - **Log Initialization**: Create the log directory `logs/` if it does not exist. Initialize `functional.log` with the start timestamp, action description, and resolved version as per the "Generation Process Logging" requirement.

**Reporting:**

Once implementation is complete, generate a summary report at `src/<os>/reports/implementation_report.md`.

**State Tracking:**
- After all source files have been created, create or update `.gen_state.json` in `src/<os>/cpp/` containing:
  - **platform**: The target OS name (e.g., `macos`, `fedora`, `debian`, `ubuntu`).
  - **language**: `cpp`.
  - **version**: Object with `MAJOR`, `MINOR`, `SUBVERSION`, `BUILD_ID` read from `version.mk`. If `version.mk` does not exist, use `{"MAJOR": 1, "MINOR": 0, "SUBVERSION": 0, "BUILD_ID": 1}` as defaults.
  - **prompts_used**: SHA-256 hashes of `common/cpp/functional.md` and `<os>/cpp/functional.md` (the prompts used to generate the source).
  - **generated_files**: SHA-256 hashes of all created `.cpp` and `.hpp` source files (not build artifacts — those are captured by `implement_build.md`).
  - **regression_image**: `"N/A"` for macOS (native-only, never uses containers). For Linux targets, use the resolved container image tag from Step 0 (e.g., `"fedora:44"`, `"debian:13"`).
  - **generation_timestamp**: ISO 8601 timestamp of when the state file was created.
- **Version Change Detection**: If `.gen_state.json` already exists, compare the current `version.mk` values against those stored. If any value has changed (e.g., `MAJOR`, `MINOR`, `SUBVERSION`, or `BUILD_ID`), log a warning and proceed — the build phase will regenerate versioned artifacts.
- **Purpose**: This state file is the authoritative source of truth for what was implemented. `implement_build.md` reads it to resolve version context. `run_regression.md` reads it for shared version and image information. `verify_build.md` does NOT modify this file — mismatches are errors, not state updates.

**Template Precedence:** Use the reporting template defined in `prompts/<os>/cpp/create_functional.md`. If none is defined, use the generic template below.

# Implementation Report - [OS Name] <use the version resolved in Step 0, e.g., "15">
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Target Version:** <use the version resolved in Step 0, e.g., "15">
**Start Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
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
