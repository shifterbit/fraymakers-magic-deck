
// API Script for Template Assist

// Set up same states as AssistStats (by excluding "var", these variables will be accessible on timeline scripts!)
STATE_IDLE = 0;
STATE_JUMP = 1;
STATE_FALL = 2;
STATE_SLAM = 3;
STATE_OUTRO = 4;


var SPAWN_X_DISTANCE = 0; // How far in front of player to spawn
var SPAWN_HEIGHT = 0; // How high up from player to spawn


var deck = match.createCustomGameObject(self.getResource().getContent("deck"), self).exports;


// Just a helper function to check if an array contains something
function contains(arr: Array<any>, item: any) {
    for (i in arr) {
        if (i == item) {
            return true;
        }
    }
    return false;
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



var fireball = deck.createSpell(castFireball, rangeCondition(0,4), 60);
var wind_tornado = deck.createSpell(castWhirlwind, rangeCondition(5, 9), 120);


// Runs on object init
function initialize() {
	deck.initializeDeck(3, [fireball, wind_tornado]);
	var capacity = deck.capacity;
	Engine.forCount(capacity, function (idx: Int) {
		var card = Sprite.create(self.getResource().getContent("cards"));
		var cardOutline = Sprite.create(self.getResource().getContent("cards"));
		deck.cardSprites.push(deck.createSpriteWithCooldownFilter(card, deck.newCoolDownFilter));
		deck.outlineSprites.push(cardOutline);

		return true;
	}, []);

	Engine.forCount(deck.cardSprites.length, function (idx: Int) {
		var sprite = deck.cardSprites[idx].sprite;
		var outline = deck.outlineSprites[idx];
		self.getOwner().getDamageCounterContainer().addChild(sprite);
		self.getOwner().getDamageCounterContainer().addChild(outline);
		deck.resizeAndRepositionCard(sprite, idx);
		deck.resizeAndRepositionCard(outline, idx);
		return true;
	}, []);



	self.getOwner().addEventListener(GameObjectEvent.HIT_DEALT, deck.addCardEvent, { persistent: true });
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



		self.getOwner().removeEventListener(GameObjectEvent.HIT_DEALT, deck.addCardEvent);
		if (owner.getHeldControls().ACTION && !deck.cooldown && contains(actionable_animations, owner.getAnimation())) {
			deck.drawSpell();
			if (deck.cards.length == 0) {
				for (i in deck.outlineSprites) {
					i.dispose();

				}

				self.destroy();

			}
		}
	}

}
function onTeardown() {

}


