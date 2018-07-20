// This class represents ALL of the Players that will be evolved.
// It serves as a 'holder' for all of the Players of each generation and is also responsible for evolving them+showing+updating them
class Population {
  ArrayList<Player> pop = new ArrayList<Player>();
  Player bestPlayer;// The best player in the population 
  int bestScore =0;// The score of the best ever player
  int gen;
  ArrayList<ConnectionHistory> innovationHistory = new ArrayList<ConnectionHistory>();
  ArrayList<Player> genPlayers = new ArrayList<Player>();
  ArrayList<Species> species = new ArrayList<Species>();

  boolean massExtinctionEvent = false;
  boolean newStage = false;
  
  int currentIndex = 0;
  
  UpdateType updateType;

  Population(int size) {
    for (int i =0; i<size; i++) {
      pop.add(new Player());
      pop.get(i).brain.generateNetwork();
      pop.get(i).brain.mutate(innovationHistory);
    }
    currentIndex = 0;
    updateType = POPULATION_UPDATE_TYPE;
  }

  // Update all the players which are alive
  void updateAlive() {
    if (updateType == UpdateType.SINGLE) {
      if (currentIndex < pop.size()) {
        if (!paused) {
          pop.get(currentIndex).look();
          pop.get(currentIndex).think();
          pop.get(currentIndex).update();
        }
        pop.get(currentIndex).show();
        if (!pop.get(currentIndex).replaySpikes.contains(spikes)) {
          // Make sure to at least have the replay spikes contain the first spikes ever
          pop.get(currentIndex).replaySpikes.add(spikes);
        }
        /*
        if (pop.get(currentIndex).dead) {
          println("Moving on to "+(currentIndex+1)+" Player");
          currentIndex++;
        }
        */
      }
    } else if (updateType == UpdateType.ALL) {
      for (int i = 0; i< pop.size(); i++) {
        if (!pop.get(i).dead) {
          if (!paused) {
            pop.get(i).look();//get inputs for brain 
            pop.get(i).think();//use outputs from neural network
            pop.get(i).update();//move the player according to the outputs from the neural network
          }
          if (!showNothing && (!showBest || i ==0)) {
            pop.get(i).show();
          }
          currentIndex = i; // This will make sure as long as players are alive, they will updateSpikes
          if (!pop.get(i).replaySpikes.contains(spikes)) {
            // Make sure to at least have the replay spikes contain the first spikes ever
            pop.get(i).replaySpikes.add(spikes);
          }
        }
      }
    } else {
      // Nothing
    }
  }
  
  // Gets the current player if updating with UpdateType.SINGLE
  Player getCurrentPlayer() {
    if (currentIndex < pop.size()) {
      return pop.get(currentIndex);
    }
    return null; // don't do this if you aren't single updating
  }
  
  // Should Update Spikes from Player
  int shouldUpdateSpikes() {
    if (updateType == UpdateType.SINGLE) {
      int shouldUpdate = pop.get(currentIndex).shouldUpdateSpikes();
      /*
      if (shouldUpdate > -1) {
        pop.get(currentIndex).replaySpikes.add(spikes);
      }
      */
      return shouldUpdate;
    } else if (updateType == UpdateType.ALL) {
      int[] shoulds = new int[pop.size()];
      for (int i = 0; i < pop.size(); i++) {
        int shouldUpdate = pop.get(i).shouldUpdateSpikes();
        /*
        if (shouldUpdate > -1) {
          pop.get(i).replaySpikes.add(spikes);
        }
        */
        shoulds[i] = shouldUpdate;
      }
      return max(shoulds);
    }
    return -1;
  }

  // Returns true if all the players are dead, how sad
  boolean done() {
    for (int i = 0; i < pop.size(); i++) {
      if (!pop.get(i).dead) {
        return false;
      }
    }
    println("all dead");
    return true;
  }
  
  // Sets the best player globally and for this gen
  void setBestPlayer() {
    Player tempBest =  species.get(0).players.get(0);
    tempBest.gen = gen;

    // If the best Player this gen is better than the global best score then set the global best to this Player
    if (tempBest.score > bestScore) {
      genPlayers.add(tempBest.cloneForReplay());
      println("old best:", bestScore);
      println("new best:", tempBest.score);
      bestScore = tempBest.score;
      bestPlayer = tempBest.cloneForReplay();
    }
  }

