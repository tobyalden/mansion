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

class SuperWizard extends Enemy
{
    public static inline var SIZE = 80;

    public static inline var SPIRAL_SHOT_SPEED = 62.5;
    public static inline var SPIRAL_TURN_RATE = 4;
    public static inline var SPIRAL_BULLETS_PER_SHOT = 2;
    public static inline var SPIRAL_SHOT_INTERVAL = 0.05;

    public static inline var RIPPLE_SHOT_SPEED = 100;
    public static inline var RIPPLE_SHOT_SPREAD = 15;
    public static inline var RIPPLE_SHOT_INTERVAL = 2.7;
    public static inline var ENRAGED_RIPPLE_SHOT_INTERVAL = 1.8;
    public static inline var RIPPLE_BULLETS_PER_SHOT = 200;

    public static inline var SPOUT_SHOT_SPEED = 150;
    public static inline var SPOUT_SHOT_INTERVAL = 1.5;
    public static inline var ENRAGED_SPOUT_SHOT_INTERVAL = 1;

    public static inline var ZIG_ZAG_COUNT = 3;
    public static inline var ENRAGED_ZIG_ZAG_COUNT = 6;
    public static inline var ZIG_ZAG_TIME = 2.5;
    public static inline var ENRAGED_ZIG_ZAG_TIME = 1.8;
    public static inline var ZIG_ZAG_SHOT_INTERVAL = 0.75;
    public static inline var ZIG_ZAG_SHOT_SPEED = 100;

    public static inline var PRE_ENRAGE_TIME = 2;
    public static inline var ENRAGE_RIPPLE_INTERVAL = 1.75;
    public static inline var ENRAGE_SPOUT_INTERVAL = 0.05;

    public static inline var PRE_PHASE_ADVANCE_TIME = 2;
    public static inline var PHASE_TRANSITION_TIME = 2;
    public static inline var ENRAGED_PHASE_TRANSITION_TIME = 1.33;
    public static inline var PHASE_DURATION = 12.5;
    public static inline var ENRAGE_PHASE_DURATION = 10;

    public static inline var STARTING_HEALTH = 100;
    public static inline var ENRAGE_THRESHOLD = 40;

    public var laser(default, null):SuperWizardLaser;

    private var sprite:Spritemap;

    private var spiralShotInterval:Alarm;
    private var spiralShotStartAngle:Float;

    private var rippleShotInterval:Alarm;
    private var spoutShotInterval:Alarm;

    private var preLaser:Alarm;
    private var preZigZag:Alarm;
    private var zigZag:LinearPath;
    private var postZigZag:Alarm;

    private var preEnrage:Alarm;
    private var enrageRippleInterval:Alarm;
    private var enrageSpoutInterval:Alarm;

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

    private var sfx:Map<String, Sfx>;

    public function new(startX:Float, startY:Float) {
        super(startX - SIZE / 2, startY - SIZE / 2);
        name = "superwizard";
        isBoss = true;
        var hitbox = new Hitbox(50, SIZE);
        hitbox.x = 16;
        mask = hitbox;
        //x -= width / 2;
        //y -= height / 2;
        screenCenter = new Vector2(x, y);
        y -= 50;
        startPosition.y -= 50;
        sprite = new Spritemap("graphics/bosses.png", SIZE, SIZE);
        sprite.add("idle", [0]);
        sprite.add("laser", [1]);
        sprite.add("shoot", [2]);
        sprite.play("idle");
        graphic = sprite;
        health = 1;

        laser = new SuperWizardLaser(this);

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
        spoutShotInterval = new Alarm(
            SPOUT_SHOT_INTERVAL, TweenType.Looping
        );
        spoutShotInterval.onComplete.bind(function() {
            spoutShot();
        });
        addTween(spoutShotInterval);

        isEnraged = false;
        enrageNextPhase = false;
        isDying = false;

        generatePhaseLocations();

        phaseRelocater = new LinearMotion();
        addTween(phaseRelocater);

        preLaser = new Alarm(SuperWizardLaser.WARM_UP_TIME);
        preLaser.onComplete.bind(function() {
            preZigZag.start();
        });
        addTween(preLaser);

        postZigZag = new Alarm(SuperWizardLaser.TURN_OFF_TIME * 2);
        postZigZag.onComplete.bind(function() {
            preAdvancePhase();
        });
        addTween(postZigZag);

        preEnrage = new Alarm(PRE_ENRAGE_TIME);
        preEnrage.onComplete.bind(function() {
            enrageRippleInterval.start();
            enrageSpoutInterval.start();
            // TODO: This makes all the phases after this shorter.
            // Is that desired? Probably, but good to note.
            phaseTimer.reset(ENRAGE_PHASE_DURATION);
        });
        addTween(preEnrage);
        enrageRippleInterval = new Alarm(
            ENRAGE_RIPPLE_INTERVAL, TweenType.Looping
        );
        enrageRippleInterval.onComplete.bind(function() {
            rippleShot();
        });
        addTween(enrageRippleInterval);
        enrageSpoutInterval = new Alarm(
            ENRAGE_SPOUT_INTERVAL, TweenType.Looping
        );
        enrageSpoutInterval.onComplete.bind(function() {
            spoutShot(false);
        });
        addTween(enrageSpoutInterval);

        currentPhase = HXP.choose("spiral", "rippleAndSpout", "zigZag");
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

        sfx = [
            "enrage" => new Sfx("audio/enrage.wav"),
            "bigshot1" => new Sfx("audio/bigshot1.wav"),
            "bigshot2" => new Sfx("audio/bigshot2.wav"),
            "bigshot3" => new Sfx("audio/bigshot3.wav"),
            "rippleattack1" => new Sfx("audio/rippleattack1.wav"),
            "rippleattack2" => new Sfx("audio/rippleattack2.wav"),
            "rippleattack3" => new Sfx("audio/rippleattack3.wav"),
            "flurry" => new Sfx("audio/flurry.wav")
        ];
        collidable = false;
        fightStarted = GameScene.hasGlobalFlag("superWizardFightStarted");
    }

