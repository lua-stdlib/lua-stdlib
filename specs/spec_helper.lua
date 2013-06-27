-- Not local, so that it is available in spec examples.
totable = (require "std.table").totable


-- Custom matcher for set membership.

local set      = require "std.set"
local util     = require "specl.util"
local matchers = require "specl.matchers"

local Matcher, matchers, q =
      matchers.Matcher, matchers.matchers, matchers.stringify

matchers.have_member = Matcher {
  function (actual, expect)
    return set.member (actual, expect)
  end,

  actual = "set",

  format_expect = function (expect)
    return " a set containing " .. q (expect) .. ", "
  end,

  format_any_of = function (alternatives)
    return " a set containing any of " ..
           util.concat (alternatives, util.QUOTED) .. ", "
  end,
}
