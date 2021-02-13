import processing.video.*;

int vEspaco = 10;
Movie mov;
int precisao = 1;

void setup() {
  size(854, 480);
  frameRate(30); // ajustar esse parâmetro
  mov = new Movie(this, "teste.mp4");
  mov.frameRate(30); // ajustar esse parâmetro
  mov.loop();
  
  noFill();
  stroke((#ff666c));
}

void draw() {
  background((#004aa3));
  if (mov.available() == true) {
    mov.read();
    mov.loadPixels();
    
    float fase = 0;
    for (int y = 0; y < height; y+=vEspaco) {
      float x = 0;
      beginShape();
      while (x < width) {
        color col = mov.get(floor(x), y);
        float r = red(col);
        float g = green(col);
        float b = blue(col);
        float intensidade = (r + g + b) / 765;
        vertex(x, y + sin(fase-intensidade)*vEspaco/2);
        x += precisao / (intensidade + 0.01) / 5;
        fase += 0.5;
      }
      endShape();
    }
  }
  saveFrame("################.png");
}
