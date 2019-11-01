package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class NPC extends Entity {
    public function new(x:Float, y:Float) {
        super(x, y);
        type = "npc";
    }

    public function getConversation() {
        return 'test';
    }
}
