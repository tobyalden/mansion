package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class Dog extends NPC {
    private var dialogNumber:Int;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "npc";
        name = "dog";
        graphic = new Image("graphics/dog.png");
        mask = new Hitbox(15, 1);
        dialogNumber = 1;
    }

    override public function getConversation() {
        var dialogNumberToReturn = dialogNumber;
        dialogNumber++;
        if(dialogNumber > 4) {
            dialogNumber = 1;
        }
        return 'dog${dialogNumberToReturn}';
    }
}
