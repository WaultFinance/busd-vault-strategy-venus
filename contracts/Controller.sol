//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IStrategy.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapRouter.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/Address.sol";
import "./libraries/EnumerableSet.sol";
import "./libraries/SafeMath.sol";

contract Controller {
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    uint256 public marketFee = 200;
    uint256 public strategistFee = 800;
    uint256 public calcDiffRate = 9990; // 0.999 difference
    uint256 public constant FEE_DENOMINATOR = 10000;

    bool internal _sendAsOrigin = false;
    bool public runHarvestOnWithdraw = true;
    bool public useGlobalRewardRate = false;
    uint256 public distLimitPerTrans = 30;
    uint256 public distributePeriodBlocks = 1200; // 1 hour
    uint256 public currentDistributeIndex;
    uint256 public lastGlobalRewardRate;
    uint256 public withdrawLockPeriod = 0;
    uint256 public withdrawRewardsLockPeriod = 0;

    uint256 public currentWaultSupply = 1000000000000000000000; // 1000 WAULT
    uint256 public startForDistributeWault;
    uint256 public endForDistributeWault;
    uint256 public lastDistributedBlock;

    mapping (address => uint256) internal _balanceOfMarketer;
    mapping (address => uint256) internal _balanceOfStrategist;

    address public _uniswapRouter = address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    address public _wault = address(0x6Ff2d9e5891a7a7c554b80e0D1B791483C78BcE9);
    address public _wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    // Info of each user
    struct UserReward {
        uint256 shares;
        uint256 rewardDebt;
        uint256 waultRewards;
        uint256 lastRewardedBlock;   
        uint256 lastRewardedTime;
        uint256 lastWithdrawRewardsTime;
        uint256 lastWithdrawTime;
        uint256 lastSupplyRate;
        uint256 lastBorrowRate;
        uint256 lastSupplyRewardRate;
        uint256 lastBorrowRewardRate;
    }

    address public governance;
    address public strategist = address(0xC627D743B1BfF30f853AE218396e6d47a4f34ceA);
    address public rewards;
    address public marketer;

    // mapping between (token, vault)
    mapping (address => address) public vaults;

    // active strategy on certain token (token, strategy)
    mapping (address => address) public strategies;

    // token -> strategy[]
    mapping (address => EnumerableSet.AddressSet) availableStrategies;

    // Info of each user in vaults
    mapping(address => mapping(address => UserReward)) public userRewards;

    // Users in vaults
    mapping(address => EnumerableSet.AddressSet) users;

    // Path to swap wanted token to Wault
    mapping(address => address[]) swapPaths;

    modifier onlyAdmin {
        require(msg.sender == governance || msg.sender == strategist, "!admin");
        _;
    }

    constructor() {
        governance = msg.sender;
        marketer = msg.sender;
        rewards = address(this);
    }

    function enableTestnet() external onlyAdmin {
        _uniswapRouter = address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        _wault = address(0xC87957427D5b5caC14c7F5bB2CEfE9cb55774709);
        _wbnb = address(0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F);

        _sendAsOrigin = true;
    }

    function balanceOfWault() public view returns(uint256) {
        return IERC20(_wault).balanceOf(address(this));
    }

    function withdrawWault(uint256 _amount) public onlyAdmin {
        uint256 _balance = balanceOfWault();
        if (_amount > _balance) _amount = _balance;
        IERC20(_wault).safeTransfer(msg.sender, _amount);
    }

    function withdrawWaultAll() external onlyAdmin {
        withdrawWault(balanceOfWault());
    }
    
    function balanceOfMarketer(address _token) external view returns(uint256) {
        return _balanceOfMarketer[_token];
    }

    function balanceOfMarketerAsWault(address _token) external view returns(uint256) {
        return _balanceOfWault(_token, _balanceOfMarketer[_token]);
    }

    function balanceOfStrategist(address _token) external view returns(uint256) {
        return _balanceOfStrategist[_token];
    }

    function balanceOfStrategistAsWault(address _token) external view returns(uint256) {
        return _balanceOfWault(_token, _balanceOfStrategist[_token]);
    }

    function setMarketer(address _marketer) external onlyAdmin {
        marketer = _marketer;
    }

    function setStrategist(address _strategist) external onlyAdmin {
        strategist = _strategist;
    }

    function setGovernance(address _governance) external onlyAdmin {
        governance = _governance;
    }

    function setRewards(address _rewards) external onlyAdmin {
        rewards = _rewards;
    }

    function setStrategistFee(uint256 _fee) external onlyAdmin {
        strategistFee = _fee;
    }

    function setMarketFee(uint256 _fee) external onlyAdmin {
        marketFee = _fee;
    }

    function setCalcDiffRate(uint256 _rate) external onlyAdmin {
        calcDiffRate = _rate;
    }

    function setRunHarvestOnWithdraw(bool _flag) external onlyAdmin {
        runHarvestOnWithdraw = _flag;
    }

    function setUseGlobalRewardRate(bool _flag) external onlyAdmin {
        useGlobalRewardRate = _flag;
    }

    function setDistributeLimitPerTansaction(uint256 _limit) external onlyAdmin {
        distLimitPerTrans = _limit;
    }

    function setDistritePeriodBlocks(uint _blocks) external onlyAdmin {
        distributePeriodBlocks = _blocks;
    }

    function userInfo(address _token, address _user) external view onlyAdmin returns(
        uint256 _shares,
        uint256 _reward,
        uint256 _waultReward,
        // uint256 _lastRewardedTime,
        uint256 _lastWithdrawTime,
        uint256 _lastRewardedBlock,
        uint256 _lastSupplyRate,
        uint256 _lastBorrowRate,
        uint256 _lastSupplyRewardRate,
        uint256 _lastBorrowRewardRate) {
        
        UserReward storage user = userRewards[vaults[_token]][_user];
        _shares = user.shares;
        _reward = user.rewardDebt;
        _waultReward = user.waultRewards;
        // _lastRewardedTime = user.lastRewardedTime;
        _lastWithdrawTime = user.lastWithdrawTime;
        _lastRewardedBlock = user.lastRewardedBlock;
        _lastSupplyRate = user.lastSupplyRate;
        _lastBorrowRate = user.lastBorrowRate;
        _lastSupplyRewardRate = user.lastSupplyRewardRate;
        _lastBorrowRewardRate = user.lastBorrowRewardRate;
    }

    function setSendAsOrigin(bool flag) external onlyAdmin {
        _sendAsOrigin = flag;
    }

    function setWithdrawLockPeriod(uint256 _period) external onlyAdmin {
        withdrawLockPeriod = _period;
    }

    function setWithdrawRewardsLockPeriod(uint256 _period) external onlyAdmin {
        withdrawRewardsLockPeriod = _period;
    }

    function setWaultRewardsParams(uint256 _amount, uint256 _start, uint256 _blocks) external onlyAdmin {
        require(_amount > 0, "invalid amount");
        currentWaultSupply = _amount;
        startForDistributeWault = _start;
        endForDistributeWault = _start.add(_blocks);
    }

    function setVault(address _token, address _vault) public onlyAdmin {
        // require(vaults[_token] == address(0), "vault for this token already deployed");

        vaults[_token] = _vault;
    }
    
    function setStrategy(address _token, address _strategy) public onlyAdmin {
        addStrategy(_token, _strategy);

        address current = strategies[_token];
        if (current != address(0)) {
            IStrategy(current).withdrawAll();
        }

        strategies[_token] = _strategy;
    }

    function addStrategy(address _token, address _strategy) public onlyAdmin {
        require(_strategy.isContract(), "Strategy is not a contract");
        require(!availableStrategies[_token].contains(_strategy), "Strategy already exists");

        availableStrategies[_token].add(_strategy);
    }

    function balanceOf(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).balanceOf().add(IERC20(_token).balanceOf(address(this)));
    }

    function withdrawFromAdmin(address _token, uint256 _amount) external onlyAdmin {
        IStrategy(strategies[_token]).withdrawDirect(msg.sender, _amount);
    }

    function _removeUser(address _token, address _user) internal {
        if (users[_token].contains(_user) == true) {
            users[_token].remove(_user);
        }
    }

    function _checkOrAddUser(address _token, address _user) internal {
        if (users[_token].contains(_user) == false) {
            users[_token].add(_user);
        }
    }

    function userCount(address _token) external view returns (uint) {
        return users[_token].length();
    }

    function userList(address _token) external view onlyAdmin returns (address[] memory) {
        address[] memory list = new address[](users[_token].length());

        for (uint256 i = 0; i < users[_token].length(); i++) {
            list[i] = users[_token].at(i);
        }

        return list;
    }

    function withdraw(address _token, uint256 _amount) external {
        require(msg.sender == vaults[_token], "!vault");
        UserReward storage user = userRewards[vaults[_token]][tx.origin];
        require(user.lastWithdrawTime.add(withdrawLockPeriod) < block.timestamp, "!available to withdraw still");

        if (runHarvestOnWithdraw) IStrategy(strategies[_token]).harvest(true);

        IStrategy(strategies[_token]).withdraw(_amount);

        _distributeWaultRewards(_token, tx.origin);
        _distributeRewards(_token, tx.origin);

        if (user.rewardDebt > 0) {
            sendAsWault(_token, tx.origin, user.rewardDebt);
            user.rewardDebt = 0;
        }

        user.lastWithdrawTime = block.timestamp;
        if (user.shares == 0) _removeUser(_token, tx.origin);

        distributeUsersReward(_token, false);
    }

    function earn(address _token, uint256 _amount) public {
        address _strategy = strategies[_token];
        address _want = IStrategy(_strategy).getWant();
        require(_want == _token, "!want");
        IERC20(_token).safeTransfer(_strategy, _amount);
        IStrategy(_strategy).deposit();

        if (useGlobalRewardRate == true && lastGlobalRewardRate == 0) updateGlobalRewardRate(_token);

        _distributeWaultRewards(_token, tx.origin);
        _distributeRewards(_token, tx.origin);
        distributeUsersReward(_token, false);
        _checkOrAddUser(_token, tx.origin);
    }

    function getBestStrategy(address _token) internal view returns (address bestStrategy) {
        bestStrategy = address(0);
        uint maxApy = 0;
        for (uint i = 0; i < availableStrategies[_token].length(); i++) {
            if (bestStrategy == address(0)) {
                bestStrategy = availableStrategies[_token].at(i);
                maxApy = IStrategy(availableStrategies[_token].at(i)).supplyRatePerBlock();
            }

            uint256 apy = IStrategy(availableStrategies[_token].at(i)).supplyRatePerBlock();
            if (maxApy < apy) {
                bestStrategy = availableStrategies[_token].at(i);
                maxApy = apy;
            }
        }

        return bestStrategy;
    }

    function invest(address _token, uint256 _amount) external {
        address currentStrategy = strategies[_token];
        IERC20(_token).safeTransfer(currentStrategy, _amount);
        IStrategy(currentStrategy).deposit();

        if (useGlobalRewardRate == true && lastGlobalRewardRate == 0) updateGlobalRewardRate(_token);

        _distributeWaultRewards(_token, tx.origin);
        _distributeRewards(_token, tx.origin);
        distributeUsersReward(_token, false);
        _checkOrAddUser(_token, tx.origin);
    }

    function _distributeRewards(address _token, address _user) internal {
        uint256 _rewards = _calculateRewards(_token, _user);
        if (_rewards > 0) {
            uint256 _marketFee = _rewards.mul(marketFee).div(FEE_DENOMINATOR);
            uint256 _strategistFee = _rewards.mul(strategistFee).div(FEE_DENOMINATOR);
            uint256 userReward = _rewards.sub(_marketFee).sub(_strategistFee);
            
            UserReward storage user = userRewards[vaults[_token]][_user];
            user.rewardDebt = user.rewardDebt.add(userReward);
            _balanceOfMarketer[_token] = _balanceOfMarketer[_token].add(_marketFee);
            _balanceOfStrategist[_token] = _balanceOfStrategist[_token].add(_strategistFee);
        }
        _updateUserRewardInfo(_token, _user);
    }

    function _calculateRewards(address _token, address _user) internal view returns (uint256) {
        UserReward storage user = userRewards[vaults[_token]][_user];
        uint256 blocks = block.number.sub(user.lastRewardedBlock);
        uint256 totalRate = useGlobalRewardRate ? lastGlobalRewardRate : _calculateTotalRatePerBlock(_token, _user);

        uint256 _rewards = user.shares.mul(blocks).mul(totalRate).div(1e18);
        return _rewards.mul(calcDiffRate).div(FEE_DENOMINATOR);
    }

    function _calculateTotalRatePerBlock(address _token, address _user) internal view returns (uint256) {
        UserReward storage user = userRewards[vaults[_token]][_user];
        uint256 leverageRate = user.lastSupplyRate.add(user.lastSupplyRewardRate).add(user.lastBorrowRewardRate);
        if (IStrategy(strategies[_token]).isRebalance() == false) leverageRate = 0;
        else if (user.lastBorrowRate > leverageRate) leverageRate = 0;
        else leverageRate = leverageRate.sub(user.lastBorrowRate);
        uint256 totalRate = leverageRate
                        .mul(IStrategy(strategies[_token]).borrowLimit()).div(1e18)
                        .add(user.lastSupplyRate)
                        .add(user.lastSupplyRewardRate);

        return totalRate;
    }

    function updateGlobalRewardRate(address _token) public {
        (uint256 supplyRate, uint256 borrowRate, uint256 supplyRewardRate, uint256 borrowRewardRate) = _getStrategyRewardRates(_token);
        uint256 leverageRate = supplyRate.add(supplyRewardRate).add(borrowRewardRate);
        if (IStrategy(strategies[_token]).isRebalance() == false) leverageRate = 0;
        else if (borrowRate > leverageRate) leverageRate = 0;
        else leverageRate = leverageRate.sub(borrowRate);
        lastGlobalRewardRate = leverageRate
                        .mul(IStrategy(strategies[_token]).borrowLimit()).div(1e18)
                        .add(supplyRate)
                        .add(supplyRewardRate);
    }

    function _getStrategyRewardRates(address _token) internal returns (
        uint256 _supplyRate,
        uint256 _borrowRate,
        uint256 _supplyRewardRate,
        uint256 _borrowRewardRate
    ) {
        uint256 available = FEE_DENOMINATOR.sub(IStrategy(strategies[_token]).totalFee());
        _supplyRate = IStrategy(strategies[_token]).supplyRatePerBlock();
        _borrowRate = IStrategy(strategies[_token]).borrowRatePerBlock();
        _supplyRewardRate = IStrategy(strategies[_token]).supplyRewardRatePerBlock().mul(available).div(1e4);
        _borrowRewardRate = IStrategy(strategies[_token]).borrowRewardRatePerBlock().mul(available).div(1e4);
    }

    function _updateUserRewardInfo(address _token, address _user) internal {
        UserReward storage user = userRewards[vaults[_token]][_user];

        user.shares = IERC20(vaults[_token]).balanceOf(_user);
        user.lastRewardedBlock = block.number;
        user.lastRewardedTime = block.timestamp;
        if (user.lastWithdrawTime == 0) user.lastWithdrawTime = block.timestamp;
        if (user.lastWithdrawRewardsTime == 0) user.lastWithdrawRewardsTime = block.timestamp;
        if (lastDistributedBlock == 0) lastDistributedBlock = block.number;
        if (useGlobalRewardRate == false) {
            uint256 available = FEE_DENOMINATOR.sub(IStrategy(strategies[_token]).totalFee());
            user.lastSupplyRate = IStrategy(strategies[_token]).supplyRatePerBlock();
            user.lastBorrowRate = IStrategy(strategies[_token]).borrowRatePerBlock();
            user.lastSupplyRewardRate = IStrategy(strategies[_token]).supplyRewardRatePerBlock().mul(available).div(1e4);
            user.lastBorrowRewardRate = IStrategy(strategies[_token]).borrowRewardRatePerBlock().mul(available).div(1e4);
        }
    }

    function _distributeWaultRewards(address _token, address _user) internal {
        if (block.number > endForDistributeWault || block.number < startForDistributeWault) return;
            
        UserReward storage user = userRewards[vaults[_token]][_user];
        uint256 waultRewardsPerBlock = currentWaultSupply.div(endForDistributeWault.sub(startForDistributeWault));
        uint256 totalSupply = IERC20(vaults[_token]).totalSupply();
        uint256 lastBlock = startForDistributeWault > user.lastRewardedBlock ? startForDistributeWault : user.lastRewardedBlock;
        uint256 waultRewards = block.number.sub(lastBlock).mul(waultRewardsPerBlock).mul(user.shares).div(totalSupply);
        user.waultRewards = user.waultRewards.add(waultRewards);
    }

    function updateUsersReward(address _token) public {
        if (lastDistributedBlock == 0) lastDistributedBlock = block.number;
        if (useGlobalRewardRate == true && lastGlobalRewardRate == 0) updateGlobalRewardRate(_token);
        for (uint i = 0; i < users[_token].length(); i++) {
            UserReward storage user = userRewards[vaults[_token]][users[_token].at(i)];
            if (user.shares == 0) continue;
            _distributeWaultRewards(_token, users[_token].at(i));
            _distributeRewards(_token, users[_token].at(i));
        }
        lastDistributedBlock = block.number;
        if (useGlobalRewardRate == true) updateGlobalRewardRate(_token);
    }

    function distributeUsersReward(address _token, bool _force) public {
        if (users[_token].length() == 0) return;
        if (lastDistributedBlock == 0) lastDistributedBlock = block.number;

        uint256 startIndex = currentDistributeIndex;

        uint i = startIndex;
        for (uint count = 0; i < users[_token].length() && count < distLimitPerTrans; i++) {
            // Skip running owner
            if (users[_token].at(i) == tx.origin) continue;
            UserReward storage user = userRewards[vaults[_token]][users[_token].at(i)];
            if (user.shares == 0) continue;
            // Doesn't need to update yet
            if (_force == false && user.lastRewardedBlock + distributePeriodBlocks > block.number) continue;
            _distributeWaultRewards(_token, users[_token].at(i));
            _distributeRewards(_token, users[_token].at(i));
            count++;
        }

        currentDistributeIndex = i;
        if (currentDistributeIndex >= users[_token].length()) currentDistributeIndex = 0;
        lastDistributedBlock = block.number;
    }

    function totalRewards(address _token) external view returns (uint _harvestRewards, uint _waultRewards) {
        _harvestRewards = 0;
        _waultRewards = 0;
        for (uint i = 0; i < users[_token].length(); i++) {
            UserReward storage user = userRewards[vaults[_token]][users[_token].at(i)];
            _harvestRewards = _harvestRewards.add(user.rewardDebt);
            _waultRewards = _waultRewards.add(user.waultRewards);
        }
        _harvestRewards = _harvestRewards.add(_balanceOfStrategist[_token]).add(_balanceOfMarketer[_token]);
    }

    function claim(address _token, uint256 _amount) external returns (uint256 _out) {
        require(msg.sender == vaults[_token], "!vault");
        UserReward storage user = userRewards[vaults[_token]][tx.origin];
        require(user.lastWithdrawRewardsTime.add(withdrawRewardsLockPeriod) < block.timestamp, "!available to withdraw rewards still");
        require(user.waultRewards > 0, "!wault rewards");
        require(balanceOfWault() > 0, "!available wault balance in contract");

        if (_amount > user.waultRewards) {
            _amount = user.waultRewards;
        }
        if (_amount > balanceOfWault()) {
            _amount = balanceOfWault();
        }
        IERC20(_wault).safeTransfer(tx.origin, _amount);
        user.waultRewards = user.waultRewards.sub(_amount);
        _out = _amount;

        _distributeWaultRewards(_token, tx.origin);
        _distributeRewards(_token, tx.origin);
        distributeUsersReward(_token, false);

        user.lastWithdrawRewardsTime = block.timestamp;
    }

    function balanceOfRewards(address _token, address _user) external view returns (uint256 _rewards, uint256 _waults) {
        UserReward storage user = userRewards[vaults[_token]][_user];
        _rewards = user.rewardDebt;
        _waults = user.waultRewards;
    }

    function balanceOfUserRewards(address _token, address _user) external view returns (uint256 _rewards, uint256 _waults, uint256 _lastRewardedTime) {
        UserReward storage user = userRewards[vaults[_token]][_user];
        _rewards = user.rewardDebt;
        _waults = user.waultRewards;
        _lastRewardedTime = user.lastRewardedTime;
    }

    function withdrawStrategistRewards(address _token, uint256 _amount) public returns (uint256 _out) {
        require(msg.sender == strategist, "!strategist");
        require(_balanceOfStrategist[_token] > 0, "!balance");
        require(_balanceOfStrategist[_token] >= _amount, "!available balance");

        _out = sendAsWault(_token, msg.sender, _amount);
        _balanceOfStrategist[_token] = _balanceOfStrategist[_token].sub(_amount);
    }

    function withdrawStrategistRewardsAll(address _token) external returns (uint256 _out) {
        require(msg.sender == strategist, "!strategist");
        require(_balanceOfStrategist[_token] > 0, "!balance");
        _out = withdrawStrategistRewards(_token, _balanceOfStrategist[_token]);
    }

    function withdrawMarketerRewards(address _token, uint256 _amount) public returns (uint256 _out) {
        require(msg.sender == marketer, "!marketer");
        require(_balanceOfMarketer[_token] > 0, "!balance");
        require(_balanceOfMarketer[_token] >= _amount, "!available balance");

        _out = sendAsWault(_token, msg.sender, _amount);
        _balanceOfMarketer[_token] = _balanceOfMarketer[_token].sub(_amount);
    }

    function withdrawMarketerRewardsAll(address _token) external returns (uint256 _out) {
        require(msg.sender == marketer, "!marketer");
        require(_balanceOfMarketer[_token] > 0, "!balance");
        _out = withdrawMarketerRewards(_token, _balanceOfMarketer[_token]);
    }

    function sendAsWault(address _token, address _recipient, uint256 _amount) internal returns (uint256 _out) {
        if (_sendAsOrigin == true) {
            sendAsOrigin(_token,_recipient, _amount);
            return _amount;
        }

        _out = IStrategy(strategies[_token]).withdrawAsWault(_recipient, _amount);
    }

    function _balanceOfWault(address _token, uint256 _amount) internal view returns (uint256) {
        if (_amount < 1000000 || _sendAsOrigin == true) return 0;
        address[] memory swapPath = new address[](3);
        swapPath[0] = _token;
        swapPath[1] = _wbnb;
        swapPath[2] =_wault;
        return IUniswapRouter(_uniswapRouter).getAmountsOut(_amount, swapPath)[2];
    }

    function _amountFromWault(address _token, uint256 _amount) internal view returns (uint256) {
        if (_amount == 0 || _sendAsOrigin == true) return 0;
        address[] memory swapPath = new address[](3);
        swapPath[0] = _token;
        swapPath[1] = _wbnb;
        swapPath[2] =_wault;
        return IUniswapRouter(_uniswapRouter).getAmountsIn(_amount, swapPath)[0];
    }

    function sendAsOrigin(address _token, address _recipient, uint256 _amount) internal {
        IStrategy(strategies[_token]).withdrawDirect(_recipient, _amount);
    }
}