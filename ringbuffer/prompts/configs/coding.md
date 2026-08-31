# LLM Coding Configuration

When in coding mode, focus on the following:

- **Correctness**: Implement the functional requirements precisely.
- **Efficiency**: Optimize for performance and memory usage, especially for a ringbuffer.
- **Compliance**: Adhere to the specified language standards (e.g., C++20).
- **Portability**: Ensure code compiles and runs on the target operating systems.
- **Clean Code**: Follow industry best practices for the specific language.
- **Tooling**: Provide accurate Makefiles or CMake configurations.
- **Documentation**: 
    - Add clear, concise comments to complex logic.
    - **Doxygen**: All source modules (header and source files) must include full Doxygen-style comments for all classes, methods, variables, and functions. This includes `@brief`, `@param`, and `@return` tags where applicable.
- **Naming**: Use the specified naming prefix (`swtr_`) for all public classes, namespaces, and functions in C and C++ to prevent symbol collisions.
