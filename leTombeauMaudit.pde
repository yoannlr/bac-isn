import ddf.minim.*;

final int tileSize = 80;
int timer = 0;
int score = 0;
int[] scores;
boolean sons = true;
PFont font1;

boolean game = false;
boolean option = false;
boolean bestscores = false;
boolean intro = false;
boolean gameOver = false;
boolean timerStarted = false;

Joueur joueur = new Joueur(1, 1);

Minim minim;
AudioSample pyramide;

String[] phrase1;
String[] phrase2;
String[] phrase3;
String[] phrase4;
String[] phrase5;
String ligne1;
String ligne2;
String ligne3;
String ligne4;
String ligne5;

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



/*    SCORES    */

void loadScores() {
  scores = new int[3];
  String[] scoresStr = loadStrings("scores.txt");
  for(int i = 0; i < 3; i++) scores[i] = Integer.parseInt(scoresStr[i]);
}

void addScore(int s) {
  scores[2] = scores[1];
  scores[1] = scores[0];
  scores[0] = s;
  String[] sc = new String[]{"" + scores[0], "" + scores[1], "" + scores[2]};
  saveStrings("data/scores.txt", sc);
}


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

HashMap<String, Integer> attackDamages = new HashMap<String, Integer>();

/*    ENNEMIS    */

class Ennemy {
  int x;
  int y;
  String type;
  int mvStep = 0;
  int mvSpeed = 0;
  int life = 60;
  
  Ennemy(String type, int x, int y) {
    this.type = type;
    this.x = x;
    this.y = y;
    println("Adding ennemy " + this.type);
    
    switch(this.type) {
      case "spider": this.mvSpeed = 2; break;
      case "snake": this.mvSpeed = 1; break;
      default: this.mvSpeed = 3; break;
    }
  }
  
  void move(int x, int y) {
    if(getCurrentMap().canPass(this.x + x, this.y + y)) {
      this.x = this.x+x;
      this.y = this.y+y;
    }
  }

  void update() {
    if(this.life < 1) return;
    
    if(isPlayerClose()) joueur.life--;
    else {
      mvStep++;
      if(this.mvStep >= this.mvSpeed) {
        this.mvStep = 0;
        if((int) random(2) == 0) move((int) (random(2) + 1) * 2 - 3, 0);
        else move(0, (int) (random(2) + 1) * 2 - 3);
      }
    }
  }
  
  boolean isPlayerClose() {
    if(joueur.x == this.x && joueur.y == this.y) return true;    //joueur et ennemi sur la meme case
    if(joueur.y == this.y && (joueur.x == this.x - 1 || joueur.x == this.x + 1)) return true;    //joueur a gauche ou a droite de l'ennemi
    if(joueur.x == this.x && (joueur.y == this.y - 1 || joueur.y == this.y + 1)) return true;    //joueur au dessus ou en dessous de l'ennemi
    return false;    //rien
  }
  
  void renderEnnemy() {
    if(this.life < 1) return;
    image(sprites.get("ennemy_" + this.type), this.x * tileSize, this.y * tileSize);
    if(this.life < 60) {
      fill(128, 0, 0);
      rect(this.x * tileSize + 10, this.y * tileSize - 10, 60, 10);
      fill(200, 0, 0);
      rect(this.x * tileSize + 10, this.y * tileSize - 10, this.life, 10);
      fill(255);
    }
  }
}



/*    WORLD    */

boolean fileExists(String path) {
  File f = new File(path);
  if(f.exists()) return true;
  return false;
}

Map[] maps = new Map[100];
int currentLevel = 1;

void setMap(int level) {
  if(fileExists(dataPath("level" + level + ".json"))) {
    maps[level] = new Map("level" + level + ".json");
    currentLevel = level;
  }
  else {
    game = false;
    gameOver = true;
  }
}

Map getCurrentMap() {
  return maps[currentLevel];
}

class Map {
  int[][] tiles;
  int mWidth;
  int mHeight;
  int spawnX, spawnY, outX, outY;
  Ennemy[] ennemies;
  Item[] items;
  
