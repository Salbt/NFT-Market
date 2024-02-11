// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";


contract NFTMarket is IERC721Receiver{

    IERC20 public erc20;
    IERC721 public erc721;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    struct Order{
        address seller;
        uint256 price;
        uint256 tokenId;
    }

    // NFTtoken对应的订单
    mapping(uint256 => Order) public orderByTokenId;
    // market订单列表
    Order[] public orders;
    // TokenId对应的订单所应的索引
    mapping(uint256 => uint256) public tokenIdByOrderIndex;

    constructor(address _erc20, address _erc721){
        require(_erc20 != address(0), "Invalid ERC20 address");
        require(_erc721 != address(0), "Invalid ERC721 address");
        erc20 = IERC20(_erc20);
        erc721 = IERC721(_erc721);
    }

    // 成交
    event Deal(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);
    // 商品上架
    event NewOrder(address indexed seller, uint256 indexed tokenId, uint256 price);
    // 修改商品价格
    event PriceChanged(address indexed seller, uint256 indexed tokenId, uint256 previousPrice, uint256 price);
    // 下架商品
    event OrderCanceled(address indexed seller, uint256 indexed tokenId);
    

    // 购买
    function buy(uint256 _tokenId) external{
        // 获取触发事件的参数
        require(isList(_tokenId), "Market: Token ID is not listed");
        address seller = orderByTokenId[_tokenId].seller;
        address buyer = msg.sender;
        uint256 price = orderByTokenId[_tokenId].price;

        // erc20token的转移
        require(
            erc20.transferFrom(buyer, seller, price),
            "Market: ERC20 transfer not successfull"
        );
        // 转移商品所有权
        erc721.safeTransferFrom(address(this), buyer, _tokenId);

        removeListing(_tokenId);
        emit Deal(buyer, seller, _tokenId, price);
    }

    // market删除商品
    function cancelOrder(uint256 _tokenId) external{
        require(isList(_tokenId), "Market: Token ID is not listed");
        address seller = orderByTokenId[_tokenId].seller;
        require(msg.sender == seller, "Market: Sender is not seller");
        erc721.safeTransferFrom(address(this), seller, _tokenId);

        removeListing(_tokenId);

        emit OrderCanceled(seller, _tokenId);
    }


    // 修改商品价格
    function changePrice(uint256 _tokenId, uint256 _newPrice) external {
        
        require(isList(_tokenId), "Market: Token ID is not listed");
        address seller = orderByTokenId[_tokenId].seller;
        require(msg.sender == seller, "Market: Sender is not seller");

        // 修改orderByTokenId中的order的价格和order中的价格
        uint256 oldPrice = orderByTokenId[_tokenId].price;
        orderByTokenId[_tokenId].price = _newPrice;
        Order storage order = orders[tokenIdByOrderIndex[_tokenId]];
        order.price = _newPrice;

        emit PriceChanged(seller, _tokenId, oldPrice, _newPrice);
    }

    function getOrderLength() public view returns (uint256) {
        return orders.length;
    }

    // 查看市场中order是否含有该订单
    function isList(uint256 _tokenId) public view returns (bool) {
        return orderByTokenId[_tokenId].seller != address(0);
    }

    // 获取所有商品
    function getAllOrders() public view returns (Order[] memory) {
        return orders;
    }

    // 获得token指定商品
    function getOrder(uint256 _tokenId) public view returns (Order memory){
        return orderByTokenId[_tokenId];
    }
    
    // 获得消息发送者的所有nft
    function getMyNFTs() public view returns (Order[] memory) {
        Order[] memory myOrders = new Order[](orders.length);
        uint256 myOrdersCount = 0;

        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].seller == msg.sender) {
                myOrders[myOrdersCount] = orders[i];
                myOrdersCount++;
            }
        }
        // myorder可能包含空的order，需要创建一个新数组去复制myorder
        Order[] memory myOrdersTrimmed = new Order[](myOrdersCount);
        for (uint256 i = 0; i < myOrdersCount; i++) {
            myOrdersTrimmed[i] = myOrders[i];
        }

        return myOrdersTrimmed;
    }

    

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public virtual override returns (bytes4) {
        require(_operator == _from, "Market: seller must be operator");
        uint256 price = toUint256(_data, 0);

        placeOrder(_from, _tokenId, price);
        return MAGIC_ON_ERC721_RECEIVED;
    }



    function toUint256(bytes memory _bytes, uint256 _start)public pure returns (uint256){
        require(_start + 32 >= _start, "Market: toUint256_overflow");
        require(_bytes.length >= _start + 32, "Market: toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    //添加商品到Market中
    function placeOrder(address _seller, uint256 _tokenId, uint256 _price) internal {
        require(_price > 0, "Market: Price must be greater than zero");
       
        // 将商品存储在orderByTokenId和orders中
        orderByTokenId[_tokenId] = Order(_seller, _tokenId, _price);
        orders.push(orderByTokenId[_tokenId]);
        tokenIdByOrderIndex[_tokenId] = orders.length - 1;

        // 触发事件
        emit NewOrder(_seller, _tokenId, _price);
    }

    // 将商品从Market中删除
    function removeListing(uint256 _tokenId) internal {
        delete orderByTokenId[_tokenId];

        // order中要删除的order索引
        uint256 orderIndex = tokenIdByOrderIndex[_tokenId];
        uint256 lastOrderIndex = orders.length - 1;

        // 如果要删除的order不是最后一个order，则将最后一个order移动到要删除的位置
        if (lastOrderIndex != orderIndex) {
            Order memory lastOrder = orders[lastOrderIndex];
            orders[orderIndex] = lastOrder;
            tokenIdByOrderIndex[lastOrder.tokenId] = orderIndex;
        }

        orders.pop();
    }

 }