  // This function is called when all the players in the population are dead and a new generation needs to be made
  void naturalSelection() {
    speciate();//seperate the population into species 
    calculateFitness();//calculate the fitness of each player
    sortSpecies();//sort the species to be ranked in fitness order, best first
    if (massExtinctionEvent) { 
      massExtinction();
      massExtinctionEvent = false;
      print("MASS EXTINCTION!");
    }
    cullSpecies();//kill off the bottom half of each species
    setBestPlayer();//save the best player of this gen
    killStaleSpecies();//remove species which haven't improved in the last 15(ish) generations
    killBadSpecies();//kill species which are so bad that they cant reproduce


    println("generation", gen, "Number of mutations", innovationHistory.size(), "species: " + species.size(), "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");


    float averageSum = getAvgFitnessSum();
    ArrayList<Player> children = new ArrayList<Player>();//the next generation
    println("Species:");               
    for (int j = 0; j < species.size(); j++) {//for each species
      println("Name: "+species.get(j).name);
      println("best unadjusted fitness:", species.get(j).bestFitness);
      for (int i = 0; i < species.get(j).players.size(); i++) {
        print("Player " + i+":", "fitness: " + species.get(j).players.get(i).fitness, "score " + species.get(j).players.get(i).score, ' ');
      }
      println();
      Player c = species.get(j).champ.clone(); // used to be cloneForReplay
      c.speciesName = species.get(j).name;
      children.add(c);//add champion without any mutation

      int NoOfChildren = floor(species.get(j).averageFitness/averageSum * pop.size()) -1;//the number of children this species is allowed, note -1 is because the champ is already added
      for (int i = 0; i< NoOfChildren; i++) {//get the calculated amount of children from this species
        Player temp = species.get(j).getOffspring(innovationHistory);
        temp.speciesName = species.get(j).name;
        children.add(temp);
      }
    }

    while (children.size() < pop.size()) {//if not enough babies (due to flooring the number of children to get a whole int)
      Player temp = species.get(0).getOffspring(innovationHistory);
      temp.speciesName = species.get(0).name;
      children.add(temp);//get babies from the best species
    }
    pop.clear();
    pop = (ArrayList)children.clone(); //set the children as the current population
    gen+=1;
    for (int i = 0; i < pop.size(); i++) {//generate networks for each of the children
      pop.get(i).brain.generateNetwork();
    }
    currentIndex = 0;
  }

  // Seperate population into species based on how similar they are to the representatives of each species in the previous gen
  void speciate() {
    for (Species s : species) {//empty species
      s.players.clear();
    }
    for (int i = 0; i< pop.size(); i++) {//for each player
      boolean speciesFound = false;
      for (Species s : species) {//for each species
        if (s.sameSpecies(pop.get(i).brain)) {//if the player is similar enough to be considered in the same species
          s.addToSpecies(pop.get(i));//add it to the species
          speciesFound = true;
          break;
        }
      }
      if (!speciesFound) {// If no species was similar enough then add a new species with this as its representative
        species.add(new Species(pop.get(i)));
      }
    }
  }
  
  // Calculates the fitness of all of the players (except the first one)
  void calculateFitness() {
    for (int i = 1; i < pop.size(); i++) {
      pop.get(i).calculateFitness();
    }
  }
  // Sorts the players within a species and the species by their fitnesses
  void sortSpecies() {
    //sort the players within a species
    for (Species s : species) {
      s.sortSpecies();
    }

    //sort the species by the fitness of its best player
    //using selection sort like a loser
    // Util.sort(species)
    ArrayList<Species> temp = new ArrayList<Species>();
    for (int i = 0; i < species.size(); i ++) {
      float max = 0;
      int maxIndex = 0;
      for (int j = 0; j< species.size(); j++) {
        if (species.get(j).bestFitness > max) {
          max = species.get(j).bestFitness;
          maxIndex = j;
        }
      }
      temp.add(species.get(maxIndex));
      species.remove(maxIndex);
      i--;
    }
    species = (ArrayList)temp.clone();
  }

  // Kills all species which haven't improved in 15 generations
  void killStaleSpecies() {
    for (int i = 2; i< species.size(); i++) {
      if (species.get(i).staleness >= 15) {
        species.remove(i);
        i--;
      }
    }
  }

  // If a species sucks so much that it wont even be allocated 1 child for the next generation then kill it now
  void killBadSpecies() {
    float averageSum = getAvgFitnessSum();

    for (int i = 1; i< species.size(); i++) {
      if (species.get(i).averageFitness/averageSum * pop.size() < 1) {//if wont be given a single child 
        species.remove(i);//sad
        i--;
      }
    }
  }

  // Returns the sum of each species' average fitness
  float getAvgFitnessSum() {
    float averageSum = 0;
    for (Species s : species) {
      averageSum += s.averageFitness;
    }
    return averageSum;
  }

  // Kill the bottom half of each species
  void cullSpecies() {
    for (Species s : species) {
      s.cull(); //kill bottom half
      s.fitnessSharing();//also while we're at it lets do fitness sharing
      s.setAverage();//reset averages because they will have changed
    }
  }

  // Kill all species that aren't in the top
  void massExtinction() {
    for (int i = EXTINCTION_SAVE_TOP; i < species.size(); i++) {
      species.remove(i);//sad
      i--;
    }
  }
  
  // Saves all players to files
  void saveAll(String directory) {
    for (int i = 0; i < pop.size(); i++) {
      try {
        File f = new File(directory+"G"+gen+"/");
        f.mkdir();
        f = new File(directory+"G"+gen+"/P"+i+"player.pd");
        saveToFile(pop.get(i), f.toString());
      } catch (Exception e) {
        e.printStackTrace();
      }
    }
  }
  
  void loadAll(String directory, int genToPick) {
    int maxI = 0;
    float maxFitness = 0;
    for (int i = 0; i < pop.size(); i++) {
      Player temp = readFromFile(directory+"G"+genToPick+"/P"+i+"player.pd");
      if (temp.fitness > maxFitness) {
        maxI = i;
        maxFitness = temp.fitness;
      }
      pop.set(i, temp);
    }
    bestPlayer = pop.get(maxI).cloneForReplay();
    bestScore = bestPlayer.bestScore;
    speciate();
  }
}
