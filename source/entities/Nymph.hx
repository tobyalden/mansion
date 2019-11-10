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

    public static inline var SPIRAL_SHOT_SPEED = 92.5;
    public static inline var SPIRAL_TURN_RATE = 1;
    public static inline var SPIRAL_BULLETS_PER_SHOT = 4;
    public static inline var SPIRAL_SHOT_INTERVAL = 0.05;

    public static inline var RIPPLE_SHOT_SPEED = 100;
    public static inline var RIPPLE_SHOT_SPREAD = 15;
    public static inline var RIPPLE_SHOT_INTERVAL = 2.7;
    public static inline var ENRAGED_RIPPLE_SHOT_INTERVAL = 1.8;
    public static inline var RIPPLE_BULLETS_PER_SHOT = 200;

    public static inline var PRE_ENRAGE_TIME = 2;
    public static inline var PRE_PHASE_ADVANCE_TIME = 2;
    public static inline var PHASE_TRANSITION_TIME = 2;
    public static inline var ENRAGED_PHASE_TRANSITION_TIME = 1.33;
    public static inline var PHASE_DURATION = 60;
    public static inline var ENRAGE_PHASE_DURATION = 8;
    public static inline var CURTAIN_PHASE_DURATION_MULTIPLIER = 1.5;

    public static inline var STARTING_HEALTH = 200;
    public static inline var ENRAGE_THRESHOLD = 40;

    private var spiralShotInterval:Alarm;
    private var spiralShotStartAngle:Float;

    private var rippleShotInterval:Alarm;

    public var sfx:Map<String, Sfx> = [
        "enrage" => new Sfx("audio/enrage.ogg"),
        "rippleattack1" => new Sfx("audio/rippleattack1.ogg"),
        "rippleattack2" => new Sfx("audio/rippleattack2.ogg"),
        "rippleattack3" => new Sfx("audio/rippleattack3.ogg"),
        "flurry" => new Sfx("audio/flurry.ogg")
    ];

    public var isDying(default, null):Bool;

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
    private var stopActing:Bool;

    private var hitbox:Hitbox;

    public function new(startX:Float, startY:Float) {
        super(startX - SIZE / 2, startY - SIZE / 2);
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

        spiralShotInterval = new Alarm(
            SPIRAL_SHOT_INTERVAL, TweenType.Looping
        );
        spiralShotInterval.onComplete.bind(function() {
            spiralShot();
        });
        addTween(spiralShotInterval);
        spiralShotStartAngle = 0;

        rippleShotInterval = new Alarm(
            RIPPLE_SHOT_INTERVAL, TweenType.Looping
        );
        rippleShotInterval.onComplete.bind(function() {
            rippleShot();
        });
        addTween(rippleShotInterval);

        isEnraged = GameScene.isNightmare ? true : false;
        enrageNextPhase = false;
        isDying = false;
        stopActing = false;

        generatePhaseLocations();

        phaseRelocater = new LinearMotion();
        addTween(phaseRelocater);

        currentPhase = HXP.choose("wheel");
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
            //"curtain" => new Vector2(screenCenter.x, screenCenter.y - 95),
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
            if(!spiralShotInterval.active) {
                spiralShotInterval.start();
                spiralShotStartAngle = getAngleTowardsPlayer();
                age = Math.PI * 1.5;

                rippleShotInterval.reset(
                    isEnraged ?
                    ENRAGED_RIPPLE_SHOT_INTERVAL
                    : RIPPLE_SHOT_INTERVAL
                );
                rippleShot();
                phaseTimer.start();
            }
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
}

