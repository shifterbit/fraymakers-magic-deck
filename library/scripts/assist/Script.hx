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
var currCard: int = 0;

function beginCooldown() {
	deck.cooldown = true;

}
function endCoolDown() {
	deck.cooldown = false;
}

function startCooldownTimer(time: int) {
	beginCooldown();
	self.addTimer(time, 1, endCoolDown, { persistent: true });

}

function zeroAssist() {
	self.getOwner().setAssistCharge(0);

}

function keepAssistBarAtZero(event) {
	zeroAssist();
}

function createSpell(spellFn, predicateFn, cooldownTime: int) {
	return {
		cast: spellFn,
		predicate: predicateFn,
		cooldownTime: cooldownTime
	};

}

function trySpell(spell, score) {
	if (spell.predicate(score)) {
		spell.cast();
		var cooldownTime: int = spell.cooldownTime;
		startCooldownTimer(cooldownTime);
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
	if (!deck.cooldown) {
		var hitboxStats: HitboxStats = event.data.hitboxStats;
		var damage = hitboxStats.damage;
		addCard(damage);
	}
}

function addCard(value: int) {
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

function initializeDeckWithSpells(deck, capacity: int, spells) {
	var spellset = [];
	for (spell in spells) {
		spellset.push(spell);
	}
	deck.spells = spellset;
	deck.capacity = capacity;
	deck.cards = [];
}


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

function castFireball() {
	var res = self.getResource().getContent("fireball");
	match.createProjectile(res, self.getOwner());
}

function castWhirlwind() {
	var res = self.getResource().getContent("wind_tornado");
	match.createProjectile(res, self.getOwner());

}

function rangeCondition(lo: int, hi: int) {
	return function (card) {
		if (card >= lo && card <= hi) {
			return true;
		} else {
			return false;
		}
	}

}

var fireball = createSpell(castFireball, rangeCondition(0,4), 60);
var wind_tornado = createSpell(castWhirlwind, rangeCondition(5,9), 120);


// Runs on object init
function initialize() {
	initializeDeckWithSpells(deck, 3, [fireball, wind_tornado]);
	var capacity = deck.capacity;
	Engine.forCount(capacity, function (idx: int) {
		var card = Sprite.create(self.getResource().getContent("cards"));
		cardSprites.push(card);
		return true;
	}, []);

	Engine.forEach(cardSprites, function (sprite: Sprite, idx: int) {
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
		self.getOwner().removeEventListener(GameObjectEvent.HIT_DEALT, addCardEvent);
		if (owner.getHeldControls().ACTION && !deck.cooldown) {
			drawSpell();
			if (deck.cards.length == 0) {
				self.destroy();
			}
		}
	}

}
function onTeardown() {

}


