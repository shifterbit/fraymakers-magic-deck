var cardSprites: ApiVarArray = self.makeArray([]);
var outlineSprites: ApiVarArray = self.makeArray([]);
var cooldownSprites: ApiVarArray = self.makeArray([]);
var iconSprites: ApiVarArray = self.makeArray([]);
var garbage: ApiVarArray = self.makeArray([]);
var active: ApiVarBool = self.makeBool(false);
var cooldown: ApiVarBool = self.makeBool(false);
var cards: ApiVarArray = self.makeArray([]);
var deckCapacity: ApiVarInt = self.makeInt(0);
var deckActions: ApiVarArray = self.makeArray([]);
var currCard: ApiVarInt = self.makeInt(0);
var iconEventListeners: ApiVarArray = self.makeArray([]);
var owner: Character = self.getRootOwner();
var cooldownSound: ApiVarString = self.makeString("");





/**
 * Runs an action for a spell
 * @callback ActionFunction
 */


/**
 * Accepts a card and check if it is actionable
 * @callback PredicateFunction
 * @param {Int} card
 * @returns {boolean}
 */


/**
 * An action to be used by a card
 * @typedef {Object} Action
 * @property {ActionFunction} run - function to be run when action is triggered.
 * @property {PredicateFunction} predicate - function to run, to check if action should be run.
 * @property {Int} cooldownTimer - Cooldown time, in frames.
 * @property {string} icon -The icon to be displayed when the action is usable.
 */


/**
 * A Sprite wrapped with a shader
 * @typedef {Object} ShaderSprite
 * @property {Object} sprite - The sprite itself.
 * @property {Object} shader - The shader to be applied.
 * @property {function} shaderFn - The shader generation function, to regenerate the shader for reuse.
 * @property {boolean} applied - whether the shader has been applied.
 */


/**
 * A Sprite wrapped with a filter
 * @typedef {Object} FilterSprite
 * @property {Object} sprite - The sprite itself.
 * @property {Object} shader - The filter to be applied.
 * @property {function} shaderFn - The filter generation function, to regenerate the shader for reuse.
 * @property {boolean} applied - whether the filter has been applied.
 */


/**
 * Set of animation idsfrom which spells can be used, additionally substring checks will be used if no exact matches have been found
 * @type {[]string}
 */
var actionable_animations: Array<String> = [
    "parry_success",
    "stand", "stand_turn", "idle",
    "walk", "walk_in", "walk_out", "walk_loop",
    "run", "run_turn", "skid",
    "jump_squat", "jump_in", "jump_out", "jump_midair", "jump_loop",
    "fall_loop", "fall_in", "fall_out",
    "crouch_loop", "crouch_in", "crouch_out",
    "dash", "airdash_land"
];

/**
 * Creates a deck action given an action function, predicate function, cooldowntime and icon
 * @param {ActionFunction} actionFn - The function that runs when the spell is cast
 * @param {PredicateFunction} predicateFn - The function that checks if the spell is valid, should accept a single int arguement and return a boolean
 * @param {Int} cooldownTime - Time in frames for spell cooldown
 * @param {string} icon - The id of the icon displayed
 * @returns {Action} The Action Object
 */
function createAction(actionFn, predicateFn, cooldownTime: Int, icon: String) {
    return {
        run: actionFn,
        predicate: predicateFn,
        cooldownTime: cooldownTime,
        icon: icon,
    };

}


/**
 * Creates a wrapped sprite object with a cooldown filter in it
 * @param {Object} sprite - Raw Sprite Object where the cooldown will be applied
 * @param {function} filterFn - function that returns a cooldown.
 * @returns {FilterSprite} The wrapped cooldown sprite
 */
function createSpriteWithFilter(sprite: Sprite, filterFn) {
    return {
        sprite: sprite,
        filter: filterFn(),
        filterFn: filterFn,
        filterApplied: false,
    }
}

/**
 * Creates a wrapped sprite object with a cooldown filter in it
 * @param {Object} sprite - Raw Sprite Object where the cooldown will be applied
 * @param {function} shaderFn - function that returns a cooldown.
 * @returns {ShaderSprite} The wrapped cooldown sprite
 */
