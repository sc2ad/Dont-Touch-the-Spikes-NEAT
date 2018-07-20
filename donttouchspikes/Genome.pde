// The Genome (Brain) for each Player.
// This acts as the network, as well as contains various helper genetic functions.
class Genome {
  ArrayList<GeneConnection> genes = new  ArrayList<GeneConnection>(); // All of the connections between Nodes
  ArrayList<Node> nodes = new ArrayList<Node>(); // All of the Nodes, in no particular order
  int inputs;
  int outputs;
  int layers = 2; // Default 2, increases as evolution occurs
  int nextNode = 0; // The next Node ID to modify
  int biasNode; // The Node ID that represents the bias Node

  ArrayList<Node> network = new ArrayList<Node>();//a list of the nodes in the order that they need to be considered in the NN

  Genome(int in, int out) {
    // Set input number and output number
    inputs = in;
    outputs = out;

    // Create input nodes: Node IDs are: [0-inputs)
    for (int i = 0; i < inputs; i++) {
      nodes.add(new Node(i));
      nextNode++;
      nodes.get(i).layer = 0;
    }

    // Create output nodes: Node IDs are: [inputs-inputs+outputs)
    for (int i = 0; i < outputs; i++) {
      nodes.add(new Node(i+inputs));
      nodes.get(i+inputs).layer = 1;
      nextNode++;
    }
    // Creates bias Node: Node ID is: inputs+outputs
    nodes.add(new Node(nextNode));
    biasNode = nextNode; 
    nextNode++;
    nodes.get(biasNode).layer = 0; // Bias Node part of input layer
  }
  
  // Create an empty genome, used for crossover
  Genome(int in, int out, boolean crossover) {
    //set input number and output number
    inputs = in; 
    outputs = out;
  }
  
  // Returns the Node with the matching ID
  Node getNode(int nodeID) {
    for (int i = 0; i < nodes.size(); i++) {
      if (nodes.get(i).id == nodeID) {
        return nodes.get(i);
      }
    }
    return null;
  }

  // Adds the output connections of each Node
  void connectNodes() {
    // Clears all of the Node connections so that they can be reconnected using the GeneConnection array instead.
    for (int i = 0; i < nodes.size(); i++) {//clear the connections
      nodes.get(i).outputConnections.clear();
    }
    // Reconnect each Node using the GeneConnection array
    for (int i = 0; i < genes.size(); i++) {
      genes.get(i).fromNode.outputConnections.add(genes.get(i));
    }
  }

  // Expects input array, returns output of NN
  float[] feedForward(float[] inputValues) {
    if (network == null) {
      throw new IllegalArgumentException("Network hasn't been initialized yet, but you are trying to feedForward it!");
    }
    
    // Set the outputs of the input nodes
    for (int i =0; i < inputs; i++) {
      nodes.get(i).outputValue = inputValues[i];
    }
    nodes.get(biasNode).outputValue = 1; // Bias = 1

    // Activate each Node in the network
    for (int i = 0; i < network.size(); i++) {
      network.get(i).activate();
    }

    // Output Node IDs are [inputs, inputs+outputs)
    float[] outs = new float[outputs];
    for (int i = 0; i < outputs; i++) {
      outs[i] = nodes.get(inputs + i).outputValue;
    }
    
    // Reset
    for (int i = 0; i < nodes.size(); i++) {
      nodes.get(i).inputSum = 0;
    }

    return outs;
  }

  // Sets up the NN as a list of nodes in the correct order to be actiavted 
  void generateNetwork() {
    connectNodes();
    network = new ArrayList<Node>();
    // For each layer: For each Node in the nodes array: If their layer matches, add it to the network.
    // This will add the Nodes in order of layer, then ID

    for (int l = 0; l < layers; l++) {
      for (int i = 0; i < nodes.size(); i++) {
        if (nodes.get(i).layer == l) {
          network.add(nodes.get(i));
        }
      }
    }
  }
  
