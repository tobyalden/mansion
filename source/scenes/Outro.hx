package scenes;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.Spritemap;
import haxepunk.graphics.text.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import entities.*;
import openfl.Assets;

class Outro extends Scene
{
    private var cutsceneSprite:Spritemap;
    private var cutsceneBorder:Image;
    private var cutscene:Entity;

    private var flowerCutsceneSprite:Spritemap;
    private var flowerCutscene:Entity;

    private var sfx:Map<String, Sfx>;
    private var outroText:Text;
    private var curtain:Curtain;

    override public function begin() {
        curtain = new Curtain(camera);
        cutsceneSprite = new Spritemap("graphics/outrocutscene.png", 200, 200);
        cutsceneSprite.add("outro", [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 , 17, 18
        ], 5, false);
        cutsceneSprite.onAnimationComplete.bind(function(_:Animation) {
            curtain.fadeOut();
            var sceneChanger = new Alarm(2);
            sceneChanger.onComplete.bind(function() {
                HXP.scene = new Credits();
            });
            addTween(sceneChanger, true);
        });
        cutscene = addGraphic(cutsceneSprite);
        cutscene.x = HXP.width / 2 - 100;
        cutscene.y = HXP.height / 2 - 100;

        flowerCutsceneSprite = new Spritemap(
            "graphics/flowercutscene.png", 200, 200
        );
        flowerCutsceneSprite.add("idle", [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
            19, 19, 19, 19, 19, 19, 19, 19, 19, 19,
            19, 19, 19, 19, 19, 19, 19, 19, 19, 19,
        ], 10, false);
        flowerCutsceneSprite.play("idle");
        flowerCutsceneSprite.onAnimationComplete.bind(function(_:Animation) {
            flowerCutscene.visible = false;
            cutsceneSprite.play("outro");
        });
        flowerCutscene = addGraphic(flowerCutsceneSprite);
        flowerCutscene.x = HXP.width / 2 - 100;
        flowerCutscene.y = HXP.height / 2 - 100;

        cutsceneBorder = new Image("graphics/cutsceneborder.png");
        cutsceneBorder.x = cutscene.x;
        cutsceneBorder.y = cutscene.y;
        addGraphic(cutsceneBorder);

        outroText = new Text("And now it's over.");
        outroText.size = 12;
        outroText.font = "font/tmnt-the-hyperstone-heist-italic.ttf";
        outroText.x = HXP.width / 2 - outroText.textWidth / 2;
        outroText.y = cutscene.y + 220;
        //addGraphic(outroText);
        sfx = [
            "outro" => new Sfx("audio/intro.wav"),
            "flowers" => new Sfx("audio/flowers.wav"),
        ];
        sfx["outro"].play();
        sfx["flowers"].play();
        add(curtain);
        curtain.fadeIn();
    }

    override public function update() {
        super.update();
    }
}

