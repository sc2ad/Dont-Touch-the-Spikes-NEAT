// This class represents a Connection between two Nodes (refered to as a Gene)
// This is essentially a weight.
class GeneConnection {
  Node fromNode;
  Node toNode;
  float weight;
  boolean enabled = true;
  int innovationNo; // This is essentially an ID to compare various Genomes, it is used to compare similarities and differences between Genomes.
  
  GeneConnection(Node from, Node to, float w, int inno) {
    fromNode = from;
    toNode = to;
    weight = w;
    innovationNo = inno;
  }

  // Mutates the weight randomly
  void mutateWeight() {
    float rand2 = random(1);
    // Completely Re-randomize weight
    if (rand2 < RE_RANDOMIZE_WEIGHT_CHANCE) {
      weight = random(-1, 1);
    } 
    // Otherwise, slightly change it.
    else {
      weight += randomGaussian()/50;
      if(weight > 1){
        weight = 1;
      }
      if(weight < -1){
        weight = -1;        
      }
    }
  }

  // Clones the GeneConnection
  GeneConnection clone(Node from, Node  to) {
    GeneConnection clone = new GeneConnection(from, to, weight, innovationNo);
    clone.enabled = enabled;
    return clone;
  }
  String toString() {
    // G:[N:[1,2], N:[2,2], W:3.2, I:4, E:true]
    return "G<"+fromNode.toString()+", "+toNode.toString()+", W:"+weight+", I:"+innovationNo+", E:"+enabled+">";
  }
}

GeneConnection geneFromString(String str) {
  try {
    String temp = str.split("G<")[1];
    String fullstring = temp.substring(0, temp.length()-1);
    Node fromNode = nodeFromString(fullstring.substring(0,fullstring.indexOf('>')+1));
    Node toNode = nodeFromString(fullstring.substring(fullstring.indexOf('>')+3,fullstring.indexOf('>',fullstring.indexOf('>')+3)+1));
    String partial = fullstring.substring(fullstring.indexOf('>',fullstring.indexOf('>')+3)+3,fullstring.length());
    String[] split = partial.split(", ");
    float weight = Float.parseFloat(split[0].substring(2, split[0].length()));
    int innovationNo = Integer.parseInt(split[1].substring(2, split[1].length()));
    //boolean enabled = Boolean.parseBoolean(split[2].substring(2, split[2].length()-1));
    boolean enabled = true;
    GeneConnection out = new GeneConnection(fromNode, toNode, weight, innovationNo);
    out.enabled = enabled;
    return out;
  } catch (Exception e) {
    e.printStackTrace();
    return null;
  }
}