function createSpriteWithShader(sprite: Sprite, shaderFn) {
    return {
        sprite: sprite,
        shader: shaderFn(),
        shaderFn: shaderFn,
        shaderApplied: false,
    }
}



/**
 * Resizes and Repositions a UI element according to card position
 * @param {Object} element - Sprite element to reposition
 * @param {Int} idx - position
 * @param {Float} scale - Sprite Scale
 * @param {Int} spacing - Spacing between other items
 * @param {Int} xOffset - X Axis Offset
 * @param {Int} yOffset - Y Axis Offset. Positive is up


 */
function resizeAndRepositionHUD(element: Sprite, idx: Int, scale: Float, spacing: Int, xOffset: Int, yOffset: Int) {
    element.scaleX = scale;
    element.scaleY = scale;
    element.x = element.x + (spacing * idx) + xOffset;
    var totalYOffset = yOffset + 32;
    var hudPosition = GraphicsSettings.damageHudPosition;
    if (hudPosition == "top") {
        element.y = element.y + 4 * (totalYOffset);
    } else {
        element.y = element.y - (totalYOffset);
    }
}



/**
 * Applies the filter to a wrapped sprite
 * @param {FilterSprite} spriteObj
 */
function applyFilter(spriteObj) {
    var sprite: Sprite = spriteObj.sprite;
    var filter: HsbcColorFilter = spriteObj.filter;
    sprite.addFilter(filter);
    spriteObj.filterApplied = true;
}

/**
 * Applies the filter to a wrapped sprite
 * @param {ShaderSprite} spriteObj
 */
function applyShader(spriteObj) {
    var sprite: Sprite = spriteObj.sprite;
    var shader: RgbaColorShader = spriteObj.shader;
    sprite.addShader(shader);
    spriteObj.shaderApplied = true;
}


/**
 * Removes and Refreshes the filter to a wrapped sprite
 * @param {FilterSprite} spriteObj
 */
function removeFilter(spriteObj) {
    var sprite: Sprite = spriteObj.sprite;
    var filter: HsbcColorFilter = spriteObj.filter;
    sprite.removeFilter(filter);
    spriteObj.filter = spriteObj.filterFn();
    spriteObj.filterApplied = false;

}


/**
 * Generates the filter used for the cooldown state
 */
function newCoolDownFilter() {
    var filter: HsbcColorFilter = new HsbcColorFilter();
    filter.brightness = -0.2;
    filter.saturation = -0.2;
    return filter;
}


/**
 * Generates the loading shader used for the dynamic cooldown ui
 */
function loadingShader() {
    var shader: RgbaColorShader = new RgbaColorShader();
    shader.color = 0x000000;
    shader.alphaMultiplier = 1 / 20;
    shader.redMultiplier = 1 / 3;
    shader.greenMultiplier = 1 / 2;
    shader.blueMultiplier = 1;
    return shader;
}

/** 
 * Puts the deck in cooldown mode.
 */
function beginCooldown() {
    cooldown.set(true);
    for (spriteObj in cardSprites.get()) {
        applyFilter(spriteObj);
    };
    removeAllHighlights();
    owner.removeEventListener(GameObjectEvent.HIT_DEALT, addCardEvent);
}

/** 
 * Puts the deck out of cooldown mode.
 */
function endCoolDown() {
    cooldown.set(false);
    for (spriteObj in cardSprites.get()) {
        removeFilter(spriteObj);
    };
    highlightCurrentCard();
    owner.addEventListener(GameObjectEvent.HIT_DEALT, addCardEvent, { persistent: true });
    var cooldownSoundId = cooldownSound.get();
    if (cooldownSoundId != "") {
        AudioClip.play(self.getResource().getContent(cooldownSoundId));
    }
}

/** 
 * Puts the deck in cooldown mode for a certain number of frames.
 * @param {Int} duration - The duration of the timer, in frames.
 */
function startCooldownTimer(duration: Int) {
    beginCooldown();
    self.addTimer(duration, 1, endCoolDown, { persistent: true });

}


