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
    public static inline var PAUSE_ON_ROOM_ENTER = 1;
    public static inline var STUN_TIME = 0.15;

    static public var groundSolids = [
        "walls", "lock", "unlock", "enemy", "pits"
    ];
    static public var airSolids = ["walls", "lock", "unlock", "enemy"];

    public var isDead(default, null):Bool;
    public var health(default, null):Int;
    private var startPosition:Vector2;
    private var startingHealth:Int;
    private var tweens:Array<Tween>;
    private var velocity:Vector2;
    private var universalSfx:Map<String, Sfx>;
    private var age:Float;
    private var stunTimer:Alarm;
    private var isBoss:Bool;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        type = "enemy";
        startPosition = new Vector2(startX, startY);
        health = 1;
        tweens = new Array<Tween>();
        velocity = new Vector2();
        universalSfx = [
            "death1" => new Sfx("audio/robotdeath1.wav"),
            "death2" => new Sfx("audio/robotdeath2.wav"),
            "death3" => new Sfx("audio/robotdeath3.wav")
        ];
        age = 0;
        isDead = false;
        stunTimer = new Alarm(STUN_TIME, TweenType.Persist);
        addTween(stunTimer);
        isBoss = false;
        startingHealth = -1;
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
        startPosition.x = x;
        startPosition.y = y;
    }

    private function hasLineOfSightOnPlayer() {
        var player = scene.getInstance("player");
        return scene.collideLine(
            "walls",
            Std.int(centerX), Std.int(centerY),
            Std.int(player.centerX), Std.int(player.centerY)
        ) == null;
    }

    override public function update() {
        graphic.color = stunTimer.active ? 0x000000 : 0xFFFFFF;
        if(startingHealth == -1) {
            startingHealth = health;
        }
        if(!isOnSameLevelAsPlayer()) {
            offscreenReset();
        }
        else {
            if(stunTimer.active && !isBoss) {
                // Do nothing
            }
            else {
                age += HXP.elapsed;
                if(age >= PAUSE_ON_ROOM_ENTER) {
                    act();
                }
            }
        }
        super.update();
    }

    private function offscreenReset() {
        age = 0;
        velocity.x = 0;
        velocity.y = 0;
        health = startingHealth;
        for(tween in tweens) {
            tween.active = false;
        }
    }

    public function resetPosition() {
        x = startPosition.x;
        y = startPosition.y;
    }

    private function act() {
        // Override in subclasses and add enemy logic here
    }

    public function isOnSameLevelAsPlayer() {
        var gameScene = cast(scene, GameScene);
        return (
            gameScene.getLevelFromPlayer()
            == gameScene.getLevelFromEntity(this)
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

    public function takeHit(damageSource:Entity) {
        stunTimer.start();
        health -= 1;
        if(health <= 0) {
            die();
        }
    }

    public function die() {
        isDead = true;
        scene.remove(this);
        explode();
        universalSfx['death${HXP.choose(1, 2, 3)}'].play();
    }

    public function getSpreadAngles(numAngles:Int, maxSpread:Float) {
        var spreadAngles = new Array<Float>();
        var startAngle = -maxSpread / 2;
        var angleIncrement = maxSpread / (numAngles - 1);
        for(i in 0...numAngles) {
            spreadAngles.push(startAngle + angleIncrement * i);
        }
        return spreadAngles;
    }

    public function getSprayAngles(numAngles:Int, maxSpread:Float) {
        var sprayAngles = new Array<Float>();
        for(i in 0...numAngles) {
            sprayAngles.push(-maxSpread / 2 + Random.random * maxSpread);
        }
        return sprayAngles;
    }

    public function getAngleTowardsPlayer() {
        var player = scene.getInstance("player");
        return (
            Math.atan2(player.centerY - centerY, player.centerX - centerX)
        );
    }

    private function explode(
        numExplosions:Int = 2, speed:Float = 600, goQuickly:Bool = true,
        goSlowly:Bool = false
    ) {
        var directions = new Array<Vector2>();
        for(i in 0...numExplosions) {
            var angle = (2/numExplosions) * i;
            directions.push(new Vector2(Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(Math.cos(angle), -Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), -Math.sin(angle)));
        }
        var count = 0;
        for(direction in directions) {
            direction.scale(speed * Math.random());
            direction.normalize(
                Math.max(0.1 + 0.2 * Math.random(), direction.length)
            );
            var explosion = new DeathParticle(
                centerX, centerY, directions[count], goQuickly, goSlowly
            );
            explosion.layer = -99;
            scene.add(explosion);
            count++;
        }
    }

    override public function updateTweens(elapsed:Float) {
        if(stunTimer.active && !isBoss) {
            stunTimer.update(elapsed);
            return;
        }
        else {
            super.updateTweens(elapsed);
        }
	}
}
