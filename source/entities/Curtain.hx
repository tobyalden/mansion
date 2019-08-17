package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import scenes.*;

class Curtain extends Entity
{
    public static inline var FADE_SPEED = 1;

    public var isFadingIn(default, null):Bool;
    private var isFadingOut:Bool;
    private var fadeSpeed:Float;
    private var curtainGraphic:ColoredRect;

    public function new(sceneCamera:Camera) {
        super(0, 0);
        curtainGraphic = new ColoredRect(HXP.width, HXP.height, 0x000000);
        curtainGraphic.alpha = 1;
        graphic = curtainGraphic;
        layer = -99999;
        isFadingIn = false;
        isFadingOut = false;
        fadeSpeed = FADE_SPEED;
        followCamera = sceneCamera;
    }

    public function fadeIn(newFadeSpeed:Float = FADE_SPEED) {
        fadeSpeed = newFadeSpeed;
        isFadingIn = true;
        isFadingOut = false;
    }

    public function fadeOut(newFadeSpeed:Float = FADE_SPEED) {
        fadeSpeed = newFadeSpeed;
        isFadingOut = true;
        isFadingIn = false;
    }

    override public function update() {
        curtainGraphic.width = HXP.width;
        curtainGraphic.height = HXP.height;
        if(isFadingIn) {
            graphic.alpha = Math.max(
                0, graphic.alpha - fadeSpeed * HXP.elapsed
            );
            if(graphic.alpha == 0) {
                isFadingIn = false;
            }
        }
        else if(isFadingOut) {
            graphic.alpha = Math.min(
                1, graphic.alpha + fadeSpeed * HXP.elapsed
            );
            if(graphic.alpha == 1) {
                isFadingOut = false;
            }
        }
        super.update();
    }
}


