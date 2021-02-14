import processing.video.*;
import com.hamoid.*;

int vEspaco = 10;
float precisao = 1;
int frame = 1;
Movie mov;

//ref:
//https://funprogramming.org/VideoExport-for-Processing/
VideoExport videoExport;

void setup() {
  size(1920, 1080);
  mov = new Movie(this, "montagem-depoimentos-pcd2021-alto-contraste-baixa.mp4");
  mov.play();
  mov.jump(0);
  mov.pause();
  
  videoExport = new VideoExport(this, "data/exportado.mp4");
  videoExport.setFrameRate(mov.frameRate);
  videoExport.startMovie();
  
  noiseSeed(0);
}

void draw() {
  if (frame >= getLength()) {
    //acabou
    videoExport.endMovie();
    exit();
  }
  
  setFrame(frame);
  
  if (mov.available() == true) {
    mov.read();
    mov.loadPixels();
    
    float zoom = max((float)width/(float)mov.width, (float)height/(float)mov.height);
    scale(zoom);
    
    background(#e6e6d8);
    noFill();
    
    float tempo = (float)frame / mov.frameRate * 3.0;
    
    //ondas
    stroke(#ff666c);
    for (int y = -vEspaco; y < mov.height + vEspaco; y += vEspaco * 2) {
      float comprimento = 0;
      beginShape();
      for (int x = 0; x < mov.width; x += 2) {
        float y_sin = sin(comprimento + tempo) * vEspaco * 2 + y;
        vertex(x, y_sin);
        comprimento += 0.1;
      }
      endShape();
    }

    //video em frequencias
    
    for (int y = 0; y < mov.height; y+=vEspaco) {
      float x = 0;
      float _y = y;
      float fase = noise(y) * TWO_PI;
      
      noFill();
      stroke(#004aa3);
      strokeWeight(1);
      beginShape();
      while (x < mov.width) {
        color col = mov.get(floor(x), y);
        float r = red(col);
        float g = green(col);
        float b = blue(col);
        float intensidade = 1 - ((r + g + b) / 765);
        _y = y + sin(fase - intensidade - tempo) * vEspaco / 2 + vEspaco / 2;
        
        vertex(x, _y);
        x += precisao / (intensidade + 0.01) / 5;
        fase += 0.5;
      }
      vertex(mov.width, _y);
      endShape();
      
    }
    
    videoExport.saveFrame();
  
    frame++;
    
    fill(#004aa3);
    textSize(100);
    text(getFrame() + " / " + (getLength() - 1), 10, 100);
  }
}

void keyPressed() {
  if (key == 'q') {
    videoExport.endMovie();
    exit();
  }
}

//ref:
//https://github.com/processing/processing-video/blob/master/examples/Movie/Frames/Frames.pde

int getLength() {
  return int(mov.duration() * mov.frameRate);
}

int getFrame() {    
  return ceil(mov.time() * 30) - 1;
}

void setFrame(int n) {
  mov.play();
    
  // The duration of a single frame:
  float frameDuration = 1.0 / mov.frameRate;
    
  // We move to the middle of the frame by adding 0.5:
  float where = (n + 0.5) * frameDuration; 
    
  // Taking into account border effects:
  float diff = mov.duration() - where;
  if (diff < 0) {
    where += diff - 0.25 * frameDuration;
  }
    
  mov.jump(where);
  mov.pause();  
}  
