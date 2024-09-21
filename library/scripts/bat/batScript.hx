
var SPAWN_X_DISTANCE = 16;

function initialize() {
    self.setScaleX(1.5);
    self.setScaleY(1.5);
    var glow = new GlowFilter();
    glow.color = 0xFF0000;
    glow.radius = 1;
    self.addFilter(glow);
}
function update() {
    if (self.getOwner().isFacingLeft() && self.isFacingRight()) {
        self.flip();
    }
    if (self.getOwner().isFacingRight() && self.isFacingLeft()) {
        self.flip();
    }

    Common.repositionToEntityEcb(self.getOwner(), -self.flipX(SPAWN_X_DISTANCE), self.getOwner().getEcbHeadY());
}