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
import entities.Level;
import scenes.*;

class RingMaster extends Enemy
{
    public static inline var SIZE = 80;
    public static inline var STARTING_HEALTH = 200;
    public static inline var ENRAGE_THRESHOLD = 80;
    public static inline var PRE_PHASE_ADVANCE_TIME = 1.5;
    public static inline var PRE_ENRAGE_TIME = 1;
    public static inline var PHASE_DURATION = 12.5;
    public static inline var ENRAGE_PHASE_DURATION = 17;
    public static inline var PHASE_TRANSITION_TIME = 1.5;
    public static inline var ENRAGED_PHASE_TRANSITION_TIME = 1;
    public static inline var PAUSE_BETWEEN_TOSSES = 1;
    public static inline var ENRAGED_PAUSE_BETWEEN_TOSSES = 0.75;
    public static inline var PAUSE_BETWEEN_CHASES = 1;
    public static inline var ENRAGED_PAUSE_BETWEEN_CHASES = 0.25;
    public static inline var SCATTER_SHOT_INTERVAL = 2;
    public static inline var ENRAGED_SCATTER_SHOT_INTERVAL = 1.5;
    public static inline var SCATTER_SHOT_SPEED = 250;
    public static inline var SCATTER_SHOT_NUM_BULLETS = 8;
    public static inline var ENRAGED_SCATTER_SHOT_NUM_BULLETS = 16;
    public static inline var CIRCLE_PERIMETER_TIME = 10;
    public static inline var ENRAGED_CIRCLE_PERIMETER_TIME = 7;
    public static inline var BOUNCE_PHASE_DURATION = 10;

    public var rings(default, null):Array<Ring>;
    public var screenCenter(default, null):Vector2;
    public var isEnraged(default, null):Bool;

    private var sprite:Spritemap;
    private var preEnrage:Alarm;
    private var phaseRelocater:LinearMotion;
    private var phaseLocations:Map<String, Vector2>;
    private var currentPhase:String;
    private var betweenPhases:Bool;
    private var phaseTimer:Alarm;
    private var preAdvancePhaseTimer:Alarm;

    private var tossTimer:Alarm;
    private var tossCount:Int;

    private var enrageNextPhase:Bool;
    private var isDying:Bool;

    private var sfx:Map<String, Sfx>;

    private var chaseTimer:Alarm;
    private var scatterShotTimer:Alarm;
    private var circlePerimeter:LinearPath;
    private var chaseCount:Int;

    private var bounceTimer:Alarm;

    private var enrageTossTimer:Alarm;
    private var endEnragePhaseTimer:Alarm;
    private var isEndingEnragePhase:Bool;

