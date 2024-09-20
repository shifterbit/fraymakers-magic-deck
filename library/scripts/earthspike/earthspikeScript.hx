// API Script for Character Template Projectile

var X_SPEED = 0; // X speed of water
var Y_SPEED = 0; // Y Speed of water

var SPAWN_X_DISTANCE = 128;
var SPAWN_Y_DISTANCE = 0;

// Instance vars
var life = self.makeInt(60 * 5);
var originalOwner = null;

function initialize() {
	//self.addEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit, { persistent: true });
	//self.addEventListener(GameObjectEvent.HIT_DEALT, onHit, { persistent: true });
	self.setScaleX(2);
	self.setScaleY(2);

	self.setCostumeIndex(self.getOwner().getCostumeIndex());
	// var owner: Character;
	// var floor = owner.getCurrentFloor();
	// floor.getX

	// Set up horizontal reflection
	Common.enableReflectionListener({ mode: "X", replaceOwner: true });
	Common.repositionToEntityEcb(self.getOwner(), self.flipX(SPAWN_X_DISTANCE), -SPAWN_Y_DISTANCE);




	self.setState(PState.ACTIVE);

	self.setXSpeed(X_SPEED);
	self.setYSpeed(Y_SPEED);
}

function onGroundHit(event) {
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);

	self.toState(PState.DESTROYING);
}

function onHit(event) {
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);

	self.toState(PState.DESTROYING);
}

function update() {
	if (self.finalFramePlayed()) {
		self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
		self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
		self.toState(PState.DESTROYING);
	}
}

function onTeardown() {
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
}