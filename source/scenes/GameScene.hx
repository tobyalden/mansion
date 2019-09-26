package scenes;

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
import entities.DialogBox;
import openfl.Assets;

// TODO: Maybe doors lock on room enter 50% of the time?
// TODO: In roguelike mode, enemies are reshuffled in addition to being
// respawned normally when resting at bonfire
// TODO: The nymph has a malignant aura around her, which she uses as her weapon

class GameScene extends Scene
{
    public static inline var PLAYFIELD_SIZE = 320;
    public static inline var NUMBER_OF_ENEMIES = 150;
    public static inline var CAMERA_PAN_TIME = 1;
    public static inline var LOCK_CHANCE = 1;

    public static var isHardMode = false;
    public static var isNightmare = false;
    public static var isProcedural = false;
    public static var currentGlobalFlags(default, null):Array<String>;
    //private static var globalFlagsAtStart:Array<String> = [];
    private static var globalFlagsAtStart:Array<String> = [
        "superWizardFightStarted", "ringMasterFightStarted"
    ];
    private var sfx:Map<String, Sfx>;

    public static function hasGlobalFlag(flag:String) {
        return currentGlobalFlags.indexOf(flag) != -1;
    }

    public static function addGlobalFlag(flag:String) {
        if(currentGlobalFlags.indexOf(flag) == -1 && flag != "") {
            currentGlobalFlags.push(flag);
            trace('added currentGlobal flag: ${flag}');
        }
    }

    public static function removeGlobalFlag(flag:String) {
        if(currentGlobalFlags.remove(flag)) {
            trace('removed currentGlobal flag: ${flag}');
        }
    }

    public var isLevelLocked(default, null):Bool;
    public var currentLevel(default, null):Level;
    public var currentScreenX(default, null):Int;
    public var currentScreenY(default, null):Int;
    public var isDialogMode(default, null):Bool;
    public var pausePlayer(default, null):Bool;
    private var roomMapBlueprint:Grid;
    private var hallwayMapBlueprint:Grid;
    private var shaftMapBlueprint:Grid;
    private var startMapBlueprint:Grid;
    private var allBlueprint:Grid;
    private var displayMap:DisplayMap;
    private var proceduralPlacementMap:Grid;
    private var allLevels:Array<Level>;
    private var player:Player;
    private var dialogBox:DialogBox;
    private var viewport:Viewport;
    private var start:Level;
    private var openSpots:Array<IntPairWithLevel>;
    private var curtain:Curtain;
    private var cameraPanner:LinearMotion;
    private var playerPusher:LinearMotion;
    private var allEnemies:Array<Entity>;
    private var onScreenBox:Entity;
    private var isMovingDuringFade:Bool;
    private var lastConversationName:String;
    private var tutorial:Tutorial;
    private var currentSong:Sfx;

    public function setIsLevelLocked(newIsLevelLocked:Bool)  {
        isLevelLocked = newIsLevelLocked;
    }

