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

    private var wizard:SuperWizard;
    private var sprite:Spritemap;
    private var warmUpTimer:Alarm;

    public function new(wizard:SuperWizard) {
        super();
        this.wizard = wizard;
        type = "hazard";
        sprite = new Spritemap("graphics/superwizardlaser.png", 30, 200);
        sprite.add("on", [0]);
        sprite.add("warmingup", [1]);
        sprite.add("off", [2]);
        sprite.play("off");
        graphic = sprite;
        mask = new Hitbox(30, 200);
        collidable = false;
        warmUpTimer = new Alarm(WARM_UP_TIME);
        warmUpTimer.onComplete.bind(function() {
            sprite.play("on");
            collidable = true;
            trace('im on');
        });
        addTween(warmUpTimer);
    }

    public function turnOn() {
        sprite.play("warmingup");
        warmUpTimer.start(); 
    }

    override public function update() {
        moveTo(wizard.centerX - width / 2, wizard.bottom);
        super.update();
    }
}
