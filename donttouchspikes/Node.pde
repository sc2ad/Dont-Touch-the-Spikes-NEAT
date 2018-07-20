// This class represents a Node (or a neuron)
class Node {
  int id; // The ID of the Node (neuron), which is ALWAYS unique
  float inputSum = 0; // rewriten by all Nodes (neurons) that have this node (neuron) as an output. This is before activation.
  float outputValue = 0; // Output value to send to all Output Nodes (neurons)
  ArrayList<GeneConnection> outputConnections = new ArrayList<GeneConnection>(); // All of the outputs of this Node (neuron)
  int layer = 0; // Where is the Node (neuron)? Layer 0 = input, Layer LAST = output
  PVector drawPos = new PVector(); // For drawing (Genome)

  Node(int no) {
    // Only ID is set on construction, everything else is mutated externally as Genome sees fit
    id = no;
  }
  // Activates the Node and relays output to future Nodes
  void activate() {
    // If not the input layer
    if (layer!=0) {
      outputValue = sigmoid(inputSum);
    }
    // Send the outputValue * weight to each of the output Nodes of this Node
    for (int i = 0; i< outputConnections.size(); i++) {
      if (outputConnections.get(i).enabled) {
        outputConnections.get(i).toNode.inputSum += outputConnections.get(i).weight * outputValue;
      }
    }
  }
  // Simple Step
  float stepFunction(float x) {
    if (x < 0) {
      return 0;
    } else {
      return 1;
    }
  }
  // reLU activation function
  float relu(float x) {
    return max(x, 0);
  }
  // Sigmoid
  float sigmoid(float x) {
    float y = 1 / (1 + pow((float)Math.E, -4.9*x));
    return y;
  }
  // Returns whether this node is connected to the parameter node
  boolean isConnectedTo(Node node) {
    if (node.layer == layer) {//nodes in the same layer cannot be connected
      return false;
    }

    // If the other Node comes BEFORE this Node, check to see if this Node is an output of that Node
    if (node.layer < layer) {
      for (int i = 0; i < node.outputConnections.size(); i++) {
        if (node.outputConnections.get(i).toNode == this) {
          return true;
        }
      }
    }
    // Otherwise check to see if the other Node is an output of this Node
    else {
      for (int i = 0; i < outputConnections.size(); i++) {
        if (outputConnections.get(i).toNode == node) {
          return true;
        }
      }
    }
    return false;
  }
  // Clone the Node
  Node clone() {
    Node clone = new Node(id);
    clone.layer = layer;
    return clone;
  }
  String toString() {
    return "N<"+id+", "+layer+">";
  }
}
Node nodeFromString(String str) {
  try {
    String[] split = str.split("N<")[1].split(">")[0].split(", ");
    int id = Integer.parseInt(split[0]);
    int layer = Integer.parseInt(split[1]);
    Node out = new Node(id);
    out.layer = layer;
    return out;
  } catch (Exception e) {
    e.printStackTrace();
    return null;
  }
}
