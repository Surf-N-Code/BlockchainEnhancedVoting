pragma solidity ^0.4.2;

contract Election {

    //Candidates
    struct Candidate {
        uint id;
        uint8 voteCount;
        string name;
    }
    //Question Categories
    struct Categories {
        uint id;
        string name;
        uint[] candidateList;
        mapping(uint => Candidate) candidateStructs;
    }

    //Contract stages
    enum Stages {
        AcceptingBlindVotes,
        RevealResults
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;
    //Store Categories by Id
    mapping(uint => Categories) public categoryStructs;
    //Read/write candidates
    mapping(uint => Candidate) public candidates;
    //Store accounts that have voted
    mapping(address => bool) public voters;
    //Election start and Enddates initialized in constructor
    uint public electionEnd;
    uint public electionStart;
    uint public electionDuration;
    uint public revealResultDuration;
    //Start with the voting stage
    Stages public stage = Stages.AcceptingBlindVotes;
    //Owner address
    address public owner = msg.sender;

    modifier onlyByMe(address _account)
    {
        require(
            msg.sender == _account,
            "Sender not authorized."
        );
        _;
    }
    function changeOwner(address _newOwner)
            public
            onlyBy(owner)
    {
        owner = _newOwner;
    }

    function getCategory(uint8 _categoryId)
        public
        view
        returns(string name, uint candidateCount)
    {
        return(categoryStructs[_categoryId].name, categoryStructs[_categoryId].candidateList.length);
    }

    function getCandidateResultsAndInfoFromCategory(uint8 _categoryId, uint _candidateId)
        public
        view
        returns(uint id, string name, uint8 voteCount)
    {
        return(
            categoryStructs[_categoryId].candidateStructs[_candidateId].id,
            categoryStructs[_categoryId].candidateStructs[_candidateId].name,
            categoryStructs[_categoryId].candidateStructs[_candidateId].voteCount
            );
    }

    function addVoteForCandidateInCategory(uint8 _categoryId, uint _candidateId)
        public
        timedTransition
        onlyWhileAcceptingVotes
        returns(bool success)
    {
        //Make sure voters only vote once
        require(!voters[msg.sender]);
        //Make sure candidate is valid
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        if(categoryStructs[_categoryId].candidateStructs[_candidateId].voteCount == 0) {
            categoryStructs[_categoryId].candidateList.push(_candidateId);
        }
        categoryStructs[_categoryId].candidateStructs[_candidateId].voteCount++;
        // record that voter has voted
        voters[msg.sender] = true;
        // trigger voted event
        votedEvent(_candidateId); //@TODO: to test this
        return true;
    }

    //Store Candidates Count
    uint public candidatesCount;

    function Election () public {
        /* for(uint8 i=0; i) */
        addCandidate(3, "Candidate 3", 0);
        addCandidate(3, "Candidate 3", 1);
        addCandidate(3, "Candidate 3", 2);
        addCandidate(3, "Candidate 3", 3);
        addCandidate(3, "Candidate 3", 4);
        addCandidate(3, "Candidate 3", 5);
        addCandidate(3, "Candidate 3", 6);
        addCandidate(3, "Candidate 3", 7);

        addCandidate(1, "Candidate 1", 0);
        addCandidate(1, "Candidate 1", 1);
        addCandidate(1, "Candidate 1", 2);
        addCandidate(1, "Candidate 1", 3);
        addCandidate(1, "Candidate 1", 4);
        addCandidate(1, "Candidate 1", 5);
        addCandidate(1, "Candidate 1", 6);
        addCandidate(1, "Candidate 1", 7);

        addCandidate(2, "Candidate 2", 0);
        addCandidate(2, "Candidate 2", 1);
        addCandidate(2, "Candidate 2", 2);
        addCandidate(2, "Candidate 2", 3);
        addCandidate(2, "Candidate 2", 4);
        addCandidate(2, "Candidate 2", 5);
        addCandidate(2, "Candidate 2", 6);
        addCandidate(2, "Candidate 2", 7);

        //Initialize voting categories
        newCategory(0, "Overall Best Teacher");
        newCategory(1, "Best Altcoin Picks");
        newCategory(2, "Best Guard on Bitcoin Watch");
        newCategory(3, "Best ICO Contributions");
        newCategory(4, "Best FA Analysis");
        newCategory(5, "Best Shot Caller on Margin Plays");
        newCategory(6, "Best Contributions to Tools and Education");
        newCategory(7, "General Positive Influence on the Pound");

        //Set the voting period
        electionStart = now;
        electionEnd = electionStart + electionDuration days;
    }

    function setTimeForElectionInDays()
        external (uint8 _time)
        onlyByMe
    {
        electionDuration = _time;
    }

    /**
     * Promotes contract into the next stage.
     * Start with phase 0 again once RevealResults is complete
     */
    function nextStage() internal {
        //Loop through stages and start again when RevealResults is done
        if(uint(stage) == 1) {
            stage = Stages(0);
        } else {
            stage = Stages(uint(stage) + 1);
        }
    }

    /**
     * Creates a timed transition into the next contract stage
     */
    modifier timedTransition() {
        //Close contract once election period ends
        if(stage == Stages.AcceptingBlindVotes
            && now >= (electionEnd)) {
                nextStage();
        }

        //Reset into AcceptingBlindVotes once RevealResults duration has passed
        if(stage == Stages.RevealResults && electionEnd + revealResultDuration > now) {

            nextStage();
        }
        _;
    }

    /**
     * Reverts if date is not in voting range
     */
    modifier onlyWhileAcceptingVotes() {
        require(stage == Stages.AcceptingBlindVotes
            && now >= electionStart
            && now <= electionEnd);
        _;
    }

    event votedEvent (
        uint indexed _candidateId
    );

    /**
     * Checks whether the period in which votes are allowd has already elapsed.
     * @return Whether voting period has elapsed
     */
    function hasClosed() public view returns (bool) {
        return now >= (electionEnd);
    }

    function newCategory(uint8 _categoryId, string _name)
        onlyByMe
        returns(bool success)
    {
        // not checking for duplicates
        categoryStructs[_categoryId].id = _categoryId;
        categoryStructs[_categoryId].name = _name;
        //categoriesList.push(_categoryId);
        return true;
    }

    function addCandidate (uint8 _candidateId, string _name, uint8 _categoryId)
        public
        onlyByMe
    {
        bool isCandidate = false;
        for(uint i; i<8; i++) {
            if(categoryStructs[i].candidateStructs[_candidateId]) {
                isCandidate = true;
            }
        }
        if(isCanddiate) {
            candidatesCount++;
        }
        categoryStructs[_categoryId].candidateStructs[_candidateId] = Candidate(_candidateId, 0, _name);
    }

    //@TODO: only owner einfügen
    //@TODO: time flexibel setzen
    /* function setTimeForElectionInDays() external (uint8 _time) {
        electionTime = _time;
    }
     */
    /* function electionTimeIsUp() external view returns (bool) {
        return (now >= (electionStart + electionTime));
    } */
}

//Election.deployed().then(function(i) {app=i})
//app.vote(2, {from: web3.eth.accounts[0]})
