package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Spell extends Entity
{
    public static inline var SPEED = 400;

    private var velocity:Vector2;
    private var sfx:Map<String, Sfx>;

    public function new(startX:Float, startY:Float, velocity:Vector2) {
        super(startX - 4, startY - 4);
        this.velocity = velocity;
        graphic = new Image("graphics/spell.png");
        mask = new Hitbox(8, 8);
        //sfx = [
            //"stun1" => new Sfx("audio/stun1.wav")
        //];
    }

    override public function update() {
        velocity.normalize(SPEED);
        moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, "walls");
        super.update();
    }

    override public function moveCollideX(e:Entity) {
        scene.remove(this);
        return true;
    }

    override public function moveCollideY(e:Entity) {
        scene.remove(this);
        return true;
    }
}
