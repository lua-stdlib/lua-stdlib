# Stdlib NEWS - User visible changes

## Noteworthy changes in release 41.1.0 (2015-01-30) [stable]

### New features

  - Anything that responds to `tostring` can be appended to a `std.strbuf`:

    ```lua
    local a, b = StrBuf { "foo", "bar" }, StrBuf { "baz", "quux" }
    a = a .. b --> "foobarbazquux"
    ```

  - `std.strbuf` stringifies lazily, so adding tables to a StrBuf
    object, and then changing the content of them before calling
    `tostring` also changes the contents of the buffer.  See LDocs for
    an example.

  - `debug.argscheck` accepts square brackets around final optional
    parameters, which is distinct to the old way of appending `?` or
    `|nil` in that no spurious "or nil" is reported for type mismatches
    against a final bracketed argument.

  - `debug.argscheck` can also check types of function return values, when
    specified as:

    ```lua
    fn = argscheck ("fname (?any...) => int, table or nil, string", fname)
    ```

    Optional results can be marked with brackets, and an ellipsis following
    the final type denotes any additional results must match that final
    type specification. Alternative result type groups are separated by "or".

  - New `table.unpack (t, [i, [j]])` function that defaults j to
    `table.maxn (t)`, even on luajit which stops before the first nil
    valued numeric index otherwise.

### Deprecations

  - `std.strbuf.tostring` has been deprecated in favour of `tostring`.
    Why write `std.strbuf.tostring (sb)` or `sb:tostring ()` when it is
    more idiomatic to write `tostring (sb)`?

### Bug fixes

  - `std.barrel` and the various `monkey_patch` functions now return
    their parent module table as documented.

  - stdlib modules are all `std.strict` compliant; require "std.strict"
    before requiring other modules no longer raises an error.

  - `debug.argscheck` can now diagnose when there are too many arguments,
    even in the case where the earlier arguments match parameters by
    skipping bracketed optionals, and the total number of arguments is
    still less than the absolute maximum allowed if optionals are counted
    too.

  - `package.normalize` now leaves valid ./../../ path prefixes unmolested.

### Incompatible changes

  - `debug.argscheck` requires nil parameter type `?` notation to be
    prepended to match Specl and TypedLua syntax.  `?` suffixes are a
    syntax error.

  - `debug.argscheck` uses `...` instead of `*` appended to the final element
    if all unmatched argument types should match.  The trailing `*` syntax
    was confusing, because it was easy to misread it as "followed by zero-or-
    more of this type".


## Noteworthy changes in release 41.0.0 (2015-01-03) [beta]

### New features

  - Preliminary Lua 5.3.0 compatibility.

  - `object.prototype` now reports "file" for open file handles, and
    "closed file" for closed file handles.

  - New `debug.argerror` and `debug.argcheck` functions that provide Lua
    equivalents of `luaL_argerror` and `luaL_argcheck`.

  - New `debug.argscheck` function for checking all function parameter
    types with a single function call in the common case.

  - New `debug.export` function, which returns a wrapper function for
    checking all arguments of an inner function against a type list.

  - New `_DEBUG.argcheck` field that disables `debug.argcheck`, and
    changes `debug.argscheck` to return its function argument unwrapped,
    for production code.  Similarly `_DEBUG = false` deactivates these
    functions in the same way.

  - New `std.operator` module, with easier to type operator names (`conj`,
    `deref`, `diff`, `disj`, `eq`, `neg`, `neq`, `prod`, `quot`, and `sum`),
    and a functional operator for concatenation `concat`; plus new mathematical
    operators `mod`, and `pow`; and relational operators `lt`, `lte`, `gt` and
    `gte`.

  - `functional.case` now accepts non-callable branch values, which are
    simply returned as is, and functable values which are called and
    their return value propagated back to the case caller.  Function
    values behave the same as in previous releases.

  - `functional.collect`, `functional.filter`, `functional.map` and
    `functional.reduce` now work with standard multi-return iterators,
    such as `std.pairs`.

  - `functional.collect` defaults to using `std.ipairs` as an iterator.

  - New `functional.cond`, for evaluating multiple distinct expressions
    to determine what following value to be the returned.

  - `functional.filter` and `functional.map` default to using `std.pairs`
    as an iterator.

  - The init argument to `functional.foldl` and `functional.foldr` is now
    optional; when omitted these functions automatically start with
    the left- or right-most element of the table argument resp.

  - New `functional.callable` function for unwrapping objects or
    primitives that can be called as if they were a function.

  - New `functional.lambda` function for compiling lambda strings:

    ```lua
    table.sort (t, lambda "|a,b| a<b")
    ```

    or, equivalently using auto-arguments:

    ```lua
    table.sort (t, lambda "= _1 < _2"
    ```

  - New `functional.map_with` that returns a new table with keys matching
    the argument table, and values made by mapping the supplied function
    over value tables.  This replaces the misplaced, and less powerful
    `list.map_with`.

  - `functional.memoize` now propagates multiple return values correctly.
    This allows memoizing of functions that use the `return nil, "message"`
    pattern for error message reporting.

  - New `functional.nop` function, for use where a function is required
    but no work should be done.

  - New `functional.zip`, which in addition to replacing the functionality
    of deprecated `list.transpose` when handling lists of lists, correctly
    zips arbitrary tables of tables, and is orthogonal to `functional.map`.
    It is also more than twice as fast as `list.transpose`, processing
    with a single pass over the argument table as opposed to the two
    passes and addition book-keeping required by `list.transpose`s
    algorithm.

  - New `functional.zip_with`, subsumes functionality of deprecated
    `list.zip_with`, but also handles arbitrary tables of tables correctly,
    and is orthogonal to `functional.map_with`.

  - `std` module now collects stdlib functions that do not really belong
    in specific type modules: including `std.assert`, `std.eval`, and
    `std.tostring`. See LDocs for details.

  - New `std.ipairs` function that ignores `__ipairs` metamethod (like Lua
    5.1 and Lua 5.3), while always iterating from index 1 through n, where n
    is the last non-`nil` valued integer key. Writing your loops to use
    `std.ipairs` ensures your code will behave consistently across supported
    versions of Lua.

    All of stdlib's implementation now uses `std.ipairs` rather than `ipairs`
    internally.

  - New `std.ielems` and `std.elems` functions for iterating sequences
    analagously to `std.ipairs` and `std.pairs`, but returning only the
    value part of each key-value pair visited.

  - New `std.ireverse` function for reversing the proper sequence part of
    any table.

  - New `std.pairs` function that respects `__pairs` metamethod, even on
    Lua 5.1.

    All of stdlib's implementation now uses `std.pairs` rather than `pairs`
    internally. Among other improvements, this makes for a much more
    elegant imlementation of `std.object`, which also behaves intuitively
    and consistently when passed to `std.pairs`.

  - `std.require` now give a verbose error message when loaded module does not
    meet version numbers passed.

  - New `std.ripairs` function for returning index & value pairs in
    reverse order, starting at the highest non-nil-valued contiguous integer
    key.

  - New `table.len` function for returning the length of a table, much like
    the core `#` operation, but respecing `__len` even on Lua 5.1.

  - New `table.insert` and `table.remove` that use `table.len` to
    calculate default *pos* parameter, as well as diagnosing out of bounds
    *pos* parameters consistently on any supported version of Lua.

  - `table.insert` returns the modified table.

  - New `table.maxn` is available even when Lua compiled without
    compatibility, but uses the core implementation when possible.

  - New `table.okeys` function, like `table.keys` except that the list of
    keys is returned with numerical keys in order followed by remaining
    keys in asciibetical order.

  - `std.tostring`, `std.string.prettytostring` and the base `std.object`
    `__tostring` metamethod now all use `table.okeys` to sort keys in the
    generated stringification of a table.

