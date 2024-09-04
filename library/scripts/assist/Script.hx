// API Script for Template Assist

// Set up same states as AssistStats (by excluding "var", these variables will be accessible on timeline scripts!)
STATE_IDLE = 0;
STATE_JUMP = 1;
STATE_FALL = 2;
STATE_SLAM = 3;
STATE_OUTRO = 4;



var SPAWN_X_DISTANCE = 0; // How far in front of player to spawn
var SPAWN_HEIGHT = 0; // How high up from player to spawn
var deck = {};
var deckFull = false;


function createSpell(spellFn, predicateFn) {
	return [spellFn, predicateFn];
}

function trySpell(spell, score) {
	if (spell.predicate(score)) {
		spell.cast();
		return true;
	} else {
		return false;
	}
}

function castFirstAvailaleSpell(deck) {
	var spellList = deck.spells;
	var score = deck.score;
	for (spell in spellList) {
		casted = trySpell(spell, score);
		if (casted) {
			return;
		};

	}
}

function addCard(event: GameObjectEvent) {
	var hitboxStats: HitboxStats = event.data.hitboxStats;
	var damage = hitboxStats.damage;
	var card = damage % 10;
	Engine.log(damage);
	Engine.log(hitboxStats);
	Engine.log(card);
	if (deck.cards.length < 3) {
		deck.cards.push(card);
	};
	Engine.log(deck);
	Engine.log(deck.cards);
	Engine.log("GOT EVENT");

}


function initializeDeckWithSpells(deck, max, spells: Array<Array<Dynamic>>) {
	var spellset = [];
	for (spell in spells) {
		action = spell[0];
		predicate = spell[1];
		magicSpell = {
			cast: actiion,
			predicate: predicate
		};
		spellset.push(magicSpell);


	}
	deck.spells = spellset;
	deck.max = max;
	deck.cards = [];
	deck.score = -1;
}

function getDeckScore() {
	if (deck.score != -1) {
		return deck.score;
	}


	sum = 0;
	for (card in deck.cards) {
		sum += card;
	}
	deck.score = sum;
	return deck.score;
}


// Runs on object init
function initialize() {
	initializeDeckWithSpells(deck, 0, []);
	Engine.log("Initializing");
	self.getOwner().addEventListener(GameObjectEvent.HIT_DEALT, addCard, {persistent: true});
	Engine.log("Added Event Listener");
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
	// Behavior for each state
	if (self.inState(STATE_IDLE)) {
		if (self.finalFramePlayed()) {
			// Bounce into air, activate gravity, and switch to jump state
			self.unattachFromFloor();
			self.setYVelocity(-20);
			self.updateGameObjectStats({ gravity: 1 });
			self.toState(STATE_JUMP);
		}
	} else if (self.inState(STATE_JUMP)) {
		// Wait until assist starts to fall
		if (self.getYVelocity() >= 0) {
			// Move to fall state
			self.toState(STATE_FALL);
		}
	} else if (self.inState(STATE_FALL)) {
		// Wait until assist lands
		if (self.isOnFloor()) {
			// Fire two projectiles and switch to slam state
			var proj1 = match.createProjectile(self.getResource().getContent("assisttemplateProjectile"), self);
			var proj2 = match.createProjectile(self.getResource().getContent("assisttemplateProjectile"), self);
			proj2.flip(); // Flip the other projectile the opposite way
			self.toState(STATE_SLAM);
		}
	} else if (self.inState(STATE_SLAM)) {
		if (self.finalFramePlayed()) {
			// Move to outro state and start fading away
			self.toState(STATE_OUTRO);
			Common.startFadeOut();
		}
	} else if (self.inState(STATE_OUTRO)) {
		if (Common.fadeOutComplete() && self.finalFramePlayed()) {
			// Destroy
			self.getOwner().removeEventListener(GameObjectEvent.HIT_DEALT, addCard);
			self.destroy();
		}
	}
}
function onTeardown() {

}


