import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import Text "mo:base/Text";
import List "mo:base/List";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";

actor class TaskBackend() {
 
  var isProcessing : Bool = false;
  type F = (Principal, Nat) -> ?(Bool, Text);
  type QueueEntry = {
    f: F;
    principal: Principal;
    tokenID: Nat;
  };
  type Queue = List.List<QueueEntry>;
  var queueMap: HashMap.HashMap<Text, Queue> = HashMap.HashMap<Text, Queue>(0, Text.equal, Text.hash);

  public shared(msg) func upgradeNFTask(tokenID: Nat) : async ?(Bool, Text) {   
    let result = await enqueue(upgradeNFT, msg.caller, tokenID);
    await delay(8000);
    isProcessing := false;
    result;
  };

  func upgradeNFT(id: Principal, tokenID: Nat) : ?(Bool, Text) {
    ?(true, "upgraded NFT");
  };

  func enqueue(f: F, principal: Principal, tokenID: Nat) : async ?(Bool, Text) {
    let tokenIDText = Nat.toText(tokenID);
    let queue = switch (queueMap.get(tokenIDText)) {
      case null { List.nil<QueueEntry>() };
      case (?q) { q };
    };
    let updatedQueue = List.push({f; principal; tokenID}, queue);
    queueMap.put(tokenIDText, updatedQueue);
    if (not isProcessing) {
      isProcessing := true;
      return dequeue(tokenIDText);
    } else {
      ?(true, "added to queue");
    }
  };

  func dequeue(tokenIDText: Text) : ?(Bool, Text) {
    let queue = switch (queueMap.get(tokenIDText)) {
      case null { List.nil<QueueEntry>() };
      case (?q) { q };
    };
    switch (List.pop(queue)) {
      case (null, _) {
        null
      };
      case (?entry, tail) {
        queueMap.put(tokenIDText, tail);
        entry.f(entry.principal, entry.tokenID);
      };
    };
  };

  public query func getQueue(tokenID: Nat) : async List.List<(Principal, Nat)> {
    let tokenIDText = Nat.toText(tokenID);
    let queue = switch (queueMap.get(tokenIDText)) {
      case null { List.nil<QueueEntry>() };
      case (?q) { q };
    };
    List.map<QueueEntry, (Principal, Nat)>(queue, func (entry: QueueEntry) : (Principal, Nat) {
      (entry.principal, entry.tokenID)
    });
  };

  private func delay(milliseconds: Nat) : async () {
    let start = Time.now();
    let end = start + (milliseconds * 1_000_000); // Convert milliseconds to nanoseconds
    while (Time.now() < end) {
      await async {}; // Yield control, allowing other operations to proceed
    };
  };
};
