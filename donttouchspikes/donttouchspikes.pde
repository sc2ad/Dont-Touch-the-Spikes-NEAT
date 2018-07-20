int width = 1500;
int height = 1000;
int maxSpikes = 12;
float spikeHeight = height / maxSpikes;
float spikeWidth = 20;
float birdWidth = 20;
float birdHeight = 20;

float STARTING_VX = 7;
float STARTING_VY = -2;
float GRAVITY = 0.3;
float JUMP_V = 6;

float xAccel = 0.2;
float speedIncreaseLevels = 2;
float spikeIncreaseLevels = 5;

// NEAT PARAMS:
// For Genome:
float RE_RANDOMIZE_WEIGHT_CHANCE = 0.1;
float WEIGHT_MUTATION_CHANCE = 0.7;
float ADD_CONNECTION_CHANCE = 0.1;
float ADD_NODE_CHANCE = 0.01;
// For Population:
int EXTINCTION_SAVE_TOP = 5; // The number of Species to save when a mass extinction occurs
UpdateType POPULATION_UPDATE_TYPE = UpdateType.ALL;

// For Player Names:
String organismNamesFile = "organismNames.txt";
String[] ORGANISM_NAMES;
HashMap<String, Integer> organismHash = new HashMap<String, Integer>();
// For Species Names:
String speciesNamesFile = "speciesNames.txt";
String[] SPECIES_NAMES;
HashMap<String, Integer> speciesHash = new HashMap<String, Integer>();

int spikeCount = 8; // Number of spikes to start with
int populationSize = 500; // Number of Players inside of population

public Spike[] spikes = drawSpikes(width - spikeWidth, 2); // This holds the active spikes to display on the screen
public ArrayList<Spike[]> existingSpikes = new ArrayList<Spike[]>(); // This holds all of the spikes that have already been shown before, for consistency between organisms when doing UpdateType.SINGLE

Population pop;

int speed = 60; //FPS
boolean showBest = false;//true if only show the best of the previous generation
boolean runBest = false; //true if replaying the best ever game
boolean humanPlaying = false; //true if the user is playing

Player humanPlayer;

boolean runThroughSpecies = false;
int upToSpecies = 0;
Player speciesChamp;

boolean showBrain = true;

boolean showBestEachGen = false;
int upToGen = 0;
Player genPlayerTemp;

boolean showNothing = false;
boolean showLearningGraph = false;
ArrayList<Integer> scoresToSave = new ArrayList<Integer>();
int numToSave = 10;
boolean paused = false;

int genToLoad = 0;
String SAVE_ALL_DIRECTORY = "C:/Users/Sc2ad/Documents/Processing/donttouchspikes/Data/";
int SAVE_ALL_FREQUENCY = 10;

// MAKE A PLATFORMER TO TRULY TEST:
/*
GREEN SQUARE = CENTER (OR CLOSE)
RED SQUARES = SPIKES
GROUND, WHICH IS ABOVE THE GROUND FOR Y
*/

void setup() {
  ORGANISM_NAMES = getStringsFromFile(organismNamesFile);
  organismHash = getHash(ORGANISM_NAMES);
  SPECIES_NAMES = getStringsFromFile(speciesNamesFile);
  speciesHash = getHash(SPECIES_NAMES);
  spikes = drawSpikes(width - spikeWidth, spikeCount);
  existingSpikes.add(spikes);
  size(1500,1000);
  stroke(255);
  background(0,0,0);
  spikeCount = 8;
  pop = new Population(populationSize);
  humanPlayer = new Player();
}

