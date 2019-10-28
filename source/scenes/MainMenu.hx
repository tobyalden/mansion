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
    public static inline var PROMPT_FADE_TIME = 0.25;

    private var curtain:Curtain;
    private var background:Image;
    private var glow:Image;
    private var glowFader:VarTween;
    private var logo:Image;
    private var menu:Array<Text>;
    private var difficultyMenu:Array<Text>;
    private var cursor:Image;
    private var bob:NumTween;
    private var selected:Int;
    private var sfx:Map<String, Sfx>;
    private var atStartPrompt:Bool;
    private var startPrompt:Spritemap;
    private var startPromptFader:VarTween;
    private var canControl:Bool;
    private var atDifficultyMenu:Bool;
    private var fadeTweens:Array<Tween>;
    private var saveGameExists:Bool;

    override public function begin() {
        curtain = new Curtain(camera);
        background = new Image("graphics/mainmenu.png");
        glow = new Image("graphics/mainmenuphoneglow.png");
        logo = new Image("graphics/logo.png");
        addGraphic(background);
        addGraphic(glow);
        addGraphic(logo);

        glowFader = new VarTween(TweenType.PingPong);
        glowFader.tween(glow, "alpha", 0, 1, Ease.sineInOut);
        addTween(glowFader, true);

        Data.load(GameScene.SAVE_FILENAME);
        var savedGlobalFlags = Data.read("globalFlags", []);
        saveGameExists = savedGlobalFlags.length > 0;

        menu = [
            new Text("New Game"),
            new Text("Continue")
        ];
        var count = 0;
        for(menuItem in menu) {
            menuItem.size = 18;
            menuItem.font = "font/tmnt-the-hyperstone-heist-italic.ttf";
            menuItem.x = 75;
            menuItem.y = 50 + count * 25;
            menuItem.alpha = 0;
            if(count == 1 && !saveGameExists) {
                // Gray out continue option if there's no saved game
                menuItem.color = 0x686868;
            }
            addGraphic(menuItem);
            count++;
        }

        difficultyMenu = [
            new Text("Normal"),
            new Text("Hard"),
            new Text("Nightmare")
        ];
        count = 1;
        for(menuItem in difficultyMenu) {
            menuItem.size = 18;
            menuItem.font = "font/tmnt-the-hyperstone-heist-italic.ttf";
            menuItem.x = 125;
            menuItem.y = 50 + count * 25;
            menuItem.alpha = 0;
            if(count == 3) {
                menuItem.color = 0x800000;
            }
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
        startPrompt = new Spritemap("graphics/startprompt.png", 640, 42);
        startPrompt.add("keyboard", [0]);
        startPrompt.add("controller", [1]);
        startPrompt.x = 50;
        startPrompt.y = 50;
        startPromptFader = new VarTween(TweenType.PingPong);
        startPromptFader.tween(startPrompt, "alpha", 0.5, 1, Ease.sineInOut);
        addTween(startPromptFader, true);
        addGraphic(startPrompt);
        add(curtain);
        curtain.fadeIn();
        canControl = true;
        atDifficultyMenu = false;
        fadeTweens = new Array<Tween>();
        sfx = [
            "start" => new Sfx("audio/start.wav"),
            "continue" => new Sfx("audio/continue.wav"),
            "select1" => new Sfx("audio/select1.wav"),
            "select2" => new Sfx("audio/select2.wav"),
            "select3" => new Sfx("audio/select3.wav"),
            "cantselect" => new Sfx("audio/cantselect.wav"),
            "back" => new Sfx("audio/back.wav"),
            //"mainmenu" => new Sfx("audio/mainmenu.ogg"),
            "laugh" => new Sfx("audio/laugh.wav")
        ];
        //sfx["mainmenu"].loop();
    }    

    private function isFading() {
        for(fadeTween in fadeTweens) {
            if(fadeTween.active) {
                return true;
            }
        }
        return false;
    }

    override public function update() {
        var controlType = Main.gamepad == null ? "keyboard" : "controller";
        startPrompt.play(controlType);
        var cursorMenu = atDifficultyMenu ? difficultyMenu : menu;
        if(atDifficultyMenu) {
            startPrompt.alpha = 0;
        }
        cursor.x = cursorMenu[selected].x - 20 + bob.value;
        cursor.y = cursorMenu[selected].y + 6;
        if(canControl) {
            if(
                (Main.inputPressed("cast") || Main.inputPressed("roll"))
                && !isFading()
            ) {
                if(atStartPrompt) {
                    fadeFromPromptToMenu();
                }
                else if(atDifficultyMenu) {
                    if(Main.inputPressed("roll")) {
                        Data.clear();
                        if(selected == 0) {
                            GameScene.isHardMode = false;
                            GameScene.isNightmare = false;
                        }
                        else if(selected == 1) {
                            GameScene.isHardMode = true;
                            GameScene.isNightmare = false;
                        }
                        else if(selected == 2) {
                            GameScene.isHardMode = true;
                            GameScene.isNightmare = true;
                            sfx["laugh"].play();
                        }
                        sfx["start"].play();
                        fadeToGame();
                    }
                    else {
                        atDifficultyMenu = false;
                        sfx["back"].play();
                        fadeFromMenuToDifficultyMenu(true);
                        selected = 0;
                    }
                }
                else {
                    if(Main.inputPressed("roll")) {
                        if(selected == 0) {
                            // New game
                            sfx["start"].play();
                            atDifficultyMenu = true;
                            fadeFromMenuToDifficultyMenu();
                        }
                        else if(selected == 1) {
                            // Continue
                            if(saveGameExists) {
                                sfx["continue"].play();
                                fadeToGame();
                            }
                            else {
                                sfx["cantselect"].play();
                            }
                        }
                    }
                    else {
                        fadeFromPromptToMenu(true);
                    }
                }
            }
            var oldSelected = selected;
            if(!atStartPrompt) {
                if(Main.inputPressed("up")) {
                    selected -= 1;
                }
                else if(Main.inputPressed("down")) {
                    selected += 1;
                }
            }
            var currentMenu = atDifficultyMenu ? difficultyMenu : menu;
            selected = Std.int(MathUtil.clamp(
                selected, 0, currentMenu.length - 1
            ));
            if(selected != oldSelected) {
                sfx['select${HXP.choose(1, 2, 3)}'].play();
            }
        }
        super.update();
    }

    private function fadeToGame() {
        canControl = false;
        curtain.fadeOut();
        var sceneChanger = new Alarm(2);
        sceneChanger.onComplete.bind(function() {
            HXP.scene = new GameScene();
        });
        addTween(sceneChanger, true);
    }

    private function fadeFromMenuToDifficultyMenu(backwards:Bool = false) {
        for(fadeTween in fadeTweens) {
            fadeTween.cancel();
        }
        fadeTweens = new Array<Tween>();
        for(menuItem in menu) {
            if(menuItem == menu[0]) {
                continue;
            }
            var menuItemTween = new VarTween();
            menuItemTween.tween(
                menuItem, "alpha", backwards ? 1 : 0,
                PROMPT_FADE_TIME / 2, Ease.sineIn
            );
            fadeTweens.push(menuItemTween);
        }
        for(menuItem in difficultyMenu) {
            var menuItemTween = new VarTween();
            menuItemTween.tween(
                menuItem, "alpha", backwards ? 0: 1,
                PROMPT_FADE_TIME / 2, Ease.sineIn
            );
            fadeTweens.push(menuItemTween);
        }

        for(fadeTween in fadeTweens) {
            addTween(fadeTween, true);
        }
    }

    private function fadeFromPromptToMenu(backwards:Bool = false) {
        for(fadeTween in fadeTweens) {
            fadeTween.cancel();
        }
        fadeTweens = new Array<Tween>();
        atStartPrompt = backwards;
        sfx[backwards ? "back" : "start"].play();
        for(menuItem in menu) {
            var menuItemTween = new VarTween();
            menuItemTween.tween(
                menuItem, "alpha", backwards ? 0 : 1, PROMPT_FADE_TIME,
                Ease.sineIn
            );
            fadeTweens.push(menuItemTween);
        }
        var cursorTween = new VarTween();
        cursorTween.tween(
            cursor, "alpha", backwards ? 0 : 1, PROMPT_FADE_TIME, Ease.sineIn
        );
        fadeTweens.push(cursorTween);
        var logoTween = new VarTween();
        logoTween.tween(
            logo, "alpha", backwards ? 1 : 0, PROMPT_FADE_TIME, Ease.sineIn
        );
        fadeTweens.push(logoTween);
        startPromptFader.active = false;
        var startPromptTween = new VarTween();
        startPromptTween.tween(
            startPrompt, "alpha", backwards ? 1 : 0, PROMPT_FADE_TIME,
            Ease.sineIn
        );
        fadeTweens.push(startPromptTween);
        for(fadeTween in fadeTweens) {
            addTween(fadeTween, true);
        }
    }
}
