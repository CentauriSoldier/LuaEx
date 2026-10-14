local piles = {};
local records, selected, nextID, message, events = {}, 0, 1, "", {};
local categories = {"Spell", "Resource", "Character", "Quest"};
local function log(text)
    message = text;
    events[#events + 1] = text;
    if #events > 30 then table.remove(events, 1); end
end
local function add(card, pile)
    local id = nextID;
    nextID = id + 1;
    records[id] = card;
    assert(select(2, piles[pile].addCard(card)));
    selected = id;
    return id;
end
local function reset(bonus)
    piles = {deck = BaseDeck(), hand = BaseDeck(), discard = BaseDeck()};
    records, selected, nextID, events = {}, 0, 1, {};
    for _, category in ipairs(categories) do
        for index = 1, 13 do
            local card = BaseCard(category.." "..index, "A generic "..category:lower().." card.");
            card.getTagSystem().add(category);
            add(card, "deck");
        end
    end
    if bonus then
        for i = 1, 2 do add(BaseCard("Bonus "..i, "An optional bonus card."), "deck"); end
    end
    selected = 1;
    log("Fresh deck: top is index one. Draw moves real instances to your hand; hands and discards are example policy.");
end
local function locate(card)
    for _, key in ipairs({"deck", "hand", "discard"}) do
        local found, index = piles[key].containsCard(card);
        if found then return key, index; end
    end
end
local function view()
    local groups = {};
    local selection = false;
    for _, key in ipairs({"deck", "hand", "discard"}) do
        local cards = {};
        for index, card in piles[key].eachCard() do
            local id;
            for candidate, object in pairs(records) do if rawequal(card, object) then id = candidate; break; end end
            local info = {id = id, index = index, name = card.getName(), description = card.getDescription(), faceUp = card.isFaceUp(), enabled = card.isEnabled(), pile = key};
            cards[#cards + 1] = info;
            if id == selected then selection = info; end
        end
        groups[#groups + 1] = {key = key, count = #piles[key], cards = cards};
    end
    return {visual = "cards", piles = groups, selected = selection, message = message, events = clone(events)};
end
function workbench_action(action, data)
    data = data or {};
    local ok, why = pcall(function()
        if action == "view" then return; end
        if action == "reset" then reset(data.bonus == true); return; end
        if action == "shuffle" then piles.deck.shuffle(); log("Shuffled draw pile only. Hand and discard are unchanged."); return; end
        if action == "reverse" then piles.deck.reverse(); log("Reversed draw-pile order."); return; end
        if action == "peek" then
            local card = piles.deck.peek();
            log(card and ("Peek: "..card.getName()..". Count is still "..#piles.deck.."; no card moved.") or "Draw pile is empty.");
            return;
        end
        if action == "draw" then
            local count = tonumber(data.count or 1);
            local cards, success = piles.deck.drawMany(count);
            assert(success, "Not enough cards. Batch draw left the deck unchanged.");
            for _, card in ipairs(cards) do card.reveal(); assert(select(2, piles.hand.addCard(card))); end
            if #cards > 0 then for id, card in pairs(records) do if rawequal(card, cards[1]) then selected = id; end end end
            log("Drew "..#cards.." card(s) into hand. Exactly those instances moved.");
            return;
        end
        if action == "recycle" then
            local _, cards = piles.discard.clear();
            for _, card in ipairs(cards) do card.hide(); assert(select(2, piles.deck.addCard(card))); end
            log("Returned "..#cards.." discarded cards to the bottom of the deck, face down.");
            return;
        end
        if action == "create" then
            assert(nextID <= 150, "Reset the lab after creating 150 card records.");
            assert(type(data.name) == "string" and data.name:find("%S") and #data.name <= 80, "Enter a card name.");
            assert(piles[data.pile], "Unknown destination pile.");
            assert(type(data.description) == "string" and data.description:find("%S"), "Enter a card description.");
            add(BaseCard(data.name, data.description, nil, nil, true), data.pile);
            log("Created a distinct card instance. Matching names do not make it a duplicate instance.");
            return;
        end
        local card = records[tonumber(data.id or selected)];
        assert(card, "Select a card first.");
        local source = locate(card);
        assert(source, "Card was deleted.");
        selected = tonumber(data.id or selected);
        if action == "select" then return;
        elseif action == "edit" then
            assert(type(data.faceUp) == "boolean" and type(data.enabled) == "boolean", "Flags must be booleans.");
            card.setFaceUp(data.faceUp).setEnabled(data.enabled);
            log("Updated the same card instance. Enabled is metadata; the deck does not automatically skip disabled cards.");
        elseif action == "flip" then card.flip(); log("Flipped "..card.getName()..".");
        elseif action == "clone" then add(clone(card), source); log("Added an independent clone, preserving face state, traits and tags.");
        elseif action == "delete" then assert(select(2, piles[source].removeCard(card))); records[selected] = nil; selected = 0; log("Deleted the selected instance from the laboratory.");
        elseif action == "move" then
            assert(piles[data.pile] and data.pile ~= source, "Choose a different pile.");
            assert(not piles[data.pile].containsCard(card), "Destination already contains this instance.");
            assert(select(2, piles[source].removeCard(card)));
            assert(select(2, piles[data.pile].addCard(card, data.top == true)));
            log("Moved the selected instance to "..data.pile..(data.top and " at the top." or " at the bottom."));
        else error("Unknown card action."); end
    end);
    if not ok then log("Rejected: "..tostring(why):gsub("[^%s:]+%.lua:%d+:%s*", "")); end
    return view();
end
reset(false);
return view();
