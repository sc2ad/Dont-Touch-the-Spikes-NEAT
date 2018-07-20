static class Util {
  static final ArrayList<Player> sortPlayers(ArrayList<Player> d) {
    Player[] temp = new Player[d.size()];
    for (int i = 0; i < temp.length; i++) {
      temp[i] = d.get(i);
    }
    temp = quickSort(temp, 0, d.size() - 1);
    ArrayList<Player> out = new ArrayList<Player>();
    for (Player p : temp) {
      out.add(p);
    }
    return out;
  }
  static final ArrayList<Species> sortSpecies(ArrayList<Species> d) {
    Species[] temp = new Species[d.size()];
    for (int i = 0; i < temp.length; i++) {
      temp[i] = d.get(i);
    }
    temp = quickSort(temp, 0, d.size() - 1);
    ArrayList<Species> out = new ArrayList<Species>();
    for (Species p : temp) {
      out.add(p);
    }
    return out;
  }
  private static Player[] quickSort(Player[] d, int lowerIndex, int higherIndex) {
    int i = lowerIndex;
    int j = higherIndex;
    float pivot = d[lowerIndex+(higherIndex-lowerIndex)/2].getFitness();
    while (i <= j) {
      while (d[i].getFitness() < pivot) {
        i++;
      }
      while (d[j].getFitness() > pivot) {
        j--;
      }
      if (i <= j) {
        d = exchangeIndicies(d, i, j);
        //move index to next position on both sides
        i++;
        j--;
      }
    }
    if (lowerIndex < j) {
      d = quickSort(d, lowerIndex, j);
    }
    if (i < higherIndex) {
      d = quickSort(d, i, higherIndex);
    }
    return d;
  }
  private static Species[] quickSort(Species[] d, int lowerIndex, int higherIndex) {
    int i = lowerIndex;
    int j = higherIndex;
    float pivot = d[lowerIndex+(higherIndex-lowerIndex)/2].bestFitness;
    while (i <= j) {
      while (d[i].bestFitness < pivot) {
        i++;
      }
      while (d[j].bestFitness > pivot) {
        j--;
      }
      if (i <= j) {
        d = exchangeIndicies(d, i, j);
        //move index to next position on both sides
        i++;
        j--;
      }
    }
    if (lowerIndex < j) {
      d = quickSort(d, lowerIndex, j);
    }
    if (i < higherIndex) {
      d = quickSort(d, i, higherIndex);
    }
    return d;
  }
  private static Player[] exchangeIndicies(Player[] d, int i, int j) {
    Player temp = d[i];
    d[i] = d[j];
    d[j] = temp;
    return d;
  }
  private static Species[] exchangeIndicies(Species[] d, int i, int j) {
    Species temp = d[i];
    d[i] = d[j];
    d[j] = temp;
    return d;
  }
}

 
    
