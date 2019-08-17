package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class FollowerTail extends Entity {
    public var head(default, null):Enemy;

    public function new(x:Float, y:Float, head:Enemy) {
        super(x, y);
        this.head = head;
        type = "tail";
        mask = new Circle(9);
        graphic = new Image("graphics/followertail.png");
    }
}
