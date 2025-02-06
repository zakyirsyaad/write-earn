// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "src/WriteAIToken.sol";

contract WriteToEarn {
    // constructor() Ownable(msg.sender) {}
    struct Story {
        address author;
        string title;
        string content;
        string imageUrl;
        uint256 readers;
        uint256 timestamp;
        bool exists;
    }

    mapping(uint256 => Story) public stories;
    mapping(address => uint256) public balance;

    uint256 public storyCounter;
    uint256 public constant MIN_TOKENS_TO_POST = 50000 * 10 ** 18;
    uint256 public constant INITIAL_REWARD = 5000 * 10 ** 18;
    uint256 public constant ADDITIONAL_REWARD = 1000 * 10 ** 18;
    uint256 public constant FIRST_READER_THRESHOLD = 50;
    uint256 public constant ADDITIONAL_READER_STEP = 10;

    WriteAI public writeToken;

    event StoryPosted(
        uint256 storyId,
        address author,
        string title,
        string content,
        string imageUrl,
        uint256 timestamp
    );

    event StoryRead(uint256 storyId, address reader, uint256 timestamp);

    event RewardDistributed(address author, uint256 reward);

    constructor(address tokenAddress) {
        writeToken = WriteAI(tokenAddress);
        // Remove minting here since it's handled in test setup
    }

    modifier onlyAuthor(uint256 storyId) {
        require(stories[storyId].author == msg.sender, "Not the author");
        _;
    }

    function postStory(
        string memory title,
        string memory content,
        string memory imageUrl
    ) external {
        require(
            writeToken.balanceOf(msg.sender) >= MIN_TOKENS_TO_POST,
            "Insufficient tokens to post"
        );

        storyCounter++;
        stories[storyCounter] = Story(
            msg.sender,
            title,
            content,
            imageUrl,
            0,
            block.timestamp,
            true
        );

        emit StoryPosted(
            storyCounter,
            msg.sender,
            title,
            content,
            imageUrl,
            block.timestamp
        );
    }

    function readStory(uint256 storyId) external {
        require(stories[storyId].exists, "Story does not exist");
        stories[storyId].readers++;

        distributeRewards(storyId);

        emit StoryRead(storyId, msg.sender, block.timestamp);
    }

    function distributeRewards(uint256 storyId) internal {
        Story storage story = stories[storyId];
        uint256 reward = 0;

        if (story.readers == FIRST_READER_THRESHOLD) {
            reward = INITIAL_REWARD;
        } else if (
            story.readers > FIRST_READER_THRESHOLD &&
            (story.readers - FIRST_READER_THRESHOLD) % ADDITIONAL_READER_STEP ==
            0
        ) {
            reward = ADDITIONAL_REWARD;
        }

        if (reward > 0) {
            writeToken.transfer(story.author, reward);
            emit RewardDistributed(story.author, reward);
        }
    }

    function getStory(
        uint256 storyId
    )
        external
        view
        returns (address, string memory, string memory, string memory, uint256)
    {
        require(stories[storyId].exists, "Story does not exist");
        Story memory story = stories[storyId];
        return (
            story.author,
            story.title,
            story.content,
            story.imageUrl,
            story.readers
        );
    }

    function getAllStories() external view returns (Story[] memory) {
        Story[] memory allStories = new Story[](storyCounter);
        for (uint256 i = 1; i <= storyCounter; i++) {
            allStories[i - 1] = stories[i];
        }
        return allStories;
    }
}
