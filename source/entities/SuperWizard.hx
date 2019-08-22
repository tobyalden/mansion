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

    public static inline var SPIRAL_SHOT_SPEED = 50;
    public static inline var SPIRAL_TURN_RATE = 4;
    public static inline var SPIRAL_BULLETS_PER_SHOT = 2;
    public static inline var SPIRAL_SHOT_INTERVAL = 0.05;

    public static inline var RIPPLE_SHOT_SPEED = 100;
    public static inline var RIPPLE_SHOT_SPREAD = 15;
    public static inline var RIPPLE_SHOT_INTERVAL = 2.7;
    public static inline var RIPPLE_BULLETS_PER_SHOT = 200;

    public static inline var SPOUT_SHOT_SPEED = 150;
    public static inline var SPOUT_SHOT_INTERVAL = 1.5;

    public static inline var ZIG_ZAG_COUNT = 3;
    public static inline var ZIG_ZAG_TIME = 2.5;
    //public static inline var ZIG_ZAG_SPEED = 3;
    public static inline var ZIG_ZAG_SHOT_INTERVAL = 0.75;
    //public static inline var ZIG_ZAG_SHOT_INTERVAL = 0.5;
    public static inline var ZIG_ZAG_SHOT_SPEED = 100;
    //public static inline var ZIG_ZAG_SHOT_SPEED = 150;

    public static inline var PRE_ENRAGE_TIME = 2;
    public static inline var ENRAGE_RIPPLE_INTERVAL = 1.75;
    public static inline var ENRAGE_SPOUT_INTERVAL = 0.05;
    public static inline var ENRAGE_PHASE_DURATION = 10;

    public static inline var PHASE_TRANSITION_TIME = 2;
    public static inline var PHASE_DURATION = 15;

    //public static inline var STARTING_HEALTH = 100;
    public static inline var STARTING_HEALTH = 10;

    public var laser(default, null):SuperWizardLaser;

    private var sprite:Spritemap;

    private var spiralShotInterval:Alarm;

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

    private var screenCenter:Vector2;
    private var isEnraged:Bool;
    private var enrageNextPhase:Bool;

    private var sfx:Map<String, Sfx>;

    // TODO: Destroy all bullets on death

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        name = "superwizard";
        mask = new Hitbox(SIZE, SIZE);
        x -= width / 2;
        y -= height / 2;
        screenCenter = new Vector2(x, y);
        y -= 50;
        sprite = new Spritemap("graphics/superwizard.png", SIZE, SIZE);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        health = STARTING_HEALTH;

        laser = new SuperWizardLaser(this);

        spiralShotInterval = new Alarm(
            SPIRAL_SHOT_INTERVAL, TweenType.Looping
        );
        spiralShotInterval.onComplete.bind(function() {
            spiralShot();
        });
        addTween(spiralShotInterval);

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

        generatePhaseLocations();

        phaseRelocater = new LinearMotion();
        addTween(phaseRelocater);

        preLaser = new Alarm(SuperWizardLaser.WARM_UP_TIME);
        preLaser.onComplete.bind(function() {
            preZigZag.start();
        });
        addTween(preLaser);

        preZigZag = new Alarm(SuperWizardLaser.WARM_UP_TIME);
        preZigZag.onComplete.bind(function() {
            zigZag.setMotion(ZIG_ZAG_COUNT * ZIG_ZAG_TIME, Ease.sineInOut);
            zigZag.start();
        });
        addTween(preZigZag);

        postZigZag = new Alarm(SuperWizardLaser.TURN_OFF_TIME * 2);
        postZigZag.onComplete.bind(function() {
            advancePhase();
        });
        addTween(postZigZag);

        preEnrage = new Alarm(PRE_ENRAGE_TIME);
        preEnrage.onComplete.bind(function() {
            enrageRippleInterval.start();
            enrageSpoutInterval.start();
            // TODO: This makes all the phases after this shorter.
            // Is that desired?
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
            advancePhase();
        });
        addTween(phaseTimer);

        isEnraged = false;
        enrageNextPhase = false;

        sfx = [
            "enrage" => new Sfx("audio/enrage.wav")
        ];
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

        zigZag = new LinearPath(TweenType.Persist);
        zigZag.onComplete.bind(function() {
            laser.turnOff();
            postZigZag.start();
        });
        zigZag.addPoint(screenCenter.x, screenCenter.y - 95);
        if(Math.random() > 0.5) {
            for(i in 0...ZIG_ZAG_COUNT) {
                zigZag.addPoint(screenCenter.x - 120, screenCenter.y - 95);
                zigZag.addPoint(screenCenter.x + 120, screenCenter.y - 95);
            }
        }
        else {
            for(i in 0...ZIG_ZAG_COUNT) {
                zigZag.addPoint(screenCenter.x + 120, screenCenter.y - 95);
                zigZag.addPoint(screenCenter.x - 120, screenCenter.y - 95);
            }
        }
        zigZag.addPoint(screenCenter.x, screenCenter.y - 95);
        addTween(zigZag);
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
        betweenPhases = true;
        for(tween in tweens) {
            tween.active = false;
        }
    }

    override private function act() {
        if(health <= STARTING_HEALTH / 4) {
            if(!isEnraged) {
                enrageNextPhase = true;
            }
        }
        if(betweenPhases) {
            if(atPhaseLocation()) {
                betweenPhases = false;
            }
            else {
                if(!phaseRelocater.active) {
                    phaseRelocater.setMotion(
                        x, y,
                        phaseLocations[currentPhase].x,
                        phaseLocations[currentPhase].y,
                        PHASE_TRANSITION_TIME,
                        Ease.sineInOut
                    );
                    phaseRelocater.start();
                }
                moveTo(phaseRelocater.x, phaseRelocater.y);
            }
        }
        else if(currentPhase == "spiral") {
            if(!spiralShotInterval.active) {
                spiralShotInterval.start();
                phaseTimer.start();
            }
        }
        else if(currentPhase == "rippleAndSpout") {
            if(!rippleShotInterval.active) {
                rippleShotInterval.start();
                spoutShotInterval.start();
                phaseTimer.start();
                rippleShot();
            }
        }
        else if(currentPhase == "zigZag") {
            if(
                !preLaser.active && !preZigZag.active
                && !zigZag.active && !postZigZag.active
            ) {
                preLaser.start();
                laser.turnOn();
            }
            else if(zigZag.active && zigZag.x != 0) {
                moveTo(zigZag.x, zigZag.y);
            }
        }
        else if(currentPhase == "enrage") {
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
        for(i in 0...SPIRAL_BULLETS_PER_SHOT) {
            var spreadAngles = getSpreadAngles(
                SPIRAL_BULLETS_PER_SHOT + 1, Math.PI * 2
            );
            var shotAngle = (
                Math.cos(age / 3) * SPIRAL_TURN_RATE + spreadAngles[i]
            );
            var shotVector = new Vector2(
                Math.cos(shotAngle), Math.sin(shotAngle)
            );
            scene.add(new Spit(this, shotVector, SPIRAL_SHOT_SPEED));
        }
    }

    private function spoutShot(isBig:Bool = true) {
        var shotAngle = getAngleTowardsPlayer();
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        scene.add(new Spit(this, shotVector, SPOUT_SHOT_SPEED, isBig));
    }

    private function rippleShot() {
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
}
