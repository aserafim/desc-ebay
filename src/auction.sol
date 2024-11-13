// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract Auction{

    address payable public owner;
    
    // variaveis de bloco serao
    // usadas para calcular o tempo
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    // enum utilizado para identificar
    // o status da auction
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;
    uint bidIncrement;

    constructor(){
        owner = payable(msg.sender);
        auctionState = State.Running;
        
        // calculamos o tempo de validade
        // da auction a partir do nro do bloco
        // sabendo que a cada 15 sec um novo
        // bloco é criado
        // neste caso a duração é de 1 semana
        startBlock = block.number;
        endBlock = startBlock + 40320;

        ipfsHash = "";
        bidIncrement = 100;
    }

    modifier notOwner{
        require(msg.sender != owner);
        _;
    }   

    modifier afterStart{
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd{
        require(block.number <= endBlock);
        _;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b) {
            return b;
        }else{
            return a;
        }
    }

    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    }

    function placeBid() public payable notOwner afterStart beforeEnd{
        // exge que a auction esteja em funcionamento
        require(auctionState == State.Running);
        // o valor mínimo de lances é 100
        require(msg.value >= 100);

        // armazena o total que o jogador em questão
        // já lançou na auction
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

}