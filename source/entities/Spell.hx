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

    public var velocity(default, null):Vector2;
    private var sfx:Map<String, Sfx>;
    private var sprite:Spritemap;

    public function new(startX:Float, startY:Float, velocity:Vector2) {
        super(startX - 4, startY - 4);
        this.velocity = velocity;
        type = "spell";
        sprite = new Spritemap("graphics/spells.png", 20, 20);
        sprite.add("idle_vertical", [0, 1], 4);
        sprite.add("idle_horizontal", [2, 3], 4);
        sprite.add("explode", [4, 5, 6], 16, false);
        sprite.x = -(20 - 8) / 2 - 2;
        sprite.y = -(20 - 8) / 2 - 2;
        if(velocity.y < 0) {
            sprite.play("idle_vertical");
        }
        else if(velocity.y > 0) {
            sprite.play("idle_vertical");
            sprite.flipY = true;
        }
        else if(velocity.x < 0) {
            sprite.play("idle_horizontal");
            sprite.flipX = true;
        }
        else if(velocity.x > 0) {
            sprite.play("idle_horizontal");
        }
        graphic = sprite;
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
            ["walls", "enemy", "tail", "lock"]
        );
        if(collidable && !cast(scene, GameScene).isEntityOnscreen(this)) {
            scene.remove(this);
        }
        else if(!collidable && sprite.complete) {
            scene.remove(this);
        }
        super.update();
    }

    private function hitEntity(e:Entity) {
        if(e.type == "enemy") {
            cast(e, Enemy).takeHit(this);
            sfx['hit${HXP.choose(1, 2, 3, 4)}'].play();
        }
        else if(e.type == "tail") {
            cast(e, FollowerTail).head.takeHit(this);
            sfx['hit${HXP.choose(1, 2, 3, 4)}'].play();
        }
        else if(e.type == "walls" || e.type == "lock") {
            sfx['hitwall${HXP.choose(1, 2, 3, 4)}'].play();
        }
        sprite.play("explode");
        collidable = false;
        velocity = new Vector2();
    }

    override public function moveCollideX(e:Entity) {
        hitEntity(e);
        return true;
    }

    override public function moveCollideY(e:Entity) {
        hitEntity(e);
        return true;
    }
}
