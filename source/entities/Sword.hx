package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Sword extends Entity {
    private var player:Player;
    private var sprite:Spritemap;

    public function new(player:Player) {
        super();
        layer = -99;
        this.player = player;
        type = "sword";
        sprite = new Spritemap("graphics/sword.png", 16, 16);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        visible = false;
        mask = new Hitbox(16, 16);
    }

    override public function update() {
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
        super.update();
    }

    public function getConversationPartner():Butler {
        var npc = collide("npc", x, y);
        if(npc == null) {
            return null;
        }
        return cast(npc, Butler);
    }

    public function getInteractable():Interactable {
        var interactable = collide("interactable", x, y);
        if(interactable == null) {
            return null;
        }
        return cast(interactable, Interactable);
    }

    public function getPiano():Entity {
        var piano = collide("piano", x, y);
        if(piano == null) {
            return null;
        }
        return piano;
    }
}