### Deprecations

  - Deprecated APIs are kept for a minimum of 1 year following the first
    release that contains the deprecations.  With each new release of
    lua-stdlib, any APIs that have been deprecated for longer than that
    will most likely be removed entirely.  You can prevent that by
    raising an issue at <https://github.com/lua-stdlib/lua-stdlib/issues>
    explaining why any deprecation should be reinstated or at least kept
    around for more than 1 year.

  - By default, deprecated APIs will issue a warning to stderr on every
    call.  However, in production code, you can turn off these warnings
    entirely with any of:

    ```lua
    _DEBUG = false
    _DEBUG = { deprecate = false }
    require "std.debug_init".deprecate = false
    ```

    Or, to confirm you're not trying to call a deprecated function at
    runtime, you can prevent deprecated functions from being defined at
    all with any of:

    ```lua
    _DEBUG = true
    _DEBUG = { deprecate = true }
    require "std.debug_init".deprecate = true
    ```

    The `_DEBUG` global must be set before requiring any stdlib modules,
    but you can adjust the fields in the `std.debug_init` table at any
    time.

  - `functional.eval` has been moved to `std.eval`, the old name now
    gives a deprecation warning.

  - `functional.fold` has been renamed to `functional.reduce`, the old
    name now gives a deprecation warning.

  - `functional.op` has been moved to a new `std.operator` module, the
    old function names now gives deprecation warnings.

  - `list.depair` and `list.enpair` have been moved to `table.depair` and
    `table.enpair`, the old names now give deprecation warnings.

  - `list.filter` has been moved to `functional.filter`, the old name now
    gives a deprecation warning.

  - `list.flatten` has been moved to `table.flatten`, the old name now
    gives a deprecation warning.

  - `list.foldl` and `list.foldr` have been replaced by the richer
    `functional.foldl` and `functional.foldr` respectively.  The old
    names now give a deprecation warning.  Note that List object methods
    `foldl` and `foldr` are not affected.

  - `list.index_key` and `list.index_value` have been deprecated. These
    functions are not general enough to belong in lua-stdlib, because
    (among others) they only work correctly with tables that can be
    inverted without loss of key values.  They currently give deprecation
    warnings.

  - `list.map` and `list.map_with` has been deprecated, in favour of the
    more powerful new `functional.map` and `functional.map_with` which
    handle tables as well as lists.

  - `list.project` has been deprecated in favour of `table.project`, the
    old name now gives a deprecation warning.

  - `list.relems` has been deprecated, in favour of the more idiomatic
    `functional.compose (std.ireverse, std.ielems)`.

  - `list.reverse` has been deprecated in favour of the more general
    and more accurately named `std.ireverse`.

  - `list.shape` has been deprecated in favour of `table.shape`, the old
    name now gives a deprecation warning.

  - `list.transpose` has been deprecated in favour of `functional.zip`,
    see above for details.

  - `list.zip_with` has been deprecated in favour of `functional.zip_with`,
    see above for details.

  - `string.assert` has been moved to `std.assert`, the old name now
    gives a deprecation warning.

  - `string.require_version` has been moved to `std.require`, the old
    name now gives a deprecation warning.

  - `string.tostring` has been moved to `std.tostring`, the old name now
    gives a deprecation warning.

  - `table.metamethod` has been moved to `std.getmetamethod`, the old
    name now gives a deprecation warning.

  - `table.ripairs` has been moved to `std.ripairs`, the old name now
    gives a deprecation warning.

  - `table.totable` has been deprecated and now gives a warning when used.

