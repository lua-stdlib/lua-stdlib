-- Parser generator

require "std/patch40.lua"
require "std/data/object.lua"
require "std/io/io.lua"


-- A grammar is a list of rules:
--   non-terminal = {list of alternative productions}

-- Production lists must not be left-recursive (i.e. start with the
-- non-terminal being defined)

-- A production must not be a prefix of a later production in the same
-- list

-- Each production is a list of non-terminals and terminals

-- An optional symbol is indicated by the suffix "_opt"

-- A list is indicated by the suffix "_list", and may be followed by
-- "_<separator-symbol>"

-- Terminals are undefined symbols

-- The element lexemes is a set of token classes; terminals not
-- appearing in this list are literal strings

-- A production may have an action, which is passed the parse tree on
-- successful completion of the production, and returns a modified
-- parse tree

-- The input to the parser is a token list; each token is of the form
-- {ty = "token_type", tok = "token_text"}.

-- The output of the parser is a tree of {ty = symbol; contents...}

-- A parser is created by p = Parser {grammar, token}, and called with
-- tree = p:parseRule (symbol, from). The resulting tree may be passed
-- to Parser.prettyPrint.


Parser = Object {_init = {"grammar", "token"}}


-- parseOpt: Try to parse an optional symbol
--   sym: the symbol being tried
--   from: the index of the token to start from
-- returns
--   tree: the resulting parse tree, or nil if empty
--   to: the index of the first unused token, or nil to indicate
--     failure
function Parser:parseOpt (sym, from)
  local tree, to = self:parseSym (sym, from)
  if to then
    return tree, to
  else
    return nil, from
  end
end

-- parseList: Try to parse a list of symbols
--   sym: the symbol being tried
--   sep: the list separator
--   from: the index of the token to start from
-- returns
--   tree: the resulting parse tree, or nil if empty
--   to: the index of the first unused token, or nil to indicate
--     failure
function Parser:parseList (sym, sep, from)
  local tree, to
  tree, from = self:parseSym (sym, from)
  local ty = sym .. "_list"
  if sep ~= "" then
    ty = ty .. "_" .. sep
  end
  local list = {ty = ty; tree}
  if from == nil then
    return list, nil
  end
  to = from
  repeat
    if sep ~= "" then
      tree, from = self:parseSym (sep, from)
    end
    if from then
      tree, from = self:parseSym (sym, from)
      if from then
        tinsert (list, tree)
        to = from
      end
    end
  until from == nil
  return list, to
end

-- parseSym: Try to parse a given symbol
--   sym: the symbol being tried
--   from: the index of the token to start from
-- returns
--   tree: the resulting parse tree, or nil if empty
--   to: the index of the first unused token, or nil to indicate
--     failure
function Parser:parseSym (sym, from)
  if strsub (sym, -4, -1) == "_opt" then -- optional symbol
    return self:parseOpt (strsub (sym, 1, -5), from)
  elseif strfind (sym, "_list.-$") then -- list
    local _, _, subsym, sep = strfind (sym, "^(.*)_list_?(.-)$")
    return self:parseList (subsym, sep, from)
  elseif self.grammar[sym] then -- non-terminal
    return self:parseRule (sym, from)
  elseif self.token[from] and -- not end of token list
    ((self.grammar.lexemes[sym] and sym == self.token[from].ty) or
     -- lexeme
     sym == self.token[from].tok) -- literal terminal
  then
    return self.token[from], from + 1 -- advance to next token
  else
    return nil, nil
  end
end

-- parseProd: Try a production
--   name: the name of the current rule
--   prod: the production (list of symbols) being tried
--   from: the index of the token to start from
-- returns
--   tree: the parse tree (incomplete if to is nil)
--   to: the index of the first unused token, or nil to indicate
--     failure
function Parser:parseProd (name, prod, from)
  local tree = {ty = name}
  local to = from
  for i = 1, getn (prod) do
    local sym
    sym, to = self:parseSym (prod[i], to)
    if to then
      tinsert (tree, sym)
    else
      return tree, nil
    end
  end
  if prod.action then
    tree = prod.action (tree, self.token)
  end
  return tree, to
end

-- parseRule: Parse according to a particular rule
--   name: the name of the rule to try
--   from: the index of the token to start from
-- returns
--   tree: parse tree
--   to: the index of the first unused token, or nil to indicate
--     failure
function Parser:parseRule (name, from)
  local alt = self.grammar[name]
  local tree, to
  for i = 1, getn (alt) do
    tree, to = self:parseProd (name, alt[i], from)
    if to then
      return tree, to
    end
  end
  return tree, nil
end

-- prettyPrint: Pretty print a parse tree
--   tree: the tree to print
--   indent: the string to prefix each line with
function Parser.prettyPrint (tree, indent)
  if tree then
    if tree.tok then
      writeLine (indent .. tree.ty .. "=" .. tree.tok)
    else
      writeLine (indent .. tree.ty)
      for i = 1, getn (tree) do
        Parser.prettyPrint (tree[i], indent .. "  ")
      end
    end
  end
end
