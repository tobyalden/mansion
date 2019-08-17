package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Follower extends Enemy {
    public static inline var ACCEL = 60;
    public static inline var MAX_SPEED = 60;
    public static inline var INITIAL_SPEED_INCREASE_RATE = 1;

    private var sprite:Spritemap;
    private var sfx:Map<String, Sfx>;
    private var initialSpeedMultiplier:Float;

    public function new(x:Float, y:Float) {
        super(x, y);
        mask = new Hitbox(24, 24);
        centerOnTile();
        type = "enemy";
        sprite = new Spritemap("graphics/follower.png", 24, 24);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        health = 3;
        initialSpeedMultiplier = 0;
        //sfx = [
            //"bounce1" => new Sfx("audio/bounce1.wav"),
            //"bounce2" => new Sfx("audio/bounce2.wav"),
            //"bounce3" => new Sfx("audio/bounce3.wav"),
        //];
    }

    override private function offscreenReset() {
        initialSpeedMultiplier = 0;
        super.offscreenReset();
    }
    
    override private function act() {
        // TODO: Add delay before they start moving
        initialSpeedMultiplier = Math.min(
            initialSpeedMultiplier + INITIAL_SPEED_INCREASE_RATE * HXP.elapsed,
            1
        );
        var player = scene.getInstance("player");
        var towardsPlayer = new Vector2(
            player.centerX - centerX, player.centerY - centerY
        );
        var accel:Float = ACCEL * initialSpeedMultiplier;
        if(distanceFrom(player, true) < 50) {
            accel *= 2.5;
        }
        towardsPlayer.normalize(accel * HXP.elapsed);
        velocity.add(towardsPlayer);
        velocity.normalize(MAX_SPEED);
        moveBy(
            velocity.x * HXP.elapsed * initialSpeedMultiplier,
            velocity.y * HXP.elapsed * initialSpeedMultiplier,
            ["walls", "enemywalls", "enemy", "pits"]
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


