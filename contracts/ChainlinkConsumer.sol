// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

library StringUtils {
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}

contract APIConsumer is ChainlinkClient, ConfirmedOwner {
    using StringUtils for string;
    using Chainlink for Chainlink.Request;

    uint256 public winner;
    uint256 public winner2;
    uint256 public winner3;

    bytes32 private jobId;
    uint256 private fee;
    string private URL;
    string public league;
    event RequestWinner(bytes32 indexed requestId, uint256 winner, uint winner2, uint winner3);

    constructor(string memory _league) ConfirmedOwner(msg.sender) {
        string memory baseURL = "http://api.football-data.org/v4/competitions/";
        string memory endpoint = "/standings"; 
        league = _league;
        URL = baseURL.concat(league).concat(endpoint);
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0x20CAc2354359919C15950dEA3033a7712b6eCf8C);
        jobId = "3d2529ce26a74c9d9e593750d94950c9";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18
    }

    /**
     * Create a Chainlink request to retrieve API response, then find the target
     * data.
     */
    function requestWinner() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add(
            "get",
            URL
        );

        req.add(
            "league",
            league
        );

        req.add("path1", "standings,0,table,0,team,id");
        req.add("path2", "standings,0,table,1,team,id"); 
        req.add("path3", "standings,0,table,2,team,id");


        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    mapping (uint => address) NFTHolder;

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(
        bytes32 _requestId,
        uint256 _winner,
        uint _winner2,
        uint _winner3
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestWinner(_requestId, _winner, winner2, winner3);
        winner = _winner;
        winner2 = _winner2;
        winner3 = _winner3;
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
    function setWinner(uint id) public {
        winner = id;
    }
}