    override public function begin() {
        currentGlobalFlags = Data.read(
            "globalFlags", globalFlagsAtStart
        );
        isMovingDuringFade = false;
        lastConversationName = "";
        var onScreenBoxSprite = new ColoredRect(
            PLAYFIELD_SIZE, PLAYFIELD_SIZE, 0xFF0000
        );
        onScreenBoxSprite.alpha = 0;
        onScreenBox = new Entity(
            0, 0, onScreenBoxSprite, new Hitbox(PLAYFIELD_SIZE, PLAYFIELD_SIZE)
        );
        onScreenBox.layer = -999999;
        add(onScreenBox);

        isDialogMode = false;
        pausePlayer = false;

        dialogBox = new DialogBox(camera);
        add(dialogBox);

        tutorial = new Tutorial(camera);
        add(tutorial);

        Key.define("restart", [Key.R]);
        Key.define("zoomout", [Key.Q]);
        isLevelLocked = false;
        allEnemies = new Array<Entity>();
        addGraphic(new Image("graphics/fullmap.png"), 20);
        player = new Player(0, 0);
        add(player);
        add(player.sword);
        if(isProcedural) {
            loadMaps(0);
            placeLevels();
            openSpots = new Array<IntPairWithLevel>();
            for(level in allLevels) {
                openSpots = openSpots.concat(level.openSpots);
                addMask(level.pits, "pits", Std.int(level.x), Std.int(level.y));
                add(new LockWalls(level.x, level.y, level));
            }
            HXP.shuffle(openSpots);
            player.x = start.x + PLAYFIELD_SIZE / 2 - 8 + 100;
            player.y = start.y + PLAYFIELD_SIZE / 2 - 8 + 100;
            var boss = new RingMaster(
                start.x + PLAYFIELD_SIZE / 2,
                start.y + PLAYFIELD_SIZE / 2
            );
            add(boss);
            //add(boss.laser);
            for(ring in boss.rings) {
                add(ring);
            }
            for(i in 0...NUMBER_OF_ENEMIES) {
                var enemySpot = getOpenSpot();
                var enemies = [
                    new Stalker(
                        enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                        enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                    ),
                    new Seer(
                        enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                        enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                    ),
                    new Booster(
                        enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                        enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                    ),
                    new Follower(
                        enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                        enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                    ),
                    new Archer(
                        enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                        enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                    ),
                    new Wizard(
                        enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                        enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                    ),
                    new Bouncer(
                        enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                        enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                    )
                ];
                var enemy = enemies[Random.randInt(enemies.length)];
                add(enemy);
                allEnemies.push(enemy);
                enemySpot.level.enemies.push(enemy);
                if(Type.getClass(enemy) == Follower) {
                    for(tail in cast(enemy, Follower).tails) {
                        add(tail);
                    }
                }
            }
            currentLevel = start;
        }
        else {
            loadStaticLevel("mansion_1F");
        }
        viewport = new Viewport(camera);
        add(viewport);
        curtain = new Curtain(camera);
        add(curtain);
        curtain.fadeIn();
        currentScreenX = Math.floor((player.centerX) / PLAYFIELD_SIZE);
        currentScreenY = Math.floor((player.centerY) / PLAYFIELD_SIZE);
        cameraPanner = new LinearMotion();
        cameraPanner.onComplete.bind(function() {
            for(enemy in allEnemies) {
                cast(enemy, Enemy).resetPosition();
            }
        });
        addTween(cameraPanner);
        playerPusher = new LinearMotion();
        playerPusher.onComplete.bind(function() {
            //player.cancelRoll();
        });
        addTween(playerPusher);
        sfx = [
            "playerrevive" => new Sfx("audio/playerrevive.wav"),
            "mansion1" => new Sfx("audio/mansion1.ogg"),
        ];
        currentSong = sfx["mansion1"];
        currentSong.loop();
    }

    public function getCurrentSong() {
        for(boss in ["superwizard", "ringmaster", "grandjoker", "grandfather"]) {
            if(isPlayerOnSameScreenAsBoss(boss)) {
                if(cast(getInstance(boss), Enemy).fightStarted) {
                    return '${boss}fight';
                }
                else {
                    return "silence";
                }
            }
        }
        return 'mansion${numberOfBossesBeaten()}';
    }

    public function numberOfBossesBeaten() {
        var bossesBeaten = 0;
        if(hasGlobalFlag("superWizardDefeated")) {
            bossesBeaten += 1;
        }
        if(hasGlobalFlag("ringMasterDefeated")) {
            bossesBeaten += 1;
        }
        if(hasGlobalFlag("grandJokerDefeated")) {
            bossesBeaten += 1;
        }
        if(hasGlobalFlag("grandfatherDefeated")) {
            bossesBeaten += 1;
        }
        return bossesBeaten;
    }

    public function isPlayerOnSameScreenAsBoss(bossName:String) {
        var boss = getInstance(bossName);
        if(boss != null) {
            if(
                getScreenCoordinates(player).x
                == getScreenCoordinates(boss).x
                && getScreenCoordinates(player).y
                == getScreenCoordinates(boss).y
            ) {
                return true;
            }
            else {
                return false;
            }
        }
        return false;
    }

    public function onDeath() {
        addGlobalFlag("respawnInRoom");
        var deathPause = new Alarm(2.5);
        deathPause.onComplete.bind(function() {
            curtain.fadeOut();
            var restartPause = new Alarm(2.5);
            restartPause.onComplete.bind(function() {
                stopSfx();
                HXP.scene = new GameScene();
            });
            addTween(restartPause, true);
            sfx["playerrevive"].play();
        });
        addTween(deathPause, true);
    }