void draw() {
  background(0,0,0);
  drawToScreen();
  noStroke();
  if (showBestEachGen) {//show the best of each gen
    if (!genPlayerTemp.dead) {//if current gen player is not dead then update it
      if (!paused) {
        genPlayerTemp.look();
        genPlayerTemp.think();
        genPlayerTemp.update();
      }
      genPlayerTemp.show();
      genPlayerTemp.shouldUpdateSpikes();
    } else {//if dead move on to the next generation
      upToGen ++;
      if (upToGen >= pop.genPlayers.size()) {//if at the end then return to the start and stop doing it
        upToGen= 0;
        showBestEachGen = false;
      } else {//if not at the end then get the next generation
        genPlayerTemp = pop.genPlayers.get(upToGen).cloneForReplay();
      }
    }
  } else if (runThroughSpecies ) {//show all the species 
      if (!speciesChamp.dead) {//if best player is not dead
        if (!paused) {
          speciesChamp.look();
          speciesChamp.think();
          speciesChamp.update();
        }
        speciesChamp.show();
        speciesChamp.shouldUpdateSpikes();
      } else {//once dead
        upToSpecies++;
        if (upToSpecies >= pop.species.size()) { 
          runThroughSpecies = false;
        } else {
          speciesChamp = pop.species.get(upToSpecies).champ.cloneForReplay();
        }
      }
  } else {
    if (humanPlaying) {//if the user is controling the ship[
      if (!humanPlayer.dead) {//if the player isnt dead then move and show the player based on input
        if (!paused) {
          humanPlayer.look();
          humanPlayer.update();
        }
        humanPlayer.show();
      } else {//once done return to ai
        humanPlaying = false;
      }
    } else if (runBest) {// if replaying the best ever game
      if (!pop.bestPlayer.dead) {//if best player is not dead
        if (!paused) {
          pop.bestPlayer.look();
          pop.bestPlayer.think();
          pop.bestPlayer.update();
        }
        pop.bestPlayer.show();
        pop.bestPlayer.shouldUpdateSpikes();
      } else {//once dead
        runBest = false;//stop replaying it
        pop.bestPlayer = pop.bestPlayer.cloneForReplay();//reset the best player so it can play again
      }
    } else {//if just evolving normally
      if (!pop.done()) {//if any players are alive then update them
        int shouldUpdate = pop.shouldUpdateSpikes();
        if (shouldUpdate > 0) {
          println("should put spikes on the right");
        } else if (shouldUpdate == 0) {
          println("should put spikes on the left");
        }
        pop.updateAlive();
        if (pop.updateType == UpdateType.ALL) {
          if (shouldUpdate > -1)
          spikes = drawSpikes(shouldUpdate, spikeCount);
        } else if (pop.updateType == UpdateType.SINGLE) {
          
          if (pop.getCurrentPlayer().dead) {
            spikeCount = 8;
            pop.currentIndex++;
            println("Updated Population Player to: "+pop.currentIndex);
            if (pop.currentIndex >= pop.pop.size()) {
              println("Stopping because out of bounds!");
              return; // Avoid out of bounds
            }
            spikes = drawExistingSpikes(width - spikeWidth, spikeCount, 0);
          }
          // Need to make sure that all organisms get the same RANDOM spikes for this generation
          // Every generation the spikes can reset
          // The score of the currentIndex is passed in to determine the index of the spike array.
          if (shouldUpdate > -1) {
            spikes = drawExistingSpikes(shouldUpdate, spikeCount, pop.getCurrentPlayer().score);
            println("Score update! Score: "+pop.getCurrentPlayer().score);
          }
          fill(color(255,255,255));
          textSize(10);
          text("X: "+pop.getCurrentPlayer().x,10,10);
          text("Y: "+pop.getCurrentPlayer().y,10,25);
          text("spd: "+pop.getCurrentPlayer().vx,10,40);
          text("yV: "+pop.getCurrentPlayer().vy,10,55);
          
        }
        for (Spike s : spikes) {
          s.draw();
        }
      } else {//all dead
        //genetic algorithm 
        if ((pop.gen) % SAVE_ALL_FREQUENCY == 0) {
          pop.saveAll(SAVE_ALL_DIRECTORY);
        }
        scoresToSave.add(pop.getCurrentPlayer().score); // Will only be the best one if not running in SINGLE
        if (scoresToSave.size() > numToSave) {
          scoresToSave.remove(0);
        }
        pop.naturalSelection();
        spikeCount = 8;
        spikes = drawSpikes(width - spikeWidth, spikeCount);
        if ((pop.gen-1) % SAVE_ALL_FREQUENCY == 0) {
          println("SAVED!");
        }
      }
      
      
    }
  } 
}
void drawToScreen() {
  if (!showNothing) {
   //pretty stuff
    //<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<replace
    if (!pop.done()) {
      if (showBrain)
      drawBrain();
      writeInfo();
    }
    drawGraph();
  }
}
void drawBrain() {  //show the brain of whatever genome is currently showing
  int startX = width/2-200;
  int startY = 80;
  int w = 400;
  int h = 200;
  if (runThroughSpecies) {
    speciesChamp.brain.drawGenome(startX,startY,w,h);
  } else if (runBest) {
    pop.bestPlayer.brain.drawGenome(startX,startY,w,h);
  } else if (humanPlaying) {
    showBrain = false;
  } else if (showBestEachGen) {
    genPlayerTemp.brain.drawGenome(startX,startY,w,h);
  } else {
    pop.getCurrentPlayer().brain.drawGenome(startX,startY,w,h);
  }
}
void drawGraph() {
  int graphX = 50;
  int graphY = height-250;
  int graphWidth = 200;
  int graphHeight = 200;
  int xInterval = graphWidth / numToSave;
  int maxScore = 0;
  for (int i = 0; i < scoresToSave.size(); i++) {
    if (scoresToSave.get(i) > maxScore) {
      maxScore = scoresToSave.get(i);
    }
  }
  int yInterval = graphHeight / (maxScore+1);
  if (showLearningGraph) {
    stroke(255);
    line(graphX,graphY,graphX,graphY+graphHeight);
    line(graphX,graphY+graphHeight,graphX+graphWidth,graphY+graphHeight);
    textSize(15);
    textAlign(LEFT);
    text(maxScore,graphX-30,graphY+10);
    if (scoresToSave.size() >= 2) {
      for (int i = 0; i < scoresToSave.size()-1; i++) {
        line(graphX+xInterval * i,graphY+graphHeight-yInterval*scoresToSave.get(i), graphX+xInterval*(i+1), graphY+graphHeight-yInterval*scoresToSave.get(i+1));
        line(graphX+xInterval * i,graphY+graphHeight+3,graphX+xInterval * i,graphY+graphHeight-3);
        textAlign(CENTER);
        text(pop.gen-scoresToSave.size()+i,graphX+xInterval * i,graphY+graphHeight+15);
      }
      line(graphX+xInterval * (scoresToSave.size()-1),graphY+graphHeight+3,graphX+xInterval * (scoresToSave.size()-1),graphY+graphHeight-3);
      text(pop.gen-1,graphX+xInterval * (scoresToSave.size()-1),graphY+graphHeight+15);
    }
  }
}
void writeInfo() {
  fill(200);
  textAlign(LEFT);
  textSize(20);
  String score = "";
  String gen = "";
  String speciesName = "";
  String orgName = "";
  if (showBestEachGen) {
    score += genPlayerTemp.score;
    gen += (genPlayerTemp.gen +1);
  } else if (runThroughSpecies) {
      score += speciesChamp.score;
      text("Species: " + (upToSpecies +1), 1150, 50);
      text("Players in this Species: " + pop.species.get(upToSpecies).players.size(), 50, height/2 + 200);
  } else if (humanPlaying) {
    score += humanPlayer.score;
  } else if (runBest) {
    score += pop.bestPlayer.score;
    gen += pop.gen;
    speciesName = pop.bestPlayer.speciesName;
    orgName = pop.bestPlayer.name;
  } else {
    if (showBest) {
      score += pop.pop.get(0).score;
      gen += pop.gen;
      speciesName = pop.pop.get(0).speciesName;
      orgName = pop.pop.get(0).name;
    } else {
      gen += pop.gen;
      score += pop.getCurrentPlayer().score;
      speciesName = pop.getCurrentPlayer().speciesName;
      orgName = pop.getCurrentPlayer().name;
    }
  }
  text("Score: " + score, 650, 40);
  text("Gen: " + gen, 1150, 40);
  text("Current Species ("+pop.species.size()+"): " + speciesName, 50, 40);
  text("Current Organism ("+(pop.currentIndex+1)+"/"+pop.pop.size()+"): " + orgName, 50, 80);
  text("Global Best Score: " + pop.bestScore, 50, 150);
}

