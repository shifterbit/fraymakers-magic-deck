
// API Script for Template Assist

// Set up same states as AssistStats (by excluding "var", these variables will be accessible on timeline scripts!)
STATE_IDLE = 0;
STATE_JUMP = 1;
STATE_FALL = 2;
STATE_SLAM = 3;
STATE_OUTRO = 4;


var SPAWN_X_DISTANCE = 0; // How far in front of player to spawn
var SPAWN_HEIGHT = 0; // How high up from player to spawn


/**
 * @type {Object} Deck
 * @property {boolean} active
 * @property {boolean} cooldown
 * @property {number[]} cards
 * @property {number} capacity
 * @property {function} drawSpell  
 * @property {function} empty
 * @property {function} castable
 * @property {function} createSpell
 * @property {function} initializeDeck
 * @property {function} newCardEvent

 * 
 */

var deckResource = match.createCustomGameObject(self.getResource().getContent("deck"), self);

var deck: object = deckResource.exports;



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



var fireball = deck.createSpell(castFireball, rangeCondition(0, 4), 60, "fireball");
var wind_tornado = deck.createSpell(castWhirlwind, rangeCondition(5, 9), 180, "tornado");

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
	deck.initializeDeck(3, [fireball, wind_tornado], "cards", "cards_cooldown", "card_icons");
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