    public function stopSfx() {
        var eirena = getInstance("superwizard");
        if(eirena != null) {
            cast(eirena, SuperWizard).stopSfx();
        }
        player.stopSfx();
    }

    public function isEntityOnscreen(e:Entity) {
        return e.collideWith(onScreenBox, e.x, e.y) != null;
    }

    public function getLevelFromPlayer() {
        for(level in allLevels) {
            if(
                player.centerX >= level.x
                && player.centerX < level.x + level.width
                && player.centerY >= level.y
                && player.centerY < level.y + level.height
            ) {
                return level;
            }
        }
        return null;
    }

    public function getLevelFromEntity(e:Entity) {
        for(level in allLevels) {
            if(e.collideRect(
                e.x, e.y, level.x, level.y, level.width, level.height
            )) {
                return level;
            }
        }
        return null;
    }

    public function getScreenCoordinates(e:Entity) {
        var screenCoordinates:IntPair = {
            x: Math.floor(e.centerX / PLAYFIELD_SIZE),
            y: Math.floor(e.centerY / PLAYFIELD_SIZE)
        };
        return screenCoordinates;
    }

    private function getOpenSpot() {
        var spotToReturn = openSpots.pop();
        for(openSpot in openSpots) {
            // Remove adjacent open spots
            if(
                spotToReturn.level.x == openSpot.level.x
                && spotToReturn.level.y == openSpot.level.y
                && (
                    Math.abs(spotToReturn.x - openSpot.x) <= 1
                    && Math.abs(spotToReturn.y - openSpot.y) <= 1
                )
            ) {
                openSpots.remove(openSpot);
            }
        }
        return spotToReturn;
    }


    private function bindCameraToLevel(
        currentScreenX:Int, currentScreenY:Int
    ) {
        var level = getLevelFromPlayer();
        var staticCameraX = currentScreenX * PLAYFIELD_SIZE;
        var staticCameraY = currentScreenY * PLAYFIELD_SIZE;
        if(level.width == PLAYFIELD_SIZE && level.height == PLAYFIELD_SIZE) {
            camera.x = staticCameraX;
            camera.y = staticCameraY;
        }
        else {
            camera.x = MathUtil.clamp(
                player.centerX - PLAYFIELD_SIZE / 2,
                level.x,
                level.x + level.width - PLAYFIELD_SIZE
            );
            camera.y = MathUtil.clamp(
                player.centerY - PLAYFIELD_SIZE / 2,
                level.y,
                level.y + level.height - PLAYFIELD_SIZE
            );
        }
        camera.x -= 20;
        camera.y -= 20;
    }

    public function panCamera(
        cameraDestinationX:Float,
        cameraDestinationY:Float,
        panTime:Float = CAMERA_PAN_TIME
    ) {
        cameraDestinationX -= 20;
        cameraDestinationY -= 20;
        cameraPanner.setMotion(
            camera.x, camera.y,
            cameraDestinationX, cameraDestinationY,
            panTime,
            Ease.sineInOut
        );
        cameraPanner.start();
        isMovingDuringFade = false;
    }

