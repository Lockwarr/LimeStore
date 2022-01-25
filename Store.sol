// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;
import "./Ownable.sol";

contract LimeStore is Ownable {
    uint public constant MAXBLOCKSBEFORERETURN = 100;
    uint _totalProducts;
    uint _totalClients;
    mapping(uint => Product) public allProducts;
    mapping(address => bool) public clientExisting;
    address[] public allClients;
    mapping(address => mapping(uint => BuyersProduct)) public buyerProducts;

    struct BuyersProduct {
        uint quantity;
        uint boughtAt;
        bool isBought;
    }
    
    struct Product {
        uint id;
        string name;
        uint quantity;
        bool available;
    }


    function getProductByName(string calldata name) public view returns(Product memory) {
        for (uint i=0; i < _totalProducts; i++) {
            if (keccak256(abi.encodePacked((allProducts[i].name))) == keccak256(abi.encodePacked((name)))) {
                return allProducts[i];
            }
        }
        return Product(0, "", 0, false);
    }

    function addProduct(string calldata name, uint quantity) public onlyOwner{
        Product memory existingProduct = getProductByName(name);
        if (existingProduct.available) {
            allProducts[existingProduct.id].quantity += quantity;
        } else if (quantity > 0) {
            allProducts[_totalProducts] = Product(_totalProducts, name, quantity, true);
            _totalProducts += 1;
        }
    }


    function listProducts() public view returns(Product[] memory) {
        Product[] memory products = new Product[](_totalProducts);

        for (uint i=0; i < _totalProducts; i++) {
            products[i] = allProducts[i];
        }
        return products;
    }

    function listClients() public view returns(address[] memory) {
        return allClients;
    }

    function buyProduct(uint id, uint quantity) public {
        require(allProducts[id].available, "Product is not available");
        require(allProducts[id].quantity >= quantity, "There aren't that many quantities available of this product");
        require(!buyerProducts[msg.sender][id].isBought, "You have already bought this product");
        buyerProducts[msg.sender][id] = BuyersProduct(quantity, block.number, true);
        allProducts[id].quantity -= quantity;
        if (!clientExisting[msg.sender]) {
            clientExisting[msg.sender] = true;
            allClients.push(msg.sender);
        }
    }

    function returnProduct(uint id) public {
        require((block.number - buyerProducts[msg.sender][id].boughtAt) < MAXBLOCKSBEFORERETURN, "You can no longer return this product");
        require(buyerProducts[msg.sender][id].isBought, "You haven't bought this product");
        allProducts[id].quantity += buyerProducts[msg.sender][id].quantity;
        buyerProducts[msg.sender][id] = BuyersProduct(0, 0, false);
    }
 

}