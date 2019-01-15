pragma solidity ^0.5.2;

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    function transfer(address to, uint256 value) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }
}

contract Ownable {
    address payable internal owner;

    constructor () internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}


contract Crowdsale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private token = IERC20();

    uint256 start;
    uint256 qcoins = 2767011611;
    mapping(address => bool) private whitelist;
    mapping(address => uint256) private balances1;
    mapping(address => uint256) private balances2;
    mapping(address => bool) private paid;
    uint256 private totalScore;
    uint256 private price;

    constructor () internal {
        start = now;
    }

    function approve(address client) public onlyOwner {
        require(client != address(0));
        whitelist[client] = true;
    }

    function remove(address client) public onlyOwner {
        require(client != address(0));
        whitelist[client] = false;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount != 0);
        require(amount < address(this).balance);
        owner.transfer(amount);
    }

    function purchase(address client) public nonReentrant payable {
        uint256 amount = msg.value;
        require(client != address(0));
        require(whitelist[client]);
        require(amount != 0);
        require(now < start + 8 weeks);

        if (now < start + 4 weeks) {
            amount = amount.div(10).mul(11);
            balances1[client] = balances1[client].add(amount);
        } else {
            balances2[client] = balances2[client].add(amount);
        }
        totalScore = totalScore.add(amount);
    }

    function () external payable {
        purchase(msg.sender);
    }

    function calculatePrice() public onlyOwner {
        require(now > start + 8 weeks);
        require(price == 0);

        price = totalScore.div(qcoins);
    }

    function payout(address client) public onlyOwner {
        require(now > start + 8 weeks);
        require(price != 0);
        require(!(paid[client]));

        uint256 balance = balances1[client].add(balances2[client]);
        uint256 amount = balance.div(price).mul(10 ** 9);
        token.safeTransfer(client, amount);
        paid[client] = true;
    }
}
