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

class RingMaster extends Enemy
{
    public static inline var SIZE = 80;
    public static inline var STARTING_HEALTH = 100;
    public static inline var ENRAGE_THRESHOLD = 40;
    public static inline var PRE_PHASE_ADVANCE_TIME = 2;
    public static inline var PRE_ENRAGE_TIME = 2;
    public static inline var PHASE_DURATION = 12.5;
    public static inline var ENRAGE_PHASE_DURATION = 10;
    public static inline var ENRAGED_PHASE_TRANSITION_TIME = 1.33;
    public static inline var PHASE_TRANSITION_TIME = 2;
    public static inline var PAUSE_BETWEEN_TOSSES = 1;
    public static inline var PAUSE_BETWEEN_CHASES = 3;
    public static inline var TARGETED_SHOT_INTERVAL = 1;
    public static inline var TARGETED_SHOT_SPEED = 300;

    public var rings(default, null):Array<Ring>;

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
    private var targetedShotTimer:Alarm;

    private var screenCenter:Vector2;
    private var isEnraged:Bool;
    private var enrageNextPhase:Bool;

    private var sfx:Map<String, Sfx>;

    private var chaseTimer:Alarm;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        rings = [
            new Ring(this), new Ring(this)
        ];
        name = "ringmaster";
        isBoss = true;
        mask = new Hitbox(SIZE, SIZE);
        x -= width / 2;
        y -= height / 2;
        screenCenter = new Vector2(x, y);
        y -= 50;
        sprite = new Spritemap("graphics/ringmaster.png", SIZE, SIZE);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        health = STARTING_HEALTH;

        isEnraged = false;
        enrageNextPhase = false;
        generatePhaseLocations();
        phaseRelocater = new LinearMotion();
        addTween(phaseRelocater);
        preEnrage = new Alarm(PRE_ENRAGE_TIME);
        preEnrage.onComplete.bind(function() {
            // Start timers for enrage attacks
            phaseTimer.reset(ENRAGE_PHASE_DURATION);
        });
        addTween(preEnrage);

        currentPhase = "chaserings";
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
            if(tossCount > 2) {
                preAdvancePhase();
                tossCount = 0;
            }
            else {
                tossRing();
            }
        });
        addTween(tossTimer);
        tossCount = 0;
        targetedShotTimer = new Alarm(
            TARGETED_SHOT_INTERVAL, TweenType.Looping
        );
        targetedShotTimer.onComplete.bind(function() {
            targetedShot();
        });
        addTween(targetedShotTimer);

        chaseTimer = new Alarm(
            Ring.MAX_TOSS_TIME + PAUSE_BETWEEN_TOSSES, TweenType.Looping
        );
        chaseTimer.onComplete.bind(function() {
            var lastChasingRing:Ring = null;
            for(ring in rings) {
                if(ring.isChasing) {
                    lastChasingRing = ring;
                }
                else {
                    ring.chase(lastChasingRing);
                    return;
                }
            }
            // If we're out of rings, start shooting and moving
            targetedShotTimer.start();
        });
        addTween(chaseTimer);

        sfx = [
            "enrage" => new Sfx("audio/enrage.wav")
        ];
    }

    private function tossRing() {
        if(tossCount == 0) {
            rings[0].toss(false);
        }
        else if(tossCount == 1) {
            rings[1].toss(true);
        }
        else {
            rings[0].toss(false);
            rings[1].toss(true);
        }
        tossCount++;
    }

    private function generatePhaseLocations() {
        phaseLocations = [
            "tossrings" => new Vector2(screenCenter.x, screenCenter.y - 95),
            "chaserings" => new Vector2(
                screenCenter.x - 95, screenCenter.y - 95
            )
        ];
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
            allPhases.remove("enrage");
            currentPhase = allPhases[
                Std.int(Math.floor(Math.random() * allPhases.length))
            ];
            // TEMP
            //currentPhase = "tossrings";
        }
    }

    override private function act() {
        if(health <= ENRAGE_THRESHOLD) {
            if(!isEnraged) {
                enrageNextPhase = true;
            }
        }
        if(betweenPhases) {
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
                tossTimer.start();
                tossRing();
            }
        }
        else if(currentPhase == "chaserings") {
            if(!chaseTimer.active) {
                chaseTimer.start();
                var player = scene.getInstance("player");
                rings[0].chase(player);
            }
        }
    }

    private function atPhaseLocation() {
        return (
            x == phaseLocations[currentPhase].x
            && y == phaseLocations[currentPhase].y
        );
    }

    private function targetedShot(isBig:Bool = false) {
        var shotAngle = getAngleTowardsPlayer();
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        scene.add(new Spit(this, shotVector, TARGETED_SHOT_SPEED, isBig));
        for(i in 0...10) {
            var scatter = shotVector.clone();
            scatter.x += Math.random() / 3;
            scatter.y += Math.random() / 3;
            var speed = TARGETED_SHOT_SPEED * HXP.choose(
                1, 0.95, 0.9, 0.85, 0.8
            );
            scene.add(new Spit(this, scatter, speed, isBig));
        }
    }

    override function die() {
        var hazards = new Array<Entity>();
        scene.getType("hazard", hazards);
        for(hazard in hazards) {
            if(Type.getClass(hazard) == Spit) {
                cast(hazard, Spit).destroy();
            }
            else {
                scene.remove(hazard);
            }
        }
        super.die();
    }
}

