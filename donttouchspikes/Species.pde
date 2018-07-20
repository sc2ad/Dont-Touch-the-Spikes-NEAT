// This class represents a Species of Genomes (Genomes that are comparable to each other)
class Species {
  ArrayList<Player> players = new ArrayList<Player>();
  float bestFitness = 0;
  String name;
  Player champ;
  float averageFitness = 0;
  int staleness = 0;//how many generations the species has gone without an improvement
  Genome rep;

  // Coefficients for testing compatibility 
  float excessCoeff = 1;
  float weightDiffCoeff = 0.5;
  float compatibilityThreshold = 3;
  

  Species() {
    name = getUniqueSpeciesName();
  }

  Species(Player p) {
    name = getUniqueSpeciesName();
    p.speciesName = name;
    players.add(p); 
    // Since it is the only one in the species it is by default the best
    bestFitness = p.fitness; 
    rep = p.brain.clone();
    champ = p.cloneForReplay();
  }

  // Returns whether the parameter Genome is in this species
  boolean sameSpecies(Genome g) {
    float compatibility;
    float excessAndDisjoint = getExcessDisjoint(g, rep);// Get the number of excess and disjoint genes between this Genome and the current species representative
    float averageWeightDiff = averageWeightDiff(g, rep);// Get the average weight difference between matching genes between this Genome and the current species representative

    // Makes larger Genomes slightly more compatible
    float largeGenomeNormaliser = g.genes.size() - 20;
    if (largeGenomeNormaliser < 1) {
      largeGenomeNormaliser = 1;
    }

    compatibility =  (excessCoeff* excessAndDisjoint/largeGenomeNormaliser) + (weightDiffCoeff* averageWeightDiff); // Compatablilty formula
    return (compatibilityThreshold > compatibility);
  }

  // Add a player to the species
  void addToSpecies(Player p) {
    p.speciesName = name;
    players.add(p);
  }

  // Returns the number of excess and disjoint genes between the 2 input genomes, which is the number of genes that don't match between the two Genomes
  float getExcessDisjoint(Genome brain1, Genome brain2) {
    float matching = 0.0;
    for (int i = 0; i < brain1.genes.size(); i++) {
      for (int j = 0; j < brain2.genes.size(); j++) {
        if (brain1.genes.get(i).innovationNo == brain2.genes.get(j).innovationNo) {
          matching++;
          break;
        }
      }
    }
    return (brain1.genes.size() + brain2.genes.size() - 2*(matching)); // return number of excess and disjoint genes, punnett square math: pq - 2(!p!q) = nonMatching genes
  }

  // Returns the avereage weight difference between matching genes in the input genomes
  float averageWeightDiff(Genome brain1, Genome brain2) {
    if (brain1.genes.size() == 0 || brain2.genes.size() ==0) {
      return 0;
    }

    float matching = 0;
    float totalDiff= 0;
    for (int i =0; i <brain1.genes.size(); i++) {
      for (int j = 0; j < brain2.genes.size(); j++) {
        if (brain1.genes.get(i).innovationNo == brain2.genes.get(j).innovationNo) {
          matching++;
          totalDiff += abs(brain1.genes.get(i).weight - brain2.genes.get(j).weight);
          break;
        }
      }
    }
    if (matching == 0) {//divide by 0 error
      return 1000; // Return some large number because none of the genes matched
    }
    return totalDiff/matching;
  }

  // Sorts the species by fitness 
  void sortSpecies() {
    ArrayList<Player> temp = new ArrayList<Player>();

    // Selection sort (WILL REPLACE WITH QUICKSORT)
    // temp = Util.sort(temp);
    for (int i = 0; i < players.size(); i ++) {
      float max = 0;
      int maxIndex = 0;
      for (int j = 0; j< players.size(); j++) {
        if (players.get(j).fitness > max) {
          max = players.get(j).fitness;
          maxIndex = j;
        }
      }
      temp.add(players.get(maxIndex));
      players.remove(maxIndex);
      i--;
    }

    players = (ArrayList)temp.clone();
    if (players.size() == 0) {
      print("uhoh, no players!"); 
      staleness = 200;
      return;
    }
    // If new best player
    if (players.get(0).fitness > bestFitness) {
      staleness = 0;
      bestFitness = players.get(0).fitness;
      rep = players.get(0).brain.clone();
      champ = players.get(0).cloneForReplay();
    } else { // If no new best player
      staleness ++;
    }
  }

  // Sets the average fitness for the Species
  void setAverage() {

    float sum = 0;
    for (int i = 0; i < players.size(); i ++) {
      sum += players.get(i).fitness;
    }
    averageFitness = sum/players.size();
  }

  // Gets the offspring from the Player in this species
  Player getOffspring(ArrayList<ConnectionHistory> innovationHistory) {
    Player baby;
    if (random(1) < 0.25) {// Punnett square math: 25% of the time there is no crossover and the child is simply a clone of a random(ish) player
      baby =  selectPlayer().clone();
    } else {// Punnet square math: 75% of the time do crossover 

      // Get 2 random parents 
      Player parent1 = selectPlayer();
      Player parent2 = selectPlayer();

      // The crossover function expects the highest fitness parent to be the object and the lowest as the argument
      if (parent1.fitness < parent2.fitness) {
        baby =  parent2.crossover(parent1);
      } else {
        baby =  parent1.crossover(parent2);
      }
    }
    baby.brain.mutate(innovationHistory);// Mutate offspring brain
    return baby;
  }

  // Selects a player based on it fitness.
  // Uses a running sum probability
  Player selectPlayer() {
    float fitnessSum = 0;
    for (int i =0; i<players.size(); i++) {
      fitnessSum += players.get(i).fitness;
    }

    float rand = random(fitnessSum);
    float runningSum = 0;

    for (int i = 0; i<players.size(); i++) {
      runningSum += players.get(i).fitness; 
      if (runningSum > rand) {
        return players.get(i);
      }
    }
    return players.get(0);
  }
  
  // Kills off bottom half of the species
  void cull() {
    if (players.size() > 2) {
      for (int i = players.size()/2; i<players.size(); i++) {
        players.remove(i); 
        i--;
      }
    }
  }

  // In order to protect unique Players, the fitnesses of each Player is divided by the number of Players in its Species
  // Makes larger Species have lower fitness
  void fitnessSharing() {
    for (int i = 0; i< players.size(); i++) {
      players.get(i).fitness/=players.size();
    }
  }
}