/** 
 * Puts the deck in cooldown mode for a certain number of frames.
 * @param {Int} duration - The total duration of the timer, in frames.
 */
function startsplitCooldownTimer(duration: Int) {
    var currPos = currCard.get();
    var currOverlay = apiArrGetIdx(cooldownSprites, currPos);
    var outline: Sprite = currOverlay.sprite;
    outline.currentFrame = 1;
    var intervalsize = duration / 52;
    var coolDownFn = function () {
        outline.currentFrame += 1;
        if (outline.currentFrame == 53) {
            cooldown.set(false);
            highlightCurrentCard();
        }
    }
    self.addTimer(intervalsize, 52, coolDownFn, { persistent: true });


}


/** 
 * Attempts to run an action
 * @param {Action} action - The action object to evaluate
 * @param {Int} score - The card value
 */
function tryAction(action, score) {
    if (action.predicate(score)) {
        action.run();
        return action;
    } else {
        return null;
    }
}


/** 
 * Goes through the list of registered actions and runs the first available one.
 * @param {Int} card - The card value
 */
function activateFirstAvailableAction(card: Int) {
    var triggered = null;
    for (action in deckActions.get()) {
        triggered = tryAction(action, card);
        if (triggered != null) { break; }
    }
    if (triggered != null) {
        var cooldownTime: Int = triggered.cooldownTime;
        startsplitCooldownTimer(cooldownTime);
    } else {
        startsplitCooldownTimer(15);
    }
}


/** 
 * Gets the icon id for the selected card
 * @param {Int} cardIdx - The card index
 */
function getIcon(cardIdx: Int) {
    var cardVal = apiArrGetIdx(cards, cardIdx);
    var actions = deckActions.get();
    for (action in actions) {
        if (action.predicate(cardVal)) {
            return action.icon;
        }
    }
    return "default";
}

/** 
 * Returns an icon refresh function for a given card index
 * @param {Int} cardIdx - The card index
 */
function iconRefresher(cardIdx: Int) {
    return function () {
        var icon: Sprite = apiArrGetIdx(iconSprites, cardIdx);
        if (icon != null) {
            icon.currentAnimation = getIcon(cardIdx);
        }
    }

}

/** 
 * Calls `addCard(value)` if the deck isn't in a cooldown state
 * @param {GameObjectEvent} event - The event passed in by the event listener, typically `HIT_DEALT`
 */
function addCardEvent(event: GameObjectEvent) {
    var foe = event.data.foe;
    var foeInvincible: Bool = foe.hasBodyStatus(BodyStatus.INVINCIBLE)
        || foe.hasBodyStatus(BodyStatus.INVINCIBLE_GRABBABLE)
        || foe.hasBodyStatus(BodyStatus.INTANGIBLE);
    if (!cooldown.get() && !foeInvincible) {
        var hitboxStats: HitboxStats = event.data.hitboxStats;
        var damage = hitboxStats.damage;
        var currentLength = apiArrLength(cards);
        var currCard: Int = currCard.get();
        self.addTimer(1, -1, iconRefresher(currCard),
            {
                persistent: true,
                condition: (function () { return (currentLength <= (apiArrLength(cards) - 1)); })
            });

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
        var icon: Sprite = apiArrGetIdx(iconSprites, currCard.get());
        var icon_name = getIcon(card);
        icon.currentAnimation = icon_name;
        sprite.currentFrame = card + 3;
        incrementCard();
        active.set(apiArrLength(cards) == deckCapacity.get());

        startCooldownTimer(60);

    }
}



/**
 * Initializes a deck from a list of actions, this uses some pretty sane defaults, with a `capacity` of 3 and 
 * using the default Ids in the template being the following: `"cards"` for `spriteId` of the cards, 
 * `"cards_cooldown"` for `cooldownOverlayId`,  and `"card_icons"` for `iconsId`
 * @param {Action[]} actions - The array of actions you generated
 * @param {String} cooldownSoundId
 */

function init(actions: Array<any>, cooldownSoundId: String) {
    var spriteId: String = "cards";
    var cooldownOverlayId: String = "cards_cooldown";
    var iconsId: String = "card_icons";
    cooldownSound.set(cooldownSoundId);

    initializeDeck(3, actions, spriteId, cooldownOverlayId, iconsId);
}

