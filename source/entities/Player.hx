package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import entities.Level;
import scenes.*;

class Player extends Entity
{
    public static inline var SPEED = 100;
    public static inline var RUN_SPEED = 170;
    public static inline var ROLL_SPEED = 350;
    public static inline var ROLL_TIME = 0.25;
    public static inline var STUN_TIME = 0.3;
    public static inline var CAST_COOLDOWN = 0.4;

    public static inline var MAX_STAMINA = 100;
    public static inline var STAMINA_RECOVERY_SPEED_MOVING = 25;
    public static inline var STAMINA_RECOVERY_SPEED_STILL = 50;
    public static inline var ROLL_COST = 40;
    public static inline var CAST_COST = 40;
    public static inline var RUN_COST = 20;
    public static inline var STAMINA_RECOVERY_DELAY = 0.5;

    public var stamina(default, null):Float;
    private var velocity:Vector2;
    private var rollCooldown:Alarm;
    private var stunCooldown:Alarm;
    private var castCooldown:Alarm;
    private var sprite:Spritemap;
    private var sfx:Map<String, Sfx>;
    private var facing:String;
    private var isRunning:Bool;
    private var staminaRecoveryDelay:Alarm;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        name = "player";
        Key.define("up", [Key.UP, Key.I]);
        Key.define("down", [Key.DOWN, Key.K]);
        Key.define("left", [Key.LEFT, Key.J]);
        Key.define("right", [Key.RIGHT, Key.L]);
        Key.define("roll", [Key.Z]);
        Key.define("cast", [Key.X]);
        sprite = new Spritemap("graphics/player.png", 16, 16);
        sprite.add("idle", [0]);
        sprite.add("roll", [1]);
        sprite.add("stun", [2]);
        sprite.add("cast", [3]);
        sprite.add("run", [4]);
        graphic = sprite;
        velocity = new Vector2();
        mask = new Hitbox(16, 16);
        rollCooldown = new Alarm(ROLL_TIME, TweenType.Persist);
        addTween(rollCooldown);
        stunCooldown = new Alarm(STUN_TIME, TweenType.Persist);
        addTween(stunCooldown);
        castCooldown = new Alarm(CAST_COOLDOWN, TweenType.Persist);
        addTween(castCooldown);
        sfx = [
            "stun1" => new Sfx("audio/stun1.wav"),
            "stun2" => new Sfx("audio/stun2.wav"),
            "stun3" => new Sfx("audio/stun3.wav"),
            "roll1" => new Sfx("audio/roll1.wav"),
            "roll2" => new Sfx("audio/roll2.wav"),
            "roll3" => new Sfx("audio/roll3.wav"),
            "cast1" => new Sfx("audio/cast1.wav"),
            "cast2" => new Sfx("audio/cast2.wav"),
            "cast3" => new Sfx("audio/cast3.wav"),
            "cast4" => new Sfx("audio/cast4.wav")
        ];
        facing = "up";
        isRunning = false;
        stamina = MAX_STAMINA;
        staminaRecoveryDelay = new Alarm(
            STAMINA_RECOVERY_DELAY, TweenType.Persist
        );
        addTween(staminaRecoveryDelay);
    }

    public function getScreenCoordinates() {
        var screenCoordinates:IntPair = {
            x: Math.floor(centerX / GameScene.PLAYFIELD_SIZE),
            y: Math.floor(centerY / GameScene.PLAYFIELD_SIZE)
        };
        return screenCoordinates;
    }

    override public function update() {
        if(Input.check("cast") && canControl() && stamina >= CAST_COST) {
            stamina -= CAST_COST;
            staminaRecoveryDelay.start();
            castSpell();
        }
        movement();
        animation();
        var staminaRecoverySpeed = (
            velocity.length == 0 ?
            STAMINA_RECOVERY_SPEED_STILL : STAMINA_RECOVERY_SPEED_MOVING
        );
        if(!isRunning && !staminaRecoveryDelay.active) {
            stamina = Math.min(
                stamina + staminaRecoverySpeed * HXP.elapsed,
                MAX_STAMINA
            );
        }
        super.update();
    }

    private function canControl() {
        return (
            !rollCooldown.active
            && !stunCooldown.active
            && !castCooldown.active
        );
    }

    private function movement() {
        if(
            Input.pressed("roll")
            && stamina >= ROLL_COST
            && (canControl() || castCooldown.active)
        ) {
            isRunning = true;
            stamina -= ROLL_COST;
            staminaRecoveryDelay.start();
            rollCooldown.active = true;
            sfx['roll${HXP.choose(1, 2, 3)}'].play();
            rollCooldown.start();
            castCooldown.active = false;
            if(Input.check("left")) {
                velocity.x = -1;
            }
            else if(Input.check("right")) {
                velocity.x = 1;
            }
            else if(facing == "left") {
                velocity.x = -1;
            }
            else if(facing == "right") {
                velocity.x = 1;
            }
            if(Input.check("up")) {
                velocity.y = -1;
            }
            else if(Input.check("down")) {
                velocity.y = 1;
            }
            else if(facing == "up") {
                velocity.y = -1;
            }
            else if(facing == "down") {
                velocity.y = 1;
            }
        }
        if(rollCooldown.active) {
            velocity.normalize(ROLL_SPEED);
        }
        else if(!canControl()) {
            if(Input.check("left")) {
                facing = "left";
            }
            else if(Input.check("right")) {
                facing = "right";
            }
            if(Input.check("up")) {
                facing = "up";
            }
            else if(Input.check("down")) {
                facing = "down";
            }
        }
        else {
            if(Input.check("left")) {
                velocity.x = -1;
                facing = "left";
            }
            else if(Input.check("right")) {
                velocity.x = 1;
                facing = "right";
            }
            else {
                velocity.x = 0;
            }
            if(Input.check("up")) {
                velocity.y = -1;
                facing = "up";
            }
            else if(Input.check("down")) {
                velocity.y = 1;
                facing = "down";
            }
            else {
                velocity.y = 0;
            }
            var speed = SPEED;
            if(!Input.check("roll") || stamina <= 0) {
                isRunning = false;
            }
            if(isRunning) {
                speed = RUN_SPEED;
                stamina = Math.max(0, stamina - RUN_COST * HXP.elapsed);
            }
            velocity.normalize(speed);
        }
        moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, "walls");
    }

    private function castSpell() {
        velocity = new Vector2();
        var spellVelocity;
        if(facing == "up") {
            spellVelocity = new Vector2(0, -1);
        }
        else if(facing == "down") {
            spellVelocity = new Vector2(0, 1);
        }
        else if(facing == "left") {
            spellVelocity = new Vector2(-1, 0);
        }
        else {
            // facing == "right"
            spellVelocity = new Vector2(1, 0);
        }
        scene.add(new Spell(centerX, centerY, spellVelocity));
        castCooldown.start();
        sfx['cast${HXP.choose(1, 2, 3, 4)}'].play();
    }

    override public function moveCollideX(e:Entity) {
        if(rollCooldown.active) {
            stun();
            sfx['stun${HXP.choose(1, 2, 3)}'].play();
        }
        return true;
    }

    override public function moveCollideY(e:Entity) {
        if(rollCooldown.active) {
            stun();
            sfx['stun${HXP.choose(1, 2, 3)}'].play();
        }
        return true;
    }

    private function stun() {
        velocity = new Vector2();
        stunCooldown.start();
    }

    private function animation() {
        if(castCooldown.active) {
            sprite.play("cast");
        }
        else if(stunCooldown.active) {
            sprite.play("stun");
        }
        else if(rollCooldown.active) {
            sprite.play("roll");
        }
        else if(isRunning) {
            sprite.play("run");
        }
        else {
            sprite.play("idle");
        }
    }
}
