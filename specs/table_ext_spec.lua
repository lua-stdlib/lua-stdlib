{["specify table_ext"] = {
  before = function ()
    unextended = require "table_ext"
  end,


  {["describe table.clone ()"] = {
    before = function ()
      subject = { k1 = {"v1"}, k2 = {"v2"}, k3 = {"v3"} }
      f       = table.clone
    end,

    {["it does not just return the subject"] = function ()
      expect (f (subject)).should_not_be (subject)
    end},
    {["it does copy the subject"] = function ()
      expect (f (subject)).should_equal (subject)
    end},
    {["it only makes a shallow copy"] = function ()
      expect (f (subject).k1).should_be (subject.k1)
    end},
    {["the original subject is not perturbed"] = function ()
      target = { k1 = subject.k1, k2 = subject.k2, k3 = subject.k3 }
      copy   = f (subject)
      expect (subject).should_equal (target)
      expect (subject).should_be (subject)
    end},
    {["it diagnoses non-table arguments"] = function ()
      expect ("table expected").should_error (f, nil)
      expect ("table expected").should_error (f, "foo")
    end},
  }},


  {["describe table.clone_rename()"] = {
    before = function ()
      subject = { k1 = {"v1"}, k2 = {"v2"}, k3 = {"v3"} }
      f       = table.clone_rename
    end,

    {["it does not just return the subject"] = function ()
      expect (f ({}, subject)).should_not_be (subject)
    end},
    {["it copies the subject"] = function ()
      expect (f ({}, subject)).should_equal (subject)
    end},
    {["it only makes a shallow copy"] = function ()
      expect (f ({}, subject).k2).should_be (subject.k2)
    end},
    {["context when renaming some keys"] = {
      before = function ()
        target = { newkey = subject.k1, k2 = subject.k2, k3 = subject.k3 }
      end,

      {["it renames during cloning"] = function ()
        expect (f ({k1 = "newkey"}, subject)).should_equal (target)
      end},
      {["it does not perturb the value in the renamed key field"] = function ()
        expect (f ({k1 = "newkey"}, subject).newkey).should_be (subject.k1)
      end},
    }},
    {["it diagnoses non-table arguments"] = function ()
      expect ("table expected").should_error (f, {}, nil)
      expect ("table expected").should_error (f, {}, "foo")
    end},
  }},


  {["describe table.empty ()"] = {
    before = function ()
      f = table.empty
    end,

    {["it returns true for an empty table"] = function ()
      expect (f {}).should_be (true)
      expect (f {nil}).should_be (true)
    end},
    {["it returns false for a non-empty table"] = function ()
      expect (f {"stuff"}).should_be (false)
      expect (f {{}}).should_be (false)
      expect (f {false}).should_be (false)
    end},
    {["it diagnoses non-table arguments"] = function ()
      expect ("table expected").should_error (f, nil)
      expect ("table expected").should_error (f, "foo")
    end},
  }},


  {["describe table.invert ()"] = {
    before = function ()
      subject = { k1 = 1, k2 = 2, k3 = 3 }
      f       = table.invert
    end,

    {["it returns a new table"] = function ()
      expect (f (subject)).should_not_be (subject)
    end},
    {["it inverts keys and values in the returned table"] = function ()
      expect (f (subject)).should_equal { "k1", "k2", "k3" }
    end},
    {["it is reversible"] = function ()
      expect (f (f (subject))).should_equal (subject)
    end},
    {["it seems to copy a list of 1..n numbers"] = function ()
      subject = { 1, 2, 3 }
      expect (f (subject)).should_equal (subject)
      expect (f (subject)).should_not_be (subject)
    end},
    {["it diagnoses non-table arguments"] = function ()
      expect ("table expected").should_error (f, nil)
      expect ("table expected").should_error (f, "foo")
    end},
  }},


  {["describe table.keys ()"] = {
    before = function ()
      subject = { k1 = 1, k2 = 2, k3 = 3 }
      f       = table.keys
    end,

    {["it returns an empty list when subject is empty"] = function ()
      expect (f {}).should_equal {}
    end},
    {["it makes a list of table keys"] = function ()
      cmp = function (a, b) return a < b end
      expect (table.sort (f (subject), cmp)).should_equal {"k1", "k2", "k3"}
    end},
    {["it does not guarantee stable ordering"] = function ()
      subject = {}
      -- is this a good test? there's a vanishingly small possibility the
      -- returned table will have all 10000 keys in the same order...
      for i = 10000, 1, -1 do table.insert (subject, i) end
      expect (f (subject)).should_not_equal (subject)
    end},
    {["it diagnoses non-table arguments"] = function ()
      expect ("table expected").should_error (f, nil)
      expect ("table expected").should_error (f, "foo")
    end},
  }},


  {["describe table.merge ()"] = {
    before = function ()
      -- Additional merge keys which are moderately unusual
      t1 = { k1 = {"v1"}, k2 = "if", k3 = {"?"} }
      t2 = { ["if"] = true, [{"?"}] = false, _ = "underscore", k3 = t1.k1 }
      f  = table.merge

      target = {}
      for k, v in pairs (t1) do target[k] = v end
      for k, v in pairs (t2) do target[k] = v end
    end,

    {["it doesn't create a whole new table"] = function ()
      expect (f (t1, t2)).should_be (t1)
    end},
    {["it doesn't change t1, if t2 is empty"] = function ()
      expect (f (t1, {})).should_be (t1)
    end},
    {["it copies t2, if t1 is empty"] = function ()
      expect (f ({}, t1)).should_not_be (t1)
      expect (f ({}, t1)).should_equal (t1)
    end},
    {["it merges keys from t2 into t1"] = function ()
      expect (f (t1, t2)).should_equal (target)
    end},
    {["it gives precedence to values from t2"] = function ()
      original = table.clone (t1)
      m = f (t1, t2)      -- Merge is destructive, do it once only.
      expect (m.k3).should_be (t2.k3)
      expect (m.k3).should_not_be (original.k3)
    end},
    {["it diagnoses non-table arguments"] = function ()
      expect ("table expected").should_error (f, nil, nil)
      expect ("table expected").should_error (f, "foo", "bar")
    end},
  }},


  {["describe table.new ()"] = {
    before = function ()
      f = table.new
    end,

    {["context when not setting a default "] = {
      before = function ()
        default = nil
      end,

      {["it returns a new table when nil is passed"] = function ()
        expect (f (default, nil)).should_equal {}
      end},
      {["it returns any table passed in"] = function ()
        t = { "unique table" }
        expect (f (default, t)).should_be (t)
      end},
    }},
    {["context when setting a default "] = {
      before = function ()
        default = "default"
      end,

      {["it returns a new table when nil is passed"] = function ()
        expect (f (default, nil)).should_equal {}
      end},
      {["it returns any table passed in"] = function ()
        t = { "unique table" }
        expect (f (default, t)).should_be (t)
      end},
    }},
    {["it returns the stored value for existing keys"] = function ()
      t = f ("default")
      v = { "unique value" }
      t[1] = v
      expect (t[1]).should_be (v)
    end},
    {["it returns the constructor default for unset keys"] = function ()
      t = f ("default")
      expect (t[1]).should_be "default"
    end},
    {["it returns the actual default object"] = function ()
      default = { "unique object" }
      t = f (default)
      expect (t[1]).should_be (default)
    end},
    {["it diagnoses non-tables/non-nil in the second argument"] = function ()
      expect ("table expected").should_error (f, nil, "foo")
    end},
  }},


  {["describe table.size ()"] = {
    before = function ()
      --          - 1 -  --------- 2 ----------  -- 3 --
      subject = { "one", { { "two" }, "three" }, four = 5 }
      f = table.size
    end,

    {["it counts the number of keys in a table"] = function ()
      expect (f (subject)).should_be (3)
    end},
    {["it counts no keys in an empty table"] = function ()
      expect (f {}).should_be (0)
    end},
    {["it diagnoses non-table arguments"] = function ()
      expect ("table expected").should_error (f, nil)
      expect ("table expected").should_error (f, "foo")
    end},
  }},


  {["describe table.sort ()"] = {
    before = function ()
      subject = { 5, 2, 4, 1, 0, 3 }
      target  = { 0, 1, 2, 3, 4, 5 }
      cmp     = function (a, b) return a < b end
      f       = table.sort
    end,

    {["it sorts elements in place"] = function ()
      f (subject, cmp)
      expect (subject).should_equal (target)
    end},
    {["it returns the sorted table"] = function ()
      expect (f (subject, cmp)).should_equal (target)
    end},
    {["it diagnoses non-table arguments"] = function ()
      expect ("table expected").should_error (f, nil)
      expect ("table expected").should_error (f, nil)
    end},
  }},

  
  {["describe table.values ()"] = {
    before = function ()
      subject = { k1 = {1}, k2 = {2}, k3 = {3} }
      f       = table.values
    end,

    {["it returns an empty list when subject is empty"] = function ()
      expect (f {}).should_equal {}
    end},
    {["it makes a list of table values"] = function ()
      cmp = function (a, b) return a[1] < b[1] end
      expect (table.sort (f (subject), cmp)).should_equal {{1}, {2}, {3}}
    end},
    {["it does guarantee stable ordering"] = function ()
      subject = {}
      -- is this a good test? or just requiring an implementation quirk?
      for i = 10000, 1, -1 do table.insert (subject, i) end
      expect (f (subject)).should_equal (subject)
    end},
    {["it diagnoses non-table arguments"] = function ()
      expect ("table expected").should_error (f, nil)
      expect ("table expected").should_error (f, "foo")
    end},
  }},


  {["context when requiring the module"] = {
    before = function ()
      extensions = { "clone", "clone_rename", "empty", "invert", "keys",
                     "merge", "new", "size", "sort", "values" }
    end,

    {["it returns the unextended module table"] = function ()
      for _, api in ipairs (extensions) do
	if api ~= "sort" then
          expect (unextended[api]).should_be (nil)
	end
      end
    end},
    {["it injects an enhanced sort function"] = function ()
      expect (unextended.sort).should_not_be (table.sort)
    end},
    {["it doesn't override any other module access points"] = function ()
      for api in pairs (unextended) do
	if api ~= "sort" then
          expect (table[api]).should_be (unextended[api])
	end
      end
    end},
  }},
}}
