pragma solidity ^0.4.2;

contract Election {
    //Contract stages
    enum Stages {
        AcceptingBlindVotes,
        RevealResults,
        GettingDiscordMembers,
        StartingNewVote
    }
    //Define categories array
    uint8[5][] categories;
    //category[1][UID] = 10 votes;

    //Candidatescount per category
    uint8[5] candidatesCountPerCategory;

    uint public electionEnd;
    uint public electionStart;
    //Start with the voting stage
    Stages public stage = Stages.AcceptingBlindVotes;

    //Create a block whether a function can be called within the current stage
    modifier atStage(Stages _stage) {
        require(
            stage == _stage,
            "Function cannot be called at this time."
        );
        _;
    }

    /**
     * Promotes contract into the next stage.
     * Start with phase 0 again once StartingNewVote is complete
     */
    function nextStage() internal {
        if(uint(stage) == 3) {
            stage = Stages(0);
        } else {
            stage = Stages(uint(stage) + 1);
        }
    }

    /**
     * Creates a timed transition into the next contract stage
     */
    modifier timedTransition() {
        if(stage == Stages.AcceptingBlindVotes
            && now >= (electionEnd)) {
                nextStage();
        }
        //All other states transition by transactions
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

    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    //Store accounts that have voted
    mapping(address => bool) public voters;
    // Read/write candidates
    mapping(uint => Candidate) public candidates;

    // Store Candidates Count
    uint public candidatesCount;

    function Election () public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
        electionStart = now;
        electionEnd = electionStart + 20 seconds;
    }

    function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint[] _candidateIds)
        public
        timedTransition
        onlyWhileAcceptingVotes {
        // require voter hasn't voted before
        require(!voters[msg.sender]);

        // require valid candidates
        for (i=0;i<_candidateIds.length) {
            require(_candidateIds[i] > 0 && _candidateIds[i] <= candidatesCount);
        }

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        votedEvent(_candidateId);
    }

    /* function vote (uint _candidateId)
        public
        timedTransition
        onlyWhileAcceptingVotes {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        votedEvent(_candidateId);
    } */

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

    function returnNow() public view returns (uint) {
        return now;
    }

    function returnEndTime() public view returns (uint) {
        return (electionEnd);
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
