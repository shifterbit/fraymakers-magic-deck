
var cardSprites: ApiVarArray = self.makeArray([]);
var outlineSprites: ApiVarArray = self.makeArray([]);
var garbage: ApiVarArray = self.makeArray([]);
var active: ApiVarBool = self.makeBool(false);
var cooldown: ApiVarBool = self.makeBool(false);
var cards: ApiVarArray = self.makeArray([]);
var deckCapacity: ApiVarInt = self.makeInt(0);
var deckSpells: ApiVarArray = self.makeArray([]);
var currCard: ApiVarInt = self.makeInt(0);

self.exports = {
    active: active,
};

var actionable_animations = [
    "parry_success",
    "stand", "stand_turn",
    "walk", "walk_in", "walk_out", "walk_loop",
    "run", "run_turn", "skid",
    "jump_squat", "jump_in", "jump_out", "jump_midair", "jump_loop",
    "fall_loop", "fall_in", "fall_out",
    "crouch_loop", "crouch_in", "crouch_out",
    "dash", "airdash_land"
];

/**
 * @callback PredicateFunction
 * @param {number}
 * @returns {boolean}
 */


/**
 * @callback SpellFunction
 */

/**
 * @typedef {Object} Spell
 * @property {SpellFunction} cast Function called when a spell is cast.
 * @property {PredicateFunction} predicateFn Function called to check if the spell if usable
 * @property {Int} cooldownTime cooldown time for the spell
 */


/** 
 * Creates a spell
 * @type {function}
 * @param {SpellFunction} spellFn The function that casts the spell.
 * @param {PredicateFunction} predicateFn The function that checks if a spell is currently castable, takes an `Int` as input and returns a `bool`
 * @param {Int} cooldownTIme cooldown time, in frames.
 * @returns {Spell}
 */
function createSpell(spellFn, predicateFn, cooldownTime: Int) {
    return {
        cast: spellFn,
        predicate: predicateFn,
        cooldownTime: cooldownTime
    };

}

/** 
 * Creates a spell
 * @param {Sprite} sprite
 * @param {callback} cooldownFilterFn
 */
function createSpriteWithCooldownFilter(sprite: Sprite, cooldownFilterFn) {
    return {
        sprite: sprite,
        filter: cooldownFilterFn(),
        filterFn: cooldownFilterFn,
        filterApplied: false,
    }
}



function resizeAndRepositionCard(card: Sprite, idx: Int) {
    card.scaleX = 0.75;
    card.scaleY = 0.75;
    card.x = card.x + (40 * idx);
    card.y = card.y - 8;
}



function applyCooldownFilter(spriteObj) {
    var sprite: Sprite = spriteObj.sprite;
    var filter: HsbcColorFilter = spriteObj.filter;
    sprite.addFilter(filter);
    spriteObj.filterApplied = true;
}

function removeCooldownFilter(spriteObj) {
    var sprite: Sprite = spriteObj.sprite;
    var filter: HsbcColorFilter = spriteObj.filter;
    sprite.removeFilter(filter);
    spriteObj.filter = spriteObj.filterFn();
    spriteObj.filterApplied = false;

}


function newCoolDownFilter() {
    var filter: HsbcColorFilter = new HsbcColorFilter();
    filter.brightness = -0.2;
    filter.saturation = -0.2;
    return filter;

}

/** 
 * Puts the deck in cooldown mode.
 */
function beginCooldown() {
    cooldown.set(true);
    for (spriteObj in cardSprites.get()) {
        applyCooldownFilter(spriteObj);
    };
    removeAllHighlights();
}

/** 
 * Puts the deck out of cooldown mode.
 */
function endCoolDown() {
    cooldown.set(false);
    for (spriteObj in cardSprites.get()) {
        removeCooldownFilter(spriteObj);
    };
    highlightCurrentCard();
}

/** 
 * Puts the deck in cooldown mode for a certain number of frames.
 * @param {Int} duration The duration of the timer, in frames.
 */
function startCooldownTimer(duration: Int) {
    beginCooldown();
    self.addTimer(duration, 1, endCoolDown, { persistent: true });

}
/** 
 * Sets the assist charge to 0.
 */
function zeroAssist() {
    self.getOwner().setAssistCharge(0);

}

/** 
 * Sets the assist charge to 0 in response to an event.
 * @param {GameObjectEvent} event The event being passed in
 */
function keepAssistBarAtZero(event: GameObjectEvent) {
    zeroAssist();
}

/** 
 * Attempts to cast a spell.
 * 
 * returns `true` if the spell as successfully been casted and also triggers the spells cooldown.
 * @param {Object} spell The spell object
 * @param {Int} score The card value
 */
function trySpell(spell, score) {
    if (spell.predicate(score)) {
        spell.cast();
        var cooldownTime: Int = spell.cooldownTime;
        startCooldownTimer(cooldownTime);
        return true;
    } else {
        return false;
    }
}

/** 
 * Goes through the list of spells on the deck and casts the first one that whose predicate function returns true.
 * @param {Int} card The card value, usually derived from damage.
 */
function castFirstAvailaleSpell(card: Int) {
    for (spell in deckSpells.get()) {
        Engine.log("Trying spell " + spell);
        var casted = trySpell(spell, card);
        if (casted) {
            return;
        };
    }
}

