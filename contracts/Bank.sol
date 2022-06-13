// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";

contract elBanco {
    Token private token;

    mapping(address => uint256) public depositStart;
    mapping(address => uint256) public etherBalanceOf;
    mapping(address => uint256) public collateralEther;

    mapping(address => bool) public isDeposited;
    mapping(address => bool) public isBorrowed;

    event Deposit(address indexed user, uint256 etherAmount, uint256 timeStart);
    event Withdraw(
        address indexed user,
        uint256 etherAmount,
        uint256 depositTime,
        uint256 interest
    );
    event Borrow(
        address indexed user,
        uint256 collateralEtherAmount,
        uint256 borrowedTokenAmount
    );
    event PayOff(address indexed user, uint256 fee);

    constructor(Token _token) {
        token = _token;
    }

    /**
    @notice function to deposit ether
    @dev the function is payable so send "value"
  */
    function deposit() external payable {
        require(
            isDeposited[msg.sender] == false,
            "cannot deposit more than once"
        );
        require(
            msg.value >= 1e16,
            "insufficient amount, min. deposit: 0.01 ETH"
        );

        etherBalanceOf[msg.sender] = etherBalanceOf[msg.sender] + msg.value;
        depositStart[msg.sender] = depositStart[msg.sender] + block.timestamp;

        isDeposited[msg.sender] = true; //activate deposit status
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    /**
    @notice function to withdraw deposited amount
   */
    function withdraw() external {
        require(isDeposited[msg.sender] == true, "Error, no previous deposit");
        uint256 userBalance = etherBalanceOf[msg.sender]; //for event

        //check user's hodl time
        uint256 depositTime = block.timestamp - depositStart[msg.sender];

        // 31668017 - interest(10% APY) per second for min. deposit amount (0.01 ETH)
        // cuz: 1e15(10% of 0.01 ETH) / 31577600 (seconds in 365.25 days)

        // (etherBalanceOf[msg.sender] / 1e16)
        //    - calc. how much higher interest will be (based on deposit)
        //    e.g.: for min. deposit (0.01 ETH),
        //          (etherBalanceOf[msg.sender] / 1e16) = 1 (the same, 31668017/s)
        //          for deposit 0.02 ETH,
        //          (etherBalanceOf[msg.sender] / 1e16) = 2 (doubled, (2*31668017)/s)

        uint256 interestPerSecond = 31668017 * (userBalance / 1e16);
        uint256 interest = interestPerSecond * depositTime;

        //send funds to user
        payable(msg.sender).transfer(userBalance); //eth back to user
        token.mint(msg.sender, interest); //interest to user

        //reset depositer data
        depositStart[msg.sender] = 0;
        etherBalanceOf[msg.sender] = 0;
        isDeposited[msg.sender] = false;

        emit Withdraw(msg.sender, userBalance, depositTime, interest);
    }

    function getAccruedInterest(address _addr)
        public
        view
        returns (uint256 interest)
    {
        uint256 depositTime = block.timestamp - depositStart[_addr];
        uint256 interestPerSecond = 31668017 * (etherBalanceOf[_addr] / 1e16);
        interest = interestPerSecond * depositTime;
    }

    /**
    @notice function to take loan
    @dev function is payable so send "value"
  */
    function borrow() external payable {
        require(msg.value >= 1e16, "Error, collateral must be >= 0.01 ETH");
        require(isBorrowed[msg.sender] == false, "Error, loan already taken");

        //this Ether will be locked till user payOff the loan
        collateralEther[msg.sender] = collateralEther[msg.sender] + msg.value;

        //calc tokens amount to mint, 50% of msg.value
        uint256 tokensToMint = collateralEther[msg.sender] / 2;

        //mint&send tokens to user
        token.mint(msg.sender, tokensToMint);

        //activate borrower's loan status
        isBorrowed[msg.sender] = true;

        emit Borrow(msg.sender, collateralEther[msg.sender], tokensToMint);
    }

    /**
    @notice function to repay loan
    @dev approve users token first before calling this function
  */
    function repay() external {
        require(isBorrowed[msg.sender] == true, "Error, loan not active");
        require(
            token.transferFrom(
                msg.sender,
                address(this),
                collateralEther[msg.sender] / 2
            ),
            "Error, can't receive tokens"
        ); //must approve dBank 1st

        uint256 fee = collateralEther[msg.sender] / 10; //calc 10% fee

        //send user's collateral minus fee
        payable(msg.sender).transfer(collateralEther[msg.sender] - fee);

        //reset borrower's data
        collateralEther[msg.sender] = 0;
        isBorrowed[msg.sender] = false;

        emit PayOff(msg.sender, fee);
    }
}

// https://testnet.bscscan.com/address/0x04B11f06FD1eC733651F86262458cbBA0B73C26b#code
