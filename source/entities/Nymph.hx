package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.tweens.motion.*;
import haxepunk.utils.*;
import entities.*;
import entities.Level;
import scenes.*;

class Nymph extends Enemy
{
    public static inline var SIZE = 80;

    public static inline var PAUSE_BETWEEN_CHASES = 1;
    public static inline var ENRAGED_PAUSE_BETWEEN_CHASES = 0.25;

    public static inline var SPIRAL_SHOT_SPEED = 92.5;
    public static inline var SPIRAL_TURN_RATE = 1;
    public static inline var SPIRAL_BULLETS_PER_SHOT = 4;
    public static inline var SPIRAL_SHOT_INTERVAL = 0.05;

    public static inline var RIPPLE_SHOT_SPEED = 100;
    public static inline var RIPPLE_SHOT_SPREAD = 15;
    public static inline var RIPPLE_SHOT_INTERVAL = 2.7;
    public static inline var ENRAGED_RIPPLE_SHOT_INTERVAL = 1.8;
    public static inline var RIPPLE_BULLETS_PER_SHOT = 200;

    public static inline var LUNGE_INTERVAL = 2;
    public static inline var LUNGE_SPEED = 250;
    public static inline var LUNGE_DECEL = 350;
    public static inline var LUNGE_SHOT_SPEED = 50;

    public static inline var SEEDER_INTERVAL = 0.3;
    public static inline var SEEDER_SHOT_SPEED = 50;
    public static inline var SEEDER_SHOT_ACCEL = 10;
    public static inline var SEEDER_CHASE_SPEED = 50;

    public static inline var WALL_SHOT_SPEED = 50;
    public static inline var WALL_SHOT_ACCEL = 200;
    public static inline var WALL_SHOT_INTERVAL = 0.5;

    public static inline var SCATTER_SHOT_INTERVAL = 2;
    public static inline var ENRAGED_SCATTER_SHOT_INTERVAL = 1.5;
    public static inline var SCATTER_SHOT_SPEED = 50;
    public static inline var SCATTER_SHOT_NUM_BULLETS = 100;
    public static inline var ENRAGED_SCATTER_SHOT_NUM_BULLETS = 16;
    public static inline var CIRCLE_PERIMETER_TIME = 10;
    public static inline var ENRAGED_CIRCLE_PERIMETER_TIME = 7;

    public static inline var END_CHASE_TIME = 5;

    public static inline var PRE_ENRAGE_TIME = 2;
    public static inline var PRE_PHASE_ADVANCE_TIME = 2;
    public static inline var PHASE_TRANSITION_TIME = 2;
    public static inline var ENRAGED_PHASE_TRANSITION_TIME = 1.33;
    public static inline var PHASE_DURATION = 60;
    public static inline var ENRAGE_PHASE_DURATION = 8;
    public static inline var CURTAIN_PHASE_DURATION_MULTIPLIER = 1.5;

    public static inline var STARTING_HEALTH = 200;
    public static inline var ENRAGE_THRESHOLD = 40;

    private var spiralShotTimer:Alarm;
    private var spiralShotStartAngle:Float;

    private var rippleShotTimer:Alarm;

    private var lungeTimer:Alarm;
    private var lungeShotTimer:Alarm;

    private var seederTimer:Alarm;

    private var wallsTimer:Alarm;
    private var slantFlip:Bool;

    public var sfx:Map<String, Sfx> = [
        "enrage" => new Sfx("audio/enrage.ogg"),
        "rippleattack1" => new Sfx("audio/rippleattack1.ogg"),
        "rippleattack2" => new Sfx("audio/rippleattack2.ogg"),
        "rippleattack3" => new Sfx("audio/rippleattack3.ogg"),
        "ringtoss1" => new Sfx("audio/ringtoss1.ogg"),
        "ringtoss2" => new Sfx("audio/ringtoss2.ogg"),
        "ringtoss3" => new Sfx("audio/ringtoss3.ogg"),
        "ringreturn" => new Sfx("audio/ringreturn.ogg"),
        "scattershot1" => new Sfx("audio/scattershot1.ogg"),
        "scattershot2" => new Sfx("audio/scattershot2.ogg"),
        "scattershot3" => new Sfx("audio/scattershot3.ogg"),
        "flurry" => new Sfx("audio/flurry.ogg")
    ];

