final int tileSize = 80;
int timer = 0;
boolean game = false;
boolean sons = true;
boolean option = false;

Joueur j = new Joueur( 1, 1);

/*
  TILES IDS
  0 AIR
  1 WALL
  2 WALL TOP
  3 PILLAR
  4 DOOR - LEFT
  5 DOOR - RIGHT
  6 SPAWN, REPLACED BY 4
  7 SPAWN, REPLACED BY 5
  8 EXIT, REPLACED BY 4
  9 EXIT, REPLACED BY 5
*/

/*    RESOURCES    */

HashMap<String, PImage> sprites = new HashMap<String, PImage>();


void loadSprites() {
  java.io.File folder = new java.io.File(dataPath(""));
  String[] files = folder.list();
  for(String s : files) {
    if(s.endsWith(".jpg") || s.endsWith(".png")) {
      println("Load sprite: " + s + " as " + s.substring(0, s.length() - 4));
      PImage i = loadImage(s);
      sprites.put(s.substring(0, s.length() - 4), i);
    }
  }
}

/*    WORLD    */
Map[] maps = new Map[100];
int currentLevel = 1;

void setMap(int level) {
  maps[level] = new Map("level" + level + ".json");
  currentLevel = level;
}

Map getCurrentMap() {
  return maps[currentLevel];
}

class Map {
  int[][] tiles;
  int mWidth;
  int mHeight;
  int spawnX, spawnY, outX, outY;
  
  Map(String file) {
    JSONObject data = loadJSONObject(file);
    
    this.mWidth = data.getInt("width");
    this.mHeight = data.getInt("height");
    this.tiles = new int[this.mWidth][this.mHeight];
    
    JSONArray tiles = data.getJSONArray("tiles");
    int[] csvMap = tiles.getIntArray();
    
    for(int x = 0; x < this.mWidth; x++) {
      for(int y = 0; y < this.mHeight; y++) {
        int t = csvMap[(y * this.mWidth) + x];
        
        switch(t) {
          case 6:
            this.spawnX = x;
            this.spawnY = y;
            t = 4;
            break;
          case 7:
            this.spawnX = x;
            this.spawnY = y;
            t = 5;
            break;
          case 8:
            this.outX = x;
            this.outY = y;
            t = 4;
            break;
          case 9:
            this.outX = x;
            this.outY = y;
            t = 5;
          default: break;
        }
        
        this.tiles[x][y] = t;
      }
    }
    
    j.x = this.spawnX;
    j.y = this.spawnY;
  }
  
  void render() {
    for(int x = 0; x < this.mWidth; x++) {
      for(int y = 0; y < this.mHeight; y++) {
        if(tiles[x][y] != 4 && tiles[x][y] != 5) {
          image(sprites.get("tile_" + this.tiles[x][y]), x * tileSize, y * tileSize);
        }
        else {
          image(sprites.get("tile_0"), x * tileSize, y * tileSize);
        }
      }
    }
  }
  
  void renderTopTiles() {
    for(int x = 0; x < this.mWidth; x++) {
      for(int y = 0; y < this.mHeight; y++) {
        if(tiles[x][y] == 4 || tiles[x][y] == 5)
          image(sprites.get("tile_" + this.tiles[x][y]), x * tileSize, y * tileSize);
      }
    } 
  }
  
  boolean canPass(int x, int y) {
    if(x >= 0 && y >= 0 && x < this.mWidth && y < this.mHeight)
      return this.tiles[x][y] == 0 || this.tiles[x][y] == 4 || this.tiles[x][y] == 5;
    return false;
  }
}

class Joueur {
  int x;
  int y;
  int d = 0;
  
  Joueur(int x, int y) {
    this.x = x;
    this.y = y;
  }
  
  void move(int x, int y) {
    if(x >= 0) this.d = 0;
    else this.d = 1;
    if(getCurrentMap().canPass(this.x+x, this.y+y)) {
      this.x = this.x+x;
      this.y = this.y+y;
    }
  }
  void joueurDraw() {
    image(sprites.get("character_" + this.d), this.x * tileSize, this.y * tileSize);
  }
}

void keyPressed() {
  if(game) {
    if( key == 'z') j.move(0,-1);
    if( key == 's') j.move(0,1);
    if( key == 'q') j.move(-1,0);
    if( key == 'd') j.move(1,0);
  }
}

void drawMenu() {
   image(sprites.get("egypt"),0,0,1280,720);
   fill(255, 255, 255, 200);
   rect(320, 60, 640, 120);
   fill(248, 196, 113, 230);
   rect(320, 270, 640, 100);
   rect(320, 430, 640, 100);
   rect(320, 590, 640, 100);
   fill(170);
   rect(1100,690, 60, 20);
   fill(0);
   textFont(createFont("courrier", 40));
   text("Le tombeau maudit", 450, 140);
   textFont(createFont("courrier", 30));
   text("Jouer", 490, 330);
   text("Mes scores", 490, 490);
   text("Options", 490, 650);
   textFont(createFont("courrier", 10));
   text("Quit", 1120, 705);
}

void drawOption() {
   image(sprites.get("egypt"),0,0,1280,720);
   fill(255, 255, 255, 200);
   rect(320, 60, 640, 120);
   fill(248, 196, 113, 230);
   rect(320, 270, 640, 100);
   //rect(320, 430, 640, 100);
   rect(320, 590, 640, 100);
   fill(0);
   textFont(createFont("courrier", 40));
   text("Le tombeau maudit", 450, 140);
   textFont(createFont("courrier", 30));
   text("Sons :", 490, 330);
   text("Retour", 490, 650);
   textFont(createFont("courrier", 25));
    if (sons) {
        fill(0);
        text("NON", 665, 330);
      }
      else {
        fill(0);
        text("OUI", 665, 330);
      }
}

/*    MAIN    */

void setup() {
  loadSprites();
  size(1280, 720);
  setMap(1);
}

void updateTimer() {
  timer = timer + (timer - millis());
  if(timer > 1000) gameTick();
}

void mousePressed() {
   if (!game && !option) {
     if (mouseX > 320 && mouseX < 960 && mouseY > 270 && mouseY < 370) { 
       game = true;
     }
     else
     if (mouseX > 320 && mouseX < 960 && mouseY > 430 && mouseY < 530) {
        
     }
     else
     if (mouseX > 320 && mouseX < 960 && mouseY > 590 && mouseY < 690) {
       option = true;
       
     }
     else
     if (mouseX > 1100 && mouseX < 1160 && mouseY > 690 && mouseY < 710) exit();
  }
  else if (option && !game) {
    if (mouseX > 320 && mouseX < 960 && mouseY > 270 && mouseY < 370) {
      if (sons) {
        sons = false;
      }
      else {
        sons = true;
      }
    }
    else
    if (mouseX > 320 && mouseX < 960 && mouseY > 590 && mouseY < 690) {
      option = false;
    }
  }
}

void gameTick() {
}

void drawGame() {
    getCurrentMap().render();
    j.joueurDraw();
    getCurrentMap().renderTopTiles();
    if(j.x == getCurrentMap().outX && j.y == getCurrentMap().outY) setMap(currentLevel + 1);
}

void draw() {
  updateTimer();
  if (!game) {
    if (option) {
      drawOption();
    }
    else drawMenu();
  }
  else if (game) {
    drawGame();
  }
}