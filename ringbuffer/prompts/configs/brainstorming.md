# LLM Brainstorming Configuration

When in brainstorming mode, focus on the following:

- **Architectural Trade-offs**: Discuss the pros and cons of different ringbuffer implementations (e.g., lock-free vs. locked).
- **Language Idioms**: Explore how to implement the buffer using the most idiomatic patterns of the target language.
- **Performance Analysis**: Predict potential bottlenecks and propose mitigation strategies.
- **API Design**: Propose intuitive and flexible interfaces for the library.
- **Edge Cases**: Identify potential failure modes and boundary conditions (e.g., wrap-around, overflow).
- **Cross-Platform Considerations**: Discuss OS-specific optimizations or constraints.
