// API Script for Character Template Projectile

var X_SPEED = 7; // X speed of water
var Y_SPEED = 0; // Y Speed of water

// Instance vars
var life = self.makeInt(60 * 15);
var multiplier = 1;

function initialize() {
	self.addEventListener(GameObjectEvent.HIT_DEALT, onHit, { persistent: true });

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