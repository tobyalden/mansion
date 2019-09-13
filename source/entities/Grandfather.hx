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

class Grandfather extends Enemy
{
    public static inline var WIDTH = 160;
    public static inline var HEIGHT = 100;

    public static inline var PRE_ENRAGE_TIME = 2;
    public static inline var PRE_PHASE_ADVANCE_TIME = 2;
    public static inline var PHASE_TRANSITION_TIME = 2;
    public static inline var ENRAGED_PHASE_TRANSITION_TIME = 1.33;
    public static inline var PHASE_DURATION = 12.5;
    public static inline var ENRAGE_PHASE_DURATION = 10;
    public static inline var CURTAIN_PHASE_DURATION_MULTIPLIER = 1.5;

    public static inline var STARTING_HEALTH = 100;
    public static inline var ENRAGE_THRESHOLD = 40;

    public static inline var CURTAIN_SHOT_SPEED = 80;
    public static inline var CURTAIN_SHOT_INTERVAL = 0.5;
    public static inline var ENRAGE_CURTAIN_SHOT_INTERVAL = 0.5;
    public static inline var CURTAIN_AIMED_SHOT_INTERVAL = 1;
    public static inline var CURTAIN_AIMED_SHOT_SPEED = 200;

    private var sprite:Spritemap;

    private var preEnrage:Alarm;

    private var phaseRelocater:LinearMotion;
    private var phaseLocations:Map<String, Vector2>;
    private var currentPhase:String;
    private var betweenPhases:Bool;
    private var phaseTimer:Alarm;
    private var preAdvancePhaseTimer:Alarm;

    private var screenCenter:Vector2;
    private var isEnraged:Bool;
    private var enrageNextPhase:Bool;

    private var curtainShotTimer:Alarm;
    private var curtainAimedShotTimer:Alarm;

    private var sfx:Map<String, Sfx>;

    public function new(startX:Float, startY:Float) {
        super(startX - WIDTH / 2, startY - HEIGHT / 2);
        name = "grandfather";
        isBoss = true;
        mask = new Hitbox(WIDTH, HEIGHT);
        //x -= width / 2;
        //y -= height / 2;
        screenCenter = new Vector2(x, y);
        y -= 50;
        startPosition.y -= 50;
        sprite = new Spritemap("graphics/grandfather.png", WIDTH, HEIGHT);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        health = STARTING_HEALTH;

        isEnraged = false;
        enrageNextPhase = false;

        generatePhaseLocations();

        phaseRelocater = new LinearMotion();
        addTween(phaseRelocater);

        currentPhase = HXP.choose("curtain");
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

        curtainShotTimer = new Alarm(CURTAIN_SHOT_INTERVAL, TweenType.Looping);
        curtainShotTimer.onComplete.bind(function() {
            curtainShot();
        });
        addTween(curtainShotTimer);

        curtainAimedShotTimer = new Alarm(
            CURTAIN_AIMED_SHOT_INTERVAL , TweenType.Looping
        );
        curtainAimedShotTimer.onComplete.bind(function() {
            curtainAimedShot();
        });
        addTween(curtainAimedShotTimer);

        preEnrage = new Alarm(PRE_ENRAGE_TIME);
        preEnrage.onComplete.bind(function() {
            // Start enrage phase timers
        });
        addTween(preEnrage);

        sfx = [
            "enrage" => new Sfx("audio/enrage.wav")
        ];
    }

    private function generatePhaseLocations() {
        phaseLocations = [
            "curtain" => new Vector2(screenCenter.x, screenCenter.y - 95)
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
            //allPhases.remove(currentPhase);
            allPhases.remove("enrage");
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
        else if(currentPhase == "curtain") {
            if(!curtainShotTimer.active) {
                phaseTimer.reset(
                    (isEnraged ? ENRAGE_PHASE_DURATION : PHASE_DURATION)
                    * CURTAIN_PHASE_DURATION_MULTIPLIER
                );
                curtainShotTimer.reset(
                    isEnraged ?
                    ENRAGE_CURTAIN_SHOT_INTERVAL : CURTAIN_SHOT_INTERVAL
                );
                curtainAimedShotTimer.start();
            }
        }
    }

    private function curtainShot() {
        var slant = HXP.choose(2, 1.5, 1, 0.5, 0) * HXP.choose(1, -1);
        var speed = HXP.choose(
            //CURTAIN_SHOT_SPEED,
            //CURTAIN_SHOT_SPEED / 1.5,
            //CURTAIN_SHOT_SPEED / 2,
            CURTAIN_SHOT_SPEED * 1.25,
            CURTAIN_SHOT_SPEED * 1.5,
            CURTAIN_SHOT_SPEED * 1.75,
            CURTAIN_SHOT_SPEED * 2,
            CURTAIN_SHOT_SPEED * 2.25,
            CURTAIN_SHOT_SPEED * 2.5
        );
        var lowerBound = HXP.choose(
            -50, -40, -30, -20, -10, 0, 10, 20, 30
        );
        var upperBound = lowerBound + HXP.choose(20, 30, 40);
        var tiltDirection = HXP.choose(true, false);
        for(i in lowerBound...upperBound) {
            var shotVector = new Vector2(0, 1);
            shotVector.rotate(Math.sin(age * 2) / 6);
            var bulletSpeed = (
                tiltDirection ?
                speed + i:
                speed + (upperBound - i)
            );
            var spit = new Spit(
                this, shotVector, bulletSpeed, false
            );
            spit.x += i * 3;
            if(slant > 0) {
                spit.y -= i * slant;
            }
            else {
                spit.y -= (upperBound - i) * Math.abs(slant);
            }
            spit.y -= 10;
            scene.add(spit);
        }
    }

    private function curtainAimedShot() {
        var shotAngle = getAngleTowardsPlayer();
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        scene.add(new Spit(this, shotVector, CURTAIN_AIMED_SHOT_SPEED, true));
    }

    private function atPhaseLocation() {
        return (
            x == phaseLocations[currentPhase].x
            && y == phaseLocations[currentPhase].y
        );
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


