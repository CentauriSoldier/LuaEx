-- Shared initial wording for the visual example. Each catalog copies this input.
return {
    dialogue = {
        merchant = {
            greeting = "Hello ${player}, thanks for visiting my shop. Your friend ${friend} was just here!",
            offer    = "This lantern costs ${price} gold.",
            farewell = "Safe travels, ${PLAYER}!",
            literal  = "Write $${friend} to show a literal placeholder.",
            contact  = "Your contact is ${friend}.",
            rumors   = {
                weather = "A traveler says rain is coming to the valley.",
                road    = "The northern road is safe for a traveler today.",
            },
        },
        guard = {
            greeting = "Halt, ${player}! State your business.",
            warning  = "Keep the road clear, traveler.",
        },
    },
    errors = {
        gold      = "You need ${amount} more gold.",
        inventory = "Your pack is full.",
    },
    menu = {
        continue = "Continue journey",
        exit     = "Return to camp",
        literal  = "Offer: 100%? [gold] . * +",
        silence  = "",
    },
    empty = {},
};