/** 
 * Calls `addCard(value)` if the deck isn't in a cooldown state
 * @param {GameObjectEvent} event The event passed in by the event listener, typically `HIT_DEALT`
 */
function addCardEvent(event: GameObjectEvent) {
    if (!cooldown.get()) {
        Engine.log("COOLDOWN");
        var hitboxStats: HitboxStats = event.data.hitboxStats;
        var damage = hitboxStats.damage;
        addCard(damage);
    }
}

/** 
 * Adds a card to the top of the deck if the deck isn't full
 * @param {Int} value The card value, usually derived from damage.
 */
function addCard(value: Int) {
    var card = value % 10;
    if (apiArrLength(cards) < deckCapacity.get()) {
        apiArrPush(cards, card);
        var sprite: Sprite = apiArrGetIdx(cardSprites, currCard.get()).sprite;
        sprite.currentFrame = card + 3;
        incrementCard();
        self.exports.active.set(apiArrLength(cards) == deckCapacity.get());
        startCooldownTimer(60);

    }
}

/** 
 * Initializes the deck with the currently configured spells
 * @param {Object} deck The deck object
 * @param {Int} capacity The maximum number of cards
 * @param {Object[]} spells  The list of spells you want accessible
 */
function initializeDeck(capacity: Int, spells: Array<any>, spriteId) {
    var spellset = [];
    for (spell in spells) {
        spellset.push(spell);
    }
    deckSpells.set(spellset);
    deckCapacity.set(capacity);

    Engine.forCount(capacity, function (idx: Int) {
        var card = Sprite.create(self.getResource().getContent(spriteId));
        var cardOutline = Sprite.create(self.getResource().getContent(spriteId));

        // We need to keep track of outlines later as we need to dispose of them at some point
        apiArrPush(garbage, cardOutline);

        apiArrPush(cardSprites, createSpriteWithCooldownFilter(card, newCoolDownFilter));

        apiArrPush(outlineSprites, cardOutline);

        return true;
    }, []);

    Engine.forCount(apiArrLength(cardSprites), function (idx: Int) {
        var sprite = apiArrGetIdx(cardSprites, idx).sprite;
        var outline = apiArrGetIdx(outlineSprites, idx);

        self.getRootOwner().getDamageCounterContainer().addChild(sprite);
        self.getRootOwner().getDamageCounterContainer().addChild(outline);
        resizeAndRepositionCard(sprite, idx);
        resizeAndRepositionCard(outline, idx);
        return true;
    }, []);

    highlightCurrentCard();
}

/** 
 * Draws a card from the top of the deck and uses it to cast a spell
 */
function drawSpell() {
    if (apiArrLength(cards) > 0 && !cooldown.get()) {
        cooldown.set(true);
        var card = apiArrPop(cards);
        var sprite = apiArrPop(cardSprites);
        var outline: Sprite = apiArrPop(outlineSprites);
        outline.currentFrame = 1;
        sprite.sprite.dispose();
        decrementCard();
        Engine.log("Casting spell");
        castFirstAvailaleSpell(card);
    }
}


// Just a helper function to check if an array contains something
function contains(arr: Array<any>, item: any) {
    for (i in arr) {
        if (i == item) {
            return true;
        }
    }
    return false;
}


function apiArrPush(arr: ApiVarArray, val: any) {
    var temp = arr.get();
    temp.push(val);
    arr.set(temp);
}

function apiArrLength(arr: ApiVarArray) {
    return arr.get().length;
}

function apiArrPop(arr: ApiVarArray) {
    var temp = arr.get();
    var popped = temp.pop();
    arr.set(temp);
    return popped;
}

function apiArrGetIdx(arr: ApiVarArray, idx: Int) {
    var temp = arr.get();
    var item = temp[idx];
    return item;
}


function apiArrSetIdx(arr: ApiVarArray, idx: Int, item: any) {
    var temp = arr.get();
    temp[idx] = item;
    arr.set(temp);
}

function castable() {
    var res = !cooldown.get() && contains(actionable_animations, self.getRootOwner().getAnimation()) == true;
    return res;
}

function incrementCard() {
    var curr = currCard.get();
    if (curr < deckCapacity.get() - 1) {
        currCard.set(curr + 1);
    }
}

function decrementCard() {
    var curr = currCard.get();
    if (curr > 0) {
        currCard.set(curr - 1);
    }
}


function empty() {
    return apiArrLength(cards) == 0;
}


function cleanup() {
    for (i in garbage.get()) {
        i.dispose();
    }
    self.destroy();
}

function removeAllHighlights() {
    Engine.forEach(outlineSprites.get(), function (outline: Sprite, _idx: Int) {
        outline.currentFrame = 1;
    }, []);
}
function highlightCurrentCard() {

    var currOutline: Sprite = apiArrGetIdx(outlineSprites, currCard.get());
    if (currOutline != null) {
        currOutline.currentFrame = 2;
    }

}

self.exports.drawSpell = drawSpell;
self.exports.resizeAndRepositionCard = resizeAndRepositionCard;
self.exports.createSpell = createSpell;
self.exports.initializeDeck = initializeDeck;
self.exports.addCardEvent = addCardEvent;
self.exports.cleanup = cleanup;
self.exports.empty = empty;
self.exports.castable = castable;





function initialize() { }
function onTeardown() { }
function update() { }