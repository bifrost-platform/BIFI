// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title BiFi's oracle interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface oracleInterface {
    function latestAnswer() external view returns (int256);
}

interface bscChainlinkOracleInterface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
      external
      view
      returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
      );
    function latestRoundData()
      external
      view
      returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
      );
}
