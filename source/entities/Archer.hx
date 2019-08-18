package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import entities.*;
import entities.Level;
import scenes.*;

class Archer extends Enemy
{
    public static inline var SPEED = 50;
    public static inline var SPIT_WINDUP = 0.5;
    public static inline var SPIT_COOLDOWN = 1;
    public static inline var SPIT_SPEED = 300;

    private var sprite:Spritemap;
    private var facing:String;
    private var spitWindup:Alarm;
    private var spitCooldown:Alarm;
    private var sfx:Map<String, Sfx>;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        mask = new Hitbox(24, 24);
        centerOnTile();
        sprite = new Spritemap("graphics/archer.png", 24, 24);
        sprite.add("down", [0, 1], 6);
        sprite.add("right", [2, 3], 6);
        sprite.add("left", [4, 5], 6);
        sprite.add("up", [6, 7], 6);
        sprite.add("down_stopped", [0]);
        sprite.add("right_stopped", [2]);
        sprite.add("left_stopped", [4]);
        sprite.add("up_stopped", [6]);
        sprite.play("down_stopped");
        graphic = sprite;
        facing = "down";
        health = 3;
        spitWindup = new Alarm(SPIT_WINDUP);
        spitWindup.onComplete.bind(function() {
            spit();
            spitCooldown.start();
        });
        addTween(spitWindup);
        spitCooldown = new Alarm(SPIT_COOLDOWN);
        addTween(spitCooldown);
        sfx = [
            "arrowdraw" => new Sfx("audio/arrowdraw.wav"),
            "arrowshoot1" => new Sfx("audio/arrowshoot1.wav"),
            "arrowshoot2" => new Sfx("audio/arrowshoot2.wav"),
            "arrowshoot3" => new Sfx("audio/arrowshoot3.wav")
        ];
    }


    override public function update() {
        super.update();
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
        scene.add(new Spit(this, spitVelocity, SPIT_SPEED));
        sfx['arrowshoot${HXP.choose(1, 2, 3)}'].play();
    }

    override private function act() {
        var player = scene.getInstance("player");
        if(spitWindup.active || spitCooldown.active) {
            sprite.play(facing + "_stopped");
            return;
        }

        if(Math.abs(centerX - player.centerX) < width / 2) {
            if(centerY > player.centerY) {
                facing = "up";
            }
            else if(centerY < player.centerY) {
                facing = "down";
            }
            spitWindup.start();
            sfx['arrowdraw'].play();
            return;
        }
        else if(Math.abs(centerY - player.centerY) < height / 2) {
            if(centerX > player.centerX) {
                facing = "left";
            }
            else if(centerX < player.centerX) {
                facing = "right";
            }
            spitWindup.start();
            sfx['arrowdraw'].play();
            return;
        }

        if(centerY > player.centerY && !isOnTopWall()) {
            velocity.y = -SPEED;
            velocity.x = 0;
            facing = "up";
        }
        else if(centerY < player.centerY && !isOnBottomWall()) {
            velocity.y = SPEED;
            velocity.x = 0;
            facing = "down";
        }
        else {
            velocity.y = 0;
        }
        if(centerX > player.centerX && !isOnLeftWall()) {
            velocity.x = -SPEED;
            velocity.y = 0;
            facing = "left";
        }
        else if(centerX < player.centerX && !isOnRightWall()) {
            velocity.x = SPEED;
            velocity.y = 0;
            facing = "right";
        }
        else {
            velocity.x = 0;
        }
        moveBy(
            velocity.x * HXP.elapsed,
            velocity.y * HXP.elapsed,
            Enemy.groundSolids
        );
        if(velocity.length == 0) {
            if(isOnTopWall()) {
                facing = "up";
            }
            else if(isOnBottomWall()) {
                facing = "down";
            }
            else if(isOnLeftWall()) {
                facing = "left";
            }
            else if(isOnRightWall()) {
                facing = "right";
            }
            sprite.play(facing + "_stopped");
        }
        else {
            sprite.play(facing);
        }
    }
}

