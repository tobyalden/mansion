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

class GrandJoker extends Enemy
{
    public static inline var SIZE = 80;

    public static inline var PRE_ENRAGE_TIME = 2;
    public static inline var PRE_PHASE_ADVANCE_TIME = 2;
    public static inline var PHASE_TRANSITION_TIME = 2;
    public static inline var ENRAGED_PHASE_TRANSITION_TIME = 1.33;
    public static inline var PHASE_DURATION = 12.5;
    public static inline var ENRAGE_PHASE_DURATION = 10;

    public static inline var STARTING_HEALTH = 100;
    public static inline var ENRAGE_THRESHOLD = 40;

    public static inline var CLOCK_SHOT_SPEED = 108;

    public static inline var CURTAIN_SHOT_SPEED = 80;
    public static inline var CURTAIN_SHOT_INTERVAL = 2;

    public static inline var CURTAIN_AIMED_SHOT_SPEED = 160;

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

    private var clockShotTimer:Alarm;

    private var curtainShotTimer:Alarm;
    private var curtainAimedShotTimer:Alarm;

    private var sfx:Map<String, Sfx>;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        name = "grandjoker";
        isBoss = true;
        mask = new Hitbox(SIZE, SIZE);
        x -= width / 2;
        y -= height / 2;
        screenCenter = new Vector2(x, y);
        y -= 50;
        sprite = new Spritemap("graphics/grandjoker.png", SIZE, SIZE);
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
            // Start enrage phase timers
            //phaseTimer.reset(ENRAGE_PHASE_DURATION);
        });
        addTween(preEnrage);

        //currentPhase = HXP.choose("clock");
        currentPhase = "curtain";
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

        clockShotTimer = new Alarm(0.025, TweenType.Looping);
        clockShotTimer.onComplete.bind(function() {
            clockShot();
        });
        addTween(clockShotTimer);

        curtainShotTimer = new Alarm(CURTAIN_SHOT_INTERVAL, TweenType.Looping);
        curtainShotTimer.onComplete.bind(function() {
            curtainShot();
        });
        addTween(curtainShotTimer);

        curtainAimedShotTimer = new Alarm(0.05, TweenType.Looping);
        curtainAimedShotTimer.onComplete.bind(function() {
            curtainAimedShot();
        });
        addTween(curtainAimedShotTimer);

        sfx = [
            "enrage" => new Sfx("audio/enrage.wav")
        ];
    }

    private function generatePhaseLocations() {
        phaseLocations = [
            "clock" => new Vector2(screenCenter.x, screenCenter.y),
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
            allPhases.remove(currentPhase);
            allPhases.remove("enrage");
            //currentPhase = allPhases[
                //Std.int(Math.floor(Math.random() * allPhases.length))
            //];
            currentPhase = "clock";
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
        else if(currentPhase == "clock") {
            if(!clockShotTimer.active) {
                clockShotTimer.start();
                age = 0;
            }
        }
        else if(currentPhase == "curtain") {
            if(!curtainShotTimer.active) {
                curtainShotTimer.start();
                curtainAimedShotTimer.start();
                age = 0;
            }
        }
        else if(currentPhase == "enrage") {
            // Do nothing
        }
    }

    private function clockShot() {
        var shotVector = new Vector2(0, -1);
        shotVector.rotate(age);
        scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED, false));

        shotVector = new Vector2(0, -1);
        shotVector.rotate(age * 2);
        scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED, false));

        //shotVector = new Vector2(0, -1);
        //shotVector.rotate(age / 2);
        //scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED, false));

        shotVector = new Vector2(0, -1);
        shotVector.rotate(-age);
        scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED, false));

        //shotVector = new Vector2(0, -1);
        //shotVector.rotate(-age * 2);
        //scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED, false));

        shotVector = new Vector2(0, -1);
        shotVector.rotate(-age / 2);
        scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED, false));
    }

    private function curtainShot() {
        var slant = HXP.choose(1.5, 1, 0.5, 0) * HXP.choose(1, -1);
        var speed = HXP.choose(
            CURTAIN_SHOT_SPEED,
            CURTAIN_SHOT_SPEED / 1.5,
            CURTAIN_SHOT_SPEED / 2,
            CURTAIN_SHOT_SPEED * 1.5,
            CURTAIN_SHOT_SPEED * 2
        );
        var boundPair = HXP.choose(
            new Vector2(0, 50),
            new Vector2(-50, 0),
            new Vector2(-25, 25)
        );
        //for(i in -Std.int(boundPair.x)...Std.int(boundPair.y)) {
        for(i in -50...50) {
            var shotVector = new Vector2(0, 1);
            var spit = new Spit(this, shotVector, speed, false);
            spit.x += i * 3;
            spit.y -= i * slant;
            scene.add(spit);
        }
    }

    private function curtainAimedShot() {
        var shotVector = new Vector2(Math.sin(age), 1);
        //scene.add(new Spit(this, shotVector, CURTAIN_AIMED_SHOT_SPEED, false));
        var shotVector = new Vector2(Math.sin(age * 2), 1);
        //scene.add(new Spit(this, shotVector, CURTAIN_AIMED_SHOT_SPEED, false));
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

