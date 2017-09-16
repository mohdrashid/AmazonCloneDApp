pragma solidity ^0.4.6;

contract Owned{
    address public owner;
    function Owned(){
        owner=msg.sender;
    }
}

contract ShopFront is Owned {

    struct ProductStruct{
    uint id;
    uint price;
    uint stock;
    address owner;
    }

    mapping(address=>uint) private balanceSheet;

    mapping (uint=>uint) idPool;
    ProductStruct[] public productList;

    //events
    event LogAddProduct(address merchant,uint productID,uint price,uint stock);
    event LogBuyProduct(address customer,uint productID);
    event LogRemoveProduct(uint productID);
    event LogRestock(uint productID,uint stock);
    event LogWithdraw(address withdrawer);

    function ShopFront(){
    }

    function addProduct(uint _id,uint _price,uint _stock) returns(bool){
        if(productList.length!=0&&idPool[_id]!=0){
            revert();
        }
        //need to check if name is null
        else if(_price!=0){
            productList.push(ProductStruct(_id,_price,_stock,msg.sender));
            idPool[_id]=productList.length;
            LogAddProduct(msg.sender,_id,_price,_stock);
            return true;
        }
        else{
            return false;
        }
    }

    function buyProduct(uint _productID, uint _quantity) payable returns(bool){
        uint listIndex=idPool[_productID];
        ProductStruct memory product = productList[listIndex-1];
        if(product.price==0||msg.value<product.price){
            revert();
        }
        else if(product.stock==0||product.stock<_quantity){
            revert();
        }
        else{
            uint productOwnerBalance=product.owner.balance;
            if(productOwnerBalance+(product.price*_quantity)<productOwnerBalance){
                revert();
            }
            productList[listIndex-1].stock-=_quantity;
            LogBuyProduct(msg.sender,_productID);
            balanceSheet[product.owner]+=(product.price*_quantity);
        }
        return true;
    }

    function withdrawBalance() returns(bool){
        if(balanceSheet[msg.sender]==0){
            revert();
        }
        //Overflow detection
        if(msg.sender.balance+balanceSheet[msg.sender]<msg.sender.balance){
            revert();
        }
        else{
            if(msg.sender.send(balanceSheet[msg.sender])){
                balanceSheet[msg.sender]=0;
                LogWithdraw(msg.sender);
                return true;
            }
            return false;
        }
    }

    function removeProduct(uint _productID) returns(bool){
        uint listIndex=idPool[_productID];
        ProductStruct memory product = productList[listIndex-1];
        if(owner!=msg.sender&&product.owner!=msg.sender){
            revert();
        }
        else{
            delete productList[listIndex-1];
            LogRemoveProduct(_productID);
            return true;
        }
    }

    function reStock(uint _index,uint stock) returns(bool){
        uint listIndex=idPool[_index];
        ProductStruct memory product=productList[listIndex-1];
        product.stock=stock;
        productList[listIndex]=product;
        LogRestock(_index,stock);
        return true;
    }

    function getProductsCount() returns(uint){
        return productList.length;
    }
}