// Draws a singular Spike with proper positioning (creates a Spike object)
Spike drawSpike(float sideOffset, int num) {
  if (num < 0 || num > maxSpikes-1) {
    // This breaks lots of things
    throw new IllegalArgumentException("UhOh: "+num);
  }
  return new Spike(sideOffset, num * spikeHeight, spikeWidth, spikeHeight);
}
// Draws all of the Spikes with proper positioning (creates Spike array)
Spike[] drawSpikes(float offset, int count) {
  Spike[] spikes = new Spike[count];
  for (int i = 0; i < count; i++) {
    spikes[i] = drawSpike(offset, (int)(Math.random() * maxSpikes));
  }
  return spikes;
}

Spike[] drawExistingSpikes(float offset, int count, int indexToCheck) {
  if (indexToCheck < existingSpikes.size()) {
    // This index can be used!
    println("GETTING INDEX: "+indexToCheck+" with X: "+existingSpikes.get(indexToCheck)[0].x);
    return existingSpikes.get(indexToCheck);
  }
  println("Creating spikes at xOffset: "+offset+" with old size: "+existingSpikes.size()+" and new size: "+(existingSpikes.size()+1));
  Spike[] spikesCreated = drawSpikes(offset, count);
  existingSpikes.add(spikesCreated);
  return spikesCreated;
  // Should not error, if it does, this loop is behind 2 or more iterations
}

