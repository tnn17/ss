// SPDX-License-Identifier: MIT 
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftToNftExchange is Ownable {
    uint private minDuration;
    mapping (address => mapping(bytes32 => uint)) internal nftOwnerToTradeIdToNftId;
    mapping (bytes32 => Trade) internal idToTrade;
    mapping (address => mapping(bytes32 => uint)) internal addressToTradeIdToWei;

    constructor(uint _minDuration) public Ownable() {
        minDuration = _minDuration;
    }

    struct Trade {
        address bidder;
        address asker;
        IERC721 bidderNFTAddress;
        IERC721 askerNFTAddress;
        uint askerNFTId;
        uint bidderNFTId;
        uint expirestAt;
        uint price;
        bool bidderReceiveNft;
        bool askerReceiveNft;
        bool askerReceiveWei;
    }

    modifier nftNotEqual(
        uint _bidderNFTId,
        IERC721 _bidderNFTAddress,
        IERC721 _askerNFTAddress,
        uint _askerNFTId
    ) {
        require((_bidderNFTId != _askerNFTId) && 
        (_bidderNFTAddress != _askerNFTAddress), "NFT can not be equal!");
        _;
    }

    modifier expirationTimeIsLongerThatMinDuration(
        uint _duration
    ) {
        require(_duration >= minDuration, 
        "The duration value cannot be less than the minimum duration value!");
        _;
    }

    modifier senderIsAskerOrBidder(
        address _addr,
        bytes32 _tradeId
    ) {
        require((_addr == idToTrade[_tradeId].bidder) || 
        (_addr == idToTrade[_tradeId].asker),
        "msg.sender must bu asker or bidder!");
        _;
    }

    modifier nftIdIsInTrade(
        bytes32 _tradeId,
        uint _nftId
    ) {
        require((_nftId == idToTrade[_tradeId].bidderNFTId) && (_nftId == idToTrade[_tradeId].askerNFTId));
        _;
    }

    modifier isTradeExist(
        bytes32 _tradeId
    ) {
        require(idToTrade[_tradeId].expirestAt != 0);
        _;
    }

    modifier isTradePayed(
        bytes32 _tradeId
    ) {
        Trade memory trade = idToTrade[_tradeId];
        require(addressToTradeIdToWei[trade.bidder][_tradeId] == trade.price);
        require(nftOwnerToTradeIdToNftId[trade.bidder][_tradeId] == trade.bidderNFTId);
        require(nftOwnerToTradeIdToNftId[trade.asker][_tradeId] == trade.askerNFTId);
        _;
    }

    modifier isSenderBidder(
        bytes32 _tradeId
    ) {
        require(idToTrade[_tradeId].bidder == msg.sender);
        _;
    }

    modifier isSenderAsker(
        bytes32 _tradeId
    ) {
        require(idToTrade[_tradeId].asker == msg.sender);
        _;
    }

    modifier isTradeAvailable(
        bytes32 _tradeId
    ) {
        require(idToTrade[_tradeId].expirestAt > block.timestamp);
        _;
    }

    event BidCreated(
        bytes32 indexed TradeId,
        address bidderAddress,
        IERC721 bidderNFTAddress,
        IERC721 askerNFTAddress,
        uint indexed bidderNFTId,
        uint indexed askerNFTId,
        uint price,
        uint expirestAt
    );

    event AskCreated(
        bytes32 indexed TradeId,
        address askerAddress,
        IERC721 bidderNFTAddress,
        IERC721 askerNFTAddress,
        uint indexed bidderNFTId,
        uint indexed askerNFTId,
        uint price,
        uint expirestAt
    );

    event NftStaked(
        bytes32 indexed tradeId,
        IERC721 indexed nftAddress,
        uint indexed nftId
    );

    event AmountPayed(
        bytes32 indexed tradeId,
        address indexed bidder,
        uint indexed amount
    );

    event NftWithdrawed(
        bytes32 indexed tradeId,
        address indexed to,
        uint indexed nftId
    );

    event WeiWithdrawed(
        bytes32 indexed tradeId,
        address indexed to,
        uint indexed amount
    );

    function createBid(
        uint _bidderNFTId,
        IERC721 _bidderNFTAddress, 
        IERC721 _askerNFTAddress,
        uint _askerNFTId, 
        uint _duration
    ) 
        external 
        payable
        nftNotEqual(
            _bidderNFTId,
            _bidderNFTAddress,
            _askerNFTAddress,
            _askerNFTId
        )
        expirationTimeIsLongerThatMinDuration(
            _duration
            )
        returns(bytes32) 
    {
        require(msg.sender == _bidderNFTAddress.ownerOf(_bidderNFTId));
        bytes32 tradeId = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                _bidderNFTId,
                _bidderNFTAddress,
                _askerNFTAddress,
                _askerNFTId,
                _duration
            )
            );

        uint expirestAt = block.timestamp + _duration;

        idToTrade[tradeId] = Trade({
            bidder: msg.sender,
            asker: address(0),
            bidderNFTAddress: _bidderNFTAddress,
            askerNFTAddress: _askerNFTAddress,
            askerNFTId: _askerNFTId,
            bidderNFTId:_bidderNFTId,
            expirestAt: expirestAt,
            price: msg.value,
            bidderReceiveNft: false,
            askerReceiveNft: false,
            askerReceiveWei: false
        });

        emit BidCreated(
            tradeId,
            msg.sender,
            _bidderNFTAddress,
            _askerNFTAddress,
            _bidderNFTId,
            _askerNFTId,
            msg.value,
            expirestAt
        );
        return tradeId;
    }

    function createAsk(
        uint _askerNFTId,
        uint _bidderNFTId,
        IERC721 _bidderNFTAddress,
        IERC721 _askerNFTAddress,
        uint _duration,
        uint _price
    )
    external
    nftNotEqual(
            _bidderNFTId,
            _bidderNFTAddress,
            _askerNFTAddress,
            _askerNFTId
        )
    expirationTimeIsLongerThatMinDuration(
        _duration
        )
    returns(bytes32) {
        require(msg.sender == _askerNFTAddress.ownerOf(_askerNFTId));
        
        bytes32 tradeId = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                _bidderNFTId,
                _bidderNFTAddress,
                _askerNFTAddress,
                _askerNFTId,
                _duration
            )
            );

        uint expirestAt = block.timestamp + _duration;

        idToTrade[tradeId] = Trade({
            bidder: address(0),
            asker: msg.sender,
            bidderNFTAddress: _bidderNFTAddress,
            askerNFTAddress: _askerNFTAddress,
            askerNFTId: _askerNFTId,
            bidderNFTId:_bidderNFTId,
            expirestAt: expirestAt,
            price: _price,
            bidderReceiveNft: false,
            askerReceiveNft: false,
            askerReceiveWei: false
        });

        emit AskCreated(
            tradeId,
            msg.sender,
            _bidderNFTAddress,
            _askerNFTAddress,
            _bidderNFTId,
            _askerNFTId,
            _price,
            expirestAt
        );
        return tradeId;
    }

    function stakeNft(
        bytes32 _tradeId,
        uint _nftId
    )
    isTradeExist(
        _tradeId
    )
    isTradeAvailable(
        _tradeId
    )
    nftIdIsInTrade(
        _tradeId,
        _nftId
    )
    senderIsAskerOrBidder(
        msg.sender,
        _tradeId
    )
    external {
        Trade memory trade = idToTrade[_tradeId];
        
        if (_nftId == trade.bidderNFTId) {
            if (trade.bidder == address(0)) {
                trade.bidder = msg.sender;
            }
            trade.bidderNFTAddress.safeTransferFrom(
                trade.bidder, address(this), _nftId);
            nftOwnerToTradeIdToNftId[trade.bidder][_tradeId] = _nftId;
            emit NftStaked(
                _tradeId,
                trade.bidderNFTAddress,
                _nftId
            );
        } else {
            if (trade.asker == address(0)) {
                trade.asker = msg.sender;
            }
            trade.askerNFTAddress.safeTransferFrom(
                trade.asker, address(this), _nftId);
            nftOwnerToTradeIdToNftId[trade.asker][_tradeId] = _nftId;
            emit NftStaked(
                _tradeId,
                trade.askerNFTAddress,
                _nftId
            );
        }
    }

    function pay(
        bytes32 _tradeId
    ) 
    external
    payable
    isTradeAvailable(
        _tradeId
    )
    isSenderBidder(
        _tradeId
    )
    isTradeExist(
        _tradeId
    )
    {
        require(msg.value == idToTrade[_tradeId].price);
        addressToTradeIdToWei[msg.sender][_tradeId] += msg.value;
        emit AmountPayed(
            _tradeId,
            msg.sender,
            msg.value
        );
    }
    
    function withdrawNft(
        bytes32 _tradeId
    )
    external
    isTradeAvailable(
        _tradeId
    )
    senderIsAskerOrBidder(
        msg.sender,
        _tradeId
    )
    isTradePayed(
        _tradeId
    )
    {
        Trade memory trade = idToTrade[_tradeId];
        if (msg.sender == trade.bidder) {
            trade.askerNFTAddress.safeTransferFrom(
                address(this), msg.sender, trade.askerNFTId);
            nftOwnerToTradeIdToNftId[trade.asker][_tradeId] = 0;
            trade.bidderReceiveNft = true;
            emit NftWithdrawed(_tradeId, msg.sender, trade.askerNFTId);
        } else {
            trade.bidderNFTAddress.safeTransferFrom(
                address(this), msg.sender, trade.bidderNFTId);
            nftOwnerToTradeIdToNftId[trade.bidder][_tradeId] = 0;
            trade.askerReceiveNft = true;
            emit NftWithdrawed(_tradeId, msg.sender, trade.bidderNFTId);
        }
    }

    function withdrawWei(
        bytes32 _tradeId
    )
    external
    isTradeAvailable(
        _tradeId
    )
    senderIsAskerOrBidder(
        msg.sender,
        _tradeId
    )
    isTradePayed(
        _tradeId
    ) 
    isSenderAsker(
        _tradeId
    )
    {
        Trade memory trade = idToTrade[_tradeId];
        payable(msg.sender).transfer(trade.price);
        addressToTradeIdToWei[trade.bidder][_tradeId] = 0;
        trade.askerReceiveWei = true;
        emit WeiWithdrawed(_tradeId, msg.sender, trade.price);
    }

    function unstakeNft(
        bytes32 _tradeId
    )
    external
    senderIsAskerOrBidder(
        msg.sender,
        _tradeId
    ) {
        Trade memory trade = idToTrade[_tradeId];
        if (
            trade.bidderReceiveNft == false &&
            trade.askerReceiveNft == false &&
            trade.askerReceiveWei == false 
        ) {
            if (trade.bidder == msg.sender &&
             nftOwnerToTradeIdToNftId[msg.sender][_tradeId] == trade.bidderNFTId) {
                trade.bidderNFTAddress.safeTransferFrom(
                    address(this), msg.sender, trade.bidderNFTId);
                nftOwnerToTradeIdToNftId[msg.sender][_tradeId] = 0;
            } else if (nftOwnerToTradeIdToNftId[msg.sender][_tradeId] == trade.askerNFTId) {
                trade.askerNFTAddress.safeTransferFrom(
                    address(this), msg.sender, trade.askerNFTId);
                nftOwnerToTradeIdToNftId[msg.sender][_tradeId] = 0;
            }
        }
    }

    function unstakeWei(
        bytes32 _tradeId
    )
    external
    senderIsAskerOrBidder(
        msg.sender,
        _tradeId
    )
    isSenderAsker(
        _tradeId
    ) {
        Trade memory trade = idToTrade[_tradeId];
        if (
            trade.bidderReceiveNft == false &&
            trade.askerReceiveWei == false &&
            trade.askerReceiveWei == false
        ) {
            if (addressToTradeIdToWei[trade.asker][_tradeId] == trade.price) {
                payable(trade.asker).transfer(trade.price);
                addressToTradeIdToWei[trade.asker][_tradeId] = 0;
            }
        }
    }
   
    function getTradeById(
        bytes32 _tradeId
    )
    external 
    view
    isTradeExist(
        _tradeId
    )
    returns (bytes32, IERC721, IERC721, uint256, uint256, uint256, bool, bool, bool) {
        Trade memory trade = idToTrade[_tradeId];

        return (
            _tradeId,
            trade.bidderNFTAddress,
            trade.askerNFTAddress,
            trade.bidderNFTId,
            trade.askerNFTId,
            trade.price,
            trade.bidderReceiveNft,
            trade.askerReceiveWei,
            trade.askerReceiveNft
        );
    }
}
