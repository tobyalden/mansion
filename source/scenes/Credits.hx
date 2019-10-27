package scenes;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import entities.*;
import openfl.Assets;

class Credits extends Scene
{
    public static inline var SCROLL_SPEED = 50;

    private var credits:Entity;
    private var creditsImage:Image;
    private var postCredits:Entity;
    private var postCreditsImage:Image;
    private var postCreditsRevealed:Bool;
    private var sfx:Map<String, Sfx>;

    override public function begin() {
        creditsImage = new Image("graphics/credits.png");
        credits = new Entity(0, HXP.height, creditsImage);
        add(credits);
        postCreditsImage = new Image("graphics/postcredits.png");
        postCreditsImage.alpha = 0;
        postCredits = new Entity(0, 0, postCreditsImage);
        add(postCredits);
        postCreditsRevealed = false;
        sfx = [
            "ending" => new Sfx("audio/ending.ogg"),
            "postcredits" => new Sfx("audio/postcredits.wav")
        ];
        sfx["ending"].play();
    }

    override public function update() {
        credits.y -= SCROLL_SPEED * HXP.elapsed;
        if(credits.y < -creditsImage.height && !postCreditsRevealed) {
            revealPostCredits();
        }
        super.update();
    }

    private function revealPostCredits() {
        var postCreditsFadeIn = new VarTween();
        postCreditsFadeIn.tween(postCreditsImage, "alpha", 1, 4);
        addTween(postCreditsFadeIn, true);
        sfx["postcredits"].play();
        postCreditsRevealed = true;
        var fadeOutDelay = new Alarm(6);
        fadeOutDelay.onComplete.bind(function() {
            var postCreditsFadeOut = new VarTween();
            postCreditsFadeOut.tween(postCreditsImage, "alpha", 0, 4);
            postCreditsFadeOut.onComplete.bind(function() {
                var backToMenuDelay = new Alarm(2);
                backToMenuDelay.onComplete.bind(function() {
                    HXP.scene = new MainMenu();
                });
                addTween(backToMenuDelay, true);
            });
            addTween(postCreditsFadeOut, true);
        });
        addTween(fadeOutDelay, true);
    }
}