void mousePressed() {
  if (humanPlaying) {
    if (humanPlayer.dead) {
      // Add the last array of spikes for redundancy
      humanPlayer.replaySpikes.add(spikes);
      humanPlayer = new Player();
      humanPlaying = false;
    } else {
      humanPlayer.jump();
    }
  }
}
void keyPressed() {
  switch(key) {
  case ' ':
    //toggle showBest
    showBest = !showBest;
    break;
  case '+'://speed up frame rate
    speed += 10;
    frameRate(speed);
    println(speed);
    break;
  case '-'://slow down frame rate
    if (speed > 10) {
      speed -= 10;
      frameRate(speed);
      println(speed);
    }
    break;
  case 'b'://run the best
    runBest = !runBest;
    break;
  case 's'://show species
    runThroughSpecies = !runThroughSpecies;
    upToSpecies = 0;
    speciesChamp = pop.species.get(upToSpecies).champ.cloneForReplay();
    break;
  case 'g'://show generations
    showBestEachGen = !showBestEachGen;
    upToGen = 0;
    genPlayerTemp = pop.genPlayers.get(upToGen).cloneForReplay();
    break;
  case ','://decrease species/gen to replay
    if (showBestEachGen) {
      upToGen--;
      genPlayerTemp = pop.genPlayers.get(upToGen).cloneForReplay();
    }
    else if (runThroughSpecies) {
      upToSpecies--;
      speciesChamp = pop.species.get(upToSpecies).champ.cloneForReplay();
    } else {
      genToLoad--;
      println("Gen to load: "+genToLoad);
    }
    break;
  case '.'://increase species/gen to replay
    if (showBestEachGen) {
      upToGen++;
      if (upToGen < pop.genPlayers.size()) {
        genPlayerTemp = pop.genPlayers.get(upToGen).cloneForReplay();
      } else {
        showBestEachGen = false;
      }
    }
    else if (runThroughSpecies) {
      upToSpecies++;
      speciesChamp = pop.species.get(upToSpecies).champ.cloneForReplay();
    } else {
      genToLoad++;
      println("Gen to load: "+genToLoad);
    }
    break;
  case 'n'://show absolutely nothing in order to speed up computation
    showNothing = !showNothing;
    break;
  case 'p'://pauses/unpauses
    paused = !paused;
    break;
  case 'a'://saves best player to file
    saveToFile(pop.bestPlayer, "bestPlayer.pl");
    break;
  case 'l'://loads best player from file
    pop.bestPlayer = readFromFile("bestPlayer.pl").cloneForReplay();
    print(pop.bestPlayer.brain.network.size());
    runBest = true;
    break;
  case 'S':
    pop.saveAll(SAVE_ALL_DIRECTORY);
    break;
  case 'L':
    pop.loadAll(SAVE_ALL_DIRECTORY, genToLoad);
    break;
  case 'e':
    showLearningGraph = !showLearningGraph;
    break;
  }
}
// Gets Names from file
String[] getStringsFromFile(String filename) {
  ArrayList<String> strings = new ArrayList<String>();
  try {
    BufferedReader br = createReader(filename);
    String st;
    while ((st = br.readLine()) != null) {
      if (!st.startsWith("#")) {
        strings.add(st);
      }
    }
  } catch (IOException e) {
    println("Could not read file: "+filename);
  }
  if (strings.size() == 0) {
    println("Read 0 strings!");
    return null;
  }
  String[] out = new String[strings.size()];
  for (int i = 0; i < strings.size(); i++) {
    out[i] = strings.get(i);
  }
  return out;
}
// Creates a HashMap from String names
HashMap<String, Integer> getHash(String[] names) {
  HashMap<String,Integer> nameUses = new HashMap<String,Integer>();
  for (int i = 0; i < names.length; i++) {
    nameUses.put(names[i], 0);
  }
  return nameUses;
}
// Takes a map and returns a unique name
String getUniqueName(HashMap<String, Integer> map) {
  int randIndex = (int)random(map.size());
  String randName = "";
  int i = 0;
  for (String o : map.keySet()) {
    if (i == randIndex) {
      randName = o;
      break;
    }
    i++;
  }
  int suffix = map.get(randName);
  map.put(randName,suffix+1);
  if (suffix == 0) {
    return randName;
  }
  return randName+suffix;
}
// Uses Organism HashMap to create a Unique name
String getUniqueOrganismName() {
  return getUniqueName(organismHash);
}
// Uses Species HashMap to create a Unique name
String getUniqueSpeciesName() {
  return getUniqueName(speciesHash);
}
void saveToFile(Player p, String location) {
  PrintWriter writer = createWriter(location);
  writer.println(p);
  writer.flush();
  writer.close();
  println("Wrote a player to: "+location);
}
Player readFromFile(String location) {
  BufferedReader reader = createReader(location);
  Player p = null;
  try {
    String line = null;
    while ((line = reader.readLine()) != null) {
      if (line.contains("P<")) {
        p = playerFromString(line);
        break;
      }
    }
  } catch (IOException e) {
    e.printStackTrace();
  }
  return p;
}
