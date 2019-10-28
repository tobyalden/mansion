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
    public static inline var PRE_PHASE_ADVANCE_TIME = 1.5;
    public static inline var PHASE_TRANSITION_TIME = 1.5;
    public static inline var ENRAGED_PHASE_TRANSITION_TIME = 1;
    public static inline var PHASE_DURATION = 12.5;
    public static inline var ENRAGE_PHASE_DURATION = 8;
    public static inline var CURTAIN_PHASE_DURATION_MULTIPLIER = 1.5;
    public static inline var WAVE_PHASE_DURATION_MULTIPLIER = 1.5;

    public static inline var STARTING_HEALTH = 200;
    public static inline var ENRAGE_THRESHOLD = 80;

    public static inline var CURTAIN_SHOT_SPEED = 80;
    public static inline var CURTAIN_SHOT_INTERVAL = 0.6;
    public static inline var ENRAGE_CURTAIN_SHOT_INTERVAL = 0.4;
    public static inline var CURTAIN_AIMED_SHOT_INTERVAL = 1.1;
    public static inline var ENRAGE_CURTAIN_AIMED_SHOT_INTERVAL = 0.9;
    public static inline var CURTAIN_AIMED_SHOT_SPEED = 200;

    public static inline var WAVE_SHOT_SPEED = 185;
    public static inline var WAVE_SHOT_INTERVAL = 2;
    public static inline var ENRAGE_WAVE_SHOT_INTERVAL = 1.5;

    public static inline var TENTACLE_SHOT_SPEED = 200;
    public static inline var TENTACLE_SHOT_INTERVAL = 0.01;

    public static inline var ENRAGE_SHOT_SPEED = 100;
    public static inline var ENRAGE_SHOT_INTERVAL = 0.01;

    public static inline var CHARGE_DISTANCE = 160;
    public static inline var CHARGE_TIME = 2;
    public static inline var ENRAGE_CHARGE_TIME = 1;

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
    private var isDying:Bool;

    private var curtainShotTimer:Alarm;
    private var curtainAimedShotTimer:Alarm;

    private var waveShotTimer:Alarm;

    private var tentacleShotTimer:Alarm;

    private var enrageShotTimer:Alarm;

    private var chargeAttack:LinearMotion;
    private var chargeRetreat:LinearMotion;

    private var lastNonChargePhase:String;

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
        sprite.add("dying", [0]);
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

        chargeAttack = new LinearMotion();
        chargeAttack.onComplete.bind(function() {
            chargeRetreat.setMotion(
                x, y, x, y - CHARGE_DISTANCE,
                isEnraged ? ENRAGE_CHARGE_TIME : CHARGE_TIME,
                Ease.sineInOut
            );
            chargeRetreat.start();
        });
        addTween(chargeAttack);
        chargeRetreat = new LinearMotion();
        chargeRetreat.onComplete.bind(function() {
            preAdvancePhase();
        });

        addTween(chargeRetreat);

        //currentPhase = HXP.choose("waves");
        currentPhase = "charge";
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

        waveShotTimer = new Alarm(WAVE_SHOT_INTERVAL, TweenType.Looping);
        waveShotTimer.onComplete.bind(function() {
            waveShot();
        });
        addTween(waveShotTimer);

        tentacleShotTimer = new Alarm(TENTACLE_SHOT_INTERVAL, TweenType.Looping);
        tentacleShotTimer.onComplete.bind(function() {
            tentacleShot();
        });
        addTween(tentacleShotTimer);

        preEnrage = new Alarm(PRE_ENRAGE_TIME);
        preEnrage.onComplete.bind(function() {
            phaseTimer.reset(ENRAGE_PHASE_DURATION);
            enrageShotTimer.start();
        });
        addTween(preEnrage);

        enrageShotTimer = new Alarm(ENRAGE_SHOT_INTERVAL, TweenType.Looping);
        enrageShotTimer.onComplete.bind(function() {
            enrageShot();
        });
        addTween(enrageShotTimer);

        sfx = [
            "enrage" => new Sfx("audio/enrage.wav")
        ];
        fightStarted = GameScene.hasGlobalFlag("grandfatherFightStarted");
    }

    private function generatePhaseLocations() {
        phaseLocations = [
            "charge" => new Vector2(screenCenter.x, screenCenter.y - 95),
            "curtain" => new Vector2(screenCenter.x, screenCenter.y - 95),
            "waves" => new Vector2(screenCenter.x, screenCenter.y - 95),
            "tentacles" => new Vector2(screenCenter.x, screenCenter.y - 95),
            "enrage" => new Vector2(screenCenter.x, screenCenter.y - 95)
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
            if(!GameScene.isNightmare) {
                allPhases.remove("enrage");
            }
            allPhases.remove(lastNonChargePhase);
            if(currentPhase == "charge") {
                currentPhase = allPhases[
                    Std.int(Math.floor(Math.random() * allPhases.length))
                ];
                lastNonChargePhase = currentPhase;
            }
            else {
                currentPhase = "charge";
            }
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
                //scene.remove(this);
                bigExplosionSpawner.cancel();
                visible = false;
                collidable = false;
            }
            clearHazards();
        }
        else if(!fightStarted || gameScene.isDialogMode) {
            // Do nothing
            sprite.play("dying");
            var player = scene.getInstance("player");
            if(player.y - bottom < 50 && !gameScene.isDialogMode) {
                gameScene.converse("grandfather");
                GameScene.addGlobalFlag("grandfatherFightStarted");
            }
        }
        else if(betweenPhases) {
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
        else if(currentPhase == "charge") {
            if(!chargeAttack.active && !chargeRetreat.active) {
                chargeAttack.setMotion(
                    x, y, x, y + CHARGE_DISTANCE,
                    isEnraged ? ENRAGE_CHARGE_TIME : CHARGE_TIME,
                    Ease.sineInOut
                );
                chargeAttack.start();
            }
            else {
                if(chargeAttack.active) {
                    moveTo(chargeAttack.x, chargeAttack.y);
                }
                else {
                    moveTo(chargeRetreat.x, chargeRetreat.y);
                }
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
                curtainAimedShotTimer.reset(
                    isEnraged ?
                    ENRAGE_CURTAIN_AIMED_SHOT_INTERVAL
                    : CURTAIN_AIMED_SHOT_INTERVAL
                );
            }
        }
        else if(currentPhase == "waves") {
            if(!waveShotTimer.active) {
                phaseTimer.reset(
                    (isEnraged ? ENRAGE_PHASE_DURATION : PHASE_DURATION)
                    * WAVE_PHASE_DURATION_MULTIPLIER
                );
                waveShotTimer.reset(
                    isEnraged ?
                    ENRAGE_WAVE_SHOT_INTERVAL : WAVE_SHOT_INTERVAL
                );
            }
        }
        else if(currentPhase == "tentacles") {
            if(!tentacleShotTimer.active) {
                age = 0;
                phaseTimer.reset(
                    (isEnraged ? ENRAGE_PHASE_DURATION : PHASE_DURATION)
                );
                tentacleShotTimer.reset(TENTACLE_SHOT_INTERVAL);
            }
        }
        else if(currentPhase == "enrage") {
            if(
                !preEnrage.active
                && !enrageShotTimer.active
            ) {
                preEnrage.start();
                sfx["enrage"].play();
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

    private function waveShot() {
        var fromSide = HXP.choose(true, false);
        var fromLeft = HXP.choose(true, false);
        for(i in -50...50) {
            var shotVector = new Vector2(0, 1);
            var accel = new Vector2(0, -70);
            var spit = new Spit(
                this, shotVector, WAVE_SHOT_SPEED, false, accel
            );
            spit.x += i * 3;
            spit.y -= 10;
            if(!fromSide) {
                scene.add(spit);
            }

            shotVector = new Vector2(fromLeft ? 1 : -1, 0);
            accel = new Vector2(fromLeft ? -60 : 60, 0);
            spit = new Spit(
                this, shotVector, WAVE_SHOT_SPEED, false, accel
            );
            spit.x -= fromLeft ? 150 : -150;
            spit.y += i * 3 + 100;
            if(fromSide) {
                scene.add(spit);
            }
        }
    }

    private function tentacleShot() {
        var shotAngle = Math.sin(age) + Math.PI / 2;
        var accel = new Vector2(Math.sin(age) * 150, 0);
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        if(isEnraged) {
            scene.add(new Spit(
                this, shotVector, TENTACLE_SHOT_SPEED, false, accel
            ));
        }

        shotAngle = -Math.sin(age / Math.PI) + Math.PI / 2;
        shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        scene.add(new Spit(
            this, shotVector, TENTACLE_SHOT_SPEED, false, accel
        ));

        shotAngle = Math.cos(age * Math.PI / 1.5) + Math.PI / 2;
        shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        scene.add(new Spit(
            this, shotVector, TENTACLE_SHOT_SPEED, false, accel
        ));

        shotAngle = -Math.cos(age) + Math.PI / 2;
        shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        scene.add(new Spit(
            this, shotVector, TENTACLE_SHOT_SPEED, false, accel
        ));
    }

    private function enrageShot() {
        var shotAngle = getAngleTowardsPlayer();
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        var spit = new Spit(this, shotVector, ENRAGE_SHOT_SPEED, false);
        scene.add(spit);
        spit = new Spit(this, shotVector, ENRAGE_SHOT_SPEED / 2, false);
        scene.add(spit);
        shotVector = new Vector2(
            -Math.cos(shotAngle), Math.sin(shotAngle)
        );
        spit = new Spit(this, shotVector, ENRAGE_SHOT_SPEED, false);
        scene.add(spit);
        spit = new Spit(this, shotVector, ENRAGE_SHOT_SPEED / 2, false);
        scene.add(spit);
    }

    private function atPhaseLocation() {
        return (
            x == phaseLocations[currentPhase].x
            && y == phaseLocations[currentPhase].y
        );
    }

    override function die() {
        GameScene.addGlobalFlag("grandfatherDefeated");
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
            gameScene.converse("grandfatherdeath");
        });
        addTween(deathConversationDelay, true);
    }
}


