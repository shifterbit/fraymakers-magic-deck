
// API Script for Template Assist

// Set up same states as AssistStats (by excluding "var", these variables will be accessible on timeline scripts!)
STATE_IDLE = 0;
STATE_JUMP = 1;
STATE_FALL = 2;
STATE_SLAM = 3;
STATE_OUTRO = 4;


var SPAWN_X_DISTANCE = 0; // How far in front of player to spawn
var SPAWN_HEIGHT = 0; // How high up from player to spawn



var deckResource = match.createCustomGameObject(self.getResource().getContent("deck"), self);

/**
 * @type {Object} Deck

 * @property {function} createSpell
 * @property {function} initializeDeck
 */
var deck: object = deckResource.exports;


/**
 * @type {SpellFunction}
 */
function castFireball() {
	var res = self.getResource().getContent("fireball");
	match.createProjectile(res, self.getOwner());
	AudioClip.play(self.getResource().getContent("blackMagicSound"));
}

/** 
 * @type {SpellFunction}
 */
function castWhirlwind() {
	var res = self.getResource().getContent("wind_tornado");
	match.createProjectile(res, self.getOwner());
	AudioClip.play(self.getResource().getContent("blackMagicSound"));

}


/** 
 * @type {SpellFunction}
 */
function castIce() {
	var res = self.getResource().getContent("ice");
	match.createProjectile(res, self.getOwner());
	AudioClip.play(self.getResource().getContent("blackMagicSound"));

}
/** 
 * @type {SpellFunction}
 */
function castEarth() {
	var res = self.getResource().getContent("earthspike");
	match.createProjectile(res, self.getOwner());
	AudioClip.play(self.getResource().getContent("blackMagicSound"));


}

function kaiokenMode() {
	var outerGlow = new GlowFilter();
	outerGlow.color = 0xFF0000;
	var middleGlow = new GlowFilter();
	middleGlow.color = 0xF95D74;
	var innerGlow = new GlowFilter();
	innerGlow.color = 0xFFFFFF;


	self.getOwner().addFilter(innerGlow);
	self.getOwner().addFilter(middleGlow);
	self.getOwner().addFilter(outerGlow);
	var doubleDamage = function (event: GameObjectEvent) {
		var baseDamage = event.data.hitboxStats.damage;
		event.data.hitboxStats.damage = baseDamage * 2;
		self.getOwner().setAssistCharge(0);
	};
	self.getOwner().addEventListener(GameObjectEvent.HITBOX_CONNECTED, doubleDamage, { persistent: true });
	self.addTimer(10, 60, function () {
		var owner: Character = self.getRootOwner();
		owner.addDamage(2);
	});

	self.addTimer(1, 60 * 10, function () {
		self.getOwner().setAssistCharge(0);
	});

	self.addTimer(60 * 10, 1, function () {
		self.getOwner().removeEventListener(GameObjectEvent.HITBOX_CONNECTED, doubleDamage);
		self.getOwner().removeFilter(outerGlow);
		self.getOwner().removeFilter(middleGlow);
		self.getOwner().removeFilter(innerGlow);
	}, { persistent: true });
	AudioClip.play(self.getResource().getContent("whiteMagicSound"));

}

function vamparismMode() {
	var innerGlow = new GlowFilter();
	innerGlow.color = 0xFFFFFF;
	var middleGlow = new GlowFilter();
	middleGlow.color = 0xD7BDE2;
	var outerGlow = new GlowFilter();
	outerGlow.color = 0x6c3483;
	var bat: CustomGameObject = match.createCustomGameObject(self.getResource().getContent("bat"), self.getOwner());
	bat.playAnimation("idle");
	var owner: Character = self.getOwner();
	bat.setX(self.getOwner().getX());


	self.getOwner().addFilter(innerGlow);
	self.getOwner().addFilter(middleGlow);
	self.getOwner().addFilter(outerGlow);
	var drain = function (event: GameObjectEvent) {
		var baseDamage = event.data.hitboxStats.damage;
		var foe = event.data.foe;
		var foeAssistCharge = foe.getAssistContentStat("assistChargeValue");
		if (foeAssistCharge >= 0 && foeAssistCharge != null) {
			foe.setAssistCharge(foe.getAssistCharge() - ((baseDamage * 1000) / (1000 * foeAssistCharge)));
		}
		self.getOwner().addDamage(-baseDamage * 0.75);

	};

	self.addTimer(1, 60 * 10, function () {
		self.getOwner().setAssistCharge(0);
	});
	self.getOwner().addEventListener(GameObjectEvent.HIT_DEALT, drain, { persistent: true });
	self.addTimer(60 * 10, 1, function () {
		self.getOwner().removeEventListener(GameObjectEvent.HIT_DEALT, drain);
		bat.destroy();
		self.getOwner().removeFilter(outerGlow);
		self.getOwner().removeFilter(middleGlow);
		self.getOwner().removeFilter(innerGlow);
	}, { persistent: true });
	AudioClip.play(self.getResource().getContent("whiteMagicSound"));


}


/**
 * Creates a range condition
 * @param {Int} lo lower bound
 * @param {Int} hi upper bound
 * @returns {PredicateFunction} predicate
 */
function rangeCondition(lo: Int, hi: Int) {
	return function (card: Int) {
		if (card >= lo && card <= hi) {
			return true;
		} else {
			return false;
		}
	}
}

function airRangeCondition(lo: Int, hi: Int) {
	var predicate = rangeCondition(lo, hi);

	return function (card) {
		return !self.getRootOwner().isOnFloor() && predicate(card);
	}
}

function groundRangeCondition(lo: Int, hi: Int) {
	var predicate = rangeCondition(lo, hi);

	return function (card) {
		return self.getRootOwner().isOnFloor() && predicate(card);
	}
}


function damageRangeCondition(minDamage: Int, maxDamage: Int, lo: Int, hi: Int) {
	var predicate = rangeCondition(lo, hi);

	return function (card) {
		var damage = self.getRootOwner().getDamage();
		var withinDamageRange = damage >= minDamage && damage <= maxDamage;
		return withinDamageRange && predicate(card);
	}
}



var fireball = deck.createSpell(castFireball, airRangeCondition(4, 6), 60, "fireball");
var ice = deck.createSpell(castIce, groundRangeCondition(4, 6), 120, "ice");
var wind_tornado = deck.createSpell(castWhirlwind, airRangeCondition(7, 9), 180, "tornado");
var earthSpike = deck.createSpell(castEarth, groundRangeCondition(7, 9), 120, "earth");
var kaioken = deck.createSpell(kaiokenMode, damageRangeCondition(0, 80, 0, 3), 900, "rage");
var vamparism = deck.createSpell(vamparismMode, damageRangeCondition(81, 999, 0, 3), 900, "vampire");



/** 
 * @type function
 * @description Initializes the deck with the currently configured spells
 * @param {Object} deck The deck object
 * @param {Int} capacity The maximum number of cards
 * @param {Object[]} spells  The list of spells you want accessible
 * @param {string} spriteId
 * @param {string} cooldownOverlayId
 */
var initializeDeck = deck.initializeDeck;
// Runs on object init
function initialize() {
	deck.initializeDeck(3, [fireball, wind_tornado, earthSpike, ice, kaioken, vamparism], "cards", "cards_cooldown", "card_icons");
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

}
function onTeardown() {

}


