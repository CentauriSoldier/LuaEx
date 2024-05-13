return class("Creature",
{--metamethods
},
{--public static members
},
{--private members

},
{--protected members
    HP_AUTO     = 10,
    HPMax_AUTO  = 100,
    Damage_AUTO = 5,
    AC_AUTO     = 0,
    Armour_AUTO = 0,
    Move = function(this, cdat)

    end
},
{--public members
    Creature = function(this, cdat, nHP, nHPMax)
        print(type(cdat.pro["HPMax"]))
        --print("Creature", nHP, nHPMax)
        --cdat.pro.HP     = nHP < 1 and 1 or nHP;
        --cdat.pro.HP     = nHP > nHPMax and nHPMax or nHP;
        --cdat.pro.HPMax  = nHPMax;
    end,
    isdead = function(this, cdat)
        return cdat.pro.HP <= 0;
    end,
},
NO_PARENT, NO_INTERFACES, false);
