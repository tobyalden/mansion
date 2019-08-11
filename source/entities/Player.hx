package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Player extends Entity
{
    public static inline var SPEED = 100;
    public static inline var ROLL_SPEED = 350;
    public static inline var ROLL_TIME = 0.25;

    private var velocity:Vector2;
    private var isRolling:Bool;
    private var rollCooldown:Alarm;
    private var sprite:Spritemap;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        Key.define("up", [Key.UP, Key.I]);
        Key.define("down", [Key.DOWN, Key.K]);
        Key.define("left", [Key.LEFT, Key.J]);
        Key.define("right", [Key.RIGHT, Key.L]);
        Key.define("roll", [Key.Z]);
        sprite = new Spritemap("graphics/player.png", 16, 16);
        sprite.add("idle", [0]);
        sprite.add("roll", [1]);
        graphic = sprite;
        velocity = new Vector2();
        mask = new Hitbox(16, 16);
        isRolling = false;
        rollCooldown = new Alarm(ROLL_TIME, TweenType.Persist);
        rollCooldown.onComplete.bind(function() {
            isRolling = false;
        });
        addTween(rollCooldown);
    }

    override public function update() {
        movement();
        animation();
        super.update();
    }

    private function movement() {
        if(Input.pressed("roll") && !isRolling) {
            isRolling = true;
            rollCooldown.start();
        }
        if(isRolling) {
            velocity.normalize(ROLL_SPEED);
        }
        else {
            if(Input.check("left")) {
                velocity.x = -1;
            }
            else if(Input.check("right")) {
                velocity.x = 1;
            }
            else {
                velocity.x = 0;
            }
            if(Input.check("up")) {
                velocity.y = -1;
            }
            else if(Input.check("down")) {
                velocity.y = 1;
            }
            else {
                velocity.y = 0;
            }
            velocity.normalize(SPEED);
        }
        moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, "walls");
    }

    private function animation() {
        if(isRolling) {
            sprite.play("roll");
        }
        else {
            sprite.play("idle");
        }
    }
}
