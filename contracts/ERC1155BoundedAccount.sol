// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IERC1155BoundedAccount.sol";
import "./callback/TokenCallbackHandler.sol";
import "./interfaces/IAccount.sol";
import "./interfaces/IEntryPoint.sol";
import "./helpers/Helpers.sol";


contract ERC1155BoundedAccount is TokenCallbackHandler, IERC1271, IAccount, IERC1155BoundedAccount {
    using UserOperationLib for UserOperation;
    using ECDSA for bytes32;
    
    IEntryPoint private immutable _entryPoint;
    
    constructor() {
        // Hardcoding entrypoint here to be ERC6551Registry compliant
        _entryPoint = IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
    }

    //return value in case of signature failure, with no time-range.
    // equivalent to _packValidationData(true,0,0);
    uint256 constant internal SIG_VALIDATION_FAILED = 1;
    
    receive() external payable {}

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result) {
        _isValidSignerOrEntryPoint(msg.sender);
        result = _call(to, value, data);
    }
    
    function executeCallBatch(
        address[] calldata to,
        bytes[] calldata data
    ) external {
        _isValidSignerOrEntryPoint(msg.sender);
        require(to.length == data.length, "wrong array lengths");
        
        for (uint256 i = 0; i < to.length; i++) {
            _call(to[i], 0, data[i]);
        }       
    }
    
    function _call(address target, uint256 value, bytes memory data) internal returns (bytes memory result) {
        bool success;
        (success, result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function token()
        external
        view
        returns (
            uint256,
            address,
            uint256
        )
    {
        bytes memory footer = new bytes(0x60);

        assembly {
            // copy 0x60 bytes from end of footer
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }
    
    function _isEntryPoint(address sender) internal view returns (bool) {
        return sender == address(entryPoint());
    }
    
    function _isValidSignerOrEntryPoint(address sender) internal view {
        require(
          _isEntryPoint(sender) || isValidSigner(sender),
          "Forbidden"
        );
    }

    function isValidSigner(address signer) public view returns (bool) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this
            .token();
        if (chainId != block.chainid) return false;

        return IERC1155(tokenContract).balanceOf(signer, tokenId) > 0;
    }
/*    
    function recoverSigner(
        bytes32 _hash,
        bytes memory _signature
    ) internal pure returns (address signer) {
        require(_signature.length == 65, "SignatureValidator#recoverSigner: invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly { 
            r := mload(add(_signature, 32))//bytes32(_signature[0:32]);
            s := mload(add(_signature, 64))//bytes32(_signature[32:64]);
            v := byte(0, mload(add(_signature, 96)))//uint8(_signature[64]);
        }
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        //
        // Source OpenZeppelin
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
          revert("SignatureValidator#recoverSigner: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
          revert("SignatureValidator#recoverSigner: invalid signature 'v' value");
        }

        // Recover ECDSA signer
        signer = ecrecover(_hash, v, r, s);
        
        // Prevent signer from being 0x0
        require(
          signer != address(0x0),
          "SignatureValidator#recoverSigner: INVALID_SIGNER"
        );

        return signer;        
    }
*/
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return (super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC1271).interfaceId ||
            interfaceId == type(IERC1155BoundedAccount).interfaceId ||
            interfaceId == type(IAccount).interfaceId);
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        public
        view
        returns (bytes4 magicValue)
    {
        //bool isValid = isValidSigner(recoverSigner(hash, signature));
        bool isValid = isValidSigner(hash.toEthSignedMessageHash().recover(signature));
        
        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }
    
    function _validateSignature(
        UserOperation calldata userOp, 
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        if (isValidSignature(userOpHash, userOp.signature) == IERC1271.isValidSignature.selector)
            return 0;
        return SIG_VALIDATION_FAILED;
        /*
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (isValidSigner(hash.recover(userOp.signature)))
        */
    }
    
    /**
     * Validate user's signature and nonce.
     * subclass doesn't need to override this method. 
     * Instead, it should override the specific internal validation methods.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override virtual returns (uint256 validationData) {
        //_isValidSignerOrEntryPoint(msg.sender);
        require(_isEntryPoint(msg.sender), "Forbidden");
        validationData = _validateSignature(userOp, userOpHash);
        // TODO: validateNonce ?!
        _payPrefund(missingAccountFunds);
    }
    
    function entryPoint() public view returns (IEntryPoint) {
        return _entryPoint;
    }
    
    /**
     * Return the account nonce.
     * This method returns the next sequential nonce.
     * For a nonce of a specific key, use `entrypoint.getNonce(account, key)`
     */
    function nonce() external view virtual returns (uint256) {
        return entryPoint().getNonce(address(this), 0);
    }    

    /**
     * sends to the entrypoint (msg.sender) the missing funds for this transaction.
     * subclass MAY override this method for better funds management
     * (e.g. send to the entryPoint more than the minimum required, so that in future transactions
     * it will not be required to send again)
     * @param missingAccountFunds the minimum value this method should send the entrypoint.
     *  this value MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
     */
    function _payPrefund(uint256 missingAccountFunds) internal virtual {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value : missingAccountFunds, gas : type(uint256).max}("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }
    
    
    // Helpers to manage the entryPoint funds
    
    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value : msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public {
        _isValidSignerOrEntryPoint(msg.sender);
        entryPoint().withdrawTo(withdrawAddress, amount);
    }
}
