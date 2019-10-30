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
    private var isOn:Bool;
    private var sfx:Map<String, Sfx>;

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
            isOn = true;
        });
        addTween(warmUpTimer);
        turnOffTimer = new Alarm(TURN_OFF_TIME);
        turnOffTimer.onComplete.bind(function() {
            sprite.play("off");
        });
        addTween(turnOffTimer);
        sfx = [
            "laser" => new Sfx("audio/laser.wav"),
            "laserwarmup" => new Sfx("audio/laserwarmup.wav"),
            "lasercooldown" => new Sfx("audio/lasercooldown.wav")
        ];
        isOn = false;
    }

    public function stopSfx() {
        sfx["laser"].stop();
    }

    public function turnOn() {
        sprite.play("warmingup");
        if(!cast(scene, GameScene).isDying) {
            sfx["laserwarmup"].play();
        }
        warmUpTimer.start(); 
    }

    public function turnOff() {
        if(!cast(scene, GameScene).isDying) {
            sfx["lasercooldown"].play();
        }
        sfx["laser"].stop();
        collidable = false;
        sprite.play("warmingup");
        turnOffTimer.start();
        isOn = false;
    }

    override public function update() {
        if(
            isOn
            && !sfx["laser"].playing
            && !cast(scene, GameScene).isDying
            && !wizard.stopActing
        ) {
            sfx["laser"].loop();
        }
        moveTo(wizard.centerX - width / 2, wizard.bottom - 40);
        super.update();
    }
}
