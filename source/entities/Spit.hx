package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Spit extends Entity
{
    public static inline var DEFAULT_SPEED = 200;
    public static inline var SIZE = 8;

    private var velocity:Vector2;
    private var sfx:Map<String, Sfx>;
    private var speed:Int;

    public function new(
        spitter:Entity, velocity:Vector2, speed:Int = DEFAULT_SPEED
    ) {
        super(spitter.centerX - SIZE / 2, spitter.centerY - SIZE / 2);
        this.velocity = velocity;
        this.speed = speed;
        type = "hazard";
        mask = new Hitbox(SIZE, SIZE);
        graphic = new Image("graphics/spit.png");
        graphic.x = -4;
        graphic.y = -4;
        sfx = [
            "hitwall1" => new Sfx("audio/hitwall1.wav"),
            "hitwall2" => new Sfx("audio/hitwall2.wav"),
            "hitwall3" => new Sfx("audio/hitwall3.wav"),
            "hitwall4" => new Sfx("audio/hitwall4.wav")
        ];
    }

    override public function update() {
        velocity.normalize(speed);
        moveBy(
            velocity.x * HXP.elapsed,
            velocity.y * HXP.elapsed,
            ["walls", "player"]
        );
        if(!isOnSameScreenAsPlayer()) {
            scene.remove(this);
        }
        super.update();
    }

    private function collideEntity(e:Entity) {
        if(e.type == "walls") {
            //sfx['hitwall${HXP.choose(1, 2, 3, 4)}'].play();
            scene.remove(this);
        }
        else if(e.type == "player") {
            var player = cast(e, Player);
            if(player.canBeHitBySpit()) {
                player.takeHit(this);
            }
            return false;
        }
        return true;
    }

    override public function moveCollideX(e:Entity) {
        return collideEntity(e);
    }

    override public function moveCollideY(e:Entity) {
        return collideEntity(e);
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