    public function new(startX:Float, startY:Float) {
        super(startX - SIZE / 2, startY - SIZE / 2);
        rings = [
            new Ring(this), new Ring(this),
            new Ring(this), new Ring(this),
            new Ring(this), new Ring(this)
        ];
        name = "ringmaster";
        isBoss = true;
        var hitbox = new Hitbox(49, 80);
        hitbox.x = 18;
        mask = hitbox;
        //x -= width / 2;
        //y -= height / 2;
        screenCenter = new Vector2(x, y);
        y -= 50;
        startPosition.y -= 50;
        sprite = new Spritemap("graphics/bosses.png", SIZE, SIZE);
        sprite.add("idle", [3]);
        sprite.add("tossone", [4]);
        sprite.add("tossboth", [5]);
        sprite.play("idle");
        graphic = sprite;
        health = (
            GameScene.isNightmare
            ? Std.int(STARTING_HEALTH * GameScene.NIGHTMARE_HEALTH_MULTIPLIER)
            : STARTING_HEALTH
        );

        isEnraged = GameScene.isNightmare ? true : false;
        enrageNextPhase = false;
        isDying = false;

        generatePhaseLocations();
        phaseRelocater = new LinearMotion();
        addTween(phaseRelocater);
        preEnrage = new Alarm(PRE_ENRAGE_TIME);
        preEnrage.onComplete.bind(function() {
            // Start timers for enrage attacks
            enrageTossTimer.start();
            endEnragePhaseTimer.start();
        });
        addTween(preEnrage);

        currentPhase = HXP.choose("tossrings", "chaserings", "bouncerings");
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

        tossTimer = new Alarm(
            Ring.MAX_TOSS_TIME + PAUSE_BETWEEN_TOSSES, TweenType.Looping
        );
        tossTimer.onComplete.bind(function() {
            var numTosses = isEnraged ? 4 : 2;
            if(tossCount > numTosses) {
                preAdvancePhase();
                tossCount = 0;
            }
            else {
                tossRing();
            }
        });
        addTween(tossTimer);
        tossCount = 0;
        scatterShotTimer = new Alarm(
            SCATTER_SHOT_INTERVAL, TweenType.Looping
        );
        scatterShotTimer.onComplete.bind(function() {
            scatterShot();
            sprite.play("tossboth");
            returnToIdleAfterPause();
        });
        addTween(scatterShotTimer);

        chaseTimer = new Alarm(
            Ring.MAX_TOSS_TIME + PAUSE_BETWEEN_CHASES, TweenType.Looping
        );
        chaseTimer.onComplete.bind(function() {
            var lastChasingRing:Ring = null;
            var numChases = isEnraged ? 4 : 2;
            for(ring in rings) {
                if(ring.isChasing) {
                    lastChasingRing = ring;
                }
                else if(chaseCount < numChases) {
                    ring.chase(lastChasingRing);
                    sprite.play("tossone");
                    sfx['ringtoss${HXP.choose(1, 2, 3)}'].play();
                    returnToIdleAfterPause();
                    chaseCount++;
                    return;
                }
            }
            // If we're out of rings, start shooting and moving
            if(!scatterShotTimer.active) {
                scatterShot();
                sprite.play("tossboth");
                returnToIdleAfterPause();
                if(isEnraged) {
                    scatterShotTimer.reset(ENRAGED_SCATTER_SHOT_INTERVAL);
                }
                else {
                    scatterShotTimer.start();
                }
                circlePerimeter.setMotion(
                    isEnraged ?
                    ENRAGED_CIRCLE_PERIMETER_TIME : CIRCLE_PERIMETER_TIME,
                    Ease.sineInOut
                );
                circlePerimeter.start();
            }
        });
        addTween(chaseTimer);
        chaseCount = 0;

        bounceTimer = new Alarm(BOUNCE_PHASE_DURATION);
        bounceTimer.onComplete.bind(function() {
            for(ring in rings) {
                ring.returnToRingMaster();
            }
            sfx['ringreturn'].play();
            var ringReturnTimer = new Alarm(Ring.RETURN_TIME);
            ringReturnTimer.onComplete.bind(function() {
                preAdvancePhase();
            });
            addTween(ringReturnTimer, true);
        });
        addTween(bounceTimer);

        enrageTossTimer = new Alarm(1, TweenType.Looping);
        enrageTossTimer.onComplete.bind(function() {
            var tossSpeed = HXP.choose(2, 3, 4, 5);
            if(!rings[0].isEnrageTossed && !rings[0].isReturning) {
                rings[0].enrageToss(true, tossSpeed);
                rings[1].enrageToss(false, tossSpeed);
            }
            else if(!rings[2].isEnrageTossed && !rings[2].isReturning) {
                rings[2].enrageToss(true, tossSpeed);
                rings[3].enrageToss(false, tossSpeed);
            }
            else if(!rings[4].isEnrageTossed && !rings[4].isReturning) {
                rings[4].enrageToss(true, tossSpeed);
                rings[5].enrageToss(false, tossSpeed);
            }
            sprite.play("tossboth");
            sfx['ringtoss1'].play();
            sfx['ringtoss${HXP.choose(2, 3)}'].play();
            sprite.flipX = !sprite.flipX;
            returnToIdleAfterPause();
        });
        addTween(enrageTossTimer);

        endEnragePhaseTimer = new Alarm(ENRAGE_PHASE_DURATION);
        endEnragePhaseTimer.onComplete.bind(function() {
            enrageTossTimer.active = false;
            for(ring in rings) {
                ring.returnToRingMaster();
            }
            sfx['ringreturn'].play();
            isEndingEnragePhase = true;
            var ringReturnTimer = new Alarm(4);
            ringReturnTimer.onComplete.bind(function() {
                preAdvancePhase();
            });
            addTween(ringReturnTimer, true);
        });
        addTween(endEnragePhaseTimer);
        isEndingEnragePhase = false;

        sfx = [
            "ringtoss1" => new Sfx("audio/ringtoss1.wav"),
            "ringtoss2" => new Sfx("audio/ringtoss2.wav"),
            "ringtoss3" => new Sfx("audio/ringtoss3.wav"),
            "ringreturn" => new Sfx("audio/ringreturn.wav"),
            "scattershot1" => new Sfx("audio/scattershot1.wav"),
            "scattershot2" => new Sfx("audio/scattershot2.wav"),
            "scattershot3" => new Sfx("audio/scattershot3.wav"),
            "enrage" => new Sfx("audio/enrage.wav")
        ];
        fightStarted = GameScene.hasGlobalFlag("ringMasterFightStarted");
    }