  // Mutate the NN by adding a new Node
  // Randomly disable a GeneConnection, then create two new GeneConnections between the input Node and the new Node + the new Node and the output Node 
  void addNode(ArrayList<ConnectionHistory> innovationHistory) {
    // Pick a random connection to create a Node between
    if (genes.size() == 0) {
      // If there are NO GeneConnections
      addConnection(innovationHistory);
      // Add a Connection from previous Genomes
      return;
    }
    int randomConnection = floor(random(genes.size()));

    while (genes.get(randomConnection).fromNode == nodes.get(biasNode) && genes.size() !=1 ) {// Bias must remain connected
      randomConnection = floor(random(genes.size()));
    }

    genes.get(randomConnection).enabled = false;

    int newNodeNo = nextNode; // nextNode is STILL the next ID to add
    nodes.add(new Node(newNodeNo));
    nextNode++;
    
    // Gets the innovationNumber of this new GeneConnection between the input Node and the new Node
    int connectionInnovationNumber = getInnovationNumber(innovationHistory, genes.get(randomConnection).fromNode, getNode(newNodeNo));
    // Add a new GeneConnection to the new Node with a weight of 1
    genes.add(new GeneConnection(genes.get(randomConnection).fromNode, getNode(newNodeNo), 1, connectionInnovationNumber));

    // Gets the innovationNumber of this new GeneConnection between the new Node and the output Node
    connectionInnovationNumber = getInnovationNumber(innovationHistory, getNode(newNodeNo), genes.get(randomConnection).toNode);
    
    // Add a new GeneConnection from the new node with a weight the same as the disabled connection
    genes.add(new GeneConnection(getNode(newNodeNo), genes.get(randomConnection).toNode, genes.get(randomConnection).weight, connectionInnovationNumber));
    getNode(newNodeNo).layer = genes.get(randomConnection).fromNode.layer + 1; // The original output Node gets shifted down 1 layer

    // Gets the innovationNumber of a new GeneConnection between the bias Node and the new Node
    connectionInnovationNumber = getInnovationNumber(innovationHistory, nodes.get(biasNode), getNode(newNodeNo));
    // Connect the bias to the new node with a weight of 0
    genes.add(new GeneConnection(nodes.get(biasNode), getNode(newNodeNo), 0, connectionInnovationNumber));

    // If the layer of the new Node is equal to the layer of the output Node, a new layer must be created.
    // All of the layers of all of the Nodes with layers >= the new Node's layer must be incremented
    if (getNode(newNodeNo).layer == genes.get(randomConnection).toNode.layer) {
      for (int i = 0; i< nodes.size() - 1; i++) { // Make sure not to include the new Node (last Node in nodes)
        if (nodes.get(i).layer >= getNode(newNodeNo).layer) {
          nodes.get(i).layer ++;
        }
      }
      layers++;
    }
    connectNodes(); // Reconnect the Nodes after this has been created
  }

  // Adds a connection between 2 nodes which aren't currently connected
  void addConnection(ArrayList<ConnectionHistory> innovationHistory) {
    // Cannot add a connection to a fully connected network
    if (fullyConnected()) {
      println("Cannot add a connection because the network is fully connected!");
      return;
    }

    // Get random nodes
    int randomNode1 = floor(random(nodes.size())); 
    int randomNode2 = floor(random(nodes.size()));
    while (isNonUnique(randomNode1, randomNode2)) {// While the random Node indicies are non Unique
      // Get new Nodes
      randomNode1 = floor(random(nodes.size())); 
      randomNode2 = floor(random(nodes.size()));
    }
    // If the first random Node is after the second then switch the first and second Nodes
    int temp;
    if (nodes.get(randomNode1).layer > nodes.get(randomNode2).layer) {
      temp =randomNode2;
      randomNode2 = randomNode1;
      randomNode1 = temp;
    }    

    // Gets the innovation number of this new connection
    int connectionInnovationNumber = getInnovationNumber(innovationHistory, nodes.get(randomNode1), nodes.get(randomNode2));
    // Add the connection with a random weight
    genes.add(new GeneConnection(nodes.get(randomNode1), nodes.get(randomNode2), random(-1, 1), connectionInnovationNumber));
    connectNodes(); // Reconnect the Nodes
  }
  
  // Returns if the two Node indicies are non Unique
  boolean isNonUnique(int r1, int r2) {
    if (nodes.get(r1).layer == nodes.get(r2).layer) return true; // If the nodes are in the same layer 
    if (nodes.get(r1).isConnectedTo(nodes.get(r2))) return true; // If the nodes are already connected
    return false;
  }