    public var isDying(default, null):Bool;
    public var rings(default, null):Array<NymphRing>;
    public var isEnraged(default, null):Bool;
    public var screenCenter(default, null):Vector2;

    private var sprite:Spritemap;

    private var preEnrage:Alarm;

    private var phaseRelocater:LinearMotion;
    private var phaseLocations:Map<String, Vector2>;
    private var currentPhase:String;
    private var betweenPhases:Bool;
    private var phaseTimer:Alarm;
    private var preAdvancePhaseTimer:Alarm;

    private var chaseTimer:Alarm;
    private var scatterShotTimer:Alarm;
    private var circlePerimeter:LinearPath;
    private var chaseCount:Int;
    private var endChaseTimer:Alarm;

    private var enrageNextPhase:Bool;
    private var stopActing:Bool;

    private var hitbox:Hitbox;

    public function new(startX:Float, startY:Float) {
        super(startX - SIZE / 2, startY - SIZE / 2);
        rings = [
            new NymphRing(this), new NymphRing(this),
            new NymphRing(this), new NymphRing(this),
            new NymphRing(this), new NymphRing(this),
            new NymphRing(this), new NymphRing(this),
            new NymphRing(this), new NymphRing(this)
        ];
        name = "nymph";
        layer = -10;
        isBoss = true;
        hitbox = new Hitbox(52, 64);
        hitbox.x = 3;
        hitbox.y = 16;
        //hitbox.x = 25;
        mask = hitbox;
        //x -= width / 2;
        //y -= height / 2;
        screenCenter = new Vector2(x, y);
        y -= 50;
        startPosition.y -= 50;
        sprite = new Spritemap("graphics/bosses.png", SIZE, SIZE + 10);
        sprite.y = -5;
        sprite.add("dying", [6]);
        sprite.add("idle", [6, 7], 4);
        sprite.add("shoot", [8, 9], 2);
        sprite.play("idle");
        graphic = sprite;
        health = (
            GameScene.isNightmare
            ? Std.int(STARTING_HEALTH * GameScene.NIGHTMARE_HEALTH_MULTIPLIER)
            : STARTING_HEALTH
        );

        spiralShotTimer = new Alarm(
            SPIRAL_SHOT_INTERVAL, TweenType.Looping
        );
        spiralShotTimer.onComplete.bind(function() {
            spiralShot();
        });
        addTween(spiralShotTimer);
        spiralShotStartAngle = 0;

        rippleShotTimer = new Alarm(
            RIPPLE_SHOT_INTERVAL, TweenType.Looping
        );
        rippleShotTimer.onComplete.bind(function() {
            rippleShot();
        });
        addTween(rippleShotTimer);

        lungeTimer = new Alarm(
            LUNGE_INTERVAL, TweenType.Looping
        );
        lungeTimer.onComplete.bind(function() {
            lunge(false);
        });
        addTween(lungeTimer);

        lungeShotTimer = new Alarm(
            LUNGE_INTERVAL, TweenType.Looping
        );
        lungeShotTimer.onComplete.bind(function() {
            lungeShot();
        });
        addTween(lungeShotTimer);

        wallsTimer = new Alarm(
            WALL_SHOT_INTERVAL, TweenType.Looping
        );
        wallsTimer.onComplete.bind(function() {
            wallShot();
        });
        addTween(wallsTimer);
        slantFlip = false;

        seederTimer = new Alarm(
            SEEDER_INTERVAL, TweenType.Looping
        );
        seederTimer.onComplete.bind(function() {
            seederShot();
        });
        addTween(seederTimer);

        chaseTimer = new Alarm(
            NymphRing.MAX_TOSS_TIME + PAUSE_BETWEEN_CHASES, TweenType.Looping
        );
        chaseTimer.onComplete.bind(function() {
            var lastChasingRing:NymphRing = null;
            var numChases = isEnraged ? 8 : 10;
            for(ring in rings) {
                if(ring.isChasing) {
                    lastChasingRing = ring;
                }
                else if(chaseCount < numChases) {
                    ring.chase(lastChasingRing);
                    sfx['ringtoss${HXP.choose(1, 2, 3)}'].play();
                    returnToIdleAfterPause();
                    chaseCount++;
                    return;
                }
                else if(!endChaseTimer.active) {
                    endChaseTimer.start();
                }
            }
        });
        addTween(chaseTimer);
        chaseCount = 0;
        endChaseTimer = new Alarm(END_CHASE_TIME);
        endChaseTimer.onComplete.bind(function() {
            for(ring in rings) {
                ring.returnToNymph(
                    isEnraged ?
                    NymphRing.ENRAGE_RETURN_TIME : NymphRing.RETURN_TIME
                );
            }
            sfx['ringreturn'].play();
            var ringReturnTimer = new Alarm(NymphRing.RETURN_TIME);
            ringReturnTimer.onComplete.bind(function() {
                preAdvancePhase();
            });
            addTween(ringReturnTimer, true);
        });
        addTween(endChaseTimer);

        scatterShotTimer = new Alarm(
            SCATTER_SHOT_INTERVAL, TweenType.Looping
        );
        scatterShotTimer.onComplete.bind(function() {
            scatterShot();
            sprite.play("tossboth");
            returnToIdleAfterPause();
        });
        addTween(scatterShotTimer);

        isEnraged = GameScene.isNightmare ? true : false;
        enrageNextPhase = false;
        isDying = false;
        stopActing = false;

        generatePhaseLocations();

        phaseRelocater = new LinearMotion();
        addTween(phaseRelocater);

        //currentPhase = HXP.choose("wheel");
        //currentPhase = HXP.choose("lunge");
        //currentPhase = HXP.choose("walls");
        //currentPhase = HXP.choose("seeder");
        currentPhase = HXP.choose("chaserings");
        betweenPhases = true;
        phaseTimer = new Alarm(PHASE_DURATION);
        phaseTimer.onComplete.bind(function() {
            preAdvancePhase();
        });
        addTween(phaseTimer);

        preAdvancePhaseTimer = new Alarm(PRE_PHASE_ADVANCE_TIME);
        preAdvancePhaseTimer.onComplete.bind(function() {
            advancePhase();
        });
        addTween(preAdvancePhaseTimer);

        preEnrage = new Alarm(PRE_ENRAGE_TIME);
        preEnrage.onComplete.bind(function() {
            age = 0;
            sprite.play("shoot");
        });
        addTween(preEnrage);

        fightStarted = GameScene.hasGlobalFlag("nymphFightStarted");
    }

