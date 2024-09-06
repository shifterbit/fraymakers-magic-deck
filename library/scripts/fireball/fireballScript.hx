// API Script for Character Template Projectile

var X_SPEED = 7; // X speed of water
var Y_SPEED = 0; // Y Speed of water

// Instance vars
var life = self.makeInt(60 * 20);

function initialize(){
	// self.addEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit, { persistent: true });
	// self.addEventListener(GameObjectEvent.HIT_DEALT, onHit, { persistent: true });

	self.setCostumeIndex(self.getRootOwner().getCostumeIndex());

	
    // Set up horizontal reflection
	Common.enableReflectionListener({ mode: "X", replaceOwner: true });
	self.setX(self.getOwner().getX());
	self.setY(self.getOwner().getY());

	self.setState(PState.ACTIVE);
	self.setXSpeed(X_SPEED);
	self.setYSpeed(Y_SPEED);
	

}

function onGroundHit(event) {
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);

	// self.toState(PState.DESTROYING);
}

function onHit(event) {
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);

	// self.toState(PState.DESTROYING);
}

function update() {
	if (self.finalFramePlayed()) {
		self.playFrame(1);
	}
	if (self.inState(PState.ACTIVE)) {
		life.dec();
		if (life.get() <= 0) {
			self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
			self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
			self.toState(PState.DESTROYING);
		}
	}
}

function onTeardown() {
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
}