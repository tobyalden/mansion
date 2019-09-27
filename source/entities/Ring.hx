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
    public static inline var ENRAGE_MIN_TOSS_TIME = 1.1;
    public static inline var ENRAGE_MAX_TOSS_TIME = 1.5;
    public static inline var CHASE_ACCEL = 350;
    public static inline var CHASE_DECCEL = 100;
    public static inline var MAX_CHASE_SPEED = 150;
    public static inline var BOUNCE_SPEED = 150;
    public static inline var RETURN_TIME = 1.5;
    public static inline var ENRAGE_RETURN_TIME = 1;
    public static inline var ENRAGE_TOSS_DOWNWARDS_SPEED = 100;
    public static inline var RING_FADE_MULTIPLIER = 3;

    public var isChasing(default, null):Bool;
    public var isReturning(default, null):Bool;
    public var isEnrageTossed(default, null):Bool;
    private var isBouncing:Bool;
    private var ringMaster:RingMaster;
    private var sprite:Spritemap;
    private var tosser:CubicMotion;
    private var velocity:Vector2;
    private var chaseTarget:Entity;
    private var returnTween:LinearMotion;
    private var age:Float;
    private var enrageTossHorizontalSpeedMultiplier:Float;
    private var enrageTossRight:Bool;
    private var returnTime:Float;
    private var sfx:Map<String, Sfx>;

    public function new(ringMaster:RingMaster) {
        super();
        this.ringMaster = ringMaster;
        type = "hazard";
        sprite = new Spritemap("graphics/ring.png", 40, 40);
        sprite.add("idle", [0]);
        sprite.play("idle");
        //sprite.alpha = 0;
        graphic = sprite;
        mask = new Circle(20);
        tosser = new CubicMotion();
        addTween(tosser);
        isChasing = false;
        isBouncing = false;
        isEnrageTossed = false;
        velocity = new Vector2();
        chaseTarget = null;
        isReturning = false;
        returnTween = new LinearMotion();
        returnTween.onComplete.bind(function() {
            isReturning = false;
        });
        addTween(returnTween);
        age = 0;
        enrageTossHorizontalSpeedMultiplier = 1;
        enrageTossRight = true;
        returnTime = RETURN_TIME;
        sfx = [
            "ringbounce1" => new Sfx("audio/ringbounce1.wav"),
            "ringbounce2" => new Sfx("audio/ringbounce2.wav"),
            "ringbounce3" => new Sfx("audio/ringbounce3.wav")
        ];
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

    public function bounce() {
        isBouncing = true;
        var player = scene.getInstance("player");
        var towardsPlayer = new Vector2(
            Math.max(Math.random(), 0.4) * HXP.choose(1, -1),
            Math.max(Math.random(), 0.4) * HXP.choose(1, -1)
        );
        //if(Math.abs(velocity.x) < 0.33) {
            //velocity.x = velocity.x / Math.abs(velocity.x) * 0.33;
        //}
        //if(Math.abs(velocity.y) < 0.33) {
            //velocity.y = velocity.y / Math.abs(velocity.y) * 0.33;
        //}
        towardsPlayer.normalize(BOUNCE_SPEED);
        velocity = towardsPlayer;
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

    public function enrageToss(tossRight:Bool, tossSpeed:Float) {
        age = 0;
        isEnrageTossed = true;
        velocity = new Vector2(0, -ENRAGE_TOSS_DOWNWARDS_SPEED);
        enrageTossHorizontalSpeedMultiplier = tossSpeed;
        enrageTossRight = tossRight;
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
                    ringMaster.isEnraged ?
                    ENRAGE_MIN_TOSS_TIME : MIN_TOSS_TIME,
                    ringMaster.isEnraged ?
                    ENRAGE_MAX_TOSS_TIME : MAX_TOSS_TIME
                ),
                Ease.sineInOut
            );
            tosser.start();
        }
    }

    public function returnToRingMaster(newReturnTime:Float = RETURN_TIME) {
        isChasing = false;
        isBouncing = false;
        isEnrageTossed = false;
        isReturning = true;
        returnTime = newReturnTime;
    }

    override public function update() {
        //sprite.alpha = Math.min(
            //sprite.alpha + HXP.elapsed * RING_FADE_MULTIPLIER, 1
        //);
        visible = true;
        if(isEnrageTossed) {
            velocity.y = Math.min(
                velocity.y + ENRAGE_TOSS_DOWNWARDS_SPEED * HXP.elapsed,
                ENRAGE_TOSS_DOWNWARDS_SPEED
            );
            velocity.x = (
                Math.sin(age * enrageTossHorizontalSpeedMultiplier)
                * 120 * (enrageTossRight ? 1 : -1)
            );
            moveBy(0, velocity.y * HXP.elapsed);
            moveTo(
                ringMaster.x + ringMaster.width / 2 - width / 2 + velocity.x + 12,
                y
            );
            if(
                top >
                ringMaster.screenCenter.y + ringMaster.height / 2
                + GameScene.PLAYFIELD_SIZE / 2
            ) {
                y -= (GameScene.PLAYFIELD_SIZE + height);
                velocity = new Vector2(0, 0);
                returnToRingMaster(ENRAGE_RETURN_TIME);
            }
        }
        else if(isBouncing) {
            var collideTypes = ["walls"];
            var collideTypes = (
                collideWith(ringMaster, x, y) != null ?
                ["walls"] : ["walls", "enemy"]
            );
            moveBy(
                velocity.x * HXP.elapsed, velocity.y * HXP.elapsed,
                collideTypes
            );
        }
        else if(isReturning) {
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
                        returnTime,
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
            //sprite.alpha = Math.max(
                //sprite.alpha - HXP.elapsed * RING_FADE_MULTIPLIER, 0
            //);
            visible = false;
            moveTo(
                ringMaster.centerX - width / 2,
                ringMaster.centerY - height / 2
            );
        }
        age += HXP.elapsed;
        super.update();
    }

    override public function moveCollideX(e:Entity) {
        velocity.x = -velocity.x;
        sfx['ringbounce${HXP.choose(1, 2, 3)}'].play();
        return true;
    }

    override public function moveCollideY(e:Entity) {
        velocity.y = -velocity.y;
        sfx['ringbounce${HXP.choose(1, 2, 3)}'].play();
        return true;
    }
}