    public function stopSfx() {
        sfx["flurry"].stop();
        stopActing = true;
    }

    private function generatePhaseLocations() {
        phaseLocations = [
            "wheel" => new Vector2(screenCenter.x, screenCenter.y),
            "lunge" => new Vector2(screenCenter.x, screenCenter.y),
            "walls" => new Vector2(screenCenter.x, screenCenter.y - 95),
            "enrage" => new Vector2(screenCenter.x, screenCenter.y - 95),
            "seeder" => new Vector2(screenCenter.x, screenCenter.y)
        ];
        circlePerimeter = new LinearPath();
        var perimeterPoints = [
            new Vector2(screenCenter.x - 95, screenCenter.y - 95),
            new Vector2(screenCenter.x + 95, screenCenter.y - 95),
            new Vector2(screenCenter.x + 95, screenCenter.y + 95),
            new Vector2(screenCenter.x - 95, screenCenter.y + 95)
        ];
        if(Math.random() > 0.5) {
            perimeterPoints.reverse();
        }
        var pointCount = 0;
        var startCount = HXP.choose(0, 1, 2, 3);
        var startPoint = perimeterPoints[
            (startCount + pointCount) % perimeterPoints.length
        ];
        phaseLocations["chaserings"] = new Vector2(startPoint.x, startPoint.y);
        while(pointCount < 5) {
            var point = perimeterPoints[
                (startCount + pointCount) % perimeterPoints.length
            ];
            circlePerimeter.addPoint(point.x, point.y);
            pointCount++;
        }
        circlePerimeter.onComplete.bind(function() {
            scatterShotTimer.active = false;

        });
        addTween(circlePerimeter);
    }

