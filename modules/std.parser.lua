-- Parser generator

import "std.object"
import "std.io.io"


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


-- @func Parser:parseOpt: Try to parse an optional symbol
--   @param sym: the symbol being tried
--   @param from: the index of the token to start from
-- @returns
--   @param tree: the resulting parse tree, or false if empty
--   @param to: the index of the first unused token, or false to
--     indicate failure
function Parser:parseOpt (sym, from)
  local tree, to = self:parseSym (sym, from)
  if to then
    return tree, to
  else
    return false, from
  end
end

-- @func parseList: Try to parse a list of symbols
--   @param sym: the symbol being tried
--   @param sep: the list separator
--   @param from: the index of the token to start from
-- @returns
--   @param tree: the resulting parse tree, or false if empty
--   @param to: the index of the first unused token, or false to
--     indicate failure
function Parser:parseList (sym, sep, from)
  local tree, to
  tree, from = self:parseSym (sym, from)
  local ty = sym .. "_list"
  if sep ~= "" then
    ty = ty .. "_" .. sep
  end
  local list = {ty = ty; tree}
  if from == false then
    return list, false
  end
  to = from
  repeat
    if sep ~= "" then
      tree, from = self:parseSym (sep, from)
    end
    if from then
      tree, from = self:parseSym (sym, from)
      if from then
        table.insert (list, tree)
        to = from
      end
    end
  until from == false
  return list, to
end

-- @func parseSym: Try to parse a given symbol
--   @param sym: the symbol being tried
--   @param from: the index of the token to start from
-- @returns
--   @param tree: the resulting parse tree, or false if empty
--   @param to: the index of the first unused token, or false to
--     indicate failure
function Parser:parseSym (sym, from)
  if string.sub (sym, -4, -1) == "_opt" then -- optional symbol
    return self:parseOpt (string.sub (sym, 1, -5), from)
  elseif string.find (sym, "_list.-$") then -- list
    local _, _, subsym, sep = string.find (sym, "^(.*)_list_?(.-)$")
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
    return false, false
  end
end

-- @func parseProd: Try a production
--   @param name: the name of the current rule
--   @param prod: the production (list of symbols) being tried
--   @param from: the index of the token to start from
-- @returns
--   @param tree: the parse tree (incomplete if to is false)
--   @param to: the index of the first unused token, or false to
--     indicate failure
function Parser:parseProd (name, prod, from)
  local tree = {ty = name}
  local to = from
  for _, prod in ipairs (prod) do
    local sym
    sym, to = self:parseSym (prod, to)
    if to then
      table.insert (tree, sym)
    else
      return tree, false
    end
  end
  if prod.action then
    tree = prod.action (tree, self.token)
  end
  return tree, to
end

-- @func parseRule: Parse according to a particular rule
--   @param name: the name of the rule to try
--   @param from: the index of the token to start from
-- @returns
--   @param tree: parse tree
--   @param to: the index of the first unused token, or false to
--     indicate failure
function Parser:parseRule (name, from)
  local alt = self.grammar[name]
  local tree, to
  for _, alt in ipairs (alt) do
    tree, to = self:parseProd (name, alt, from)
    if to then
      return tree, to
    end
  end
  return tree, false
end

-- @func prettyPrint: Pretty print a parse tree
--   @param tree: the tree to print
--   @param indent: the string to prefix each line with
function Parser.prettyPrint (tree, indent)
  if tree then
    if tree.tok then
      io.writeLine (indent .. tree.ty .. "=" .. tree.tok)
    else
      io.writeLine (indent .. tree.ty)
      for _, v in ipairs (tree) do
        Parser.prettyPrint (v, indent .. "  ")
      end
    end
  end
end
