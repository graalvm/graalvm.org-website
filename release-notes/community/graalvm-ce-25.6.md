---
layout: toc_content_ecosystem
title: GraalVM 25.6
link_title: GraalVM 25.6
permalink: "/release-notes/25.6/"
toc_group: release-notes
---

# GraalVM 25.6.5.1
(2026-11-24)

* [Platform and Distributions](#platform-and-distributions)
* [Native Image](#native-image)
* [GraalJS](#graaljs)
* [GraalPy](#graalpy)
* [GraalWasm](#graalwasm)
* [Truffle Framework](#truffle-language-implementation-framework)

## Platform and Distributions

* Released **GraalVM Community Edition 25.6.5.1**, a feature release based on OpenJDK 25.0.5.1. See [OpenJDK 25 Updates](https://jdk.java.net/25/){:target="_blank"}.
* Released **Oracle GraalVM 25.6.5.1**, a feature release based on Oracle JDK 25.0.5.1. See [Java SE 25.0.5.1 Release Notes](https://www.oracle.com/java/technologies/javase/25-0-5-1-relnotes.html){:target="_blank"}.
* Version compatibility: GraalVM 25.6.5.1 is compatible with [Graal Languages and other components](https://www.graalvm.org/latest/reference-manual/languages) version **25.6.5.1**.

## Native Image

* Added initial runtime support for `PrintFlagsFinal`. Configured runtime option values are printed before application startup. Effective values computed by subsystems can differ; for example, the garbage collector limit can differ when `MaxHeapSize` is `0`. The listing includes the options available in the image, labels each entry `{native image}`, and reports origins as `{default}`, `{build-time}`, `{command line}`, or `{runtime}`. Output normally goes to standard error and respects Native Image log-file and callback routing.
* Added runtime support for `IgnoreUnrecognizedVMOptions` and `UnlockDiagnosticVMOptions`.
* Added runtime support for `AbortVMOnCompilationFailure` through the Graal compiler's `CompilationFailureAction` option when runtime compilation is available.
* Updated the bundle format to version 3.0. Numbered directories for captured inputs and output destinations are allocated independently of input substitutions. Older bundle formats remain readable.
* Fixed image build failures caused by unused service providers with missing optional dependencies. Requesting an unlinkable provider still fails at runtime.
* Fixed conditional foreign metadata collection in the Tracing Agent, including partial runs, and preserved foreign conditions when generating or merging reachability metadata.

## GraalJS

* Updated Node.js to version 24.22.3.

## GraalPy

* Added support for PyREPL and made it the default. Set the `PYTHON_BASIC_REPL=1` environment variable to turn it off.
* Added a Java-based decimal module with significantly better performance.
* Published [https://gds.oracle.com/repositories/pypi/public-release/](https://gds.oracle.com/repositories/pypi/public-release/) with many more pre-built Python packages. It is set as the default value for the `--extra-index-url` `pip` option. The index at [https://www.graalvm.org/python/wheels/](https://www.graalvm.org/python/wheels/) is deprecated and will be removed in the future.

## GraalWasm

* GraalWasm contexts now enforce single-threaded access. Concurrent WebAssembly execution must use separate polyglot contexts.

## Truffle Framework

### Root node compilation, splitting, and calls

* Breaking change: Before compiling a root, automatic splitting now clones marked direct-call targets instead of cloning them during direct-call execution. `RootNode.cloneUninitialized` is invoked without an entered language context during automatic splitting; the root language remains entered, so implementations can still use `LanguageReference`. See [Splitting](https://github.com/oracle/graal/blob/master/truffle/docs/splitting/Splitting.md) for details.
* Added `RootNode.visitCloneableNodes` so roots can expose node trees stored outside ordinary child fields.
* The root node's language is now entered while Truffle prepares a root or inline compilation, allowing implementations of `RootNode.prepareForCompilation` to use `LanguageReference`.
* Added `RootNode.call(Node, int, Object[])` and root-aware direct and indirect call overloads to optimize interpreter calls when concrete root types are known. Added `RootNode.initializeCallTarget()` for explicit initialization; root-based calls require an initialized call target and otherwise throw `IllegalStateException`.

### Bytecode DSL

* `Float` and `Double` constants are now compared by their raw bits, so distinct `NaN` payloads no longer share a constant-pool slot.
* Constants used inside a finally handler are now serialized once, in the outermost context that can decode them, and the handler refers to that entry. Replays of the handler and the enclosing code therefore share one deserialized instance. A constant that references a root node declared inside the handler stays in the handler's own table. Equality-based deduplication is unchanged, and previously serialized bytecode still deserializes.
* Added `BytecodeIndexMode` (`CACHED_NODE`, the default; `FRAME`; `MANUAL`; `NONE`), `BytecodeNode.getBytecodeIndex(Frame)`, and `BytecodeNode.setBytecodeIndex(Frame, int)`. The existing `storeBytecodeIndexInFrame()` option remains supported; true is equivalent to `FRAME`. Illegal-local exception factories can accept the current bytecode index, or -1 when unavailable.
* Added `BytecodeNode.setBytecodeIndex(Node, Frame, int)` to store or clear the current bytecode index from nested nodes, with an encapsulating-node fallback for uncached execution.
* Added execution-metadata options on `OperationProxy.Proxyable` (`bindFrame`, `bindBytecodeNode`, `bindBytecodeIndex`) and `@Bind("$bytecodeIndex")`. AST indices default to -1 unless explicitly bound.
* Added `BytecodeRootNode.getInstrumentationNodeObject(TagTreeNode)` to supply tag-specific metadata, including variable names for read/write instrumentation.

### Bytecode-indexed calls and exceptions

* Added explicit bytecode-index call overloads and support in `FrameInstance` and guest stack traces; `-1` retains implicit lookup. Recompiled varargs calls may select a new overload; pass guest arguments in one `Object[]` to preserve their meaning. Existing binaries are unaffected.
* Added an `AbstractTruffleException` constructor overload and `getBytecodeIndex()` for explicit exception locations.
* Added `TruffleOptions.DetailedAssertions` to opt into expensive assertions with `-Dtruffle.DetailedAssertions=true`, independently of inexpensive Java assertions.
* Fixed empty variadic child validation in the Specialization DSL when execute methods provide all evaluated operands.
