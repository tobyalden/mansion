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
    // Should ALL monsters pause on room enter?
    public static inline var SPEED = 100;
    //public static inline var RUN_SPEED = 150;
    public static inline var RUN_SPEED = 100;
    public static inline var ROLL_SPEED = 350;
    public static inline var ROLL_TIME = 0.25;
    public static inline var STUN_TIME = 0.3;
    public static inline var CAST_COOLDOWN = 0.4;

    public static inline var MAX_STAMINA = 125;
    public static inline var STAMINA_RECOVERY_SPEED_MOVING = 25;
    public static inline var STAMINA_RECOVERY_SPEED_STILL = 50;
    //public static inline var ROLL_COST = 60;
    //public static inline var CAST_COST = 30;
    //public static inline var RUN_COST = 10;
    public static inline var ROLL_COST = 0;
    public static inline var CAST_COST = 0;
    public static inline var RUN_COST = 0;
    public static inline var STAMINA_RECOVERY_DELAY = 0.5;

    public static inline var KNOCKBACK_TIME = 0.25;
    public static inline var INVINCIBLE_TIME = 1.5;
    public static inline var KNOCKBACK_SPEED = 200;

    public static inline var MAX_HEALTH = 3;
    public static inline var DEATH_DECCEL = 0.95;

    public var stamina(default, null):Float;
    public var health(default, null):Int;
    private var velocity:Vector2;
    private var rollCooldown:Alarm;
    private var stunCooldown:Alarm;
    private var castCooldown:Alarm;
    private var sprite:Spritemap;
    private var sfx:Map<String, Sfx>;
    private var facing:String;
    private var isRunning:Bool;
    private var staminaRecoveryDelay:Alarm;

    private var knockbackTimer:Alarm;
    private var invincibleTimer:Alarm;

    private var isFlashing:Bool;
    private var flasher:Alarm;
    private var stopFlasher:Alarm;

    private var isDead:Bool;
    private var isFalling:Bool;
    private var boundingBox:Hitbox;
    private var lastSafeSpot:Vector2;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        type = "player";
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
        sprite.add("dead", [5]);
        sprite.add("fall", [6, 7, 8, 9], 12, false);
        graphic = sprite;
        velocity = new Vector2();
        boundingBox = new Hitbox(16, 16);
        mask = boundingBox;

        rollCooldown = new Alarm(ROLL_TIME, TweenType.Persist);
        addTween(rollCooldown);
        stunCooldown = new Alarm(STUN_TIME, TweenType.Persist);
        addTween(stunCooldown);
        castCooldown = new Alarm(CAST_COOLDOWN, TweenType.Persist);
        addTween(castCooldown);

        knockbackTimer = new Alarm(KNOCKBACK_TIME, TweenType.Persist);
        addTween(knockbackTimer);
        invincibleTimer = new Alarm(INVINCIBLE_TIME, TweenType.Persist);
        addTween(invincibleTimer);

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
            "cast4" => new Sfx("audio/cast4.wav"),
            "playerhit1" => new Sfx("audio/playerhit1.wav"),
            "playerhit2" => new Sfx("audio/playerhit2.wav"),
            "playerhit3" => new Sfx("audio/playerhit3.wav"),
            "fall" => new Sfx("audio/fall.wav")
        ];
        facing = "up";
        isRunning = false;
        stamina = MAX_STAMINA;
        health = MAX_HEALTH;
        staminaRecoveryDelay = new Alarm(
            STAMINA_RECOVERY_DELAY, TweenType.Persist
        );
        addTween(staminaRecoveryDelay);

        isFlashing = false;
        flasher = new Alarm(0.05, TweenType.Looping);
        flasher.onComplete.bind(function() {
            if(isFlashing) {
                sprite.visible = !sprite.visible;
                trace('flashin');
            }
        });
        addTween(flasher, true);

        stopFlasher = new Alarm(INVINCIBLE_TIME, TweenType.Persist);
        stopFlasher.onComplete.bind(function() {
            sprite.visible = true;
            isFlashing = false;
        });
        addTween(stopFlasher, false);

        isDead = false;
        isFalling = false;

        lastSafeSpot = new Vector2(x, y);
    }

    public function setLastSafeSpot(newSafeSpot:Vector2) {
        lastSafeSpot = newSafeSpot;
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
        if(!isRunning && !isFalling && !staminaRecoveryDelay.active) {
            stamina = Math.min(
                stamina + staminaRecoverySpeed * HXP.elapsed,
                MAX_STAMINA
            );
        }
        var collideTypes = (
            rollCooldown.active && !stunCooldown.active ?
            ["enemy", "tail"] : ["enemy", "tail", "hazard"]
        );
        trace(collideTypes);
        var enemy = collideMultiple(collideTypes, x, y);
        if(enemy != null && !invincibleTimer.active && !isDead && !isFalling) {
            if(enemy.collideRect(enemy.x, enemy.y, x + 4, y + 4, 8, 8)) {
                takeHit(enemy);
            }
        }

        var pit = collide("pits", x, y);
        if(pit != null && !isFalling && !rollCooldown.active) {
            if(
                pit.collidePoint(pit.x, pit.y, centerX, centerY)
                && pit.collidePoint(pit.x + 6, pit.y, centerX, centerY)
                && pit.collidePoint(pit.x - 6, pit.y, centerX, centerY)
                && pit.collidePoint(pit.x, pit.y + 6, centerX, centerY)
                && pit.collidePoint(pit.x, pit.y - 6, centerX, centerY)
            ) {
                fallIntoPit();
            }
        }

        super.update();
    }

    public function canBeHitBySpit() {
        return (
            !invincibleTimer.active
            && !isDead
            && !isFalling
            && (!rollCooldown.active || stunCooldown.active)
        );
    }

    public function collideMultiple(
        collideTypes:Array<String>, collideX:Float, collideY:Float
    ) {
        for(collideType in collideTypes) {
            var collideResult = collide(collideType, collideX, collideY);
            if(collideResult != null) {
                return collideResult;
            }
        }
        return null;
    }

    private function canControl() {
        return (
            !rollCooldown.active
            && !stunCooldown.active
            && !castCooldown.active
            && !castCooldown.active
            && !knockbackTimer.active
            && !isDead
            && !isFalling
        );
    }

    private function movement() {
        if(isDead) {
            velocity.scale(Math.pow(
                DEATH_DECCEL, (HXP.elapsed * HXP.assignedFrameRate)
            ));
            if(velocity.length < 100 * HXP.elapsed) {
                velocity.x = 0;
                velocity.y = 0;
            }
        }
        else if(knockbackTimer.active || isFalling) {
            // Do nothing
        }
        else if(
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
        else if(rollCooldown.active) {
            velocity.normalize(ROLL_SPEED);
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
        moveBy(
            velocity.x * HXP.elapsed,
            velocity.y * HXP.elapsed,
            ["walls", "lock"]
        );
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

    private function hitEntity(e:Entity) {
        if(e.type == "walls" && rollCooldown.active) {
            stun();
            sfx['stun${HXP.choose(1, 2, 3)}'].play();
        }
    }

    private function die() {
        isDead = true;
        cast(scene, GameScene).onDeath();
    }

    private function fallIntoPit() {
        isFalling = true;
        velocity = new Vector2();
        sprite.play("fall");
        sfx['fall'].play();
        if(health > 1) {
            var resetTimer = new Alarm(1);
            resetTimer.onComplete.bind(function() {
                x = lastSafeSpot.x;
                y = lastSafeSpot.y;
                knockbackTimer.start();
                invincibleTimer.start();
                stopFlasher.start();
                isFlashing = true;
                isFalling = false;
                health -= 1;
            });
            addTween(resetTimer, true);
        }
        else {
            var resetTimer = new Alarm(1);
            resetTimer.onComplete.bind(function() {
                health -= 1;
                die();
            });
            addTween(resetTimer, true);
        }
    }

    public function takeHit(damageSource:Entity) {
        health -= 1;
        if(health <= 0) {
            die();
        }
        knockbackTimer.start();
        invincibleTimer.start();
        var awayFromDamage = new Vector2(
            centerX - damageSource.centerX, centerY - damageSource.centerY
        );
        awayFromDamage.normalize(KNOCKBACK_SPEED);
        velocity = awayFromDamage;
        sfx['playerhit${HXP.choose(1, 2, 3)}'].play();
        isFlashing = true;
        stopFlasher.start();
    }

    override public function moveCollideX(e:Entity) {
        hitEntity(e);
        return true;
    }

    override public function moveCollideY(e:Entity) {
        hitEntity(e);
        return true;
    }

    private function stun() {
        velocity = new Vector2();
        stunCooldown.start();
    }

    private function animation() {
        if(isFalling) {
            // Do nothing
        }
        else if(isDead) {
            sprite.play("dead");
        }
        else if(castCooldown.active) {
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
