package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.tweens.motion.*;
import haxepunk.utils.*;
import entities.*;
import entities.Level;
import scenes.*;

class RingMaster extends Enemy
{
    public static inline var SIZE = 80;
    public static inline var STARTING_HEALTH = 100;
    public static inline var ENRAGE_THRESHOLD = 40;
    public static inline var PRE_PHASE_ADVANCE_TIME = 2;
    public static inline var PRE_ENRAGE_TIME = 2;
    public static inline var PHASE_DURATION = 12.5;
    public static inline var ENRAGE_PHASE_DURATION = 10;
    public static inline var ENRAGED_PHASE_TRANSITION_TIME = 1.33;
    public static inline var PHASE_TRANSITION_TIME = 2;

    public var ring(default, null):Ring;

    private var sprite:Spritemap;
    private var preEnrage:Alarm;
    private var phaseRelocater:LinearMotion;
    private var phaseLocations:Map<String, Vector2>;
    private var currentPhase:String;
    private var betweenPhases:Bool;
    private var phaseTimer:Alarm;
    private var preAdvancePhaseTimer:Alarm;

    private var screenCenter:Vector2;
    private var isEnraged:Bool;
    private var enrageNextPhase:Bool;

    private var sfx:Map<String, Sfx>;

    public function new(startX:Float, startY:Float) {
        super(startX, startY);
        this.ring = new Ring(this);
        name = "ringmaster";
        isBoss = true;
        mask = new Hitbox(SIZE, SIZE);
        x -= width / 2;
        y -= height / 2;
        screenCenter = new Vector2(x, y);
        y -= 50;
        sprite = new Spritemap("graphics/ringmaster.png", SIZE, SIZE);
        sprite.add("idle", [0]);
        sprite.play("idle");
        graphic = sprite;
        health = STARTING_HEALTH;

        isEnraged = false;
        enrageNextPhase = false;
        generatePhaseLocations();
        phaseRelocater = new LinearMotion();
        addTween(phaseRelocater);
        preEnrage = new Alarm(PRE_ENRAGE_TIME);
        preEnrage.onComplete.bind(function() {
            // Start timers for enrage attacks
            phaseTimer.reset(ENRAGE_PHASE_DURATION);
        });
        addTween(preEnrage);

        currentPhase = "tossrings";
        betweenPhases = true;
        phaseTimer = new Alarm(PHASE_DURATION);
        phaseTimer.onComplete.bind(function() {
            preAdvancePhase();
        });
        addTween(phaseTimer);

        preAdvancePhaseTimer = new Alarm(PRE_PHASE_ADVANCE_TIME);
        preAdvancePhaseTimer.onComplete.bind(function() {
            advancePhase();
        });
        addTween(preAdvancePhaseTimer);

        sfx = [
            "enrage" => new Sfx("audio/enrage.wav")
        ];
    }

    private function generatePhaseLocations() {
        phaseLocations = [
            "tossrings" => new Vector2(screenCenter.x, screenCenter.y - 95),
        ];
    }

    private function preAdvancePhase() {
        betweenPhases = true;
        for(tween in tweens) {
            tween.active = false;
        }
        preAdvancePhaseTimer.start();
    }

    private function advancePhase() {
        generatePhaseLocations();
        if(enrageNextPhase) {
            isEnraged = true;
            enrageNextPhase = false;
            currentPhase = "enrage";
        }
        else {
            var allPhases = new Array<String>();
            for(phaseName in phaseLocations.keys()) {
                allPhases.push(phaseName);
            }
            allPhases.remove(currentPhase);
            allPhases.remove("enrage");
            currentPhase = allPhases[
                Std.int(Math.floor(Math.random() * allPhases.length))
            ];
            // TEMP
            currentPhase = "tossrings";
        }
    }

    override private function act() {
        if(health <= ENRAGE_THRESHOLD) {
            if(!isEnraged) {
                enrageNextPhase = true;
            }
        }
        if(betweenPhases) {
            if(preAdvancePhaseTimer.active) {
                // Do nothing
            }
            else if(atPhaseLocation()) {
                betweenPhases = false;
            }
            else {
                if(!phaseRelocater.active) {
                    phaseRelocater.setMotion(
                        x, y,
                        phaseLocations[currentPhase].x,
                        phaseLocations[currentPhase].y,
                        (
                            isEnraged ?
                            ENRAGED_PHASE_TRANSITION_TIME
                            : PHASE_TRANSITION_TIME
                        ),
                        Ease.sineInOut
                    );
                    phaseRelocater.start();
                }
                moveTo(phaseRelocater.x, phaseRelocater.y);
            }
        }
        else if(currentPhase == "tossrings") {
            ring.toss();
        }
    }

    private function atPhaseLocation() {
        return (
            x == phaseLocations[currentPhase].x
            && y == phaseLocations[currentPhase].y
        );
    }

    override function die() {
        var hazards = new Array<Entity>();
        scene.getType("hazard", hazards);
        for(hazard in hazards) {
            if(Type.getClass(hazard) == Spit) {
                cast(hazard, Spit).destroy();
            }
            else {
                scene.remove(hazard);
            }
        }
        super.die();
    }
}

