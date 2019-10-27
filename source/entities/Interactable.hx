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

    public function new(
        x:Float, y:Float, width:Int, height:Int, dialogpath:String
    ) {
        super(x, y);
        this.dialogpath = dialogpath;
        type = "interactable";
        mask = new Hitbox(width, height);
    }

    public function getConversation() {
        return dialogpath;
    }
}