  Map(String file) {
    JSONObject data = loadJSONObject(file);
    
    this.mWidth = data.getInt("width");
    this.mHeight = data.getInt("height");
    this.tiles = new int[this.mWidth][this.mHeight];
    
    JSONArray tiles = data.getJSONArray("tiles");
    int[] csvMap = tiles.getIntArray();
    
    JSONArray ennemiesConf = data.getJSONArray("ennemies");
    String[] ennemiesString = ennemiesConf.getStringArray();
    this.ennemies = new Ennemy[ennemiesString.length];
    
    int n = 0;
    for(String s : ennemiesString) {
      String[] params = s.split(",");
      Ennemy e = new Ennemy(params[0], Integer.parseInt(params[1]), Integer.parseInt(params[2]));
      this.ennemies[n] = e;
      n++;
    }

    JSONArray itemsConf = data.getJSONArray("items");
    String[] itemsString = itemsConf.getStringArray();
    this.items = new Item[itemsString.length];
    
    n = 0;
    for(String s : itemsString) {
      String[] params = s.split(",");
      Item i = new Item(params[0], Integer.parseInt(params[1]), Integer.parseInt(params[2]));
      this.items[n] = i;
      n++;
    }
    
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
    
    joueur.x = this.spawnX;
    joueur.y = this.spawnY;
  }
  
