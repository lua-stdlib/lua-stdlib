-- Parser generator

import "std.object"
import "std.io.io"


-- A parser is created by
--
--     p = Parser {grammar}
--
-- and called with
--
--     result = p:parse (start_token, token_list[, from])
--
-- where start_token is the non-terminal at which to start parsing in
-- the grammar, token_list is a list of tokens of the form
--
--     {ty = "token_type", tok = "token_text"}
--
-- and from is the token in the list from which to start (the default
-- value is 1).
--
-- The output of the parser is a tree, each of whose
-- nodes is of the form:
--
--     {ty = symbol, node_1 = tree_1, node_2 = tree_2, ...[list]}
--
-- where each node_i is a symbolic name, and list is the list of
-- subtrees returned if the corresponding token was a list token.
--
-- A grammar is a table of rules of the form
--
--     non-terminal = {production_1, production_2, ...}
--
-- plus a special item
--
--     lexemes = Set {"class_1", "class_2", ...}
--
-- Each production gives a form that a non-terminal may take. A
-- production has the form
--
--     production = {"token_1", "token_2", ...,
--                   [_action = action_function;]
--                   [abstract_1, abstract_2, ...]}
--
-- A production
--
--   * must not start with the non-terminal being defined (it must not
--     be left-recursive)
--   * must not be a prefix of a later production in the same
--     non-terminal
--
-- Each token may be
--
--   * a non-terminal, i.e. a token defined by the grammar
--      * an optional symbol is indicated by the suffix "_opt"
--      * a list is indicated by the suffix "_list", and may be
--        followed by "_<separator-symbol>" (default is
--        whitespace-separated)
--   * a lexeme class
--   * something else, which is taken as a literal string to match
--
-- action_function is an optional action that is performed before the
-- abstract syntax rules, of the form
--
--     function (tree, token, pos)
--       ...
--       return tree_
--     end
--
-- It is passed the parse tree for the current node, the token list,
-- and the current position in the token list, and returns a new parse
-- tree.
--
-- Each abstract syntax rule is of the form
--
--     name = result
--
-- where result can be
--
--   * a number i, which is replaced by the parse tree for the ith
--     token in the production
--   * a function, which is passed the list of parse trees for the
--     entire production and the token list, and returns a parse tree
--
-- If a production has no abstract syntax rules, the result is just
-- a list of subtrees.


Parser = Object {_init = {"grammar"}}


function Parser:_clone (values)
  local grammar = table.permute (self._init, values)
  -- Collect up the abstract syntax rules
  for _, rule in ipairs (grammar) do
    rule._abstract = {}
    for i, v in pairs (rule) do
      if type (i) == "string" then
        rule._abstract[i] = v
      end
    end
  end
  local object = table.merge (self, grammar)
  return setmetatable (object, object)
end

-- @func Parser:parse: Parse a token list
--   @param start: the token at which to start
--   @param token: the list of tokens
-- @returns
--   @param tree: parse tree
function Parser:parse (start, token, from)

  local grammar = self.grammar -- for consistency and brevity
  local rule, symbol -- functions called before they are defined
  
  -- @func Parser:optional: Try to parse an optional symbol
  --   @param sym: the symbol being tried
  --   @param from: the index of the token to start from
  -- @returns
  --   @param tree: the resulting parse tree, or nil if empty
  --   @param to: the index of the first unused token, or false to
  --     indicate failure
  local function optional (sym, from)
    local tree, to = symbol (sym, from)
    if to then
      return tree, to
    else
      return nil, from
    end
  end

  -- @func Parser:list: Try to parse a list of symbols
  --   @param sym: the symbol being tried
  --   @param sep: the list separator
  --   @param from: the index of the token to start from
  -- @returns
  --   @param tree: the resulting parse tree, or nil if empty
  --   @param to: the index of the first unused token, or false to
  --     indicate failure
  local function list (sym, sep, from)
    local tree, to
    tree, from = symbol (sym, from)
    local ty = sym .. "_list"
    if sep ~= "" then
      ty = ty .. "_" .. sep
    end
    local list = {ty = ty, tree}
    if from == false then
      return list, false
    end
    to = from
    repeat
      if sep ~= "" then
        tree, from = symbol (sep, from)
      end
      if from then
        tree, from = symbol (sym, from)
        if from then
          table.insert (list, tree)
          to = from
        end
      end
    until from == false
    return list, to
  end

  -- @func symbol: Try to parse a given symbol
  --   @param sym: the symbol being tried
  --   @param from: the index of the token to start from
  -- @returns
  --   @param tree: the resulting parse tree, or nil if empty
  --   @param to: the index of the first unused token, or false to
  --     indicate failure
  symbol = function (sym, from) -- declared at the top
    if string.sub (sym, -4, -1) == "_opt" then -- optional symbol
      return optional (string.sub (sym, 1, -5), from)
    elseif string.find (sym, "_list.-$") then -- list
      local _, _, subsym, sep = string.find (sym, "^(.*)_list_?(.-)$")
      return list (subsym, sep, from)
    elseif grammar[sym] then -- non-terminal
      return rule (sym, from)
    elseif token[from] and -- not end of token list
      ((grammar.lexemes[sym] and sym == token[from].ty) or
       -- lexeme
       sym == token[from].tok) -- literal terminal
    then
      return token[from], from + 1 -- advance to next token
    else
      return nil, false
    end
  end

  -- @func production: Try a production
  --   @param name: the name of the current rule
  --   @param prod: the production (list of symbols) being tried
  --   @param from: the index of the token to start from
  -- @returns
  --   @param tree: the parse tree (incomplete if to is false)
  --   @param to: the index of the first unused token, or false to
  --     indicate failure
  local function production (name, prod, from)
    local tree = {ty = name}
    local to = from

    -- Convert concrete to abstract syntax
    local function abstract ()
      local ntree = {}
      for i, v in pairs (prod._abstract) do
        if type (v) == "number" then
          ntree[i] = tree[v]
        elseif type (v) == "function" then
          ntree[i] = v (tree, token)
        else
          die ("bad abstract syntax rule of type " .. type (v))
        end
      end
      return ntree
    end

    for _, prod in ipairs (prod) do
      local sym
      sym, to = symbol (prod, to)
      if to then
        table.insert (tree, sym)
      else
        return tree, false
      end
    end
    if prod._action then
      tree = prod._action (tree, token, to)
    end
    if prod._abstract then
      tree = abstract ()
    end
    return tree, to
  end

  -- @func rule: Parse according to a particular rule
  --   @param name: the name of the rule to try
  --   @param from: the index of the token to start from
  -- @returns
  --   @param tree: parse tree
  --   @param to: the index of the first unused token, or false to
  --     indicate failure
  rule = function (name, from) -- declared at the top
    local alt = grammar[name]
    local tree, to
    for _, alt in ipairs (alt) do
      tree, to = production (name, alt, from)
      if to then
        return tree, to
      end
    end
    return tree, false
  end

  return rule (start, 1, from or 1)
end
