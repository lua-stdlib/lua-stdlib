{["specify package_ext"] = {
  before = function ()
    unextended = require "package_ext"
  end,

  {["context when requiring the module"] = {
    before = function ()
      -- don't try to check all the entries in unextended package,
      -- because they naturally change as modules are loaded.
      apis = { "config", "cpath", "loaders", "loadlib", "preload",
               "searchers", "searchpath", "seeall" }
    end,

    {["it returns the unextended package table"] = function ()
      expect (unextended.config).should_be (package.config)
      expect (unextended.dirsep).should_be (nil)
      expect (unextended.pathsep).should_be (nil)
      expect (unextended.path_mark).should_be (nil)
      expect (unextended.execdir).should_be (nil)
      expect (unextended.igmark).should_be (nil)
    end},
    {["it splits package.config up"] = function ()
      expect (string.format ("%s\n%s\n%s\n%s\n%s\n",
              package.dirsep, package.pathsep, package.path_mark, package.execdir, package.igmark)
      ).should_be (package.config)
    end},
    {["it doesn't override any other module access points"] = function ()

      for _, api in ipairs (apis) do
        expect (package[api]).should_be (unextended[api])
      end
    end},
  }},
}}
