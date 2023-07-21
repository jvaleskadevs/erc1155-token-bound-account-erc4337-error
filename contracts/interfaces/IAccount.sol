// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../UserOperation.sol";
// @dev the ERC-165 identifier for this interface is `TODO`
interface IAccount {
  function validateUserOp
      (UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
      external returns (uint256 validationData);
}
