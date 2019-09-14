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
    public static inline var BIG_SIZE = 24;

    private var velocity:Vector2;
    private var sfx:Map<String, Sfx>;
    private var speed:Float;
    private var sprite:Image;
    private var accel:Vector2;

    public function new(
        spitter:Entity, velocity:Vector2, speed:Float = DEFAULT_SPEED,
        isBig:Bool = false, accel:Vector2 = null
    ) {
        var size = isBig ? BIG_SIZE : SIZE;
        super(spitter.centerX - size / 2, spitter.centerY - size / 2);
        this.velocity = velocity;
        this.speed = speed;
        velocity.normalize(speed);
        this.accel = accel;
        type = "hazard";
        mask = new Hitbox(size, size);
        if(isBig) {
            sprite = new Image("graphics/bigspit.png");
        }
        else {
            sprite = new Image("graphics/spit.png");
        }
        sprite.x = -(sprite.width - size) / 2;
        sprite.y = -(sprite.height - size) / 2;
        graphic = sprite;
        sfx = [
            "hitwall1" => new Sfx("audio/hitwall1.wav"),
            "hitwall2" => new Sfx("audio/hitwall2.wav"),
            "hitwall3" => new Sfx("audio/hitwall3.wav"),
            "hitwall4" => new Sfx("audio/hitwall4.wav")
        ];
    }

    override public function update() {
        if(accel != null) {
            velocity.x += accel.x * HXP.elapsed;
            velocity.y += accel.y * HXP.elapsed;
        }
        moveBy(
            velocity.x * HXP.elapsed,
            velocity.y * HXP.elapsed,
            ["player"]
            //["walls", "player", "lock"]
        );
        var player = scene.getInstance("player");
        //if(!cast(scene, GameScene).isEntityOnscreen(this)) {
        if(distanceFrom(player) > GameScene.PLAYFIELD_SIZE * 2) {
            scene.remove(this);
        }
        super.update();
    }

    public function destroy() {
        scene.remove(this);
    }

    private function collideEntity(e:Entity) {
        if(e.type == "walls" || e.type == "lock") {
            //sfx['hitwall${HXP.choose(1, 2, 3, 4)}'].play();
            //destroy();
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

    public function isOnSameLevelAsPlayer() {
        var gameScene = cast(scene, GameScene);
        return (
            gameScene.getLevelFromPlayer()
            == gameScene.getLevelFromEntity(this)
        );
    }
}
