package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import openfl.Assets;
import scenes.*;

typedef DialogFile = {
  var conversation:NPCConversation;
}

typedef NPCConversation = Array<NPCDialogLine>;

typedef NPCDialogLine = {
  var portrait:String;
  var text:String;
}

class DialogBox extends Entity
{
    public static inline var BOX_WIDTH = 300;
    public static inline var BOX_HEIGHT = 50;

    public static inline var FADE_SPEED = 10;

    public static inline var BOB_SPEED = 0.25;
    public static inline var BOB_AMOUNT = 2.5;

    public static inline var SLOW_START = 2;

    private var text:Text;
    private var box:ColoredRect;
    private var portrait:Spritemap;
    private var cursor:Spritemap;
    private var conversation:Array<NPCDialogLine>;
    private var conversationIndex:Int;
    private var displayCharCount:Int;
    private var typeTimer:Alarm;
    private var fastTypeTimer:Alarm;
    private var isTypingFast:Bool;
    private var bob:Float;
    private var cursorStartY:Float;

    private var isFadingIn:Bool;
    private var isFadingOut:Bool;

    public function new(sceneCamera:Camera) {
        super();
        //LoveEntity.loadSfx(["type1", "type2", "type3", "typenext"]);
        layer = -99;
        followCamera = sceneCamera;
        box = new ColoredRect(BOX_WIDTH, 0, 0x000000);
        portrait = new Spritemap("graphics/portraits.png", 160, 160);
        portrait.add("mc", [0]);
        portrait.add("butler", [1]);
        portrait.x = BOX_WIDTH - 150;
        portrait.y = -160;
        text = new Text(
            "", 0, 0, BOX_WIDTH - 20, BOX_HEIGHT
        );
        text.size = 12;
        text.font = "font/tmnt-the-hyperstone-heist-italic.ttf";
        text.resizable = false;
        text.wordWrap = true;
        text.leading = 10;
        cursor = new Spritemap("graphics/cursor.png", 11, 6);
        cursor.add("idle", [0]);
        cursor.add("blink", [0, 1], 3);
        cursor.play("blink");
        cursor.x = BOX_WIDTH - 15;
        cursor.y = BOX_HEIGHT - 10;
        cursorStartY = cursor.y;
        addGraphic(box);
        addGraphic(text);
        addGraphic(cursor);
        addGraphic(portrait);
        
        conversation = new Array<NPCDialogLine>();

        conversationIndex = 0;
        displayCharCount = 1;

        typeTimer = new Alarm(0.1, TweenType.Looping);
        typeTimer.onComplete.bind(function() {
            addCharacter(false);
        });
        addTween(typeTimer);
        typeTimer.start();

        fastTypeTimer = new Alarm(0.025, TweenType.Looping);
        fastTypeTimer.onComplete.bind(function() {
            addCharacter(true);
        });
        addTween(fastTypeTimer);
        fastTypeTimer.start();

        isTypingFast = false;
        bob = 0;

        isFadingIn = false;
        isFadingOut = false;
        visible = false;
    }

    private function addCharacter(calledFromFastTimer:Bool) {
        if(
            calledFromFastTimer && !isTypingFast
            || calledFromFastTimer && text.text.length < SLOW_START
            || isFadingIn || isFadingOut || !visible
        ) {
            return;
        }
        displayCharCount++;
        var oldLength = text.text.length;
        var currentChar = (
            conversation[conversationIndex].text.charAt(displayCharCount)
        );
        text.text = conversation[conversationIndex].text.substring(
            0, displayCharCount
        );
        if(
            oldLength != text.text.length
            && (!isTypingFast || isTypingFast && text.text.length % 2 == 0)
        ) {
            //LoveEntity.allSfx['type${HXP.choose(1, 2, 3)}'].play();
        }
    }

    private function advanceConversation() {
        if(isFadingIn || isFadingOut) {
            return;
        }
        //LoveEntity.allSfx['typenext'].play();
        displayCharCount = 0;
        conversationIndex++;
        text.text = "";
        if(conversationIndex >= conversation.length) {
            fadeOut();
        }
        else {
            if(conversation[conversationIndex].portrait == "mc") {
                portrait.x = BOX_WIDTH - 150;
            }
            else {
                portrait.x = 10;
            }
            portrait.play(conversation[conversationIndex].portrait);
        }
    }

    public function loadConversation(conversationToLoad:NPCConversation) {
        conversation = new Array<NPCDialogLine>();
        for(line in conversationToLoad) {
            for(parsedLine in parseLine(line)) {
                conversation.push({
                    portrait: line.portrait, text: parsedLine.text
                });
            }
        }
    }

    private function parseLine(line:NPCDialogLine) {
        var currentText = text.text;
        text.text = "";

        var words = line.text.split(" ");
        var parsedLines = new Array<String>();
        var currentLine = "";
        for(word in words) {
            var oldHeight = text.textHeight;
            text.text = currentLine + " " + word;
            if(oldHeight != text.textHeight) {
                parsedLines.push(currentLine + "\n");
                currentLine = word;
                text.text = currentLine;
            }
            else {
                currentLine += " " + word;
            }
        }
        parsedLines.push(currentLine);
        parsedLines.shift();

        text.text = currentText;

        var parsedDialog = new Array<NPCDialogLine>();
        var conjoinedLine = "";
        for(i in 0...parsedLines.length) {
            conjoinedLine += parsedLines[i];
            if(i % 2 == 1) {
                parsedDialog.push({
                    portrait: line.portrait,
                    text: conjoinedLine
                });
                conjoinedLine = "";
            }
            else if(i == parsedLines.length - 1) {
                parsedDialog.push({
                    portrait: line.portrait,
                    text: conjoinedLine
                });
            }
        }

        return parsedDialog;
    }

    public function fadeIn() {
        visible = true;
        isFadingIn = true;
        box.height = 0;
        cursor.visible = false;
        displayCharCount = 0;
        conversationIndex = 0;
        if(conversation[conversationIndex].portrait == "mc") {
            portrait.x = BOX_WIDTH - 150;
        }
        else {
            portrait.x = 10;
        }
        portrait.play(conversation[conversationIndex].portrait);
    }

    public function fadeOut() {
        isFadingOut = true;
    }

    override public function update() {
        cursor.visible = !isFadingIn && !isFadingOut;
        if(isFadingIn) {
            box.height = Math.min(box.height + FADE_SPEED, BOX_HEIGHT);
            box.y = (BOX_HEIGHT/2) * (1 - (box.height / BOX_HEIGHT));
            if(box.height == BOX_HEIGHT) {
                isFadingIn = false;
            }
        }
        else if(isFadingOut) {
            box.height = Math.max(box.height - FADE_SPEED, 0);
            box.y = (BOX_HEIGHT/2) * (1 - (box.height / BOX_HEIGHT));
            if(box.height == 0) {
                isFadingOut = false;
                cast(scene, GameScene).endConversation();
                visible = false;
            }
        }

        if(
            Main.inputPressed("roll")
            && visible
            && text.text.length == conversation[conversationIndex].text.length
        ) {
            advanceConversation();
        }

        isTypingFast = Main.inputCheck("roll");
        
        x = 20 + (GameScene.PLAYFIELD_SIZE - BOX_WIDTH) / 2;
        y = 20 + GameScene.PLAYFIELD_SIZE - BOX_HEIGHT - 10;

        bob += BOB_SPEED;
        if(bob >= Math.PI * 2) {
            bob -= Math.PI * 2;
        }
        //cursor.y = Math.floor(
            //cursorStartY + Math.sin(bob - Math.PI/2) * BOB_AMOUNT
        //);

        super.update();
    }
}