### Incompatible changes

  - `std.monkey_patch` works the same way as the other submodule
    monkey_patch functions now, by injecting its methods into the given
    (or global) namespace.  To get the previous effect of running all the
    monkey_patch functions, either run them all manually, or call
    `std.barrel ()` as before.

  - `functional.bind` sets fixed positional arguments when called as
    before, but when the newly bound function is called, those arguments
    fill remaining unfixed positions rather than being overwritten by
    original fixed arguments.  For example, where this would have caused
    an error previously, it now prints "100" as expected.

    ```lua
    local function add (a, b) return a + b end
    local incr = functional.bind (add, {1})
    print (incr (99))
    ```

    If you have any code that calls functions returned from `bind`, you
    need to remove the previously ignored arguments that correspond to
    the fixed argument positions in the `bind` invocation.

  - `functional.collect`, `functional.filter` and `functional.map` still
    make a list from the results from an iterator that returns single
    values, but when an iterator returns multiple values they now make a
    table with key:value pairs taken from the first two returned values of
    each iteration.

  - The `functional.op` table has been factored out into its own new
    module `std.operator`.  It will also continue to be available from the
    legacy `functional.op` access point for the forseeable future.

  - The `functional.op[".."]` operator is no longer a list concatenation
    only loaded when `std.list` is required, but a regular string
    concatenation just like Lua's `..` operator.

  - `io.catdir` now raises an error when called with no arguments, for
    consistency with `io.catfile`.

  - `io.die` no longer calls `io.warn` to write the error message to
    stderr, but passes that error message to the core `error` function.

  - `std.set` objects used to be lax about enforcing type correctness in
    function arguments, but now that we have strict type-checking on all
    apis, table arguments are not coerced to Set objects but raise an
    error.  Due to an accident of implementation, you can get the old
    inconsistent behaviour back for now by turning off type checking
    before loading any stdlib modules:

    ```lua
    _DEBUG = { argcheck = false }
    local set = require "std.set"
    ```

  - `string.pad` will still (by implementation accident) coerce non-
    string initial arguments to a string using `string.tostring` as long
    as argument checking is disabled.  Under normal circumstances,
    passing a non-string will now raise an error as specified in the api
    documentation.

  - `table.totable` is deprecated, and thus objects no longer provide or
    use a `__totable` metamethod.  Instead, using a `__pairs` metamethod
    to return key/value pairs, and that will automatically be used by
    `__tostring`, `object.mapfields` etc.  The base object now provides a
    `__pairs` metamethod that returns key/value pairs in order, and
    ignores private fields.  If you have objects that relied on the
    previous treatment of `__totable`, please convert them to set a
    custom `__pairs` instead.


### Bug fixes

  - Removed LDocs for unused `_DEBUG.std` field.

  - `debug.trace` works with Lua 5.2.x again.

  - `list:foldr` works again instead of raising a "bad argument #1 to
    'List'" error.

  - `list.transpose` works again, and handles empty lists without
    raising an error; but is deprecated and will be removed in a future
    release (see above).

  - `list.zip_with` no longer raises an argument error on every call; but,
    like `list.transpose`, is also deprecated (see above).

  - `optparse.on` now works with `std.strict` enabled.

  - `std.require` (nee `string.require_version`) now extracts the last
    substring made entirely of digits and periods from the required
    module's version string before splitting on period.  That means, for
    version strings like luaposix's "posix library for Lua 5.2 / 32" we
    now correctly compare just the numeric part against specified version
    range rather than an ASCII comparison of the whole thing as before!

  - The documentation now correcly notes that `std.require` looks
    first in `module.version` and then `module._VERSION` to match the
    long-standing implementation.

  - `string.split` now really does split on whitespace when no split
    pattern argument is provided.  Also, the documentation now
    correctly cites `%s+` as the default whitespace splitting pattern
    (not `%s*` which splits between every non-whitespace character).


## Noteworthy changes in release 40 (2014-05-01) [stable]

### New features

  - `functional.memoize` now accepts a user normalization function,
    falling back on `string.tostring` otherwise.

  - `table.merge` now supports `map` and `nometa` arguments orthogonally
    to `table.clone`.

  - New `table.merge_select` function, orthogonal to
    `table.clone_select`.  See LDocs for details.

