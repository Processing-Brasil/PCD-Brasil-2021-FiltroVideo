import processing.video.*;
import com.hamoid.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.spi.*;

final String videoIn = "teste.mp4";//arquivo de video para gerar as ondas
final String videoOut = "data/exportado.mp4";//arquivo exportado
final String audioIn = "musica.mp3";//arquivo que influenciará nas vibrações
final String audioOut = "musica.mp3";//arquivo que será exportado no video final

final int vEspaco = 10;
final float precisao = 1;

int frame = 1;
Movie mov;

//ref:
//https://funprogramming.org/VideoExport-for-Processing/
VideoExport videoExport;

//http://code.compartmental.net/tools/minim/
Minim minim;
float[][] spectra;
final int MAX_AUDIO_LEVEL = 156;
final int MAX_FFT_INDEX = 150;//max 512
final float VIDEO_TO_AUDIO_FRAME = 1.955;//número mágico para sincronizar frames

void setup() {
  size(1920, 1080);
  mov = new Movie(this, videoIn);
  mov.play();
  mov.jump(0);
  mov.pause();
  
  videoExport = new VideoExport(this, videoOut);
  videoExport.setFrameRate(mov.frameRate);
  videoExport.setAudioFileName(audioOut);
  videoExport.startMovie();
  
  minim = new Minim(this);
  AudioSample audio = minim.loadSample(audioIn, 2048);
  analyzeUsingAudioSample(audio);
  audio.close(); 
  
  setFrame(frame);
  
  noiseSeed(0);
}

void draw() {
  if (frame >= getLength()) {
    //acabou
    videoExport.endMovie();
    exit();
  }
  
  
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
      
      //converte o fft para strokeWeight
      int audioFrame = floor(frame * VIDEO_TO_AUDIO_FRAME);
      float audioAmp = 1;
      if(audioFrame < spectra.length){
        int fftIndex = floor(map(y, 0, mov.height, MAX_FFT_INDEX, 0));
        println(fftIndex);
        final int framesAoRedor = 2;
        int inicio = fftIndex < framesAoRedor ? 0 : -framesAoRedor; 
        for(int i = inicio; i <= framesAoRedor; i++){
          audioAmp += map(spectra[audioFrame][fftIndex + i], 0, MAX_AUDIO_LEVEL, 0, 2);
        }
      }
      strokeWeight(audioAmp);
      
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
    setFrame(frame);
    
    noStroke();
    fill(0);
    rect(10, 10, 250, 115);
    fill(255);
    textSize(20);
    text("Concluído: " + ((getFrame() * 100 / (getLength() - 1))/100.f) + "%", 20, 35);
    text("Total de frames: " + (getLength() - 1), 20, 55);
    text("Frame do video: " + getFrame(), 20, 75);
    text("Frame: " + frame, 20, 95);
    text("Frame Diff: " + (frame - getFrame()), 20, 115);
    
    //visualizacao do fft do audio
    int audioFrame = floor(frame * VIDEO_TO_AUDIO_FRAME);
    if(audioFrame < spectra.length){
      noStroke();
      fill(#004aa3);
      beginShape();
      vertex(0, mov.height);
      for(int i = 0; i < spectra[audioFrame].length-1; ++i )
      {
        float x = map(i, 0, spectra[audioFrame].length-1, 0, mov.width);
        float y = map(spectra[audioFrame][i], 0, MAX_AUDIO_LEVEL, mov.height, 0);
        vertex(x, y);
      }
      vertex(mov.width, mov.height);
      endShape();
    }
  }else{ 
    setFrame(frame);
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
  return ceil(mov.time() *  mov.frameRate);
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


//extracted from offlineAnalysis that comes with Minim library
void analyzeUsingAudioSample(AudioSample audio)
{  
  // get the left channel of the audio as a float array
  // getChannel is defined in the interface BuffereAudio, 
  // which also defines two constants to use as an argument
  // BufferedAudio.LEFT and BufferedAudio.RIGHT
  float[] leftChannel = audio.getChannel(AudioSample.LEFT);
  
  // then we create an array we'll copy sample data into for the FFT object
  // this should be as large as you want your FFT to be. generally speaking, 1024 is probably fine.
  int fftSize = 1024;
  float[] fftSamples = new float[fftSize];
  FFT fft = new FFT( fftSize, audio.sampleRate() );
  
  // now we'll analyze the samples in chunks
  int totalChunks = (leftChannel.length / fftSize) + 1;
  
  // allocate a 2-dimentional array that will hold all of the spectrum data for all of the chunks.
  // the second dimension if fftSize/2 because the spectrum size is always half the number of samples analyzed.
  spectra = new float[totalChunks][fftSize/2];
  
  for(int chunkIdx = 0; chunkIdx < totalChunks; ++chunkIdx)
  {
    int chunkStartIndex = chunkIdx * fftSize;
   
    // the chunk size will always be fftSize, except for the 
    // last chunk, which will be however many samples are left in source
    int chunkSize = min( leftChannel.length - chunkStartIndex, fftSize );
   
    // copy first chunk into our analysis array
    System.arraycopy( leftChannel, // source of the copy
               chunkStartIndex, // index to start in the source
               fftSamples, // destination of the copy
               0, // index to copy to
               chunkSize // how many samples to copy
              );
      
    // if the chunk was smaller than the fftSize, we need to pad the analysis buffer with zeroes        
    if ( chunkSize < fftSize )
    {
      // we use a system call for this
      java.util.Arrays.fill( fftSamples, chunkSize, fftSamples.length - 1, 0.0 );
    }
    
    // now analyze this buffer
    fft.forward( fftSamples );
   
    // and copy the resulting spectrum into our spectra array
    for(int i = 0; i < 512; ++i)
    {
      spectra[chunkIdx][i] = fft.getBand(i);
    }
  }
}
