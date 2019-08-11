package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class Player extends Entity
{
    public static inline var SPEED = 100;
    public static inline var ROLL_SPEED = 350;
    public static inline var ROLL_TIME = 0.25;
    public static inline var STUN_TIME = 0.3;

    private var velocity:Vector2;
    private var isRolling:Bool;
    private var isStunned:Bool;
    private var rollCooldown:Alarm;
    private var stunCooldown:Alarm;
    private var sprite:Spritemap;
    private var sfx:Map<String, Sfx>;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        Key.define("up", [Key.UP, Key.I]);
        Key.define("down", [Key.DOWN, Key.K]);
        Key.define("left", [Key.LEFT, Key.J]);
        Key.define("right", [Key.RIGHT, Key.L]);
        Key.define("roll", [Key.Z]);
        sprite = new Spritemap("graphics/player.png", 16, 16);
        sprite.add("idle", [0]);
        sprite.add("roll", [1]);
        sprite.add("stun", [2]);
        graphic = sprite;
        velocity = new Vector2();
        mask = new Hitbox(16, 16);
        isRolling = false;
        rollCooldown = new Alarm(ROLL_TIME, TweenType.Persist);
        rollCooldown.onComplete.bind(function() {
            isRolling = false;
        });
        addTween(rollCooldown);
        stunCooldown = new Alarm(STUN_TIME, TweenType.Persist);
        stunCooldown.onComplete.bind(function() {
            isStunned = false;
        });
        addTween(stunCooldown);
        sfx = [
            "stun1" => new Sfx("audio/stun1.wav"),
            "stun2" => new Sfx("audio/stun2.wav"),
            "stun3" => new Sfx("audio/stun3.wav"),
            "roll1" => new Sfx("audio/roll1.wav"),
            "roll2" => new Sfx("audio/roll2.wav"),
            "roll3" => new Sfx("audio/roll3.wav")
        ];
    }

    override public function update() {
        movement();
        animation();
        super.update();
    }

    private function movement() {
        if(Input.pressed("roll") && !isRolling && !isStunned) {
            isRolling = true;
            sfx['roll${HXP.choose(1, 2, 3)}'].play();
            rollCooldown.start();
        }
        if(isStunned) {
            // Do nothing
        }
        else if(isRolling) {
            velocity.normalize(ROLL_SPEED);
        }
        else {
            if(Input.check("left")) {
                velocity.x = -1;
            }
            else if(Input.check("right")) {
                velocity.x = 1;
            }
            else {
                velocity.x = 0;
            }
            if(Input.check("up")) {
                velocity.y = -1;
            }
            else if(Input.check("down")) {
                velocity.y = 1;
            }
            else {
                velocity.y = 0;
            }
            velocity.normalize(SPEED);
        }
        moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, "walls");
    }

    override public function moveCollideX(e:Entity) {
        if(isRolling) {
            stun();
        }
        return true;
    }

    override public function moveCollideY(e:Entity) {
        if(isRolling) {
            stun();
        }
        return true;
    }

    private function stun() {
        isRolling = false;
        isStunned = true;
        velocity = new Vector2();
        sfx['stun${HXP.choose(1, 2, 3)}'].play();
        stunCooldown.start();
    }

    private function animation() {
        if(isStunned) {
            sprite.play("stun");
        }
        else if(isRolling) {
            sprite.play("roll");
        }
        else {
            sprite.play("idle");
        }
    }
}
