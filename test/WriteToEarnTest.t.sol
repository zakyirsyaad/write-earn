// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/WriteToEarn.sol";
import "../src/WriteAIToken.sol";

contract WriteToEarnTest is Test {
    WriteToEarn public writeToEarn;
    WriteAI public writeToken;
    address public owner;
    address public alice;
    address public bob;

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Deploy contracts
        writeToken = new WriteAI();
        writeToEarn = new WriteToEarn(address(writeToken));

        // Transfer ownership of WriteAI token to WriteToEarn contract
        writeToken.transferOwnership(address(writeToEarn));

        // Mint tokens to WriteToEarn contract for rewards
        writeToken.mint(address(writeToEarn), 1000000 * 10 ** 18); // 1M tokens for rewards

        // Mint tokens to test users
        writeToken.mint(alice, 100000 * 10 ** 18);
        writeToken.mint(bob, 100000 * 10 ** 18);
    }

    function test_PostStory() public {
        vm.startPrank(alice);

        string memory title = "Test Story";
        string memory content = "This is a test story content";
        string memory imageUrl = "https://example.com/image.jpg";

        writeToEarn.postStory(title, content, imageUrl);

        (
            address author,
            string memory returnedTitle,
            string memory returnedContent,
            string memory returnedImageUrl,
            uint256 readers
        ) = writeToEarn.getStory(1);

        assertEq(author, alice);
        assertEq(returnedTitle, title);
        assertEq(returnedContent, content);
        assertEq(returnedImageUrl, imageUrl);
        assertEq(readers, 0);

        vm.stopPrank();
    }

    function test_ReadStory() public {
        // First post a story
        vm.startPrank(alice);
        writeToEarn.postStory("Test", "Content", "image.jpg");
        vm.stopPrank();

        // Bob reads the story
        vm.startPrank(bob);
        writeToEarn.readStory(1);

        (, , , , uint256 readers) = writeToEarn.getStory(1);
        assertEq(readers, 1);
        vm.stopPrank();
    }

    function test_RewardDistribution() public {
        // Alice posts a story
        vm.startPrank(alice);
        writeToEarn.postStory("Test", "Content", "image.jpg");
        uint256 initialBalance = writeToken.balanceOf(alice);
        vm.stopPrank();

        // Generate 50 reads to trigger initial reward
        for (uint256 i = 1; i <= 50; i++) {
            address reader = makeAddr(string(abi.encodePacked("reader", i)));
            vm.prank(reader);
            writeToEarn.readStory(1);
        }

        uint256 finalBalance = writeToken.balanceOf(alice);
        assertEq(finalBalance, initialBalance + writeToEarn.INITIAL_REWARD());
    }

    function test_GetAllStories() public {
        // Post multiple stories
        vm.startPrank(alice);
        writeToEarn.postStory("Story 1", "Content 1", "image1.jpg");
        writeToEarn.postStory("Story 2", "Content 2", "image2.jpg");
        vm.stopPrank();

        WriteToEarn.Story[] memory allStories = writeToEarn.getAllStories();
        assertEq(allStories.length, 2);
        assertEq(allStories[0].title, "Story 1");
        assertEq(allStories[1].title, "Story 2");
    }

    function testFail_InsufficientTokensToPost() public {
        // Create a new address with no tokens
        address poor = makeAddr("poor");

        vm.prank(poor);
        writeToEarn.postStory("Test", "Content", "image.jpg"); // Should fail
    }

    function testFail_NonexistentStory() public {
        writeToEarn.readStory(999); // Should fail
    }

    function test_AdditionalRewards() public {
        // Alice posts a story
        vm.startPrank(alice);
        writeToEarn.postStory("Test", "Content", "image.jpg");
        uint256 initialBalance = writeToken.balanceOf(alice);
        vm.stopPrank();

        // Generate 60 reads to trigger initial reward and one additional reward
        for (uint256 i = 1; i <= 60; i++) {
            address reader = makeAddr(string(abi.encodePacked("reader", i)));
            vm.prank(reader);
            writeToEarn.readStory(1);
        }

        uint256 finalBalance = writeToken.balanceOf(alice);
        assertEq(
            finalBalance,
            initialBalance +
                writeToEarn.INITIAL_REWARD() +
                writeToEarn.ADDITIONAL_REWARD()
        );
    }
}
