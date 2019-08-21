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
    //public static inline var RIPPLE_SHOT_INTERVAL = 1.75;
    public static inline var RIPPLE_SHOT_INTERVAL = 2.7;
    public static inline var RIPPLE_BULLETS_PER_SHOT = 100;

    public static inline var SPOUT_SHOT_SPEED = 150;
    //public static inline var SPOUT_SHOT_INTERVAL = 0.05;
    public static inline var SPOUT_SHOT_INTERVAL = 1.5;

    public static inline var ZIG_ZAG_COUNT = 5;
    public static inline var ZIG_ZAG_TIME = 3;
    //public static inline var ZIG_ZAG_SPEED = 3;
    public static inline var ZIG_ZAG_SHOT_INTERVAL = 0.75;
    //public static inline var ZIG_ZAG_SHOT_INTERVAL = 0.5;
    public static inline var ZIG_ZAG_SHOT_SPEED = 100;
    //public static inline var ZIG_ZAG_SHOT_SPEED = 150;

    private var sprite:Spritemap;
    private var spiralShotInterval:Alarm;

    private var rippleShotInterval:Alarm;

    private var spoutShotInterval:Alarm;

    private var zigZag:LinearPath;
    private var zigZagShotInterval:Alarm;

    private var phaseRelocater:LinearMotion;
    private var phaseLocations:Map<String, Vector2>;
    private var phase:String;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        y -= 95;
        mask = new Hitbox(SIZE, SIZE);
        centerOnTile();
        sprite = new Spritemap("graphics/superwizard.png", SIZE, SIZE);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        health = 100;

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
        zigZagShotInterval = new Alarm(
            ZIG_ZAG_SHOT_INTERVAL, TweenType.Looping
        );
        zigZagShotInterval.onComplete.bind(function() {
            zigZagShot();
        });
        addTween(zigZagShotInterval);

        phaseLocations = [
            "spiral" => new Vector2(x, y),
            "rippleAndSpout" => new Vector2(x - 95, y - 95),
            "zigZag" => new Vector2(x, y - 95)
        ];

        phaseRelocater = new LinearMotion();
        addTween(phaseRelocater);
        phase = "rippleAndSpout";

        zigZag = new LinearPath(TweenType.Looping);
        zigZag.addPoint(x, y);
        for(i in 0...ZIG_ZAG_COUNT) {
            zigZag.addPoint(x - 95, y);
            zigZag.addPoint(x + 95, y);
        }
        zigZag.addPoint(x, y);
        addTween(zigZag);
    }

    override private function act() {
        //if(!spiralShotInterval.active) {
            //spiralShotInterval.start();
        //}
        //if(!phaseRelocater.active) {
            //phaseRelocater.start();
        //}
        //else {
        //}
        //if(!atPhaseLocation()) {
            //if(!phaseRelocater.active) {
                //phaseRelocater.setMotion(
                    //x, y,
                    //phaseLocations[phase].x, phaseLocations[phase].y,
                    //2,
                    //Ease.sineInOut
                //);
                //phaseRelocater.start();
            //}
            //moveTo(phaseRelocater.x, phaseRelocater.y);
        //}
        //else {
            //if(!rippleShotInterval.active) {
                //rippleShotInterval.start();
            //}
            //if(!spoutShotInterval.active) {
                //spoutShotInterval.start();
            //}
        //}
        if(!zigZag.active) {
            zigZag.setMotion(ZIG_ZAG_COUNT * ZIG_ZAG_TIME, Ease.sineInOut);
            zigZag.start();
            zigZagShotInterval.start();
            zigZagShot();
        }
        else {
            moveTo(zigZag.x, zigZag.y);
        }
        trace('at ${x}, ${y}, zigZag is ${zigZag.x}, ${zigZag.y}');
    }

    private function atPhaseLocation() {
        return x == phaseLocations[phase].x && y == phaseLocations[phase].y;
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

    private function spoutShot() {
        var shotAngle = getAngleTowardsPlayer();
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        scene.add(new Spit(this, shotVector, SPOUT_SHOT_SPEED, true));
    }

    private function rippleShot() {
        var spreadAngles = getSpreadAngles(
            RIPPLE_BULLETS_PER_SHOT, Math.PI * 2 / 1.25
        );
        for(i in 0...RIPPLE_BULLETS_PER_SHOT) {
            var shotAngle = spreadAngles[i] + Math.PI / 2;
            var shotVector = new Vector2(
                Math.cos(shotAngle), Math.sin(shotAngle)
            );
            scene.add(new Spit(this, shotVector, RIPPLE_SHOT_SPEED));
        }
    }

    private function zigZagShot() {
        var shotAngle = getAngleTowardsPlayer();
        var shotVector = new Vector2(
            Math.cos(shotAngle), Math.sin(shotAngle)
        );
        shotVector.x += (Math.random() - 0.5) / 1.5;
        scene.add(new Spit(this, shotVector, ZIG_ZAG_SHOT_SPEED, true));
    }
}
