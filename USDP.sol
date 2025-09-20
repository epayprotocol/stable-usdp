// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC20 {
    // metadata
    string public name;
    string public symbol;
    uint8 public immutable decimals;

    // accounting
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        decimals = 18;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        require(currentAllowance >= value, "ERC20: insufficient allowance");
        unchecked {
            _approve(from, msg.sender, currentAllowance - value);
        }
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from zero");
        require(to != address(0), "ERC20: transfer to zero");
        uint256 fromBal = balanceOf[from];
        require(fromBal >= value, "ERC20: transfer amount exceeds balance");
        unchecked {
            balanceOf[from] = fromBal - value;
        }
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from zero");
        require(spender != address(0), "ERC20: approve to zero");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _mint(address to, uint256 value) internal {
        require(to != address(0), "ERC20: mint to zero");
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        require(from != address(0), "ERC20: burn from zero");
        uint256 bal = balanceOf[from];
        require(bal >= value, "ERC20: burn amount exceeds balance");
        unchecked {
            balanceOf[from] = bal - value;
        }
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }
}

interface Oracle { function latestAnswer() external view returns (uint256); }

contract USDP is ERC20("E-Pay Dollar USD", "USDP") {
    address public manager;

    uint256 public constant INITIAL_SUPPLY = 5_000_000_000 * 10**18;

    constructor(address _initialManager) {
        manager = _initialManager;
        _mint(_initialManager, INITIAL_SUPPLY);
    }

    modifier onlyManager() {
        require(manager == msg.sender, "UNAUTHORIZED: Only manager can call");
        _;
    }

    function setManager(address newManager) external onlyManager {
        require(newManager != address(0), "Invalid manager");
        manager = newManager;
    }

    function mint(address to,   uint256 amount) external onlyManager { _mint(to,   amount); }
    function burn(address from, uint256 amount) external onlyManager { _burn(from, amount); }
}

contract Manager {
    uint256 public constant MIN_COLLAT_RATIO = 1e18;

    // Assumed decimals
    uint8 public constant USDT_DECIMALS   = 6; // e.g., USDT
    uint8 public constant ORACLE_DECIMALS = 8; // e.g., Chainlink

    ERC20 public usdt;
    USDP  public usdp;

    Oracle public oracle;

    mapping(address => uint256) public address2deposit;
    mapping(address => uint256) public address2minted;

    constructor(address _usdt, address _usdp, address _oracle) {
        usdt   = ERC20(_usdt);
        usdp   = USDP(_usdp);
        oracle = Oracle(_oracle);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "amount=0");
        bool ok = usdt.transferFrom(msg.sender, address(this), amount);
        require(ok, "USDT transferFrom failed");
        address2deposit[msg.sender] += amount;
    }

    function burn(uint256 amount) external {
        address2minted[msg.sender] -= amount;
        usdp.burn(msg.sender, amount);
    }

    function mint(uint256 amount) external {
        address2minted[msg.sender] += amount;
        require(collatRatio(msg.sender) >= MIN_COLLAT_RATIO, "Insufficient collateral");
        usdp.mint(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        address2deposit[msg.sender] -= amount;
        require(collatRatio(msg.sender) >= MIN_COLLAT_RATIO, "Insufficient collateral after withdraw");
        bool ok = usdt.transfer(msg.sender, amount);
        require(ok, "USDT transfer failed");
    }

    function liquidate(address user) external {
        require(collatRatio(user) < MIN_COLLAT_RATIO, "Not liquidatable");
        // Liquidator repays user's debt with their own USDP, receives user's collateral
        uint256 debt = address2minted[user];
        require(debt > 0, "No debt");
        usdp.burn(msg.sender, debt);
        uint256 collateral = address2deposit[user];
        address2deposit[user] = 0;
        address2minted[user] = 0;
        bool ok = usdt.transfer(msg.sender, collateral);
        require(ok, "USDT transfer failed");
    }

    function collatRatio(address user) public view returns (uint256) {
        uint256 minted = address2minted[user];
        if (minted == 0) return type(uint256).max;

        uint256 price = oracle.latestAnswer();
        require(price > 0, "oracle=0");

        uint256 depositAmt = address2deposit[user];

        // Compute deposit value in 18 decimals: depositAmt[USDT_DECIMALS] * price[ORACLE_DECIMALS] * 10^(18 - USDT_DECIMALS - ORACLE_DECIMALS)
        uint256 scale = 10 ** (18 - (USDT_DECIMALS + ORACLE_DECIMALS));

        // overflow checks
        require(depositAmt == 0 || price <= type(uint256).max / depositAmt, "Overflow deposit*price");
        uint256 product = depositAmt * price;
        require(product == 0 || scale <= type(uint256).max / product, "Overflow scaling");
        uint256 depositUSD18 = product * scale;

        // ratio in 1e18 fixed-point: (depositUSD18 * 1e18) / minted
        require(depositUSD18 == 0 || 1e18 <= type(uint256).max / depositUSD18, "Overflow ratio scale");
        return (depositUSD18 * 1e18) / minted;
    }
}
