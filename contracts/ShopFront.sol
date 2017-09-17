pragma solidity ^0.4.6;

contract Owned{
    address public owner;
    function Owned(){
        owner=msg.sender;
    }

    modifier onlyOwner(){
        require(owner==msg.sender);
        _;
    }
}


contract Administrated is Owned{
    mapping(address=>bool) public admins;

    event LogAddAdmin(address admin);
    event LogRemoveAdmin(address admin);

    function Administrated(){

    }

    function addAdmin(address admin) public onlyOwner returns (bool){
        admins[admin]=true;
        LogAddAdmin(admin);
        return true;
    }

    function removeAdmin(address admin) public onlyOwner returns (bool){
        admins[admin]=false;
        LogRemoveAdmin(admin);
        return true;
    }
}

contract ShopFront is Administrated {

    struct ProductStruct{
    uint id;
    uint price;
    uint stock;
    bool isPresent;
    address owner;
    }

    mapping(address=>uint) private balanceSheet;

    mapping (uint=>ProductStruct) productList;

    //events
    event LogAddProduct(address merchant,uint productID,uint price,uint stock);
    event LogBuyProduct(address customer,uint productID);
    event LogRemoveProduct(uint productID);
    event LogRestock(uint productID,uint stock);
    event LogWithdraw(address withdrawer);

    function ShopFront(){
    }

    function addProduct(uint _id,uint _price,uint _stock) returns(bool){
        require(productList[_id].isPresent==false);
        require(_price!=0);
        productList[_id]=ProductStruct(_id,_price,_stock,true,msg.sender);
        LogAddProduct(msg.sender,_id,_price,_stock);
        return true;

    }

    function buyProduct(uint _productID, uint _quantity) payable returns(bool){
        ProductStruct memory product = productList[_productID];
        require(product.isPresent==true);
        require(product.price!=0||msg.value>=product.price);
        require(product.stock!=0||product.stock>=_quantity);

        uint productOwnerBalance=product.owner.balance;
        if(productOwnerBalance+(product.price*_quantity)<productOwnerBalance){
            revert();
        }
        productList[_productID].stock-=_quantity;
        LogBuyProduct(msg.sender,_productID);
        balanceSheet[product.owner]+=(product.price*_quantity);

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
            uint amountToSend=balanceSheet[msg.sender];
            if(amountToSend==0) revert();
            balanceSheet[msg.sender]=0;
            if(msg.sender.send(amountToSend)){
                LogWithdraw(msg.sender);
                return true;
            }
            else{
                balanceSheet[msg.sender]=amountToSend;
                revert();
            }
        }
    }

    function removeProduct(uint _productID) returns(bool){
        ProductStruct memory product = productList[_productID];
        require(product.isPresent==true);
        require(owner==msg.sender||admins[msg.sender]==true||product.owner==msg.sender);

        productList[_productID].isPresent=false;
        LogRemoveProduct(_productID);
        return true;

    }

    function reStock(uint _index,uint stock) returns(bool){
        ProductStruct memory product=productList[_index];
        require(product.price>0);
        product.stock=stock;
        productList[_index]=product;
        LogRestock(_index,stock);
        return true;
    }

    function getProduct(uint _index) constant public returns(uint id,uint price,uint stock){
        ProductStruct memory product=productList[_index];
        require(product.isPresent);
        return (product.id,product.price,product.stock);
    }
}
