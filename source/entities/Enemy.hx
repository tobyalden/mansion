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
    private var startingHealth:Int;
    private var health:Int;
    private var tweens:Array<Tween>;
    private var velocity:Vector2;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        type = "enemy";
        startPosition = new Vector2(startX, startY);
        health = 1;
        tweens = new Array<Tween>();
        velocity = new Vector2();
    }

    override public function addTween(tween:Tween, start:Bool = false) {
        tweens.push(tween);
        return super.addTween(tween, start);
    }

    public function hasActiveTween() {
        for(tween in tweens) {
            if(tween.active) {
                return true;
            }
        }
        return false;
    }

    private function centerOnTile() {
        x -= (width - Level.TILE_SIZE) / 2;
        y -= (height - Level.TILE_SIZE) / 2;
    }

    override public function update() {
        if(startingHealth == null) {
            startingHealth = health;
        }
        if(!isOnSameScreenAsPlayer()) {
            x = startPosition.x;
            y = startPosition.y;
            velocity.x = 0;
            velocity.y = 0;
            health = startingHealth;
            for(tween in tweens) {
                tween.active = false;
            }
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

    public function collideMultiple(
        collideTypes:Array<String>, collideX:Float, collideY:Float
    ) {
        for(collideType in collideTypes) {
            var collideResult = collide(collideType, collideX, collideY);
            if(collideResult != null) {
                return collideResult;
            }
        }
        return null;
    }

    public function isOnTopWall() {
        if(collideMultiple(["walls", "enemywalls", "enemy"], x, y - 1) != null) {
            return true;
        }
        return false;
    }

    public function isOnBottomWall() {
        if(collideMultiple(["walls", "enemywalls", "enemy"], x, y + 1) != null) {
            return true;
        }
        return false;
    }

    public function isOnLeftWall() {
        if(collideMultiple(["walls", "enemywalls", "enemy"], x - 1, y) != null) {
            return true;
        }
        return false;
    }

    public function isOnRightWall() {
        if(collideMultiple(["walls", "enemywalls", "enemy"], x + 1, y) != null) {
            return true;
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
