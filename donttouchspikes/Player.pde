// TIME TO IMPLEMENT NEAT FOR DONT TOUCH THE SPIKES!
/*
Inputs: PlayerX, PlayerY, PlayerXSpeed, PlayerYSpeed, SpikeLocations (0,1 if spike there)
OR distance to spike in front of, above, and below dood?
Outputs: Do i jump? 0-1 (>0.5 = jump)

fitness = score (fitness increases as score increases?)

make sure to be able to replay if desired (save spike locations to arr)
make player able to play
make brain visualizable

Implement NEAT here!
*/

int inputs = 8;
int outputs = 1;

class Player {
  float fitness = -1; // Default so that it is known when fitness isn't calculated
  float unadjustedFitness;
  Genome brain;
  ArrayList<Float[]> replayActions = new ArrayList<Float[]>();
  float[] vision = new float[inputs];
  float[] actions = new float[outputs];
  int lifespan = 0;
  int bestScore = 0;
  boolean dead = false;
  boolean replay = false;
  int gen = 0;
  int score = 0;
  String name;
  String speciesName = "Not yet defined";
  
  float x, y;
  float vx, vy;
  
  ArrayList<Spike[]> replaySpikes = new ArrayList<Spike[]>();
  
  public Player() {
    brain = new Genome(inputs, outputs);
    vx = STARTING_VX;
    vy = STARTING_VY;
    x = width/2-birdWidth/2;
    y = height/2-birdHeight/2;
    name = getUniqueOrganismName();
  }
  void show() {
    fill(color(0,255,0));
    rect(x,y,birdWidth,birdHeight);
    if (replay) {
      for (Spike s : replaySpikes.get(score)) {
        s.draw();
      }
    }
  }
  void move() {
    x += vx;
    vy += GRAVITY;
    y += vy;
    
    // Checks collisions
    if (y < 0 || y > height - birdHeight) {
      // Game lost from top/bottom
      System.out.println("Death from Top/Bottom!");
      dead = true;
      return;
    }
    if (!replay) {
      for (int i = 0; i < spikes.length; i++) {
        if (spikes[i].check(x,y) || spikes[i].check(x+birdWidth,y) || spikes[i].check(x,y+birdHeight) || spikes[i].check(x+birdWidth,y+birdHeight)) {
          // Spike collision happened! Kill player
          System.out.println("Death from spike!");
          dead = true;
          return;
        }
      }
    } else {
      // If replaying, check collisions of the real spikes
      // Use score as index accessor
      /*
      for (int i = 0; i < replaySpikes.get(score).length; i++) {
        if (replaySpikes.get(score)[i].check(x,y) || replaySpikes.get(score)[i].check(x+birdWidth,y) || replaySpikes.get(score)[i].check(x,y+birdHeight) || replaySpikes.get(score)[i].check(x+birdWidth,y+birdHeight)) {
          // Spike collision happened! Kill player
          System.out.println("Death from replay spike!");
          dead = true;
          return;
        }
      }
      */
      if (score == replaySpikes.size()) {
        dead = true;
      }
    }
    lifespan++;
  }
  // Returns location where the spikes should be drawn. This will occur as long as the returned value >= 0
  int shouldUpdateSpikes() {
    if (!replay) {
      if (x < 0 || x + birdWidth > width) {
        vx = -vx;
        score++;
        if (score % spikeIncreaseLevels == 0 && spikeCount < maxSpikes-1) {
          spikeCount++;
        }
        if (score % speedIncreaseLevels == 0) {
          vx = vx < 0 ? vx - xAccel : vx + xAccel;
        }
        int retVal = x < 0 ? (int)(width-spikeWidth) : 0;
        x += vx; // To move it off of the wall so it doesn't collide again
        return retVal;
      }
    } else {
      if (x < 0 || x + birdWidth > width) {
        vx = -vx;
        score++;
        println("Replay score: "+score);
        if (score == replaySpikes.size()) {
          dead = true; // Kill it as a failsafe to avoid index out of bounds errors
        }
        if (score % speedIncreaseLevels == 0) {
          vx = vx < 0 ? vx - xAccel : vx + xAccel;
        }
        int retVal = x < 0 ? (int)(width-spikeWidth) : 0;
        x += vx; // To move it off of the wall so it doesn't collide again
        return retVal;
      }
    }
    return -1;
  }
  void update() {
    // Updates sprite
    move();
    
  }
  void look() {
    // Updates vision array with proper values each frame
    // LAST STEP!
    /*
    Inputs: PlayerX, PlayerY, PlayerXSpeed, PlayerYSpeed, SpikeLocations (0,1 if spike there)
    OR distance to spike in front of, above, and below dood?
    Outputs: Do i jump? 0-1 (>0.5 = jump)
    */
    vision[0] = (float)x/((float)width);
    vision[1] = (float)y/((float)height);
    vision[2] = abs(vx); // might not want abs?
    vision[3] = vy;
    /*
    // Spike above bird
    vision[4] = distToSpike(-1);
    // Spike in front of bird
    vision[5] = distToSpike(0);
    // Spike below bird
    vision[6] = distToSpike(1);
    */
    /*
    // Is spike? above bird
    vision[7] = getSpike(-1) != null ? 1 : 0;
    // Is spike? in front of bird
    vision[8] = getSpike(0) != null ? 1 : 0;
    // Is spike? below bird
    vision[9] = getSpike(1) != null ? 1 : 0;
    */
    // Is gap? above bird
    vision[4] = getSpike(-1) == null ? 1 : 0;
    // Is gap? in front of bird
    vision[5] = getSpike(0) == null ? 1 : 0;
    // Is gap? below bird
    vision[6] = getSpike(1) == null ? 1 : 0;
    // Direction to nearest gap. 1 = Up, -1 = Down, 0 = forward
    vision[7] = directionToNearestGap();
  }
  private Spike getSpike(int yoffset) {
    int testX = vx > 0 ? (int)(width-spikeWidth/2) : (int)spikeWidth/2;
    if (y + yoffset * spikeHeight < 0 || y + yoffset * spikeHeight > height) {
      // Spike out of bounds, pretend it exists so bot learns not to think it is safe to jump off the screen
      return new Spike(testX,y + yoffset * spikeHeight, spikeWidth, spikeHeight);
    }
    if (!replay) {
      for (Spike s : spikes) {
        if (s.check(testX,y + yoffset * spikeHeight) || s.check(testX,y + yoffset * spikeHeight + birdHeight)) {
          // There is a spike at the level
          return s;
        }
      }
    } else {
      for (Spike s : replaySpikes.get(score)) {
        if (s.check(testX,y + yoffset * spikeHeight) || s.check(testX,y + yoffset * spikeHeight + birdHeight)) {
          // There is a spike at the level
          return s;
        }
      }
    }
    return null;
  }
  private float distToSpike(int yOffset) {
    Spike s = getSpike(yOffset);
    if (s == null) {
      return vx > 0 ? dist(x + birdWidth, y, width, y) : dist(x, y, 0, y);
    }
    return vx > 0 ? dist(x + birdWidth, y, s.x, y + yOffset * spikeHeight) : dist(x, y, s.x+spikeWidth, y + yOffset * spikeHeight);
  }
  private float directionToNearestGap() {
    for (int i = 0; i < maxSpikes; i++) {
      if (getSpike(i) == null) {
        return i > 0 ? -1 : 0;
      }
      if (getSpike(-i) == null) {
        return -i < 0 ? 1 : 0;
      }
    }
    return 0;
  }
  // Jumps if it decides to jump
  void think() {
    float max = 0;
    int maxIndex = 0;
    //get the output of the neural network
    actions = brain.feedForward(vision);
    if (replay) {
      //println(vision);
      for (int i = 0; i < actions.length; i++) {
        if (lifespan >= replayActions.size()) {
          dead = true;
          return;
        }
        actions[i] = replayActions.get(lifespan)[i];
      }
    }

    Float[] temp = new Float[actions.length];
    for (int i = 0; i < actions.length; i++) {
      if (actions[i] > max) {
        max = actions[i];
        maxIndex = i;
      }
      temp[i] = actions[i];
    }
    if (!replay) {
      replayActions.add(temp);
    }
    
    if (max > 0.5) {
      // Jump if at least 50%
      jump();
    }
    // maybe store outputs to array when replaying instead? that way when it thinks it just replays... avoids possible collision issues?
  }
  void jump() {
    if (!dead) {
      vy = -JUMP_V;
    }
  }
  // Clones player
  Player clone() {
    Player out = new Player();
    out.replay = false;
    out.fitness = fitness;
    out.gen = gen;
    out.bestScore = score;
    out.brain = brain.clone();
    return out;
  }
  // Clones for replaying
  Player cloneForReplay() {
    Player out = new Player();
    out.replaySpikes = (ArrayList)replaySpikes.clone();
    out.replayActions = (ArrayList)replayActions.clone();
    out.replay = true;
    out.fitness = fitness;
    out.gen = gen;
    out.bestScore = score;
    out.brain = brain.clone();
    out.name = name;
    out.speciesName = speciesName;
    out.score = 0;
    return out;
  }
  // Calculates fitness
  void calculateFitness() {
    fitness = (2 * score) * (2 * score) + lifespan;
  }
  // Getter method for fitness (rarely used)
  float getFitness() {
    if (fitness < 0) {
      calculateFitness();
    }
    return fitness;
  }
  // Crossover function - less fit parent is parent2
  Player crossover(Player parent2) {
    Player child = new Player();
    
    child.brain = brain.crossover(parent2.brain);
    child.brain.generateNetwork();
    
    return child;
  }
  String toString() {
    String out = "P<Name:"+name;
    out += ", speciesName:"+speciesName;
    out += ", gen:"+gen;
    out += ", fitness:"+fitness;
    out += ", bestScore:"+bestScore;
    out += ", replay:"+replay;
    out += ", ACTIONS:`";
    for (Float[] f : replayActions) {
      out += "<";
      for (int i = 0; i < f.length; i++) {
        out += f[i]+", ";
      }
      out = out.substring(0, out.length()-2); // Removes ", " at end
      out += ">, ";
    }
    out = out.substring(0, out.length()-2); // Removes ", " at end
    out += ",, SPIKES:"+spikesToString(replaySpikes);
    out += ", "+brain+">";
    return out;
  }
}

