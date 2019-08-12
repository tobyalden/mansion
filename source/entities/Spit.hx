package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Spit extends Entity
{
    public static inline var SPEED = 200;

    private var velocity:Vector2;
    private var sfx:Map<String, Sfx>;

    public function new(startX:Float, startY:Float, velocity:Vector2) {
        super(startX - 4, startY - 4);
        this.velocity = velocity;
        type = "hazard";
        graphic = new Image("graphics/spit.png");
        mask = new Hitbox(8, 8);
        sfx = [
            "hitwall1" => new Sfx("audio/hitwall1.wav"),
            "hitwall2" => new Sfx("audio/hitwall2.wav"),
            "hitwall3" => new Sfx("audio/hitwall3.wav"),
            "hitwall4" => new Sfx("audio/hitwall4.wav")
        ];
    }

    override public function update() {
        velocity.normalize(SPEED);
        moveBy(
            velocity.x * HXP.elapsed,
            velocity.y * HXP.elapsed,
            ["walls"]
        );
        super.update();
    }

    override public function moveCollideX(e:Entity) {
        if(e.type == "walls") {
            sfx['hitwall${HXP.choose(1, 2, 3, 4)}'].play();
        }
        scene.remove(this);
        return true;
    }

    override public function moveCollideY(e:Entity) {
        if(e.type == "walls") {
            sfx['hitwall${HXP.choose(1, 2, 3, 4)}'].play();
        }
        scene.remove(this);
        return true;
    }
}