/**
 * Initializes a deck
 * @param {Int} capacity - deck capacity
 * @param {Action[]} actions - The array of actions you generated
 * @param {String} spriteId - Id For card sprite
 * @param {String} spriteId - Id the cooldown overlay sprite
 * @param {String} spriteId - Id For icons sprite
 * @param {String} cooldownSoundId - AudioId for sound played upon cooldown end
 */
function initializeDeck(capacity: Int, actions: Array<any>, spriteId, cooldownOverlayId, iconsId) {
    var actionList = [];
    for (action in actions) {
        actionList.push(action);
    }
    deckActions.set(actionList);
    deckCapacity.set(capacity);

    Engine.forCount(capacity, function (idx: Int) {
        var card = Sprite.create(self.getResource().getContent(spriteId));
        var cardOutline = Sprite.create(self.getResource().getContent(spriteId));
        var cooldownOutline = Sprite.create(self.getResource().getContent(cooldownOverlayId));
        var iconSprite = Sprite.create(self.getResource().getContent(iconsId));

        iconSprite.currentAnimation = "";

        cooldownOutline.currentFrame = 53;
        cooldownOutline.alpha = 0.95;

        // We need to keep track of outlines later as we need to dispose of them at some point
        apiArrPush(garbage, cardOutline);
        apiArrPush(garbage, cooldownOutline);
        apiArrPush(garbage, iconSprite);



        apiArrPush(cardSprites, createSpriteWithFilter(card, newCoolDownFilter));
        apiArrPush(outlineSprites, cardOutline);
        apiArrPush(iconSprites, iconSprite);

        apiArrPush(cooldownSprites, createSpriteWithShader(cooldownOutline, loadingShader));
        return true;
    }, []);

    Engine.forCount(capacity, function (idx: Int) {
        var sprite = apiArrGetIdx(cardSprites, idx).sprite;
        var outline: Sprite = apiArrGetIdx(outlineSprites, idx);
        var cooldownObj = apiArrGetIdx(cooldownSprites, idx);
        var cooldownSprite: Sprite = cooldownObj.sprite;
        var iconSprite = apiArrGetIdx(iconSprites, idx);
        applyShader(cooldownObj);
        owner.getDamageCounterContainer().addChild(sprite);
        owner.getDamageCounterContainer().addChild(outline);
        owner.getDamageCounterContainer().addChild(cooldownSprite);
        owner.getDamageCounterContainer().addChild(iconSprite);


        var baseXOffset = 32;

        resizeAndRepositionHUD(sprite, idx, 0.75, 45, baseXOffset, 0);
        resizeAndRepositionHUD(outline, idx, 0.75, 45, baseXOffset, 0);
        resizeAndRepositionHUD(cooldownSprite, idx, 0.75, 45, baseXOffset, 0);
        resizeAndRepositionHUD(iconSprite, idx, 0.50, 45, 16 + baseXOffset, 0);

        return true;
    }, []);

    highlightCurrentCard();
    owner.addEventListener(GameObjectEvent.HIT_DEALT, addCardEvent, { persistent: true });

}


/** 
 * Draws a card from the top of the deck
 */
function drawCard() {
    if (apiArrLength(cards) > 0 && !cooldown.get()) {
        if (!owner.isOnFloor()) {
            owner.playAnimation("assist_call_air");
        } else {
            owner.playAnimation("assist_call");
        }
        cooldown.set(true);
        var card = apiArrPop(cards);
        var sprite = apiArrPop(cardSprites);
        var outline: Sprite = apiArrPop(outlineSprites);
        var iconSprite = apiArrPop(iconSprites);
        outline.currentFrame = 1;
        iconSprite.dispose();
        sprite.sprite.dispose();
        decrementCard();
        activateFirstAvailableAction(card);
    }
}


/** 
 * Checks if the substring is contained within another string
 * @param {String} text - The source string
 * @param {String} substr - the substring to look for
 */
