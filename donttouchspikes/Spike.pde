class Spike {
  public float x,y,w,h;
  Spike(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  public void draw() {
    fill(255,0,0);
    rect(x,y,w,h);
  }
  public boolean check(float x, float y) {
    return x>this.x && x<this.x+this.w && y>this.y && y<this.y+this.h;
  }
  String toString() {
    return "S<"+x+", "+y+", "+w+", "+h+">";
  }
}
Spike spikeFromString(String str) {
  try {
    String[] split = str.split("S<")[1].split(">")[0].split(", ");
    float x = Float.parseFloat(split[0]);
    float y = Float.parseFloat(split[1]);
    float w = Float.parseFloat(split[2]);
    float h = Float.parseFloat(split[3]);
    return new Spike(x, y, w, h);
  } catch (Exception e) {
    e.printStackTrace();
    return null;
  }
}
String spikeArrayToString(Spike[] arr) {
  String out = "A<";
  for (Spike s : arr) {
    out += s+", ";
  }
  out = out.substring(0, out.length()-2)+">";
  return out;
}
Spike[] spikeArrayFromString(String str) {
  ArrayList<Spike> temp = new ArrayList<Spike>();
  while (str.contains("S<")) {
    String spikeStr = str.substring(str.indexOf("S<"), str.indexOf(">")+1);
    temp.add(spikeFromString(spikeStr));
    str = str.substring(str.indexOf(">")+1,str.length());
  }
  Spike[] out = new Spike[temp.size()];
  for (int i = 0; i < out.length; i++) {
    out[i] = temp.get(i);
  }
  return out;
}
String spikesToString(ArrayList<Spike[]> arr) {
  if (arr.size() == 0) {
    return "";
  }
  String out = "A;";
  for (Spike[] s : arr) {
    out += spikeArrayToString(s)+"', ;";
  }
  return out.substring(0, out.length()-3); // removes last ", ;"
}
ArrayList<Spike[]> spikesFromString(String str) {
  ArrayList<Spike[]> out = new ArrayList<Spike[]>();
  while (str.contains(";")) {
    String forSpikeArr = str.split(";")[1].split("'")[0];
    out.add(spikeArrayFromString(forSpikeArr));
    str = str.substring(str.indexOf(forSpikeArr)+forSpikeArr.length()+3, str.length());
  }
  return out;
}