  // Returns the innovation number for the given Connection
  // If this mutation has never been seen before then it will be given a new, unique innovation number
  // If this mutation matches a previous mutation then it will be given the same innovation number as the previous one
  int getInnovationNumber(ArrayList<ConnectionHistory> innovationHistory, Node from, Node to) {
    // nextConnectionNumber is a public, global variable because all the Genomes should share innovationNumber Uniqueness.
    // In other words, all the different Genomes could mutate unique innovationNumbers, but that should be reflected.
    boolean isNew = true;
    int connectionInnovationNumber = ConnectionHistory.nextConnectionInnovationNumber;
    for (int i = 0; i < innovationHistory.size(); i++) { // For each previous mutation
      if (innovationHistory.get(i).matches(this, from, to)) { // If match found
        isNew = false;// The Connection is not unique/new
        connectionInnovationNumber = innovationHistory.get(i).innovationNumber; // Set the innovation number as the innovation number of the match
        break;
      }
    }

    if (isNew) { // If the mutation is new then create an ArrayList of integers representing the current state of the genome
      ArrayList<Integer> currentGenomeState = new ArrayList<Integer>();
      for (int i = 0; i< genes.size(); i++) { // Set the innovation numbers
        currentGenomeState.add(genes.get(i).innovationNo);
      }

      // Then add this unique Connection to innovationHistory
      innovationHistory.add(new ConnectionHistory(from.id, to.id, connectionInnovationNumber, currentGenomeState));
      ConnectionHistory.nextConnectionInnovationNumber++;
    }
    return connectionInnovationNumber;
  }

  // Returns whether the network is fully connected or not
  boolean fullyConnected() {
    int maxConnections = 0;
    int[] nodesInLayers = new int[layers]; // Array which stores the amount of nodes in each layer

    for (int i =0; i< nodes.size(); i++) {
      nodesInLayers[nodes.get(i).layer] +=1;
    }

    // For each layer the maximum amount of connections is the number of Nodes in this layer * the number of Nodes one layer in front of it
    // Add the up all of these for each layer to get maxConnections
    for (int i = 0; i < layers-1; i++) {
      int nodesInFront = 0;
      for (int j = i+1; j < layers; j++) {//for each layer infront of this layer
        nodesInFront += nodesInLayers[j];//add up nodes
      }
      maxConnections += nodesInLayers[i] * nodesInFront;
    }

    // If the number of connections is equal to the max number of connections possible then it is full
    if (maxConnections == genes.size()) {
      return true;
    }
    return false;
  }

  // Mutates the genome
  void mutate(ArrayList<ConnectionHistory> innovationHistory) {
    // If there are no GeneConnections, add a random one from history
    if (genes.size() == 0) {
      addConnection(innovationHistory);
    }
    // Randomly choose to mutate the weight
    float rand1 = random(1);
    if (rand1<WEIGHT_MUTATION_CHANCE) {
      for (int i = 0; i< genes.size(); i++) {
        genes.get(i).mutateWeight();
      }
    }
    // Randomly choose to add a GeneConnection
    float rand2 = random(1);
    if (rand2<ADD_CONNECTION_CHANCE) {
      addConnection(innovationHistory);
    }
    // Randomly choose to add a Node
    float rand3 = random(1);
    if (rand3<ADD_NODE_CHANCE) {
      addNode(innovationHistory);
    }
  }

