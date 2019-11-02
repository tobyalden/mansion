package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Bouncer extends Enemy {
    public static inline var MAX_SPEED = 75;

    private var sprite:Spritemap;
    private var sfx:Map<String, Sfx>;

    public function new(x:Float, y:Float) {
        super(x, y);
        mask = new Hitbox(24, 24);
        centerOnTile();
        type = "enemy";
        sprite = new Spritemap("graphics/bouncer.png", 24, 24);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        health = 3;
        //sfx = [
            //"bounce1" => new Sfx("audio/bounce1.ogg"),
            //"bounce2" => new Sfx("audio/bounce2.ogg"),
            //"bounce3" => new Sfx("audio/bounce3.ogg"),
        //];
    }
    
    override private function act() {
        var player = scene.getInstance("player");
        if(velocity.x == 0) {
            velocity.x = x > player.x ? MAX_SPEED : -MAX_SPEED;
        }
        if(velocity.y == 0) {
            velocity.y = y > player.y ? MAX_SPEED : -MAX_SPEED;
        }
        moveBy(
            velocity.x * HXP.elapsed, velocity.y * HXP.elapsed,
            Enemy.groundSolids
        );
        sprite.flipX = velocity.x < 0;
    }

    public override function moveCollideX(e:Entity) {
        velocity.x = -velocity.x;
        return true;
    }

    public override function moveCollideY(e:Entity) {
        velocity.y = -velocity.y;
        return true;
    }
}

