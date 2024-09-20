// API Script for Character Template Projectile

var X_SPEED = 7; // X speed of water
var Y_SPEED = 0; // Y Speed of water
var maxspd = 1.5;
// Instance vars
var life = self.makeInt(60 * 8);
var originalOwner = null;
var target = self.makeObject(null);
var accel = .5; //Acceleration.
//  The rate at which it accelerates towards the target.
var baseSpeed = 3.5;  //Base Speed.
//How fast the projectile will when first spawned.
var ang = self.makeFloat(0);  //Angle
//The angle between the projectile and it's target.


var pos = self.makePoint(self.getX(), self.getY() + self.getEcbLeftHipY());  //Position
var distance = self.makeFloat(Math.POSITIVE_INFINITY);

var owner: Character = self.getRootOwner();


var vfx = self.makeObject(null);

function setTarget() {
	for (player in owner.getFoes()) {// player is any one of the owner's "foes". This will iterate through all of them.

		var tpos = Point.create(player.getX(), player.getY() + player.getEcbLeftHipY()); //target position
		// the position of the current foe, centered like before.
		var dis = pos.distanceSquared(tpos); //distance between you and the current foe... kinda.
		if (dis < distance.get()) {
			// if the current foe is closer than the targeted foe, then change the target and distance to be this foe.
			target.set(player);
			distance.set(dis);
		}
		tpos.dispose();//dispose of points whenever you are done using them.
	}
}

function aim() {
	var targetP = target.get();
	var pos = Point.create(self.getX(), self.getY() + self.getEcbLeftHipY());
	var tpos = Point.create(targetP.getX(), targetP.getY() + targetP.getEcbLeftHipY());
	//as with the targeting code, we're defining the positions of both the player, and the target as points.

	ang.set(Math.getAngleBetween(pos, tpos));  //Yes, finding the angle between 2 points is really this simple.
	//specifically, it finds the angle that the first point would have to move to reach the second point. Which is exactly what we want.

	pos.dispose();//dispose of points whenever you are done using them.
	tpos.dispose();//dispose of points whenever you are done using them.
}
function move(spd: Number) {

	self.setXVelocity(self.getXVelocity() + Math.calculateXVelocity(spd, ang.get()));
	self.setYVelocity(self.getYVelocity() + Math.calculateYVelocity(-spd, ang.get()));
	var spdang = Math.calculateSpeed(self.getXVelocity(), self.getYVelocity());// Speed at Angle (current speed)
	if (spdang > maxspd) {
		self.setXVelocity(self.getXVelocity() * maxspd / spdang);
		self.setYVelocity(self.getYVelocity() * maxspd / spdang);
	}
}


function initialize() {
	//	self.addEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit, { persistent: true });
	self.setScaleX(0.4);
	self.setScaleY(0.4);
	self.addEventListener(GameObjectEvent.HIT_DEALT, onHit, { persistent: true });
	self.addEventListener(GameObjectEvent.REFLECTED, function (event: GameObjectEvent) { setTarget(); }, {persistent: true});

	self.setCostumeIndex(self.getOwner().getCostumeIndex());

	// Set up horizontal reflection
	Common.enableReflectionListener({ mode: "X", replaceOwner: true });


	Common.repositionToEntityEcb(self.getOwner(), self.flipX(64), -50);
	self.setState(PState.ACTIVE);
	self.addTimer(1, -1, function () {
		self.setRotation(self.getRotation() + 4);
	});
	setTarget();
	// self.setXSpeed(X_SPEED);
	// self.setYSpeed(Y_SPEED);


	aim();
	move(1);
}

function onGroundHit(event) {
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);

	self.toState(PState.DESTROYING);
}

function onHit(event) {
	if (vfx.get() == null) {
		vfx.set(match.createVfx(new VfxStats({ spriteContent: self.getResource().getContent("ice"), animation: "vfx" }), self));

	}
	if (life.get() > 60) {
		life.set(60);
	}
}

function update() {
	aim();
	move(accel);
	if (life.get() % 20 == 0) {
		self.reactivateHitboxes();
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