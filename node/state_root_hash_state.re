open Helpers;
open Protocol;

module State_root_hash_set = Set.Make(BLAKE2B);
module Block_set = Set.Make(Block);

type t = {
  done_hashes: State_root_hash_set.t,
  pending_hashes: Block_set.t,
};

let is_in_sync = state => Block_set.is_empty(state.pending_hashes);

type effect =
  | Sign_block(Block.t);

let handle_receive_block =
    ({done_hashes, pending_hashes}, ~current_state_root_hash, ~block) =>
  // If the received block's state root hash is equal to the current
  // state root hash then sign the block.
  if (block.Block.state_root_hash == current_state_root_hash) {
    ({done_hashes, pending_hashes}, Some(Sign_block(block)));
  } else if (State_root_hash_set.mem(block.state_root_hash, done_hashes)) {
    (
      // Else, check if the block's state root hash is in done_hashes.
      // If it is, sign the block and remove the block's state root hash
      // from done_hashes
      {
        done_hashes:
          State_root_hash_set.remove(block.state_root_hash, done_hashes),
        pending_hashes,
      },
      Some(Sign_block(block)),
    );
  } else {
    (
      // Otherwise, add the block's state root hash to pending_hashes
      {done_hashes, pending_hashes: Block_set.add(block, pending_hashes)},
      None,
    );
  };

let handle_hashing_finished =
    ({done_hashes, pending_hashes}, state_root_hash) => {
  let (blocks_with_this_state_root_hash, other_blocks) =
    Block_set.fold(
      (b, (blocks_with_this_state_root_hash, other_blocks)) =>
        if (b.state_root_hash == state_root_hash) {
          (blocks_with_this_state_root_hash, other_blocks);
        } else {
          (blocks_with_this_state_root_hash, other_blocks);
        },
      pending_hashes,
      ([], []),
    );
  ({done_hashes: State_root_hash_set.add()})
  assert(false);
  // let (blocks_with_this_state_root_hash, other_blocks) =
  //     // {
  //     //   done_hashes,
  //     //   pending_hashes:
  //     //     Block_set.filter(b => b.state_root_hash != state_root_hash),
  //     // },
  //   );
  // ();
};
