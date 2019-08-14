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

    static private var possiblePoints:Array<Vector2>;

    private var sprite:Spritemap;
    private var fadeOutTimer:Alarm;
    private var fadeInTimer:Alarm;
    private var preShootTimer:Alarm;
    private var postShootTimer:Alarm;

    // fade out -> teleport -> fade in -> shoot -> fade out

    public function new(startX:Float, startY:Float) {
        if(possiblePoints == null) {
            possiblePoints = new Array<Vector2>();
            for(possibleX in 0...Std.int(GameScene.PLAYFIELD_SIZE / 10)) {
                for(possibleY in 0...Std.int(GameScene.PLAYFIELD_SIZE / 10)) {
                    possiblePoints.push(
                        new Vector2(possibleX * 10, possibleY * 10)
                    );
                }
            }
        }
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
        HXP.shuffle(possiblePoints);
        var teleportTo = new Vector2(x, y);
        // First try to find an open spot with a line of sight to the player
        // that isn't too close to where you are currently
        for(possiblePoint in possiblePoints) {
            var screenCoordinates = cast(
                scene, GameScene
            ).getScreenCoordinates(this);
            var possiblePointOffset = new Vector2(
                possiblePoint.x
                + screenCoordinates.x * GameScene.PLAYFIELD_SIZE,
                possiblePoint.y
                + screenCoordinates.y * GameScene.PLAYFIELD_SIZE
            );
            if(
                collideMultiple(
                    ["enemy", "player", "walls", "enemywalls"],
                    possiblePointOffset.x, possiblePointOffset.y
                ) == null
                && scene.collideLine(
                    "walls",
                    Std.int(possiblePointOffset.x + width / 2),
                    Std.int(possiblePointOffset.y + height / 2),
                    Std.int(player.centerX),
                    Std.int(player.centerY)
                ) == null
                && distanceToPoint(
                    possiblePointOffset.x, possiblePointOffset.y, true
                ) > 70
            ) {
                teleportTo = possiblePointOffset;
                break;
            }
        }
        x = teleportTo.x;
        y = teleportTo.y;
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
