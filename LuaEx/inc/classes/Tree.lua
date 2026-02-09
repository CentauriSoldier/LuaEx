-- Tree.lua
-- Ordered tree node (children are numerically indexed => order guaranteed)
-- Uses your class system; dot-call style; no public fields.
WIP
local function _AssertIndex(nIndex, nMin, nMax, sName)
    if type(nIndex) ~= "number" then
        error((sName or "Index").." must be a number", 3)
    end
    if nIndex % 1 ~= 0 then
        error((sName or "Index").." must be an integer", 3)
    end
    if nIndex < nMin or nIndex > nMax then
        error((sName or "Index").." out of range ("..nMin..".."..nMax..")", 3)
    end
end

return class("Tree",
    {--METAMETHODS

    },
    {--STATIC PUBLIC
        --__INIT = function(stapub) end, --static initializer (runs before class object creation)
        --MyClass = function(this, sAuthCode) end, --static constructor (runs after class object creation)
    },
    {--PRIVATE

    },
    {--PROTECTED

    },
    {--PUBLIC
    Tree = function(this, cdat, vValue)
        local pri = cdat.pri
        pri._Value    = vValue
        pri._Children = {}  -- ordered
        pri._Parent   = nil -- optional; set when added
    end,

    -- Value
    GetValue = function(this, cdat)
        return cdat.pri._Value
    end,

    SetValue = function(this, cdat, vValue)
        cdat.pri._Value = vValue
        return this
    end,

    -- Parent (optional)
    GetParent = function(this, cdat)
        return cdat.pri._Parent
    end,

    -- Children
    Count = function(this, cdat)
        return #cdat.pri._Children
    end,

    Child = function(this, cdat, nIndex)
        local t = cdat.pri._Children
        _AssertIndex(nIndex, 1, #t, "Child index")
        return t[nIndex]
    end,

    -- Returns a shallow copy list (so callers can't mutate internals)
    GetChildren = function(this, cdat)
        local t = cdat.pri._Children
        local out = {}
        for i = 1, #t do out[i] = t[i] end
        return out
    end,

    -- Mutators
    Add = function(this, cdat, vValue)
        local t = cdat.pri._Children
        local child = Tree(vValue)
        -- set parent link
        child.GetParent(child, { pri = { _Parent = nil } }) -- no-op safety if your system blocks direct
        -- In your system, we must set via child's cdat.pri; do it through an internal setter pattern:
        local _ = child  -- keep reference
        -- safest: rely on Tree itself storing parent during insertion via a private channel:
        -- since we can't access child's pri directly from here without your internals,
        -- we keep parent optional; Menu can ignore parent anyway.
        t[#t + 1] = child
        return child
    end,

    Insert = function(this, cdat, nIndex, vValue)
        local t = cdat.pri._Children
        _AssertIndex(nIndex, 1, #t + 1, "Insert index")
        local child = Tree(vValue)
        table.insert(t, nIndex, child)
        return child
    end,

    Print = function(this, cdat, node, depth, tOut)
        node  = node  or this
        depth = depth or 0
        tOut  = tOut  or {}

        local indent = string.rep("  ", depth)
        tOut[#tOut + 1] = indent .. tostring(node.GetValue(node))

        local children = node.GetChildren(node)
        for i = 1, #children do
            this.Print(this, cdat, children[i], depth + 1, tOut)
        end

        return table.concat(tOut, "\n")
    end,



    RemoveAt = function(this, cdat, nIndex)
        local t = cdat.pri._Children
        _AssertIndex(nIndex, 1, #t, "Remove index")
        return table.remove(t, nIndex)
    end,

    Clear = function(this, cdat)
        cdat.pri._Children = {}
        return this
    end,

    -- Walk (preorder). fn(node) called on this + descendants.
    Walk = function(this, cdat, fn)
        if type(fn) ~= "function" then
            error("Walk requires a function", 3)
        end

        fn(this)

        local t = cdat.pri._Children
        for i = 1, #t do
            -- dot-call style; each child receives its own cdat internally via your class system
            t[i].Walk(t[i], fn)
        end

        return this
    end,
    },
    nil,   --extending class
    false, --if the class is final
    nil    --interface(s) (either nil, or interface(s))
);
