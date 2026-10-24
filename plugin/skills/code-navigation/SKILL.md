---
name: code-navigation
description: Answers questions about code structure and bindings without reading whole files. Use when exploring unfamiliar code, mapping dependencies, reading an API surface, tracing call chains or data flow across files, or checking a function's side effects before changing it.
---

# Code Navigation

Questions about code come in two shapes. A structure or binding question
("what does this file declare", "who uses this symbol", "what does this
function touch") is answered from the code's syntax tree and its bindings. A
text question ("where does this string appear", "show me lines 40-80") is
answered from the text. Pick the answer source by the shape of the question,
and take the cheapest answer that is enough.

## Procedure

1. **Scope first.** Before mapping a repository, narrow to the paths the
   question touches. An unscoped map of a large repository costs more than
   the question is worth.
2. **Structure before bodies.** Read a file's declarations and signatures
   before its bodies; read a body only when the question needs it.
3. **Bindings, not names.** "Where is this used" means every binding of the
   symbol, not every match of its name. A name can be a substring of another
   name, or shadowed. When only name matches are available, report them as
   name matches, never as bindings.
4. **Keep a symbol's identity.** Once a symbol is located, refer to it by
   its file and qualified name in follow-up questions, so the answer is
   about that symbol and no same-named other.
5. **Before changing a function,** know what it reads, writes, raises and
   calls, and which files depend on its file, so the blast radius is known
   before the edit.
6. **Trace end to end.** For a call chain or a data flow, follow the actual
   calls and values across files, from the start to the end; never infer a
   link from a name.

## Report

Each answer states what it covers, and whether each result is a resolved
binding or a name match. A not-found answer is not proof of absence: say how
it was searched.
