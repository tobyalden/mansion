package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Butler extends Entity {
    public function new(x:Float, y:Float) {
        super(x, y);
        type = "npc";
        graphic = new Image("graphics/butler.png");
        mask = new Hitbox(16, 16);
    }

    public function getConversation() {
        return "butler1";
    }
}
