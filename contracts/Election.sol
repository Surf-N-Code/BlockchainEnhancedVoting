pragma solidity ^0.4.24;

contract Election {
    //Store candidate
    //Read candidate
    string public candidate; //public so that we get a getter
    //Constructor
    constructor () public {
        candidate = "Candidate 1";
    }
}
