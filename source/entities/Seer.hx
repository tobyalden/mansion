package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import entities.*;
import entities.Level;
import scenes.*;

class Seer extends Enemy
{
    public static inline var ACCEL = 60;
    public static inline var DECCEL = 100;
    public static inline var MAX_SPEED = 72;
    public static inline var SPIT_COOLDOWN = 2;
    public static inline var SIZE = 24;

    private var sprite:Spritemap;
    private var facing:String;
    private var spitTimer:NumTween;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        mask = new Hitbox(SIZE, SIZE);
        centerOnTile();
        sprite = new Spritemap("graphics/seer.png", SIZE, SIZE);
        sprite.add("down", [0]);
        sprite.add("right", [1]);
        sprite.add("left", [2]);
        sprite.add("up", [3]);
        sprite.play("down");
        graphic = sprite;
        facing = "down";
        health = 5;
        spitTimer = new NumTween(TweenType.PingPong);
        spitTimer.tween(0, 1, SPIT_COOLDOWN, Ease.sineInOut);
        spitTimer.onComplete.bind(function() {
            if(
                spitTimer.forward
                && cast(scene, GameScene).isEntityOnscreen(this)
                && hasLineOfSightOnPlayer()
            ) {
                spit();
            }
        });
        addTween(spitTimer, true);
    }

    override public function update() {
        super.update();
    }

    override private function act() {
        if(!spitTimer.active) {
            spitTimer.start();
        }
        var player = scene.getInstance("player");

        if(Math.abs(centerX - player.centerX) < width / 2) {
            velocity.x = MathUtil.approach(
                velocity.x, 0, DECCEL * HXP.elapsed
            );
        }
        if(centerX > player.centerX) {
            velocity.x -= ACCEL * HXP.elapsed;
        }
        else if(centerX < player.centerX) {
            velocity.x += ACCEL * HXP.elapsed;
        }

        if(Math.abs(centerY - player.centerY) < width) {
            velocity.y = MathUtil.approach(
                velocity.y, 0, DECCEL * HXP.elapsed
            );
        }
        else if(centerY < player.centerY) {
            velocity.y += ACCEL * HXP.elapsed;
        }
        else if(centerY > player.centerY) {
            velocity.y -= ACCEL * HXP.elapsed;
        }

        if(velocity.x > MAX_SPEED) {
            velocity.x = MAX_SPEED;
        }
        else if(velocity.x < -MAX_SPEED) {
            velocity.x = -MAX_SPEED;
        }
        if(velocity.y > MAX_SPEED) {
            velocity.y = MAX_SPEED;
        }
        else if(velocity.y < -MAX_SPEED) {
            velocity.y = -MAX_SPEED;
        }
        moveBy(
            velocity.x * HXP.elapsed * spitTimer.percent,
            velocity.y * HXP.elapsed * spitTimer.percent,
            Enemy.airSolids
        );
        animation();
    }

    private function spit() {
        var spitVelocity;
        if(facing == "up") {
            spitVelocity = new Vector2(0, -1);
        }
        else if(facing == "down") {
            spitVelocity = new Vector2(0, 1);
        }
        else if(facing == "left") {
            spitVelocity = new Vector2(-1, 0);
        }
        else {
            // facing == "right"
            spitVelocity = new Vector2(1, 0);
        }
        scene.add(new Spit(this, spitVelocity));
    }

    override public function moveCollideX(e:Entity) {
        velocity.x = 0;
        return true;
    }

    override public function moveCollideY(e:Entity) {
        velocity.y = 0;
        return true;
    }

    private function animation() {
        var player = scene.getInstance("player");
        if(
            Math.abs(centerX - player.centerX)
            > Math.abs(centerY - player.centerY)
        ) {
            if(centerX > player.centerX) {
                facing = "left";
            }
            else {
                facing = "right";
            }
        }
        else {
            if(centerY > player.centerY) {
                facing = "up";
            }
            else {
                facing = "down";
            }
        }
        sprite.play(facing);
    }
}