  // Performs crossover, assuming that this Genome is more fit than the other Genome
  Genome crossover(Genome parent2) {
    Genome child = new Genome(inputs, outputs, true);
    child.genes.clear();
    child.nodes.clear();
    child.layers = layers;
    child.nextNode = nextNode;
    child.biasNode = biasNode;
    ArrayList<GeneConnection> childGenes = new ArrayList<GeneConnection>(); // This will serve as a list of GeneConnections to inherit from parents
    // Remove this array soon...
    ArrayList<Boolean> isEnabled = new ArrayList<Boolean>();  // All of the enabled/disabled Nodes (because why would I make each Node have an enabled/disabled tag...)
    // All genes
    for (int i = 0; i < genes.size(); i++) {
      boolean setEnabled = true; // Is this node in the chlid going to be enabled

      int parent2gene = parent2.matchingGene(genes.get(i).innovationNo);
      if (parent2gene != -1) { // If the gene does not match between parents
        if (!genes.get(i).enabled || !parent2.genes.get(parent2gene).enabled) {// If either of the matching genes are disabled
          // Punnet square math! 75% of time disable child's gene
          if (random(1) < 0.75) {
            setEnabled = false;
          }
        }
        float rand = random(1);
        if (rand<0.5) {
          // Punnet square math! 50% of time get Gene from Parent1
          childGenes.add(genes.get(i));
        } else {
          // Punnet square math! 50% of time get Gene from Parent2
          childGenes.add(parent2.genes.get(parent2gene));
        }
      } else { // This gene already exists in both parents, take from more fit parent
        childGenes.add(genes.get(i));
        setEnabled = genes.get(i).enabled;
      }
      isEnabled.add(setEnabled);
    }

    // Since all excess and disjoint genes are inherrited from the more fit parent (this Genome) the child's Node structure is no different from this parent
    // So all of the child's Nodes can be inherrited from this parent
    for (int i = 0; i < nodes.size(); i++) {
      child.nodes.add(nodes.get(i).clone());
    }

    // Clone all the connections so that they connect the childs new nodes
    for ( int i = 0; i < childGenes.size(); i++) {
      child.genes.add(childGenes.get(i).clone(child.getNode(childGenes.get(i).fromNode.id), child.getNode(childGenes.get(i).toNode.id)));
      child.genes.get(i).enabled = isEnabled.get(i); // Please remove this
    }
    child.connectNodes();
    return child;
  }

  // Returns whether or not there is a gene matching the input innovation number in the provided Genome
  int matchingGene(int innovationNumber) {
    for (int i = 0; i < genes.size(); i++) {
      if (genes.get(i).innovationNo == innovationNumber) {
        return i;
      }
    }
    return -1; //no matching gene found
  }

  // Prints out info about the genome to the console 
  void printGenome() {
    println("Genome layers: ", layers);  
    println("Bias node: "  + biasNode);
    println("Node IDs: ");
    for (int i = 0; i < nodes.size(); i++) {
      print(nodes.get(i).id + ",");
    }
    println("Genes");
    for (int i = 0; i < genes.size(); i++) {//for each GeneConnection
      println("gene " + genes.get(i).innovationNo, "From node " + genes.get(i).fromNode.id, "To node " + genes.get(i).toNode.id, 
        "is enabled " +genes.get(i).enabled, "from layer " + genes.get(i).fromNode.layer, "to layer " + genes.get(i).toNode.layer, "weight: " + genes.get(i).weight);
    }
    println();
  }

  // Returns a clone of this genome
  Genome clone() {
    Genome clone = new Genome(inputs, outputs, true);

    for (int i = 0; i < nodes.size(); i++) {
      clone.nodes.add(nodes.get(i).clone());
    }
    // Copy all the connections so that they connect the new Nodes in the Clone
    for ( int i =0; i<genes.size(); i++) {
      clone.genes.add(genes.get(i).clone(clone.getNode(genes.get(i).fromNode.id), clone.getNode(genes.get(i).toNode.id)));
    }

    clone.layers = layers;
    clone.nextNode = nextNode;
    clone.biasNode = biasNode;
    clone.connectNodes();
    clone.generateNetwork();

    return clone;
  }

