
var cardSprites: Array<any> = [];
var outlineSprites: Array<Sprite> = [];
var currCard: Int = 0;
self.exports = {
	usable: false,
	cooldown: false,
	cards: [],
	capacity: 0,
	spells: [],
    cardSprites: cardSprites,
    outlineSprites: outlineSprites,
    current: currCard
};


/**
 * @callback PredicateFunction
 * @param {number}
 * @returns {bool}
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
	self.exports.cooldown = true;
	for (spriteObj in cardSprites) {
		applyCooldownFilter(spriteObj);
	};

}

/** 
 * Puts the deck out of cooldown mode.
 */
function endCoolDown() {
	self.exports.cooldown = false;
	for (spriteObj in cardSprites) {
		removeCooldownFilter(spriteObj);
	};
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
	for (spell in self.exports.spells) {
		casted = trySpell(spell, card);
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
	if (!self.exports.cooldown) {
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
	if (self.exports.cards.length < self.exports.capacity) {
		self.exports.cards.push(card);
		var sprite: Sprite = self.exports.cardSprites[self.exports.currCard].sprite;
		sprite.currentFrame = card + 2;
		self.exports.currCard += 1;
		self.exports.usable = self.exports.cards.length == self.exports.capacity;
		startCooldownTimer(60);

	}
}

/** 
 * Initializes the deck with the currently configured spells
 * @param {Object} deck The deck object
 * @param {Int} capacity The maximum number of cards
 * @param {Object[]} spells  The list of spells you want accessible
 */
function initializeDeck(capacity: Int, spells: Array<any>) {
	var spellset = [];
    Engine.log(spells);
	for (spell in spells) {
		spellset.push(spell);
	}
	self.exports.spells = spellset;
	self.exports.capacity = capacity;
}

/** 
 * Draws a card from the top of the deck and uses it to cast a spell
 */
function drawSpell() {
	if (self.exports.cards.length > 0 && !self.exports.cooldown) {
		self.exports.cooldown = true;
		var card = self.exports.cards.pop();
		var sprite = self.exports.cardSprites.pop();
        Engine.log(self.exports.cardSprites);
		sprite.sprite.dispose();
		currCard -= 1;
		castFirstAvailaleSpell(card);
	}
}
self.exports.drawSpell = drawSpell;
self.exports.resizeAndRepositionCard = resizeAndRepositionCard;
self.exports.createSpell = createSpell;
self.exports.initializeDeck = initializeDeck;
self.exports.addCardEvent = addCardEvent;
self.exports.newCoolDownFilter = newCoolDownFilter;
self.exports.createSpriteWithCooldownFilter = createSpriteWithCooldownFilter;





function initialize() {}
function onTeardown() {}
function update() {}