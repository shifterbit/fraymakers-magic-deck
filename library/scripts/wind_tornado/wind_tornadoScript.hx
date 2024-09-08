// API Script for Character Template Projectile

var X_SPEED = 0; // X speed of water
var Y_SPEED = -1; // Y Speed of water

// Instance vars
var life = self.makeInt(60 * 5);
var baseLife = 60 * 5;
var originalOwner = null;

function initialize() {
	self.addEventListener(GameObjectEvent.HIT_DEALT, onHit, { persistent: true });
	self.setCostumeIndex(self.getOwner().getCostumeIndex());

	// Set up horizontal reflection
	Common.enableReflectionListener({ mode: "X", replaceOwner: true });

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

	// self.toState(PState.DESTROYING);
}

function turnAround() {
	self.setYSpeed(-X_SPEED);
	X_SPEED = -X_SPEED;

}


function update() {
	var newSpeed = -1 + -1.05*((baseLife - life.get())/baseLife);
	self.setYSpeed(newSpeed);

	
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