### Incompatible changes

  - Core methods and metamethods are no longer monkey patched by default
    when you `require "std"` (or `std.io`, `std.math`, `std.string` or
    `std.table`).  Instead they provide a new `monkey_patch` method you
    should use when you don't care about interactions with other
    modules:

    ```lua
    local io = require "std.io".monkey_patch ()
    ```

    To install all of stdlib's monkey patches, the `std` module itself
    has a `monkey_patch` method that loads all submodules with their own
    `monkey_patch` method and runs them all.

    If you want full compatibility with the previous release, in addition
    to the global namespace scribbling snippet above, then you need to
    adjust the first line to:

    ```lua
    local std = require "std".monkey_patch ()
    ```

  - The global namespace is no longer clobbered by `require "std"`. To
    get the old behaviour back:

    ```lua
    local std = require "std".barrel (_G)
    ```

    This will execute all available monkey_patch functions, and then
    scribble all over the `_G` namespace, just like the old days.

  - The `metamethod` call is no longer in `std.functional`, but has moved
    to `std.table` where it properly belongs.  It is a utility method for
    tables and has nothing to do with functional programming.

  - The following deprecated camelCase names have been removed, you
    should update your code to use the snake_case equivalents:
    `std.io.processFiles`, `std.list.indexKey`, `std.list.indexValue`,
    `std.list.mapWith`, `std.list.zipWith`, `std.string.escapePattern`,
    `std.string. escapeShell`, `std.string.ordinalSuffix`.

  - The following deprecated function names have been removed:
    `std.list.new`   (call `std.list` directly instead),
    `std.list.slice` (use `std.list.sub` instead),
    `std.set.new`    (call `std.set` directly instead),
    `std.strbuf.new` (call `std.strbuf` directly instead), and
    `std.tree.new`   (call `std.tree` directly instead).

### Bug fixes

  - Allow `std.object` derived tables as `std.tree` keys again.


## Noteworthy changes in release 39 (2014-04-23) [stable]

### New features

  - New `std.functional.case` function for rudimentary case statements.
    The main difference from serial if/elseif/end comparisons is that
    `with` is evaluated only once, and then the match function is looked
    up with an O(1) table reference and function call, as opposed to
    hoisting an expression result into a temporary variable, and O(n)
    comparisons.

    The function call overhead is much more significant than several
    comparisons, and so `case` is slower for all but the largest series
    of if/elseif/end comparisons.  It can make your code more readable,
    however.

    See LDocs for usage.

  - New pathstring management functions in `std.package`.

    Manage `package.path` with normalization, duplicate removal,
    insertion & removal of elements and automatic folding of '/' and '?'
    onto `package.dirsep` and `package.path_mark`, for easy addition of
    new paths. For example, instead of all this:

    ```lua
    lib = std.io.catfile (".", "lib", package.path_mark .. ".lua")
    paths = std.string.split (package.path, package.pathsep)
    for i, path in ipairs (paths) do
      -- ... lots of normalization code...
    end
    i = 1
    while i <= #paths do
      if paths[i] == lib then
        table.remove (paths, i)
      else
        i = i + 1
      end
    end
    table.insert (paths, 1, lib)
    package.path = table.concat (paths, package.pathsep)
    ```

    You can now write just:

    ```lua
    package.path = package.normalize ("./lib/?.lua", package.path)
    ```

  - `std.optparse:parse` accepts a second optional parameter, a table of
    default option values.

  - `table.clone` accepts an optional table of key field renames in the
    form of `{oldkey = newkey, ...}` subsuming the functionality of
    `table.clone_rename`. The final `nometa` parameter is supported
    whether or not a rename map is given:

    ```lua
    r = table.clone (t, "nometa")
    r = table.clone (t, {oldkey = newkey}, "nometa")
    ```

### Deprecations

  - `table.clone_rename` now gives a warning on first call, and will be
    removed entirely in a few releases.  The functionality has been
    subsumed by the improvements to `table.clone` described above.

### Bug fixes

  - `std.optparse` no longer throws an error when it encounters an
    unhandled option in a combined (i.e. `-xyz`) short option string.

  - Surplus unmapped fields are now discarded during object cloning, for
    example when a prototype has `_init` set to `{ "first", "second" }`,
    and is cloned using `Proto {'one', 'two', 'three'}`, then the
    unmapped `three` argument is now discarded.

  - The path element returned by `std.tree.nodes` can now always be
    used as a key list to dereference the root of the tree, particularly
    `tree[{}]` now returns the root node of `tree`, to match the initial
    `branch` and final `join` results from a full traversal by
    `std.tree.nodes (tree)`.

### Incompatible changes

  - `std.string` no longer sets `__append`, `__concat` and `__index` in
    the core strings metatable by default, though `require "std"` does
    continue to do so.  See LDocs for `std.string` for details.

  - `std.optparse` no longer normalizes unhandled options.  For example,
    `--unhandled-option=argument` is returned unmolested from `parse`,
    rather than as two elements split on the `=`; and if a combined
    short option string contains an unhandled option, then whatever was
    typed at the command line is returned unmolested, rather than first
    stripping off and processing handled options, and returning only the
    unhandled substring.

  - Setting `_init` to `{}` in a prototype object will now discard all
    positional parameters passed during cloning, because a table valued
    `_init` is a list of field names, beyond which surplus arguments (in
    this case, all arguments!) are discarded.


## Noteworthy changes in release 38 (2014-01-30) [stable]

