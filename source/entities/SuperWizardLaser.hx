package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class SuperWizardLaser extends Entity {
    public static inline var WARM_UP_TIME = 1;
    public static inline var TURN_OFF_TIME = 0.6;

    private var wizard:SuperWizard;
    private var sprite:Spritemap;
    private var warmUpTimer:Alarm;
    private var turnOffTimer:Alarm;

    public function new(wizard:SuperWizard) {
        super();
        this.wizard = wizard;
        type = "hazard";
        layer = -9;
        sprite = new Spritemap("graphics/superwizardlaser.png", 30, 300);
        sprite.add("on", [0, 3], 4);
        sprite.add("warmingup", [1, 2], 4);
        sprite.add("off", [4]);
        sprite.play("off");
        graphic = sprite;
        mask = new Hitbox(30, 200);
        collidable = false;
        warmUpTimer = new Alarm(WARM_UP_TIME);
        warmUpTimer.onComplete.bind(function() {
            sprite.play("on");
            collidable = true;
        });
        addTween(warmUpTimer);
        turnOffTimer = new Alarm(TURN_OFF_TIME);
        turnOffTimer.onComplete.bind(function() {
            sprite.play("off");
        });
        addTween(turnOffTimer);
    }

    public function turnOn() {
        sprite.play("warmingup");
        warmUpTimer.start(); 
    }

    public function turnOff() {
        collidable = false;
        sprite.play("warmingup");
        turnOffTimer.start();
    }

    override public function update() {
        moveTo(wizard.centerX - width / 2, wizard.bottom - 40);
        super.update();
    }
}
