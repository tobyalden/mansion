package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class FrontDoor extends Entity {
    public function new(x:Float, y:Float, width:Int, height:Int) {
        super(x, y);
        mask = new Hitbox(width, height);
    }

    override public function update() {
        collidable = cast(scene, GameScene).numberOfBossesBeaten() >= 4;
        if(collide("player", x, y) != null) {
            cast(scene, GameScene).leaveHouse();
        }
        super.update();
    }
}

