const TimeEnumes = {
  hours: "hours",
  days: "days",
  minutes: "minutes",
  seconds: "seconds",
  weeks: "weeks",
  years: "years",
};

const CommonErrorMsg = {
  PAUSE: "Pausable: paused",
  CHECK_ADMIN: "Caller is not admin",
};

const TreeAuctionErrorMsg = {
  MANUAL_WITHDRAW_USER_BALANCE: "User balance is not enough",
  TREE_STATUS: "the tree is on other provide",
  BID_VALUE: "invalid amount",
  BID_BEFORE_START: "auction not started",
  BID_AFTER_END: "auction already ended",
  END_AUCTION_BEFORE_END_TIME: "Auction not yet ended",
  END_AUCTION_WHEN_IT_HAS_BEEN_ENDED: "endAuction has already been called",
};

const IncrementalSellErrorMsg = {
  TREE_STATUS: "one of trees is on other provide.",
  INVALID_PARAM: "all params must have value",
  INVALID_AMOUNT: "invalid amount",
  OFFER_NOT_RUNNING: "offer not runing"
};

const GenesisTreeErrorMsg = {
  PLANT_TREE_WITH_PLANTER: "planter of tree can plant it",
  PLANT_TREE_ACCESS_NO_PLANTER: "planter in gb can plant tree",
  VERIFY_PLANT_ACCESS: "ambassador or planter can verify plant",
  VERIFY_PLANT_BY_PLANTER: "Planter of tree can't accept update",
  INVALID_TREE_STATUS_IN_VERIFY_PLANT: "invalid tree status",
  INVALID_UPDATE_STATUS_IN_VERIFY_PLANT: "invalid update status",
  DUPLICATE_TREE: "duplicate tree",
  INVALID_IPFS: "invalid ipfs hash",
  INVALID_TREE_STATUS_FOR_PLANT: "invalid tree status for plant",
  TREE_IS_PLANTED_BEFORE: "the tree is planted",
  INVALID_GB: "invalid gb",
  INVALID_PLANTER: "invalid planter data",
  INVALID_TREE: "invalid tree",
  UPDATE_TIME_NOT_REACH: "Update time not reach",
  ONLY_PLANTER_OF_TREE_CAN_SEND_UPDATE: "Only Planter of tree can send update",
  TREE_NOT_PLANTED: "Tree not planted",
  ADMIN_ABBASSADOR_PLANTER: "Admin or ambassador or planter can accept updates",
  INVALID_ACCESS_PLANTER_OF_TREE: "Planter of tree can't verify update",
  UPDATE_STATUS_MUST_BE_PENDING: "update status must be pending",
  CALLER_IS_NOT_AUCTION_OR_INCS: "Caller is not IncrementalSell or Auction",
  CALLER_IS_NOT_AUCTION: "Caller is not Auction",
};

module.exports = {
  TimeEnumes,
  CommonErrorMsg,
  TreeAuctionErrorMsg,
  IncrementalSellErrorMsg,
  GenesisTreeErrorMsg,
};