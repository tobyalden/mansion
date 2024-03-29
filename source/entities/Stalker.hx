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

class Stalker extends Enemy
{
    public static inline var SPEED = 50;

    private var sprite:Spritemap;
    private var facing:String;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        mask = new Hitbox(24, 24);
        centerOnTile();
        sprite = new Spritemap("graphics/stalker.png", 24, 24);
        sprite.add("down_stopped", [0]);
        sprite.add("down", [1, 2], 6);
        sprite.add("left_stopped", [3]);
        sprite.add("left", [4, 5], 6);
        sprite.add("right_stopped", [6]);
        sprite.add("right", [7, 8], 6);
        sprite.add("up_stopped", [9]);
        sprite.add("up", [10, 11], 6);
        sprite.play("down_stopped");
        graphic = sprite;
        facing = "down";
        health = 3;
    }

    override private function act() {
        var player = scene.getInstance("player");
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