  void update() {
    for(Ennemy e : this.ennemies) e.update();
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
  
  void renderEntities() {
    for(Ennemy e : this.ennemies) {
      e.renderEnnemy();
    }

    for(Item i : this.items) {
      i.render();
    }

    joueur.joueurDraw();
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

class Item {
  String type;
  int x, y;

  Item(String t, int x, int y) {
    this.type = t;
    this.x = x;
    this.y = y;
    
    println("Adding item " + this.type);
  }

  void render() {
    image(sprites.get("item_" + this.type), this.x * tileSize, this.y * tileSize);
  }

  void pickup() {
    if(joueur.x == this.x && joueur.y == this.y) {
      if(this.type.equals("heart")) joueur.life = 100;
      else joueur.addItem(this.type);
      this.x = -1;
      this.y = -1;
    }
  }
}

/*    JOUEUR   */

class Joueur {
  int x;
  int y;
  int life = 100;
  int d = 0;
  String[] inventory = new String[5];
  int selectedSlot;
  
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
  
  void attack() {
    for(Ennemy e : getCurrentMap().ennemies) {
      if(e.isPlayerClose()) {
        if(this.inventory[this.selectedSlot] != null) e.life -= attackDamages.get(this.inventory[this.selectedSlot]);
        else e.life -= 1;
      }
    }
  }

  void pickupItems() {
    for(Item i : getCurrentMap().items) i.pickup();
  }
  
  void addItem(String type) {
    for(int i = 0; i < 5; i++) {
      if(this.inventory[i] == null) {
        this.inventory[i] = type;
        return;
      }
    }
  }
  
  void renderUI() {
    //Vie
    image(sprites.get("ui"), 0, 0);
    fill(200, 0, 0);
    rect(30, 5, 2 * joueur.life, 20);
    fill(255);
    
    //Inventaire
    for(int i = 0; i < 5; i++) {
      if(i == this.selectedSlot) image(sprites.get("selected_slot"), 80 * i + 240, 0);
      if(this.inventory[i] != null) image(sprites.get("item_" + this.inventory[i]), 80 * i + 240, 0);
    }
    
    //Niveau actuel
    textFont(createFont("courrier", 23));
    text("Niv " + currentLevel + " | Sc " + score, 40, 60);
  }
}

/*    MENUS    */

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

void drawBestScores() {
  image(sprites.get("egypt"),0,0,1280,720);
  fill(255, 255, 255, 200);
  rect(320, 60, 640, 120);
  fill(248, 196, 113, 230);
  rect(320, 240, 640, 300);
  rect(320, 590, 640, 100);
  fill(0);
  textFont(createFont("courrier", 40));
  text("Le tombeau maudit", 450, 140);
  textFont(createFont("courrier", 30));
  text("Historique des scores", 490, 280);
  text("Retour", 490, 650);
  text(scores[0], 490, 350);
  text(scores[1], 490, 400);
  text(scores[2], 490, 450);
}

void drawGameOver() {
  image(sprites.get("egypt"),0,0,1280,720);
  textFont(createFont("courrier", 40));
  text("Game Over", 520, 140);
  text("Score: " + score, 550, 600);
  textFont(createFont("courrier", 30));
  text("Retour Menu", 1000, 650);
}

void affiche(String t, int x, int y) {
  text(t, x, y);
}

void drawIntro() {
  fill(255);
  textFont(font1);
  image(sprites.get("intro"), 0, 0);
  affiche(ligne1,250,230);
  affiche(ligne2,250,280);
  affiche(ligne3,250,330);
  affiche(ligne4,250,380);
  affiche(ligne5,450,500);
  image(sprites.get("controls"), 0, 0);
}

void resetGame() {
    addScore(score);
    score = 0;
    gameOver = false;
    currentLevel = 1;
    maps = new Map[100];
    maps[1] = new Map("level1.json");
}

/*    MAIN    */

void setup() {
  strokeWeight(0);
  loadSprites();
  loadScores();
  size(1280, 720);
  setMap(1);
  minim = new Minim(this);
  
  font1 = loadFont("DejaVuSerifCondensed-Bold-16.vlw");
  phrase1 = loadStrings("1.txt");
  phrase2 = loadStrings("2.txt");
  phrase3 = loadStrings("3.txt");
  phrase4 = loadStrings("4.txt");
  phrase5 = loadStrings("5.txt");
  
  for (int i=0; i<phrase1.length;i++){
    ligne1 = phrase1[i];
  }
  for (int i=0; i<phrase2.length;i++){
    ligne2 = phrase2[i];
  }
  for (int i=0; i<phrase3.length;i++){
    ligne3 = phrase3[i];
  }
  for (int i=0; i<phrase4.length;i++){
    ligne4 = phrase4[i];
  }
  for (int i=0; i<phrase5.length;i++){
    ligne5 = phrase5[i];
  } 
  
  //pyramide = minim.loadSample("pyramide.wav");
  
  attackDamages.put("sword", 20);
  attackDamages.put("heart", 0);
  attackDamages.put("stick", 5);
}

void updateTimer() {
  timer = timer + (timer - millis());
  if(timer > 1000 && game) {
    timer = 0;
    getCurrentMap().update();
  }
}

void mousePressed() {
  if (!game && !option && !bestscores && !intro && !gameOver) {
     if (mouseX > 320 && mouseX < 960 && mouseY > 270 && mouseY < 370) { 
       intro = true;
     }
     else
     if (mouseX > 320 && mouseX < 960 && mouseY > 430 && mouseY < 530) {
        bestscores = true;
     }
     else
     if (mouseX > 320 && mouseX < 960 && mouseY > 590 && mouseY < 690) {
       option = true;
       
     }
     else
     if (mouseX > 1100 && mouseX < 1160 && mouseY > 690 && mouseY < 710) exit();
  }
  else if (option && !game && !bestscores && !intro) {
    if (mouseX > 320 && mouseX < 960 && mouseY > 270 && mouseY < 370) {
      sons = !sons;
    }
    else
    if (mouseX > 320 && mouseX < 960 && mouseY > 590 && mouseY < 690) {
      option = false;
    }
  }
  else if (bestscores && !game && !option && !intro) {
    if (mouseX > 320 && mouseX < 960 && mouseY > 590 && mouseY < 690) {
      bestscores = false;
    }
  }
  else if(intro && !game && !option && !bestscores) {
    if(mouseX > 1150 && mouseY > 650) {
      intro = false;
      game = true;
      timerStarted = true;
    }
  }
  else if(gameOver) {
    if(mouseX > 900 && mouseY > 600) {
      resetGame();
    }
  }
}

void keyPressed() {
  if(game) {
    if( key == 'z') joueur.move(0,-1);
    if( key == 's') joueur.move(0,1);
    if( key == 'q') joueur.move(-1,0);
    if( key == 'd') joueur.move(1,0);
    if( key == 'a') joueur.attack();
  }
}

void drawGame() {
  joueur.pickupItems();
  getCurrentMap().render();
  getCurrentMap().renderEntities();
  getCurrentMap().renderTopTiles();
  if(joueur.x == getCurrentMap().outX && joueur.y == getCurrentMap().outY) {
    score += 1000 + joueur.life;
    joueur.life += 10;
    if(joueur.life > 100) joueur.life = 100;
    setMap(currentLevel + 1);
  }
  joueur.renderUI();
  
  if(joueur.life < 1) {
    game = false;
    gameOver = true;
  }
  
  timer();
}

void mouseWheel(MouseEvent e) {
  if(!game) return;
  int n = e.getCount();
  if(joueur.selectedSlot + n >= 0 && joueur.selectedSlot + n < 5) joueur.selectedSlot += n;
}

void timer() {
  if(timerStarted) {
      int times = (millis()%60000)/1000;
      int timem = (millis()%3600000)/60000;
      if(timem >= 3) {
        timerStarted = false;
        game = false;
        gameOver = true;
      }
      text("Temps ecoule: " + timem + ":" + times + "/3:00", 950 , 30);
  }
}

void draw() {
  updateTimer();
  if (!game) {
    if (option) {
      drawOption();
    }
    else if (bestscores) {
      drawBestScores();
    }
    else if (intro) {
      drawIntro();
    }
    else if (gameOver) {
      drawGameOver();
    }
    else drawMenu();
  }
  else {
    drawGame();
  }
}

void stop() {
  minim.stop();
  super.stop();
}
