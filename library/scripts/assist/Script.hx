
// API Script for Template Assist

// Set up same states as AssistStats (by excluding "var", these variables will be accessible on timeline scripts!)
STATE_IDLE = 0;
STATE_JUMP = 1;
STATE_FALL = 2;
STATE_SLAM = 3;
STATE_OUTRO = 4;


var SPAWN_X_DISTANCE = 0; // How far in front of player to spawn
var SPAWN_HEIGHT = 0; // How high up from player to spawn
var deck = {
	usable: false,
	cooldown: false,
	cards: [],
	capacity: 0,
	spells: [],
};





var cardSprites: Array<Sprite> = [];
var currCard: Int = 0;

/**
 * @callback PredicateFunction
 * @property {number}
 * @return {bool}
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
 * @param {SpellFunction} spellFn
 * @param {PredicateFunction} predicateFn
 * @param {Int} cooldownTIme
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
 * @type {SpellFunction}
 */
function castFireball() {
	var res = self.getResource().getContent("fireball");
	match.createProjectile(res, self.getOwner());
}

/** 
 * @type {SpellFunction}
 */
function castWhirlwind() {
	var res = self.getResource().getContent("wind_tornado");
	match.createProjectile(res, self.getOwner());

}

/**
 * Creates a range condition
 * @param {Int} lo lower bound
 * @param {Int} hi upper bound
 * @returns {PredicateFunction} predicate
 */
function rangeCondition(lo: Int, hi: Int) {
	return function (card) {
		if (card >= lo && card <= hi) {
			return true;
		} else {
			return false;
		}
	}

}


function contains(arr: Array<any>, item: any) {
	for (i in arr) {
		if (i == item) {
			return true;
		}
	}
	return false;
}

var fireball = createSpell(castFireball, rangeCondition(0, 4), 60);
var wind_tornado = createSpell(castWhirlwind, rangeCondition(5, 9), 120);


// Runs on object init
function initialize() {
	initializeDeckWithSpells(deck, 3, [fireball, wind_tornado]);
	var capacity = deck.capacity;
	Engine.forCount(capacity, function (idx: Int) {
		var card = Sprite.create(self.getResource().getContent("cards"));
		cardSprites.push(card);
		return true;
	}, []);

	Engine.forEach(cardSprites, function (sprite: Sprite, idx: Int) {
		self.getOwner().getDamageCounterContainer().addChildAt(sprite, idx);
		sprite.scaleX = 0.75;
		sprite.scaleY = 0.75;
		sprite.x = sprite.x + (40 * idx);
		sprite.y = sprite.y - 8;
		return true;
	}, []);



	self.getOwner().addEventListener(GameObjectEvent.HIT_DEALT, addCardEvent, { persistent: true });
	// Face the same direction as the user
	if (self.getOwner().isFacingLeft()) {
		self.faceLeft();
	}

	// Reposition relative to the user
	Common.repositionToEntityEcb(self.getOwner(), self.flipX(SPAWN_X_DISTANCE), -SPAWN_HEIGHT);

	// Add fade in effect
	Common.startFadeIn();
}


function update() {
	self.getOwner().setAssistCharge(0);
	if (deck.usable) {
		var owner: Character = self.getOwner();
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
		self.getOwner().removeEventListener(GameObjectEvent.HIT_DEALT, addCardEvent);
		if (owner.getHeldControls().ACTION && !deck.cooldown && contains(actionable_animations, owner.getAnimation())) {
			drawSpell();
			if (deck.cards.length == 0) {
				self.destroy();
			}
		}
	}

}
function onTeardown() {

}


/** 
 * Puts the deck in cooldown mode.
 */
function beginCooldown() {
	deck.cooldown = true;

}

/** 
 * Puts the deck out of cooldown mode.
 */
function endCoolDown() {
	deck.cooldown = false;
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
	for (spell in deck.spells) {
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
	if (!deck.cooldown) {
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
	if (deck.cards.length < deck.capacity) {
		deck.cards.push(card);
		var sprite: Sprite = cardSprites[currCard];
		sprite.currentFrame = card + 2;
		currCard += 1;
		deck.usable = deck.cards.length == deck.capacity;
		startCooldownTimer(60);

	}
}

/** 
 * Initializes the deck with the currently configured spells
 * @param {Object} deck The deck object
 * @param {Int} capacity The maximum number of cards
 * @param {Object[]} spells  The list of spells you want accessible
 */
function initializeDeckWithSpells(deck, capacity: Int, spells: Array<any>) {
	var spellset = [];
	for (spell in spells) {
		spellset.push(spell);
	}
	deck.spells = spellset;
	deck.capacity = capacity;
	deck.cards = [];
}

/** 
 * Draws a card from the top of the deck and uses it to cast a spell
 */
function drawSpell() {
	if (deck.cards.length > 0 && !deck.cooldown) {
		deck.cooldown = true;
		var card = deck.cards.pop();
		var sprite: CustomGameObject = cardSprites.pop();
		sprite.dispose();
		currCard -= 1;
		castFirstAvailaleSpell(card);
	}
}