// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { APIConsumer, ConfirmedOwner } from  "./ChainlinkConsumer.sol";


/// @custom:security-contact marcelofrayha@gmail.com
contract FootStocks is ERC1155, ERC1155Supply, ConfirmedOwner, APIConsumer {

    address private _owner;
    bool public isActive;
    // These variables can be used to implement a reset state function
    // uint[] public idsList;
    // address[] public listOfOwners;
    // mapping (address => bool) public ownerOnList;
    // mapping (address => uint[]) public ownerWallet;
    mapping (uint => uint) public mintPrice;
    mapping (uint => mapping(address => uint)) public transferPrice;
    mapping (uint => address[]) public tokenOwners; 

    constructor(string memory _league) APIConsumer(_league) payable
        ERC1155("https://ipfs.io/ipfs/QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn")
    {
        _owner = msg.sender;
        isActive = true;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }
    // Updates the list of all the owners a NFT has
    function updateOwnersList (uint id, address account) private {
        bool inTheList = false;
        for (uint i = 0; i < tokenOwners[id].length; i++) {
            if (tokenOwners[id][i] == account) inTheList = true;
            if (balanceOf(tokenOwners[id][i], id) == 0) {
                tokenOwners[id][i] = tokenOwners[id][tokenOwners[id].length - 1];
                tokenOwners[id].pop();
            }
        }
        if (!inTheList) tokenOwners[id].push(account); 
    }

    // Updates the list of all NFTs owned by an account - Only required to reset the contract
    // function updateWallet (address account, uint id) private {
    //     bool inTheList = false;
    //     for (uint i = 0; i < ownerWallet[account].length; i++) {
    //         if (ownerWallet[account][i] == id) inTheList = true;
    //         if (balanceOf(account, id) == 0) {
    //             ownerWallet[account][i] = ownerWallet[account][ownerWallet[account].length - 1];
    //             ownerWallet[account].pop();
    //             inTheList = false;
    //         }
    //     }
    //     if (!inTheList) ownerWallet[account].push(id); 
    // }

    // Updates the list of all minted NFTs - Only required to reset the contract
    // function updateIdsList (uint id) private {
    //     bool inTheList = false;
    //     for (uint i = 0; i < idsList.length; i++) {
    //         if (idsList[i] == id) inTheList = true;
    //     }
    //     if (!inTheList) idsList.push(id); 
    // }

    //Returns all the owners of a NFT
    function getOwnersList (uint id) public view returns (address[] memory) {
        return tokenOwners[id];
    }

    // function getOwnerWallet (address account) public view returns (uint[] memory) {
    //     return ownerWallet[account];
    // }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) payable external {
        require(isActive, "Not active");
        require(amount + totalSupply(id) <= 100000, "The NFT reached its cap");
        require(amount <= 20, "You can only mint 20 in the same transaction");
        if (totalSupply(id) == 0) mintPrice[id] = 100;
        require (msg.value >= mintPrice[id]*amount, "Send more money");
        _mint(account, id, amount, data);
        if (!isApprovedForAll(msg.sender, address(this))) setApprovalForAll(address(this), true);
        mintPrice[id] += amount*100;
        updateOwnersList(id, account);
        // updateIdsList(id);
        // updateWallet(account, id);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        payable
        external
    {
        require(isActive, "Not active");
        for (uint i = 0; i < ids.length; i++) {
            require(amounts[i] + totalSupply(ids[i]) <= 100000, "The NFT reached its cap");
            require(amounts[i] <= 20, "You can only mint 20 in the same transaction");
            if (totalSupply(ids[i]) == 0) mintPrice[ids[i]] = 100;
           require (msg.value >= mintPrice[ids[i]]*amounts[i], "Send more money");
            mintPrice[ids[i]] += amounts[i]*100;
            updateOwnersList(ids[i], to);
            // updateIdsList(ids[i]);
            // updateWallet(to, ids[i]);

        }
        _mintBatch(to, ids, amounts, data);
        if (!isApprovedForAll(msg.sender, address(this))) setApprovalForAll(address(this), true);
    }
    
    function setTokenPrice(uint id, uint price ) external {
        require (balanceOf(msg.sender, id) > 0, "You don't have this NFT");
        transferPrice[id][msg.sender] = price;
    }

    function buyToken(uint id, uint amount, address nftOwner) payable public {
        require(isActive, "Not active");
        require(msg.value == transferPrice[id][nftOwner], "The value sent must match the price");
        require(amount <= balanceOf(nftOwner, id), "You can't buy that much");
        require(winner == 0, "We already have a winner, the market is closed");
        payable(nftOwner).transfer(transferPrice[id][nftOwner]*999/1000);
        payable(_owner).transfer(transferPrice[id][nftOwner]*5/10000);
        (bool success, ) = address(this).call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", nftOwner, msg.sender, id, amount, ""));
        require(success, "Function call failed");
    }

    function payWinner() payable external {
        require(isActive, "Not active");
        require (winner != 0, "There is no winner");
        require (exists(winner), "No one minted the winner's NFT");
        uint supply = totalSupply(winner);
        uint value = address(this).balance;
        for (uint i = 0; i < getOwnersList(winner).length; i++) {
            address nftOwner = tokenOwners[winner][i];
            uint balance = balanceOf(nftOwner, winner);
            payable(nftOwner).transfer(value * balance / supply);
        }
        isActive = false;
    }

    // function updateListOfOwners () public {
    //     for (uint i = 0; i < idsList.length; i++) {
    //         mintPrice[idsList[i]] = 0;
    //         for (uint j = 0; j < tokenOwners[idsList[i]].length; j++) {
    //             address ownerAddress = tokenOwners[idsList[i]][j];
    //             if(ownerOnList[ownerAddress] != true) {
    //                 listOfOwners.push(ownerAddress);
    //                 ownerOnList[ownerAddress] = true;
    //             }
    //         }
    //         // delete tokenOwners[idsList[i]];
    //     }    
    // }

    // function resetState() public {
    //     winner = 0;
    //         for (uint j = 0; j < listOfOwners.length; j++) {
    //             uint walletSize = getOwnerWallet(listOfOwners[j]).length;
    //             address[] memory batchParam = new address[](walletSize);
    //             uint[] memory ammounts = new uint[](walletSize);
    //             for (uint z = 0; z < walletSize; z++) {
    //                 batchParam[z] = listOfOwners[j];
    //             }
    //             ammounts = balanceOfBatch(batchParam, getOwnerWallet(listOfOwners[j]));
    //             (bool success, ) = address(this)
    //             .call(abi.encodeWithSignature("burnBatch(address,uint[],uint[])", listOfOwners[j], getOwnerWallet(listOfOwners[j]), ammounts, ""));
    //             require(success, "Function call failed");
    //             delete ownerWallet[listOfOwners[j]];
    //             delete ownerOnList[listOfOwners[j]];
    //         }
        
    //     delete listOfOwners;
    //     delete idsList;
    // }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._safeTransferFrom(
             from,
             to,
             id,
             amount,
             data
          );
        updateOwnersList(id, to);
        // updateWallet(to, id);
        // updateWallet(from, id);
    }
    // The following function is override required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
:x!
:qa!
:a!
:x!

