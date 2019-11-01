package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class Dad extends NPC {
    private var dialogNumber:Int;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "npc";
        name = "dad";
        graphic = new Image("graphics/dad.png");
        mask = new Hitbox(10, 18);

        dialogNumber = Data.read("highestDadDialogHeard", 1);
    }

    private function getHighestAvailableConversation() {
        var gameScene = cast(scene, GameScene);
		var numBossesBeaten = gameScene.numberOfBossesBeaten();
		if(numBossesBeaten == 1) {
            return 2;
		}
		else if(numBossesBeaten == 2) {
            return 4;
		}
		else if(numBossesBeaten == 3) {
            return 6;
		}
		else {
            return 8;
		}
    }

    public function onBossDeath() {
        if(
            Data.read("highestDadDialogHeard", 1)
            == getHighestAvailableConversation() - 2
        ) {
            dialogNumber = getHighestAvailableConversation() - 1;
        }
    }

    override public function update() {
        var gameScene = cast(HXP.scene, GameScene);
        var numBossesBeaten = gameScene.numberOfBossesBeaten();
        visible = numBossesBeaten > 0;
        collidable = numBossesBeaten > 0;
        super.update();
    }

    override public function getConversation() {
        var dialogNumberToReturn = dialogNumber;
        dialogNumber++;
        if(dialogNumber > getHighestAvailableConversation()) {
            dialogNumber = getHighestAvailableConversation() - 1;
        }
        if(dialogNumber > Data.read("highestDadDialogHeard", 1)) {
            Data.write("highestDadDialogHeard", dialogNumberToReturn);
        }
        Data.save(GameScene.SAVE_FILENAME);
        return 'dad${dialogNumberToReturn}';
    }
}
