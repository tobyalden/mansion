package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Exit extends Entity {
    public var destination(default, null):Vector2;

    public function new(
        x:Float, y:Float, width:Int, height:Int, destination:Vector2
    ) {
        super(x, y);
        this.destination = destination;
        type = "exit";
        graphic = new ColoredRect(width, height, 0x0000FF);
        mask = new Hitbox(width, height);
    }
}
