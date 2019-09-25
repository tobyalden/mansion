package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Butler extends Entity {
    private var dialogNumber:Int;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "npc";
        graphic = new Image("graphics/butler.png");
        mask = new Hitbox(16, 16);
        dialogNumber = 1;
    }

    public function getConversation() {
        var dialogNumberToReturn = dialogNumber;
        dialogNumber++;
        if(dialogNumber > 5) {
            dialogNumber = 2;
        }
        return 'butler${dialogNumberToReturn}';
    }
}
