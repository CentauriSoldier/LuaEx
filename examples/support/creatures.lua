ExampleCreature=class("ExampleCreature",{
    __clone=function(this) return deserialize(serialize(this)) end,
}, {}, {health=null}, {}, {
    ExampleCreature=function(this,cdat,name,health)
        cdat.pri.health=Pool(health,health)
    end,
    getHealthPool=function(this,cdat) return cdat.pri.health end,
    takeDamage=function(this,cdat,amount) cdat.pri.health.adjust(-amount);return this end,
    isDead=function(this,cdat) return cdat.pri.health.get()==0 end,
})

ExampleHuman=class("ExampleHuman",{}, {}, {name=""}, {}, {
    ExampleHuman=function(this,cdat,super,name,health)
        super(name,health);cdat.pri.name=name
    end,
    getName=function(this,cdat) return cdat.pri.name end,
},ExampleCreature)

local Rank=enum("ExampleSoldierRank",{"SCOUT","SERGEANT","CAPTAIN"})
ExampleSoldier=class("ExampleSoldier",{}, {RANK=Rank}, {rank=null}, {}, {
    ExampleSoldier=function(this,cdat,super,name,health,rank)
        super(name,health);cdat.pri.rank=rank
    end,
    getRank=function(this,cdat) return cdat.pri.rank end,
},ExampleHuman)

return {Creature=ExampleCreature,Human=ExampleHuman,Soldier=ExampleSoldier,Rank=Rank}
