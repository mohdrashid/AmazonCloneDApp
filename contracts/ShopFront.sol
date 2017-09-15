pragma solidity ^0.4.0;


contract ShopFront {

    address public owner;

    struct ProductStruct{
    uint id;
    uint price;
    string name;
    uint stockAmount;
    address owner;
    }

    mapping(address=>uint) balanceSheet;

    mapping (uint=>uint) idPool;
    ProductStruct[] public productList;

    modifier requireOwner(){
        require(msg.sender==owner);
        _;
    }

    function ShopFront(){
        owner=msg.sender;
    }

    function addProduct(uint _id,uint _price,string _name,uint _stockAmount) returns(bool){
        if(productList.length!=0&&idPool[_id]!=0){
            revert();
        }
        //need to check if name is null
        else if(_price!=0){
            productList.push(ProductStruct(_id,_price,_name,_stockAmount,msg.sender));
            idPool[_id]=productList.length;
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
        else if(product.stockAmount==0||product.stockAmount<_quantity){
            revert();
        }
        else{
            uint productOwnerBalance=product.owner.balance;
            if(productOwnerBalance+(product.price*_quantity)<productOwnerBalance){
                revert();
            }
            productList[listIndex-1].stockAmount-=_quantity;
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
                return true;
            }
            return false;
        }
    }

    function removeProduct(uint _productID) returns(bool){
        uint listIndex=idPool[_productID];
        ProductStruct memory product = productList[listIndex-1];
        if(product.owner!=msg.sender){
            revert();
        }
        else{
            delete productList[listIndex-1];
            return true;
        }
    }

    function reStock(uint _index,uint stockAmount) returns(bool){
        uint listIndex=idPool[_index];
        ProductStruct memory product=productList[listIndex-1];
        product.stockAmount=stockAmount;
        productList[listIndex]=product;
        return true;
    }

    function getProductsCount() returns(uint){
        return productList.length;
    }

    function kill() requireOwner() public returns(bool success){
        selfdestruct(owner);
        success=true;
    }
}
