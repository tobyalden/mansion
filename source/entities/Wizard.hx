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

class Wizard extends Enemy
{
    public static inline var SIZE = 24;
    public static inline var FADE_TIME = 1;

    private var sprite:Spritemap;
    private var fadeOutTimer:Alarm;
    private var fadeInTimer:Alarm;
    private var preShootTimer:Alarm;
    private var postShootTimer:Alarm;

    // fade out -> teleport -> fade in -> shoot -> fade out

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        mask = new Hitbox(SIZE, SIZE);
        centerOnTile();
        sprite = new Spritemap("graphics/wizard.png", SIZE, SIZE);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        health = 4;

        fadeOutTimer = new Alarm(FADE_TIME, TweenType.Persist);
        fadeOutTimer.onComplete.bind(function() {
            teleport();
            fadeInTimer.start();
        });
        addTween(fadeOutTimer);

        fadeInTimer = new Alarm(FADE_TIME, TweenType.Persist);
        fadeInTimer.onComplete.bind(function() {
            preShootTimer.start();
        });
        addTween(fadeInTimer);

        preShootTimer = new Alarm(FADE_TIME, TweenType.Persist);
        preShootTimer.onComplete.bind(function() {
            spit();
            postShootTimer.start();
        });
        addTween(preShootTimer);

        postShootTimer = new Alarm(FADE_TIME, TweenType.Persist);
        postShootTimer.onComplete.bind(function() {
            fadeOutTimer.start();
        });
        addTween(postShootTimer);
    }

    override public function update() {
        super.update();
    }

    override private function act() {
        if(!hasActiveTween()) {
            fadeOutTimer.start();
        }
        if(fadeInTimer.active) {
            sprite.alpha = fadeInTimer.percent;
        }
        else if(fadeOutTimer.active) {
            sprite.alpha = 1 - fadeOutTimer.percent;
        }
        else {
            sprite.alpha = 1;
        }
    }

    private function teleport() {
        var player = scene.getInstance("player");
        var randomPoint = getRandomPoint();
        // First try to find an open spot with a line of sight to the player
        // that isn't too close to where you are currently
        for(i in 0...1000) {
            if(
                collideMultiple(
                    ["enemy", "player", "walls", "enemywalls"],
                    randomPoint.x, randomPoint.y
                ) != null
                || scene.collideLine(
                    "walls",
                    Std.int(centerX), Std.int(centerY),
                    Std.int(player.centerX), Std.int(player.centerY)
                ) != null
                || distanceToPoint(randomPoint.x, randomPoint.y, true) < 75
            ) {
                randomPoint = getRandomPoint();
            }
            else {
                break;
            } 
            if(i == 99999) {
                trace('giving up!');
            }
        }
        // ...then if you can't, just find an open spot
        for(i in 0...10000) {
            if(
                collideMultiple(
                    ["enemy", "player", "walls", "enemywalls"],
                    randomPoint.x, randomPoint.y
                ) != null
            ) {
                randomPoint = getRandomPoint();
            }
            else {
                break;
            } 
            if(i == 99999) {
                trace('giving up again!');
            }
        }
        x = randomPoint.x;
        y = randomPoint.y;
    }

    private function getRandomPoint() {
        var player = scene.getInstance("player");
        var level = cast(scene, GameScene).getLevelFromEntity(this);
        return new Vector2(
            Math.floor(centerX / GameScene.PLAYFIELD_SIZE)
            * GameScene.PLAYFIELD_SIZE
            + Math.random() * GameScene.PLAYFIELD_SIZE,
            Math.floor(centerY / GameScene.PLAYFIELD_SIZE)
            * GameScene.PLAYFIELD_SIZE
            + Math.random() * GameScene.PLAYFIELD_SIZE
        );

    }

    private function spit() {
        var player = scene.getInstance("player");
        var towardsPlayer = new Vector2(
            player.centerX - centerX, player.centerY - centerY
        );
        scene.add(new Spit(this, towardsPlayer));
    }

    override public function moveCollideX(e:Entity) {
        return true;
    }

    override public function moveCollideY(e:Entity) {
        return true;
    }
}
