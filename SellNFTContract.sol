// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <=0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyToken is ERC721, ERC721URIStorage {
    constructor() ERC721("ShriKrishnaNFT", "Krishn") {}

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) public {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract SellNFT is MyToken {
    MyToken private NFTAddress;
    uint private count;

    struct NFT {
        address NFTOwner;
        uint256 NFTprice;
        bool NFTOnSelling;
    }
    struct BidNft {
        address newBidder;
        address previousBidder;
        uint256 minimumTokenAmount;
        uint256 nftPrice;
        bool bidStart;
        bool bidEnd;
        bool tokenOnBid;
    }
    mapping(uint256 => NFT) public NFTDetails;
    mapping(uint256 => BidNft) public BidNftDetails;

    constructor(address tokenaddress) {
        require(
            tokenaddress != address(0),
            "Address != 0."
        );
        NFTAddress = MyToken(tokenaddress);
    }

    function MintNFT(string calldata uri) public {
        require(bytes(uri).length > 0, "Empty string");
        uint NFTId = count;
        NFTId++;
        NFTAddress.safeMint(msg.sender, NFTId, uri);

        NFT memory nft = NFTDetails[NFTId];
        nft.NFTOwner = msg.sender;
        NFTDetails[NFTId] = nft;
    }

    function _checkOwner(uint16 tokenId) internal view virtual {
        require(
            msg.sender == NFTAddress.ownerOf(tokenId),
            "Only Owner"
        );
    }

    modifier onlyOwner(uint16 tokenId) {
        _checkOwner(tokenId);
        _;
    }

    function setNFTOnBid(uint16 tokenId, uint256 minimumPrice)
        public
        onlyOwner(tokenId)
    {
        BidNft memory bidNft = BidNftDetails[tokenId];
        require(!bidNft.tokenOnBid, "Already set.");
        require(!NFTDetails[tokenId].NFTOnSelling, "Nft on selling");
        bidNft.minimumTokenAmount = minimumPrice;
        bidNft.tokenOnBid = true;
        BidNftDetails[tokenId] = bidNft;
    }

    function startBiding(uint16 tokenId) public onlyOwner(tokenId) {
        BidNft memory bidNft = BidNftDetails[tokenId];
        require(bidNft.tokenOnBid, "Set nft on biding.");
        require(!bidNft.bidStart, "Already start biding.");
        bidNft.bidStart = true;
        BidNftDetails[tokenId] = bidNft;
    }

    function _checkStartAndEnd(uint16 tokenId) internal view virtual {
        require(
            BidNftDetails[tokenId].bidStart,
            "Biding not start."
        );
        require(!BidNftDetails[tokenId].bidEnd, "Biding ended.");
    }

    modifier bidStartAndEnd(uint16 tokenId) {
        _checkStartAndEnd(tokenId);
        _;
    }

    function stopBiding(uint16 tokenId)
        public
        onlyOwner(tokenId)
        bidStartAndEnd(tokenId)
    {
        BidNft memory bidNft = BidNftDetails[tokenId];
        bidNft.bidEnd = true;
        BidNftDetails[tokenId] = bidNft;
    }

    function publicBidMoneyOnNFT(uint16 tokenId)
        public
        payable
        bidStartAndEnd(tokenId)
    {
        BidNft memory bidNft = BidNftDetails[tokenId];
        require(
            msg.sender != NFTAddress.ownerOf(tokenId),
            "Your are Owner."
        );
        require(
            msg.value > bidNft.minimumTokenAmount,
            "msg.value > minimumTokenAmount."
        );
        address previousBidder = bidNft.newBidder;
        uint256 oldAmount = bidNft.nftPrice;
        require(
            msg.value > bidNft.nftPrice,
            "msg.value > previous bidder amount."
        );
        bidNft.nftPrice = msg.value;
        bidNft.newBidder = msg.sender;
        bidNft.previousBidder = previousBidder;
        if (previousBidder != address(0)) {
            payable(previousBidder).transfer(oldAmount);
        }

        BidNftDetails[tokenId] = bidNft;
    }

    function TransferNFTToWinnerOfBid(uint16 tokenId)
        public
        payable
        onlyOwner(tokenId)
    {
        address tokenOwner = NFTAddress.ownerOf(tokenId);
        BidNft memory bidNft = BidNftDetails[tokenId];
        require(
            NFTAddress.getApproved(tokenId) == address(this),
            "Give Approval."
        );
        require(bidNft.bidEnd, "First stop biding.");
        payable(tokenOwner).transfer(bidNft.nftPrice);
        NFTAddress.transferFrom(tokenOwner, bidNft.newBidder, tokenId);
        NFT memory Nft = NFTDetails[tokenId];
        Nft.NFTOwner = bidNft.newBidder;
        NFTDetails[tokenId] = Nft;

        bidNft.newBidder = address(0);
        bidNft.previousBidder = address(0);
        bidNft.bidStart = false;
        bidNft.bidEnd = false;
        bidNft.nftPrice = 0;
        bidNft.minimumTokenAmount = 0;
        bidNft.tokenOnBid = false;

        BidNftDetails[tokenId] = bidNft;
    }

    function sellNFT(uint16 tokenId, uint256 price) public onlyOwner(tokenId) {
        NFT memory nft = NFTDetails[tokenId];
        require(price > 0, "Price > 0.");
        require(!nft.NFTOnSelling, "NFT selled.");
        require(!BidNftDetails[tokenId].tokenOnBid, "Nft on Biding");
        nft.NFTprice = price;
        nft.NFTOnSelling = true;
        NFTDetails[tokenId] = nft;
    }

    function buyNFT(uint16 tokenId) public payable {
        address tokenOwner = NFTAddress.ownerOf(tokenId);
        require(
            tokenOwner != msg.sender,
            "NFT alrady exist."
        );
        NFT memory nft = NFTDetails[tokenId];
        require(nft.NFTOnSelling, "Not set on selling.");

        require(msg.value == nft.NFTprice, "msg.value = nft.NFTprice");
        payable(tokenOwner).transfer(nft.NFTprice);
        NFTAddress.transferFrom(tokenOwner, msg.sender, tokenId);

        nft.NFTOwner = msg.sender;
        nft.NFTprice = nft.NFTprice;
        nft.NFTOnSelling = false;
        NFTDetails[tokenId] = nft;
    }

    function OwnerOf(uint16 tokenId)
        public
        view
        returns (address tokenOwnerAddress)
    {
        return NFTAddress.ownerOf(tokenId);
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