### New features

  - The separator parameter to `std.string.split` is now optional.  It
    now splits strings with `%s+` when no separator is specified.  The
    new implementation is faster too.

  - New `std.object.mapfields` method factors out the table field copying
    and mapping performed when cloning a table `_init` style object. This
    means you can call it from a function `_init` style object after
    collecting a table to serve as `src` to support derived objects with
    normal std.object syntax:

    ```lua
    Proto = Object {
      _type = "proto"
      _init = function (self, arg, ...)
        if type (arg) == "table" then
          mapfields (self, arg)
        else
          -- non-table instantiation code
        end
      end,
    }
    new = Proto (str, #str)
    Derived = proto { _type = "Derived", ... }
    ```

  - Much faster object cloning; `mapfields` is in imperative style and
    makes one pass over each table it looks at, where previous releases
    used functional style (stack frame overhead) and multiple passes over
    input tables.

    On my 2013 Macbook Air with 1.3GHz Core i5 CPU, I can now create a
    million std.objects with several assorted fields in 3.2s.  Prior to
    this release, the same process took 8.15s... and even release 34.1,
    with drastically simpler Objects (19SLOC vs over 120) took 5.45s.

  - `std.object.prototype` is now almost an order of magnitude faster
    than previous releases, taking about 20% of the time it previously
    used to return its results.

  - `io.warn` and `io.die` now integrate properly with `std.optparse`,
     provided you save the `opts` return from `parser:parse` back to the
     global namespace where they can access it:

    ```lua
    local OptionParser = require "std.optparse"
    local parser = OptionParser "eg 0\nUsage: eg\n"
    _G.arg, _G.opts = parser:parse (_G.arg)
    if not _G.opts.keep_going then
      require "std.io".warn "oh noes!"
    end
    ```

    will, when run, output to stderr: "eg: oh noes!"

### Bug fixes

  - Much improved documentation for `optparse`, so you should be able
    to use it without reading the source code now!

  - `io.warn` and `io.die` no longer output a line-number when there is
    no file name to append it to.

  - `io.warn` and `io.die` no longer crash in the absence of a global
    `prog` table.

  - `string.split` no longer goes into an infinite loop when given an
    empty separator string.

  - Fix `getmetatable (container._functions) == getmetatable (container)`,
    which made tostring on containers misbehave, among other latent bugs.

  - `_functions` is never copied into a metatable now, finally solving
    the conflicted concerns of needing metatables to be shared between
    all objects of the same `_type` (for `__lt` to work correctly for one
    thing) and not leaving a dangling `_functions` list in the metatable
    of cloned objects, which could delete functions with matching names
    from subsequent clones.


## Noteworthy changes in release 37 (2014-01-19) [stable]

### New features

  - Lazy loading of submodules into `std` on first reference.  On initial
    load, `std` has the usual single `version` entry, but the `__index`
    metatable will automatically require submodules on first reference:

    ```lua
   local std = require "std"
   local prototype = std.container.prototype
    ```

  - New `std.optparse` module: A civilised option parser.
    (L)Documentation distributed in doc/classes/std.optparse.html.

### Bug fixes

  - Modules no longer leak `new' and `proper_subset' into the global
    table.

  - Cloned `Object` and `Container` derived types are more aggressive
    about sharing metatables, where previously the metatable was copied
    unnecessarily the base object used `_functions` for module functions

  - The retracted release 36 changed the operand order of many `std.list`
    module functions unnecessarily.  Now that `_function` support is
    available, there's no need to be so draconian, so the original v35
    and earlier operand order works as before again.

  - `std.list.new`, `std.set.new`, `set.strbuf.new` and `std.tree.new`
    are available again for backwards compatibility.

  - LuaRocks install doesn't copy config.ld and config.ld to $docdir.

### Incompatible changes

  - `std.getopt` is no more. It appears to have no users, though if there
    is a great outcry, it should be easy to make a compatibility api over
    `std.optparse` in the next release.


## Noteworthy changes in release 36 (2014-01-16) [stable]

### New features

  - Modules have been refactored so that they can be safely
    required individually, and without loading themselves or any
    dependencies on other std modules into the global namespace.

  - Objects derived from the `std.object` prototype have a new
    <derived_object>:prototype () method that returns the contents of the
    new internal `_type` field.  This can be overridden during cloning
    with, e.g.:

    ```lua
    local Object = require "std.object"
    Prototype = Object { _type = "Prototype", <other_fields> }
    ```

  - Objects derived from the `std.object` prototype return a new table
    with a shallow copy of all non-private fields (keys that do not
    begin with "_") when passed to `table.totable` - unless overridden
    in the derived object's __totable field.

  - list and strbuf are now derived from `std.object`, which means that
    they respond to `object.prototype` with appropriate type names ("List",
    "StrBuf", etc.) and can be used as prototypes for further derived
    objects or clones; support object:prototype (); respond to totable etc.

  - A new Container module at `std.container` makes separation between
    container objects (which are free to use __index as a "[]" access
    metamethod, but) which have no object methods, and regular objects
    (which do have object methods, but) which cannot use the __index
    metamethod for "[]" access to object contents.

  - set and tree are now derived from `std.container`, so there are no
    object methods.  Instead there are a full complement of equivalent
    module functions.  Metamethods continue to work as before.

  - `string.prettytostring` always displays table elements in the same
    order, as provided by `table.sort`.

  - `table.totable` now accepts a string, and returns a list of the
    characters that comprise the string.

  - Can now be installed directly from a release tarball by `luarocks`.
    No need to run `./configure` or `make`, unless you want to install to
    a custom location, or do not use LuaRocks.

### Bug fixes

  - string.escape_pattern is now Lua 5.2 compatible.

  - all objects now reuse prototype metatables, as required for __le and
    __lt metamethods to work as documented.

