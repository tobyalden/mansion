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

class MainMenu extends Scene
{
    public static inline var BOB_AMOUNT = 5;
    public static inline var BOB_SPEED = 0.5;
    public static inline var PROMPT_FADE_TIME = 0.5;

    private var background:Image;
    private var logo:Image;
    private var menu:Array<Text>;
    private var cursor:Image;
    private var bob:NumTween;
    private var selected:Int;
    private var sfx:Map<String, Sfx>;
    private var atStartPrompt:Bool;

    override public function begin() {
        background = new Image("graphics/mainmenu.png");
        logo = new Image("graphics/logo.png");
        addGraphic(background);
        addGraphic(logo);
        menu = [
            new Text("New Game"),
            new Text("Continue")
        ];
        var count = 0;
        for(menuItem in menu) {
            menuItem.size = 18;
            menuItem.font = "font/tmnt-the-hyperstone-heist-italic.ttf";
            menuItem.x = 75;
            menuItem.y = 100 + count * 25;
            menuItem.alpha = 0;
            addGraphic(menuItem);
            count++;
        }
        cursor = new Image("graphics/menucursor.png");
        cursor.alpha = 0;
        bob = new NumTween(TweenType.PingPong);
        bob.tween(-BOB_AMOUNT, BOB_AMOUNT, BOB_SPEED, Ease.circInOut);
        addTween(bob, true);
        selected = 0;
        addGraphic(cursor);
        atStartPrompt = true;
        sfx = [
            "start" => new Sfx("audio/start.wav")
        ];
    }    

    override public function update() {
        cursor.x = menu[selected].x - 20 + bob.value;
        cursor.y = menu[selected].y + 6;
        if(
            Main.inputPressed("cast")
            || Main.inputPressed("roll")
        ) {
            if(atStartPrompt) {
                atStartPrompt = false;
                sfx["start"].play();
                for(menuItem in menu) {
                    var menuItemTween = new VarTween();
                    menuItemTween.tween(
                        menuItem, "alpha", 1, PROMPT_FADE_TIME, Ease.sineIn
                    );
                    addTween(menuItemTween, true);
                }
                var cursorTween = new VarTween();
                cursorTween.tween(
                    cursor, "alpha", 1, PROMPT_FADE_TIME, Ease.sineIn
                );
                addTween(cursorTween, true);
                var logoTween = new VarTween();
                logoTween.tween(
                    logo, "alpha", 0, PROMPT_FADE_TIME, Ease.sineIn
                );
                addTween(logoTween, true);
            }
        }
        var oldSelected = selected;
        if(Main.inputPressed("up")) {
            selected -= 1;
        }
        else if(Main.inputPressed("down")) {
            selected += 1;
        }
        selected = Std.int(MathUtil.clamp(selected, 0, menu.length - 1));
        if(selected != oldSelected) {
            // Menu sfx
        }
        super.update();
    }
}