    override public function update() {
        trace(getCurrentSong());
        if(Input.check("restart")) {
            HXP.scene = new GameScene();
        }
        var _exit = player.collide("exit", player.x, player.y);
        if(_exit != null && !pausePlayer) {
            var exit = cast(_exit, Exit);
            pausePlayer = true;
            curtain.fadeOut(6);
            var movePlayerTween = new Alarm(0.2, function() {
                player.x = exit.destination.x;
                player.y = exit.destination.y;
                curtain.fadeIn(6);
                var enableMoveTimer = new Alarm(0.5, function() {
                    pausePlayer = false;
                });
                addTween(enableMoveTimer, true);
                isMovingDuringFade = true;
            });
            addTween(movePlayerTween, true);
        }
        var allEntities = new Array<Entity>();
        getAll(allEntities);
        for(entity in allEntities) {
            entity.active = !cameraPanner.active;
        }
        super.update();
        var oldScreenX = currentScreenX;
        var oldScreenY = currentScreenY;
        var oldLevel = currentLevel;
        currentScreenX = Math.floor((player.centerX) / PLAYFIELD_SIZE);
        currentScreenY = Math.floor((player.centerY) / PLAYFIELD_SIZE);
        currentLevel = getLevelFromPlayer();
        if(currentLevel != oldLevel) {
            isLevelLocked = Math.random() <= LOCK_CHANCE;
            var cameraDestinationX = MathUtil.clamp(
                player.centerX - PLAYFIELD_SIZE / 2,
                currentLevel.x,
                currentLevel.x + currentLevel.width - PLAYFIELD_SIZE
            );
            var cameraDestinationY = MathUtil.clamp(
                player.centerY - PLAYFIELD_SIZE / 2,
                currentLevel.y,
                currentLevel.y + currentLevel.height - PLAYFIELD_SIZE
            );
            panCamera(
                cameraDestinationX, cameraDestinationY,
                isMovingDuringFade ? CAMERA_PAN_TIME / 4 : CAMERA_PAN_TIME
            );

            var playerDestinationX = player.x;
            var playerDestinationY = player.y;
            if(currentScreenX < oldScreenX) {
                player.setLastSafeSpot(
                    new Vector2(player.x - Level.TILE_SIZE, player.y)
                );
                playerDestinationX -= Level.TILE_SIZE;
            }
            else if(currentScreenX > oldScreenX) {
                player.setLastSafeSpot(
                    new Vector2(player.x + Level.TILE_SIZE, player.y)
                );
                playerDestinationX += Level.TILE_SIZE;
            }
            else if(currentScreenY < oldScreenY) {
                player.setLastSafeSpot(
                    new Vector2(player.x, player.y - Level.TILE_SIZE)
                );
                playerDestinationY -= Level.TILE_SIZE;
            }
            else if(currentScreenY > oldScreenY) {
                player.setLastSafeSpot(
                    new Vector2(player.x, player.y + Level.TILE_SIZE)
                );
                playerDestinationY += Level.TILE_SIZE;
            }
            playerPusher.setMotion(
                player.x, player.y,
                playerDestinationX, playerDestinationY,
                CAMERA_PAN_TIME,
                Ease.sineInOut
            );
            playerPusher.start();
        }
        if(cameraPanner.active) {
            camera.x = cameraPanner.x;
            camera.y = cameraPanner.y;
            player.moveTo(playerPusher.x, playerPusher.y);
        }
        else {
            bindCameraToLevel(currentScreenX, currentScreenY);
        }
        if(Input.check("zoomout")) {
            camera.x = -1700;
            camera.y = -200;
            camera.scale = 0.1;
            player.visible = false;
            viewport.visible = false;
        }
        else {
            camera.scale = 1;
            player.visible = true;
            viewport.visible = true;
        }
        onScreenBox.x = camera.x + 20;
        onScreenBox.y = camera.y + 20;

        if(player.sword.getConversationPartner() != null) {
            tutorial.visible = !isDialogMode;
            tutorial.teach("talk");
        }
        else {
            tutorial.visible = !hasGlobalFlag("tutorialCompleted");
            if(currentScreenX == 4 && currentScreenY == 7) {
                tutorial.teach("movement");
            }
            else if(currentScreenX == 4 && currentScreenY == 6) {
                tutorial.teach("roll");
            }
            else if(
                currentScreenX == 5 && currentScreenY == 6
                || currentScreenX == 8 && currentScreenY == 2
                || currentScreenX == 3 && currentScreenY == 7
            ) {
                tutorial.teach("attack");
            }
            else {
                addGlobalFlag("tutorialCompleted");
            }
        }

        debug();
    }

