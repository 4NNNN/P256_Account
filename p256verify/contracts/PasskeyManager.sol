// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./Base64.sol";
//import "./P256.sol";


contract PasskeyManager {
    struct PassKeyId {
        uint256 pubKeyX;
        uint256 pubKeyY;
        string keyId;
    }    
    mapping(bytes32 => PassKeyId) public authorisedKeys;
    bytes32[] private knownKeyHashes;

    event PublicKeyAdded(bytes32 indexed keyHash, uint256 pubKeyX, uint256 pubKeyY, string keyId);
    event PublicKeyRemoved(bytes32 indexed keyHash, uint256 pubKeyX, uint256 pubKeyY, string keyId);


    /**
     * Allows the owner to add a passkey key.
     * @param _keyId the id of the key
     * @param _pubKeyX public key X val from a passkey that will have a full ownership and control of this account.
     * @param _pubKeyY public key X val from a passkey that will have a full ownership and control of this account.
     */
    function addPassKey(string calldata _keyId, uint256 _pubKeyX, uint256 _pubKeyY) public  {
        _addPassKey(keccak256(abi.encodePacked(_keyId)), _pubKeyX, _pubKeyY, _keyId);
    }

    function _addPassKey(bytes32 _keyHash, uint256 _pubKeyX, uint256 _pubKeyY, string calldata _keyId) internal {
        emit PublicKeyAdded(_keyHash, _pubKeyX, _pubKeyY, _keyId);
        authorisedKeys[_keyHash] = PassKeyId(_pubKeyX, _pubKeyY, _keyId);
        knownKeyHashes.push(_keyHash);
    }

    
    function getAuthorisedKeys() public view returns (PassKeyId[] memory knownKeys){
        knownKeys = new PassKeyId[](knownKeyHashes.length);
        for (uint256 i = 0; i < knownKeyHashes.length; i++) {
            knownKeys[i] = authorisedKeys[knownKeyHashes[i]];
        }
        return knownKeys;
    }

    function removePassKey(string calldata _keyId) public {
        require(knownKeyHashes.length > 1, "Cannot remove the last key");
        bytes32 keyHash = keccak256(abi.encodePacked(_keyId));
        PassKeyId memory passKey = authorisedKeys[keyHash];
        if (passKey.pubKeyX == 0 && passKey.pubKeyY == 0) {
            return;
        }
        delete authorisedKeys[keyHash];
        for (uint256 i = 0; i < knownKeyHashes.length; i++) {
            if (knownKeyHashes[i] == keyHash) {
                knownKeyHashes[i] = knownKeyHashes[knownKeyHashes.length - 1];
                knownKeyHashes.pop();
                break;
            }
        }
        emit PublicKeyRemoved(keyHash, passKey.pubKeyX, passKey.pubKeyY, passKey.keyId);
    }
}
