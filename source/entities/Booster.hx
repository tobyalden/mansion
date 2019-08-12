package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Booster extends Enemy {
    public static inline var DECCEL = 40;
    public static inline var BOOST_POWER = 140;
    public static inline var MAX_SPEED = 150;
    public static inline var BOUNCE_FACTOR = 0.85;
    public static inline var TIME_BETWEEN_BOOSTS = 2.3;

    private var sprite:Spritemap;
    private var boostTimer:Alarm;
    private var startBoosting:Alarm;
    private var facing:String;
    private var sfx:Map<String, Sfx>;

    public function new(x:Float, y:Float) {
        super(x, y);
        mask = new Hitbox(24, 24);
        centerOnTile();
        type = "enemy";
        sprite = new Spritemap("graphics/booster.png", 24, 24);
        sprite.add("down", [0]);
        sprite.add("right", [1]);
        sprite.add("left", [2]);
        sprite.add("up", [3]);
        sprite.play("down");
        graphic = sprite;

        boostTimer = new Alarm(TIME_BETWEEN_BOOSTS, TweenType.Looping);
        boostTimer.onComplete.bind(function() {
            boost();
        });
        addTween(boostTimer);

        startBoosting = new Alarm(1, TweenType.Persist);
        startBoosting.onComplete.bind(function() {
            boost();
            boostTimer.start();
        });
        addTween(startBoosting);

        health = 4;
        sfx = [
            "boost1" => new Sfx("audio/boost1.wav"),
            "boost2" => new Sfx("audio/boost2.wav"),
            "boost3" => new Sfx("audio/boost3.wav"),
        ];
    }

    private function boost() {
        var player = scene.getInstance("player");
        var towardsPlayer = new Vector2(
            player.centerX - centerX, player.centerY - centerY
        );
        towardsPlayer.normalize(BOOST_POWER);
        velocity = towardsPlayer;
        sfx['boost${HXP.choose(1, 2, 3)}'].play();
    }

    override public function update() {
        if(!boostTimer.active && !startBoosting.active) {
            startBoosting.start();
        }

        var player = scene.getInstance("player");
        if(velocity.length > MAX_SPEED) {
            velocity.normalize(MAX_SPEED);
        }
        var deccelAmount = DECCEL * HXP.elapsed;
        if(velocity.length > deccelAmount) {
            velocity.normalize(velocity.length - deccelAmount);
        } 
        else {
            velocity.normalize(0);
        }

        moveBy(
            velocity.x * HXP.elapsed, velocity.y * HXP.elapsed,
            ["walls", "enemywalls", "enemy"]
        );
        animation();
        super.update();
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

    public override function moveCollideX(e:Entity) {
        velocity.x = -velocity.x * BOUNCE_FACTOR;
        return true;
    }

    public override function moveCollideY(e:Entity) {
        velocity.y = -velocity.y * BOUNCE_FACTOR;
        return true;
    }
}
