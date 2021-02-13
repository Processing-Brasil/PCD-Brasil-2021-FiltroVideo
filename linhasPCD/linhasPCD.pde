import processing.video.*;

int vEspaco = 20;
Movie mov;
color movColors[]; // cor do pixel
int precisao = 1;
color paleta[] = new color[3];


void setup() {
  size(854, 480);
  frameRate(30); // ajustar esse parâmetro
  mov = new Movie(this, "teste.mp4");
  mov.frameRate(30); // ajustar esse parâmetro
  mov.loop();
  movColors = new color[width * height];
  paleta[0] = (#004aa3);
  paleta[1] =(#ff666c);
  paleta[2] =(#e6e6d8);
}

void draw() {
  background(paleta[0]);
  noFill();
  stroke(paleta[1]);

  if (mov.available() == true) {
    mov.read();
    mov.loadPixels();
    int count = 0;
    int fase = 0;

    beginShape();
    for (int j = 0; j < height; j+=vEspaco) { // eico vertical
      for (int i = 0; i < width; i++) { // horizontal
        if (count < movColors.length ) { // para não execeder o tamanho da lista
          movColors[count] = mov.get(i, j);
          float red = red(movColors[count]);
          float green = green(movColors[count]);
          float blue = blue(movColors[count]);
          float intensidade = red + green + blue / 765;
          vertex(i, j + sin(fase-intensidade)*vEspaco/2);
          i += precisao / (intensidade + 0.01) / 20;
          fase +=0.01;
        }
      }
    }
    endShape();
  }
  saveFrame("################.png");
}