### Deprecations

  - To avoid confusion between the builtin Lua `type` function and the
    method for finding the object prototype names, `std.object.type` is
    deprecated in favour of `std.object.prototype`. `std.object.type`
    continues to work for now, but might be removed from a future
    release.

    ```lua
    local prototype = (require 'std.object').prototype
    ```

    ...makes for more readable code, rather than confusion between the
    different flavours of `type`.

### Incompatible changes

  - Following on from the Grand Renaming™ change in the last release,
    `std.debug_ext`, `std.io_ext`, `std.math_ext`, `std.package_ext`,
    `std.string_ext` and `std.table_ext` no longer have the spurious
    `_ext` suffix.  Instead, you must now use, e.g.:

    ```lua
    local string = require "std.string"
    ```

    These names are now stable, and will be available from here for
    future releases.

  - The `std.list` module, as a consequence of returning a List object
    prototype rather than a table of functions including a constructor,
    now always has the list operand as the first argument, whether that
    function is called with `.` syntax or `:` syntax.  Functions which
    previously had the list operand in a different position when called
    with `.` syntax were: list.filter, list.foldl, list.foldr,
    list.index_key, list.index_value, list.map, list.map_with,
    list.project, list.shape and list.zip_with.  Calls made as object
    methods using `:` calling syntax are unchanged.

  - The `std.set` module is a `std.container` with no object methods,
    and now uses prototype functions instead:

    ```lua
    local union = Set.union (set1, set2)
    ```


## Noteworthy changes in release 35 (2013-05-06) [stable]

### New features

  - Move to the Slingshot release system.
  - Continuous integration from Travis automatically builds stdilb
    with Lua 5.1, Lua 5.2 and luajit-2.0 with every commit, which
    should help prevent future release breaking compatibility with
    one or another of those interpreters.

### Bug fixes

  - `std.package_ext` no longer overwrites the core `package` table,
    leaving the core holding on to memory that Lua code could no
    longer access.

### Incompatible changes

  - The Grand Renaming™ - everything now installs to $luaprefix/std/,
    except `std.lua` itself.  Importing individual modules now involves:

    ```lua
    local list = require "std.list"
    ```

    If you want to have all the symbols previously available from the
    global and core module namespaces, you will need to put them there
    yourself, or import everything with:

    ```lua
    require "std"
    ```

    which still behaves per previous releases.

    Not all of the modules work correctly when imported individually
    right now, until we figure out how to break some circular dependencies.


## Noteworthy changes in release 34.1 (2013-04-01) [stable]

  - This is a maintenance release to quickly fix a breakage in getopt
    from release v34.  Getopt no longer parses non-options, but stops
    on the first non-option... if a use case for the other method
    comes up, we can always add it back in.


## Noteworthy changes in release 34 (2013-03-25) [stable]

  - stdlib is moving towards supporting separate requirement of individual
    modules, without scribbling on the global environment; the work is not
    yet complete, but we're collecting tests along the way to ensure that
    once it is all working, it will carry on working;

  - there are some requirement loops between modules, so not everything can
    be required independently just now;

  - `require "std"` will continue to inject std symbols into the system
    tables for backwards compatibility;

  - stdlib no longer ships a copy of Specl, which you will need to install
    separately if you want to run the bundled tests;

  - getopt supports parsing of undefined options; useful for programs that
    wrap other programs;

  - getopt.Option constructor is no longer used, pass a plain Lua table of
    options, and getopt will do the rest;


## Noteworthy changes in release 33 (2013-07-27) [stable]

  - This release improves stability where Specl has helped locate some
    corner cases that are now fixed.

  - `string_ext.wrap` and `string_ext.tfind` now diagnose invalid arguments.

  - Specl code coverage is improving.

  - OrdinalSuffix improvements.

  - Use '%' instead of math.mod, as the latter does not exist in Lua 5.2.

  - Accept negative arguments.


