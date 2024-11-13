// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract AuctionCreator{
    Auction[] public auctions;

    function createAuction() public{
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

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

    constructor(address eoa){
        owner = payable(eoa);
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

    function finalizeAuction() public{
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled){ // auction cancelada
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }else{ // auction finalizada (nao cancelada)
            if(msg.sender == owner){
                recipient = owner;
                value = highestBindingBid;
            }else{
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else{
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        // zera os bids do solicitante
        bids[recipient] = 0;

        // envia o valor ao solicitante
        recipient.transfer(value);
    }
}