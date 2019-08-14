package scenes;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import entities.*;
import entities.Level;
import openfl.Assets;

class GameScene extends Scene
{
    public static inline var PLAYFIELD_SIZE = 320;
    public static inline var NUMBER_OF_ENEMIES = 50;

    private var roomMapBlueprint:Grid;
    private var hallwayMapBlueprint:Grid;
    private var shaftMapBlueprint:Grid;
    private var startMapBlueprint:Grid;
    private var allBlueprint:Grid;
    private var map:Grid;
    private var allLevels:Array<Level>;
    private var player:Player;
    private var viewport:Viewport;
    private var start:Level;
    private var openSpots:Array<IntPairWithLevel>;
    private var enemyWall:Entity;

    override public function begin() {
        Key.define("restart", [Key.R]);
        Key.define("zoomout", [Key.Q]);
        loadMaps(0);
        placeLevels();
        openSpots = new Array<IntPairWithLevel>();
        for(level in allLevels) {
            openSpots = openSpots.concat(level.openSpots);
        }
        HXP.shuffle(openSpots);
        createEnemyWall();
        player = new Player(
            start.x + PLAYFIELD_SIZE / 2 - 8,
            start.y + PLAYFIELD_SIZE / 2 - 8
        );
        add(player);
        for(i in 0...NUMBER_OF_ENEMIES) {
            var enemySpot = getOpenSpot();
            var enemies = [
                //new Stalker(
                    //enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                    //enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                //),
                //new Seer(
                    //enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                    //enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                //),
                //new Booster(
                    //enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                    //enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                //)
                new Bouncer(
                    enemySpot.level.x + enemySpot.x * Level.TILE_SIZE,
                    enemySpot.level.y + enemySpot.y * Level.TILE_SIZE
                )
            ];
            add(enemies[Random.randInt(enemies.length)]);
        }
        viewport = new Viewport(camera);
        add(viewport);
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

    private function createEnemyWall() {
        var enemyWallMask = new Grid(
            Level.MIN_LEVEL_WIDTH + Level.TILE_SIZE * 2,
            Level.MIN_LEVEL_HEIGHT + Level.TILE_SIZE * 2,
            Std.int(Level.TILE_SIZE / 2),
            Std.int(Level.TILE_SIZE / 2)
        );
        for(wallTileX in 0...enemyWallMask.columns) {
            for(wallTileY in 0...enemyWallMask.rows) {
                if(
                    wallTileX <= 2
                    || wallTileY <= 2
                    || wallTileX == enemyWallMask.columns - 3
                    || wallTileY == enemyWallMask.rows - 3
                  ) {
                    enemyWallMask.setTile(wallTileX, wallTileY);
                }
            }
        }
        enemyWall = new Entity(0, 0);
        enemyWall.mask = enemyWallMask;
        enemyWall.type = "enemywalls";
        add(enemyWall);
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

    override public function update() {
        if(Input.check("restart")) {
            HXP.scene = new GameScene();
        }
        super.update();
        camera.x = (
            Math.floor((player.centerX) / PLAYFIELD_SIZE)
            * PLAYFIELD_SIZE - 20
        );
        camera.y = (
            Math.floor((player.centerY) / PLAYFIELD_SIZE)
            * PLAYFIELD_SIZE - 20
        );
        enemyWall.x = (
            Math.floor((player.centerX) / PLAYFIELD_SIZE)
            * PLAYFIELD_SIZE - Level.TILE_SIZE
        );
        enemyWall.y = (
            Math.floor((player.centerY) / PLAYFIELD_SIZE)
            * PLAYFIELD_SIZE - Level.TILE_SIZE
        );
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
    }

    private function loadMaps(mapNumber:Int) {
        var mapPath = 'maps/${'test'}.oel';
        var xml = Xml.parse(Assets.getText(mapPath));
        var fastXml = new haxe.xml.Fast(xml.firstElement());
        var mapWidth = Std.parseInt(fastXml.node.width.innerData);
        var mapHeight = Std.parseInt(fastXml.node.height.innerData);
        map = new Grid(mapWidth, mapHeight, Level.TILE_SIZE, Level.TILE_SIZE);
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
                        && !map.getTile(tileX, tileY)
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
                                        map.getTile(
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
                                        map.setTile(
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
}
