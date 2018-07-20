// This class represents the original Genome when a mutation occurs between two specific Node IDs.
// This allows us to compare various Genomes to each other and test to see if they share characteristics.
static class ConnectionHistory {
  
  public static int nextConnectionInnovationNumber = 100;
  
  int fromNode; // Start
  int toNode; // Finish
  int innovationNumber; // Original innovation number

  // This array is _essentially_ a Genome copy.
  // It stores all of the innovation numbers of the Genome for when the mutation first occurred.
  ArrayList<Integer> originalGenomeCopy = new ArrayList<Integer>();
  //the innovation Numbers from the connections of the genome which first had this mutation 
  //this represents the genome and allows us to test if another genome is the same
  //this is before this connection was added

  ConnectionHistory(int from, int to, int inno, ArrayList<Integer> innovationNos) {
    fromNode = from;
    toNode = to;
    innovationNumber = inno;
    originalGenomeCopy = (ArrayList)innovationNos.clone();
  }
  // Returns whether the Genome in history matches the original Genome and the connection is between the same nodes
  boolean matches(Genome genome, Node from, Node to) {
    if (genome.genes.size() == originalGenomeCopy.size()) { // Genome+Genome Copy must have same size to match
      if (from.id == fromNode && to.id == toNode) { // The two Nodes in question must share the same IDs as the Nodes this History represents
        for (int i = 0; i< genome.genes.size(); i++) {
          if (!originalGenomeCopy.contains(genome.genes.get(i).innovationNo)) {
            return false; // Return false if one of the innovation numbers does not match between the Genome and the copied Genome
          }
        }

        // The Genome and the original Genome match.
        return true;
      }
    }
    return false;
  }
}
