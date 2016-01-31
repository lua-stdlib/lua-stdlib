## Lua

 - Requiring any stdlib module must not leak any symbols into the global
   namespace.

 - Any stdlib module may `require "std.base"`, and use any functions from
   there, as well as functions from `std.debug` (and `debug_init`); but,
   all other modules export argument checked functions that should not be
   called from anywhere in stdlib -- this is the client API.  If a
   function is needed by more than one module, move it to `std.base`
   without argument checking, and re-export with `argscheck` if necess-
   ary.

   Obviously, for objects it's perfectly fine to require the file that
   defines the object being derived from.  But to prevent accidentally
   calling argchecked methods, we always immediately create a prototype
   object with, e.g:

       local Container = require "std.container" {}

   (`std.object` is an exception to this rule because of how tightly
   bound to `std.container` it is, and does directly call some of
   containers methods by design).

 - Minimise forward declarations of functions, because having some
   declared as `local` in line, and others not is ugly and can easily
   cause rogue `local` keywords to be introduced that end up shadowing
   the intended declaration.  Mutually recursive functions, and
   alternate definitions are acceptable, in which case keep the forward
   declarations and definitions as close together as possible to
   minimise any possible misunderstandings later.

 - Try to maintain asciibetical ordering of function definitions in each
   source file, except where doing so would require forward declar-
   ations.  In that case use topological ordering to avoid the forward
   declarations.

 - Unless a table cannot possibly have a __len metamethod (i.e. it was
   constructed without one in the current scope), always use
   `base.insert` and `base.len` rather than core `table.insert` and the
   `#` operator, which do not honor __len in all implementations.

 - Unless a table cannot possibly have __pairs or __len metamethods
   (i.e. it was constructed without them in the current scope), always
   use `base.pairs` or `base.ipairs` rather than core `pairs` and
   `ipairs`, which do not honor __pairs or __len in all implementations.

 - Use consistent short names for common parameters:

     fh  a file handle, usually from io.open or similar
     fmt a format string
     fn  a function
     i   an index
     k   a value, usually from pairs or similar
     l   a list-like table
     n   a number
     s   a string
     t   a table

 - Do argument check all object methods (functions available from an
   object created by a module function -- usually listed in the
   `__index` subtable of the object metatable), to catch pathological
   calls early, preferably using a `typecheck.argscheck` wrapper around
   the internal implementation: this way, implementation functions can
   call each other without excessive rechecking of argument types.

 - Do argument check all module functions (functions available in the
   table returned from requiring that module).

 - Do argument check metamethods, to catch pathological calls early.


## LDocs

 - LDocs should be next to each function's argcheck wrapper (if it has
   one) in the export table, so that it's easy to check the consistency
   between the types declared in the LDocs and the argument types
   enforced by `typecheck.argscheck` or equivalent.

 - `backtick_references` is disabled for stdlib, if you want an inline
   cross-reference, use `@{reference}`.

 - Be liberal with `@see` references to similar apis.

 - Refer to other argument names with italics (`*italic*` in markdown).

 - Try to add entries for callback function signatures, and name them
   with the suffix `cb`.

 - Rely on the reader to understand how `:` call syntax works in Lua, and
   don't waste effort documenting methods that are already documented as
   functions.

 - Do document the prototype chain.  Don't document methods inherited
   from the prototype, even they have been overridden to behave consist-
   ently from a UI perspective even though the implementation needs to be
   different to provide that same UI.