    private function preAdvancePhase() {
        betweenPhases = true;
        for(tween in tweens) {
            tween.active = false;
        }
        preAdvancePhaseTimer.start();
    }

    private function advancePhase() {
        generatePhaseLocations();
        if(enrageNextPhase) {
            isEnraged = true;
            enrageNextPhase = false;
            currentPhase = "enrage";
        }
        else {
            var allPhases = new Array<String>();
            for(phaseName in phaseLocations.keys()) {
                allPhases.push(phaseName);
            }
            allPhases.remove(currentPhase);
            if(!GameScene.isNightmare) {
                allPhases.remove("enrage");
            }
            currentPhase = allPhases[
                Std.int(Math.floor(Math.random() * allPhases.length))
            ];
        }
    }

    override private function act() {
        if(health <= ENRAGE_THRESHOLD) {
            if(!isEnraged) {
                enrageNextPhase = true;
            }
        }
        collidable = (fightStarted && !isDead);
        var gameScene = cast(scene, GameScene);
        if(isDying) {
            // Do nothing
            sprite.play("dying");
            if(!gameScene.pausePlayer) {
                isDead = true;
                bigExplosionSpawner.cancel();
                visible = false;
                collidable = false;
            }
            clearHazards();
            for(ring in rings) {
                scene.remove(ring);
            }
        }
        else if(!fightStarted || gameScene.isDialogMode) {
            // Do nothing
            sprite.play("dying");
            var player = scene.getInstance("player");
            if(player.y - bottom < 50 && !gameScene.isDialogMode) {
                gameScene.converse("nymph");
                GameScene.addGlobalFlag("nymphFightStarted");
            }
        }
        else if(betweenPhases) {
            sfx['flurry'].stop();
            var player = scene.getInstance("player");
            sprite.play("idle");
            sprite.flipX = centerX > player.centerX;
            hitbox.x = sprite.flipX ? 25 : 3;
            if(preAdvancePhaseTimer.active) {
                // Do nothing
            }
            else if(atPhaseLocation()) {
                betweenPhases = false;
            }
            else {
                if(!phaseRelocater.active) {
                    phaseRelocater.setMotion(
                        x, y,
                        phaseLocations[currentPhase].x,
                        phaseLocations[currentPhase].y,
                        (
                            isEnraged ?
                            ENRAGED_PHASE_TRANSITION_TIME
                            : PHASE_TRANSITION_TIME
                        ),
                        Ease.sineInOut
                    );
                    phaseRelocater.start();
                }
                moveTo(phaseRelocater.x, phaseRelocater.y);
            }
        }
        else if(currentPhase == "wheel") {
            if(!spiralShotTimer.active) {
                spiralShotTimer.start();
                spiralShotStartAngle = getAngleTowardsPlayer();
                age = Math.PI * 1.5;

                rippleShotTimer.reset(
                    isEnraged ?
                    ENRAGED_RIPPLE_SHOT_INTERVAL
                    : RIPPLE_SHOT_INTERVAL
                );
                rippleShot();
                phaseTimer.start();
            }
        }
        else if(currentPhase == "lunge") {
            if(!lungeShotTimer.active) {
                lungeShotTimer.start();
                var shotDelay = new Alarm(LUNGE_INTERVAL / 2);
                shotDelay.onComplete.bind(function() {
                    lungeTimer.start();
                    lunge();
                });
                addTween(shotDelay, true);
                phaseTimer.start();
                lungeShot();
            }
            velocity.x = MathUtil.approach(
                velocity.x, 0, LUNGE_DECEL * HXP.elapsed
            );
            velocity.y = MathUtil.approach(
                velocity.y, 0, LUNGE_DECEL * HXP.elapsed
            );
            moveBy(
                velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, "walls"
            );
        }
        else if(currentPhase == "walls") {
            if(!wallsTimer.active) {
                wallsTimer.start();
                wallShot();
                phaseTimer.start();
            }
        }
        else if(currentPhase == "seeder") {
            if(!seederTimer.active) {
                seederTimer.start();
            }
            var angle = getAngleTowardsPlayer();
            velocity = new Vector2(
                Math.cos(angle), Math.sin(angle)
            );
            velocity.normalize(SEEDER_CHASE_SPEED);
            moveBy(
                velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, "walls"
            );
        }
        else if(currentPhase == "chaserings") {
            var player = scene.getInstance("player");
            sprite.flipX = centerX < player.centerX;
            if(!chaseTimer.active) {
                if(isEnraged) {
                    chaseTimer.reset(
                        NymphRing.MAX_TOSS_TIME + ENRAGED_PAUSE_BETWEEN_CHASES
                    );
                }
                else {
                    chaseTimer.start();
                }
                var player = scene.getInstance("player");
                rings[0].chase(player);
                sprite.play("tossone");
                sfx['ringtoss${HXP.choose(1, 2, 3)}'].play();
                returnToIdleAfterPause();
                chaseCount = 1;
            }
            //if(circlePerimeter.active && circlePerimeter.x != 0) {
                //moveTo(circlePerimeter.x, circlePerimeter.y);
            //}
        }
        else if(currentPhase == "enrage") {
            //if(
                //enrageShotTimer.active
                //&& age >= ENRAGE_SINGLE_ROTATION_DURATION * 2
            //) {
                //preAdvancePhase();
            //}
            //else if(
                //!preEnrage.active
                //&& !enrageShotTimer.active
                //&& !preAdvancePhaseTimer.active
            //) {
                //preEnrage.start();
                //sfx["enrage"].play();
            //}
        }
    }

