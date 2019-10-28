package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Exit extends Entity {
    public var destination(default, null):Vector2;
    private var sfx:Sfx;
    private var sfxName:String;

    public function new(
        x:Float, y:Float, width:Int, height:Int, destination:Vector2,
        sfxName:String
    ) {
        super(x, y);
        this.sfxName = sfxName;
        this.destination = destination;
        type = "exit";
        //graphic = new ColoredRect(width, height, 0x0000FF);
        mask = new Hitbox(width, height);
        if(sfxName != "") {
            sfx = new Sfx('audio/${sfxName}.wav');
        }
    }

    public function playSfx() {
        if(sfxName == "") {
            return;
        }
        sfx.play();
    }
}
