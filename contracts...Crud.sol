pragma solidity 0.8.0;

contract CRUD {
    struct User{
        uint id;
        string name;
    }
    
    User[] public users;
    uint public nextIds = 1;
    
    function create(string memory name) public {
        users.push(User(nextIds,name));
        nextIds ++;
    }
    
    function read(uint id) view public returns(User memory){
        uint i = find(id);
        User memory user  = users[i];
        return user;
    }
    
    function find(uint id) view internal returns(uint){
        for(uint i=0;i<users.length;i++){
            if(users[i].id == id ){
                return i;
            }
        }
        revert('User does not exist');
    }
    
    function update(uint id, string memory name) public {
        uint i = find(id);
        users[i].name = name;
    }
    
    function deleteUser(uint id) public {
        uint i = find(id);
        delete users[i];
    }
    
    
    
    
}