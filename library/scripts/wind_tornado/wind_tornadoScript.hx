// API Script for Character Template Projectile

var X_SPEED = 0; // X speed of water
var Y_SPEED = -1; // Y Speed of water
var SPAWN_X_DISTANCE = 32 * 2.3;
var SPAWN_Y_DISTANCE = 0;

// Instance vars
var life = self.makeInt(60 * 5);
var originalOwner = null;

function initialize() {
	self.addEventListener(GameObjectEvent.HIT_DEALT, onHit, { persistent: true });
	self.setCostumeIndex(self.getOwner().getCostumeIndex());

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
}


function onHit(event) {
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
	if (life.get() > 160) {
		life.set(160);
	}
}

function turnAround() {
	self.setYSpeed(-X_SPEED);
	X_SPEED = -X_SPEED;
}


function update() {
	self.getOwner().setAssistCharge(0);
	var speedIncrease = 2 / life.get();
	var baseSpeed = Math.abs(self.getYSpeed());
	var speedMultiplier = (baseSpeed + speedIncrease) / baseSpeed;
	self.setYSpeed(self.getYSpeed() * speedMultiplier);



	if (self.inState(PState.ACTIVE)) {
		life.dec();
		if (life.get() <= 0) {
			self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
			self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
			self.toState(PState.DESTROYING);
		}
	}
	if (self.finalFramePlayed()) {
		self.playFrame(1);
	}
}

function onTeardown() {
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
}