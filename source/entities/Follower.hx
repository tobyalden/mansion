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
    public static inline var DISTANCE_BETWEEN_TAILS = 10;
    public static inline var NUMBER_OF_TAILS = 7;

    public var tails(default, null):Array<Entity>;
    private var sprite:Spritemap;
    private var sfx:Map<String, Sfx>;
    private var initialSpeedMultiplier:Float;
    private var locationHistory:Array<Vector2>;
    private var locationRecorder:Alarm;

    public function new(x:Float, y:Float) {
        super(x, y);
        mask = new Circle(12);
        centerOnTile();
        type = "enemy";
        sprite = new Spritemap("graphics/follower.png", 24, 24);
        sprite.add("idle", [0]);
        sprite.play("idle");
        addGraphic(sprite);
        tails = new Array<Entity>();
        for(i in 0...NUMBER_OF_TAILS) {
            var tail = new FollowerTail(x + 3, y + 3, this);
            tails.push(tail);
        }
        health = 6;
        initialSpeedMultiplier = 0;
        locationHistory = new Array<Vector2>();
        locationRecorder = new Alarm(
            (1 / HXP.assignedFrameRate) / 2, TweenType.Looping
        );
        locationRecorder.onComplete.bind(function() {
            recordLocation();
        });
        addTween(locationRecorder);
        //sfx = [
            //"bounce1" => new Sfx("audio/bounce1.ogg"),
            //"bounce2" => new Sfx("audio/bounce2.ogg"),
            //"bounce3" => new Sfx("audio/bounce3.ogg"),
        //];
    }

    override public function resetPosition() {
        super.resetPosition();
        for(tail in tails) {
            tail.moveTo(x + 3, y + 3);
        }
    }

    private function recordLocation() {
        var newLocation = new Vector2(x, y);
        locationHistory.push(newLocation);
        if(locationHistory.length > DISTANCE_BETWEEN_TAILS * NUMBER_OF_TAILS) {
            locationHistory.shift();
        }
    }

    override public function die() {
        for(tail in tails) {
            cast(tail, FollowerTail).die();
        }
        super.die();
    }

    override private function offscreenReset() {
        initialSpeedMultiplier = 0;
        locationHistory = new Array<Vector2>();
        super.offscreenReset();
    }
    
    override private function act() {
        if(!locationRecorder.active) {
            locationHistory.push(new Vector2(x, y));
            locationRecorder.start();
        }
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

        var tailCount = 0;
        for(tail in tails) {
            var tailIndice = Std.int(Math.min(
                tailCount * DISTANCE_BETWEEN_TAILS, locationHistory.length - 1
            ));
            tail.x = locationHistory[tailIndice].x + 3;
            tail.y = locationHistory[tailIndice].y + 3;
            tailCount++;
        }

        moveBy(
            velocity.x * HXP.elapsed * initialSpeedMultiplier,
            velocity.y * HXP.elapsed * initialSpeedMultiplier,
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


