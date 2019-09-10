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
    public static inline var CAST_COOLDOWN = 0.2;
    //public static inline var CAST_COOLDOWN = 0.4;
    public static inline var HEAL_TIME = 2.5;

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

    public static inline var PITFALL_RESET_TIME = 1;
    public static inline var STARTING_NUMBER_OF_FLASKS = 3;

    public var stamina(default, null):Float;
    public var health(default, null):Int;
    public var facing(default, null):String;
    public var flaskCount(default, null):Int;
    private var velocity:Vector2;
    private var rollCooldown:Alarm;
    private var stunCooldown:Alarm;
    private var castCooldown:Alarm;
    private var sprite:Spritemap;
    private var shadow:Image;
    private var sfx:Map<String, Sfx>;
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
    private var healTimer:Alarm;
    private var healSigil:Spritemap;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        layer = -10;
        type = "player";
        name = "player";
        boundingBox = new Hitbox(16, 16);
        mask = boundingBox;
        sprite = new Spritemap("graphics/player.png", 16, 16);
        var runAnimationSpeed = 6;
        var rollAnimationSpeed = 8;
        sprite.add("cast_down", [0]);
        sprite.add("roll_down", [1, 2], rollAnimationSpeed, false);
        sprite.add("idle_down", [3]);
        sprite.add("walk_down", [4, 3, 5, 3], runAnimationSpeed);
        sprite.add("cast_up", [6]);
        sprite.add("roll_up", [7, 8], rollAnimationSpeed, false);
        sprite.add("idle_up", [9]);
        sprite.add("walk_up", [10, 9, 11, 9], runAnimationSpeed);
        sprite.add("cast_right", [12]);
        sprite.add("roll_right", [13, 14], rollAnimationSpeed, false);
        sprite.add("idle_right", [15]);
        sprite.add("walk_right", [16, 15, 17, 15], runAnimationSpeed);
        sprite.add("stun", [18]);
        sprite.add("fall", [18, 19, 20, 22], 8, false);
        sprite.add("dead", [21]);
        shadow = new Spritemap("graphics/shadow.png", 16, 16);

        healSigil = new Spritemap("graphics/spells.png", 20, 20);
        healSigil.add("idle", [11, 7, 8, 9, 10], 5 / HEAL_TIME, false);
        healSigil.x = -2;
        healSigil.y = -2;

        addGraphic(healSigil);
        addGraphic(shadow);
        addGraphic(sprite);
        velocity = new Vector2();

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
        flaskCount = STARTING_NUMBER_OF_FLASKS;
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
        healTimer = new Alarm(HEAL_TIME);
        healTimer.onComplete.bind(function() {
            health += 1;
            flaskCount -= 1;
        });
        addTween(healTimer);
    }

    public function cancelRoll() {
        rollCooldown.active = false;
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
        var gameScene = cast(scene, GameScene);
        if(
            Main.inputPressed("cast")
            && (canControl() || castCooldown.percent > 0.5)
            && !gameScene.isDialogMode
        ) {
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

        if(canControl() && velocity.length == 0) {
            if(!healTimer.active && health < MAX_HEALTH && flaskCount > 0) {
                healTimer.start();
                healSigil.play("idle", true);
            }
        }
        else {
            healTimer.active = false;
        }

        healSigil.visible = healTimer.active;
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
            && !cast(scene, GameScene).isDialogMode
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
        else if(cast(scene, GameScene).isDialogMode) {
            velocity.x = 0;
            velocity.y = 0;
        }
        else if(knockbackTimer.active || isFalling) {
            // Do nothing
        }
        else if(
            Main.inputPressed("roll")
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
            if(Main.inputCheck("left")) {
                velocity.x = -1;
            }
            else if(Main.inputCheck("right")) {
                velocity.x = 1;
            }
            else if(facing == "left") {
                velocity.x = -1;
            }
            else if(facing == "right") {
                velocity.x = 1;
            }
            if(Main.inputCheck("up")) {
                velocity.y = -1;
            }
            else if(Main.inputCheck("down")) {
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
            if(Main.inputCheck("left")) {
                facing = "left";
            }
            else if(Main.inputCheck("right")) {
                facing = "right";
            }
            if(Main.inputCheck("up")) {
                facing = "up";
            }
            else if(Main.inputCheck("down")) {
                facing = "down";
            }
        }
        else if(!canControl()) {
            if(Main.inputCheck("left")) {
                facing = "left";
            }
            else if(Main.inputCheck("right")) {
                facing = "right";
            }
            if(Main.inputCheck("up")) {
                facing = "up";
            }
            else if(Main.inputCheck("down")) {
                facing = "down";
            }
        }
        else {
            if(Main.inputCheck("left")) {
                velocity.x = -1;
                facing = "left";
            }
            else if(Main.inputCheck("right")) {
                velocity.x = 1;
                facing = "right";
            }
            else {
                velocity.x = 0;
            }
            if(Main.inputCheck("up")) {
                velocity.y = -1;
                facing = "up";
            }
            else if(Main.inputCheck("down")) {
                velocity.y = 1;
                facing = "down";
            }
            else {
                velocity.y = 0;
            }
            var speed = SPEED;
            if(!Main.inputCheck("roll") || stamina <= 0) {
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
            var currentLevel = cast(scene, GameScene).currentLevel;
            var resetTimer = new Alarm(PITFALL_RESET_TIME);
            resetTimer.onComplete.bind(function() {
                x = lastSafeSpot.x;
                y = lastSafeSpot.y;
                var cameraDestinationX = MathUtil.clamp(
                    centerX - GameScene.PLAYFIELD_SIZE / 2,
                    currentLevel.x,
                    currentLevel.x + currentLevel.width
                    - GameScene.PLAYFIELD_SIZE
                );
                var cameraDestinationY = MathUtil.clamp(
                    centerY - GameScene.PLAYFIELD_SIZE / 2,
                    currentLevel.y,
                    currentLevel.y + currentLevel.height
                    - GameScene.PLAYFIELD_SIZE
                );
                cast(scene, GameScene).panCamera(
                    cameraDestinationX, cameraDestinationY, PITFALL_RESET_TIME
                );
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
            var resetTimer = new Alarm(PITFALL_RESET_TIME);
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
        sprite.y = rollCooldown.active ? -5 : 0;
        shadow.visible = rollCooldown.active;
        if(!stunCooldown.active) {
            sprite.flipX = facing == "left";
        }
        if(cast(scene, GameScene).isDialogMode) {
            if(facing == "left") {
                sprite.play("idle_right");
            }
            else {
                sprite.play('idle_${facing}');
            }
        }
        else if(isFalling) {
            // Do nothing
        }
        else if(isDead) {
            sprite.play("dead");
        }
        else if(castCooldown.active) {
            if(facing == "left") {
                sprite.play("cast_right");
            }
            else {
                sprite.play('cast_${facing}');
            }
        }
        else if(stunCooldown.active) {
            sprite.play("stun");
        }
        else if(rollCooldown.active) {
            if(facing == "left") {
                sprite.play("roll_right");
            }
            else {
                sprite.play('roll_${facing}');
            }
        }
        else if(velocity.length > 0) {
            if(facing == "left") {
                sprite.play("walk_right");
            }
            else {
                sprite.play('walk_${facing}');
            }
        }
        else {
            if(facing == "left") {
                sprite.play("idle_right");
            }
            else {
                sprite.play('idle_${facing}');
            }
        }
    }
}