    private function loadStaticLevel(levelName:String) {
        var levelPath = 'levels/${levelName}.oel';
        var xml = Xml.parse(Assets.getText(levelPath));
        var fastXml = new haxe.xml.Fast(xml.firstElement());
        var entities = new Array<Entity>();
        allLevels = new Array<Level>();
        var wholeLevelWidth = Std.parseInt(fastXml.node.width.innerData);
        var wholeLevelHeight = Std.parseInt(fastXml.node.height.innerData);
        var fullLayout = new Grid(
            Std.int(wholeLevelWidth / Level.TILE_SIZE),
            Std.int(wholeLevelHeight / Level.TILE_SIZE),
            DisplayMap.TILE_SIZE, DisplayMap.TILE_SIZE
        );
        for (r in fastXml.node.walls.nodes.rect) {
            fullLayout.setRect(
                Std.int(Std.parseInt(r.att.x) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Level.TILE_SIZE)
            );
        }
        displayMap = new DisplayMap(fullLayout, camera);
        add(displayMap);
        for (room in fastXml.node.rooms.nodes.room) {
            var level = new Level(
                Std.parseInt(room.att.x),
                Std.parseInt(room.att.y),
                "static",
                levelName,
                Std.parseInt(room.att.width),
                Std.parseInt(room.att.height)
            );
            level.updateGraphic();
            add(level);
            allLevels.push(level);
            addMask(level.pits, "pits", Std.int(level.x), Std.int(level.y));
            add(new LockWalls(level.x, level.y, level));
        }
        if(hasGlobalFlag("respawnInRoom")) {
            for(playerStart in fastXml.node.objects.nodes.respawn) {
                player.x = Std.parseInt(playerStart.att.x);
                player.y = Std.parseInt(playerStart.att.y);
                currentLevel = getLevelFromPlayer();
                break;
            }
        }
        else {
            for(playerStart in fastXml.node.objects.nodes.player) {
                player.x = Std.parseInt(playerStart.att.x);
                player.y = Std.parseInt(playerStart.att.y);
                currentLevel = getLevelFromPlayer();
                break;
            }
        }
        for(stalker in fastXml.node.objects.nodes.stalker) {
            var stalker = new Stalker(
                Std.parseInt(stalker.att.x),
                Std.parseInt(stalker.att.y)
            );
            allEnemies.push(stalker);
        }
        for(archer in fastXml.node.objects.nodes.archer) {
            var archer = new Archer(
                Std.parseInt(archer.att.x),
                Std.parseInt(archer.att.y)
            );
            allEnemies.push(archer);
        }
        for(bouncer in fastXml.node.objects.nodes.bouncer) {
            var bouncer = new Bouncer(
                Std.parseInt(bouncer.att.x),
                Std.parseInt(bouncer.att.y)
            );
            allEnemies.push(bouncer);
        }
        for(follower in fastXml.node.objects.nodes.follower) {
            var follower = new Follower(
                Std.parseInt(follower.att.x),
                Std.parseInt(follower.att.y)
            );
            allEnemies.push(follower);
            for(tail in follower.tails) {
                add(tail);
            }
        }
        for(seer in fastXml.node.objects.nodes.seer) {
            var seer = new Seer(
                Std.parseInt(seer.att.x),
                Std.parseInt(seer.att.y)
            );
            allEnemies.push(seer);
        }
        for(wizard in fastXml.node.objects.nodes.wizard) {
            var wizard = new Wizard(
                Std.parseInt(wizard.att.x),
                Std.parseInt(wizard.att.y)
            );
            allEnemies.push(wizard);
        }
        for(booster in fastXml.node.objects.nodes.booster) {
            var booster = new Booster(
                Std.parseInt(booster.att.x),
                Std.parseInt(booster.att.y)
            );
            allEnemies.push(booster);
        }
        for(superWizard in fastXml.node.objects.nodes.superwizard) {
            if(hasGlobalFlag("superWizardDefeated")) {
                break;
            }
            var superWizard = new SuperWizard(
                Std.parseInt(superWizard.att.x),
                Std.parseInt(superWizard.att.y)
            );
            allEnemies.push(superWizard);
            add(superWizard.laser);
        }
        for(ringMaster in fastXml.node.objects.nodes.ringmaster) {
            if(hasGlobalFlag("ringMasterDefeated")) {
                break;
            }
            var ringMaster = new RingMaster(
                Std.parseInt(ringMaster.att.x),
                Std.parseInt(ringMaster.att.y)
            );
            allEnemies.push(ringMaster);
            for(ring in ringMaster.rings) {
                add(ring);
            }
        }
        for(grandJoker in fastXml.node.objects.nodes.grandjoker) {
            if(hasGlobalFlag("grandJokerDefeated")) {
                break;
            }
            var grandJoker = new GrandJoker(
                Std.parseInt(grandJoker.att.x),
                Std.parseInt(grandJoker.att.y)
            );
            allEnemies.push(grandJoker);
        }
        for(grandfather in fastXml.node.objects.nodes.grandfather) {
            if(hasGlobalFlag("grandfatherDefeated")) {
                break;
            }
            var grandfather = new Grandfather(
                Std.parseInt(grandfather.att.x),
                Std.parseInt(grandfather.att.y)
            );
            allEnemies.push(grandfather);
        }
        for(butler in fastXml.node.objects.nodes.butler) {
            var butler = new Butler(
                Std.parseInt(butler.att.x),
                Std.parseInt(butler.att.y)
            );
            add(butler);
        }
        for(exit in fastXml.node.objects.nodes.exit) {
            var nodes = new Array<Vector2>();
            for(n in exit.nodes.node) {
                nodes.push(
                    new Vector2(Std.parseInt(n.att.x), Std.parseInt(n.att.y))
                );
            }
            var exit = new Exit(
                Std.parseInt(exit.att.x),
                Std.parseInt(exit.att.y),
                Std.parseInt(exit.att.width),
                Std.parseInt(exit.att.height),
                nodes[0]
            );
            add(exit);
        }
        for(enemy in allEnemies) {
            add(enemy);
            getLevelFromEntity(enemy).enemies.push(cast(enemy, Enemy));
        }
    }