    private function spiralShot() {
        if(!sfx["flurry"].playing && !stopActing) {
            sfx["flurry"].loop();
        }
        var numBullets = (
            isEnraged ? SPIRAL_BULLETS_PER_SHOT + 1 : SPIRAL_BULLETS_PER_SHOT
        );
        for(i in 0...numBullets) {
            var spreadAngles = getSpreadAngles(
                numBullets + 1, Math.PI * 2
            );
            var shotAngle = (
                spiralShotStartAngle
                + Math.cos(age / 3) * SPIRAL_TURN_RATE + spreadAngles[i]
            );
            var shotVector = new Vector2(
                Math.cos(shotAngle), Math.sin(shotAngle)
            );
            scene.add(new Spit(this, shotVector, SPIRAL_SHOT_SPEED));
        }
    }

    private function rippleShot() {
        sfx['rippleattack${HXP.choose(1, 2, 3)}'].play();
        var spreadAngles = getSpreadAngles(
            RIPPLE_BULLETS_PER_SHOT, Math.PI * 2
        );
        for(i in 0...RIPPLE_BULLETS_PER_SHOT) {
            var shotAngle = spreadAngles[i] + Math.PI / 2;
            var shotVector = new Vector2(
                Math.cos(shotAngle), Math.sin(shotAngle)
            );
            scene.add(new Spit(this, shotVector, RIPPLE_SHOT_SPEED));
        }
    }

    private function lunge(backwards:Bool = false) {
        //sfx['rippleattack${HXP.choose(1, 2, 3)}'].play();
        var lungeAngle = getAngleTowardsPlayer();
        velocity = new Vector2(
            Math.cos(lungeAngle), Math.sin(lungeAngle)
        );
        velocity.normalize(LUNGE_SPEED);
        if(backwards) {
            velocity.inverse();
        }
    }

