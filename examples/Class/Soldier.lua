return class("Soldier",
{--metamethods
    __add = function(left, right, cdat)

    end,
},
{--public static members
    RANK = enum("RANK",
    {"Private", "PrivateSecondClass",   "PrivateFirstClass",    "Specialist", "Corporal", "Sergeant", "StaffSergeant",  "SergeantFirstClass",   "MasterSergeant",   "FirstSergeant",    "SergeantMajor",    "CommandSergeantMajor",     "SergeantMajoroftheArmy"},
    {"Private", "Private Second Class", "Private First Class",  "Specialist", "Corporal", "Sergeant", "Staff Sergeant", "Sergeant First Class", "Master Sergeant",  "First Sergeant",   "Sergeant Major",   "Command Sergeant Major",   "Sergeant Major of the Army"}, true);
},
{--private members
    Rank = null--Soldier.RANK,
},
{--protected members
},
{--public members
    Soldier = function(this, cdat, super, sName, nHP, eRank)
        --print("Soldier", sName, nHP)
        super(sName, nHP);
        --cdat.pri.Rank = eRank;
    end,
    serialize = function(this, cdat)
        return "Name: ${name}\r\nMax HP: ${hpmax}\r\nHP: ${hp}\t\nDamage: ${damage}\r\nAmour: ${armour}" % {
            name = this.GetName(), hpmax = cdat.pro.HPMax, hp = cdat.pro.HP, damage = cdat.pro.Damage, armour = cdat.pro.Armour
        };
    end,
},
Human, NO_INTERFACES, false);
