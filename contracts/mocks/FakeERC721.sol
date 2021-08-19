// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FakeERC721 is ERC721("testToken", "tNFT") {

    function mint(uint _tokenId, address _beneficiary) public {
        _mint(_beneficiary, _tokenId);
    }
}