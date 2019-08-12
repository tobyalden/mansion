package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import entities.Level;
import scenes.*;

class Enemy extends Entity
{
    private var startPosition:Vector2;
    private var health:Int;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        type = "enemy";
        startPosition = new Vector2(startX, startY);
        health = 1;
    }

    override public function update() {
        if(!isOnSameScreenAsPlayer()) {
            x = startPosition.x;
            y = startPosition.y;
        }
        else {
            act();
        }
        super.update();
    }

    private function act() {
        // Override in subclasses and add enemy logic here
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

    public function isOnTopWall() {
        for(collideType in ["walls", "enemywalls", "enemy"]) {
            if(collide(collideType, x, y - 1) != null) {
                return true;
            }
        }
        return false;
    }

    public function isOnBottomWall() {
        for(collideType in ["walls", "enemywalls", "enemy"]) {
            if(collide(collideType, x, y + 1) != null) {
                return true;
            }
        }
        return false;
    }

    public function isOnLeftWall() {
        for(collideType in ["walls", "enemywalls", "enemy"]) {
            if(collide(collideType, x - 1, y) != null) {
                return true;
            }
        }
        return false;
    }

    public function isOnRightWall() {
        for(collideType in ["walls", "enemywalls", "enemy"]) {
            if(collide(collideType, x + 1, y) != null) {
                return true;
            }
        }
        return false;
    }

    public function takeHit() {
        health -= 1;
        if(health <= 0) {
            die();
        }
    }

    public function die() {
        scene.remove(this);
    }
}