    private function loadMaps(mapNumber:Int) {
        var mapPath = 'maps/${'test'}.oel';
        var xml = Xml.parse(Assets.getText(mapPath));
        var fastXml = new haxe.xml.Fast(xml.firstElement());
        var mapWidth = Std.parseInt(fastXml.node.width.innerData);
        var mapHeight = Std.parseInt(fastXml.node.height.innerData);
        proceduralPlacementMap = new Grid(
            mapWidth, mapHeight, Level.TILE_SIZE, Level.TILE_SIZE
        );
        roomMapBlueprint = new Grid(
            mapWidth, mapHeight, Level.TILE_SIZE, Level.TILE_SIZE
        );
        hallwayMapBlueprint = new Grid(
            mapWidth, mapHeight, Level.TILE_SIZE, Level.TILE_SIZE
        );
        shaftMapBlueprint = new Grid(
            mapWidth, mapHeight, Level.TILE_SIZE, Level.TILE_SIZE
        );
        startMapBlueprint = new Grid(
            mapWidth, mapHeight, Level.TILE_SIZE, Level.TILE_SIZE
        );
        allBlueprint = new Grid(
            mapWidth, mapHeight, Level.TILE_SIZE, Level.TILE_SIZE
        );
        for (r in fastXml.node.rooms.nodes.rect) {
            roomMapBlueprint.setRect(
                Std.int(Std.parseInt(r.att.x) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Level.TILE_SIZE)
            );
            allBlueprint.setRect(
                Std.int(Std.parseInt(r.att.x) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Level.TILE_SIZE)
            );
        }
        for (r in fastXml.node.hallways.nodes.rect) {
            hallwayMapBlueprint.setRect(
                Std.int(Std.parseInt(r.att.x) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Level.TILE_SIZE)
            );
            allBlueprint.setRect(
                Std.int(Std.parseInt(r.att.x) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Level.TILE_SIZE)
            );
        }
        for (r in fastXml.node.shafts.nodes.rect) {
            shaftMapBlueprint.setRect(
                Std.int(Std.parseInt(r.att.x) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Level.TILE_SIZE)
            );
            allBlueprint.setRect(
                Std.int(Std.parseInt(r.att.x) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Level.TILE_SIZE)
            );
        }
        for (r in fastXml.node.start.nodes.rect) {
            startMapBlueprint.setRect(
                Std.int(Std.parseInt(r.att.x) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Level.TILE_SIZE)
            );
            allBlueprint.setRect(
                Std.int(Std.parseInt(r.att.x) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.y) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.w) / Level.TILE_SIZE),
                Std.int(Std.parseInt(r.att.h) / Level.TILE_SIZE)
            );
        }
    }

    private function sealLevel(
        level:Level, tileX:Int, tileY:Int, checkX:Int, checkY:Int
    ) {
        if(
            !roomMapBlueprint.getTile(tileX + checkX - 1, tileY + checkY)
            && !hallwayMapBlueprint.getTile(tileX + checkX - 1, tileY + checkY)
        ) {
            level.fillLeft(checkY);
        }
        if(
            !roomMapBlueprint.getTile(tileX + checkX + 1, tileY + checkY)
            && !hallwayMapBlueprint.getTile(tileX + checkX + 1, tileY + checkY)
        ) {
            level.fillRight(checkY);
        }
        if(
            !roomMapBlueprint.getTile(tileX + checkX, tileY + checkY - 1)
            && !shaftMapBlueprint.getTile(tileX + checkX, tileY + checkY - 1)
        ) {
            level.fillTop(checkX);
        }
        if(
            !roomMapBlueprint.getTile(tileX + checkX, tileY + checkY + 1)
            && !shaftMapBlueprint.getTile(tileX + checkX, tileY + checkY + 1)
            && !startMapBlueprint.getTile(tileX + checkX, tileY + checkY + 1)
        ) {
            level.fillBottom(checkX);
        }
    }

    private function placeLevels() {
        allLevels = new Array<Level>();
        var levelTypes = ["room", "hallway", "shaft", "start"];
        var count = 0;
        for(mapBlueprint in [
            roomMapBlueprint, hallwayMapBlueprint, shaftMapBlueprint,
            startMapBlueprint
        ]) {
            for(tileX in 0...mapBlueprint.columns) {
                for(tileY in 0...mapBlueprint.rows) {
                    if(
                        mapBlueprint.getTile(tileX, tileY)
                        && !proceduralPlacementMap.getTile(tileX, tileY)
                    ) {
                        var canPlace = false;
                        while(!canPlace) {
                            var level = new Level(
                                tileX * Level.MIN_LEVEL_WIDTH,
                                tileY * Level.MIN_LEVEL_HEIGHT,
                                levelTypes[count]
                            );
                            var levelWidth = Std.int(
                                level.width / Level.MIN_LEVEL_WIDTH
                            );
                            var levelHeight = Std.int(
                                level.height / Level.MIN_LEVEL_HEIGHT
                            );
                            canPlace = true;
                            for(checkX in 0...levelWidth) {
                                for(checkY in 0...levelHeight) {
                                    if(
                                        proceduralPlacementMap.getTile(
                                            tileX + checkX, tileY + checkY
                                        )
                                        || !mapBlueprint.getTile(
                                            tileX + checkX, tileY + checkY
                                        )
                                    ) {
                                        canPlace = false;
                                    }
                                }
                            }
                            if(canPlace) {
                                for(checkX in 0...levelWidth) {
                                    for(checkY in 0...levelHeight) {
                                        proceduralPlacementMap.setTile(
                                            tileX + checkX, tileY + checkY
                                        );
                                        if(level.levelType != "start") {
                                            sealLevel(
                                                level,
                                                tileX, tileY,
                                                checkX, checkY
                                            );
                                        }
                                    }
                                }
                                level.findOpenSpots();
                                level.updateGraphic();
                                add(level);
                                if(level.levelType == "start") {
                                    start = level;
                                }
                                allLevels.push(level);
                            }
                        }
                    }
                }
            }
            count++;
        }
    }

    private function debug() {
        if(Main.inputPressed("testdialog")) {
            converse('test');
        }
        else if(Main.inputPressed("print")) {
            trace('screenX: ${currentScreenX}. screenY" ${currentScreenY}');
        }
    }

    public function converse(conversationName:String) {
        lastConversationName = conversationName;
        var json:DialogFile = haxe.Json.parse(
            Assets.getText('dialog/${conversationName}.json')
        );
        var conversation = loadConversation(json);
        isDialogMode = true;
        pausePlayer = true;
        dialogBox.loadConversation(conversation);
        dialogBox.fadeIn();
    }

    public function setPausePlayer(newPausePlayer:Bool) {
        pausePlayer = newPausePlayer;
    }

    public function endConversation() {
        isDialogMode = false;
        pausePlayer = false;
        if(lastConversationName == "superwizard") {
            cast(getInstance("superwizard"), Enemy).setFightStarted(true);
        }
        else if(lastConversationName == "ringmaster") {
            cast(getInstance("ringmaster"), Enemy).setFightStarted(true);
        }
        else if(lastConversationName == "grandjoker") {
            cast(getInstance("grandjoker"), Enemy).setFightStarted(true);
        }
        else if(lastConversationName == "grandfather") {
            cast(getInstance("grandfather"), Enemy).setFightStarted(true);
        }
    }

    private function loadConversation(json:DialogFile) {
        var conversation = new NPCConversation();
        for(jsonLine in json.conversation) {
            conversation.push({
                portrait: jsonLine.portrait, text: jsonLine.text
            });
        }
        return conversation;
    }
}
