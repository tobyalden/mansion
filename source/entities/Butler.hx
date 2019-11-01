package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Butler extends NPC {
    private var dialogNumber:Int;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "npc";
        graphic = new Image("graphics/butler.png");
        mask = new Hitbox(16, 16);
        dialogNumber = GameScene.hasGlobalFlag("flasksobtained") ? 2 : 1;
    }

    override public function getConversation() {
        var dialogNumberToReturn = dialogNumber;
        dialogNumber++;
        if(dialogNumber > 6) {
            dialogNumber = 2;
        }
        if(
            dialogNumberToReturn == 2
            && GameScene.hasGlobalFlag("superwizardDefeated")
            || dialogNumberToReturn == 3
            && GameScene.hasGlobalFlag("ringmasterDefeated")
            || dialogNumberToReturn == 4
            && GameScene.hasGlobalFlag("grandjokerDefeated")
            || dialogNumberToReturn == 5
            && GameScene.hasGlobalFlag("grandfatherDefeated")
            || dialogNumberToReturn == 6
            && GameScene.hasGlobalFlag("grandfatherDefeated")
        ) {
            return 'butler${dialogNumberToReturn}alt';
        }
        return 'butler${dialogNumberToReturn}';
    }
}
