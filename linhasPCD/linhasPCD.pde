import processing.video.*;

int vEspaco = 10;
Movie mov;
int precisao = 1;
int frame = 1;

void setup() {
  size(854, 480);
  mov = new Movie(this, "teste.mp4");
  mov.play();
  mov.jump(0);
  mov.pause();
  
  noFill();
  stroke((#ff666c));
}

void draw() {
  background((#004aa3));
  if (frame >= getLength()) return;//acabou
  setFrame(frame);
  
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
    frame++;
    saveFrame("################.png");
  }
  text(getFrame() + " / " + (getLength() - 1), 10, 30);
}


//ref:
//https://github.com/processing/processing-video/blob/master/examples/Movie/Frames/Frames.pde
void movieEvent(Movie m) {
  m.read();
}

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
