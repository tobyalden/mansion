package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.tweens.motion.*;
import haxepunk.utils.*;
import scenes.*;

class Ring extends Entity {
    public static inline var MIN_TOSS_TIME = 1.5;
    public static inline var MAX_TOSS_TIME = 2;
    public static inline var CHASE_ACCEL = 350;
    public static inline var CHASE_DECCEL = 100;
    public static inline var MAX_CHASE_SPEED = 150;
    public static inline var RETURN_TIME = 2;

    public var isChasing(default, null):Bool;
    private var ringMaster:RingMaster;
    private var sprite:Spritemap;
    private var tosser:CubicMotion;
    private var velocity:Vector2;
    private var chaseTarget:Entity;
    private var isReturning:Bool;
    private var returnTween:LinearMotion;

    public function new(ringMaster:RingMaster) {
        super();
        this.ringMaster = ringMaster;
        type = "hazard";
        sprite = new Spritemap("graphics/ring.png", 40, 40);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        mask = new Circle(20);
        tosser = new CubicMotion();
        addTween(tosser);
        isChasing = false;
        velocity = new Vector2();
        chaseTarget = null;
        isReturning = false;
        returnTween = new LinearMotion();
        returnTween.onComplete.bind(function() {
            isReturning = false;
        });
        addTween(returnTween);
    }

    private function getCurveControlPoint(target:Entity, flip:Bool) {
        var towardsPlayer = new Vector2(
            target.centerX - centerX, target.centerY - centerY
        );
        var offset = towardsPlayer.clone();
        offset.perpendicular();
        offset.scale(1.5);
        if(flip) {
            offset.inverse();
        }
        towardsPlayer.scale(1.35);
        towardsPlayer.add(offset);
        return towardsPlayer;
    }

    public function chase(target:Entity) {
        isChasing = true;
        chaseTarget = target;
    }

    public function setChaseVelocity() {
        var towardsPlayer = new Vector2(
            chaseTarget.centerX - centerX, chaseTarget.centerY - centerY
        );
        //towardsPlayer.normalize();

        //for(ring in ringMaster.rings) {
            //if(ring == this) {
                //continue;
            //}
            //else {
                //var awayFromRing = new Vector2(
                    //centerX - ring.centerX, centerY - ring.centerY
                //);
                //var distanceFactor = Math.max(
                    //60 - awayFromRing.length, 0
                //) / 60 * 0.75;
                //awayFromRing.normalize(distanceFactor);
                //towardsPlayer.add(awayFromRing);
            //}
        //}

        if(towardsPlayer.length < 50) {
            towardsPlayer.normalize(CHASE_ACCEL * HXP.elapsed);
        }
        else {
            towardsPlayer.normalize(CHASE_ACCEL * HXP.elapsed * 2);
        }
        velocity += towardsPlayer;
        velocity.normalize(MAX_CHASE_SPEED);
    }

    public function toss(clockwise:Bool) {
        if(!tosser.active) {
            var player = scene.getInstance("player");
            var controlPointA = getCurveControlPoint(player, false);
            var controlPointB = getCurveControlPoint(player, true);
            if(clockwise) {
                var temp = controlPointA;
                controlPointA = controlPointB;
                controlPointB = temp;
            }
            tosser.setMotion(
                x, y,
                x + controlPointA.x, y + controlPointA.y,
                x + controlPointB.x, y + controlPointB.y,
                x, y,
                MathUtil.clamp(
                    distanceFrom(player, true) / 50,
                    MIN_TOSS_TIME, MAX_TOSS_TIME
                ),
                Ease.sineInOut
            );
            tosser.start();
        }
    }

    public function returnToRingMaster() {
        isChasing = false;
        isReturning = true;
    }

    override public function update() {
        if(isReturning) {
            if(velocity.length > 0) {
                velocity.x = MathUtil.approach(
                    velocity.x, 0, HXP.elapsed * CHASE_DECCEL
                );
                velocity.y = MathUtil.approach(
                    velocity.y, 0, HXP.elapsed * CHASE_DECCEL
                );
                moveBy(
                    velocity.x * HXP.elapsed, velocity.y * HXP.elapsed
                );
            }
            else {
                if(!returnTween.active) {
                    returnTween.setMotion(
                        x, y,
                        ringMaster.centerX - width / 2,
                        ringMaster.centerY - height / 2,
                        RETURN_TIME,
                        Ease.sineInOut
                    );
                    returnTween.start();
                }
                moveTo(returnTween.x, returnTween.y);
            }
        }
        else if(isChasing) {
            setChaseVelocity();
            moveBy(
                velocity.x * HXP.elapsed, velocity.y * HXP.elapsed
            );
        }
        else if(tosser.active) {
            moveTo(tosser.x, tosser.y);
        }
        else {
            moveTo(
                ringMaster.centerX - width / 2,
                ringMaster.centerY - height / 2
            );
        }
        super.update();
    }

    override public function moveCollideX(e:Entity) {
        velocity.x = -velocity.x;
        return true;
    }

    override public function moveCollideY(e:Entity) {
        velocity.y = -velocity.y;
        return true;
    }
}

