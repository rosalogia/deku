open Helpers;
open Protocol;

[@deriving yojson]
type identity = {
  key: Address.key,
  t: Address.t,
  uri: Uri.t,
};

module Address_map: Map.S with type key = Address.t;
module Uri_map: Map.S with type key = Uri.t;
type t = {
  identity,
  trusted_validator_membership_change: Trusted_validators_membership_change.Set.t,
  interop_context: Tezos_interop.Context.t,
  data_folder: string,
  pending_side_ops: list(Operation.Side_chain.t),
  pending_main_ops: list(Operation.Main_chain.t),
  block_pool: Block_pool.t,
  protocol: Protocol.t,
  snapshots: Snapshots.t,
  // networking
  uri_state: Uri_map.t(string),
  validators_uri: Address_map.t(Uri.t),
  recent_operation_results:
    BLAKE2B.Map.t([ | `Transaction | `Withdraw(Ledger.Handle.t)]),
  /** A list of triples including:
    - State root hash - an indentifier for a state root onto which you can apply
          blocks and know the current state
    - Validator hash - the hash of all the validators approved in corresponding
          state root.
    - Epoch of the state root hash - a timestampe generated when the hash
          of the state root began to be created.

    FIXME: clarify terminology of epoch vs finality period. Basically same thing.
    (Actually I've started to clarify this more in flows.re [try_to_produce_block])

    The state root starts with genesis, and then updates every finality
    period (approximately every 60 seconds). This means you don't have to
    download the entire history of the chain to derive the state corresponding
    to a given block - only the state corresponding to its state root hash is required.

    At the start of each new finality period, we start hashing the current
    state, requiring every validator to finish hashing that same state before
    the start of the next finality period. At the end of the finality
    period, the state hash finished in that period becomes the hash used
    in the next finality period. Because a block always points to the state
    hash of the previous period, nodes does not need to wait for the expensive
    operation of hashing to complete before they can apply a block, and can thus
    hash the state asynchronously. */
  state_root_hash_list: list((BLAKE2B.t, BLAKE2B.t, float)),
};

let make:
  (
    ~identity: identity,
    ~trusted_validator_membership_change: Trusted_validators_membership_change.Set.t,
    ~interop_context: Tezos_interop.Context.t,
    ~data_folder: string,
    ~initial_validators_uri: Address_map.t(Uri.t)
  ) =>
  t;
let apply_block:
  (t, Block.t) =>
  result(t, [> | `Invalid_block_when_applying | `Invalid_state_root_hash]);

let load_snapshot:
  (
    ~state_root_hash: BLAKE2B.t,
    ~state_root: string,
    ~additional_blocks: list(Block.t),
    ~last_block: Block.t,
    ~last_block_signatures: list(Signature.t),
    t
  ) =>
  result(
    t,
    [>
      | `Invalid_block_when_applying
      | `Invalid_state_root_hash
      | `Not_all_blocks_are_signed
      | `Snapshots_with_invalid_hash
      | `State_root_not_the_expected
    ],
  );
