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
    public static inline var CURTAIN_PHASE_DURATION_MULTIPLIER = 1.5;

    public static inline var STARTING_HEALTH = 100;
    public static inline var ENRAGE_THRESHOLD = 40;

    public static inline var CLOCK_SHOT_SPEED = 108;

    public static inline var CURTAIN_SHOT_SPEED = 80;
    public static inline var CURTAIN_SHOT_INTERVAL = 2;
    public static inline var ENRAGE_CURTAIN_SHOT_INTERVAL = 1;
    public static inline var CURTAIN_BARRIER_SHOT_SPEED = 160;

    public static inline var CIRCLE_PERIMETER_TIME = 10;
    public static inline var ENRAGED_CIRCLE_PERIMETER_TIME = 7.5;
    public static inline var CIRCLE_SHOT_SPEED = 80;

    public static inline var ENRAGE_SHOT_INTERVAL = 0.02;
    public static inline var ENRAGE_SHOT_SPEED = 100;
    public static inline var ENRAGE_SINGLE_ROTATION_DURATION = 10;

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

    private var clockShotTimer:Alarm;

    private var curtainShotTimer:Alarm;
    private var curtainBarrierShotTimer:Alarm;

    private var circlePerimeter:LinearPath;
    private var circleShotTimer:Alarm;

    private var enrageShotTimer:Alarm;

    private var sfx:Map<String, Sfx>;
    private var hitbox:Hitbox;

    public function new(startX:Float, startY:Float) {
        super(startX - SIZE / 2, startY - SIZE / 2);
        name = "grandjoker";
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
        sprite = new Spritemap("graphics/bosses.png", SIZE, SIZE);
        sprite.add("dying", [6]);
        sprite.add("idle", [6, 7], 4);
        sprite.add("shoot", [8, 9], 2);
        sprite.play("idle");
        graphic = sprite;
        health = STARTING_HEALTH;

        isEnraged = false;
        enrageNextPhase = false;
        isDying = false;

        generatePhaseLocations();

        phaseRelocater = new LinearMotion();
        addTween(phaseRelocater);

        currentPhase = HXP.choose("clock", "curtain", "circle");
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

        curtainBarrierShotTimer = new Alarm(0.05, TweenType.Looping);
        curtainBarrierShotTimer.onComplete.bind(function() {
            curtainBarrierShot();
            sprite.play("shoot");
        });
        addTween(curtainBarrierShotTimer);

        circleShotTimer = new Alarm(0.015, TweenType.Looping);
        circleShotTimer.onComplete.bind(function() {
            circleShot();
        });
        addTween(circleShotTimer);

        preEnrage = new Alarm(PRE_ENRAGE_TIME);
        preEnrage.onComplete.bind(function() {
            age = 0;
            enrageShotTimer.start();
            sprite.play("shoot");
        });
        addTween(preEnrage);

        enrageShotTimer = new Alarm(ENRAGE_SHOT_INTERVAL, TweenType.Looping);
        enrageShotTimer.onComplete.bind(function() {
            enrageShot();
        });
        addTween(enrageShotTimer);

        sfx = [
            "enrage" => new Sfx("audio/enrage.wav"),
            "rippleattack1" => new Sfx("audio/rippleattack1.wav"),
            "rippleattack2" => new Sfx("audio/rippleattack2.wav"),
            "rippleattack3" => new Sfx("audio/rippleattack3.wav"),
            "flurry" => new Sfx("audio/flurry.wav")
        ];
        fightStarted = GameScene.hasGlobalFlag("grandJokerFightStarted");
    }

    private function generatePhaseLocations() {
        phaseLocations = [
            "clock" => new Vector2(screenCenter.x, screenCenter.y),
            "curtain" => new Vector2(screenCenter.x, screenCenter.y - 95),
            // circle is set below
            "enrage" => new Vector2(screenCenter.x, screenCenter.y)
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
        phaseLocations["circle"] = new Vector2(startPoint.x, startPoint.y);
        while(pointCount < 5) {
            var point = perimeterPoints[
                (startCount + pointCount) % perimeterPoints.length
            ];
            circlePerimeter.addPoint(point.x, point.y);
            pointCount++;
        }
        circlePerimeter.onComplete.bind(function() {
            preAdvancePhase();
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
            allPhases.remove("enrage");
            if(currentPhase == "enrage") {
                allPhases.remove("clock");
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
                gameScene.converse("grandjoker");
                GameScene.addGlobalFlag("grandJokerFightStarted");
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
        else if(currentPhase == "clock") {
            if(!clockShotTimer.active) {
                if(!sfx["flurry"].playing) {
                    sfx["flurry"].loop();
                }
                sprite.play("shoot");
                phaseTimer.reset(
                    isEnraged ? ENRAGE_PHASE_DURATION : PHASE_DURATION
                );
                clockShotTimer.start();
                age = Math.random() * Math.PI * 2;
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
                curtainBarrierShotTimer.start();
                age = Math.random() * Math.PI * 2;
            }
        }
        else if(currentPhase == "circle") {
            if(!sfx["flurry"].playing) {
                sfx["flurry"].loop();
            }
            var player = scene.getInstance("player");
            sprite.play("idle");
            sprite.flipX = centerX > player.centerX;
            hitbox.x = sprite.flipX ? 25 : 3;
            if(!circlePerimeter.active && !preAdvancePhaseTimer.active) {
                circlePerimeter.setMotion(
                    isEnraged ?
                    ENRAGED_CIRCLE_PERIMETER_TIME : CIRCLE_PERIMETER_TIME,
                    Ease.linear
                );
                circlePerimeter.start();
                circleShotTimer.start();
            }
            else {
                moveTo(circlePerimeter.x, circlePerimeter.y);
            }
        }
        else if(currentPhase == "enrage") {
            if(
                enrageShotTimer.active
                && age >= ENRAGE_SINGLE_ROTATION_DURATION * 2
            ) {
                preAdvancePhase();
            }
            else if(
                !preEnrage.active
                && !enrageShotTimer.active
                && !preAdvancePhaseTimer.active
            ) {
                preEnrage.start();
                sfx["enrage"].play();
            }
        }
    }

    private function clockShot() {
        var rotationSpeedMultiplier = isEnraged ? 1.25 : 1;
        var shotVector = new Vector2(0, -1);
        shotVector.rotate(-age * Math.PI / 2 * rotationSpeedMultiplier);
        scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED, false));

        shotVector = new Vector2(0, -1);
        shotVector.rotate(age * Math.PI / 3 * rotationSpeedMultiplier);
        scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED / 2, false));

        var shotVector = new Vector2(0, -1);
        shotVector.rotate(-age * Math.PI / 4 * rotationSpeedMultiplier);
        scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED / 2, false));

        shotVector = new Vector2(0, -1);
        shotVector.rotate(age * Math.PI / 5 * rotationSpeedMultiplier);
        scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED, false));

        if(isEnraged) {
            shotVector = new Vector2(0, -1);
            shotVector.rotate(age * Math.PI / 1.5);
            scene.add(new Spit(this, shotVector, CLOCK_SHOT_SPEED, false));
        }
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
        for(i in -50...50) {
            var shotVector = new Vector2(0, 1);
            var spit = new Spit(this, shotVector, speed, false);
            spit.x += i * 3;
            spit.y -= i * slant;
            scene.add(spit);
        }
        sfx['rippleattack${HXP.choose(1, 2, 3)}'].play();
    }

    private function curtainBarrierShot() {
        if(!sfx["flurry"].playing) {
            sfx["flurry"].loop();
        }
        var shotVector = new Vector2(1, (Math.random() - 0.5) / 1.5);
        var shotSpeed = Math.max(
            CURTAIN_BARRIER_SHOT_SPEED * Math.random(),
            CURTAIN_BARRIER_SHOT_SPEED / 4
        );
        scene.add(new Spit(this, shotVector, shotSpeed, false));
        var shotVector = new Vector2(-1, (Math.random() - 0.5) / 1.5);
        scene.add(new Spit(this, shotVector, shotSpeed, false));
        var shotVector = new Vector2(1, (Math.random() - 0.8));
        scene.add(new Spit(this, shotVector, shotSpeed, false));
        var shotVector = new Vector2(-1, (Math.random() - 0.8));
        scene.add(new Spit(this, shotVector, shotSpeed, false));

        var shotVector = new Vector2(1, 0.3);
        var spit = new Spit(this, shotVector, CURTAIN_BARRIER_SHOT_SPEED, false);
        scene.add(spit);

        shotVector = new Vector2(-1, 0.3);
        spit = new Spit(this, shotVector, CURTAIN_BARRIER_SHOT_SPEED, false);
        scene.add(spit);
    }

    private function circleShot() {
        var shotAngle = age * 4;
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        var spit = new Spit(this, shotVector, CIRCLE_SHOT_SPEED, false);
        scene.add(spit);

        shotAngle = getAngleTowardsPlayer();
        shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        spit = new Spit(this, shotVector, CIRCLE_SHOT_SPEED * 2, false);
        scene.add(spit);

        if(isEnraged) {
            shotAngle = -age * 4;
            shotVector = new Vector2(
                Math.cos(shotAngle), Math.sin(shotAngle)
            );
            spit = new Spit(this, shotVector, CIRCLE_SHOT_SPEED, false);
            scene.add(spit);
        }
    }

    private function enrageShot() {
        if(!sfx["flurry"].playing) {
            sfx["flurry"].loop();
        }
        var shotAngle = -Math.PI / 2;
        if(age < ENRAGE_SINGLE_ROTATION_DURATION) {
            shotAngle += age * age;
        }
        else {
            shotAngle += (
                (ENRAGE_SINGLE_ROTATION_DURATION * 2 - age)
                * (ENRAGE_SINGLE_ROTATION_DURATION * 2 - age)
            );
        }
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        var spit = new Spit(
            this, shotVector, ENRAGE_SHOT_SPEED, false
        );
        scene.add(spit);
    }

    private function atPhaseLocation() {
        return (
            x == phaseLocations[currentPhase].x
            && y == phaseLocations[currentPhase].y
        );
    }

    override function die() {
        GameScene.addGlobalFlag("grandjokerDefeated");
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
            gameScene.converse("grandjokerdeath");
        });
        addTween(deathConversationDelay, true);
    }
}
