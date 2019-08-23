package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Sword extends Entity {
    public static inline var SWING_TIME = 0.5;

    public var swingTimer(default, null):Alarm;
    private var player:Player;
    private var sprite:Spritemap;

    public function new(player:Player) {
        super();
        this.player = player;
        type = "sword";
        sprite = new Spritemap("graphics/sword.png", 16, 16);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        mask = new Hitbox(16, 16);
        collidable = true;
        sprite.alpha = 0;
        swingTimer = new Alarm(SWING_TIME);
        addTween(swingTimer);
    }

    public function swing() {
        swingTimer.start();
        collidable = true;
    }

    override public function update() {
        if(swingTimer.active) {
            sprite.alpha = 1 - swingTimer.percent;
        }
        else {
            sprite.alpha = 0;
            collidable = false;
        }

        if(player.facing == "up") {
            moveTo(player.x, player.y - height);
        }
        else if(player.facing == "down") {
            moveTo(player.x, player.y + height);
        }
        else if(player.facing == "left") {
            moveTo(player.x - width, player.y);
        }
        else if(player.facing == "right") {
            moveTo(player.x + width, player.y);
        }

        var enemies = new Array<Entity>();
        collideInto("enemy", x, y, enemies);
        if(enemies.length > 0) {
            for(enemy in enemies) {
                cast(enemy, Enemy).takeHit(this);
            }
            collidable = false;
        }
        super.update();
    }
}