function containsSubstring(text: String, substr: String) {
    if (substr.length > text.length) {
        return false;
    }
    var match = false;
    Engine.forCount(text.length - substr.length + 1, function (idx: Int) {
        var temp = text.substr(idx, idx + substr.length);
        if (temp == substr) {
            match = true;
            return false;
        }
        return true;
    }, []);
    return match;

}


/** 
 * Checks if any item in the array is either equal to or is a subtring of the target
 * @param {String[]} arr - array of strings
 * @param {String} target - target string
 */
function hasMatchOrSubstring(arr: Array<String>, target: String) {
    for (i in arr) {
        if (i == target || containsSubstring(target, i)) {
            return true;
        }
    }
    return false;
}


/** 
 * Checks if any item in the array is either equal to or is a subtring of the target
 * @param {ApiVarArray} arr - A Fraymakers API Wrapped array
 * @param target - value to push to the array
 */
function apiArrPush(arr: ApiVarArray, val: any) {
    var temp = arr.get();
    temp.push(val);
    arr.set(temp);
}

/** 
 * Returns the length of the array
 * @param {ApiVarArray} arr - A Fraymakers API Wrapped array
 */
function apiArrLength(arr: ApiVarArray) {
    return arr.get().length;
}

/** 
 * Pops off the last item of the array
 * @param {ApiVarArray} arr - A Fraymakers API Wrapped array
 * @returns The last item of the array
 */
function apiArrPop(arr: ApiVarArray) {
    var temp = arr.get();
    var popped = temp.pop();
    arr.set(temp);
    return popped;
}


/** 
 * Gets an item from the Fraymakers API Wrapped array at a particular index
 * @param {ApiVarArray} arr - A Fraymakers API Wrapped array
 * @param {Int} idx - index
 * @returns The selected item of the array
 */
function apiArrGetIdx(arr: ApiVarArray, idx: Int) {
    var temp = arr.get();
    var item = temp[idx];
    return item;
}

/** 
 * Gets an item from the Fraymakers API Wrapped array at a particular index
 * @param {ApiVarArray} arr - A Fraymakers API Wrapped array
 * @param {Int} idx - index
 * @param {Any} item - Item to insert
 */
function apiArrSetIdx(arr: ApiVarArray, idx: Int, item: any) {
    var temp = arr.get();
    temp[idx] = item;
    arr.set(temp);
}


/** 
 * Checks if the current animation can be acted out of using cards
 */
function runnable() {
    var res = !cooldown.get() && hasMatchOrSubstring(actionable_animations, owner.getAnimation()) == true;
    return res;
}

/** 
 * Increments the current card index
 */
function incrementCard() {
    if (currCard.get() < deckCapacity.get() - 1) {
        currCard.inc();
    }
}

/** 
 * Decrements the current card index
 */
function decrementCard() {
    if (currCard.get() > 0) {
        currCard.dec();
    }
}

/** 
 * Checks if the deck is empty
 */
function empty() {
    return apiArrLength(cards) == 0;
}

/** 
 * Cleans up the deck, ensuring all resources are destroyed
 */
function cleanup() {
    var dispoables = garbage.get();
    for (i in dispoables) {
        i.dispose();
    }
    self.destroy();
}

/** 
 * Removes all highlights from cards
 */
function removeAllHighlights() {
    var outlines = outlineSprites.get();
    Engine.forEach(outlines, function (outline: Sprite, _idx: Int) {
        outline.currentFrame = 1;
    }, []);
}

/** 
 * Highlughts only the current card
 */
function highlightCurrentCard() {
    removeAllHighlights();
    var currOutline: Sprite = apiArrGetIdx(outlineSprites, currCard.get());
    if (currOutline != null) {
        currOutline.currentFrame = 2;
    }

}

function update() {
    owner.setAssistCharge(0);
    if (active.get()) {
        owner.removeEventListener(GameObjectEvent.HIT_DEALT, addCardEvent);
        if (owner.getHeldControls().ACTION && runnable()) {
            drawCard();
            if (empty()) {
                cleanup();
                self.dispose();


            }
        }
    }

}

self.exports.createAction = createAction;
self.exports.initializeDeck = initializeDeck;
self.exports.init = init;



function initialize() { }
function onTeardown() { }