## Noteworthy changes in release 32 (2013-02-22) [stable]

  - This release fixes a critical bug preventing getopt from returning
    anything in getopt.opt.  Gary V. Vaughan is now a co-maintainer, currently
    reworking the sources to use (Lua 5.1 compatible) Lua 5.2 style module
    packaging, which requires you to assign the return values from your imports:

    ```lua
    getopt = require "getopt"
    ```

  - Extension modules, table_ext, package_ext etc. return the unextended module
    table before injecting additional package methods, so you can ignore those
    return values or save them for programatically backing out the changes:

    ```lua
    table_unextended = require "table_ext"
    ```

  - Additionally, Specl (see http://github.com/gvvaughan/specl/) specifications
    are being written for stdlib modules to help us stop accidentally breaking
    things between releases.


## Noteworthy changes in release 31 (2013-02-20) [stable]

  - This release improves the list module: lists now have methods, list.slice
    is renamed to list.sub (the old name is provided as an alias for backwards
    compatibility), and all functions that construct a new list return a proper
    list, not a table. As a result, it is now often possible to write code that
    works on both lists and strings.


## Noteworthy changes in release 30 (2013-02-17) [stable]

  - This release changes some modules to be written in a Lua 5.2 style (but
    not the way they work with 5.1). Some fixes and improvements were made to
    the build system. Bugs in the die function, the parser module, and a nasty
    bug in the set module introduced in the last release (29) were fixed.


## Noteworthy changes in release 29 (2013-02-06) [stable]

  - This release overhauls the build system to have LuaRocks install releases
    directly from git rather than from tarballs, and fixes a bug in set (issue
    #8).


## Noteworthy changes in release 28 (2012-10-28) [stable]

  - This release improves the documentation and build system, and improves
    require_version to work by default with more libraries.


## Noteworthy changes in release 27 (2012-10-03) [stable]

  - This release changes getopt to return all arguments in a list, rather than
    optionally processing them with a function, fixes an incorrect definition
    of set.elems introduced in release 26, turns on debugging by default,
    removes the not-very-useful string.gsubs, adds constructor functions for
    objects, renames table.rearrange to the more descriptive table.clone_rename
    and table.indices to table.keys, and makes table.merge not clone but modify
    its left-hand argument. A function require_version has been added to allow
    version constraints on a module being required. Gary Vaughan has
    contributed a memoize function, and minor documentation and build system
    improvements have been made. Usage information is now output to stdout, not
    stderr. The build system has been fixed to accept Lua 5.2. The luarock now
    installs documentation, and the build command used is now more robust
    against previous builds in the same tree.


## Noteworthy changes in release 26 (2012-02-18) [stable]

  - This release improves getoptâs output messages and conformance to
    standard practice for default options. io.processFiles now unsets prog.file
    when it finishes, so that a program can tell when itâs no longer
    processing a file. Three new tree iterators, inodes, leaves and ileaves,
    have been added; the set iterator set.elements (renamed to set.elems for
    consistency with list.elems) is now leaves rather than pairs. tree indexing
    has been made to work in more circumstances (thanks, Gary Vaughan).
    io.writeline is renamed io.writelines for consistency with io.readlines and
    its function. A slurping function, io.slurp, has been added. Strings now
    have a __concat metamethod.


## Noteworthy changes in release 25 (2011-09-19) [stable]

  - This release adds a version string to the std module and fixes a buglet in
    the build system.


## Noteworthy changes in release 24 (2011-09-19) [stable]

  - This release fixes a rename missing from release 23, and makes a couple of
    fixes to the new build system, also from release 23.


## Noteworthy changes in release 23 (2011-09-17) [stable]

  - This release removes the posix_ext module, which is now part of luaposix,
    renames string.findl to string.tfind to be the same as lrexlib, and
    autotoolizes the build system, as well as providing a rockspec file.


## Noteworthy changes in release 22 (2011-09-02) [stable]

  - This release adds two new modules: strbuf, a trivial string buffers
    implementation, which is used to speed up the stdlib tostring method for
    tables, and bin, which contains a couple of routines for converting binary
    data into numbers and strings. Some small documentation and build system
    fixes have been made.


## Noteworthy changes in release 21 (2011-06-06) [stable]

  - This release converts the documentation of stdlib to LuaDoc, adds an
    experimental Lua 5.2 module "fstable", for storing tables directly on
    disk as files and directories, and fixes a few minor bugs (with help from
    David Favro).

  - This release has been tested lightly on Lua 5.2 alpha, but is not
    guaranteed to work fully.


## Noteworthy changes in release 20 (2011-04-14) [stable]

  - This release fixes a conflict between the global _DEBUG setting and the use
    of strict.lua, changes the argument order of some list functions to favour
    OO-style use, adds posix.euidaccess, and adds OO-style use to set. mk1file
    can now produce a single-file version of a user-supplied list of modules,
    not just the standard set.


## Noteworthy changes in release 19 (2011-02-26) [stable]

  - This release puts the package.config reflection in a new package_ext
    module, where it belongs. Thanks to David Manura for this point, and for a
    small improvement to the code.


## Noteworthy changes in release 18 (2011-02-26) [stable]

  - This release provides named access to the contents of package.config, which
    is undocumented in Lua 5.1. See luaconf.h and the Lua 5.2 manual for more
    details.


## Noteworthy changes in release 17 (2011-02-07) [stable]

  - This release fixes two bugs in string.pad (thanks to Bob Chapman for the
    fixes).


## Noteworthy changes in release 16 (2010-12-09) [stable]

  - Adds posix module, using luaposix, and makes various other small fixes and
    improvements.


## Noteworthy changes in release 15 (2010-06-14) [stable]

  - This release fixes list.foldl, list.foldr, the fold iterator combinator and
    io.writeLine. It also simplifies the op table, which now merely sugars the
    built-in operators rather than extending them. It adds a new tree module,
    which subsumes the old table.deepclone and table.lookup functions.
    table.subscript has become op["[]"], and table.subscripts has been removed;
    the old treeIter iterator has been simplified and generalised, and renamed
    to nodes. The mk1file script and std.lua library loader have had the module
    list factored out into modules.lua. strict.lua from the Lua distribution is
    now included in stdlib, which has been fixed to work with it. Some minor
    documentation and other code improvements and fixes have been made.


## Noteworthy changes in release 14 (2010-06-07) [stable]

  - This release makes stdlib compatible with strict.lua, which required a
    small change to the debug_ext module. Some other minor changes have also
    been made to that module. The table.subscripts function has been removed
    from the table_ext.lua.


## Noteworthy changes in release 13 (2010-06-02) [stable]

  - This release removes the lcs module from the standard set loaded by
    "std", removes an unnecessary definition of print, and tidies up the
    implementation of the "op" table of functional versions of the infix
    operators and logical operators.


## Noteworthy changes in release 12 (2009-09-07) [stable]

  - This release removes io.basename and io.dirname, which are now available in
    lposix, and the little-used functions addSuffix and changeSuffix which
    dependend on them. io.pathConcat is renamed to io.catdir and io.pathSplit
    to io.splitdir, making them behave the same as the corresponding Perl
    functions. The dependency on lrexlib has been removed along with the rex
    wrapper module. Some of the more esoteric and special-purpose modules
    (mbox, xml, parser) are no longer loaded by 'require "std"'.

    This leaves stdlib with no external dependencies, and a rather more
    coherent set of basic modules.


## Noteworthy changes in release 11 (2009-03-15) [stable]

  - This release fixes a bug in string.format, removes the redundant
    string.join (it's the same as table.concat), and adds to table.clone and
    table.deepclone the ability to copy without metatables. Thanks to David
    Kantowitz for pointing out the various deficiencies.


## Noteworthy changes in release 10 (2009-03-13) [stable]

  - This release fixes table.deepclone to copy metatables, as it should.
    Thanks to David Kantowitz for the fix.


## Noteworthy changes in release 9 (2009-02-19) [stable]

  - This release updates the object module to be the same as that published
    in "Lua Gems", and fixes a bug in the utility mk1file which makes a
    one-file version of the library, to stop it permanently redefining require.


## Noteworthy changes in release 8 (2008-09-04) [stable]

  - This release features fixes and improvements to the set module; thanks to
    Jiutian Yanling for a bug report and suggestion which led to this work.


## Noteworthy changes in release 7 (2008-09-04) [stable]

  - just a bug fix


## Noteworthy changes in release 6 (2008-07-28) [stable]

  - This release rewrites the iterators in a more Lua-ish 5.1 style.


## Noteworthy changes in release 5 (2008-03-04) [stable]

  - I'm happy to announce a new release of my standard Lua libraries. It's been
    nearly a year since the last release, and I'm happy to say that since then
    only one bug has been found (thanks Roberto!). Two functions have been
    added in this release, to deal with file paths, and one removed (io.length,
    which is handled by lfs.attributes) along with one constant (INTEGER_BITS,
    handled by bitlib's bit.bits).

  - For those not familiar with stdlib, it's a pure-Lua library of mostly
    fundamental data structures and algorithms, in particular support for
    functional and object-oriented programming, string and regex operations and
    extensible pretty printing of data structures. More specific modules
    include a getopt implementation, a generalised least common subsequences
    (i.e. diff algorithm) implementation, a recursive-descent parser generator,
    and an mbox parser.

  - It's quite a mixed bag, but almost all written for real projects. It's
    written in a doc-string-ish style with the supplied very simple ldoc tool.

  - I am happy with this code base, but there are various things it could use:

    0. Tests. Tests. Tests. The code has no unit tests. It so needs them.

    1. More code. Nothing too specialised (unless it's too small to be released
       on its own, although very little seems "too small" in the Lua
       community). Anything that either has widespread applicability (like
       getopt) or is very general (data structures, algorithms, design
       patterns) is good.

    2. Refactoring. The code is not ideally factored. At the moment it is
       divided into modules that extend existing libraries, and new modules
       constructed along similar lines, but I think that some of the divisions
       are confusing. For example, the functional programming support is spread
       between the list and base modules, and would probably be better in its
       own module, as those who aren't interested in the functional style won't
       want the functional list support or the higher-order functions support,
       and those who want one will probably want the other.

    3. Documentation work. There's not a long wrong with the existing
       documentation, but it would be nice, now that there is a stable LuaDoc,
       to use that instead of the built-in ldoc, which I'm happy to discard now
       that LuaDoc is stable. ldoc was always designed as a minimal LuaDoc
       substitute in any case.

    4. Maintenance and advocacy. For a while I have been reducing my work on
       Lua, and am also now reducing my work in Lua. If anyone would like to
       take on stdlib, please talk to me. It fills a much-needed function: I
       suspect a lot of Lua programmers have invented the wheels with which it
       is filled over and over again. In particular, many programmers could
       benefit from the simplicity of its simple and well-designed functional,
       string and regex capabilities, and others will love its comprehensive
       getopt.


## Noteworthy changes in release 4 (2007-04-26) [beta]

  - This release removes the dependency on the currently unmaintained lposix
    library, includes pre-built HTML documentation, and fixes some 5.0-style
    uses of variadic arguments.

    Thanks to Matt for pointing out all these problems. stdlib is very much
    user-driven at the moment, since it already does everything I need, and I
    don't have much time to work on it, so do please contact me if you find
    bugs or problems or simply don't understand it, as the one thing I *do*
    want to do is make it useful and accessible!


## Noteworthy changes in release 3 (2007-02-25) [beta]

  - This release fixes the "set" and "lcs" (longest common subsequence, or
    "grep") libraries, which were broken, and adds one or two other bug and
    design fixes. Thanks are due to Enrico Tassi for pointing out some of the
    problems.


## Noteworthy changes in release 2 (2007-01-05) [beta]

  - This release includes some bug fixes, and compatibility with lrexlib 2.0.


## Noteworthy changes in release 1 (2011-09-02) [beta]

  - It's just a snapshot of CVS, but it's pretty stable at the moment; stdlib,
    until such time as greater interest or participation enables (or forces!)
    formal releases will be in permanent beta, and tracking CVS is recommended.