Player playerFromString(String str) {
  try {
    str = str.split("P<")[1];
    String name = str.split("Name:")[1].split(", ")[0];
    String speciesName = str.split("speciesName:")[1].split(", ")[0];
    int gen = Integer.parseInt(str.split("gen:")[1].split(", ")[0]);
    float fitness = Float.parseFloat(str.split("fitness:")[1].split(", ")[0]);
    int bestScore = Integer.parseInt(str.split("bestScore:")[1].split(", ")[0]);
    boolean replay = Boolean.parseBoolean(str.split("replay:")[1].split(", ")[0]);
    String forActions = str.split(", ACTIONS:`")[1].split(", SPIKES")[0];
    ArrayList<Float[]> replayActions = new ArrayList<Float[]>();
    while (forActions.contains(">")) {
      String singleton = forActions.split("<")[1].split(">")[0];
      String[] arr = singleton.split(", "); // Gets all of the floats individually
      if (arr.length == 0) {
        arr = new String[]{singleton};
      }
      int len = arr.length;
      Float[] floats = new Float[len];
      for (int i = 0; i < len; i++) {
        floats[i] = Float.parseFloat(arr[i]);
      }
      replayActions.add(floats);
      forActions = forActions.substring(forActions.indexOf(">")+1, forActions.length());
    }
    String forSpikes = str.split("SPIKES:")[1];
    ArrayList<Spike[]> replaySpikes = spikesFromString(forSpikes);
    Genome brain = genomeFromString(forSpikes);
    Player out = new Player();
    out.replaySpikes = (ArrayList)replaySpikes.clone();
    out.replayActions = (ArrayList)replayActions.clone();
    out.replay = false;
    out.fitness = fitness;
    out.gen = gen;
    out.bestScore = bestScore;
    out.brain = brain.clone();
    out.name = name;
    out.speciesName = speciesName;
    return out;
  } catch (Exception e) {
    e.printStackTrace();
    return null;
  }
}
