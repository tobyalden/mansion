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

class Intro extends Scene
{
    private var cutsceneSprite:Spritemap;
    private var cutsceneBorder:Image;
    private var cutscene:Entity;
    private var sfx:Map<String, Sfx>;
    private var introText:Text;
    private var curtain:Curtain;

    override public function begin() {
        curtain = new Curtain(camera);
        cutsceneSprite = new Spritemap("graphics/introcutscene.png", 200, 200);
        cutsceneSprite.add("intro", [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7,
            7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13,
            13, 14, 14, 14, 15, 15, 15, 16, 16, 16, 17, 17, 17, 18, 18, 18, 19,
            19, 19,
            20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
            20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
            20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
            20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
            20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
            21, 21, 21, 21, 22, 22, 22, 22, 23, 23, 23, 23, 24, 24, 24, 24, 25,
            25, 25, 25, 26, 26, 26, 26, 27, 27, 27, 27, 28, 28, 28, 28, 29, 29,
            29, 29, 30, 30, 30, 30, 31, 31, 31, 31, 32, 32, 32, 32
        ], 20, false);
        cutsceneSprite.play("intro");
        cutsceneSprite.onAnimationComplete.bind(function(_:Animation) {
            curtain.fadeOut();
            var sceneChanger = new Alarm(2);
            sceneChanger.onComplete.bind(function() {
                HXP.scene = new GameScene();
            });
            addTween(sceneChanger, true);
        });
        cutscene = addGraphic(cutsceneSprite);
        cutscene.x = HXP.width / 2 - 100;
        cutscene.y = HXP.height / 2 - 100;

        cutsceneBorder = new Image("graphics/cutsceneborder.png");
        cutsceneBorder.x = cutscene.x;
        cutsceneBorder.y = cutscene.y;
        addGraphic(cutsceneBorder);

        introText = new Text("After years away, I've finally come home.");
        introText.size = 12;
        introText.font = "font/tmnt-the-hyperstone-heist-italic.ttf";
        introText.x = HXP.width / 2 - introText.textWidth / 2;
        introText.y = cutscene.y + 220;
        //addGraphic(introText);
        sfx = [
            "intro" => new Sfx("audio/intro.wav"),
        ];
        sfx["intro"].play();
        add(curtain);
        curtain.fadeIn();
    }

    override public function update() {
        super.update();
    }
}