    private function returnToIdleAfterPause() {
        var returnToIdlePause = new Alarm(0.75);
        returnToIdlePause.onComplete.bind(function() {
            sprite.play("idle");
        });
        addTween(returnToIdlePause, true);
    }

    private function tossRing() {
        if(isEnraged) {
            if(tossCount == 4) {
                rings[0].toss(false);
                rings[1].toss(true);
                sprite.play("tossboth");
                sfx['ringtoss1'].play();
                sfx['ringtoss2'].play();
                sprite.flipX = !sprite.flipX;
            }
            else {
                var tossRight = tossCount % 2 == 0 ? true : false;
                rings[tossCount % 4].toss(tossRight);
                sprite.play("tossone");
                sfx['ringtoss${HXP.choose(1, 2, 3)}'].play();
                sprite.flipX = tossRight;
            }
        }
        else {
            if(tossCount == 0) {
                rings[0].toss(false);
                sprite.flipX = false;
                sprite.play("tossone");
                sfx['ringtoss${HXP.choose(1, 2, 3)}'].play();
            }
            else if(tossCount == 1) {
                rings[1].toss(true);
                sprite.flipX = true;
                sprite.play("tossone");
                sfx['ringtoss${HXP.choose(1, 2, 3)}'].play();
            }
            else {
                rings[0].toss(false);
                rings[1].toss(true);
                sprite.play("tossboth");
                sfx['ringtoss1'].play();
                sfx['ringtoss2'].play();
                sprite.flipX = !sprite.flipX;
            }
        }
        returnToIdleAfterPause();
        tossCount++;
    }

