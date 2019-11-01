package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class Sister extends NPC {
    private var dialogNumber:Int;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "npc";
        name = "sister";
        graphic = new Image("graphics/sister.png");
        mask = new Hitbox(14, 16);

        dialogNumber = Data.read("highestSisterDialogHeard", 1);
    }

    private function getHighestAvailableConversation() {
        var gameScene = cast(scene, GameScene);
		var numBossesBeaten = gameScene.numberOfBossesBeaten();
		if(numBossesBeaten == 2) {
            return 2;
		}
		else if(numBossesBeaten == 3) {
            return 4;
		}
        else {
            return 6;
		}
    }

    public function onBossDeath() {
        trace('Sister.onBossDeath() called.');
        trace('Data.read("highestSisterDialogHeard", 1) = ${Data.read("highestSisterDialogHeard", 1)}');
        trace('getHighestAvailableConversation() - 2 = ${getHighestAvailableConversation() - 2}');
        if(
            Data.read("highestSisterDialogHeard", 1)
            == getHighestAvailableConversation() - 2
        ) {
            dialogNumber = getHighestAvailableConversation() - 1;
            trace('set new conversation on boss death');
        }
    }

    override public function update() {
        var gameScene = cast(HXP.scene, GameScene);
        var numBossesBeaten = gameScene.numberOfBossesBeaten();
        visible = numBossesBeaten > 1;
        collidable = numBossesBeaten > 1;
        super.update();
    }

    override public function getConversation() {
        var dialogNumberToReturn = dialogNumber;
        dialogNumber++;
        if(dialogNumber > getHighestAvailableConversation()) {
            dialogNumber = getHighestAvailableConversation() - 1;
        }
        if(dialogNumberToReturn > Data.read("highestSisterDialogHeard", 1)) {
            Data.write("highestSisterDialogHeard", dialogNumberToReturn);
            trace('wrote ${dialogNumberToReturn} as highest dialog heard');
        }
        Data.save(GameScene.SAVE_FILENAME);
        return 'sister${dialogNumberToReturn}';
    }
}

