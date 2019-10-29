package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Interactable extends Entity {
    private var dialogpath:String;
    private var sfx:Map<String, Sfx>;

    public function new(
        x:Float, y:Float, width:Int, height:Int, dialogpath:String
    ) {
        super(x, y);
        this.dialogpath = dialogpath;
        type = "interactable";
        mask = new Hitbox(width, height);
        sfx = [
            "doorlocked" => new Sfx("audio/doorlocked.wav")
        ];
    }

    public function getConversation() {
        if(dialogpath == "lockeddoor" || dialogpath == "frontdoor") {
            sfx["doorlocked"].play();
        }
        return dialogpath;
    }

    override public function update() {
        if(
            dialogpath == "lockeddoor"
            && cast(scene, GameScene).numberOfBossesBeaten() >= 3
        ) {
            collidable = false;
        }
        else if(
            dialogpath == "frontdoor"
            && cast(scene, GameScene).numberOfBossesBeaten() >= 4
        ) {
            collidable = false;
        }
        super.update();
    }
}
