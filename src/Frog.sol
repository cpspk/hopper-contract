// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";
import {ERC2981} from "./ERC2981.sol";

contract FrogNFT is ERC721, ERC2981 {
    using SafeTransferLib for address;

    address public owner;
    uint256 public saleTime;

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 public immutable MAX_PER_ADDRESS;
    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable MINT_COST;

    /*///////////////////////////////////////////////////////////////
                                FROGS
    //////////////////////////////////////////////////////////////*/

    struct Frog {
        uint32 level;
        uint32 experience;
        uint8 strength;
        uint8 agility;
        uint8 vitality;
        uint8 intelligence;
        uint8 fertility;
    }

    mapping(uint256 => Frog) frogs;
    uint256 frogsLength;

    // whitelist for leveling up
    mapping(address => uint256) public caretakers;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MintLimit();
    error InsufficientAmount();
    error Unauthorized();
    error InvalidCaretaker();
    error InvalidTokenID();

    constructor(
        string memory _NFT_NAME,
        string memory _NFT_SYMBOL,
        uint256 _MINT_COST,
        uint256 _MAX_SUPPLY,
        uint256 _MAX_PER_ADDRESS,
        address _ROYALTY_ADDRESS,
        uint256 _ROYALTY_FEE,
        uint256 _SALE_TIME
    ) ERC721(_NFT_NAME, _NFT_SYMBOL) ERC2981(_ROYALTY_ADDRESS, _ROYALTY_FEE) {
        owner = msg.sender;

        MINT_COST = _MINT_COST;
        MAX_SUPPLY = _MAX_SUPPLY;
        _SALE_TIME = _SALE_TIME;

        //slither-disable-next-line missing-zero-check
        MAX_PER_ADDRESS = _MAX_PER_ADDRESS;
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        //slither-disable-next-line missing-zero-check
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    function withdraw() external onlyOwner {
        owner.safeTransferETH(address(this).balance);
    }

    /*///////////////////////////////////////////////////////////////
                        FROG LEVEL MECHANICS
            Caretakers are other authorized contracts that
                according to their own logic can issue a frog
                    to level up
    //////////////////////////////////////////////////////////////*/

    function addCaretaker(address caretaker) external onlyOwner {
        caretakers[caretaker] = 1;
    }

    function removeCaretaker(address caretaker) external onlyOwner {
        delete caretakers[caretaker];
    }

    function levelUp(
        uint256 tokenId,
        uint256 newAbility,
        uint256 newPower
    ) external {
        if (caretakers[msg.sender] == 0) revert InvalidCaretaker();

        // overflow is unrealistic
        unchecked {
            frogs[tokenId].level += 1;
        }
    }

    /*///////////////////////////////////////////////////////////////
                          FROG GENERATION
    //////////////////////////////////////////////////////////////*/

    function enoughRandom() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        // solhint-disable-next-line
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number)
                    )
                )
            );
    }

    //slither-disable-next-line weak-prng
    function generate(uint256 seed) internal pure returns (Frog memory) {
        return Frog({
            strength: uint8((seed >> (8*1)) % 10),
            agility: uint8((seed >> (8*2)) % 10),
            vitality: uint8((seed >> (8*3)) % 10),
            intelligence: uint8((seed >> (8*4)) % 10),
            fertility: uint8((seed >> (8*5)) % 10),
            level: 0,
            experience: 0
        });
    }

    function mint(uint256 numberOfMints) payable external {

        if(MINT_COST * numberOfMints > msg.value) revert InsufficientAmount();

        uint256 frogID = frogsLength;

        if (
            numberOfMints > MAX_PER_ADDRESS ||
            frogID + numberOfMints > MAX_SUPPLY
        ) revert MintLimit();

        // overflow is unrealistic
        unchecked {
           frogsLength += numberOfMints;

            uint256 seed = enoughRandom();
            for (uint256 i = 0; i < numberOfMints; i++) {
                _mint(msg.sender, frogID + i);
               frogs[frogID + i] = generate(seed >> i);
            }
        }

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return "TODO"; // todo
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}