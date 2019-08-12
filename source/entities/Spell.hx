package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Spell extends Entity
{
    public static inline var SPEED = 400;

    private var velocity:Vector2;
    private var sfx:Map<String, Sfx>;

    public function new(startX:Float, startY:Float, velocity:Vector2) {
        super(startX - 4, startY - 4);
        this.velocity = velocity;
        type = "spell";
        graphic = new Image("graphics/spell.png");
        mask = new Hitbox(8, 8);
        sfx = [
            "hit1" => new Sfx("audio/hit1.wav"),
            "hit2" => new Sfx("audio/hit2.wav"),
            "hit3" => new Sfx("audio/hit3.wav"),
            "hit4" => new Sfx("audio/hit4.wav"),
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
            ["walls", "enemy"]
        );
        if(!isOnSameScreenAsPlayer()) {
            scene.remove(this);
        }
        super.update();
    }

    override public function moveCollideX(e:Entity) {
        if(e.type == "enemy") {
            cast(e, Enemy).takeHit();
            sfx['hit${HXP.choose(1, 2, 3, 4)}'].play();
        }
        else if(e.type == "walls") {
            sfx['hitwall${HXP.choose(1, 2, 3, 4)}'].play();
        }
        scene.remove(this);
        return true;
    }

    override public function moveCollideY(e:Entity) {
        if(e.type == "enemy") {
            cast(e, Enemy).takeHit();
            sfx['hit${HXP.choose(1, 2, 3, 4)}'].play();
        }
        else if(e.type == "walls") {
            sfx['hitwall${HXP.choose(1, 2, 3, 4)}'].play();
        }
        scene.remove(this);
        return true;
    }

    public function isOnSameScreenAsPlayer() {
        var myCoordinates = cast(scene, GameScene).getScreenCoordinates(this);
        var playerCoordinates = cast(scene, GameScene).getScreenCoordinates(
            scene.getInstance("player")
        );
        return (
            myCoordinates.x == playerCoordinates.x
            && myCoordinates.y == playerCoordinates.y
        );
    }
}