  //draw the genome on the screen
  void drawGenome(int startX, int startY, int w, int h) {
    // yuck
    ArrayList<ArrayList<Node>> allNodes = new ArrayList<ArrayList<Node>>();
    ArrayList<PVector> nodePoses = new ArrayList<PVector>();
    ArrayList<Integer> nodeNumbers= new ArrayList<Integer>();

    // Split the nodes into layers
    for (int i = 0; i < layers; i++) {
      ArrayList<Node> temp = new ArrayList<Node>();
      for (int j = 0; j< nodes.size(); j++) {//for each node 
        if (nodes.get(j).layer == i ) {//check if it is in this layer
          temp.add(nodes.get(j)); //add it to this layer
        }
      }
      allNodes.add(temp);//add this layer to all nodes
    }

    //for each layer add the position of the node on the screen to the node posses arraylist
    for (int i = 0; i < layers; i++) {
      fill(255, 0, 0);
      float x = startX + (float)((i+1)*w)/(float)(layers+1.0);
      for (int j = 0; j< allNodes.get(i).size(); j++) {//for the position in the layer
        float y = startY + ((float)(j + 1.0) * h)/(float)(allNodes.get(i).size() + 1.0);
        nodePoses.add(new PVector(x, y));
        nodeNumbers.add(allNodes.get(i).get(j).id);
      }
    }

    //draw connections 
    stroke(0);
    strokeWeight(2);
    for (int i = 0; i< genes.size(); i++) {
      if (genes.get(i).enabled) {
        stroke(0);
      } else {
        stroke(100);
      }
      PVector from;
      PVector to;
      from = nodePoses.get(nodeNumbers.indexOf(genes.get(i).fromNode.id));
      to = nodePoses.get(nodeNumbers.indexOf(genes.get(i).toNode.id));
      if (genes.get(i).weight > 0) {
        stroke(255, 0, 0);
      } else {
        stroke(0, 0, 255);
      }
      strokeWeight(map(abs(genes.get(i).weight), 0, 1, 0, 5));
      line(from.x, from.y, to.x, to.y);
    }

    //draw nodes last so they appear ontop of the connection lines
    for (int i = 0; i < nodePoses.size(); i++) {
      fill(255);
      stroke(0);
      strokeWeight(1);
      ellipse(nodePoses.get(i).x, nodePoses.get(i).y, 20, 20);
      textSize(10);
      fill(0);
      textAlign(CENTER, CENTER);


      text(nodeNumbers.get(i), nodePoses.get(i).x, nodePoses.get(i).y);
    }
  }
  
  String toString() {
    String out = "GENOME<<";
    out+="I:"+inputs+", ";
    out+="O:"+outputs+", ";
    out+="NODE<";
    for (int i = 0; i < nodes.size(); i++) {
      out+=nodes.get(i)+", ";
    }
    out += ">, GENES<";
    for (int i = 0; i < genes.size(); i++) {
      out+=genes.get(i)+", ";
    }
    out+=">, Layers:"+layers+", ";
    out+="nextNode:"+nextNode+", ";
    out+="biasNode:"+biasNode+">>";
    return out;
  }
}

Genome genomeFromString(String str) {
  try {
    str = str.split("GENOME<<")[1];
    int inputs = Integer.parseInt(str.split("I:")[1].split(", ")[0]);
    int outputs = Integer.parseInt(str.split("O:")[1].split(", ")[0]);
    ArrayList<Node> nodes = new ArrayList<Node>();
    String forNodes = str.split("NODE<")[1].split(">, GENES<")[0];
    while (forNodes.contains("N<")) {
      nodes.add(nodeFromString(forNodes));
      forNodes = forNodes.substring(forNodes.indexOf(">")+1, forNodes.length());
    }
    ArrayList<GeneConnection> genes = new ArrayList<GeneConnection>();
    String forGenes = str.split("GENES<")[1].split(">, Layers:")[0];
    while (forGenes.contains("G<")) {
      String forGene1 = forGenes.substring(0, forGenes.indexOf("e>")+1);
      genes.add(geneFromString(forGene1));
      forGenes = forGenes.substring(forGenes.indexOf("e>")+3, forGenes.length());
    }
    int layers = Integer.parseInt(str.split("Layers:")[1].split(", ")[0]);
    int nextNode = Integer.parseInt(str.split("nextNode:")[1].split(", ")[0]);
    int biasNode = Integer.parseInt(str.split("biasNode:")[1].split(">>")[0]);
    
    Genome clone = new Genome(inputs, outputs, true);

    for (int i = 0; i < nodes.size(); i++) {
      clone.nodes.add(nodes.get(i).clone());
    }
    // Copy all the connections so that they connect the new Nodes in the Clone
    for ( int i =0; i<genes.size(); i++) {
      clone.genes.add(genes.get(i).clone(clone.getNode(genes.get(i).fromNode.id), clone.getNode(genes.get(i).toNode.id)));
    }

    clone.layers = layers;
    clone.nextNode = nextNode;
    clone.biasNode = biasNode;
    clone.connectNodes();
    clone.generateNetwork();

    return clone;
    
  } catch (Exception e) {
    e.printStackTrace();
    return null;
  }
}
