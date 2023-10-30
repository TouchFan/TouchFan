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


// File contracts/TouchFanSharesV1.sol

pragma solidity 0.8.17;


contract TouchFanSharesV1 is Ownable {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;
    uint256 public referrerFeePercent;
    address public referrerStorage;

    event Trade(
        address trader,
        address subject,
        bool isBuy,
        uint256 shareAmount,
        uint256 ethAmount,
        uint256 protocolEthAmount,
        uint256 subjectEthAmount,
        uint256 referrerEthAmount,
        uint256 supply,
        uint256 trader_balance,
        uint256 blockTime
    );

    event FeeDestinationSet(address feeDestination);

    event ProtocolFeePercentSet(uint256 feePercent);
    event SubjectFeePercentSet(uint256 feePercent);
    event ReferrerFeePercentSet(uint256 feePercent);
    event ReferrerStorageSet(address referrerStorage);

    struct TradeFees {
        uint256 protocolFee;
        uint256 subjectFee;
        uint256 referrerFee;
    }

    // SharesSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;

    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
        emit FeeDestinationSet(_feeDestination);
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
        emit ProtocolFeePercentSet(_feePercent);
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        subjectFeePercent = _feePercent;
        emit SubjectFeePercentSet(_feePercent);
    }

    function setReferrerFeePercent(uint256 _feePercent) public onlyOwner {
        referrerFeePercent = _feePercent;
        emit ReferrerFeePercentSet(_feePercent);
    }

    function setReferrerStorage(address _referrerStorage) public onlyOwner {
        referrerStorage = _referrerStorage;
        emit ReferrerStorageSet(_referrerStorage);
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply)* (supply+1000000) * (2 * (supply) + 1000000) / 6;
        uint256 sum2 =  (supply + amount) * (supply + 1000000 + amount) * (2 * (supply + amount) + 1000000) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000000000000000000000;
    }

    function getBuyPrice(address sharesSubject, uint256 amount)
        public
        view
        returns (uint256)
    {
        return getPrice(sharesSupply[sharesSubject], amount);
    }

    function getSellPrice(address sharesSubject, uint256 amount)
        public
        view
        returns (uint256)
    {
        return getPrice(sharesSupply[sharesSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(address sharesSubject, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 price = getBuyPrice(sharesSubject, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        uint256 referrerFee = (price * referrerFeePercent) / 1 ether;
        return price + protocolFee + subjectFee + referrerFee;
    }

    function getSellPriceAfterFee(address sharesSubject, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 price = getSellPrice(sharesSubject, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        uint256 referrerFee = (price * referrerFeePercent) / 1 ether;
        return price - protocolFee - subjectFee - referrerFee;
    }

    function buyShares(address sharesSubject, uint256 amount) public payable {
        require(amount > 0, "invalid amount");
        address referrer = IReferrerStorage(referrerStorage).referrers(
            msg.sender
        );
        require(referrer != address(0), "Need invite");
        uint256 supply = sharesSupply[sharesSubject];
        require(
            supply > 0 || sharesSubject == msg.sender,
            "Only the shares' subject can buy the first share"
        );
        uint256 price = getPrice(supply, amount);
        TradeFees memory tradeFees;
        tradeFees.protocolFee = (price * protocolFeePercent) / 1 ether;
        tradeFees.subjectFee = (price * subjectFeePercent) / 1 ether;
        tradeFees.referrerFee = (price * referrerFeePercent) / 1 ether;
        require(
            msg.value >=
                price +
                    tradeFees.protocolFee +
                    tradeFees.subjectFee +
                    tradeFees.referrerFee,
            "Insufficient payment"
        );
        uint256 traderBalance = sharesBalance[sharesSubject][msg.sender] =
            sharesBalance[sharesSubject][msg.sender] +
            amount;
        sharesSupply[sharesSubject] = supply + amount;

        {
            (bool success1, ) = protocolFeeDestination.call{
                value: tradeFees.protocolFee
            }("");
            (bool success2, ) = sharesSubject.call{value: tradeFees.subjectFee}(
                ""
            );
            (bool success3, ) = referrer.call{value: tradeFees.referrerFee}("");
            require(success1 && success2 && success3, "Unable to send funds");
        }

        emit Trade(
            msg.sender,
            sharesSubject,
            true,
            amount,
            price,
            tradeFees.protocolFee,
            tradeFees.subjectFee,
            tradeFees.referrerFee,
            supply + amount,
            traderBalance,
            block.timestamp
        );
    }

    function sellShares(address sharesSubject, uint256 amount) public payable {
        require(amount > 0, "invalid amount");
        address referrer = IReferrerStorage(referrerStorage).referrers(
            msg.sender
        );
        require(referrer != address(0), "Need invite");
        uint256 supply = sharesSupply[sharesSubject];
        require(supply > amount, "Cannot sell the last share");
        uint256 price = getPrice(supply - amount, amount);

        TradeFees memory tradeFees;

        tradeFees.protocolFee = (price * protocolFeePercent) / 1 ether;
        tradeFees.subjectFee = (price * subjectFeePercent) / 1 ether;
        tradeFees.referrerFee = (price * referrerFeePercent) / 1 ether;
        require(
            sharesBalance[sharesSubject][msg.sender] >= amount,
            "Insufficient shares"
        );
        uint256 traderBalance = sharesBalance[sharesSubject][msg.sender] =
            sharesBalance[sharesSubject][msg.sender] -
            amount;
        sharesSupply[sharesSubject] = supply - amount;
        {
            (bool success1, ) = msg.sender.call{
                value: price -
                    tradeFees.protocolFee -
                    tradeFees.subjectFee -
                    tradeFees.referrerFee
            }("");
            (bool success2, ) = protocolFeeDestination.call{
                value: tradeFees.protocolFee
            }("");
            (bool success3, ) = sharesSubject.call{value: tradeFees.subjectFee}(
                ""
            );
            (bool success4, ) = referrer.call{value: tradeFees.referrerFee}("");
            require(
                success1 && success2 && success3 && success4,
                "Unable to send funds"
            );
        }
        emit Trade(
            msg.sender,
            sharesSubject,
            false,
            amount,
            price,
            tradeFees.protocolFee,
            tradeFees.subjectFee,
            tradeFees.referrerFee,
            supply - amount,
            traderBalance,
            block.timestamp
        );
    }
}
