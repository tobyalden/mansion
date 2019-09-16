package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.math.*;
import scenes.*;

class Tutorial extends Entity
{
    private var tutorialDisplay:Spritemap;

    public function new(sceneCamera:Camera) {
        super();
        layer = -99;
        followCamera = sceneCamera;

        tutorialDisplay = new Spritemap("graphics/tutorial.png", 320, 24);
        tutorialDisplay.add("movement_keyboard", [0]);
        tutorialDisplay.add("movement_controller", [1]);
        tutorialDisplay.add("roll_keyboard", [2]);
        tutorialDisplay.add("roll_controller", [3]);
        tutorialDisplay.add("attack_keyboard", [4]);
        tutorialDisplay.add("attack_controller", [5]);
        tutorialDisplay.add("talk_keyboard", [6]);
        tutorialDisplay.add("talk_controller", [7]);
        tutorialDisplay.play("movement_keyboard");
        addGraphic(tutorialDisplay);
    }

    public function teach(tutorialName:String) {
        var controlType = Main.gamepad == null ? "keyboard" : "controller";
        tutorialDisplay.play('${tutorialName}_${controlType}');
    }

    override public function update() {
        tutorialDisplay.x = (
            GameScene.PLAYFIELD_SIZE / 2 + 20 - tutorialDisplay.width / 2
        );
        tutorialDisplay.y = GameScene.PLAYFIELD_SIZE + 20 - 25;
        super.update();
    }
}
