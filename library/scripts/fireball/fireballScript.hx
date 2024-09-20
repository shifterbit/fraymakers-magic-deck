// API Script for Character Template Projectile

var X_SPEED = 7; // X speed of water
var Y_SPEED = 0; // Y Speed of water
var SPAWN_X_DISTANCE = 64;
var SPAWN_Y_DISTANCE = 0;

// Instance vars
var life = self.makeInt(60 * 15);
var multiplier = 1;

function initialize() {
	self.setScaleX(0.75);
	self.setScaleY(0.75);

	self.addEventListener(GameObjectEvent.HIT_DEALT, onHit, { persistent: true });

	self.setCostumeIndex(self.getRootOwner().getCostumeIndex());


	// Set up horizontal reflection
	Common.enableReflectionListener({ mode: "X", replaceOwner: true });
	Common.repositionToEntityEcb(self.getOwner(), self.flipX(SPAWN_X_DISTANCE), -SPAWN_Y_DISTANCE);
	// self.setX(self.getOwner().getX());
	// self.setY(self.getOwner().getY());

	self.setState(PState.ACTIVE);
	self.setXSpeed(X_SPEED);
	self.setYSpeed(Y_SPEED);




}

function onGroundHit(event) {
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
}

function onHit(event) {
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
	if (life.get() > 60) {
		life.set(60);
	}
}

function update() {
	self.getOwner().setAssistCharge(0);

	if (self.inState(PState.ACTIVE)) {
		life.dec();
		if (life.get() <= 0) {
			self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
			self.destroy();
		}
	}
	if (self.finalFramePlayed()) {
		self.playFrame(1);
	}
}

function onTeardown() {
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
}