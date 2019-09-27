package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Piano extends Entity {
    public function new(x:Float, y:Float) {
        super(x, y);
        type = "piano";
        mask = new Hitbox(32, 16);
    }
}