    private function generatePhaseLocations() {
        phaseLocations = [
            "tossrings" => new Vector2(screenCenter.x, screenCenter.y - 95),
            // chaserings is set below
            "bouncerings" => new Vector2(screenCenter.x, screenCenter.y),
            "enrage" => new Vector2(screenCenter.x, screenCenter.y - 95)
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
            for(ring in rings) {
                ring.returnToRingMaster(
                    isEnraged ? Ring.ENRAGE_RETURN_TIME : Ring.RETURN_TIME
                );
            }
            sfx['ringreturn'].play();
            var ringReturnTimer = new Alarm(Ring.RETURN_TIME);
            ringReturnTimer.onComplete.bind(function() {
                preAdvancePhase();
            });
            addTween(ringReturnTimer, true);
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
            // TODO: TEMP
            //if(currentPhase == "tossrings") {
                //currentPhase = "chaserings";
            //}
            //else if(currentPhase == "chaserings") {
                //currentPhase = "bouncerings";
            //}
            //else {
                //currentPhase = "tossrings";
            //}
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
            if(!gameScene.pausePlayer) {
                isDead = true;
                //scene.remove(this);
                bigExplosionSpawner.cancel();
                visible = false;
                collidable = false;
            }
            clearHazards();
        }
        else if(!fightStarted || gameScene.isDialogMode) {
            // Do nothing
            var player = scene.getInstance("player");
            if(player.y - bottom < 50 && !gameScene.isDialogMode) {
                gameScene.converse("ringmaster");
                GameScene.addGlobalFlag("ringMasterFightStarted");
            }
        }
        else if(betweenPhases) {
            sprite.play("idle");
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
        else if(currentPhase == "tossrings") {
            if(!tossTimer.active) {
                if(isEnraged) {
                    tossTimer.reset(ENRAGED_PAUSE_BETWEEN_TOSSES);
                }
                else {
                    tossTimer.reset(Ring.MAX_TOSS_TIME + PAUSE_BETWEEN_TOSSES);
                }
                tossRing();
            }
        }
        else if(currentPhase == "chaserings") {
            var player = scene.getInstance("player");
            sprite.flipX = centerX < player.centerX;
            if(!chaseTimer.active) {
                if(isEnraged) {
                    chaseTimer.reset(
                        Ring.MAX_TOSS_TIME + ENRAGED_PAUSE_BETWEEN_CHASES
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
            if(circlePerimeter.active && circlePerimeter.x != 0) {
                moveTo(circlePerimeter.x, circlePerimeter.y);
            }
        }
        else if(currentPhase == "bouncerings") {
            sprite.play("tossboth");
            if(!bounceTimer.active && !rings[0].isReturning) {
                sfx['ringtoss1'].play();
                sfx['ringtoss2'].play();
                sfx['ringtoss3'].play();
                bounceTimer.start();
                var bounceCount = 0;
                var numBounces = isEnraged ? 5 : 3;
                for(ring in rings) {
                    if(bounceCount >= numBounces) {
                        continue;
                    }
                    ring.bounce();
                    bounceCount++;
                }
            }
        }
        else if(currentPhase == "enrage") {
            if(isEndingEnragePhase) {
                // Do nothing
            }
            else if(
                !preEnrage.active
                && !enrageTossTimer.active
            ) {
                preEnrage.start();
                sfx["enrage"].play();
            }
        }
    }

    private function atPhaseLocation() {
        return (
            x == phaseLocations[currentPhase].x
            && y == phaseLocations[currentPhase].y
        );
    }

    private function scatterShot(isBig:Bool = false) {
        var shotAngle = getAngleTowardsPlayer();
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        scene.add(new Spit(this, shotVector, SCATTER_SHOT_SPEED, isBig));
        var numBullets = (
            isEnraged ?
            ENRAGED_SCATTER_SHOT_NUM_BULLETS : SCATTER_SHOT_NUM_BULLETS
        );
        for(i in 0...numBullets) {
            var scatter = shotVector.clone();
            scatter.x += Math.random() / 4;
            scatter.y += Math.random() / 4;
            var speed = SCATTER_SHOT_SPEED * HXP.choose(1, 0.95, 0.9, 0.85);
            scene.add(new Spit(this, scatter, speed, isBig));
        }
        sfx['scattershot${HXP.choose(1, 2, 3)}'].play();
    }

    override function die() {
        GameScene.addGlobalFlag("ringmasterDefeated");
        GameScene.saveGame();
        for(tween in tweens) {
            tween.active = false;
        }
        bigExplosionSpawner.start();
        clearHazards();
        isDying = true;
        collidable = false;
        var gameScene = cast(scene, GameScene);
        gameScene.setPausePlayer(true);
        var deathConversationDelay = new Alarm(1, function() {
            var gameScene = cast(scene, GameScene);
            gameScene.converse("ringmasterdeath");
        });
        addTween(deathConversationDelay, true);
    }
}