    private function lungeShot() {
        //var lungeAngle = Math.PI / 4;
        //var lungeAngle = Math.random() * Math.PI * 2;
        //rippleShot();
        //var lungeAngle = Math.random() * Math.PI * 2;
        var lungeAngle = getAngleTowardsPlayer() + Math.PI / 4;
        for (i in 0...50) {
            var shotAngle = lungeAngle + Math.PI / 2;
            var shotVector = new Vector2(
                Math.cos(shotAngle), Math.sin(shotAngle)
            );
            scene.add(new Spit(this, shotVector, LUNGE_SHOT_SPEED + i * 3));

            shotAngle = lungeAngle - Math.PI / 2;
            shotVector = new Vector2(
                Math.cos(shotAngle), Math.sin(shotAngle)
            );
            scene.add(new Spit(this, shotVector, LUNGE_SHOT_SPEED + i * 3));

            shotAngle = lungeAngle;
            shotVector = new Vector2(
                Math.cos(shotAngle), Math.sin(shotAngle)
            );
            scene.add(new Spit(this, shotVector, LUNGE_SHOT_SPEED + i * 3));

            shotAngle = lungeAngle - Math.PI;
            shotVector = new Vector2(
                Math.cos(shotAngle), Math.sin(shotAngle)
            );
            scene.add(new Spit(this, shotVector, LUNGE_SHOT_SPEED + i * 3));
        }
    }

    private function atPhaseLocation() {
        return (
            x == phaseLocations[currentPhase].x
            && y == phaseLocations[currentPhase].y
        );
    }

    override function die() {
        trace('dying');
        GameScene.addGlobalFlag("nymphDefeated");
        GameScene.saveGame();
        for(tween in tweens) {
            tween.active = false;
        }
        stopSfx();
        bigExplosionSpawner.start();
        clearHazards();
        isDying = true;
        collidable = false;
        var gameScene = cast(scene, GameScene);
        gameScene.setPausePlayer(true);
        var deathConversationDelay = new Alarm(1, function() {
            var gameScene = cast(scene, GameScene);
            gameScene.converse("nymphdeath");
        });
        addTween(deathConversationDelay, true);
    }

    private function wallShot() {
        //var shotVector = Math.random() * Math.PI * 2;
        //for(i in -50...50) {
            //var spit = new Spit(
                //this, shotVector, WALL_SHOT_SPEED, false,
                //new Vector2(0, accel + (i * 2 * accelSlant))
            //);
        //}
        //var slant = HXP.choose(2, 1, 1.5) * (slantFlip ? -1 : 1);
        //slantFlip = Math.random() > 0.5;
        ////var slant = 0;
        //var speed = WALL_SHOT_SPEED;
        //var accel = WALL_SHOT_ACCEL * HXP.choose(2, 1.5, 1);
        //var accelSlant = HXP.choose(1, -1);
        //for(i in -50...50) {
            //var shotVector = new Vector2(0, 1);
            //var spit = new Spit(
                //this, shotVector, speed, false,
                //new Vector2(0, accel + (i * 2 * accelSlant))
            //);
            //spit.x += i * 3;
            //spit.y -= i * slant;
            //scene.add(spit);
        //}
        sfx['rippleattack${HXP.choose(1, 2, 3)}'].play();
    }

    private function seederShot() {
        var shotAngle = Math.random() * Math.PI * 2;
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        var shotVectorInverse = shotVector.clone();
        shotVectorInverse.inverse();
        shotVectorInverse.normalize(SEEDER_SHOT_ACCEL);
        var spit = new Spit(
            this, shotVector, SEEDER_SHOT_SPEED, false,
            shotVectorInverse
        );
        scene.add(spit);
    }

    private function scatterShot(isBig:Bool = false) {
        var shotAngle = getAngleTowardsPlayer();
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        var numBullets = (
            isEnraged ?
            ENRAGED_SCATTER_SHOT_NUM_BULLETS : SCATTER_SHOT_NUM_BULLETS
        );
        for(i in 0...numBullets) {
            scene.add(new Spit(
                this, shotVector, SCATTER_SHOT_SPEED + i * 4
            ));
        }
        sfx['scattershot${HXP.choose(1, 2, 3)}'].play();
    }

    private function returnToIdleAfterPause() {
        var returnToIdlePause = new Alarm(0.75);
        returnToIdlePause.onComplete.bind(function() {
            sprite.play("idle");
        });
        addTween(returnToIdlePause, true);
    }

    override public function moveCollideX(e:Entity) {
        //velocity.x = -velocity.x / 4;
        return true;
    }

    override public function moveCollideY(e:Entity) {
        //velocity.y = -velocity.y / 4;
        return true;
    }
}

