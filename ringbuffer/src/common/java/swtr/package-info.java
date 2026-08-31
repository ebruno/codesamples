/**
 * swtr ringbuffer library — high-performance, cross-platform circular buffer.
 * 
 * Implements a three-stage pipelined architecture (Read → Transform → Write)
 * that connects independent threads through a fixed-size array of shared slots.
 * Each slot carries its own state machine, checksum, and data buffer, enabling
 * lock-free concurrent processing with cache-line-aligned counters to prevent false sharing.
 * 
 * <p><b>Implemented:</b> C++, Java, Python &nbsp;|&nbsp; 
 * <b>7 target OSes:</b> macOS, Fedora, Debian, Ubuntu, Arch Linux, FreeBSD 14, Raspberry Pi OS</p>
 * 
 * <h2>Pipeline Overview</h2>
 * <ol>
 *   <li><b>Read thread</b> fills slots from input file descriptor, marking READYFORTRANSFORM when full</li>
 *   <li><b>Transform thread</b> applies user-supplied function to each slot's data, computes checksum</li>
 *   <li><b>Write thread</b> writes transformed data to output file descriptor, clears slot buffer</li>
 * </ol>
 * 
 * <h2>Core Types</h2>
 * <ul>
 *   <li>{@link swtr.BufferStatus} — Pipeline slot states (14 values)</li>
 *   <li>{@link swtr.ChecksumAlgorithm} — Hash algorithms (NONE, MD5, SHA256, SHA512)</li>
 *   <li>{@link swtr.LogLevel} — Logging verbosity levels (TRACE through CRITICAL)</li>
 *   <li>{@link swtr.BufferSlot} — Shared slot with state machine, checksum, and data buffer</li>
 *   <li>{@link swtr.RingBuffer} — Abstract interface defining the pipeline API</li>
 *   <li>{@link swtr.SwtrRingBuffer} — Concrete implementation with lock-free atomic coordination</li>
 *   <li>{@link swtr.ErrorHandler} — Error callback interface for pipeline error handling</li>
 *   <li>{@link swtr.TransformFunction} — Transform function interface for data processing</li>
 * </ul>
 */
package swtr;
