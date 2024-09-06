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
	usable: true,
	cards: [],
	capacity: 0,
	spells: [],
};

function keepAssistBarAtZero(event) {
	self.getOwner().setAssistCharge(0);
}

function lockAssistCharge() {
	self.getOwner().addEventListener(CharacterEvent.ATTACK_END, keepAssistBarAtZero, { persistent: true });
	self.getOwner().addEventListener(CharacterEvent.ATTACK_START, keepAssistBarAtZero, { persistent: true });
}
function unlockAssistCharge() {
	self.getOwner().removeEventListener(CharacterEvent.ATTACK_END, keepAssistBarAtZero);
	self.getOwner().removeEventListener(CharacterEvent.ATTACK_START, keepAssistBarAtZero);
}


function createSpell(spellFn, predicateFn) {
	return {
		cast: spellFn,
		predicate: predicateFn
	};

}

function trySpell(spell, score) {
	if (spell.predicate(score)) {
		spell.cast();
		return true;
	} else {
		return false;
	}
}

function castFirstAvailaleSpell(card: int) {
	for (spell in deck.spells) {
		casted = trySpell(spell, card);
		if (casted) {
			return;
		};
	}
}

function addCardEvent(event: GameObjectEvent) {
	var hitboxStats: HitboxStats = event.data.hitboxStats;
	var damage = hitboxStats.damage;
	addCard(damage);
}

function addCard(value: int) {
	var card = value % 10;
	if (deck.cards.length < deck.capacity) {
		deck.cards.push(card);
		Engine.log(deck);

	} else {

	}
}

function initializeDeckWithSpells(deck, capacity: int, spells) {
	var spellset = [];
	for (spell in spells) {
		Engine.log(spell);
		spellset.push(spell);


	}
	deck.spells = spellset;
	deck.capacity = capacity;
	deck.cards = [];
}




function drawSpell() {
	Engine.log(deck);
	if (deck.cards.length > 0) {
		var card = deck.cards.pop();
		castFirstAvailaleSpell(card);
	}
}

function castFireball() {
	var res = self.getResource().getContent("fireball");
	var proj = match.createProjectile(res, self.getOwner());

	Engine.log("Fireball cast");
	Engine.log(self.getOwner());
}
function alwaysTrue(card) {
	return true;
}
var fireball = createSpell(castFireball, alwaysTrue);

// Runs on object init
function initialize() {
	initializeDeckWithSpells(deck, 3, [fireball]);
	Engine.log("Initializing");
	self.getOwner().addEventListener(GameObjectEvent.HIT_DEALT, addCardEvent, { persistent: true });
	lockAssistCharge();
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
			drawSpell();
			Engine.log(deck);

			Common.startFadeOut();
		}
	} else if (self.inState(STATE_OUTRO)) {
		if (Common.fadeOutComplete() && self.finalFramePlayed()) {
			// Destroy
			self.getOwner().removeEventListener(GameObjectEvent.HIT_DEALT, addCardEvent);
			self.destroy();
		}
	}
}
function onTeardown() {
	lockAssistCharge();


}