    public function stopSfx() {
        sfx["flurry"].stop();
        laser.stopSfx();
    }

    private function generatePhaseLocations() {
        phaseLocations = [
            "spiral" => new Vector2(screenCenter.x, screenCenter.y),
            "rippleAndSpout" => new Vector2(
                screenCenter.x + 95 * HXP.choose(1, -1),
                screenCenter.y + 95 * HXP.choose(1, -1)
            ),
            "zigZag" => new Vector2(screenCenter.x, screenCenter.y - 95),
            "enrage" => new Vector2(screenCenter.x, screenCenter.y - 95)
        ];

        zigZag = new LinearPath();
        zigZag.onComplete.bind(function() {
            laser.turnOff();
            postZigZag.start();
        });
        zigZag.addPoint(screenCenter.x, screenCenter.y - 95);
        var zigZagCount = isEnraged ? ENRAGED_ZIG_ZAG_COUNT : ZIG_ZAG_COUNT;
        var zigZagTime = isEnraged ? ENRAGED_ZIG_ZAG_TIME : ZIG_ZAG_TIME;
        if(Math.random() > 0.5) {
            for(i in 0...zigZagCount) {
                zigZag.addPoint(screenCenter.x - 120, screenCenter.y - 95);
                zigZag.addPoint(screenCenter.x + 120, screenCenter.y - 95);
            }
        }
        else {
            for(i in 0...zigZagCount) {
                zigZag.addPoint(screenCenter.x + 120, screenCenter.y - 95);
                zigZag.addPoint(screenCenter.x - 120, screenCenter.y - 95);
            }
        }
        zigZag.addPoint(screenCenter.x, screenCenter.y - 95);
        addTween(zigZag);

        preZigZag = new Alarm(SuperWizardLaser.WARM_UP_TIME);
        preZigZag.onComplete.bind(function() {
            zigZag.setMotion(zigZagCount * zigZagTime, Ease.sineInOut);
            zigZag.start();
        });
        addTween(preZigZag);
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
                gameScene.converse("superwizard");
                GameScene.addGlobalFlag("superWizardFightStarted");
            }
        }
        else if(betweenPhases) {
            sfx['flurry'].stop();
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
        else if(currentPhase == "spiral") {
            sprite.play("shoot");
            if(!spiralShotInterval.active) {
                spiralShotInterval.start();
                spiralShotStartAngle = getAngleTowardsPlayer();
                age = Math.PI * 1.5;
                phaseTimer.start();
            }
        }
        else if(currentPhase == "rippleAndSpout") {
            sprite.play("shoot");
            if(!rippleShotInterval.active) {
                rippleShotInterval.reset(
                    isEnraged ?
                    ENRAGED_RIPPLE_SHOT_INTERVAL
                    : RIPPLE_SHOT_INTERVAL
                );
                spoutShotInterval.reset(
                    isEnraged ?
                    ENRAGED_SPOUT_SHOT_INTERVAL
                    : SPOUT_SHOT_INTERVAL
                );
                phaseTimer.start();
                rippleShot();
            }
        }
        else if(currentPhase == "zigZag") {
            sprite.play("laser");
            if(
                !preLaser.active && !preZigZag.active
                && !zigZag.active && !postZigZag.active
            ) {
                preLaser.start();
                laser.turnOn();
            }
            else if(zigZag.active && zigZag.x != 0) {
                // Checking that zigZag.x != 0 is a workaround for a bug
                // where LinearMotion instances return (0, 0) after starting
                // until a frame has passed
                moveTo(zigZag.x, zigZag.y);
                laser.moveTo(centerX - laser.width / 2, bottom - 40);
            }
        }
        else if(currentPhase == "enrage") {
            sprite.play("shoot");
            if(
                !preEnrage.active
                && !enrageRippleInterval.active
                && !enrageSpoutInterval.active
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

    private function spiralShot() {
        if(!sfx["flurry"].playing) {
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

    private function spoutShot(isBig:Bool = true) {
        if(isBig) {
            sfx['bigshot${HXP.choose(1, 2, 3)}'].play();
        }
        var shotAngle = getAngleTowardsPlayer();
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        scene.add(new Spit(this, shotVector, SPOUT_SHOT_SPEED, isBig));
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

    override function die() {
        GameScene.addGlobalFlag("superwizardDefeated");
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
            gameScene.converse("superwizarddeath");
        });
        addTween(deathConversationDelay, true);
    }
}
