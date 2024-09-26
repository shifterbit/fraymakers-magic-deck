
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


var actionable_animations = [
    "parry_success",
    "stand", "stand_turn", "idle",
    "walk", "walk_in", "walk_out", "walk_loop",
    "run", "run_turn", "skid",
    "jump_squat", "jump_in", "jump_out", "jump_midair", "jump_loop",
    "fall_loop", "fall_in", "fall_out",
    "crouch_loop", "crouch_in", "crouch_out",
    "dash", "airdash_land"
];


function createAction(actionFn, predicateFn, cooldownTime: Int, icon) {
    return {
        run: actionFn,
        predicate: predicateFn,
        cooldownTime: cooldownTime,
        icon: icon,
    };

}


function createSpriteWithCooldownFilter(sprite: Sprite, cooldownFilterFn) {
    return {
        sprite: sprite,
        filter: cooldownFilterFn(),
        filterFn: cooldownFilterFn,
        filterApplied: false,
    }
}

function createSpriteWithShader(sprite: Sprite, shaderFn) {
    return {
        sprite: sprite,
        shader: shaderFn(),
        shaderFn: shaderFn,
        shaderApplied: false,
    }
}



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



function applyCooldownFilter(spriteObj) {
    var sprite: Sprite = spriteObj.sprite;
    var filter: HsbcColorFilter = spriteObj.filter;
    sprite.addFilter(filter);
    spriteObj.filterApplied = true;
}

function applyShader(spriteObj) {
    var sprite: Sprite = spriteObj.sprite;
    var shader: RgbaColorShader = spriteObj.shader;
    sprite.addShader(shader);
    spriteObj.shaderApplied = true;
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
        applyCooldownFilter(spriteObj);
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
        removeCooldownFilter(spriteObj);
    };
    highlightCurrentCard();
    owner.addEventListener(GameObjectEvent.HIT_DEALT, addCardEvent, { persistent: true });
    AudioClip.play(self.getResource().getContent("cooldownEndSound"));


}

/** 
 * Puts the deck in cooldown mode for a certain number of frames.
 * @param {Int} duration The duration of the timer, in frames.
 */
function startCooldownTimer(duration: Int) {
    beginCooldown();
    self.addTimer(duration, 1, endCoolDown, { persistent: true });

}

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
 * Sets the assist charge to 0.
 */
function zeroAssist() {
    self.getOwner().setAssistCharge(0);

}


function keepAssistBarAtZero(event: GameObjectEvent) {
    zeroAssist();
}


function tryAction(action, score) {
    if (action.predicate(score)) {
        action.run();
        return action;
    } else {
        return null;
    }
}

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
function iconRefresher(currentCard: Int) {
    return function () {
        var icon: Sprite = apiArrGetIdx(iconSprites, currentCard);
        if (icon != null) {
            icon.currentAnimation = getIcon(currentCard);
        }
    }

}

/** 
 * Calls `addCard(value)` if the deck isn't in a cooldown state
 * @param {GameObjectEvent} event The event passed in by the event listener, typically `HIT_DEALT`
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



        apiArrPush(cardSprites, createSpriteWithCooldownFilter(card, newCoolDownFilter));
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


function isSubstring(text: String, substr: String) {
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


// Just a helper function to check if an array contains something
function hasMatchOrSubstring(arr: Array<String>, item: String) {
    for (i in arr) {
        if (i == item || isSubstring(item, i)) {
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

function runnable() {
    var res = !cooldown.get() && hasMatchOrSubstring(actionable_animations, owner.getAnimation()) == true;
    return res;
}

function incrementCard() {
    if (currCard.get() < deckCapacity.get() - 1) {
        currCard.inc();
    }
}

function decrementCard() {
    if (currCard.get() > 0) {
        currCard.dec();
    }
}


function empty() {
    return apiArrLength(cards) == 0;
}


function cleanup() {
    var dispoables = garbage.get();
    for (i in dispoables) {
        i.dispose();
    }
    self.destroy();
}

function removeAllHighlights() {
    var outlines = outlineSprites.get();
    Engine.forEach(outlines, function (outline: Sprite, _idx: Int) {
        outline.currentFrame = 1;
    }, []);
}
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



function initialize() { }
function onTeardown() { }
