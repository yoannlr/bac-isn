int tileSize = 40;

class Map {
  int[][] tiles;
  int mWidth;
  int mHeight;
  
  Map(String file) {
    JSONObject data = loadJSONObject(file);
    
    this.mWidth = data.getInt("width");
    this.mHeight = data.getInt("height");
    this.tiles = new int[this.mWidth][this.mHeight];
    
    JSONArray tiles = data.getJSONArray("tiles");
    int[] csvMap = tiles.getIntArray();
    
    for(int x = 0; x < this.mWidth; x++) {
      for(int y = 0; y < this.mHeight; y++) {
        this.tiles[x][y] = csvMap[(y * this.mWidth) + x];
      }
    }
  }
  
  void render() {
    for(int x = 0; x < this.mWidth; x++) {
      for(int y = 0; y < this.mHeight; y++) {
        if(this.tiles[x][y] == 1) {
          rect(x * tileSize, y * tileSize, tileSize, tileSize);
        }
      }
    }
  }
}

Map map;

void setup() {
  size(400, 400);
  map = new Map("level1.json");
}

void draw() {
  map.render();
}