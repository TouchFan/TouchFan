// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.9.3

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.17;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.9.3

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity 0.8.17;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/interfaces/IReferrerStorage.sol

pragma solidity 0.8.17;


interface IReferrerStorage {
    event ReferrerSet(
        address sender,
        address referrer,
        uint256 blockTime
    );
    function referrers(address _sender) external view returns(address referrer);
    function setReferrer(address _referrer) external;


}


// File contracts/TFCommunitySharesV1.sol

pragma solidity 0.8.17;


contract TFCommunitySharesV1 is Ownable {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public referrerFeePercent;

    address public manager;
    address public referrerStorage;
    uint256 public proposalID = 1;
    uint256 public proposalFee;
    event Trade(
        address trader,
        uint256 CommunityID,
        bool isBuy,
        uint256 shareAmount,
        uint256 ethAmount,
        uint256 protocolEthAmount,
        uint256 referrerEthAmount,
        uint256 supply,
        uint256 trader_balance,
        uint256 blockTime
    );

    event ReferrerSet(address sender, address referrer, uint256 blockTime);

    event FeeDestinationSet(address feeDestination);
    event ManagerSet(address manager);
    event ProtocolFeePercentSet(uint256 feePercent);

    event ReferrerFeePercentSet(uint256 feePercent);

    event ReferrerStorageSet(address referrerStorage);

    event ProposalFeeSet(uint256 proposalFee);



    event ProposalCreated(
        address sender,
        uint256 proposalID,
        string description,
        uint256 proposalFee,
        uint256 blockTime
    );

    event ProposalStateUpdated(
        address sender,
        uint256 proposalID,
        string description,
        uint256 blockTime
    );

    event ForFollowersPaid(
        address sender,
        uint256 proposalID,
        uint256 followersFee,
        uint256 blockTime
    );


    event ProposalStateUpdatedFollowers(
        address sender,
        uint256 proposalID,
        uint256 toPayFollowers,
        uint256 toPayEthForFollowers,
        uint256 blockTime
    );

    struct Proposal {
        string description;
        address proposer;
        uint256 toPayFollowers;
        uint256 toPayEthForFollowers;
        uint256 forVotes;
        uint256 timestamp;
        bool paySuccess;
        bool success;
    }

    mapping(uint256 => Proposal) public proposalsBy;

    // sender => (description => created)
    mapping(address => mapping(string => bool)) public createProposalRecords;

    // CommunityID => (Holder => Balance)
    mapping(uint256 => mapping(address => uint256))
        public communitySharesBalance;

    // CommunityID => Supply
    mapping(uint256 => uint256) public communitySharesSupply;

    modifier onlyManager() {
        require(manager == msg.sender, "caller is not the manager");
        _;
    }

    function setManager(address _manager) public onlyOwner {
        manager = _manager;
        emit ManagerSet(_manager);
    }

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
        emit FeeDestinationSet(_feeDestination);
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
        emit ProtocolFeePercentSet(_feePercent);
    }

    function setReferrerFeePercent(uint256 _feePercent) public onlyOwner {
        referrerFeePercent = _feePercent;
        emit ReferrerFeePercentSet(_feePercent);
    }

    function setReferrerStorage(address _referrerStorage) public onlyOwner {
        referrerStorage = _referrerStorage;
        emit ReferrerStorageSet(_referrerStorage);
    }

    function setProposalFee(uint256 _proposalFee) public onlyOwner {
        proposalFee = _proposalFee;
        emit ProposalFeeSet(_proposalFee);
    }

    function createProposal(string memory description) public payable {
        require(msg.value >= proposalFee, "Insufficient proposalFee");
        require(!createProposalRecords[msg.sender][description], "Proposal created");

        // Get a reference to the new proposal
        Proposal memory newProposal = Proposal({
            description: description,
            proposer: msg.sender,
            forVotes: 0,
            toPayFollowers : 0,
            toPayEthForFollowers:0,
            timestamp: 0,
            paySuccess : false,
            success: false
        });
        proposalsBy[proposalID] = newProposal;

        (bool success1, ) = protocolFeeDestination.call{value: msg.value}("");
        require(success1, "proposalFee send error");

        createProposalRecords[msg.sender][description] = true;

        emit ProposalCreated(
            msg.sender,
            proposalID,
            description,
            msg.value,
            block.timestamp
        );
        proposalID = proposalID + 1;
    }
    function payForFollowers(uint256 _proposalID ) public payable {
        require(!proposalsBy[_proposalID].paySuccess, "not match");

        proposalsBy[_proposalID].paySuccess = true;

        require(msg.value == proposalsBy[_proposalID].toPayEthForFollowers, "Insufficient payFee");


        (bool success1, ) = protocolFeeDestination.call{value: msg.value}("");
        require(success1, "payFee send error");

        emit ForFollowersPaid(
            msg.sender,
            _proposalID,
            msg.value,
            block.timestamp
        );
    }

    function updateProposalFollowers(uint256 _proposalID, uint256 _followers, uint256 _toPayEthForFollowers)
    public
    onlyManager
    {
        require(!proposalsBy[_proposalID].success, "not match");
        require(!proposalsBy[_proposalID].paySuccess, "Already paid");

        // Get a reference to the  proposal
        Proposal storage proposal = proposalsBy[_proposalID];
        // Set the fields of the proposal
        proposal.toPayFollowers = _followers;
        proposal.toPayEthForFollowers = _toPayEthForFollowers;

        emit ProposalStateUpdatedFollowers(
            msg.sender,
            _proposalID,
            _followers,
            _toPayEthForFollowers,
            block.timestamp
        );
    }

    function updateProposalState(uint256 _proposalID, uint256 _forVotes)
        public
        onlyManager
    {
        require(!proposalsBy[_proposalID].success, "not match");

        // Get a reference to the  proposal
        Proposal storage proposal = proposalsBy[_proposalID];
        // Set the fields of the proposal
        proposal.forVotes = _forVotes;
        proposal.success = true;
        proposal.timestamp = block.timestamp;

        emit ProposalStateUpdated(
            msg.sender,
            _proposalID,
            proposal.description,
            block.timestamp
        );
    }

    function getPrice(uint256 supply, uint256 amount)
        public
        pure
        returns (uint256)
    {
        uint256 sum1 = supply == 0 ? 0 : (supply)* (supply+1000000) * (2 * (supply) + 1000000) / 6;
        uint256 sum2 =  (supply + amount) * (supply + 1000000 + amount) * (2 * (supply + amount) + 1000000) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000000000000000000000;
    }

    function getCommunityBuyPrice(uint256 communityID, uint256 amount)
        public
        view
        returns (uint256)
    {
        return getPrice(communitySharesSupply[communityID], amount);
    }

    function getCommunitySellPrice(uint256 communityID, uint256 amount)
        public
        view
        returns (uint256)
    {
        return getPrice(communitySharesSupply[communityID] - amount, amount);
    }

    function getCommunityBuyPriceAfterFee(uint256 communityID, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 price = getCommunityBuyPrice(communityID, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 referrerFee = (price * referrerFeePercent) / 1 ether;
        return price + protocolFee + referrerFee;
    }

    function getCommunitySellPriceAfterFee(uint256 communityID, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 price = getCommunitySellPrice(communityID, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 referrerFee = (price * referrerFeePercent) / 1 ether;
        return price - protocolFee - referrerFee;
    }

    function buyCommunityShares(uint256 communityID, uint256 amount)
        public
        payable
    {
        require(amount > 0, "invalid amount");
        address referrer = IReferrerStorage(referrerStorage).referrers(
            msg.sender
        );
        require(referrer != address(0), "Need invite");

        require(proposalsBy[communityID].success, "proposal not success");

        uint256 supply = communitySharesSupply[communityID];
        require(
            supply > 0 ||
                proposalsBy[communityID].proposer == msg.sender ||
                block.timestamp > proposalsBy[communityID].timestamp + 24 hours,
            "Only the shares' subject can buy the first share"
        );
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 referrerFee = (price * referrerFeePercent) / 1 ether;
        require(
            msg.value >= price + protocolFee + referrerFee,
            "Insufficient payment"
        );
        uint256 traderBalance = communitySharesBalance[communityID][
            msg.sender
        ] = communitySharesBalance[communityID][msg.sender] + amount;
        communitySharesSupply[communityID] = supply + amount;
        {
            (bool success1, ) = protocolFeeDestination.call{value: protocolFee}(
                ""
            );
            (bool success2, ) = referrer.call{value: referrerFee}("");
            require(success1 && success2, "Unable to send funds");
        }

        emit Trade(
            msg.sender,
            communityID,
            true,
            amount,
            price,
            protocolFee,
            referrerFee,
            supply + amount,
            traderBalance,
            block.timestamp
        );
    }

    function sellCommunityShares(uint256 communityID, uint256 amount)
        public
        payable
    {
        require(amount > 0, "invalid amount");
        address referrer = IReferrerStorage(referrerStorage).referrers(
            msg.sender
        );
        require(referrer != address(0), "Need invite");
        //require(proposalsBy[communityID].success, "proposal not success");

        uint256 supply = communitySharesSupply[communityID];
        require(supply > amount, "Cannot sell the last share");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 referrerFee = (price * referrerFeePercent) / 1 ether;
        require(
            communitySharesBalance[communityID][msg.sender] >= amount,
            "Insufficient shares"
        );
        uint256 traderBalance = communitySharesBalance[communityID][
            msg.sender
        ] = communitySharesBalance[communityID][msg.sender] - amount;
        communitySharesSupply[communityID] = supply - amount;
        {
            (bool success1, ) = msg.sender.call{
                value: price - protocolFee - referrerFee
            }("");
            (bool success2, ) = protocolFeeDestination.call{value: protocolFee}(
                ""
            );
            (bool success3, ) = referrer.call{value: referrerFee}("");
            require(success1 && success2 && success3, "Unable to send funds");
        }
        emit Trade(
            msg.sender,
            communityID,
            false,
            amount,
            price,
            protocolFee,
            referrerFee,
            supply - amount,
            traderBalance,
            block.timestamp
        );
    }
}
